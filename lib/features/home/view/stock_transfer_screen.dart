import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as pw;
import 'dart:io';
import 'package:soya_app/core/services/image_picker_service.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soya_app/features/bottom_navigation_bar/controller/bottom_navbar_controller.dart';
import 'package:soya_app/features/home/controller/stock_controller.dart';
import 'package:soya_app/features/home/model/goni_type_model.dart';
import 'package:soya_app/features/home/model/inventory_location_model.dart';
import 'package:soya_app/features/home/model/thappi_model.dart';
import 'package:soya_app/features/home/model/stock_transfer_item.dart';
import 'package:soya_app/features/home/model/stock_transfer_request.dart';
import 'package:soya_app/features/home/model/vendor_transfer_list_model.dart';
import 'package:soya_app/features/home/view/farmer_kyc_screen.dart';
import 'package:soya_app/features/home/view/widgets/bag_summary_tabs.dart';
import 'package:soya_app/features/home/view/widgets/receive_transfer_dialog.dart';
import 'package:soya_app/core/widgets/header_widget.dart';
import 'package:soya_app/core/widgets/tost_message.dart';
import 'package:soya_app/core/services/pdf_transfer_service.dart';
import 'package:soya_app/util/colors.dart';
import 'package:soya_app/util/font_family.dart';
import 'package:soya_app/core/widgets/empty_state_widget.dart';
import 'package:printing/printing.dart';
import 'package:dropdown_search/dropdown_search.dart';

class StockTransferScreen extends StatefulWidget {
  const StockTransferScreen({super.key});

  @override
  State<StockTransferScreen> createState() => _StockTransferScreenState();
}

class _StockTransferScreenState extends State<StockTransferScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final TextEditingController _vehicleNoController = TextEditingController();
  final TextEditingController _grossWeightController = TextEditingController();
  final TextEditingController _bagWeightController = TextEditingController();
  final TextEditingController _netWeightController = TextEditingController();
  final TextEditingController _bagCountController = TextEditingController();

  String? _selectedGoniTypeId;
  final String _selectedUnit = 'QTL';
  StockController? _stockController;

  // New Fields
  String?
      _selectedTransferType; // 'VENDOR_TO_VENDOR', 'VENDOR_TO_PLANT', 'VENDOR_TO_GODOWN', 'GODOWN_TO_PLANT', 'GODOWN_TO_VENDOR'
  String? _selectedSourceLocationId;
  String? _selectedDestinationLocationId;
  String? _selectedDestinationVendorId;
  bool _isThappiWise = false;
  List<Thappi> _selectedThappis = [];

  final List<Map<String, String>> _transferTypes = [
    {'label': 'Vendor → Vendor', 'value': 'VENDOR_TO_VENDOR'},
    {'label': 'Vendor → Plant', 'value': 'VENDOR_TO_PLANT'},
    {'label': 'Vendor → Godown', 'value': 'VENDOR_TO_GODOWN'},
    {'label': 'Godown → Plant', 'value': 'GODOWN_TO_PLANT'},
    {'label': 'Godown → Vendor', 'value': 'GODOWN_TO_VENDOR'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    _grossWeightController.addListener(_calculateNetWeight);
    _bagWeightController.addListener(_calculateNetWeight);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _stockController = Provider.of<StockController>(context, listen: false);
      _stockController?.fetchGoniTypes();
      _stockController?.fetchVendorStockSummary();
      _stockController?.getVendorTransfers(limit: 50);
      _stockController?.getVendorTransfers(limit: 50, type: 'incoming');
      _stockController?.fetchVendors();
      _stockController?.fetchVendorBagSummary();
      _stockController?.fetchInventoryLocations();

      _loadVendorName();
    });
  }

  void _calculateNetWeight() {
    double gross = double.tryParse(_grossWeightController.text) ?? 0.0;
    double bag = double.tryParse(_bagWeightController.text) ?? 0.0;
    double net = gross - bag;
    if (net < 0) net = 0;
    _netWeightController.text = net.toStringAsFixed(2);
  }

  Future<void> _loadVendorName() async {
    // Attempt to automatically match current vendor to a source location
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('userName');
    if (name != null && name.isNotEmpty) {
      // Just keep as helper context
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _grossWeightController.dispose();
    _bagWeightController.dispose();
    _netWeightController.dispose();
    _vehicleNoController.dispose();
    _bagCountController.dispose();
    super.dispose();
  }

  Future<void> _submitTransfer() async {
    final controller = Provider.of<StockController>(context, listen: false);

    if (_vehicleNoController.text.isEmpty ||
        _selectedTransferType == null ||
        _selectedSourceLocationId == null ||
        (_selectedTransferType!.endsWith('_TO_VENDOR')
            ? _selectedDestinationVendorId == null
            : _selectedDestinationLocationId == null)) {
      ToastMessage.show(context,
          message: 'Please fill all required routing fields', isError: true);
      return;
    }

    if (_isThappiWise && _selectedThappis.isEmpty) {
      ToastMessage.show(context,
          message: 'Please select at least one Thappi', isError: true);
      return;
    }

    if (!_isThappiWise && controller.selectedBags.isEmpty) {
      ToastMessage.show(context,
          message: 'Please add at least one bag type breakdown', isError: true);
      return;
    }

    double weight = double.tryParse(_netWeightController.text) ?? 0.0;
    if (weight <= 0.0) {
      ToastMessage.show(context,
          message: 'Net weight must be greater than 0', isError: true);
      return;
    }

    String? resolvedDestLocationId;
    if (_selectedTransferType!.endsWith('_TO_VENDOR')) {
      final activeLocations = controller.inventoryLocations
          .where((e) => e.isActive == true)
          .toList();
      final selectedVendor = controller.vendors
          .firstWhere((v) => v.id == _selectedDestinationVendorId);
      final destLoc = activeLocations.firstWhere(
          (loc) =>
              loc.type == 'VENDOR' &&
              (loc.vendorId == _selectedDestinationVendorId ||
                  loc.name
                      .toLowerCase()
                      .contains(selectedVendor.name?.toLowerCase() ?? '---')),
          orElse: () => activeLocations.firstWhere(
              (loc) => loc.type == 'VENDOR',
              orElse: () => activeLocations.first));
      resolvedDestLocationId = destLoc.id;
    } else {
      resolvedDestLocationId = _selectedDestinationLocationId;
    }

    // Step 1: Create Transfer (PENDING)
    final request = StockTransferRequest(
      weight: weight,
      unit: _selectedUnit,
      sourceLocationId: _selectedSourceLocationId!,
      destinationLocationId: resolvedDestLocationId!,
      vehicalNumber: _vehicleNoController.text,
      thappiIds:
          _isThappiWise ? _selectedThappis.map((t) => t.id).toList() : null,
      items: _isThappiWise
          ? null
          : controller.selectedBags
              .map((bag) => StockTransferItem(
                  bagCount: bag.bagCount, goniTypeId: bag.goniType.id!))
              .toList(),
      toVendorId: _selectedTransferType!.endsWith('_TO_VENDOR')
          ? _selectedDestinationVendorId
          : null,
    );

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Creating Transfer...'),
              ],
            ),
          ),
        ),
      ),
    );

    final transferId =
        await controller.stockTransfer(context: context, request: request);

    if (transferId != null) {
      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Clear fields
      _vehicleNoController.clear();
      _grossWeightController.clear();
      _bagWeightController.clear();
      _netWeightController.clear();
      _bagCountController.clear();
      _selectedTransferType = null;
      _selectedSourceLocationId = null;
      _selectedDestinationLocationId = null;
      _selectedDestinationVendorId = null;
      _selectedThappis = [];
      controller.clearBags();

      // Print/Generate PDF automatically
      final recentTransfers = controller.vendorTransfers;
      final createdTransfer = recentTransfers.firstWhere(
          (element) => element.id == transferId,
          orElse: () => recentTransfers.first);

      if (mounted) {
        _showPdfPreview(context, createdTransfer, isDispatch: true);
      }
    } else {
      if (mounted) Navigator.pop(context);
    }
  }

  void _showPdfPreview(BuildContext context, VendorTransferData transfer,
      {required bool isDispatch}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.85,
        child: Scaffold(
          appBar: AppBar(
            title: Text(
                isDispatch ? 'Dispatch Receipt PDF' : 'Receive Receipt PDF'),
            actions: [
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () async {
                  final pdfData = isDispatch
                      ? await PdfTransferService.generateDispatchPdf(transfer)
                      : await PdfTransferService.generateReceivePdf(transfer);
                  await Printing.sharePdf(
                      bytes: pdfData,
                      filename: 'transfer_${transfer.transferNo}.pdf');
                },
              )
            ],
          ),
          body: PdfPreview(
            build: (format) => isDispatch
                ? PdfTransferService.generateDispatchPdf(transfer)
                : PdfTransferService.generateReceivePdf(transfer),
            allowSharing: true,
            allowPrinting: true,
          ),
        ),
      ),
    );
  }

  void _showThappiSelectionDialog(StockController controller) {
    if (_selectedSourceLocationId == null) {
      ToastMessage.show(context,
          message: 'Please select a Source Location first', isError: true);
      return;
    }

    controller.fetchThappisForLocation(_selectedSourceLocationId!);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: BoxDecoration(
                color: whiteColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24.r),
                  topRight: Radius.circular(24.r),
                ),
              ),
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 50.w,
                      height: 5.h,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Text(
                    'Select Thappis (Stacks)',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      fontFamily: FontFamily.jost,
                    ),
                  ),
                  SizedBox(height: 15.h),
                  Expanded(
                    child: Consumer<StockController>(
                      builder: (context, sc, child) {
                        if (sc.isLoading) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        final availableThappis = sc.thappis
                            .where(
                                (t) => t.status?.toUpperCase() == 'AVAILABLE')
                            .toList();
                        if (availableThappis.isEmpty) {
                          return const Center(
                              child: Text(
                                  'No active Thappis found at this location.'));
                        }
                        return ListView.separated(
                          itemCount: availableThappis.length,
                          separatorBuilder: (context, idx) =>
                              SizedBox(height: 10.h),
                          itemBuilder: (context, idx) {
                            final thappi = availableThappis[idx];
                            final isSelected =
                                _selectedThappis.any((t) => t.id == thappi.id);
                            final bool isNotAvailable =
                                thappi.status?.toUpperCase() != 'AVAILABLE';
                            return InkWell(
                              onTap: isNotAvailable
                                  ? null
                                  : () {
                                      setModalState(() {
                                        if (isSelected) {
                                          _selectedThappis.removeWhere(
                                              (t) => t.id == thappi.id);
                                        } else {
                                          _selectedThappis.add(thappi);
                                        }
                                      });
                                    },
                              child: Container(
                                padding: EdgeInsets.all(12.w),
                                decoration: BoxDecoration(
                                  color: isNotAvailable
                                      ? Colors.grey.shade100
                                      : (isSelected
                                          ? primeryColor.withOpacity(0.05)
                                          : whiteColor),
                                  borderRadius: BorderRadius.circular(12.r),
                                  border: Border.all(
                                    color: isNotAvailable
                                        ? Colors.grey.shade300
                                        : (isSelected
                                            ? primeryColor
                                            : Colors.grey.shade300),
                                    width: isSelected ? 1.5 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Checkbox(
                                      activeColor: primeryColor,
                                      value: isSelected && !isNotAvailable,
                                      onChanged: isNotAvailable
                                          ? null
                                          : (val) {
                                              setModalState(() {
                                                if (isSelected) {
                                                  _selectedThappis.removeWhere(
                                                      (t) => t.id == thappi.id);
                                                } else {
                                                  _selectedThappis.add(thappi);
                                                }
                                              });
                                            },
                                    ),
                                    SizedBox(width: 8.w),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  'Thappi Code: ${thappi.code}',
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14.sp,
                                                    color: isNotAvailable
                                                        ? Colors.grey
                                                        : blackColor,
                                                  ),
                                                ),
                                              ),
                                              SizedBox(width: 8.w),
                                              if (thappi.status != null &&
                                                  thappi.status!.isNotEmpty)
                                                Container(
                                                  padding: EdgeInsets.symmetric(
                                                      horizontal: 6.w,
                                                      vertical: 2.h),
                                                  decoration: BoxDecoration(
                                                    color: isNotAvailable
                                                        ? Colors.red.shade50
                                                        : Colors.green.shade50,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            4.r),
                                                    border: Border.all(
                                                      color: isNotAvailable
                                                          ? Colors.red.shade200
                                                          : Colors
                                                              .green.shade200,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    thappi.status!
                                                        .toUpperCase(),
                                                    style: TextStyle(
                                                      fontSize: 10.sp,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: isNotAvailable
                                                          ? Colors.red.shade700
                                                          : Colors
                                                              .green.shade700,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                          SizedBox(height: 4.h),
                                          Text(
                                              'Weight: ${thappi.weightQtl} QTL | Moisture: ${thappi.moisture}%',
                                              style: TextStyle(
                                                  fontSize: 12.sp,
                                                  color: greyColor)),
                                          Text(
                                              'Bags: ${thappi.bagBreakdown.map((e) => "${e.bagCount}x ${e.name ?? 'Bags'}").join(", ")}',
                                              style: TextStyle(
                                                  fontSize: 11.sp,
                                                  color: greyColor)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 15.h),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            // First close the bottom sheet, then show create dialog, or just show dialog over it
                            // It's better to show dialog over it so they can see the thappis after creation
                            _showCreateThappiDialog(controller);
                          },
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            side: BorderSide(color: primeryColor),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.r)),
                          ),
                          child: Text('Create New Thappi',
                              style: TextStyle(
                                  color: primeryColor, fontSize: 14.sp)),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              // Aggregate values
                              double totalWeight = _selectedThappis.fold(
                                  0.0, (sum, t) => sum + t.weightQtl);
                              _grossWeightController.text = "";
                              _bagWeightController.text = "";
                              _netWeightController.text =
                                  totalWeight.toStringAsFixed(2);
                            });
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            backgroundColor: primeryColor,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.r)),
                          ),
                          child: Text('Confirm (${_selectedThappis.length})',
                              style: TextStyle(
                                  color: whiteColor, fontSize: 14.sp)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showCreateThappiDialog(StockController controller) {
    final TextEditingController weightCtrl = TextEditingController();
    final TextEditingController moistureCtrl = TextEditingController();
    final TextEditingController fmCtrl = TextEditingController();
    final TextEditingController damageCtrl = TextEditingController();

    List<Map<String, dynamic>> bagBreakdown = [];
    String? selectedGoniTypeId;
    final TextEditingController bagCountCtrl = TextEditingController();
    bool isCreating = false;
    File? selectedImageFile;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r)),
              title: Text('Create New Thappi',
                  style: TextStyle(
                      fontFamily: FontFamily.jost,
                      fontWeight: FontWeight.bold,
                      fontSize: 18.sp)),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: double.maxFinite,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldLabel('Weight (QTL)'),
                      _buildTextField(
                        controller: weightCtrl,
                        keyboardType: TextInputType.number,
                      ),
                      SizedBox(height: 12.h),
                      /*
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel('Moisture %'),
                                _buildTextField(
                                  controller: moistureCtrl,
                                  keyboardType: TextInputType.number,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel('FM %'),
                                _buildTextField(
                                  controller: fmCtrl,
                                  keyboardType: TextInputType.number,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel('Damage %'),
                                _buildTextField(
                                  controller: damageCtrl,
                                  keyboardType: TextInputType.number,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12.h),*/
                      _buildFieldLabel('Thappi Photo (Optional)'),
                      InkWell(
                        onTap: () async {
                          final file =
                              await ImagePickerService.pickFile(context);
                          if (file != null) {
                            setModalState(() {
                              selectedImageFile = file;
                            });
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(
                              vertical: 12.h, horizontal: 16.w),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.camera_alt_outlined,
                                  color: primeryColor),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Text(
                                  selectedImageFile != null
                                      ? p.basename(selectedImageFile!.path)
                                      : 'Select Thappi Photo (Max 5MB)',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: selectedImageFile != null
                                        ? blackColor
                                        : greyColor,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (selectedImageFile != null)
                                InkWell(
                                  onTap: () {
                                    setModalState(() {
                                      selectedImageFile = null;
                                    });
                                  },
                                  child: Icon(Icons.cancel,
                                      color: Colors.red.shade400, size: 20.sp),
                                ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 16.h),
                      const Divider(),
                      SizedBox(height: 2.h),
                      Text('Bag Breakdown',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14.sp)),
                      SizedBox(height: 12.h),
                      _buildFieldLabel('Select Bag Type'),
                      _buildDropdown<String>(
                        value: selectedGoniTypeId,
                        hint: 'Select Bag Type',
                        items: controller.goniTypes.map((g) {
                          return DropdownMenuItem(
                              value: g.id,
                              child: Text(g.name ?? 'Unknown',
                                  style: TextStyle(fontSize: 14.sp)));
                        }).toList(),
                        onChanged: (val) =>
                            setModalState(() => selectedGoniTypeId = val),
                      ),
                      SizedBox(height: 12.h),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel('Bag Count'),
                                _buildTextField(
                                  controller: bagCountCtrl,
                                  keyboardType: TextInputType.number,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 12.w),
                          ElevatedButton(
                            onPressed: () {
                              if (selectedGoniTypeId != null &&
                                  bagCountCtrl.text.isNotEmpty) {
                                setModalState(() {
                                  bagBreakdown.add({
                                    'goniTypeId': selectedGoniTypeId,
                                    'bagCount':
                                        int.tryParse(bagCountCtrl.text) ?? 0,
                                  });
                                  bagCountCtrl.clear();
                                  selectedGoniTypeId = null;
                                });
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primeryColor,
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16.w, vertical: 12.h),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6.r)),
                            ),
                            child: Text('Add',
                                style: TextStyle(color: whiteColor)),
                          )
                        ],
                      ),
                      if (bagBreakdown.isNotEmpty) ...[
                        SizedBox(height: 16.h),
                        ...bagBreakdown.map((b) {
                          final goniName = controller.goniTypes
                              .firstWhere((g) => g.id == b['goniTypeId'])
                              .name;
                          return Container(
                            margin: EdgeInsets.only(bottom: 8.h),
                            padding: EdgeInsets.symmetric(
                                horizontal: 12.w, vertical: 10.h),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('${b['bagCount']} x $goniName',
                                    style: TextStyle(
                                        fontSize: 13.sp,
                                        fontWeight: FontWeight.w500)),
                                InkWell(
                                  onTap: () {
                                    setModalState(() {
                                      bagBreakdown.remove(b);
                                    });
                                  },
                                  child: const Icon(Icons.close,
                                      size: 20, color: Colors.red),
                                ),
                              ],
                            ),
                          );
                        }),
                      ]
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('CANCEL', style: TextStyle(color: greyColor)),
                ),
                ElevatedButton(
                  onPressed: isCreating
                      ? null
                      : () async {
                          if (weightCtrl.text.isEmpty) {
                            ToastMessage.show(context,
                                message: 'Please fill weight', isError: true);
                            return;
                          }
                          if (bagBreakdown.isEmpty) {
                            ToastMessage.show(context,
                                message: 'Please add at least one bag type',
                                isError: true);
                            return;
                          }

                          setModalState(() {
                            isCreating = true;
                          });

                          final success = await controller.createThappi(
                            context: context,
                            locationId: _selectedSourceLocationId!,
                            weightQtl: double.tryParse(weightCtrl.text) ?? 0.0,
                            moisture: moistureCtrl.text.isNotEmpty
                                ? double.tryParse(moistureCtrl.text)
                                : null,
                            fm: fmCtrl.text.isNotEmpty
                                ? double.tryParse(fmCtrl.text)
                                : null,
                            damage: damageCtrl.text.isNotEmpty
                                ? double.tryParse(damageCtrl.text)
                                : null,
                            bagBreakdown: bagBreakdown,
                            image: selectedImageFile,
                          );

                          if (mounted) {
                            setModalState(() {
                              isCreating = false;
                            });
                          }

                          if (success && mounted) {
                            Navigator.pop(context);
                          }
                        },
                  style:
                      ElevatedButton.styleFrom(backgroundColor: primeryColor),
                  child: isCreating
                      ? SizedBox(
                          width: 16.w,
                          height: 16.h,
                          child: CircularProgressIndicator(
                              color: whiteColor, strokeWidth: 2))
                      : Text('CREATE', style: TextStyle(color: whiteColor)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showReceiveDialog(
      BuildContext context, VendorTransferData transfer, StockController sc) {
    showDialog(
      context: context,
      builder: (context) {
        return ReceiveTransferDialog(transfer: transfer);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<StockController>();
    return Scaffold(
      backgroundColor: lightGreenColor,
      body: SafeArea(
        child: Column(
          children: [
            const HeaderWidget(),
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      controller.clearBags();
                      Provider.of<BottomNavBarController>(context,
                              listen: false)
                          .updateFormView(FormView.selection);
                    },
                    icon: Icon(Icons.arrow_back_ios,
                        color: blackColor, size: 24.sp),
                  ),
                  Text(
                    'Stock & Inventory Flow',
                    style: TextStyle(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.bold,
                      fontFamily: FontFamily.jost,
                      color: blackColor,
                    ),
                  ),
                ],
              ),
            ),
            TabBar(
              controller: _tabController,
              labelColor: primeryColor,
              unselectedLabelColor: greyColor,
              indicatorColor: primeryColor,
              labelStyle: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  fontFamily: FontFamily.jost),
              tabs: const [
                Tab(text: 'New Transfer'),
                Tab(text: 'Incoming'),
                Tab(text: 'History'),
                Tab(text: 'Bag Summary'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: New Transfer
                  _buildNewTransferTab(controller),

                  // Tab 2: Incoming
                  _buildIncomingTab(controller),

                  // Tab 3: History
                  _buildHistoryTab(controller),

                  // Tab 4: Bag Summary
                  BagSummaryContentView(controller: controller),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildNewTransferTab(StockController controller) {
    final activeLocations =
        controller.inventoryLocations.where((e) => e.isActive == true).toList();

    // Filters for locations based on transfer type
    List<InventoryLocation> sourceOptions = [];
    List<InventoryLocation> destOptions = [];

    if (_selectedTransferType != null) {
      if (_selectedTransferType!.startsWith('VENDOR_TO_')) {
        sourceOptions =
            activeLocations.where((e) => e.type == 'VENDOR').toList();
      } else if (_selectedTransferType!.startsWith('GODOWN_TO_')) {
        sourceOptions =
            activeLocations.where((e) => e.type == 'GODOWN').toList();
      }

      if (_selectedTransferType!.endsWith('_TO_VENDOR')) {
        destOptions = activeLocations.where((e) => e.type == 'VENDOR').toList();
      } else if (_selectedTransferType!.endsWith('_TO_PLANT')) {
        destOptions = activeLocations.where((e) => e.type == 'PLANT').toList();
      } else if (_selectedTransferType!.endsWith('_TO_GODOWN')) {
        destOptions = activeLocations.where((e) => e.type == 'GODOWN').toList();
      }
    }

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      child: Column(
        children: [
          // Available stock summary display card
          _buildStockSummaryCard(controller),
          SizedBox(height: 20.h),

          // Routing Section
          _buildFormSection(
            title: 'Routing & Transfer Type',
            icon: Icons.alt_route,
            children: [
              _buildFieldLabel('Transfer Operations Type'),
              _buildDropdown<String>(
                value: _selectedTransferType,
                hint: 'Select Transfer Type',
                items: _transferTypes
                    .map((e) => DropdownMenuItem(
                        value: e['value'], child: Text(e['label']!)))
                    .toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedTransferType = val;
                    _selectedSourceLocationId = null;
                    _selectedDestinationLocationId = null;
                    _selectedDestinationVendorId = null;
                    _selectedThappis = [];
                  });
                },
              ),
              SizedBox(height: 12.h),
              if (_selectedTransferType != null) ...[
                _buildFieldLabel('Source Location'),
                _buildDropdown<String>(
                  value: _selectedSourceLocationId,
                  hint: 'Select Source Location',
                  items: sourceOptions
                      .map((e) => DropdownMenuItem(
                          value: e.id, child: Text("${e.name} (${e.code})")))
                      .toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedSourceLocationId = val;
                      _selectedThappis = [];
                    });
                  },
                ),
                SizedBox(height: 12.h),
                if (_selectedTransferType!.endsWith('_TO_VENDOR')) ...[
                  _buildFieldLabel('Destination Vendor'),
                  _buildSearchableVendorDropdown(controller),
                  SizedBox(height: 12.h),
                  _buildFieldLabel('Destination Location'),
                  _buildDropdown<String>(
                    value: _selectedDestinationLocationId,
                    hint: 'Select Destination Location',
                    items: destOptions
                        .map((e) => DropdownMenuItem(
                            value: e.id, child: Text("${e.name} (${e.code})")))
                        .toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedDestinationLocationId = val;
                      });
                    },
                  ),
                ] else ...[
                  _buildFieldLabel('Destination Location'),
                  _buildDropdown<String>(
                    value: _selectedDestinationLocationId,
                    hint: 'Select Destination',
                    items: destOptions
                        .map((e) => DropdownMenuItem(
                            value: e.id, child: Text("${e.name} (${e.code})")))
                        .toList(),
                    onChanged: (val) {
                      setState(() => _selectedDestinationLocationId = val);
                    },
                  ),
                ],
              ]
            ],
          ),

          // Logistics
          _buildFormSection(
            title: 'Logistics Details',
            icon: Icons.local_shipping_outlined,
            children: [
              _buildFieldLabel('Vehical Number'),
              _buildTextField(
                controller: _vehicleNoController,
                inputFormatters: [UpperCaseTextFormatter()],
              ),
            ],
          ),

          // Quantity & Stock / Thappis
          _buildFormSection(
            title: 'Soyabean Quantity & Bags Breakdown',
            icon: Icons.inventory_2_outlined,
            children: [
              // Selection mode
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Transfer Thappi-Wise?',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13.sp)),
                  Switch(
                    activeThumbColor: primeryColor,
                    value: _isThappiWise,
                    onChanged: (val) {
                      setState(() {
                        _isThappiWise = val;
                        _grossWeightController.text = "";
                        _bagWeightController.text = "";
                        _netWeightController.text = "";
                        _selectedThappis = [];
                      });
                    },
                  ),
                ],
              ),
              SizedBox(height: 12.h),

              if (_isThappiWise) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: ElevatedButton.icon(
                    style:
                        ElevatedButton.styleFrom(backgroundColor: primeryColor),
                    onPressed: () => _showThappiSelectionDialog(controller),
                    icon: const Icon(Icons.grid_view_rounded,
                        color: Colors.white),
                    label: const Text('SELECT THAPPIS',
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
                if (_selectedThappis.isNotEmpty) ...[
                  SizedBox(height: 12.h),
                  _buildFieldLabel('Selected Stacks/Thappis'),
                  Wrap(
                    spacing: 8.w,
                    runSpacing: 4.h,
                    children: _selectedThappis.map((t) {
                      return Chip(
                        label: Text('${t.code} (${t.weightQtl} QTL)'),
                        deleteIcon: const Icon(Icons.close, size: 14),
                        onDeleted: () {
                          setState(() {
                            _selectedThappis.removeWhere((x) => x.id == t.id);
                            double totalWeight = _selectedThappis.fold(
                                0.0, (sum, x) => sum + x.weightQtl);
                            _netWeightController.text =
                                totalWeight.toStringAsFixed(2);
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ] else ...[
                // Custom gross, bag, net weights
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('Gross Weight (QTL)'),
                          _buildTextField(
                              controller: _grossWeightController,
                              keyboardType: TextInputType.number),
                        ],
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('Bag Weight (QTL)'),
                          _buildTextField(
                              controller: _bagWeightController,
                              keyboardType: TextInputType.number),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                _buildFieldLabel('Net Weight (QTL) - Auto Calculated'),
                _buildTextField(
                    controller: _netWeightController, readOnly: true),

                SizedBox(height: 16.h),
                const Divider(),
                SizedBox(height: 8.h),
                Text('Add Bag Count Breakdowns',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13.sp)),
                SizedBox(height: 10.h),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('Bag Type'),
                          _buildGoniDropdown(controller.goniTypes),
                        ],
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('Count'),
                          _buildTextField(
                              controller: _bagCountController,
                              keyboardType: TextInputType.number),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    style:
                        ElevatedButton.styleFrom(backgroundColor: primeryColor),
                    onPressed: () {
                      if (_selectedGoniTypeId != null &&
                          _bagCountController.text.isNotEmpty) {
                        int count = int.tryParse(_bagCountController.text) ?? 0;
                        if (count > 0) {
                          final goni = controller.goniTypes.firstWhere(
                              (element) => element.id == _selectedGoniTypeId);
                          controller.addBag(goni, count);
                          _bagCountController.clear();
                        }
                      }
                    },
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text('ADD BAG BREAKDOWN',
                        style: TextStyle(color: Colors.white)),
                  ),
                ),

                if (controller.selectedBags.isNotEmpty) ...[
                  SizedBox(height: 16.h),
                  _buildFieldLabel('Added Bags'),
                  ...controller.selectedBags.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final bag = entry.value;
                    final isKaltani =
                        bag.goniType.name?.toLowerCase().contains('kaltani') ==
                            true;
                    return Container(
                      margin: EdgeInsets.only(bottom: 8.h),
                      padding: EdgeInsets.all(10.w),
                      decoration: BoxDecoration(
                        color: whiteColor,
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    '${bag.goniType.name} (${bag.goniType.weightPerBag} Kg)',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                Text(
                                    isKaltani
                                        ? 'Updates Inventory Stock'
                                        : 'Recorded for Reference Only',
                                    style: TextStyle(
                                        fontSize: 11.sp,
                                        color: isKaltani
                                            ? Colors.green.shade800
                                            : Colors.orange.shade800)),
                              ],
                            ),
                          ),
                          Text('${bag.bagCount} Bags',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => controller.removeBag(idx)),
                        ],
                      ),
                    );
                  }),
                ]
              ],
            ],
          ),

          SizedBox(height: 20.h),
          SizedBox(
            width: double.infinity,
            height: 50.h,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primeryColor),
              onPressed: controller.isLoading ? null : () => _submitTransfer(),
              child: controller.isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text('DISPATCH TRANSFER',
                      style: TextStyle(
                          color: whiteColor,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold)),
            ),
          ),
          SizedBox(height: 40.h),
        ],
      ),
    );
  }

  Widget _buildIncomingTab(StockController sc) {
    // Show active dispatched transfers heading to this vendor
    final incoming = sc.incomingTransfers
        .where((e) => e.status?.toUpperCase() == 'DISPATCHED')
        .toList();
    if (incoming.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.call_received,
        title: 'No Incoming Stock',
        description:
            'No active dispatched transfers destined for your location.',
      );
    }
    return ListView.separated(
      padding: EdgeInsets.all(20.w),
      itemCount: incoming.length,
      separatorBuilder: (context, idx) => SizedBox(height: 12.h),
      itemBuilder: (context, idx) {
        final transfer = incoming[idx];
        return Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: whiteColor,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(transfer.transferNo ?? 'N/A',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15.sp,
                          color: primeryColor)),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20.r)),
                    child: Text('DISPATCHED',
                        style: TextStyle(
                            color: Colors.orange,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const Divider(height: 24),
              _buildLocationRoutingRow(transfer),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                        'D Weight: ${transfer.dispatchedWeight ?? transfer.weight} ${transfer.unit}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(width: 8),
                  Text(
                      '${transfer.dispatchedBagCount ?? transfer.bagCount} Kaltani Bags'),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Vehicle Number: ${transfer.vehicalNumber ?? "N/A"}',
                style: TextStyle(
                  fontSize: 13.sp,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style:
                      ElevatedButton.styleFrom(backgroundColor: primeryColor),
                  onPressed: () => _showReceiveDialog(context, transfer, sc),
                  icon: const Icon(Icons.check, color: Colors.white),
                  label: const Text('RECEIVE & VERIFY',
                      style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHistoryTab(StockController sc) {
    if (sc.vendorTransfers.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.history,
        title: 'No History Found',
        description: 'Once you transfer stock, they will appear here.',
      );
    }
    return ListView.separated(
      padding: EdgeInsets.all(20.w),
      itemCount: sc.vendorTransfers.length,
      separatorBuilder: (context, idx) => SizedBox(height: 12.h),
      itemBuilder: (context, idx) {
        final transfer = sc.vendorTransfers[idx];
        final isDiscrepancy = transfer.status?.toUpperCase() == 'DISCREPANCY';
        final isReceived = transfer.status?.toUpperCase() == 'RECEIVED';

        return Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: whiteColor,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
                color:
                    isDiscrepancy ? Colors.red.shade300 : Colors.grey.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(transfer.transferNo ?? 'N/A',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15.sp)),
                  _buildStatusBadge(transfer.status ?? 'PENDING'),
                ],
              ),
              const Divider(height: 20),
              _buildLocationRoutingRow(transfer),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Weight: ${transfer.weight} ${transfer.unit}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('Vehicle: ${transfer.vehicalNumber}'),
                ],
              ),
              if (isReceived || isDiscrepancy) ...[
                const SizedBox(height: 8),
                Text(
                    'Received: ${transfer.receivedWeight} ${transfer.receivedUnit ?? transfer.unit} | Bags: ${transfer.receivedBagCount}',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade800)),
              ],
              if (isDiscrepancy) ...[
                const SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(6.r)),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          color: Colors.red, size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                            'Shortage: ${transfer.weightDifference} QTL | Missing: ${transfer.bagDifference} Bags',
                            style: const TextStyle(
                                color: Colors.red, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          _showPdfPreview(context, transfer, isDispatch: true),
                      icon: const Icon(Icons.picture_as_pdf, size: 16),
                      label: const Text('Dispatch Proof',
                          style: TextStyle(fontSize: 11)),
                    ),
                  ),
                  if (isReceived || isDiscrepancy) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showPdfPreview(context, transfer,
                            isDispatch: false),
                        icon: const Icon(Icons.picture_as_pdf, size: 16),
                        label: const Text('Receive Verification',
                            style: TextStyle(fontSize: 11)),
                      ),
                    ),
                  ]
                ],
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildLocationRoutingRow(VendorTransferData transfer) {
    return Row(
      children: [
        const Icon(Icons.location_on_outlined, color: Colors.grey, size: 16),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            "${transfer.sourceLocation?.name ?? transfer.vendor?.name ?? 'N/A'} → ${transfer.destinationLocation?.name ?? transfer.toVendor?.name ?? 'N/A'}",
            style: TextStyle(
                fontSize: 12.sp,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildStockSummaryCard(StockController controller) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.amber.shade100, Colors.orange.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.orange.withOpacity(0.3), width: 1),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics_outlined,
                    color: Colors.amber[800], size: 20.sp),
                SizedBox(width: 10.w),
                Text(
                  'Vendor Available Stock Summary',
                  style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.amber[900],
                      fontFamily: FontFamily.jost),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      const Text('Total Weight',
                          style: TextStyle(color: Colors.grey, fontSize: 11)),
                      Text(
                          '${controller.totalAvailableWeight.toStringAsFixed(2)} QTL',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                ),
                Container(
                    height: 30.h,
                    width: 1,
                    color: Colors.orange.withOpacity(0.3)),
                Expanded(
                  child: Column(
                    children: [
                      const Text('Kaltani Bags',
                          style: TextStyle(color: Colors.grey, fontSize: 11)),
                      Text('${controller.totalRemainingBags} Bags',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormSection(
      {required String title,
      required IconData icon,
      required List<pw.Widget> children}) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18.sp, color: primeryColor),
              SizedBox(width: 8.w),
              Text(title,
                  style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      fontFamily: FontFamily.jost,
                      color: blackColor)),
            ],
          ),
          SizedBox(height: 16.h),
          ...children.map((e) => e),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Text(label,
          style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              color: blackColor,
              fontFamily: FontFamily.jost)),
    );
  }

  Widget _buildTextField({
    TextEditingController? controller,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    bool readOnly = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: BoxDecoration(
        color: readOnly ? Colors.grey.shade100 : whiteColor,
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(color: Colors.grey.withOpacity(0.4), width: 0.5),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        readOnly: readOnly,
        style: TextStyle(
            fontSize: 14.sp,
            fontFamily: FontFamily.jost,
            color: readOnly ? Colors.grey.shade600 : blackColor),
        decoration: InputDecoration(
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.symmetric(vertical: 12.h)),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T? value,
    required String hint,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      height: 48.h,
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(color: Colors.grey.withOpacity(0.4), width: 0.5),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Text(hint,
              style: TextStyle(
                  fontSize: 14.sp,
                  fontFamily: FontFamily.jost,
                  color: Colors.grey)),
          isExpanded: true,
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildSearchableVendorDropdown(StockController controller) {
    final selectedVendor =
        controller.vendors.any((v) => v.id == _selectedDestinationVendorId)
            ? controller.vendors
                .firstWhere((v) => v.id == _selectedDestinationVendorId)
            : null;

    return Container(
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(color: Colors.grey.withOpacity(0.4), width: 0.5),
      ),
      child: DropdownSearch<VendorShort>(
        popupProps: PopupProps.menu(
          showSearchBox: true,
          searchFieldProps: TextFieldProps(
            style: TextStyle(
              fontSize: 14.sp,
              fontFamily: FontFamily.jost,
              color: blackColor,
            ),
            decoration: InputDecoration(
              hintText: "Search Vendor...",
              hintStyle: TextStyle(
                fontSize: 14.sp,
                fontFamily: FontFamily.jost,
                color: Colors.grey,
              ),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6.r),
                borderSide:
                    BorderSide(color: Colors.grey.withOpacity(0.4), width: 0.5),
              ),
            ),
          ),
        ),
        items: controller.vendors,
        itemAsString: (item) =>
            "${item.name ?? 'Unknown'} (${item.phone ?? ''})",
        compareFn: (i1, i2) => i1.id == i2.id,
        dropdownDecoratorProps: DropDownDecoratorProps(
          dropdownSearchDecoration: InputDecoration(
            filled: true,
            fillColor: whiteColor,
            isDense: true,
            hintText: 'Select Destination Vendor',
            hintStyle: TextStyle(
              fontSize: 14.sp,
              fontFamily: FontFamily.jost,
              color: Colors.grey,
            ),
            contentPadding:
                EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            border: InputBorder.none,
          ),
          baseStyle: TextStyle(
            fontSize: 14.sp,
            fontFamily: FontFamily.jost,
            color: blackColor,
          ),
        ),
        onChanged: (val) {
          setState(() {
            _selectedDestinationVendorId = val?.id;
            if (val != null) {
              final activeLocations = controller.inventoryLocations
                  .where((e) => e.isActive == true)
                  .toList();
              final destLoc = activeLocations.firstWhere(
                  (loc) =>
                      loc.type == 'VENDOR' &&
                      (loc.vendorId == val.id ||
                          loc.name
                              .toLowerCase()
                              .contains(val.name?.toLowerCase() ?? '---')),
                  orElse: () => activeLocations.firstWhere(
                      (loc) => loc.type == 'VENDOR',
                      orElse: () => activeLocations.first));
              _selectedDestinationLocationId = destLoc.id;
            } else {
              _selectedDestinationLocationId = null;
            }
          });
        },
        selectedItem: selectedVendor,
      ),
    );
  }

  Widget _buildGoniDropdown(List<GoniType> goniTypes) {
    const defaultGoniId = "134b6ab2-1fd3-4ce9-ab39-fb13feec1096";
    if (_selectedGoniTypeId == null && goniTypes.isNotEmpty) {
      final defaultGoni =
          goniTypes.where((e) => e.id == defaultGoniId).firstOrNull;
      if (defaultGoni != null) {
        _selectedGoniTypeId = defaultGoni.id;
      }
    }

    return _buildDropdown<String>(
      value: _selectedGoniTypeId,
      hint: 'Select Bag Type',
      items: goniTypes.map((GoniType type) {
        return DropdownMenuItem<String>(
          value: type.id,
          child: Text(type.name ?? 'Unknown',
              style: TextStyle(fontSize: 14.sp, fontFamily: FontFamily.jost)),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() => _selectedGoniTypeId = newValue);
      },
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status.toUpperCase()) {
      case 'COMPLETED':
      case 'RECEIVED':
        color = Colors.green;
        break;
      case 'PENDING':
        color = Colors.orange;
        break;
      case 'DISPATCHED':
        color = Colors.blue;
        break;
      case 'DISCREPANCY':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: color, width: 0.5),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
            fontSize: 10.sp,
            fontWeight: FontWeight.bold,
            color: color,
            fontFamily: FontFamily.jost),
      ),
    );
  }
}
