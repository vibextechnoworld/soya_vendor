import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_cropper/image_cropper.dart';
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
  /// When [enableCrop] is true, the picked image opens in a cropper that
  /// supports rotating and cropping before being returned.
  static Future<File?> pickFile(BuildContext context,
      {bool enableCrop = false}) async {
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
        final File pickedFile = File(image.path);
        if (enableCrop) {
          final croppedFile = await _cropImage(context, pickedFile);
          if (croppedFile != null) {
            return File(croppedFile.path);
          }
          // User cancelled cropping, fall back to the original image
        }
        return pickedFile;
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

  /// Opens the cropper UI allowing the user to rotate and crop the image.
  /// Returns the cropped file or null if the user cancels.
  static Future<CroppedFile?> _cropImage(
      BuildContext context, File sourceFile) async {
    try {
      return await ImageCropper().cropImage(
        sourcePath: sourceFile.path,
        compressQuality: 80,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Rotate & Crop',
            toolbarColor: appColor,
            toolbarWidgetColor: whiteColor,
            backgroundColor: whiteColor,
            activeControlsWidgetColor: appColor,
            dimmedLayerColor: Colors.black.withOpacity(0.4),
            cropFrameColor: appColor,
            cropGridColor: Colors.grey,
            cropFrameStrokeWidth: 2,
            cropGridRowCount: 3,
            cropGridColumnCount: 3,
            cropGridStrokeWidth: 1,
            showCropGrid: true,
            lockAspectRatio: false,
            hideBottomControls: false,
            initAspectRatio: CropAspectRatioPreset.original,
            cropStyle: CropStyle.rectangle,
          ),
          IOSUiSettings(
            title: 'Rotate & Crop',
            aspectRatioLockEnabled: false,
            rotateClockwiseButtonHidden: false,
            resetButtonHidden: false,
            aspectRatioPickerButtonHidden: true,
          ),
        ],
      );
    } catch (e) {
      debugPrint('Error cropping image: $e');
      if (context.mounted) {
        ToastMessage.show(context,
            message: 'Error cropping image: $e', isError: true);
      }
      return null;
    }
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
    // Only camera requires a runtime permission. Gallery picking uses the
    // system photo picker (Android 13+) or ACTION_GET_CONTENT / ACTION_PICK
    // on older versions, neither of which requires a storage permission.
    if (source != ImageSource.camera) return true;

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
