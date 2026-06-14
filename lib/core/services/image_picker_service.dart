import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:soya_app/core/widgets/tost_message.dart';
import 'package:soya_app/util/colors.dart';
import 'package:soya_app/util/font_family.dart';

enum FileSource { camera, gallery, document }

class ImagePickerService {
  static final ImagePicker _picker = ImagePicker();

  /// Picks an image or document after showing a source selection dialog.
  /// Handles keyboard unfocusing and permission checks.
  static Future<File?> pickFile(BuildContext context) async {
    // 1. Unfocus keyboard immediately to prevent UI lag
    FocusScope.of(context).unfocus();

    // 2. Show source selection dialog
    final source = await _showImageSourceDialog(context);
    if (source == null) return null;

    // 3. Add a small delay to allow the bottom sheet to close and UI thread to settle
    // This prevents the native file picker from blocking the UI during transitions (prevents ANR)
    await Future.delayed(const Duration(milliseconds: 300));

    // 4. Handle picking based on source
    try {
      if (source == FileSource.document) {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'bmp'],
          withData: false, // Don't load file data into memory
        );
        if (result != null && result.files.single.path != null) {
          return File(result.files.single.path!);
        }
        return null;
      }

      // Convert FileSource to ImageSource
      final imageSource = source == FileSource.camera
          ? ImageSource.camera
          : ImageSource.gallery;

      // Check and request permissions
      final hasPermission = await _handlePermissions(context, imageSource);
      if (!hasPermission) return null;

      final XFile? image = await _picker.pickImage(
        source: imageSource,
        imageQuality: 80, // Optimize image size
      );
      if (image != null) {
        return File(image.path);
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
      if (context.mounted) {
        ToastMessage.show(context,
            message: 'Error picking file: $e', isError: true);
      }
    }
    return null;
  }

  /// Picks multiple images or documents after showing a source selection dialog.
  /// Handles keyboard unfocusing and permission checks.
  static Future<List<File>?> pickMultipleFiles(BuildContext context) async {
    // 1. Unfocus keyboard immediately to prevent UI lag
    FocusScope.of(context).unfocus();

    // 2. Show source selection dialog
    final source = await _showImageSourceDialog(context);
    if (source == null) return null;

    // 3. Add a small delay to allow the bottom sheet to close and UI thread to settle
    await Future.delayed(const Duration(milliseconds: 300));

    // 4. Handle picking based on source
    try {
      if (source == FileSource.document) {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'bmp'],
          allowMultiple: true,
          withData: false, // Don't load file data into memory
        );
        if (result != null && result.files.isNotEmpty) {
          return result.files
              .where((f) => f.path != null)
              .map((f) => File(f.path!))
              .toList();
        }
        return null;
      }

      if (source == FileSource.camera) {
        final hasPermission = await _handlePermissions(context, ImageSource.camera);
        if (!hasPermission) return null;

        final XFile? image = await _picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 80,
        );
        if (image != null) {
          return [File(image.path)];
        }
        return null;
      }

      if (source == FileSource.gallery) {
        final hasPermission = await _handlePermissions(context, ImageSource.gallery);
        if (!hasPermission) return null;

        final List<XFile> images = await _picker.pickMultiImage(
          imageQuality: 80,
        );
        if (images.isNotEmpty) {
          return images.map((img) => File(img.path)).toList();
        }
        return null;
      }
    } catch (e) {
      debugPrint('Error picking files: $e');
      if (context.mounted) {
        ToastMessage.show(context,
            message: 'Error picking files: $e', isError: true);
      }
    }
    return null;
  }

  static Future<bool> _handlePermissions(
      BuildContext context, ImageSource source) async {
    if (source == ImageSource.camera) {
      var status = await Permission.camera.status;
      if (!status.isGranted) {
        status = await Permission.camera.request();
        if (!status.isGranted) {
          if (context.mounted) {
            ToastMessage.show(context,
                message: 'Camera permission is required to take photos',
                isError: true);
          }
          if (status.isPermanentlyDenied) {
            openAppSettings();
          }
          return false;
        }
      }
    } else {
      // Gallery permission - For Android 13+ handled by image_picker mostly,
      // but explicit check is safer for older versions or specific needs.
      if (Platform.isAndroid) {
        var status = await Permission.photos.status;
        if (status.isDenied || status.isLimited) {
          status = await Permission.photos.request();
        }

        if (status.isDenied) {
          status = await Permission.storage.status;
          if (status.isDenied) {
            status = await Permission.storage.request();
          }
        }

        if (status.isDenied) {
          if (context.mounted) {
            ToastMessage.show(context,
                message: 'Storage permission is required to access gallery',
                isError: true);
          }
          return false;
        }
      }
    }
    return true;
  }

  static Future<FileSource?> _showImageSourceDialog(
      BuildContext context) async {
    return await showModalBottomSheet<FileSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: whiteColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: EdgeInsets.only(top: 10.h),
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: greyColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 20.h),
              child: Text(
                'Select File Source',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  fontFamily: FontFamily.jost,
                  color: appColor,
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSourceOption(
                  context: context,
                  icon: Icons.camera_alt_rounded,
                  label: 'Camera',
                  onTap: () => Navigator.pop(context, FileSource.camera),
                ),
                _buildSourceOption(
                  context: context,
                  icon: Icons.photo_library_rounded,
                  label: 'Gallery',
                  onTap: () => Navigator.pop(context, FileSource.gallery),
                ),
                _buildSourceOption(
                  context: context,
                  icon: Icons.file_present_rounded,
                  label: 'Document',
                  onTap: () => Navigator.pop(context, FileSource.document),
                ),
              ],
            ),
            SizedBox(height: 30.h),
          ],
        ),
      ),
    );
  }

  static Widget _buildSourceOption({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(15.r),
            decoration: BoxDecoration(
              color: appColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: appColor, size: 30.r),
          ),
          SizedBox(height: 8.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 14.sp,
              fontFamily: FontFamily.jost,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
