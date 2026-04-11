// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'Pixel Gallery';

  @override
  String get settingsTitle => 'Configurações';

  @override
  String get settingsMaterialYou => 'Material You';

  @override
  String get settingsMaterialYouDesc =>
      'Usar cores dinâmicas do papel de parede';

  @override
  String get settingsStartupAlbums => 'Iniciar em Álbuns';

  @override
  String get settingsStartupAlbumsDesc =>
      'Iniciar na página de Álbuns em vez de Fotos';

  @override
  String get settingsExcludedFolders => 'Pastas Excluídas';

  @override
  String get settingsExcludedFoldersDesc => 'Ocultar pastas da galeria';

  @override
  String get settingsLicenses => 'Licenças de Código Aberto';

  @override
  String get settingsLicensesDesc => 'Créditos e informações de licença';

  @override
  String get settingsSourceCode => 'Código Fonte';

  @override
  String homeSelectedCount(int count) {
    return '$count Selecionado(s)';
  }

  @override
  String get homeShare => 'Compartilhar';

  @override
  String get homeDelete => 'Excluir';

  @override
  String get homeLock => 'Mover para Pasta Bloqueada';

  @override
  String get homeHiddenAlbums => 'Álbuns Ocultos';

  @override
  String get homeLockedFolder => 'Pasta Bloqueada';

  @override
  String get albumsFavourites => 'Favoritos';

  @override
  String get albumsBin => 'Lixeira';

  @override
  String albumsItemsCount(int count) {
    return '$count itens';
  }

  @override
  String albumsHiddenCount(int count) {
    return 'Ocultou $count álbum(ns) de Recentes';
  }

  @override
  String albumsUnhiddenCount(int count) {
    return 'Exibiu $count álbum(ns) em Recentes';
  }

  @override
  String get albumsEmptySelection => 'Os álbuns selecionados estão vazios';

  @override
  String get albumsDeleteTitle => 'Excluir conteúdo do álbum';

  @override
  String albumsDeleteContent(int photoCount, int albumCount) {
    return 'Excluir $photoCount foto(s) de $albumCount álbum(ns)?';
  }

  @override
  String get albumsDeleteWarning => 'A própria pasta não será removida.';

  @override
  String get moveToBin => 'Move to bin';

  @override
  String get moveToBinDesc => 'Items can be restored from the recycle bin';

  @override
  String get deletePermanentlyDesc => 'Items will be permanently deleted';

  @override
  String get cancel => 'Cancelar';

  @override
  String get deletePermanently => 'Excluir permanentemente';

  @override
  String albumsMovedToBin(int count) {
    return '$count item(ns) movido(s) para a lixeira';
  }

  @override
  String albumsPermDeletedCount(int count) {
    return '$count item(ns) excluído(s) permanentemente';
  }

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get settingsLanguageDesc => 'Escolha o seu idioma preferido';

  @override
  String get languageSystemDefault => 'Padrão do Sistema';

  @override
  String get languageEnglish => 'Inglês';

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
