import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sabi_pipu_tms/core/extensions/string_extensions.dart';

import 'android_storage_service.dart';

class MediaService {
  /// Returns the contents of a selected image, or null when cancelled.
  static Future<Uint8List?> pickImageBytes() async {
    final file = await FilePicker.pickFile(type: FileType.image);
    if (file == null) return null;
    return file.readAsBytes();
  }

  /// Keeps the chosen image inside the app's private documents directory.
  static Future<String?> pickPrivateImage() async {
    final bytes = await pickImageBytes();
    if (bytes == null) return null;
    final documents = await getApplicationDocumentsDirectory();
    final directory = await Directory(
      '${documents.path}/homework',
    ).create(recursive: true);
    final file = File(
      '${directory.path}/${DateTime.now().microsecondsSinceEpoch}',
    );
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  static Future<Uint8List?> readHomeworkImage(String path) async {
    final documents = await getApplicationDocumentsDirectory();
    final folder = '${documents.path}/homework/';
    if (!path.startsWith(folder) ||
        !RegExp(r'^\d+$').hasMatch(path.substring(folder.length))) {
      return null;
    }
    final file = File(path);
    return await file.exists() ? file.readAsBytes() : null;
  }

  /// Downloads the file at [url] and saves it appropriately.
  ///
  /// - **Images** (jpg, jpeg, png, gif, webp, bmp, heic) → saved to the device
  ///   gallery using [ImageGallerySaverPlus.saveImage].
  /// - **Videos** (mp4, mov, avi, mkv, webm) → downloaded to a temp file and
  ///   saved to the device gallery using [ImageGallerySaverPlus.saveFile].
  /// - **Everything else** → downloaded with Dio and stored in the system
  ///   Downloads folder (Android) or the app documents directory (iOS).
  ///
  /// Returns `true` on success, `false` on failure.
  static Future<bool> downloadFile(
    String url, {
    String? fileName,
    Function(bool success, String message)? callBack,
    Function(int, int)? onReceiveProgress,
  }) async {
    try {
      // Derive file name from URL if not provided
      final name = fileName ?? Uri.parse(url).pathSegments.last;
      final ext = name.split('.').last.toLowerCase();

      // ── Request appropriate permission ─────────────────────────────────
      final bool hasPermission = await _requestPermission();
      if (!hasPermission) {
        callBack?.call(
          false,
          'Permission denied, Please allow media access to save the file.',
        );
        return false;
      }

      // ── Route by file type ─────────────────────────────────────────────
      if (_isImage(ext) || _isVideo(ext)) {
        final result = await _saveMediaToGallery(url, name: name);
        callBack?.call(
          result,
          result ? 'Media saved successfully' : 'Failed to save media',
        );
        return result;
      } else {
        final result = await _saveToDownloads(
          url,
          name: name,
          onReceiveProgress: onReceiveProgress,
        );
        callBack?.call(
          result,
          result ? 'File saved successfully' : 'Failed to save file',
        );
        return result;
      }
    } catch (e) {
      callBack?.call(false, 'Failed to download file');
      return false;
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  static const _imageExtensions = {
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp',
    'bmp',
    'heic',
  };
  static const _videoExtensions = {'mp4', 'mov', 'avi', 'mkv', 'webm'};

  static bool _isImage(String ext) => _imageExtensions.contains(ext);
  static bool _isVideo(String ext) => _videoExtensions.contains(ext);

  /// Requests the minimum permission needed for saving downloaded media.
  static Future<bool> _requestPermission() async {
    if (Platform.isAndroid) {
      return AndroidStorageService.requestPermission();
    } else if (Platform.isIOS) {
      final status = await Permission.photos.request();
      return status.isGranted;
    }
    return true;
  }

  /// Downloads an image from [url] as bytes and saves it to the gallery.
  // static Future<bool> _saveImageToGallery(String url, {required String name}) async {
  //   final response = await Dio().get<List<int>>(url, options: Options(responseType: ResponseType.bytes));
  //   if (response.data == null) return false;

  //   final result = await ImageGallerySaverPlus.saveImage(
  //     response.data!,
  //     name: name.replaceAll(RegExp(r'\.[^.]+$'), ''),
  //   );
  //   return result['isSuccess'] == true;
  // }

  /// Downloads a video/Image from [url] to a temp file and saves it to the gallery.
  static Future<bool> _saveMediaToGallery(
    String url, {
    required String name,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final savePath = '${tempDir.path}/$name';

    await Dio().download(url, savePath);

    final result = await ImageGallerySaverPlus.saveFile(
      savePath,
      isReturnPathOfIOS: true,
    );
    // Clean up temp file
    final tempFile = File(savePath);
    if (await tempFile.exists()) await tempFile.delete();

    return result['isSuccess'] == true;
  }

  /// Downloads any file with Dio and saves it to the Downloads folder.
  static Future<bool> _saveToDownloads(
    String url, {
    required String name,
    Function(int, int)? onReceiveProgress,
  }) async {
    Directory? temporaryDirectory;
    try {
      if (Platform.isAndroid) {
        final tempDir = await getTemporaryDirectory();
        temporaryDirectory = await tempDir.createTemp('download_');
        final savePath = '${temporaryDirectory.path}/$name';
        await Dio().download(
          url,
          savePath,
          onReceiveProgress: onReceiveProgress,
        );
        return await AndroidStorageService.saveToDownloads(
          savePath,
          name: name,
        );
      }

      final dir = await getApplicationDocumentsDirectory();
      final savePath = '${dir.path}/$name';
      await Dio().download(url, savePath, onReceiveProgress: onReceiveProgress);
      return File(savePath).existsSync();
    } catch (e) {
      e.toString().logInfo();
      return false;
    } finally {
      if (temporaryDirectory != null && await temporaryDirectory.exists()) {
        await temporaryDirectory.delete(recursive: true);
      }
    }
  }

  static Future<List<PlatformFile>?> pickFiles({
    bool allowMultiple = true,
    List<String>? allowedExtensions,
    FileType type = FileType.any,
  }) async {
    final result = await FilePicker.pickFiles(
      // allowMultiple: allowMultiple,
      allowedExtensions: allowedExtensions,
      type: type,
    );
    return result;
  }

  static Future<List<MultipartFile>> platformFilesToMultipartFiles(
    List<PlatformFile> files,
  ) async {
    return Future.wait(
      files.map((file) async {
        // If the file has a path, create the MultipartFile from it.
        if (file.path != null) {
          return MultipartFile.fromFile(file.path!, filename: file.name);
        }

        // Otherwise, fall back to the in-memory bytes.
        // if (file.extension != null) {
        //   return MultipartFile.fromBytes(file.bytes!, filename: file.name);
        // }

        throw Exception(
          'PlatformFile "${file.name}" has neither path nor bytes.',
        );
      }),
    );
  }

  static Future<List<MultipartFile>> pathsToMultipartFiles(
    List<String> filePaths,
  ) async {
    try {
      return Future.wait(
        filePaths.map((path) async {
          return MultipartFile.fromFile(path);
        }),
      );
    } catch (e) {
      rethrow;
    }
  }
}
