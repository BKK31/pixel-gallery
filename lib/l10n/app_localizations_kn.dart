// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Kannada (`kn`).
class AppLocalizationsKn extends AppLocalizations {
  AppLocalizationsKn([String locale = 'kn']) : super(locale);

  @override
  String get appTitle => 'ಪಿಕ್ಸೆಲ್ ಗ್ಯಾಲರಿ';

  @override
  String get settingsTitle => 'ಸೆಟ್ಟಿಂಗ್ಸ್';

  @override
  String get settingsMaterialYou => 'ಮೆಟೀರಿಯಲ್ ಯೂ';

  @override
  String get settingsMaterialYouDesc =>
      'ವಾಲ್‌ಪೇಪರ್‌ನಿಂದ ಡೈನಾಮಿಕ್ ಬಣ್ಣಗಳನ್ನು ಬಳಸಿ';

  @override
  String get settingsStartupAlbums => 'ಆಲ್ಬಮ್‌ಗಳಲ್ಲಿ ಪ್ರಾರಂಭಿಸಿ';

  @override
  String get settingsStartupAlbumsDesc =>
      'ಫೋಟೋಗಳ ಬದಲಿಗೆ ಆಲ್ಬಮ್‌ಗಳ ಪುಟದಲ್ಲಿ ಪ್ರಾರಂಭಿಸಿ';

  @override
  String get settingsExcludedFolders => 'ಹೊರಗಿಡಲಾದ ಫೋಲ್ಡರ್‌ಗಳು';

  @override
  String get settingsExcludedFoldersDesc =>
      'ಗ್ಯಾಲರಿಯಿಂದ ಫೋಲ್ಡರ್‌ಗಳನ್ನು ಮರೆಮಾಡಿ';

  @override
  String get settingsLicenses => 'ಓಪನ್ ಸೋರ್ಸ್ ಪರವಾನಗಿಗಳು';

  @override
  String get settingsLicensesDesc => 'ಕ್ರೆಡಿಟ್ಸ್ ಮತ್ತು ಪರವಾನಗಿ ಮಾಹಿತಿ';

  @override
  String get settingsSourceCode => 'ಸೋರ್ಸ್ ಕೋಡ್';

  @override
  String homeSelectedCount(int count) {
    return '$count ಆಯ್ಕೆ ಮಾಡಲಾಗಿದೆ';
  }

  @override
  String get homeShare => 'ಹಂಚಿಕೊಳ್ಳಿ';

  @override
  String get homeDelete => 'ಅಳಿಸಿ';

  @override
  String get homeLock => 'ಲಾಕ್ ಮಾಡಲಾದ ಫೋಲ್ಡರ್‌ಗೆ ಸರಿಸಿ';

  @override
  String get homeHiddenAlbums => 'ಮರೆಮಾಡಿದ ಆಲ್ಬಮ್‌ಗಳು';

  @override
  String get homeLockedFolder => 'ಲಾಕ್ ಮಾಡಲಾದ ಫೋಲ್ಡರ್';

  @override
  String get albumsFavourites => 'ಮೆಚ್ಚಿನವುಗಳು';

  @override
  String get albumsBin => 'ಬಿನ್';

  @override
  String albumsItemsCount(int count) {
    return '$count ಐಟಂಗಳು';
  }

  @override
  String albumsHiddenCount(int count) {
    return 'ಇತ್ತೀಚಿನವುಗಳಿಂದ $count ಆಲ್ಬಮ್‌(ಗಳನ್ನು) ಮರೆಮಾಡಲಾಗಿದೆ';
  }

  @override
  String albumsUnhiddenCount(int count) {
    return 'ಇತ್ತೀಚಿನವುಗಳಿಂದ $count ಆಲ್ಬಮ್‌(ಗಳನ್ನು) ತೋರಿಸಲಾಗಿದೆ';
  }

  @override
  String get albumsEmptySelection => 'ಆಯ್ಕೆ ಮಾಡಿದ ಆಲ್ಬಮ್‌ಗಳು ಖಾಲಿಯಾಗಿವೆ';

  @override
  String get albumsDeleteTitle => 'ಆಲ್ಬಮ್ ವಿಷಯಗಳನ್ನು ಅಳಿಸಿ';

  @override
  String albumsDeleteContent(int photoCount, int albumCount) {
    return '$albumCount ಆಲ್ಬಮ್‌(ಗಳಿಂದ) $photoCount ಫೋಟೋ(ಗಳನ್ನು) ಅಳಿಸುವುದೇ?';
  }

  @override
  String get albumsDeleteWarning => 'ಫೋಲ್ಡರ್ ಅನ್ನು ತೆಗೆದುಹಾಕಲಾಗುವುದಿಲ್ಲ.';

  @override
  String get moveToBin => 'Move to bin';

  @override
  String get moveToBinDesc => 'Items can be restored from the recycle bin';

  @override
  String get deletePermanentlyDesc => 'Items will be permanently deleted';

  @override
  String get cancel => 'ರದ್ದುಮಾಡಿ';

  @override
  String get deletePermanently => 'ಶಾಶ್ವತವಾಗಿ ಅಳಿಸಿ';

  @override
  String albumsMovedToBin(int count) {
    return '$count ಐಟಂ(ಗಳನ್ನು) ಕಸದ ಬುಟ್ಟಿಗೆ ಸರಿಸಲಾಗಿದೆ';
  }

  @override
  String albumsPermDeletedCount(int count) {
    return '$count ಐಟಂ(ಗಳನ್ನು) ಶಾಶ್ವತವಾಗಿ ಅಳಿಸಲಾಗಿದೆ';
  }

  @override
  String get settingsLanguage => 'ಭಾಷೆ';

  @override
  String get settingsLanguageDesc => 'ನಿಮ್ಮ ಆದ್ಯತೆಯ ಭಾಷೆಯನ್ನು ಆರಿಸಿ';

  @override
  String get languageSystemDefault => 'ಸಿಸ್ಟಮ್ ಡೀಫಾಲ್ಟ್';

  @override
  String get languageEnglish => 'ಇಂಗ್ಲೀಷ್';

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
