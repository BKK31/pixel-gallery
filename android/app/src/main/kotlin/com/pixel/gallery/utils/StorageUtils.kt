package com.pixel.gallery.utils

import android.Manifest
import android.annotation.SuppressLint
import android.content.ContentResolver
import android.content.ContentUris
import android.content.Context
import android.content.pm.PackageManager
import android.media.MediaMetadataRetriever
import android.net.Uri
import android.os.Binder
import android.os.Build
import android.os.ParcelFileDescriptor
import android.os.storage.StorageManager
import android.provider.DocumentsContract
import android.provider.MediaStore
import android.text.TextUtils
import android.util.Log
import androidx.core.net.toUri
import androidx.core.text.isDigitsOnly
import com.commonsware.cwac.document.DocumentFileCompat
import com.pixel.gallery.utils.FileUtils.transferFrom
import com.pixel.gallery.utils.MimeTypes.isImage
import com.pixel.gallery.utils.MimeTypes.isVideo
import com.pixel.gallery.utils.PermissionManager.getGrantedDirForPath
import com.pixel.gallery.utils.UriUtils.tryParseId
import java.io.File
import java.io.FileInputStream
import java.io.IOException
import java.io.InputStream
import java.io.OutputStream
import java.util.Locale
import java.util.regex.Pattern

object StorageUtils {
    private val LOG_TAG = LogUtils.createTag<StorageUtils>()

    private const val SCHEME_CONTENT = ContentResolver.SCHEME_CONTENT

    // cf DocumentsContract.EXTERNAL_STORAGE_PROVIDER_AUTHORITY
    private const val EXTERNAL_STORAGE_PROVIDER_AUTHORITY = "com.android.externalstorage.documents"

    // cf DocumentsContract.EXTERNAL_STORAGE_PRIMARY_EMULATED_ROOT_ID
    private const val EXTERNAL_STORAGE_PRIMARY_EMULATED_ROOT_ID = "primary"

    private const val TREE_URI_ROOT = "$SCHEME_CONTENT://$EXTERNAL_STORAGE_PROVIDER_AUTHORITY/tree/"

    private val MEDIA_STORE_VOLUME_EXTERNAL = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) MediaStore.VOLUME_EXTERNAL else "external"

    // TODO TLAD get it from `MediaStore.Images.Media.EXTERNAL_CONTENT_URI`?
    private val IMAGE_PATH_ROOT = "/$MEDIA_STORE_VOLUME_EXTERNAL/images/"

    // TODO TLAD get it from `MediaStore.Video.Media.EXTERNAL_CONTENT_URI`?
    private val VIDEO_PATH_ROOT = "/$MEDIA_STORE_VOLUME_EXTERNAL/video/"

    private val UUID_PATTERN = Regex("[A-Fa-f\\d-]+")
    private val TREE_URI_PATH_PATTERN = Pattern.compile("(.*?):(.*)")

    const val TRASH_PATH_PLACEHOLDER = "#trash"

    // whether the provided path is on one of this app specific directories:
    // - /storage/{volume}/Android/data/{package_name}/files
    // - /data/user/0/{package_name}/files
    private fun isAppFile(context: Context, path: String): Boolean {
        val dirs = listOf(
            *context.getExternalFilesDirs(null).filterNotNull().toTypedArray(),
            context.filesDir,
        )
        return dirs.any { path.startsWith(it.path) }
    }

    private fun appExternalFilesDirFor(context: Context, path: String): File? {
        val dirs = context.getExternalFilesDirs(null).filterNotNull()
        val volumePath = getVolumePath(context, path)
        return volumePath?.let { dirs.firstOrNull { it.startsWith(volumePath) } } ?: dirs.firstOrNull()
    }

    fun trashDirFor(context: Context, path: String): File? {
        val externalFilesDir = appExternalFilesDirFor(context, path)
        if (externalFilesDir == null) {
            Log.e(LOG_TAG, "failed to find external files dir for path=$path")
            return null
        }
        val trashDir = File(externalFilesDir, "trash")
        trashDir.mkdirs()
        if (!trashDir.exists()) {
            Log.e(LOG_TAG, "failed to create directories at path=$trashDir")
            return null
        }
        return trashDir
    }

    /**
     * Volume paths
     */

    // volume paths, with trailing "/"
    private var mStorageVolumePaths: Array<String>? = null

    // primary volume path, with trailing "/"
    private var mPrimaryVolumePath: String? = null

    fun getPrimaryVolumePath(context: Context): String {
        if (mPrimaryVolumePath == null) {
            mPrimaryVolumePath = findPrimaryVolumePath(context)
        }
        return mPrimaryVolumePath!!
    }

    fun getVolumePaths(context: Context): Array<String> {
        if (mStorageVolumePaths == null || mStorageVolumePaths!!.isEmpty()) {
            mStorageVolumePaths = findVolumePaths(context)
        }
        return mStorageVolumePaths!!
    }

    fun getVolumePath(context: Context, anyPath: String): String? {
        return getVolumePaths(context).firstOrNull { anyPath.startsWith(it) }
    }

    private fun getPathStepIterator(context: Context, anyPath: String, root: String?): Iterator<String?>? {
        val rootLength = (root ?: getVolumePath(context, anyPath))?.length ?: return null

        var fileName: String? = null
        var relativePath: String? = null
        val lastSeparatorIndex = anyPath.lastIndexOf(File.separator) + 1
        if (lastSeparatorIndex > rootLength) {
            fileName = anyPath.substring(lastSeparatorIndex)
            relativePath = anyPath.substring(rootLength, lastSeparatorIndex)
        }
        relativePath ?: return null

        val pathSteps = relativePath.split(File.separator).filter { it.isNotEmpty() }.toMutableList()
        if (fileName?.isNotEmpty() == true) {
            pathSteps.add(fileName)
        }
        return pathSteps.iterator()
    }

    private fun appSpecificVolumePath(file: File?): String? {
        file ?: return null
        val appSpecificPath = file.absolutePath
        val relativePathStartIndex = appSpecificPath.indexOf("Android/data")
        if (relativePathStartIndex < 0) return null
        return appSpecificPath.take(relativePathStartIndex)
    }

    private fun findPrimaryVolumePath(context: Context): String? {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            val sm = context.getSystemService(Context.STORAGE_SERVICE) as? StorageManager
            val path = sm?.primaryStorageVolume?.directory?.path
            if (path != null) {
                return ensureTrailingSeparator(path)
            }
        }

        // fallback
        try {
            // we want:
            // /storage/emulated/0/
            // `Environment.getExternalStorageDirectory()` (deprecated) yields:
            // /storage/emulated/0
            // `context.getExternalFilesDir(null)` yields:
            // /storage/emulated/0/Android/data/{package_name}/files
            return appSpecificVolumePath(context.getExternalFilesDir(null))
        } catch (e: Exception) {
            Log.e(LOG_TAG, "failed to find primary volume path", e)
        }
        return null
    }

    private fun findVolumePaths(context: Context): Array<String> {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            val sm = context.getSystemService(Context.STORAGE_SERVICE) as? StorageManager
            val paths = sm?.storageVolumes?.mapNotNull { it.directory?.path }
            if (paths != null) {
                return paths.map(::ensureTrailingSeparator).toTypedArray()
            }
        }

        // fallback
        val paths = HashSet<String>()
        try {
            // Primary emulated SD-CARD
            val rawEmulatedStorageTarget = System.getenv("EMULATED_STORAGE_TARGET") ?: ""
            if (TextUtils.isEmpty(rawEmulatedStorageTarget)) {
                // fix of empty raw emulated storage on marshmallow
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    lateinit var files: List<File>
                    var validFiles: Boolean
                    val retryInterval = 100L
                    val maxDelay = 1000L
                    var totalDelay = 0L
                    do {
                        // `getExternalFilesDirs` sometimes include `null` when called right after getting read access
                        // (e.g. on API 30 emulator) so we retry until the file system is ready.
                        // It can also include `null` when there is a faulty SD card.
                        val externalFilesDirs = context.getExternalFilesDirs(null)
                        validFiles = !externalFilesDirs.contains(null)
                        if (validFiles) {
                            files = externalFilesDirs.filterNotNull()
                        } else {
                            Log.d(LOG_TAG, "External files dirs contain `null`. Retrying...")
                            totalDelay += retryInterval
                            try {
                                Thread.sleep(retryInterval)
                            } catch (e: InterruptedException) {
                                Log.e(LOG_TAG, "insomnia", e)
                            }
                        }
                    } while (!validFiles && totalDelay < maxDelay)
                    paths.addAll(files.mapNotNull(::appSpecificVolumePath))
                } else {
                    // Primary physical SD-CARD (not emulated)
                    val rawExternalStorage = System.getenv("EXTERNAL_STORAGE") ?: ""

                    // Device has physical external storage; use plain paths.
                    if (TextUtils.isEmpty(rawExternalStorage)) {
                        // EXTERNAL_STORAGE undefined; falling back to default.
                        paths.addAll(physicalPaths)
                    } else {
                        paths.add(rawExternalStorage)
                    }
                }
            } else {
                // Device has emulated storage; external storage paths should have userId burned into them.
                // /storage/emulated/[0,1,2,...]/
                val path = getPrimaryVolumePath(context)
                val rawUserId = path.split(File.separator).lastOrNull(String::isNotEmpty)?.takeIf { it.isDigitsOnly() } ?: ""
                if (rawUserId.isEmpty()) {
                    paths.add(rawEmulatedStorageTarget)
                } else {
                    paths.add(rawEmulatedStorageTarget + File.separator + rawUserId)
                }
            }

            // All Secondary SD-CARDs (all exclude primary) separated by ":"
            System.getenv("SECONDARY_STORAGE")?.let { secondaryStorages ->
                paths.addAll(secondaryStorages.split(File.pathSeparator).filter { it.isNotEmpty() })
            }
        } catch (e: Exception) {
            Log.e(LOG_TAG, "failed to find volume paths", e)
        }

        return paths.map { ensureTrailingSeparator(it) }.toTypedArray()
    }

    // returns physicalPaths based on phone model
    @SuppressLint("SdCardPath")
    private val physicalPaths = arrayOf(
        "/storage/sdcard0",
        "/storage/sdcard1",
        "/storage/extsdcard",
        "/storage/sdcard0/external_sdcard",
        "/mnt/extsdcard",
        "/mnt/sdcard/external_sd",
        "/mnt/external_sd",
        "/mnt/media_rw/sdcard1",
        "/removable/microsd",
        "/mnt/emmc",
        "/storage/external_SD",
        "/storage/ext_sd",
        "/storage/removable/sdcard1",
        "/data/sdext",
        "/data/sdext2",
        "/data/sdext3",
        "/data/sdext4",
        "/sdcard1",
        "/sdcard2",
        "/storage/microsd"
    )

    /**
     * Volume tree URIs
     */

    private fun getVolumeUuidForDocumentUri(context: Context, anyPath: String): String? {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            val sm = context.getSystemService(Context.STORAGE_SERVICE) as? StorageManager
            sm?.getStorageVolume(File(anyPath))?.let { volume ->
                if (volume.isPrimary) {
                    return EXTERNAL_STORAGE_PRIMARY_EMULATED_ROOT_ID
                }
                volume.uuid?.let { uuid ->
                    return uuid.uppercase(Locale.ROOT)
                }
            }
        }

        getVolumePath(context, anyPath)?.let { volumePath ->
            if (volumePath == getPrimaryVolumePath(context)) {
                return EXTERNAL_STORAGE_PRIMARY_EMULATED_ROOT_ID
            }
            volumePath.split(File.separator).lastOrNull { it.isNotEmpty() }?.let { uuid ->
                if (uuid.matches(UUID_PATTERN)) {
                    return uuid.uppercase(Locale.ROOT)
                }
            }

            context.contentResolver.persistedUriPermissions.firstOrNull { uriPermission ->
                convertTreeDocumentUriToDirPath(context, uriPermission.uri)?.let {
                    getVolumePath(context, it)?.let { grantedVolumePath ->
                        grantedVolumePath == volumePath
                    }
                } ?: false
            }?.let { uriPermission ->
                splitTreeDocumentUri(uriPermission.uri)?.let { (uuid, _) ->
                    return uuid
                }
            }
        }

        Log.e(LOG_TAG, "failed to find volume UUID for anyPath=$anyPath")
        return null
    }

    private fun getVolumePathFromTreeDocumentUriUuid(context: Context, uuid: String): String? {
        if (uuid == EXTERNAL_STORAGE_PRIMARY_EMULATED_ROOT_ID) {
            return getPrimaryVolumePath(context)
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            val sm = context.getSystemService(Context.STORAGE_SERVICE) as? StorageManager
            if (sm != null) {
                for (volumePath in getVolumePaths(context)) {
                    try {
                        val volume = sm.getStorageVolume(File(volumePath))
                        if (volume != null && uuid.equals(volume.uuid, ignoreCase = true)) {
                            return volumePath
                        }
                    } catch (_: Exception) {
                        // ignore
                    }
                }
            }
        }

        for (volumePath in getVolumePaths(context)) {
            val volumeUuid = volumePath.split(File.separator).lastOrNull { it.isNotEmpty() }
            if (uuid.equals(volumeUuid, ignoreCase = true)) {
                return volumePath
            }
        }

        val primaryVolumePath = getPrimaryVolumePath(context)
        getVolumePaths(context).firstOrNull { volumePath ->
            if (volumePath == primaryVolumePath) {
                false
            } else {
                val volumeUuid = volumePath.split(File.separator).lastOrNull { it.isNotEmpty() }
                !(volumeUuid == null || volumeUuid.matches(UUID_PATTERN))
            }
        }?.let { return it }

        Log.e(LOG_TAG, "failed to find volume path for UUID=$uuid")
        return null
    }

    fun convertDirPathToTreeDocumentUri(context: Context, dirPath: String): Uri? {
        val uuid = getVolumeUuidForDocumentUri(context, dirPath)
        if (uuid != null) {
            val relativeDir = removeTrailingSeparator(PathSegments(context, dirPath).relativeDir ?: "")
            return DocumentsContract.buildTreeDocumentUri(EXTERNAL_STORAGE_PROVIDER_AUTHORITY, "$uuid:$relativeDir")
        }
        Log.e(LOG_TAG, "failed to convert dirPath=$dirPath to tree document URI")
        return null
    }

    fun convertDirPathToDocumentUri(context: Context, dirPath: String): Uri? {
        val uuid = getVolumeUuidForDocumentUri(context, dirPath)
        if (uuid != null) {
            val relativeDir = removeTrailingSeparator(PathSegments(context, dirPath).relativeDir ?: "")
            return DocumentsContract.buildDocumentUri(EXTERNAL_STORAGE_PROVIDER_AUTHORITY, "$uuid:$relativeDir")
        }
        Log.e(LOG_TAG, "failed to convert dirPath=$dirPath to document URI")
        return null
    }

    private fun splitTreeDocumentUri(treeDocumentUri: Uri): Pair<String, String>? {
        val treeDocumentUriString = treeDocumentUri.toString()
        if (treeDocumentUriString.length <= TREE_URI_ROOT.length) return null
        val encoded = treeDocumentUriString.substring(TREE_URI_ROOT.length)
        val matcher = TREE_URI_PATH_PATTERN.matcher(Uri.decode(encoded))
        with(matcher) {
            if (find()) {
                val uuid = group(1)
                val relativePath = group(2)
                if (uuid != null && relativePath != null) {
                    return Pair(uuid, relativePath)
                }
            }
        }
        Log.e(LOG_TAG, "failed to split treeDocumentUri=$treeDocumentUri to UUID and relative path")
        return null
    }

    fun convertTreeDocumentUriToDirPath(context: Context, treeDocumentUri: Uri): String? {
        splitTreeDocumentUri(treeDocumentUri)?.let { (uuid, relativePath) ->
            val volumePath = getVolumePathFromTreeDocumentUriUuid(context, uuid)
            if (volumePath != null) {
                return ensureTrailingSeparator(volumePath + relativePath)
            }
        }
        Log.e(LOG_TAG, "failed to convert treeDocumentUri=$treeDocumentUri to path")
        return null
    }

    /**
     * Document files
     */

    fun getDocumentFile(context: Context, anyPath: String, mediaUri: Uri): DocumentFileCompat? {
        try {
            if (requireAccessPermission(context, anyPath)) {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && isMediaStoreContentUri(mediaUri)) {
                    PermissionManager.sanitizePersistedUriPermissions(context)
                    try {
                        val docUri = MediaStore.getDocumentUri(context, mediaUri)
                        if (docUri != null) {
                            return DocumentFileCompat.fromSingleUri(context, docUri)
                        }
                    } catch (e: Exception) {
                        Log.w(LOG_TAG, "failed to get document URI for mediaUri=$mediaUri", e)
                    }
                }

                val df = getVolumePath(context, anyPath)?.let { convertDirPathToTreeDocumentUri(context, it) }?.let { getDocumentFileFromVolumeTree(context, it, anyPath) }
                if (df != null) return df

                if (mediaUri.userInfo != null) {
                    val genericMediaUri = stripMediaUriUserInfo(mediaUri)
                    Log.d(LOG_TAG, "retry getDocumentFile for mediaUri=$mediaUri without userInfo: $genericMediaUri")
                    return getDocumentFile(context, anyPath, genericMediaUri)
                }
            }
            return DocumentFileCompat.fromFile(File(anyPath))
        } catch (e: SecurityException) {
            Log.w(LOG_TAG, "failed to get document file from mediaUri=$mediaUri", e)
        }
        return null
    }

    fun createDirectoryDocIfAbsent(context: Context, dirPath: String): DocumentFileCompat? {
        try {
            val targetDirPath = ensureTrailingSeparator(dirPath)
            return if (requireAccessPermission(context, targetDirPath)) {
                val grantedDir = getGrantedDirForPath(context, targetDirPath) ?: return null
                val rootTreeDocumentUri = convertDirPathToTreeDocumentUri(context, grantedDir) ?: return null
                var parentFile: DocumentFileCompat? = DocumentFileCompat.fromTreeUri(context, rootTreeDocumentUri) ?: return null
                val pathIterator = getPathStepIterator(context, targetDirPath, grantedDir)
                var currentDirPath = ensureTrailingSeparator(grantedDir)
                while (pathIterator?.hasNext() == true) {
                    val dirName = pathIterator.next()
                    var treeDocFile = findDocumentFileIgnoreCase(parentFile, dirName)
                    currentDirPath = ensureTrailingSeparator(currentDirPath + dirName)

                    if (treeDocFile == null && File(currentDirPath).exists()) {
                        Log.e(LOG_TAG, "failed to get document file for existing path=$currentDirPath from granted dir=$grantedDir. Revoking granted dir...")
                        PermissionManager.revokeDirectoryAccess(context, grantedDir)
                        throw Exception("failed to get document file for existing path=$currentDirPath from grantedDir=$grantedDir")
                    }

                    if (treeDocFile == null || !treeDocFile.exists()) {
                        treeDocFile = parentFile?.createDirectory(dirName)
                        if (treeDocFile == null) {
                            Log.e(LOG_TAG, "failed to create directory with name=$dirName from parent=$parentFile")
                            return null
                        }
                    }
                    parentFile = treeDocFile
                }
                parentFile
            } else {
                val directory = File(targetDirPath)
                directory.mkdirs()
                if (!directory.exists()) {
                    Log.e(LOG_TAG, "failed to create directories at path=$targetDirPath")
                    return null
                }
                DocumentFileCompat.fromFile(directory)
            }
        } catch (e: Exception) {
            Log.e(LOG_TAG, "failed to create directory at path=$dirPath", e)
            return null
        }
    }

    private fun getDocumentFileFromVolumeTree(context: Context, rootTreeDocumentUri: Uri, anyPath: String): DocumentFileCompat? {
        var documentFile: DocumentFileCompat? = DocumentFileCompat.fromTreeUri(context, rootTreeDocumentUri) ?: return null

        val pathIterator = getPathStepIterator(context, anyPath, null)
        while (pathIterator?.hasNext() == true) {
            documentFile = findDocumentFileIgnoreCase(documentFile, pathIterator.next()) ?: return null
        }
        return documentFile
    }

    private fun findDocumentFileIgnoreCase(documentFile: DocumentFileCompat?, displayName: String?): DocumentFileCompat? {
        documentFile ?: return null
        for (doc in documentFile.listFiles()) {
            if (displayName.equals(doc.name, ignoreCase = true)) {
                return doc
            }
        }
        return null
    }

    /**
     * Misc
     */

    fun canEditByFile(context: Context, path: String) = !requireAccessPermission(context, path)

    fun requireAccessPermission(context: Context, anyPath: String): Boolean {
        if (isAppFile(context, anyPath)) return false

        if (Build.VERSION.SDK_INT > Build.VERSION_CODES.Q) return true

        val onPrimaryVolume = anyPath.startsWith(getPrimaryVolumePath(context))
        return !onPrimaryVolume
    }

    fun isMediaStoreContentUri(uri: Uri?): Boolean {
        uri ?: return false
        return SCHEME_CONTENT.equals(uri.scheme, ignoreCase = true) && MediaStore.AUTHORITY.equals(uri.host, ignoreCase = true)
    }

    fun getOriginalUri(context: Context, uri: Uri): Uri {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q && isMediaStoreContentUri(uri)) {
            val path = uri.path
            path ?: return uri
            if (path.startsWith(IMAGE_PATH_ROOT) || path.startsWith(VIDEO_PATH_ROOT)) {
                if (context.checkSelfPermission(Manifest.permission.ACCESS_MEDIA_LOCATION) == PackageManager.PERMISSION_GRANTED) {
                    return MediaStore.setRequireOriginal(uri)
                }
            }
        }
        return uri
    }

    fun getMediaStoreScopedStorageSafeUri(uri: Uri, mimeType: String): Uri {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q && isMediaStoreContentUri(uri)) {
            val uriPath = uri.path
            when {
                uriPath?.contains("/downloads/") == true -> {
                    getMediaUriImageVideoUri(uri, mimeType)?.let { imageVideoUri -> return imageVideoUri }
                }

                uri.userInfo != null -> return stripMediaUriUserInfo(uri)
            }
        }
        return uri
    }

    private fun getMediaUriImageVideoUri(uri: Uri, mimeType: String): Uri? {
        return uri.tryParseId()?.let { id ->
            return when {
                isImage(mimeType) -> ContentUris.withAppendedId(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, id)
                isVideo(mimeType) -> ContentUris.withAppendedId(MediaStore.Video.Media.EXTERNAL_CONTENT_URI, id)
                else -> uri
            }
        }
    }

    private fun stripMediaUriUserInfo(uri: Uri) = uri.toString().replaceFirst("${uri.userInfo}@", "").toUri()

    fun openInputStream(context: Context, uri: Uri): InputStream? {
        val effectiveUri = getOriginalUri(context, uri)
        return try {
            return when (uri.scheme) {
                ContentResolver.SCHEME_FILE -> FileInputStream(uri.path)
                else -> context.contentResolver.openInputStream(effectiveUri)
            }
        } catch (e: Exception) {
            Log.w(LOG_TAG, "failed to open input stream from effectiveUri=$effectiveUri for uri=$uri", e)
            null
        }
    }

    fun openOutputStream(context: Context, mimeType: String, uri: Uri, mode: String): OutputStream? {
        val effectiveUri = getMediaStoreScopedStorageSafeUri(uri, mimeType)
        return try {
            context.contentResolver.openOutputStream(effectiveUri, mode)
        } catch (e: Exception) {
            Log.w(LOG_TAG, "failed to open output stream from effectiveUri=$effectiveUri for uri=$uri mode=$mode", e)
            null
        }
    }

    fun openInputFileDescriptor(context: Context, uri: Uri): ParcelFileDescriptor? {
        val effectiveUri = getOriginalUri(context, uri)
        return try {
            context.contentResolver.openFileDescriptor(effectiveUri, "r")
        } catch (e: Exception) {
            Log.w(LOG_TAG, "failed to open input file descriptor from effectiveUri=$effectiveUri for uri=$uri", e)
            null
        }
    }

    fun openMetadataRetriever(context: Context, uri: Uri): MediaMetadataRetriever? {
        val effectiveUri = getOriginalUri(context, uri)
        return try {
            MediaMetadataRetriever().apply {
                setDataSource(context, effectiveUri)
            }
        } catch (_: Exception) {
            Log.w(LOG_TAG, "failed to initialize MediaMetadataRetriever for uri=$uri effectiveUri=$effectiveUri")
            null
        }
    }

    private fun getTempDirectory(context: Context): File = File(context.cacheDir, "temp")

    fun createTempFile(context: Context, extension: String? = null): File {
        val directory = getTempDirectory(context)
        directory.mkdirs()
        if (!directory.exists()) {
            throw IOException("failed to create directories at path=$directory")
        }
        val tempFile = File.createTempFile("aves", extension, directory)
        tempFile.deleteOnExit()
        return tempFile
    }

    fun ensureTrailingSeparator(dirPath: String): String {
        return if (dirPath.endsWith(File.separator)) dirPath else dirPath + File.separator
    }

    fun removeTrailingSeparator(dirPath: String): String {
        return if (dirPath.endsWith(File.separator)) dirPath.dropLast(1) else dirPath
    }

    class PathSegments(context: Context, fullPath: String) {
        var volumePath: String? = null
        var relativeDir: String? = null
        private var fileName: String? = null

        init {
            volumePath = getVolumePath(context, fullPath)
            if (volumePath != null) {
                val lastSeparatorIndex = fullPath.lastIndexOf(File.separator) + 1
                val volumePathLength = volumePath!!.length
                if (lastSeparatorIndex > volumePathLength) {
                    fileName = fullPath.substring(lastSeparatorIndex)
                    relativeDir = fullPath.substring(volumePathLength, lastSeparatorIndex)
                }
            }
        }
    }
}
