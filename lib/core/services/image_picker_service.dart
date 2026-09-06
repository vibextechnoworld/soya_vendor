import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image/image.dart' as img;
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:soya_app/core/widgets/tost_message.dart';
import 'package:soya_app/util/colors.dart';
import 'package:soya_app/util/font_family.dart';

enum FileSource { camera, gallery, document }

class ImagePickerService {
  static final ImagePicker _picker = ImagePicker();

  /// Compresses an image file to reduce upload size over slow networks.
  /// - Non-image files (PDFs, etc.) are returned unchanged.
  /// - Images are decoded, resized to a max dimension, and re-encoded as JPEG.
  /// - Returns the original file if compression fails (fail-safe).
  static Future<File> compressForUpload(File file,
      {int maxDimension = 1400, int quality = 70}) async {
    try {
      if (!file.existsSync()) return file;

      // Only compress raster images; leave PDFs/documents untouched.
      final lower = file.path.toLowerCase();
      final isImage = lower.endsWith('.jpg') ||
          lower.endsWith('.jpeg') ||
          lower.endsWith('.png') ||
          lower.endsWith('.bmp') ||
          lower.endsWith('.webp');
      if (!isImage) return file;

      // Try to decode with the image package (pure Dart, no native deps).
      Uint8List? bytes = await file.readAsBytes();
      if (bytes.isEmpty) return file;

      final decoder = img.decodeImage(bytes);
      if (decoder == null) return file;

      var image = decoder;
      // Downscale if wider/taller than the target dimension.
      final scale =
          (image.width > image.height ? image.width : image.height) /
              maxDimension;
      if (scale > 1) {
        image = img.copyResize(image,
            width: (image.width / scale).round(),
            height: (image.height / scale).round());
      }

      // Re-encode to JPEG. Use a temp file in the same directory as the source.
      final dir = file.parent;
      final outFile =
          File('${dir.path}/cmp_${DateTime.now().millisecondsSinceEpoch}.jpg');
      final jpg = img.encodeJpg(image, quality: quality);

      // Only replace if the compressed version is actually smaller.
      if (jpg.length < bytes.length) {
        await outFile.writeAsBytes(jpg, flush: true);
        return outFile;
      }
      return file;
    } catch (e) {
      debugPrint('Image compression failed, using original: $e');
      return file;
    }
  }

  /// Picks an image or document after showing a source selection dialog.
  /// Handles keyboard unfocusing and permission checks.
  /// When [enableCrop] is true, the picked image opens in a cropper that
  /// supports rotating and cropping before being returned.
  /// When [allowedSources] is provided, only those source options are shown
  /// in the selection dialog (and skipped entirely if just one is allowed).
  static Future<File?> pickFile(BuildContext context,
      {bool enableCrop = false, List<FileSource>? allowedSources}) async {
    // 1. Unfocus keyboard immediately to prevent UI lag
    FocusScope.of(context).unfocus();

    // 2. Show source selection dialog
    final source = (allowedSources != null && allowedSources.length == 1)
        ? allowedSources.first
        : await _showImageSourceDialog(context, allowedSources: allowedSources);
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
          return await compressForUpload(File(result.files.single.path!));
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
          // Downscale before rotate/crop: pure-Dart decode + copyRotate
          // allocate full RGBA buffers per copy, so very large camera images
          // can trigger native out-of-memory crashes.
          final boundedFile = await _boundedImage(pickedFile);
          final rotatedFile = await _rotateAndZoom(context, boundedFile);
          if (rotatedFile != null) {
            return await compressForUpload(rotatedFile);
          }
          // User cancelled, fall back to the original image
        }
        return await compressForUpload(pickedFile);
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

  /// Downscales very large images (e.g., 48MP camera shots) to a bounded
  /// dimension before rotate/crop. Prevents native OOM crashes that happen
  /// when the pure-Dart image package decodes and copies full-resolution
  /// RGBA buffers. Returns the original file if already small or on any
  /// failure (fail-safe).
  static Future<File> _boundedImage(File file,
      {int maxDimension = 2500}) async {
    try {
      if (!file.existsSync()) return file;
      final bytes = await file.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return file;
      final largest =
          (decoded.width > decoded.height) ? decoded.width : decoded.height;
      if (largest <= maxDimension) return file;

      final scale = largest / maxDimension;
      final resized = img.copyResize(decoded,
          width: (decoded.width / scale).round(),
          height: (decoded.height / scale).round());
      final dir = file.parent;
      final outFile = File(
          '${dir.path}/bnd_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await outFile.writeAsBytes(img.encodeJpg(resized, quality: 90),
          flush: true);
      return outFile;
    } catch (e) {
      debugPrint('Image bounding failed, using original: $e');
      return file;
    }
  }

  /// Opens a full-screen viewer that lets the user ZOOM (pinch/pan) and
  /// ROTATE the image, with NO cropping. Rotation is applied to the actual
  /// pixels so the saved file is truly rotated.
  /// Returns the rotated file, or null if the user cancels (keep original).
  static Future<File?> _rotateAndZoom(
      BuildContext context, File sourceFile) async {
    try {
      final File? result = await showDialog<File?>(
        context: context,
        barrierColor: Colors.black,
        builder: (_) => _RotateZoomViewer(sourceFile: sourceFile),
      );
      return result;
    } catch (e) {
      debugPrint('Error in rotate/zoom viewer: $e');
      if (context.mounted) {
        ToastMessage.show(context,
            message: 'Error: $e', isError: true);
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
          final files = result.files
              .where((f) => f.path != null)
              .map((f) => File(f.path!))
              .toList();
          final compressed = <File>[];
          for (final f in files) {
            compressed.add(await compressForUpload(f));
          }
          return compressed;
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
          return [await compressForUpload(File(image.path))];
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
          final compressed = <File>[];
          for (final img in images) {
            compressed.add(await compressForUpload(File(img.path)));
          }
          return compressed;
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

  static Future<FileSource?> _showImageSourceDialog(BuildContext context,
      {List<FileSource>? allowedSources}) async {
    final List<FileSource> sources = allowedSources ?? [
      FileSource.camera,
      FileSource.gallery,
      FileSource.document,
    ];
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
                if (sources.contains(FileSource.camera))
                  _buildSourceOption(
                    context: context,
                    icon: Icons.camera_alt_rounded,
                    label: 'Camera',
                    onTap: () => Navigator.pop(context, FileSource.camera),
                  ),
                if (sources.contains(FileSource.gallery))
                  _buildSourceOption(
                    context: context,
                    icon: Icons.photo_library_rounded,
                    label: 'Gallery',
                    onTap: () => Navigator.pop(context, FileSource.gallery),
                  ),
                if (sources.contains(FileSource.document))
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

/// Full-screen rotate + zoom viewer. NO crop frame.
/// Pinch/pan to zoom, rotate button turns the image 90deg clockwise.
/// Done applies the real pixel rotation and returns the rotated file.
/// Cancel returns null (keep original).
class _RotateZoomViewer extends StatefulWidget {
  const _RotateZoomViewer({required this.sourceFile});

  final File sourceFile;

  @override
  State<_RotateZoomViewer> createState() => _RotateZoomViewerState();
}

class _RotateZoomViewerState extends State<_RotateZoomViewer> {
  int _rotations = 0;
  bool _saving = false;
  bool _closing = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        children: [
          // Rotatable + zoomable image
          Positioned.fill(
            child: RotatedBox(
              quarterTurns: _rotations,
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 5,
                panEnabled: true,
                child: Image.file(
                  widget.sourceFile,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          // Close button (cancel, keep original)
          Positioned(
            top: 16,
            left: 16,
            child: GestureDetector(
              onTap: () => _dismiss(null),
              child: Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.close, color: whiteColor, size: 22.sp),
              ),
            ),
          ),
          // Top-right column: rotate + crop buttons
          Positioned(
            top: 16,
            right: 16,
            child: Column(
              children: [
                GestureDetector(
                  onTap: () =>
                      setState(() => _rotations = (_rotations + 1) % 4),
                  child: Container(
                    padding: EdgeInsets.all(8.r),
                    decoration: BoxDecoration(
                      color: appColor,
                      shape: BoxShape.circle,
                    ),
                    child:
                        Icon(Icons.rotate_right, color: whiteColor, size: 22.sp),
                  ),
                ),
                SizedBox(height: 12.h),
                GestureDetector(
                  onTap: _saving ? null : _openCropper,
                  child: Container(
                    padding: EdgeInsets.all(8.r),
                    decoration: BoxDecoration(
                      color: whiteColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.crop, color: appColor, size: 22.sp),
                  ),
                ),
              ],
            ),
          ),
          // Bottom bar with Done button
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Center(
              child: _saving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: appColor,
                        padding: EdgeInsets.symmetric(
                            horizontal: 32.w, vertical: 12.h),
                      ),
                      onPressed: _saving
                          ? null
                          : (_rotations == 0
                              ? () => _dismiss(widget.sourceFile)
                              : _applyRotation),
                      child: Text(
                        'DONE',
                        style: TextStyle(
                          color: whiteColor,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                          fontFamily: FontFamily.jost,
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  /// Pops the viewer exactly once with the given result (or null to cancel).
  /// Guards against double-tap / double-pop on any completion path.
  void _dismiss(File? result) {
    if (_closing || !mounted) return;
    _closing = true;
    _saving = true;
    Navigator.pop(context, result);
  }

  Future<void> _applyRotation() async {
    if (_closing) return;
    setState(() => _saving = true);
    try {
      final bytes = await widget.sourceFile.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) {
        _dismiss(widget.sourceFile);
        return;
      }
      var rotated = decoded;
      for (var i = 0; i < _rotations; i++) {
        rotated = img.copyRotate(rotated, angle: 90);
      }
      final dir = widget.sourceFile.parent;
      final outFile = File(
          '${dir.path}/rot_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await outFile.writeAsBytes(img.encodeJpg(rotated, quality: 90),
          flush: true);
      _dismiss(outFile);
    } catch (e) {
      debugPrint('Rotation failed: $e');
      _dismiss(widget.sourceFile);
    }
  }

  /// Applies the current rotation (if any) to a temp file, then opens the
  /// native cropper so the user can select a crop area. Returns the cropped
  /// file as the final result.
  Future<void> _openCropper() async {
    setState(() => _saving = true);
    try {
      // 1. Ensure the temp file is in the current rotation orientation.
      File orientedFile = widget.sourceFile;
      if (_rotations != 0 && !_closing) {
        final bytes = await widget.sourceFile.readAsBytes();
        final decoded = img.decodeImage(bytes);
        if (decoded != null) {
          img.Image rotated = decoded;
          for (var i = 0; i < _rotations; i++) {
            rotated = img.copyRotate(rotated, angle: 90);
          }
          final dir = widget.sourceFile.parent;
          orientedFile = File(
              '${dir.path}/rot_${DateTime.now().millisecondsSinceEpoch}.jpg');
          await orientedFile.writeAsBytes(
              img.encodeJpg(rotated, quality: 90),
              flush: true);
        }
      }

      // 2. Open the native cropper with aspect ratio locked to original.
      final CroppedFile? cropped = await ImageCropper().cropImage(
        sourcePath: orientedFile.path,
        compressQuality: 90,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: appColor,
            toolbarWidgetColor: whiteColor,
            backgroundColor: whiteColor,
            activeControlsWidgetColor: appColor,
            dimmedLayerColor: Colors.black.withOpacity(0.4),
            cropFrameColor: appColor,
            cropGridColor: Colors.grey,
            cropFrameStrokeWidth: 2,
            showCropGrid: true,
            lockAspectRatio: false,
            hideBottomControls: false,
            initAspectRatio: CropAspectRatioPreset.original,
            cropStyle: CropStyle.rectangle,
          ),
          IOSUiSettings(
            title: 'Crop Image',
            aspectRatioLockEnabled: false,
            aspectRatioPickerButtonHidden: false,
            resetAspectRatioEnabled: true,
          ),
        ],
      );

      if (!mounted || _closing) return;
      if (cropped != null) {
        _dismiss(File(cropped.path));
      } else {
        // User cancelled the cropper; go back to the rotate/zoom viewer.
        setState(() => _saving = false);
      }
    } catch (e) {
      debugPrint('Crop failed: $e');
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }
}
