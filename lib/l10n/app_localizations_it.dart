// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'Pixel Gallery';

  @override
  String get settingsTitle => 'Impostazioni';

  @override
  String get settingsMaterialYou => 'Material You';

  @override
  String get settingsMaterialYouDesc => 'Usa i colori dinamici dello sfondo';

  @override
  String get settingsStartupAlbums => 'Avvio su Album';

  @override
  String get settingsStartupAlbumsDesc =>
      'Avvia nella pagina Album invece di Foto';

  @override
  String get settingsExcludedFolders => 'Cartelle Escluse';

  @override
  String get settingsExcludedFoldersDesc => 'Nascondi cartelle dalla galleria';

  @override
  String get settingsLicenses => 'Licenze Open Source';

  @override
  String get settingsLicensesDesc => 'Crediti e informazioni sulla licenza';

  @override
  String get settingsSourceCode => 'Codice Sorgente';

  @override
  String homeSelectedCount(int count) {
    return '$count Selezionati';
  }

  @override
  String get homeShare => 'Condividi';

  @override
  String get homeDelete => 'Elimina';

  @override
  String get homeLock => 'Sposta nella Cartella Protetta';

  @override
  String get homeHiddenAlbums => 'Album Nascosti';

  @override
  String get homeLockedFolder => 'Cartella Protetta';

  @override
  String get albumsFavourites => 'Preferiti';

  @override
  String get albumsBin => 'Cestino';

  @override
  String albumsItemsCount(int count) {
    return '$count elementi';
  }

  @override
  String albumsHiddenCount(int count) {
    return 'Nascosti $count album dai Recenti';
  }

  @override
  String albumsUnhiddenCount(int count) {
    return 'Rivelati $count album dai Recenti';
  }

  @override
  String get albumsEmptySelection => 'Gli album selezionati sono vuoti';

  @override
  String get albumsDeleteTitle => 'Elimina contenuto album';

  @override
  String albumsDeleteContent(int photoCount, int albumCount) {
    return 'Eliminare $photoCount foto da $albumCount album?';
  }

  @override
  String get albumsDeleteWarning => 'La cartella stessa non verrà rimossa.';

  @override
  String get moveToBin => 'Move to bin';

  @override
  String get moveToBinDesc => 'Items can be restored from the recycle bin';

  @override
  String get deletePermanentlyDesc => 'Items will be permanently deleted';

  @override
  String get cancel => 'Annulla';

  @override
  String get deletePermanently => 'Elimina permanentemente';

  @override
  String albumsMovedToBin(int count) {
    return 'Spostati $count elementi nel cestino';
  }

  @override
  String albumsPermDeletedCount(int count) {
    return 'Eliminati permanentemente $count elementi';
  }

  @override
  String get settingsLanguage => 'Lingua';

  @override
  String get settingsLanguageDesc => 'Scegli la tua lingua preferita';

  @override
  String get languageSystemDefault => 'Predefinito di sistema';

  @override
  String get languageEnglish => 'Inglese';

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
