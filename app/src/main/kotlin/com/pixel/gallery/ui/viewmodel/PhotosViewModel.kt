package com.pixel.gallery.ui.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.pixel.gallery.data.local.entity.MediaEntry
import com.pixel.gallery.data.repository.MediaFileOperationResult
import com.pixel.gallery.data.repository.MediaRepository
import com.pixel.gallery.data.repository.SettingsRepository
import com.pixel.gallery.services.MetadataService
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import com.pixel.gallery.model.Album
import javax.inject.Inject

@HiltViewModel
class PhotosViewModel @Inject constructor(
    private val repository: MediaRepository,
    private val settingsRepository: SettingsRepository,
    private val metadataService: MetadataService
) : ViewModel() {

    sealed class GridItem {
        data class Header(val title: String, val timestamp: Long) : GridItem()
        data class Photo(val entry: MediaEntry) : GridItem()
    }

    data class ExternalMedia(
        val uri: String,
        val mimeType: String,
        val resolvedContentId: Long? = null,
        val resolvedFolderName: String? = null
    )

    private val _externalMedia = MutableStateFlow<ExternalMedia?>(null)
    val externalMedia: StateFlow<ExternalMedia?> = _externalMedia

    fun setExternalMediaUri(uri: String?, mimeType: String? = null) {
        if (uri != null) {
            viewModelScope.launch {
                val resolved = repository.resolveExternalUri(uri)
                _externalMedia.value = ExternalMedia(
                    uri = uri,
                    mimeType = mimeType ?: "image/*",
                    resolvedContentId = resolved?.first,
                    resolvedFolderName = resolved?.second
                )
            }
        } else {
            _externalMedia.value = null
        }
    }

    fun clearExternalMediaUri() {
        _externalMedia.value = null
    }

    val allPhotos: StateFlow<List<MediaEntry>> = repository.allEntries
        .stateIn(viewModelScope, SharingStarted.Lazily, emptyList())

    val hiddenFolders: StateFlow<Set<String>> = settingsRepository.hiddenFolders
        .stateIn(viewModelScope, SharingStarted.Lazily, emptySet())

    val photos: StateFlow<List<MediaEntry>> = combine(
        allPhotos,
        hiddenFolders
    ) { all, hidden ->
        all.filter { entry ->
            !hidden.any { entry.path.startsWith(it) }
        }.sortedWith(
            compareByDescending<MediaEntry> { it.bestTimestamp }
                .thenByDescending { it.contentId }
        )
    }.stateIn(viewModelScope, SharingStarted.Lazily, emptyList())

    fun groupMedia(entries: List<MediaEntry>, columns: Int = 3): List<GridItem> {
        val items = mutableListOf<GridItem>()
        var lastHeader = ""
        // Use monthly grouping if columns are 6 or more
        val format = if (columns >= 6) "MMMM yyyy" else "MMMM d, yyyy"
        val sdf = java.text.SimpleDateFormat(format, java.util.Locale.getDefault())
        
        entries.forEach { entry ->
            val timestamp = entry.bestTimestamp
            
            val date = java.util.Date(timestamp)
            val header = sdf.format(date)
            if (header != lastHeader) {
                items.add(GridItem.Header(header, timestamp))
                lastHeader = header
            }
            items.add(GridItem.Photo(entry))
        }
        return items
    }

    val gridColumns: StateFlow<Int> = settingsRepository.gridColumns
        .stateIn(viewModelScope, SharingStarted.Eagerly, 3)

    val groupedPhotos: StateFlow<List<GridItem>> = combine(photos, gridColumns) { media, cols ->
        groupMedia(media, cols)
    }.stateIn(viewModelScope, SharingStarted.Lazily, emptyList())

    val favourites: StateFlow<List<MediaEntry>> = repository.favourites
        .map { list ->
            list.sortedWith(
                compareByDescending<MediaEntry> { it.bestTimestamp }
                    .thenByDescending { it.contentId }
            )
        }
        .stateIn(viewModelScope, SharingStarted.Lazily, emptyList())

    val groupedFavourites: StateFlow<List<GridItem>> = combine(favourites, gridColumns) { media, cols ->
        groupMedia(media, cols)
    }.stateIn(viewModelScope, SharingStarted.Lazily, emptyList())

    val trashedMedia: StateFlow<List<MediaEntry>> = repository.trash
        .map { list ->
            list.sortedWith(
                compareByDescending<MediaEntry> { it.bestTimestamp }
                    .thenByDescending { it.contentId }
            )
        }
        .stateIn(viewModelScope, SharingStarted.Lazily, emptyList())

    val groupedTrashedMedia: StateFlow<List<GridItem>> = combine(trashedMedia, gridColumns) { media, cols ->
        groupMedia(media, cols)
    }.stateIn(viewModelScope, SharingStarted.Lazily, emptyList())

    val trashDates: StateFlow<Map<Long, Long>> = repository.trashDates
        .stateIn(viewModelScope, SharingStarted.Lazily, emptyMap())

    val vaultEntries: StateFlow<List<MediaEntry>> = repository.vaultEntries
        .stateIn(viewModelScope, SharingStarted.Lazily, emptyList())

    val groupedVaultEntries: StateFlow<List<GridItem>> = combine(vaultEntries, gridColumns) { media, cols ->
        groupMedia(media, cols)
    }.stateIn(viewModelScope, SharingStarted.Lazily, emptyList())

    val startupAtAlbums: StateFlow<Boolean> = settingsRepository.startupAtAlbums
        .stateIn(viewModelScope, SharingStarted.Eagerly, false)

    val materialYou: StateFlow<Boolean> = settingsRepository.materialYou
        .stateIn(viewModelScope, SharingStarted.Eagerly, true)

    val confirmTrash: StateFlow<Boolean> = settingsRepository.confirmTrash
        .stateIn(viewModelScope, SharingStarted.Eagerly, true)

    val confirmDelete: StateFlow<Boolean> = settingsRepository.confirmDelete
        .stateIn(viewModelScope, SharingStarted.Eagerly, true)

    val ribbonOpen: StateFlow<Boolean> = settingsRepository.ribbonOpen
        .stateIn(viewModelScope, SharingStarted.Lazily, false)

    val videoMuted: StateFlow<Boolean> = settingsRepository.videoMuted
        .stateIn(viewModelScope, SharingStarted.Lazily, false)

    val excludedFolders: StateFlow<Set<String>> = settingsRepository.excludedFolders
        .stateIn(viewModelScope, SharingStarted.Lazily, emptySet())


    val albums: StateFlow<List<Album>> = photos
        .map { photos ->
            photos.groupBy { 
                val file = java.io.File(it.path)
                file.parentFile?.name ?: "Unknown"
            }.map { (name, entries) ->
                val firstEntry = entries.first()
                val parentPath = java.io.File(firstEntry.path).parent ?: ""
                Album(name, parentPath, firstEntry.uri, entries.size)
            }.sortedBy { it.name }
        }
        .stateIn(viewModelScope, SharingStarted.Lazily, emptyList())

    val hiddenAlbums: StateFlow<List<Album>> = combine(
        allPhotos,
        hiddenFolders
    ) { all, hidden ->
        all.filter { entry ->
            hidden.any { entry.path.startsWith(it) }
        }.groupBy { 
            val file = java.io.File(it.path)
            file.parentFile?.name ?: "Unknown"
        }.map { (name, entries) ->
            val firstEntry = entries.first()
            val parentPath = java.io.File(firstEntry.path).parent ?: ""
            Album(name, parentPath, firstEntry.uri, entries.size)
        }.sortedBy { it.name }
    }.stateIn(viewModelScope, SharingStarted.Lazily, emptyList())

    private var contentObserver: android.database.ContentObserver? = null

    init {
        refresh()
        registerContentObserver()
    }

    private fun registerContentObserver() {
        contentObserver = object : android.database.ContentObserver(android.os.Handler(android.os.Looper.getMainLooper())) {
            override fun onChange(selfChange: Boolean) {
                super.onChange(selfChange)
                refresh()
            }
        }
        val resolver = repository.getContentResolver()
        resolver.registerContentObserver(android.provider.MediaStore.Images.Media.EXTERNAL_CONTENT_URI, true, contentObserver!!)
        resolver.registerContentObserver(android.provider.MediaStore.Video.Media.EXTERNAL_CONTENT_URI, true, contentObserver!!)
    }

    override fun onCleared() {
        super.onCleared()
        contentObserver?.let {
            repository.getContentResolver().unregisterContentObserver(it)
        }
    }

    fun refresh(delayMillis: Long = 0L) {
        viewModelScope.launch {
            if (delayMillis > 0L) {
                kotlinx.coroutines.delay(delayMillis)
            }
            repository.syncWithMediaStore()
        }
    }

    // --- Actions ---
    fun toggleFavourite(id: Long, isCurrentlyFavourite: Boolean) {
        viewModelScope.launch {
            if (isCurrentlyFavourite) {
                repository.removeFavourite(id)
            } else {
                repository.addFavourite(id)
            }
        }
    }

    fun isFavourite(id: Long): Flow<Boolean> = repository.isFavourite(id)

    fun moveToTrash(id: Long, uri: String, path: String) {
        viewModelScope.launch {
            repository.trashMedia(id, uri, path)
        }
    }

    fun moveToTrashBulk(uris: List<String>) {
        viewModelScope.launch {
            if (repository.trashMediaBulk(uris)) {
                refresh(1000L)
            }
        }
    }

    fun restoreMedia(id: Long, uri: String) {
        viewModelScope.launch {
            repository.restoreMedia(id, uri)
            refresh(1000L)
        }
    }

    fun restoreMediaBulk(uris: List<String>) {
        viewModelScope.launch {
            if (repository.restoreMediaBulk(uris)) {
                refresh(1000L)
            }
        }
    }

    fun moveToVault(entry: MediaEntry) {
        viewModelScope.launch {
            if (repository.moveToVault(entry)) {
                refresh(1000L)
            }
        }
    }

    fun restoreFromVault(id: Long) {
        viewModelScope.launch {
            if (repository.restoreFromVault(id)) {
                refresh(1000L)
            }
        }
    }

    fun deleteMediaBulk(uris: List<String>) {
        viewModelScope.launch {
            if (repository.deleteMediaBulk(uris)) {
                refresh(1000L)
            }
        }
    }

    // --- Metadata ---
    fun getMediaMetadata(path: String) = metadataService.getMetadata(path)
    fun getCoordinates(path: String) = metadataService.getCoordinates(path)
    fun extractMotionVideo(path: String) = metadataService.extractMotionVideo(path)
    fun isUltraHdr(path: String) = metadataService.isUltraHdr(path)


    // --- Settings Actions ---
    fun setStartupAtAlbums(value: Boolean) {
        viewModelScope.launch {
            settingsRepository.setStartupAtAlbums(value)
        }
    }

    fun setMaterialYou(value: Boolean) {
        viewModelScope.launch {
            settingsRepository.setMaterialYou(value)
        }
    }

    fun setConfirmTrash(value: Boolean) {
        viewModelScope.launch {
            settingsRepository.setConfirmTrash(value)
        }
    }

    fun setConfirmDelete(value: Boolean) {
        viewModelScope.launch {
            settingsRepository.setConfirmDelete(value)
        }
    }

    fun addExcludedFolder(path: String) {
        viewModelScope.launch {
            settingsRepository.addExcludedFolder(path)
        }
    }

    fun removeExcludedFolder(path: String) {
        viewModelScope.launch {
            settingsRepository.removeExcludedFolder(path)
        }
    }

    fun addHiddenFolder(path: String) {
        viewModelScope.launch {
            settingsRepository.addHiddenFolder(path)
        }
    }

    fun removeHiddenFolder(path: String) {
        viewModelScope.launch {
            settingsRepository.removeHiddenFolder(path)
        }
    }

    fun setGridColumns(value: Int) {
        viewModelScope.launch {
            settingsRepository.setGridColumns(value)
        }
    }

    fun setRibbonOpen(value: Boolean) {
        viewModelScope.launch {
            settingsRepository.setRibbonOpen(value)
        }
    }

    fun setVideoMuted(value: Boolean) {
        viewModelScope.launch {
            settingsRepository.setVideoMuted(value)
        }
    }

    fun createNewAlbum(name: String) {
        viewModelScope.launch {
            val defaultPicturesDir = android.os.Environment.getExternalStoragePublicDirectory(android.os.Environment.DIRECTORY_PICTURES)
            val targetDir = java.io.File(defaultPicturesDir, name)
            if (!targetDir.exists()) {
                targetDir.mkdirs()
            }
            refresh()
        }
    }

    fun copyOrMoveMedia(
        entries: List<MediaEntry>,
        targetAlbumNameOrPath: String,
        isMove: Boolean,
        onComplete: (MediaFileOperationResult) -> Unit
    ) {
        viewModelScope.launch {
            val result = repository.copyOrMoveMedia(entries, targetAlbumNameOrPath, isMove)
            refresh()
            onComplete(result)
        }
    }
}
