# Pixel Gallery

<p align="center">
  <img src="screenshots/logo.png" width="120" alt="Pixel Gallery Logo">
</p>

<p align="center">
  <b>A modern, open-source gallery app built for Android with Flutter.</b>
</p>

<p align="center">
  <a href="https://flutter.dev">
    <img src="https://img.shields.io/badge/Made%20with-Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Made with Flutter">
  </a>
  <a href="https://dart.dev">
    <img src="https://img.shields.io/badge/Language-Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Language Dart">
  </a>
  <a href="https://github.com/bkk31">
    <img src="https://img.shields.io/badge/Maintained%3F-yes-green.svg?style=for-the-badge" alt="Maintained">
  </a>
</p>

<p align="center">
  <a href="#features">Features</a> •
  <a href="#screenshots">Screenshots</a> •
  <a href="#installation">Installation</a> •
  <a href="#tech-stack">Tech Stack</a> •
  <a href="#contributing">Contributing</a> •
  <a href="#license">License</a>
</p>

---

## 📖 About

**Pixel Gallery** is a sleek, privacy-focused gallery application designed to provide a premium user experience. It leverages the power of **Material You** dynamic theming to adapt to your device's wallpaper, ensuring a seamless and personalized look. From managing your photo albums to viewing motion photos and map locations, Pixel Gallery creates a beautiful home for your memories.

## ✨ Features

- **🎨 Material You Design** - Fully adapts to your device's system colors (Android 12+).
- **📂 Smart Organization** - Automatically categorizes your media into Albums, Recents, and Videos.
- **🗑️ Recycle Bin** - Safely recover deleted photos and videos or permanently remove them.
- **🎞️ Motion Photos** - Detects and plays the video component of Motion Photos (Live Photos).
- **📍 Location Map** - View exactly where your photos were taken on an interactive OpenStreetMap.
- **📷 EXIF Details** - View detailed camera metadata (Model, Aperture, ISO, Shutter Speed).
- **⚡ Fast & Responsive** - Built with performance in mind using Flutter's rendering engine.
- **🔒 Privacy First** - Your photos stay on your device. No cloud uploads, no tracking.

## 📱 Screenshots

|                              Home Screen                              |                               Photos Screen                               |                               Albums                               |
| :-------------------------------------------------------------------: | :-----------------------------------------------------------------------: | :----------------------------------------------------------------: |
| <img src="screenshots/home_screen.png" width="200" alt="Home Screen"> | <img src="screenshots/photos_screen.png" width="200" alt="Photos Screen"> | <img src="screenshots/albums_screen.png" width="200" alt="Albums"> |

|                               Viewer Screen                               |                                 Recycle Bin                                  |                                Settings                                |
| :-----------------------------------------------------------------------: | :--------------------------------------------------------------------------: | :--------------------------------------------------------------------: |
| <img src="screenshots/viewer_screen.png" width="200" alt="Viewer Screen"> | <img src="screenshots/recycle_bin_screen.png" width="200" alt="Recycle Bin"> | <img src="screenshots/settings_screen.png" width="200" alt="Settings"> |

## 📸 Credits

Sample photos used in screenshots are by the following authors on Unsplash:

- [Ispywithmylittleeye](https://unsplash.com/@ispywithmylittleeye)
- [Khouser01](https://unsplash.com/@khouser01)
- [Teodor Drobota](https://unsplash.com/@teodordrobota)
- [Wulcan](https://unsplash.com/@wulcan)
- [Sardar Kamran](https://unsplash.com/@sardarkamran128)
- [Fermin Rodriguez Penelas](https://unsplash.com/@ferminrp)
- [Ivan Diaz](https://unsplash.com/@ivvndiaz)
- [Gilley Aguilar](https://unsplash.com/@gilleyaguilar)
- [NordWood Themes](https://unsplash.com/@nl_lehmann)
- [Studio Mike Franca](https://unsplash.com/@studiomikefranca)
- [Chandu 029](https://unsplash.com/@chandu029)
- [Hanna Plants](https://unsplash.com/@hanna_plants)
- [Joshua Kettle](https://unsplash.com/@joshuakettle)

## 🛠 Installation

To run Pixel Gallery locally, you'll need [Flutter](https://flutter.dev/docs/get-started/install) installed.

1.  **Clone the repository:**

    ```bash
    git clone https://github.com/bkk31/pixel-gallery.git
    cd pixel-gallery
    ```

2.  **Install dependencies:**

    ```bash
    flutter pub get
    ```

3.  **Run the app:**
    ```bash
    flutter run
    ```

## 🏗 Tech Stack

Pixel Gallery is built with a curated list of top-tier libraries:

- [**Flutter**](https://flutter.dev) - UI Toolkit.
- [**photo_manager**](https://pub.dev/packages/photo_manager) - Advanced asset management.
- [**dynamic_color**](https://pub.dev/packages/dynamic_color) - Material You theming.
- [**video_player**](https://pub.dev/packages/video_player) - Video playback support.
- [**photo_view**](https://pub.dev/packages/photo_view) - Zoomable image viewer.
- [**flutter_map**](https://pub.dev/packages/flutter_map) + [**latlong2**](https://pub.dev/packages/latlong2) - OpenStreetMap integration.
- [**native_exif**](https://pub.dev/packages/native_exif) - Efficient EXIF metadata reading.
- [**motion_photos**](https://pub.dev/packages/motion_photos) - Motion photo extracting.
- [**share_plus**](https://pub.dev/packages/share_plus) - Native sharing capabilities.
- [**intl**](https://pub.dev/packages/intl) - Internationalization and date formatting.

## 🤝 Contributing

Contributions are welcome! If you have suggestions or want to report a bug, please open an issue or submit a pull request.

1.  Fork the repository.
2.  Create your feature branch (`git checkout -b feature/amazing-feature`).
3.  Commit your changes (`git commit -m 'Add some amazing feature'`).
4.  Push to the branch (`git push origin feature/amazing-feature`).
5.  Open a Pull Request.

## 📄 License

Distributed under the GNU Public License GPL-3. See `LICENSE` for more information.
