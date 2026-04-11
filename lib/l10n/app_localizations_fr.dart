// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Pixel Gallery';

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get settingsMaterialYou => 'Material You';

  @override
  String get settingsMaterialYouDesc =>
      'Utiliser les couleurs dynamiques du fond d\'écran';

  @override
  String get settingsStartupAlbums => 'Démarrer sur les albums';

  @override
  String get settingsStartupAlbumsDesc =>
      'Démarrer sur la page Albums au lieu de Photos';

  @override
  String get settingsExcludedFolders => 'Dossiers exclus';

  @override
  String get settingsExcludedFoldersDesc =>
      'Masquer des dossiers de la galerie';

  @override
  String get settingsLicenses => 'Licences open source';

  @override
  String get settingsLicensesDesc => 'Crédits et informations sur les licences';

  @override
  String get settingsSourceCode => 'Code source';

  @override
  String homeSelectedCount(int count) {
    return '$count sélectionnés';
  }

  @override
  String get homeShare => 'Partager';

  @override
  String get homeDelete => 'Supprimer';

  @override
  String get homeLock => 'Déplacer vers le dossier verrouillé';

  @override
  String get homeHiddenAlbums => 'Albums masqués';

  @override
  String get homeLockedFolder => 'Dossier verrouillé';

  @override
  String get albumsFavourites => 'Favoris';

  @override
  String get albumsBin => 'Corbeille';

  @override
  String albumsItemsCount(int count) {
    return '$count éléments';
  }

  @override
  String albumsHiddenCount(int count) {
    return '$count album(s) masqué(s) des récents';
  }

  @override
  String albumsUnhiddenCount(int count) {
    return '$count album(s) affiché(s) dans les récents';
  }

  @override
  String get albumsEmptySelection => 'Les albums sélectionnés sont vides';

  @override
  String get albumsDeleteTitle => 'Supprimer le contenu de l\'album';

  @override
  String albumsDeleteContent(int photoCount, int albumCount) {
    return 'Supprimer $photoCount photo(s) de $albumCount album(s) ?';
  }

  @override
  String get albumsDeleteWarning => 'Le dossier lui-même ne sera pas supprimé.';

  @override
  String get moveToBin => 'Move to bin';

  @override
  String get moveToBinDesc => 'Items can be restored from the recycle bin';

  @override
  String get deletePermanentlyDesc => 'Items will be permanently deleted';

  @override
  String get cancel => 'Annuler';

  @override
  String get deletePermanently => 'Supprimer définitivement';

  @override
  String albumsMovedToBin(int count) {
    return '$count élément(s) déplacé(s) vers la corbeille';
  }

  @override
  String albumsPermDeletedCount(int count) {
    return '$count élément(s) supprimé(s) définitivement';
  }

  @override
  String get settingsLanguage => 'Langue';

  @override
  String get settingsLanguageDesc => 'Choisissez votre langue préférée';

  @override
  String get languageSystemDefault => 'Par défaut du système';

  @override
  String get languageEnglish => 'Anglais';

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
