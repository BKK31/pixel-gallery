// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Pixel Galerie';

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get settingsMaterialYou => 'Material You';

  @override
  String get settingsMaterialYouDesc =>
      'Dynamische Farben vom Hintergrundbild verwenden';

  @override
  String get settingsStartupAlbums => 'Alben beim Start';

  @override
  String get settingsStartupAlbumsDesc =>
      'Auf der Alben-Seite anstatt bei Fotos starten';

  @override
  String get settingsExcludedFolders => 'Ausgeschlossene Ordner';

  @override
  String get settingsExcludedFoldersDesc => 'Ordner in der Galerie ausblenden';

  @override
  String get settingsLicenses => 'Open-Source-Lizenzen';

  @override
  String get settingsLicensesDesc => 'Danksagungen und Lizenzinformationen';

  @override
  String get settingsSourceCode => 'Quellcode';

  @override
  String homeSelectedCount(int count) {
    return '$count ausgewählt';
  }

  @override
  String get homeShare => 'Teilen';

  @override
  String get homeDelete => 'Löschen';

  @override
  String get homeLock => 'In gesperrten Ordner verschieben';

  @override
  String get homeHiddenAlbums => 'Ausgeblendete Alben';

  @override
  String get homeLockedFolder => 'Gesperrter Ordner';

  @override
  String get albumsFavourites => 'Favoriten';

  @override
  String get albumsBin => 'Papierkorb';

  @override
  String albumsItemsCount(int count) {
    return '$count Elemente';
  }

  @override
  String albumsHiddenCount(int count) {
    return '$count Album/Alben aus \'Zuletzt\' ausgeblendet';
  }

  @override
  String albumsUnhiddenCount(int count) {
    return '$count Album/Alben in \'Zuletzt\' eingeblendet';
  }

  @override
  String get albumsEmptySelection => 'Ausgewählte Alben sind leer';

  @override
  String get albumsDeleteTitle => 'Albuminhalte löschen';

  @override
  String albumsDeleteContent(int photoCount, int albumCount) {
    return '$photoCount Foto(s) aus $albumCount Album/Alben löschen?';
  }

  @override
  String get albumsDeleteWarning => 'Der Ordner selbst wird nicht gelöscht.';

  @override
  String get moveToBin => 'Move to bin';

  @override
  String get moveToBinDesc => 'Items can be restored from the recycle bin';

  @override
  String get deletePermanentlyDesc => 'Items will be permanently deleted';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get deletePermanently => 'Endgültig löschen';

  @override
  String albumsMovedToBin(int count) {
    return '$count Element(e) in den Papierkorb verschoben';
  }

  @override
  String albumsPermDeletedCount(int count) {
    return '$count Element(e) endgültig gelöscht';
  }

  @override
  String get settingsLanguage => 'Sprache';

  @override
  String get settingsLanguageDesc => 'Wähle deine bevorzugte Sprache';

  @override
  String get languageSystemDefault => 'Systemstandard';

  @override
  String get languageEnglish => 'Englisch';

  @override
  String get deleteItems => 'Delete items';

  @override
  String deleteSelectedCount(int count) {
    return 'Delete $count selected item(s)?';
  }

  @override
  String get movedToTrashSnackbar => 'Moved selected items to trash';

  @override
  String get deletedPermanentlySnackbar => 'Permanently deleted selected items';

  @override
  String movedToLockedFolderSnackbar(int count) {
    return 'Moved $count item(s) to Locked Folder';
  }

  @override
  String photosCount(int count) {
    return '$count photos';
  }

  @override
  String get deletePhoto => 'Delete photo';

  @override
  String get deletePhotoDesc => 'What would you like to do with this photo?';

  @override
  String get restoredToGallery => 'Restored to gallery';

  @override
  String get failedToRestore => 'Failed to restore';

  @override
  String get failedToMoveToLocked => 'Failed to move to Locked Folder';

  @override
  String get failedToLaunchEditor => 'Failed to launch editor';

  @override
  String get wallpaperSetSuccess => 'Wallpaper set successfully';

  @override
  String get wallpaperSetFailed => 'Failed to set wallpaper';

  @override
  String get homeScreen => 'Home Screen';

  @override
  String get lockScreen => 'Lock Screen';

  @override
  String get bothScreens => 'Both';

  @override
  String get details => 'Details';

  @override
  String get unknown => 'Unknown';

  @override
  String get cameraInfo => 'Camera Info';

  @override
  String get camera => 'Camera';

  @override
  String get exifSettings => 'Settings';

  @override
  String get location => 'Location';

  @override
  String get removeFromLockedFolder => 'Remove from Locked Folder';

  @override
  String get moveToLockedFolder => 'Move to Locked Folder';

  @override
  String get setAsWallpaper => 'Set as wallpaper';

  @override
  String get recycleBin => 'Recycle Bin';

  @override
  String get recycleBinEmpty => 'Recycle Bin is empty';

  @override
  String restoredCount(int count) {
    return 'Restored $count items';
  }

  @override
  String restoredCountWithFail(int successCount, int failCount) {
    return 'Restored $successCount items, failed $failCount';
  }

  @override
  String daysRemaining(int count) {
    return '${count}d';
  }

  @override
  String get lockedFolderNoItems => 'No locked items';

  @override
  String get lockedFolderDesc =>
      'Move photos here from the viewer to hide them behind biometric lock';

  @override
  String lockedItemsCount(int count) {
    return '$count locked items';
  }

  @override
  String get movingFiles => 'Moving files…';

  @override
  String get uninstallWarning =>
      'Uninstalling the app will permanently delete locked files.';

  @override
  String get addToAlbum => 'Add to Album';

  @override
  String addToSpecificAlbum(String albumName) {
    return 'Add to $albumName';
  }

  @override
  String get moveOrCopyDesc =>
      'Do you want to move or copy the selected items?';

  @override
  String get copy => 'Copy';

  @override
  String get move => 'Move';

  @override
  String get createNewAlbum => 'Create New Album';

  @override
  String get albumName => 'Album Name';

  @override
  String get albumNameHint => 'e.g. Vacation';

  @override
  String get create => 'Create';

  @override
  String get movingItems => 'Moving items...';

  @override
  String get copyingItems => 'Copying items...';

  @override
  String moveSuccessCount(int count) {
    return 'Successfully moved $count items.';
  }

  @override
  String copySuccessCount(int count) {
    return 'Successfully copied $count items.';
  }

  @override
  String get errorCreateAlbum =>
      'Failed to create album folder. Check permissions.';

  @override
  String get noHiddenAlbums => 'No hidden albums';

  @override
  String get hiddenAlbumsDesc => 'Long-press an album to hide it from Recents';

  @override
  String get unhideSelected => 'Unhide selected';

  @override
  String get hideSelected => 'Hide selected';

  @override
  String get deleteContents => 'Delete contents';

  @override
  String get excludeFolder => 'Exclude Folder';

  @override
  String get folderExcluded => 'Folder excluded';

  @override
  String get noFavourites => 'No favourites yet';

  @override
  String favouritesCount(int count) {
    return '$count favourites';
  }
}
