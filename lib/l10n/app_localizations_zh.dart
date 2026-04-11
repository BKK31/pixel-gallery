// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Pixel 相册';

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsMaterialYou => 'Material You';

  @override
  String get settingsMaterialYouDesc => '使用壁纸中的动态颜色';

  @override
  String get settingsStartupAlbums => '启动时显示相册';

  @override
  String get settingsStartupAlbumsDesc => '启动时打开相册页而非照片页';

  @override
  String get settingsExcludedFolders => '排除的文件夹';

  @override
  String get settingsExcludedFoldersDesc => '从相册中隐藏文件夹';

  @override
  String get settingsLicenses => '开源许可';

  @override
  String get settingsLicensesDesc => '鸣谢及许可信息';

  @override
  String get settingsSourceCode => '源代码';

  @override
  String homeSelectedCount(int count) {
    return '已选择 $count 项';
  }

  @override
  String get homeShare => '分享';

  @override
  String get homeDelete => '删除';

  @override
  String get homeLock => '移动到锁定文件夹';

  @override
  String get homeHiddenAlbums => '隐藏的相册';

  @override
  String get homeLockedFolder => '锁定文件夹';

  @override
  String get albumsFavourites => '收藏';

  @override
  String get albumsBin => '回收站';

  @override
  String albumsItemsCount(int count) {
    return '$count 个项目';
  }

  @override
  String albumsHiddenCount(int count) {
    return '已从“最近”中隐藏 $count 个相册';
  }

  @override
  String albumsUnhiddenCount(int count) {
    return '已从“最近”中取消隐藏 $count 个相册';
  }

  @override
  String get albumsEmptySelection => '选中的相册为空';

  @override
  String get albumsDeleteTitle => '删除相册内容';

  @override
  String albumsDeleteContent(int photoCount, int albumCount) {
    return '从 $albumCount 个相册中删除 $photoCount 张照片？';
  }

  @override
  String get albumsDeleteWarning => '文件夹本身不会被删除。';

  @override
  String get moveToBin => 'Move to bin';

  @override
  String get moveToBinDesc => 'Items can be restored from the recycle bin';

  @override
  String get deletePermanentlyDesc => 'Items will be permanently deleted';

  @override
  String get cancel => '取消';

  @override
  String get deletePermanently => '永久删除';

  @override
  String albumsMovedToBin(int count) {
    return '已将 $count 个项目移至回收站';
  }

  @override
  String albumsPermDeletedCount(int count) {
    return '已永久删除 $count 个项目';
  }

  @override
  String get settingsLanguage => '语言';

  @override
  String get settingsLanguageDesc => '选择您的首选语言';

  @override
  String get languageSystemDefault => '系统默认';

  @override
  String get languageEnglish => '英语';

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
