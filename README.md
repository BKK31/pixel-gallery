# Pixel Gallery (Native)

A high-performance, modern Android gallery application built entirely with **Kotlin** and **Jetpack Compose**.

This is the native port of the original Pixel Gallery, designed to provide a seamless, system-integrated experience for managing photos and videos.

## ✨ Features

-   **Native MediaStore Integration**: Fast, direct access to device media using the latest Android APIs.
-   **Full-Screen Media Viewer**: Smooth panning, zooming (via Telephoto), and native video playback (via Media3/ExoPlayer).
-   **Interactive Organization**: View media by Recents or grouped into Albums.
-   **Recycle Bin**: Full support for Android's native Trash API—move items to the bin and restore them with ease.
-   **Favourites**: Keep track of your best moments in a dedicated collection.
-   **Multi-Selection**: Long-press to select multiple items for bulk sharing, trashing, or permanent deletion.
-   **Modern Design**: Built with **Material 3 Expressive** components, featuring support for **Material You** dynamic coloring.
-   **Privacy Focused**: Native support for **Locked Folders** and biometric security.

## 🛠 Tech Stack

-   **UI**: Jetpack Compose (Material 3)
-   **Architecture**: MVVM with Clean Architecture principles
-   **Dependency Injection**: Hilt
-   **Database**: Room (for local metadata and collections)
-   **Preference Storage**: DataStore
-   **Image Loading**: Glide
-   **Video Playback**: Media3 / ExoPlayer

## 🚀 Getting Started

### Migration from Flutter

If you are updating from the original Flutter version of Pixel Gallery:

1.  **Media**: Your photos and videos are safe. The native app will scan and display them automatically.
2.  **Settings**: Your preferences (like "Startup at Albums" and "Material You") will be automatically migrated to the new format on first launch.
3.  **Recycle Bin**: **CRITICAL.** The native app uses the Android System Trash API, which is different from the Flutter version's internal bin. **Please "Restore" any items in the Flutter Recycle Bin before installing this update.**
4.  **Favourites**: Due to database schema changes, your marked favourites will be reset. You will need to re-favourite your items in the new app.

### Prerequisites

-   Android Studio Ladybug or newer
-   JDK 17+
-   Android SDK 35 (Compile SDK)

### Building

1.  Clone the repository:
    ```bash
    git clone https://github.com/bkk31/pixel-gallery.git
    cd pixel-gallery
    git checkout native-port
    ```
2.  Build the debug APK:
    ```bash
    ./gradlew assembleDebug
    ```
3.  Install and Run:
    ```bash
    ./gradlew installDebug && adb shell am start -n com.pixel.gallery/.MainActivity
    ```

## 📄 License

This project is licensed under the Apache License 2.0. See the [LICENSE](LICENSE) file for details.
