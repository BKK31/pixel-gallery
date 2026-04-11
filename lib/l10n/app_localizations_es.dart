// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Galería Pixel';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get settingsMaterialYou => 'Material You';

  @override
  String get settingsMaterialYouDesc =>
      'Usar colores dinámicos del fondo de pantalla';

  @override
  String get settingsStartupAlbums => 'Iniciar en Álbumes';

  @override
  String get settingsStartupAlbumsDesc =>
      'Iniciar en la página de Álbumes en lugar de Fotos';

  @override
  String get settingsExcludedFolders => 'Carpetas excluidas';

  @override
  String get settingsExcludedFoldersDesc => 'Ocultar carpetas de la galería';

  @override
  String get settingsLicenses => 'Licencias de código abierto';

  @override
  String get settingsLicensesDesc => 'Créditos e información de licencias';

  @override
  String get settingsSourceCode => 'Código fuente';

  @override
  String homeSelectedCount(int count) {
    return '$count seleccionados';
  }

  @override
  String get homeShare => 'Compartir';

  @override
  String get homeDelete => 'Eliminar';

  @override
  String get homeLock => 'Mover a la carpeta bloqueada';

  @override
  String get homeHiddenAlbums => 'Álbumes ocultos';

  @override
  String get homeLockedFolder => 'Carpeta bloqueada';

  @override
  String get albumsFavourites => 'Favoritos';

  @override
  String get albumsBin => 'Papelera';

  @override
  String albumsItemsCount(int count) {
    return '$count elementos';
  }

  @override
  String albumsHiddenCount(int count) {
    return 'Se ocultaron $count álbumes de Recientes';
  }

  @override
  String albumsUnhiddenCount(int count) {
    return 'Se mostraron $count álbumes de Recientes';
  }

  @override
  String get albumsEmptySelection => 'Los álbumes seleccionados están vacíos';

  @override
  String get albumsDeleteTitle => 'Eliminar contenido del álbum';

  @override
  String albumsDeleteContent(int photoCount, int albumCount) {
    return '¿Eliminar $photoCount fotos de $albumCount álbumes?';
  }

  @override
  String get albumsDeleteWarning => 'La carpeta en sí no se eliminará.';

  @override
  String get moveToBin => 'Move to bin';

  @override
  String get moveToBinDesc => 'Items can be restored from the recycle bin';

  @override
  String get deletePermanentlyDesc => 'Items will be permanently deleted';

  @override
  String get cancel => 'Cancelar';

  @override
  String get deletePermanently => 'Eliminar permanentemente';

  @override
  String albumsMovedToBin(int count) {
    return 'Se movieron $count elementos a la papelera';
  }

  @override
  String albumsPermDeletedCount(int count) {
    return 'Se eliminaron permanentemente $count elementos';
  }

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get settingsLanguageDesc => 'Elige tu idioma preferido';

  @override
  String get languageSystemDefault => 'Predeterminado del sistema';

  @override
  String get languageEnglish => 'Inglés';

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
