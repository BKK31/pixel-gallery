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

    val photos: StateFlow<List<MediaEntry>> = repository.allEntries
        .stateIn(viewModelScope, SharingStarted.Lazily, emptyList())

    val favourites: StateFlow<List<MediaEntry>> = repository.favourites
        .stateIn(viewModelScope, SharingStarted.Lazily, emptyList())

    val trashedMedia: StateFlow<List<MediaEntry>> = repository.trash
        .stateIn(viewModelScope, SharingStarted.Lazily, emptySet())
        .map { it.toList() } // Compatibility
        .stateIn(viewModelScope, SharingStarted.Lazily, emptyList())

    val startupAtAlbums: StateFlow<Boolean> = settingsRepository.startupAtAlbums
        .stateIn(viewModelScope, SharingStarted.Eagerly, false)

    val materialYou: StateFlow<Boolean> = settingsRepository.materialYou
        .stateIn(viewModelScope, SharingStarted.Eagerly, true)

    val albums: StateFlow<List<Album>> = repository.allEntries
        .map { photos ->
            photos.groupBy { 
                val file = java.io.File(it.path)
                file.parentFile?.name ?: "Unknown"
            }.map { (name, entries) ->
                Album(name, entries.first().uri, entries.size)
            }.sortedBy { it.name }
        }
        .stateIn(viewModelScope, SharingStarted.Lazily, emptyList())

    init {
        refresh()
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
}
