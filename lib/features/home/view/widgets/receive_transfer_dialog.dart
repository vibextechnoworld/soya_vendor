import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:soya_app/features/home/controller/stock_controller.dart';
import 'package:soya_app/features/home/model/vendor_transfer_list_model.dart';
import 'package:soya_app/core/services/location_service.dart';
import 'package:soya_app/core/widgets/tost_message.dart';
import 'package:soya_app/util/colors.dart';
import 'package:soya_app/util/font_family.dart';
import 'package:soya_app/core/services/pdf_transfer_service.dart';

class ReceiveTransferDialog extends StatefulWidget {
  final VendorTransferData transfer;

  const ReceiveTransferDialog({super.key, required this.transfer});

  @override
  State<ReceiveTransferDialog> createState() => _ReceiveTransferDialogState();
}

class _ReceiveTransferDialogState extends State<ReceiveTransferDialog> {
  late TextEditingController _weightController;
  late TextEditingController _bagController;
  late TextEditingController _locTextController;
  late TextEditingController _latController;
  late TextEditingController _lngController;
  late String _selectedUnit;

  bool _isLocationLoading = false;
  String? _locationError;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Prefill with dispatchedWeight and dispatchedBagCount (with weight/bagCount fallbacks)
    _weightController = TextEditingController(
        text:
            (widget.transfer.dispatchedWeight ?? widget.transfer.weight ?? 0.0)
                .toString());
    _bagController = TextEditingController(
        text: (widget.transfer.dispatchedBagCount ??
                widget.transfer.bagCount ??
                0)
            .toString());
    _locTextController = TextEditingController();
    _latController = TextEditingController();
    _lngController = TextEditingController();
    _selectedUnit =
        widget.transfer.receivedUnit ?? widget.transfer.unit ?? 'QTL';

    // Trigger auto-fetching on open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchLocation();
    });
  }

  @override
  void dispose() {
    _weightController.dispose();
    _bagController.dispose();
    _locTextController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  Future<void> _fetchLocation() async {
    if (!mounted) return;
    setState(() {
      _isLocationLoading = true;
      _locationError = null;
      _locTextController.text = 'Fetching coordinates...';
      _latController.text = '...';
      _lngController.text = '...';
    });

    try {
      final positionStr = await LocationService.getCurrentLocation();
      if (positionStr == null) {
        if (mounted) {
          setState(() {
            _isLocationLoading = false;
            _locationError =
                'Failed to get GPS location. Please check settings/permissions.';
            _locTextController.text = '';
            _latController.text = '';
            _lngController.text = '';
          });
        }
        return;
      }

      final parts = positionStr.split(',');
      final double latitude = double.parse(parts[0]);
      final double longitude = double.parse(parts[1]);

      final address =
          await LocationService.getLocationName(latitude, longitude);

      if (mounted) {
        setState(() {
          _isLocationLoading = false;
          _latController.text = latitude.toStringAsFixed(6);
          _lngController.text = longitude.toStringAsFixed(6);
          _locTextController.text = address ?? 'Fetched Location';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLocationLoading = false;
          _locationError = 'Error fetching location: ${e.toString()}';
          _locTextController.text = '';
          _latController.text = '';
          _lngController.text = '';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      title: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: primeryColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.assignment_turned_in_rounded,
                color: primeryColor, size: 30.sp),
          ),
          SizedBox(height: 12.h),
          Text(
            'Receive & Verify',
            style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                fontFamily: FontFamily.jost,
                color: blackColor),
          ),
          SizedBox(height: 4.h),
          Text(
            'Verify quantities received at destination for transfer #${widget.transfer.transferNo}',
            style: TextStyle(
                fontSize: 12.sp,
                color: greyColor,
                fontFamily: FontFamily.jost,
                fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      content: SizedBox(
        width: 320.w,
        child: SingleChildScrollView(
          child: ListenableBuilder(
            listenable: Listenable.merge([_weightController, _bagController]),
            builder: (context, _) {
              final double? recWeight = double.tryParse(_weightController.text);
              final int? recBags = int.tryParse(_bagController.text);

              // Use dispatched weight and bag count as reference, fallback to general weight/bagCount
              final double refWeight = widget.transfer.dispatchedWeight ??
                  widget.transfer.weight ??
                  0.0;
              final int refBags = widget.transfer.dispatchedBagCount ??
                  widget.transfer.bagCount ??
                  0;

              double weightDiff = 0.0;
              int bagDiff = 0;
              if (recWeight != null) {
                weightDiff = refWeight - recWeight;
              }
              if (recBags != null) {
                bagDiff = refBags - recBags;
              }

              final isDiscrepancy = weightDiff != 0.0 || bagDiff != 0;

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: _buildDialogField(
                          'Received Weight',
                          child: TextField(
                            controller: _weightController,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14.sp,
                                fontFamily: FontFamily.jost),
                            decoration: _inputDecoration(
                                hint: 'Weight', icon: Icons.scale_rounded),
                            enabled: !_isSubmitting,
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        flex: 1,
                        child: _buildDialogField(
                          'Unit',
                          child: DropdownButtonFormField<String>(
                            value: _selectedUnit,
                            style: TextStyle(
                                color: blackColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 13.sp,
                                fontFamily: FontFamily.jost),
                            decoration: _inputDecoration(
                                hint: 'Unit', icon: Icons.straighten_rounded),
                            items: const [
                              DropdownMenuItem(
                                  value: 'QTL', child: Text('QTL')),
                              DropdownMenuItem(value: 'KG', child: Text('KG')),
                              DropdownMenuItem(value: 'MT', child: Text('MT')),
                            ],
                            onChanged: _isSubmitting
                                ? null
                                : (val) => val != null
                                    ? setState(() => _selectedUnit = val)
                                    : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  _buildDialogField(
                    'Received Bag Count',
                    child: TextField(
                      controller: _bagController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14.sp,
                          fontFamily: FontFamily.jost),
                      decoration: _inputDecoration(
                          hint: 'Bag Count', icon: Icons.inventory_2_outlined),
                      enabled: !_isSubmitting,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  _buildDialogField(
                    'Receive Location Text',
                    child: TextField(
                      controller: _locTextController,
                      readOnly: true,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 13.sp,
                        fontFamily: FontFamily.jost,
                        color: Colors.black54,
                      ),
                      decoration: _inputDecoration(
                        hint: _isLocationLoading
                            ? 'Acquiring GPS location...'
                            : 'Location Text',
                        icon: Icons.location_on_outlined,
                        suffixIcon: _isLocationLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: Padding(
                                  padding: EdgeInsets.all(12),
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDialogField(
                          'Latitude',
                          child: TextField(
                            controller: _latController,
                            readOnly: true,
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 12.sp,
                              fontFamily: FontFamily.jost,
                              color: Colors.black54,
                            ),
                            decoration: _inputDecoration(
                              hint: _isLocationLoading
                                  ? 'Fetching...'
                                  : 'Latitude',
                              icon: Icons.map_outlined,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: _buildDialogField(
                          'Longitude',
                          child: TextField(
                            controller: _lngController,
                            readOnly: true,
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 12.sp,
                              fontFamily: FontFamily.jost,
                              color: Colors.black54,
                            ),
                            decoration: _inputDecoration(
                              hint: _isLocationLoading
                                  ? 'Fetching...'
                                  : 'Longitude',
                              icon: Icons.explore_outlined,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_locationError != null) ...[
                    SizedBox(height: 10.h),
                    Container(
                      padding: EdgeInsets.all(10.w),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Column(
                        children: [
                          Text(
                            _locationError!,
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: Colors.orange.shade900,
                              fontFamily: FontFamily.jost,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 6.h),
                          TextButton.icon(
                            onPressed:
                                _isLocationLoading ? null : _fetchLocation,
                            icon: const Icon(Icons.refresh, size: 14),
                            label: Text(
                              'Retry Fetching Location',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11.sp,
                                  fontFamily: FontFamily.jost),
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: primeryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    SizedBox(height: 10.h),
                    Text(
                      'Note: GPS coordinates are automatically fetched and required for live tracking.',
                      style: TextStyle(
                        color: Colors.orange.shade800,
                        fontSize: 10.sp,
                        fontFamily: FontFamily.jost,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  if (isDiscrepancy) ...[
                    SizedBox(height: 12.h),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(10.w),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.warning_rounded,
                                  color: Colors.red.shade700, size: 16.sp),
                              SizedBox(width: 6.w),
                              Text(
                                'Discrepancy Warning',
                                style: TextStyle(
                                    color: Colors.red.shade900,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: FontFamily.jost,
                                    fontSize: 12.sp),
                              ),
                            ],
                          ),
                          SizedBox(height: 6.h),
                          if (weightDiff != 0.0)
                            Text(
                              'Weight Difference: ${weightDiff.toStringAsFixed(2)} $_selectedUnit (${weightDiff > 0 ? "Shortage" : "Excess"})',
                              style: TextStyle(
                                  color: Colors.red.shade800,
                                  fontFamily: FontFamily.jost,
                                  fontSize: 11.sp),
                            ),
                          if (bagDiff != 0)
                            Text(
                              'Bag Difference: $bagDiff bags (${bagDiff > 0 ? "Missing" : "Extra"})',
                              style: TextStyle(
                                  color: Colors.red.shade800,
                                  fontFamily: FontFamily.jost,
                                  fontSize: 11.sp),
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
      actionsPadding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 20.h),
      actions: [
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                child: Text('CANCEL',
                    style: TextStyle(
                        color: greyColor,
                        fontFamily: FontFamily.jost,
                        fontWeight: FontWeight.bold,
                        fontSize: 13.sp,
                        letterSpacing: 1)),
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: ElevatedButton(
                onPressed: _isSubmitting || _isLocationLoading
                    ? null
                    : () async {
                        final double? weight =
                            double.tryParse(_weightController.text);
                        final int? bags = int.tryParse(_bagController.text);
                        if (weight == null || weight <= 0.0) {
                          ToastMessage.show(context,
                              message: 'Please enter a valid weight',
                              isError: true);
                          return;
                        }
                        if (bags == null || bags <= 0) {
                          ToastMessage.show(context,
                              message: 'Please enter a valid bag count',
                              isError: true);
                          return;
                        }

                        final double? lat =
                            double.tryParse(_latController.text);
                        final double? lng =
                            double.tryParse(_lngController.text);

                        if (lat == null || lng == null) {
                          ToastMessage.show(context,
                              message:
                                  'GPS coordinates are required to receive transfer',
                              isError: true);
                          return;
                        }

                        setState(() {
                          _isSubmitting = true;
                        });

                        final sc = context.read<StockController>();
                        final success = await sc.receiveStockTransfer(
                          context: context,
                          transferId: widget.transfer.id!,
                          receivedWeight: weight,
                          receivedUnit: _selectedUnit,
                          receivedBagCount: bags,
                          receiveLatitude: lat,
                          receiveLongitude: lng,
                          receiveLocationText: _locTextController.text.isEmpty
                              ? null
                              : _locTextController.text,
                        );

                        if (mounted) {
                          setState(() {
                            _isSubmitting = false;
                          });
                        }

                        if (success && mounted) {
                          Navigator.pop(context);

                          // Print Receive PDF
                          final updatedTransfers =
                              sc.incomingTransfers.isNotEmpty
                                  ? sc.incomingTransfers
                                  : sc.vendorTransfers;
                          final updated = updatedTransfers.firstWhere(
                              (element) => element.id == widget.transfer.id,
                              orElse: () => widget.transfer);

                          // Preview PDF
                          _showPdfPreview(context, updated);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primeryColor,
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r)),
                ),
                child: _isSubmitting
                    ? SizedBox(
                        height: 16.h,
                        width: 16.w,
                        child: const CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Text('RECEIVE',
                        style: TextStyle(
                            color: Colors.white,
                            fontFamily: FontFamily.jost,
                            fontWeight: FontWeight.bold,
                            fontSize: 13.sp,
                            letterSpacing: 1)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showPdfPreview(BuildContext context, VendorTransferData transfer) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 500.h,
            child: PdfPreview(
              build: (format) =>
                  PdfTransferService.generateReceivePdf(transfer),
              allowPrinting: true,
              allowSharing: true,
              canChangePageFormat: false,
              canChangeOrientation: false,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Close',
                style: TextStyle(
                  color: primeryColor,
                  fontFamily: FontFamily.jost,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDialogField(String label, {required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.bold,
              fontFamily: FontFamily.jost,
              color: blackColor),
        ),
        SizedBox(height: 4.h),
        child,
      ],
    );
  }

  InputDecoration _inputDecoration(
      {required String hint, required IconData icon, Widget? suffixIcon}) {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFFF8FAF9),
      hintText: hint,
      prefixIcon: Icon(icon, size: 16.sp, color: primeryColor),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide(color: primeryColor, width: 1.5)),
      contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      isDense: true,
    );
  }
}
