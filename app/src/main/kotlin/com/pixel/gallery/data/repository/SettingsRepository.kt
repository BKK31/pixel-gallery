package com.pixel.gallery.data.repository

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.*
import androidx.datastore.preferences.preferencesDataStore
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import javax.inject.Inject
import javax.inject.Singleton

import androidx.datastore.preferences.SharedPreferencesMigration
import androidx.datastore.preferences.preferencesDataStore

private val Context.dataStore: DataStore<Preferences> by preferencesDataStore(
    name = "settings",
    produceMigrations = { context ->
        listOf(
            SharedPreferencesMigration(context, "FlutterSharedPreferences")
        )
    }
)

@Singleton
class SettingsRepository @Inject constructor(
    @ApplicationContext private val context: Context
) {
    private val STARTUP_AT_ALBUMS = booleanPreferencesKey("flutter.albums")
    private val MATERIAL_YOU = booleanPreferencesKey("flutter.material_you")

    val startupAtAlbums: Flow<Boolean> = context.dataStore.data
        .map { preferences -> preferences[STARTUP_AT_ALBUMS] ?: false }

    val materialYou: Flow<Boolean> = context.dataStore.data
        .map { preferences -> preferences[MATERIAL_YOU] ?: true }

    suspend fun setStartupAtAlbums(value: Boolean) {
        context.dataStore.edit { preferences ->
            preferences[STARTUP_AT_ALBUMS] = value
        }
    }

    suspend fun setMaterialYou(value: Boolean) {
        context.dataStore.edit { preferences ->
            preferences[MATERIAL_YOU] = value
        }
    }
}
