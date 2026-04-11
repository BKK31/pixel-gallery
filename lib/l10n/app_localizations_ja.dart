// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'Pixel ギャラリー';

  @override
  String get settingsTitle => '設定';

  @override
  String get settingsMaterialYou => 'Material You';

  @override
  String get settingsMaterialYouDesc => '壁紙のダイナミックカラーを使用する';

  @override
  String get settingsStartupAlbums => '起動時にアルバムを表示';

  @override
  String get settingsStartupAlbumsDesc => '写真ではなくアルバムページを最初に表示します';

  @override
  String get settingsExcludedFolders => '除外設定';

  @override
  String get settingsExcludedFoldersDesc => 'ギャラリーに表示しないフォルダを選択します';

  @override
  String get settingsLicenses => 'オープンソースライセンス';

  @override
  String get settingsLicensesDesc => 'クレジットとライセンス情報';

  @override
  String get settingsSourceCode => 'ソースコード';

  @override
  String homeSelectedCount(int count) {
    return '$count 件選択中';
  }

  @override
  String get homeShare => '共有';

  @override
  String get homeDelete => '削除';

  @override
  String get homeLock => 'ロックされたフォルダに移動';

  @override
  String get homeHiddenAlbums => '非表示のアルバム';

  @override
  String get homeLockedFolder => 'ロックされたフォルダ';

  @override
  String get albumsFavourites => 'お気に入り';

  @override
  String get albumsBin => 'ゴミ箱';

  @override
  String albumsItemsCount(int count) {
    return '$count 個のアイテム';
  }

  @override
  String albumsHiddenCount(int count) {
    return '「最近」から $count 個のアルバムを非表示にしました';
  }

  @override
  String albumsUnhiddenCount(int count) {
    return '「最近」から $count 個のアルバムを再表示しました';
  }

  @override
  String get albumsEmptySelection => '選択されたアルバムは空です';

  @override
  String get albumsDeleteTitle => 'アルバムの内容を削除';

  @override
  String albumsDeleteContent(int photoCount, int albumCount) {
    return '$albumCount 個のアルバムから $photoCount 枚の写真を削除しますか？';
  }

  @override
  String get albumsDeleteWarning => 'フォルダ自体は削除されません。';

  @override
  String get moveToBin => 'Move to bin';

  @override
  String get moveToBinDesc => 'Items can be restored from the recycle bin';

  @override
  String get deletePermanentlyDesc => 'Items will be permanently deleted';

  @override
  String get cancel => 'キャンセル';

  @override
  String get deletePermanently => '完全に削除';

  @override
  String albumsMovedToBin(int count) {
    return '$count 個のアイテムをゴミ箱に移動しました';
  }

  @override
  String albumsPermDeletedCount(int count) {
    return '$count 個のアイテムを完全に削除しました';
  }

  @override
  String get settingsLanguage => '言語';

  @override
  String get settingsLanguageDesc => '使用する言語を選択します';

  @override
  String get languageSystemDefault => 'システムのデフォルト';

  @override
  String get languageEnglish => '英語';

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
