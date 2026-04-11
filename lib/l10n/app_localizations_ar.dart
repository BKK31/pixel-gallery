// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'معرض بيكسل';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get settingsMaterialYou => 'ماتيريال يو';

  @override
  String get settingsMaterialYouDesc =>
      'استخدام ألوان ديناميكية من خلفية الشاشة';

  @override
  String get settingsStartupAlbums => 'البدء عند الألبومات';

  @override
  String get settingsStartupAlbumsDesc => 'ابدأ بصفحة الألبومات بدلاً من الصور';

  @override
  String get settingsExcludedFolders => 'المجلدات المستبعدة';

  @override
  String get settingsExcludedFoldersDesc => 'إخفاء المجلدات من المعرض';

  @override
  String get settingsLicenses => 'تراخيص المصادر المفتوحة';

  @override
  String get settingsLicensesDesc => 'بيانات المطورين ومعلومات الترخيص';

  @override
  String get settingsSourceCode => 'الكود المصدري';

  @override
  String homeSelectedCount(int count) {
    return 'تم تحديد $count';
  }

  @override
  String get homeShare => 'مشاركة';

  @override
  String get homeDelete => 'حذف';

  @override
  String get homeLock => 'نقل إلى المجلد المقفل';

  @override
  String get homeHiddenAlbums => 'الألبومات المخفية';

  @override
  String get homeLockedFolder => 'المجلد المقفل';

  @override
  String get albumsFavourites => 'المفضلة';

  @override
  String get albumsBin => 'سلة المهملات';

  @override
  String albumsItemsCount(int count) {
    return '$count عناصر';
  }

  @override
  String albumsHiddenCount(int count) {
    return 'تم إخفاء $count ألبوم(ألبومات) من الألبومات الحديثة';
  }

  @override
  String albumsUnhiddenCount(int count) {
    return 'تم إظهار $count ألبوم(ألبومات) من الألبومات الحديثة';
  }

  @override
  String get albumsEmptySelection => 'الألبومات المحددة فارغة';

  @override
  String get albumsDeleteTitle => 'حذف محتويات الألبوم';

  @override
  String albumsDeleteContent(int photoCount, int albumCount) {
    return 'حذف $photoCount صورة(صور) من $albumCount ألبوم(ألبومات)؟';
  }

  @override
  String get albumsDeleteWarning => 'لن يتم إزالة المجلد نفسه.';

  @override
  String get moveToBin => 'Move to bin';

  @override
  String get moveToBinDesc => 'Items can be restored from the recycle bin';

  @override
  String get deletePermanentlyDesc => 'Items will be permanently deleted';

  @override
  String get cancel => 'إلغاء';

  @override
  String get deletePermanently => 'حذف نهائيًا';

  @override
  String albumsMovedToBin(int count) {
    return 'تم نقل $count عنصر(عناصر) إلى المهملات';
  }

  @override
  String albumsPermDeletedCount(int count) {
    return 'تم حذف $count عنصر(عناصر) نهائيًا';
  }

  @override
  String get settingsLanguage => 'اللغة';

  @override
  String get settingsLanguageDesc => 'اختر لغتك المفضلة';

  @override
  String get languageSystemDefault => 'تلقائي حسب النظام';

  @override
  String get languageEnglish => 'الإنجليزية';

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
