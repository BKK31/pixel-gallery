# Pixel Gallery

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

**Pixel Gallery** is a sleek, privacy-focused gallery application designed to provide a premium user experience. It leverages the power of **Material You** dynamic theming to adapt to your device's wallpaper, ensuring a seamless and personalized look. From managing your photo albums to viewing motion photos, Pixel Gallery creates a beautiful home for your memories.

## ✨ Features

- **🎨 Material You Design** - Fully adapts to your device's system colors (Android 12+).
- **📂 Smart Organization** - Automatically categorizes your media into Albums, Recents, and Videos.
- **🗑️ Recycle Bin** - Safely recover deleted photos and videos or permanently remove them.
- **🎞️ Motion Photos** - View the video component of your motion photos (Live Photos) locally.
- **⚡ Fast & Responsive** - Built with performance in mind using Flutter's rendering engine.
- **🔒 Privacy First** - Your photos stay on your device. No cloud uploads, no tracking.

## 📱 Screenshots

|                          Home Screen                           |                           Photo Viewer                            |                           Albums                            |                            Settings                             |
| :------------------------------------------------------------: | :---------------------------------------------------------------: | :---------------------------------------------------------: | :-------------------------------------------------------------: |
| <img src="screenshots/home.png" width="200" alt="Home Screen"> | <img src="screenshots/viewer.png" width="200" alt="Photo Viewer"> | <img src="screenshots/albums.png" width="200" alt="Albums"> | <img src="screenshots/settings.png" width="200" alt="Settings"> |

> _Note: Screenshots are placeholders. Please add actual screenshots to an `screenshots/` directory._

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

Distributed under the MIT License. See `LICENSE` for more information.
