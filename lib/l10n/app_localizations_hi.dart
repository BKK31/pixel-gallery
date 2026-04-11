// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'पिक्सेल गैलरी';

  @override
  String get settingsTitle => 'सेटिंग्स';

  @override
  String get settingsMaterialYou => 'मटीरियल यू';

  @override
  String get settingsMaterialYouDesc =>
      'वॉलपेपर से डायनेमिक रंगों का उपयोग करें';

  @override
  String get settingsStartupAlbums => 'एल्बम से स्टार्टअप';

  @override
  String get settingsStartupAlbumsDesc =>
      'फ़ोटो के बजाय एल्बम पेज पर शुरू करें';

  @override
  String get settingsExcludedFolders => 'बाहर रखे गए फोल्डर';

  @override
  String get settingsExcludedFoldersDesc => 'गैलरी से फोल्डर छिपाएं';

  @override
  String get settingsLicenses => 'ओपन सोर्स लाइसेंस';

  @override
  String get settingsLicensesDesc => 'क्रेडिट और लाइसेंस की जानकारी';

  @override
  String get settingsSourceCode => 'सोर्स कोड';

  @override
  String homeSelectedCount(int count) {
    return '$count चयनित';
  }

  @override
  String get homeShare => 'शेयर करें';

  @override
  String get homeDelete => 'हटाएं';

  @override
  String get homeLock => 'लॉक किए गए फोल्डर में ले जाएं';

  @override
  String get homeHiddenAlbums => 'छिपे हुए एल्बम';

  @override
  String get homeLockedFolder => 'लॉक किया गया फोल्डर';

  @override
  String get albumsFavourites => 'पसंदीदा';

  @override
  String get albumsBin => 'बिन';

  @override
  String albumsItemsCount(int count) {
    return '$count आइटम';
  }

  @override
  String albumsHiddenCount(int count) {
    return 'हाल ही के एल्बम से $count एल्बम छिपाए गए';
  }

  @override
  String albumsUnhiddenCount(int count) {
    return 'हाल ही के एल्बम से $count एल्बम वापस दिखाए गए';
  }

  @override
  String get albumsEmptySelection => 'चयनित एल्बम खाली हैं';

  @override
  String get albumsDeleteTitle => 'एल्बम की सामग्री हटाएं';

  @override
  String albumsDeleteContent(int photoCount, int albumCount) {
    return '$albumCount एल्बम से $photoCount फ़ोटो हटाएं?';
  }

  @override
  String get albumsDeleteWarning => 'फोल्डर खुद नहीं हटाया जाएगा।';

  @override
  String get moveToBin => 'Move to bin';

  @override
  String get moveToBinDesc => 'Items can be restored from the recycle bin';

  @override
  String get deletePermanentlyDesc => 'Items will be permanently deleted';

  @override
  String get cancel => 'रद्द करें';

  @override
  String get deletePermanently => 'स्थायी रूप से हटाएं';

  @override
  String albumsMovedToBin(int count) {
    return '$count आइटम ट्रैश में ले जाए गए';
  }

  @override
  String albumsPermDeletedCount(int count) {
    return 'स्थायी रूप से $count आइटम हटा दिए गए';
  }

  @override
  String get settingsLanguage => 'भाषा';

  @override
  String get settingsLanguageDesc => 'अपनी पसंदीदा भाषा चुनें';

  @override
  String get languageSystemDefault => 'सिस्टम डिफ़ॉल्ट';

  @override
  String get languageEnglish => 'अंग्रेज़ी';

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
