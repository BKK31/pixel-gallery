// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Pixel Gallery';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsMaterialYou => 'Material You';

  @override
  String get settingsMaterialYouDesc => 'Use dynamic colors from wallpaper';

  @override
  String get settingsStartupAlbums => 'Startup at Albums';

  @override
  String get settingsStartupAlbumsDesc =>
      'Start on Albums page instead of Photos';

  @override
  String get settingsExcludedFolders => 'Excluded Folders';

  @override
  String get settingsExcludedFoldersDesc => 'Hide folders from the gallery';

  @override
  String get settingsLicenses => 'Open Source Licenses';

  @override
  String get settingsLicensesDesc => 'Credits and license information';

  @override
  String get settingsSourceCode => 'Source Code';

  @override
  String homeSelectedCount(int count) {
    return '$count Selected';
  }

  @override
  String get homeShare => 'Share';

  @override
  String get homeDelete => 'Delete';

  @override
  String get homeLock => 'Move to Locked Folder';

  @override
  String get homeHiddenAlbums => 'Hidden Albums';

  @override
  String get homeLockedFolder => 'Locked Folder';

  @override
  String get albumsFavourites => 'Favourites';

  @override
  String get albumsBin => 'Bin';

  @override
  String albumsItemsCount(int count) {
    return '$count items';
  }

  @override
  String albumsHiddenCount(int count) {
    return 'Hid $count album(s) from Recents';
  }

  @override
  String albumsUnhiddenCount(int count) {
    return 'Unhid $count album(s) from Recents';
  }

  @override
  String get albumsEmptySelection => 'Selected albums are empty';

  @override
  String get albumsDeleteTitle => 'Delete album contents';

  @override
  String albumsDeleteContent(int photoCount, int albumCount) {
    return 'Delete $photoCount photo(s) from $albumCount album(s)?';
  }

  @override
  String get albumsDeleteWarning => 'The folder itself will not be removed.';

  @override
  String get albumsMoveToBin => 'Move to bin';

  @override
  String get albumsBinDesc => 'Items can be restored from the recycle bin';

  @override
  String get albumsPermDeleteDesc => 'Items will be permanently deleted';

  @override
  String get cancel => 'Cancel';

  @override
  String get deletePermanently => 'Delete permanently';

  @override
  String albumsMovedToBin(int count) {
    return 'Moved $count item(s) to trash';
  }

  @override
  String albumsPermDeletedCount(int count) {
    return 'Permanently deleted $count item(s)';
  }

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageDesc => 'Choose your preferred language';

  @override
  String get languageSystemDefault => 'System Default';

  @override
  String get languageEnglish => 'English';
}
