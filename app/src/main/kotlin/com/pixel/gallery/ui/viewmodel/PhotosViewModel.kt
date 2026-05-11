package com.pixel.gallery.ui.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.pixel.gallery.data.local.entity.MediaEntry
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

    data class ExternalMedia(val uri: String, val mimeType: String)

    private val _externalMedia = MutableStateFlow<ExternalMedia?>(null)
    val externalMedia: StateFlow<ExternalMedia?> = _externalMedia

    fun setExternalMediaUri(uri: String?, mimeType: String? = null) {
        if (uri != null) {
            _externalMedia.value = ExternalMedia(uri, mimeType ?: "image/*")
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
        }
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
        .stateIn(viewModelScope, SharingStarted.Lazily, emptyList())

    val groupedFavourites: StateFlow<List<GridItem>> = combine(favourites, gridColumns) { media, cols ->
        groupMedia(media, cols)
    }.stateIn(viewModelScope, SharingStarted.Lazily, emptyList())

    val trashedMedia: StateFlow<List<MediaEntry>> = repository.trash
        .stateIn(viewModelScope, SharingStarted.Lazily, emptySet())
        .map { it.toList() } // Compatibility
        .stateIn(viewModelScope, SharingStarted.Lazily, emptyList())

    val groupedTrashedMedia: StateFlow<List<GridItem>> = combine(trashedMedia, gridColumns) { media, cols ->
        groupMedia(media, cols)
    }.stateIn(viewModelScope, SharingStarted.Lazily, emptyList())

    val vaultEntries: StateFlow<List<MediaEntry>> = repository.vaultEntries
        .stateIn(viewModelScope, SharingStarted.Lazily, emptyList())

    val groupedVaultEntries: StateFlow<List<GridItem>> = combine(vaultEntries, gridColumns) { media, cols ->
        groupMedia(media, cols)
    }.stateIn(viewModelScope, SharingStarted.Lazily, emptyList())

    val startupAtAlbums: StateFlow<Boolean> = settingsRepository.startupAtAlbums
        .stateIn(viewModelScope, SharingStarted.Eagerly, false)

    val materialYou: StateFlow<Boolean> = settingsRepository.materialYou
        .stateIn(viewModelScope, SharingStarted.Eagerly, true)

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

    fun refresh() {
        viewModelScope.launch {
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
                refresh()
            }
        }
    }

    fun restoreMedia(id: Long, uri: String) {
        viewModelScope.launch {
            repository.restoreMedia(id, uri)
        }
    }

    fun restoreMediaBulk(uris: List<String>) {
        viewModelScope.launch {
            if (repository.restoreMediaBulk(uris)) {
                refresh()
            }
        }
    }

    fun moveToVault(entry: MediaEntry) {
        viewModelScope.launch {
            if (repository.moveToVault(entry)) {
                refresh()
            }
        }
    }

    fun restoreFromVault(id: Long) {
        viewModelScope.launch {
            if (repository.restoreFromVault(id)) {
                refresh()
            }
        }
    }

    fun deleteMediaBulk(uris: List<String>) {
        viewModelScope.launch {
            if (repository.deleteMediaBulk(uris)) {
                refresh()
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
}
