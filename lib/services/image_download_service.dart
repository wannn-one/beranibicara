import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

class ImageDownloadService {
  static final Dio _dio = Dio();

  /// Downloads an image from the given URL and saves it to the device
  static Future<bool> downloadImage(
    BuildContext context,
    String imageUrl, {
    String? customFileName,
  }) async {
    if (!context.mounted) return false;
    
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Mengunduh gambar...'),
            ],
          ),
        ),
      );

      // Request storage permission
      final hasPermission = await _requestStoragePermission(context);
      if (!hasPermission) {
        if (context.mounted) Navigator.of(context).pop(); // Close loading dialog
        return false;
      }

      // Get the downloads directory
      Directory? downloadsDir;
      if (Platform.isAndroid) {
        downloadsDir = Directory('/storage/emulated/0/Download');
        if (!await downloadsDir.exists()) {
          downloadsDir = await getExternalStorageDirectory();
        }
      } else if (Platform.isIOS) {
        downloadsDir = await getApplicationDocumentsDirectory();
      }

      if (downloadsDir == null) {
        if (context.mounted) {
          Navigator.of(context).pop();
          _showErrorDialog(context, 'Tidak dapat mengakses direktori penyimpanan');
        }
        return false;
      }

      // Generate filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = customFileName ?? 'beranibicara_image_$timestamp.jpg';
      final filePath = '${downloadsDir.path}/$fileName';

      // Download the image
      final response = await _dio.download(
        imageUrl,
        filePath,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: false,
          validateStatus: (status) {
            return status! < 500;
          },
        ),
      );

      if (!context.mounted) return false;
      Navigator.of(context).pop(); // Close loading dialog

      if (response.statusCode == 200) {
        _showSuccessDialog(context, 'Gambar berhasil diunduh ke: $filePath');
        return true;
      } else {
        _showErrorDialog(context, 'Gagal mengunduh gambar. Status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        _showErrorDialog(context, 'Terjadi kesalahan: ${e.toString()}');
      }
      return false;
    }
  }

  /// Request storage permission
  static Future<bool> _requestStoragePermission(BuildContext context) async {
    if (Platform.isAndroid) {
      // Check Android version
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final sdkInt = androidInfo.version.sdkInt;
      
      if (sdkInt >= 33) {
        // Android 13+ (API 33+) - Use scoped storage
        final status = await Permission.photos.request();
        if (status.isGranted) {
          return true;
        }
        
        // If denied, show dialog to open app settings
        if (status.isDenied || status.isPermanentlyDenied) {
          if (!context.mounted) return false;
          return await _showPermissionDialog(context, 'Izin akses foto diperlukan untuk mengunduh gambar');
        }
      } else if (sdkInt >= 30) {
        // Android 11-12 (API 30-32)
        final status = await Permission.manageExternalStorage.request();
        if (status.isGranted) {
          return true;
        }
        
        if (status.isDenied || status.isPermanentlyDenied) {
          if (!context.mounted) return false;
          return await _showPermissionDialog(context, 'Izin penyimpanan eksternal diperlukan untuk mengunduh gambar');
        }
      } else {
        // Android 10 and below (API 29 and below)
        final status = await Permission.storage.request();
        if (status.isGranted) {
          return true;
        }
        
        if (status.isDenied || status.isPermanentlyDenied) {
          if (!context.mounted) return false;
          return await _showPermissionDialog(context, 'Izin penyimpanan diperlukan untuk mengunduh gambar');
        }
      }
      
      return false;
    } else if (Platform.isIOS) {
      final status = await Permission.photos.request();
      return status.isGranted;
    }
    return true; // For other platforms
  }

  /// Show permission dialog and redirect to settings if needed
  static Future<bool> _showPermissionDialog(BuildContext context, String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Izin Diperlukan'),
          ],
        ),
        content: Text('$message\n\nBuka pengaturan aplikasi untuk memberikan izin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop(true);
              await openAppSettings();
            },
            child: const Text('Buka Pengaturan'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// Show success dialog
  static void _showSuccessDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Berhasil'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Show error dialog
  static void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('Error'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
} 