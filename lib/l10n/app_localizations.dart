import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_it.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_kn.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('hi'),
    Locale('it'),
    Locale('ja'),
    Locale('kn'),
    Locale('pt'),
    Locale('ru'),
    Locale('zh'),
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'Pixel Gallery'**
  String get appTitle;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsMaterialYou.
  ///
  /// In en, this message translates to:
  /// **'Material You'**
  String get settingsMaterialYou;

  /// No description provided for @settingsMaterialYouDesc.
  ///
  /// In en, this message translates to:
  /// **'Use dynamic colors from wallpaper'**
  String get settingsMaterialYouDesc;

  /// No description provided for @settingsStartupAlbums.
  ///
  /// In en, this message translates to:
  /// **'Startup at Albums'**
  String get settingsStartupAlbums;

  /// No description provided for @settingsStartupAlbumsDesc.
  ///
  /// In en, this message translates to:
  /// **'Start on Albums page instead of Photos'**
  String get settingsStartupAlbumsDesc;

  /// No description provided for @settingsExcludedFolders.
  ///
  /// In en, this message translates to:
  /// **'Excluded Folders'**
  String get settingsExcludedFolders;

  /// No description provided for @settingsExcludedFoldersDesc.
  ///
  /// In en, this message translates to:
  /// **'Hide folders from the gallery'**
  String get settingsExcludedFoldersDesc;

  /// No description provided for @settingsLicenses.
  ///
  /// In en, this message translates to:
  /// **'Open Source Licenses'**
  String get settingsLicenses;

  /// No description provided for @settingsLicensesDesc.
  ///
  /// In en, this message translates to:
  /// **'Credits and license information'**
  String get settingsLicensesDesc;

  /// No description provided for @settingsSourceCode.
  ///
  /// In en, this message translates to:
  /// **'Source Code'**
  String get settingsSourceCode;

  /// No description provided for @homeSelectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Selected'**
  String homeSelectedCount(int count);

  /// No description provided for @homeShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get homeShare;

  /// No description provided for @homeDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get homeDelete;

  /// No description provided for @homeLock.
  ///
  /// In en, this message translates to:
  /// **'Move to Locked Folder'**
  String get homeLock;

  /// No description provided for @homeHiddenAlbums.
  ///
  /// In en, this message translates to:
  /// **'Hidden Albums'**
  String get homeHiddenAlbums;

  /// No description provided for @homeLockedFolder.
  ///
  /// In en, this message translates to:
  /// **'Locked Folder'**
  String get homeLockedFolder;

  /// No description provided for @albumsFavourites.
  ///
  /// In en, this message translates to:
  /// **'Favourites'**
  String get albumsFavourites;

  /// No description provided for @albumsBin.
  ///
  /// In en, this message translates to:
  /// **'Bin'**
  String get albumsBin;

  /// No description provided for @albumsItemsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String albumsItemsCount(int count);

  /// No description provided for @albumsHiddenCount.
  ///
  /// In en, this message translates to:
  /// **'Hid {count} album(s) from Recents'**
  String albumsHiddenCount(int count);

  /// No description provided for @albumsUnhiddenCount.
  ///
  /// In en, this message translates to:
  /// **'Unhid {count} album(s) from Recents'**
  String albumsUnhiddenCount(int count);

  /// No description provided for @albumsEmptySelection.
  ///
  /// In en, this message translates to:
  /// **'Selected albums are empty'**
  String get albumsEmptySelection;

  /// No description provided for @albumsDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete album contents'**
  String get albumsDeleteTitle;

  /// No description provided for @albumsDeleteContent.
  ///
  /// In en, this message translates to:
  /// **'Delete {photoCount} photo(s) from {albumCount} album(s)?'**
  String albumsDeleteContent(int photoCount, int albumCount);

  /// No description provided for @albumsDeleteWarning.
  ///
  /// In en, this message translates to:
  /// **'The folder itself will not be removed.'**
  String get albumsDeleteWarning;

  /// No description provided for @moveToBin.
  ///
  /// In en, this message translates to:
  /// **'Move to bin'**
  String get moveToBin;

  /// No description provided for @moveToBinDesc.
  ///
  /// In en, this message translates to:
  /// **'Items can be restored from the recycle bin'**
  String get moveToBinDesc;

  /// No description provided for @deletePermanentlyDesc.
  ///
  /// In en, this message translates to:
  /// **'Items will be permanently deleted'**
  String get deletePermanentlyDesc;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @deletePermanently.
  ///
  /// In en, this message translates to:
  /// **'Delete permanently'**
  String get deletePermanently;

  /// No description provided for @albumsMovedToBin.
  ///
  /// In en, this message translates to:
  /// **'Moved {count} item(s) to trash'**
  String albumsMovedToBin(int count);

  /// No description provided for @albumsPermDeletedCount.
  ///
  /// In en, this message translates to:
  /// **'Permanently deleted {count} item(s)'**
  String albumsPermDeletedCount(int count);

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageDesc.
  ///
  /// In en, this message translates to:
  /// **'Choose your preferred language'**
  String get settingsLanguageDesc;

  /// No description provided for @languageSystemDefault.
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get languageSystemDefault;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @deleteItems.
  ///
  /// In en, this message translates to:
  /// **'Delete items'**
  String get deleteItems;

  /// No description provided for @deleteSelectedCount.
  ///
  /// In en, this message translates to:
  /// **'Delete {count} selected item(s)?'**
  String deleteSelectedCount(int count);

  /// No description provided for @movedToTrashSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Moved selected items to trash'**
  String get movedToTrashSnackbar;

  /// No description provided for @deletedPermanentlySnackbar.
  ///
  /// In en, this message translates to:
  /// **'Permanently deleted selected items'**
  String get deletedPermanentlySnackbar;

  /// No description provided for @movedToLockedFolderSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Moved {count} item(s) to Locked Folder'**
  String movedToLockedFolderSnackbar(int count);

  /// No description provided for @photosCount.
  ///
  /// In en, this message translates to:
  /// **'{count} photos'**
  String photosCount(int count);

  /// No description provided for @deletePhoto.
  ///
  /// In en, this message translates to:
  /// **'Delete photo'**
  String get deletePhoto;

  /// No description provided for @deletePhotoDesc.
  ///
  /// In en, this message translates to:
  /// **'What would you like to do with this photo?'**
  String get deletePhotoDesc;

  /// No description provided for @restoredToGallery.
  ///
  /// In en, this message translates to:
  /// **'Restored to gallery'**
  String get restoredToGallery;

  /// No description provided for @failedToRestore.
  ///
  /// In en, this message translates to:
  /// **'Failed to restore'**
  String get failedToRestore;

  /// No description provided for @failedToMoveToLocked.
  ///
  /// In en, this message translates to:
  /// **'Failed to move to Locked Folder'**
  String get failedToMoveToLocked;

  /// No description provided for @failedToLaunchEditor.
  ///
  /// In en, this message translates to:
  /// **'Failed to launch editor'**
  String get failedToLaunchEditor;

  /// No description provided for @wallpaperSetSuccess.
  ///
  /// In en, this message translates to:
  /// **'Wallpaper set successfully'**
  String get wallpaperSetSuccess;

  /// No description provided for @wallpaperSetFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to set wallpaper'**
  String get wallpaperSetFailed;

  /// No description provided for @homeScreen.
  ///
  /// In en, this message translates to:
  /// **'Home Screen'**
  String get homeScreen;

  /// No description provided for @lockScreen.
  ///
  /// In en, this message translates to:
  /// **'Lock Screen'**
  String get lockScreen;

  /// No description provided for @bothScreens.
  ///
  /// In en, this message translates to:
  /// **'Both'**
  String get bothScreens;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @cameraInfo.
  ///
  /// In en, this message translates to:
  /// **'Camera Info'**
  String get cameraInfo;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @exifSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get exifSettings;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @removeFromLockedFolder.
  ///
  /// In en, this message translates to:
  /// **'Remove from Locked Folder'**
  String get removeFromLockedFolder;

  /// No description provided for @moveToLockedFolder.
  ///
  /// In en, this message translates to:
  /// **'Move to Locked Folder'**
  String get moveToLockedFolder;

  /// No description provided for @setAsWallpaper.
  ///
  /// In en, this message translates to:
  /// **'Set as wallpaper'**
  String get setAsWallpaper;

  /// No description provided for @recycleBin.
  ///
  /// In en, this message translates to:
  /// **'Recycle Bin'**
  String get recycleBin;

  /// No description provided for @recycleBinEmpty.
  ///
  /// In en, this message translates to:
  /// **'Recycle Bin is empty'**
  String get recycleBinEmpty;

  /// No description provided for @restoredCount.
  ///
  /// In en, this message translates to:
  /// **'Restored {count} items'**
  String restoredCount(int count);

  /// No description provided for @restoredCountWithFail.
  ///
  /// In en, this message translates to:
  /// **'Restored {successCount} items, failed {failCount}'**
  String restoredCountWithFail(int successCount, int failCount);

  /// No description provided for @daysRemaining.
  ///
  /// In en, this message translates to:
  /// **'{count}d'**
  String daysRemaining(int count);

  /// No description provided for @lockedFolderNoItems.
  ///
  /// In en, this message translates to:
  /// **'No locked items'**
  String get lockedFolderNoItems;

  /// No description provided for @lockedFolderDesc.
  ///
  /// In en, this message translates to:
  /// **'Move photos here from the viewer to hide them behind biometric lock'**
  String get lockedFolderDesc;

  /// No description provided for @lockedItemsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} locked items'**
  String lockedItemsCount(int count);

  /// No description provided for @movingFiles.
  ///
  /// In en, this message translates to:
  /// **'Moving files…'**
  String get movingFiles;

  /// No description provided for @uninstallWarning.
  ///
  /// In en, this message translates to:
  /// **'Uninstalling the app will permanently delete locked files.'**
  String get uninstallWarning;

  /// No description provided for @addToAlbum.
  ///
  /// In en, this message translates to:
  /// **'Add to Album'**
  String get addToAlbum;

  /// No description provided for @addToSpecificAlbum.
  ///
  /// In en, this message translates to:
  /// **'Add to {albumName}'**
  String addToSpecificAlbum(String albumName);

  /// No description provided for @moveOrCopyDesc.
  ///
  /// In en, this message translates to:
  /// **'Do you want to move or copy the selected items?'**
  String get moveOrCopyDesc;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @move.
  ///
  /// In en, this message translates to:
  /// **'Move'**
  String get move;

  /// No description provided for @createNewAlbum.
  ///
  /// In en, this message translates to:
  /// **'Create New Album'**
  String get createNewAlbum;

  /// No description provided for @albumName.
  ///
  /// In en, this message translates to:
  /// **'Album Name'**
  String get albumName;

  /// No description provided for @albumNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Vacation'**
  String get albumNameHint;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @movingItems.
  ///
  /// In en, this message translates to:
  /// **'Moving items...'**
  String get movingItems;

  /// No description provided for @copyingItems.
  ///
  /// In en, this message translates to:
  /// **'Copying items...'**
  String get copyingItems;

  /// No description provided for @moveSuccessCount.
  ///
  /// In en, this message translates to:
  /// **'Successfully moved {count} items.'**
  String moveSuccessCount(int count);

  /// No description provided for @copySuccessCount.
  ///
  /// In en, this message translates to:
  /// **'Successfully copied {count} items.'**
  String copySuccessCount(int count);

  /// No description provided for @errorCreateAlbum.
  ///
  /// In en, this message translates to:
  /// **'Failed to create album folder. Check permissions.'**
  String get errorCreateAlbum;

  /// No description provided for @noHiddenAlbums.
  ///
  /// In en, this message translates to:
  /// **'No hidden albums'**
  String get noHiddenAlbums;

  /// No description provided for @hiddenAlbumsDesc.
  ///
  /// In en, this message translates to:
  /// **'Long-press an album to hide it from Recents'**
  String get hiddenAlbumsDesc;

  /// No description provided for @unhideSelected.
  ///
  /// In en, this message translates to:
  /// **'Unhide selected'**
  String get unhideSelected;

  /// No description provided for @hideSelected.
  ///
  /// In en, this message translates to:
  /// **'Hide selected'**
  String get hideSelected;

  /// No description provided for @deleteContents.
  ///
  /// In en, this message translates to:
  /// **'Delete contents'**
  String get deleteContents;

  /// No description provided for @excludeFolder.
  ///
  /// In en, this message translates to:
  /// **'Exclude Folder'**
  String get excludeFolder;

  /// No description provided for @folderExcluded.
  ///
  /// In en, this message translates to:
  /// **'Folder excluded'**
  String get folderExcluded;

  /// No description provided for @noFavourites.
  ///
  /// In en, this message translates to:
  /// **'No favourites yet'**
  String get noFavourites;

  /// No description provided for @favouritesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} favourites'**
  String favouritesCount(int count);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'ar',
    'de',
    'en',
    'es',
    'fr',
    'hi',
    'it',
    'ja',
    'kn',
    'pt',
    'ru',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'hi':
      return AppLocalizationsHi();
    case 'it':
      return AppLocalizationsIt();
    case 'ja':
      return AppLocalizationsJa();
    case 'kn':
      return AppLocalizationsKn();
    case 'pt':
      return AppLocalizationsPt();
    case 'ru':
      return AppLocalizationsRu();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
