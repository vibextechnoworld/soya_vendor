import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:soya_app/core/widgets/header_widget.dart';
import 'package:soya_app/core/widgets/name_initials_avatar.dart';
import 'package:soya_app/features/home/controller/billing_controller.dart';
import 'package:soya_app/features/login_and_signup/controller/login_controller.dart';
import 'package:soya_app/features/home/model/farmer_model.dart';
import 'package:soya_app/util/colors.dart';
import 'package:soya_app/util/font_family.dart';
import 'package:soya_app/features/bottom_navigation_bar/controller/bottom_navbar_controller.dart';
import 'package:soya_app/features/home/model/save_bill_request.dart';
import 'package:soya_app/features/home/model/deduction_master_model.dart';
import 'package:soya_app/features/home/model/goni_type_model.dart';
import 'package:soya_app/features/home/model/quality_rate_model.dart';
import 'package:soya_app/routes/app_routes.dart';
import 'package:soya_app/core/widgets/tost_message.dart';

class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  late BillingController _billingController;
  final TextEditingController _farmerNameController = TextEditingController();
  final TextEditingController _netWeightController = TextEditingController();
  final TextEditingController _numBagsController = TextEditingController();
  final TextEditingController _rateController = TextEditingController();
  final TextEditingController _vehicleNumberController =
      TextEditingController();
  final TextEditingController _driverNameController = TextEditingController();
  final TextEditingController _returnBagCountController =
      TextEditingController();
  final TextEditingController _returnNotesController = TextEditingController();
  final Map<String, TextEditingController> _qualityControllers = {};

  final FocusNode _farmerFocusNode = FocusNode();
  int _currentStep = 0;
  Timer? _qualityDebounce;

  @override
  void initState() {
    super.initState();
    _billingController = context.read<BillingController>();
    _billingController.addListener(_onBillingControllerUpdate);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Check if we are editing an existing bill
      final isEditing = _billingController.editingBillId != null;

      if (!isEditing) {
        // Reset controller state for a fresh new bill
        _billingController.resetForNewBill();

        // Reset local UI state
        _currentStep = 0;
        _farmerNameController.clear();
        _netWeightController.clear();
        _numBagsController.clear();
        _rateController.clear();
        _vehicleNumberController.clear();
        _driverNameController.clear();
        _returnBagCountController.clear();
        _returnNotesController.clear();
        for (var controller in _qualityControllers.values) {
          controller.clear();
        }
      }

      _billingController.fetchDeductionMasters();
      _billingController.fetchGoniTypes();
      _billingController.fetchTodaysRates();

      // Pre-fill for Update
      if (isEditing && _billingController.selectedBillDetails != null) {
        _isEditingDraft = true;
        final bill = _billingController.selectedBillDetails!;
        _farmerNameController.text = bill.farmer?.name ?? '';
        _netWeightController.text =
            ((bill.primaryQuantity ?? bill.items?.firstOrNull?.quantity ?? 0) * 100)
                .toString();
        _rateController.text =
            (bill.ratePerUnit ?? bill.items?.firstOrNull?.rate ?? 0)
                .toString();
        _numBagsController.text =
            (bill.bagCount ?? bill.items?.firstOrNull?.bagCount ?? 0)
                .toString();
        _vehicleNumberController.text = bill.vehicleNumber ?? '';
        _driverNameController.text = bill.driverName ?? '';
        _billingController.restoreEditingState(bill);

        // Sync _actualQualityValues so deduction calculation uses restored values
        for (final entry
            in _billingController.deductionVariableValues.entries) {
          _billingController.updateQualityValue(entry.key, entry.value);
        }
      }
    });
  }

  bool _isEditingDraft = false;

  void _onBillingControllerUpdate() {
    if (!mounted) return;
    if (_isEditingDraft) return;
    if (_billingController.selectedQuality != null) {
      _rateController.text =
          (_billingController.selectedQuality!.rate ?? 0).toString();
    } else {
      _rateController.clear();
    }
  }

  String _formatRateDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final date = DateTime.parse(dateStr).toLocal();
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year;

      int hour = date.hour;
      final minute = date.minute.toString().padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';
      hour = hour % 12;
      if (hour == 0) hour = 12;
      final hourStr = hour.toString().padLeft(2, '0');

      return '$day/$month/$year $hourStr:$minute $period';
    } catch (e) {
      if (dateStr.length >= 10) {
        return dateStr.substring(0, 10);
      }
      return dateStr;
    }
  }

  @override
  void dispose() {
    _billingController.removeListener(_onBillingControllerUpdate);
    _farmerNameController.dispose();
    _netWeightController.dispose();
    _numBagsController.dispose();
    _rateController.dispose();
    _vehicleNumberController.dispose();
    _driverNameController.dispose();
    _returnBagCountController.dispose();
    _returnNotesController.dispose();
    for (var controller in _qualityControllers.values) {
      controller.dispose();
    }
    _billingController.resetForNewBill();
    _farmerFocusNode.dispose();
    _qualityDebounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightGreenColor,
      body: SafeArea(
        child: Column(
          children: [
            const HeaderWidget(),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Consumer<BillingController>(
                  builder: (context, controller, child) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 10.h),
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: IconButton(
                                onPressed: () {
                                  if (_currentStep > 0) {
                                    setState(() => _currentStep--);
                                  } else {
                                    Provider.of<BottomNavBarController>(
                                      context,
                                      listen: false,
                                    ).updateFormView(FormView.selection);
                                  }
                                },
                                icon: Icon(
                                  Icons.arrow_back_ios,
                                  color: blackColor,
                                  size: 24.sp,
                                ),
                              ),
                            ),
                            Text(
                              'Billing',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 36.sp,
                                fontWeight: FontWeight.bold,
                                fontFamily: FontFamily.georgia,
                                color: blackColor,
                              ),
                            ),
                            // Eye icon for billing history
                            // Align(
                            //     alignment: Alignment.centerRight,
                            //     child: IconButton(
                            //       onPressed: () {
                            //         // Navigate to Billing History
                            //         // TODO: Implement navigation
                            //       },
                            //       icon: Icon(Icons.remove_red_eye_outlined,
                            //           color: blackColor),
                            //     ))
                          ],
                        ),
                        SizedBox(height: 16.h),
                        // Today's Rate Display
                        if (controller.todaysRates.isNotEmpty) ...[
                          Container(
                            width: double.infinity,
                            margin: EdgeInsets.only(bottom: 20.h),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(8.r),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFF3E0),
                                        borderRadius:
                                            BorderRadius.circular(8.r),
                                      ),
                                      child: Icon(Icons.trending_up,
                                          color: const Color(0xFFEF6C00),
                                          size: 20.sp), // Orange
                                    ),
                                    SizedBox(width: 12.w),
                                    Text(
                                      "Today's Rates",
                                      style: TextStyle(
                                        fontSize: 18.sp,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: FontFamily.jost,
                                        color: blackColor,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 12.h),
                                SizedBox(
                                  height: 110.h,
                                  child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    physics: const BouncingScrollPhysics(),
                                    itemCount: controller.todaysRates.length +
                                        (controller.vendorRate > 0 ? 1 : 0),
                                    separatorBuilder: (context, index) =>
                                        SizedBox(width: 12.w),
                                    itemBuilder: (context, index) {
                                      final bool isMyRate =
                                          controller.vendorRate > 0 &&
                                              index == 0;
                                      final rate = isMyRate
                                          ? QualityRateData(
                                              quality: 'my_rate',
                                              rate: controller.vendorRate)
                                          : controller.todaysRates[
                                              controller.vendorRate > 0
                                                  ? index - 1
                                                  : index];

                                      final rawQuality =
                                          rate.quality ?? 'Unknown';
                                      // Format: first_quality -> First Quality
                                      final qualityName = isMyRate
                                          ? controller.vendorName
                                          : rawQuality
                                              .split('_')
                                              .map((word) => word.isNotEmpty
                                                  ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
                                                  : '')
                                              .join(' ');

                                      // Determine color based on index or quality for variety
                                      final colors = [
                                        const Color(0xFFE3F2FD), // Blue
                                        const Color(0xFFE8F5E9), // Green
                                        const Color(0xFFF3E5F5), // Purple
                                      ];
                                      final borderColors = [
                                        const Color(0xFF2196F3),
                                        const Color(0xFF4CAF50),
                                        const Color(0xFF9C27B0),
                                      ];
                                      final colorIndex = index % colors.length;

                                      final bool isMaster = context
                                              .read<LoginController>()
                                              .masterVendor ==
                                          true;
                                      return InkWell(
                                        onTap: isMaster
                                            ? () {
                                                controller.selectQuality(rate);
                                              }
                                            : null,
                                        borderRadius:
                                            BorderRadius.circular(12.r),
                                        child: Container(
                                          width: 165.w,
                                          padding: EdgeInsets.all(12.w),
                                          decoration: BoxDecoration(
                                            color: colors[colorIndex],
                                            borderRadius:
                                                BorderRadius.circular(12.r),
                                            border: Border.all(
                                              color: borderColors[colorIndex]
                                                  .withOpacity(0.3),
                                              width: 1,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withOpacity(0.05),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Container(
                                                padding: EdgeInsets.symmetric(
                                                    horizontal: 8.w,
                                                    vertical: 4.h),
                                                decoration: BoxDecoration(
                                                  color: whiteColor,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          4.r),
                                                ),
                                                child: Text(
                                                  qualityName,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontSize: 12.sp,
                                                    fontWeight: FontWeight.w600,
                                                    color: borderColors[
                                                        colorIndex],
                                                    fontFamily: FontFamily.jost,
                                                  ),
                                                ),
                                              ),
                                              const Spacer(),
                                              Text(
                                                "₹${rate.rate}",
                                                style: TextStyle(
                                                  fontSize: 20.sp,
                                                  fontWeight: FontWeight.bold,
                                                  color: blackColor,
                                                  fontFamily: FontFamily.jost,
                                                ),
                                              ),
                                              Text(
                                                "per Quintal",
                                                style: TextStyle(
                                                  fontSize: 10.sp,
                                                  color: greyColor,
                                                  fontFamily: FontFamily.jost,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        SizedBox(height: 20.h),
                        _buildStepperHeader(),
                        SizedBox(height: 24.h),

                        // STEP 0: DRAFT CREATION
                        if (_currentStep == 0) ...[
                          _buildFieldLabel('Search Farmer'),
                          // Row(
                          //   children: [
                          //     _buildSearchTypeRadioButton(
                          //         controller, FarmerSearchType.name, 'Name'),
                          //     SizedBox(width: 20.w),
                          //     _buildSearchTypeRadioButton(controller,
                          //         FarmerSearchType.aadhaar, 'Aadhaar No.'),
                          //   ],
                          // ),
                          SizedBox(height: 10.h),
                          _buildFarmerSearchField(controller),
                          if (controller.selectedFarmer != null) ...[
                            SizedBox(height: 12.h),
                            _buildSelectedFarmerCard(
                                controller.selectedFarmer!),
                          ],
                          if (controller.searchedFarmers.isNotEmpty)
                            _buildSuggestionsList(controller),
                          if (!controller.isLoading &&
                              controller.searchedFarmers.isEmpty &&
                              _farmerNameController.text.isNotEmpty &&
                              controller.selectedFarmer == null)
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.h),
                              child: Text(
                                "No farmers found",
                                style: TextStyle(
                                  color: Colors.red.shade400,
                                  fontSize: 12.sp,
                                  fontFamily: FontFamily.jost,
                                ),
                              ),
                            ),
                          if (controller.isLoading &&
                              controller.searchedFarmers.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          SizedBox(height: 16.h),
                          if (context.read<LoginController>().masterVendor ==
                              true) ...[
                            _buildFieldLabel('Select Billing Date'),
                            GestureDetector(
                              onTap: () async {
                                DateTime? pickedDate = await showDatePicker(
                                  context: context,
                                  initialDate: controller.selectedBillingDate ??
                                      DateTime.now(),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now(),
                                  builder: (context, child) {
                                    return Theme(
                                      data: Theme.of(context).copyWith(
                                        colorScheme: ColorScheme.light(
                                          primary: primeryColor,
                                          onPrimary: whiteColor,
                                          onSurface: blackColor,
                                        ),
                                        textButtonTheme: TextButtonThemeData(
                                          style: TextButton.styleFrom(
                                            foregroundColor: primeryColor,
                                          ),
                                        ),
                                      ),
                                      child: child!,
                                    );
                                  },
                                );
                                if (pickedDate != null) {
                                  controller.setSelectedBillingDate(pickedDate);
                                  await controller.fetchRatesByDate(pickedDate,
                                      context: context);
                                }
                              },
                              child: Container(
                                height: 48.h,
                                width: double.infinity,
                                padding: EdgeInsets.symmetric(horizontal: 12.w),
                                decoration: BoxDecoration(
                                  color: whiteColor,
                                  borderRadius: BorderRadius.circular(6.r),
                                  border: Border.all(
                                      color: Colors.grey.withOpacity(0.4),
                                      width: 0.5),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      controller.selectedBillingDate == null
                                          ? "Select Date"
                                          : "${controller.selectedBillingDate!.day.toString().padLeft(2, '0')}/${controller.selectedBillingDate!.month.toString().padLeft(2, '0')}/${controller.selectedBillingDate!.year}",
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        fontFamily: FontFamily.jost,
                                        color: blackColor,
                                      ),
                                    ),
                                    Icon(
                                      Icons.calendar_today,
                                      color: primeryColor,
                                      size: 20.sp,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: 16.h),
                            _buildFieldLabel('Selected Rate'),
                            (() {
                              final List<QualityRateData> options = [];
                              if (controller.todaysRates.isNotEmpty) {
                                options.addAll(controller.todaysRates);
                              }
                              if (controller.vendorRate > 0) {
                                final vendorRateOption = QualityRateData(
                                  quality: 'my_rate',
                                  rate: controller.vendorRate,
                                );
                                if (!options.any((o) =>
                                    o.quality == 'my_rate' &&
                                    o.rate == controller.vendorRate)) {
                                  options.add(vendorRateOption);
                                }
                              }
                              if (controller.selectedQuality != null &&
                                  !options
                                      .contains(controller.selectedQuality)) {
                                options.insert(0, controller.selectedQuality!);
                              }

                              if (options.isEmpty) {
                                return Container(
                                  height: 48.h,
                                  width: double.infinity,
                                  padding:
                                      EdgeInsets.symmetric(horizontal: 12.w),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(6.r),
                                    border: Border.all(
                                        color: Colors.grey.withOpacity(0.3),
                                        width: 0.5),
                                  ),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      "No rate available for this date",
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        fontFamily: FontFamily.jost,
                                        color: greyColor,
                                      ),
                                    ),
                                  ),
                                );
                              }

                              return Container(
                                height: 48.h,
                                width: double.infinity,
                                padding: EdgeInsets.symmetric(horizontal: 12.w),
                                decoration: BoxDecoration(
                                  color: whiteColor,
                                  borderRadius: BorderRadius.circular(6.r),
                                  border: Border.all(
                                      color: Colors.grey.withOpacity(0.4),
                                      width: 0.5),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<QualityRateData>(
                                    value: options.contains(
                                            controller.selectedQuality)
                                        ? controller.selectedQuality
                                        : options.first,
                                    isExpanded: true,
                                    items: options.map((item) {
                                      final isMyRate =
                                          item.quality == 'my_rate';
                                      final rawQuality =
                                          item.quality ?? 'Unknown';
                                      final qualityName = isMyRate
                                          ? controller.vendorName
                                          : rawQuality
                                              .split('_')
                                              .map((word) => word.isNotEmpty
                                                  ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
                                                  : '')
                                              .join(' ');
                                      final rateVal = item.rate ?? 0;

                                      return DropdownMenuItem<QualityRateData>(
                                        value: item,
                                        child: Text.rich(
                                          TextSpan(
                                            text: "$qualityName - ₹$rateVal",
                                            style: TextStyle(
                                              fontSize: 13.sp,
                                              fontFamily: FontFamily.jost,
                                              color: blackColor,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            children: [
                                              if (item.createdAt != null)
                                                TextSpan(
                                                  text:
                                                      ' (${_formatRateDate(item.createdAt)})',
                                                  style: TextStyle(
                                                    fontSize: 12.sp,
                                                    fontFamily: FontFamily.jost,
                                                    color: greyColor,
                                                    fontWeight: FontWeight.w400,
                                                  ),
                                                ),
                                            ],
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (QualityRateData? newValue) {
                                      if (newValue != null) {
                                        controller.selectQuality(newValue);
                                      }
                                    },
                                  ),
                                ),
                              );
                            })(),
                          ] else ...[
                            _buildFieldLabel('Selected Rate'),
                            Container(
                              height: 48.h,
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(horizontal: 12.w),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(6.r),
                                border: Border.all(
                                    color: Colors.grey.withOpacity(0.3),
                                    width: 0.5),
                              ),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: (() {
                                  if (controller.selectedQuality?.quality ==
                                      'my_rate') {
                                    return Text(
                                      "${controller.vendorName} - ₹${controller.vendorRate}",
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        fontFamily: FontFamily.jost,
                                        color: blackColor,
                                      ),
                                    );
                                  }
                                  if (controller.selectedQuality == null) {
                                    if (controller.vendorRate > 0) {
                                      return Text(
                                        "${controller.vendorName} - ₹${controller.vendorRate}",
                                        style: TextStyle(
                                          fontSize: 14.sp,
                                          fontFamily: FontFamily.jost,
                                          color: blackColor,
                                        ),
                                      );
                                    }
                                    return Text(
                                      'No Rate Selected',
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        fontFamily: FontFamily.jost,
                                        color: blackColor,
                                      ),
                                    );
                                  }

                                  final rawQuality =
                                      controller.selectedQuality!.quality ??
                                          'Unknown';
                                  final qualityName = rawQuality
                                      .split('_')
                                      .map((word) => word.isNotEmpty
                                          ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
                                          : '')
                                      .join(' ');
                                  final rateVal =
                                      controller.selectedQuality!.rate ?? 0;

                                  return Text.rich(
                                    TextSpan(
                                      text: "$qualityName - ₹$rateVal",
                                      style: TextStyle(
                                        fontSize: 13.sp,
                                        fontFamily: FontFamily.jost,
                                        color: blackColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      children: [
                                        if (controller
                                                .selectedQuality!.createdAt !=
                                            null)
                                          TextSpan(
                                            text:
                                                ' (${_formatRateDate(controller.selectedQuality!.createdAt)})',
                                            style: TextStyle(
                                              fontSize: 10.sp,
                                              fontFamily: FontFamily.jost,
                                              color: greyColor,
                                            ),
                                          ),
                                      ],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  );
                                })(),
                              ),
                            ),
                          ],
                          SizedBox(height: 16.h),
                          Row(
                            children: [
                              Expanded(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                    _buildFieldLabel('Kilogram (KG)'),
                                    _buildTextField(
                                        controller: _netWeightController,
                                        keyboardType: TextInputType.number)
                                  ])),
                              SizedBox(width: 12.w),
                              Expanded(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                    _buildFieldLabel('Rate (₹/QTL)'),
                                    _buildTextField(
                                        controller: _rateController,
                                        readOnly: true,
                                        keyboardType: TextInputType.number)
                                  ])),
                            ],
                          ),
                          SizedBox(height: 16.h),
                          _buildFieldLabel('Vehicle Number'),
                          _buildTextField(
                            controller: _vehicleNumberController,
                            keyboardType: TextInputType.text,
                            textCapitalization: TextCapitalization.characters,
                            onChanged: (val) {
                              controller.setVehicleNumber(val.toUpperCase());
                            },
                          ),
                          SizedBox(height: 16.h),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildFieldLabel('Vehicle Type'),
                                    Container(
                                      height: 48.h,
                                      width: double.infinity,
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 12.w),
                                      decoration: BoxDecoration(
                                        color: whiteColor,
                                        borderRadius:
                                            BorderRadius.circular(6.r),
                                        border: Border.all(
                                            color: Colors.grey.withOpacity(0.4),
                                            width: 0.5),
                                      ),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          value: controller.vehicleType,
                                          isExpanded: true,
                                          items: ["Truck", "Tractor", "Pickup", "Tempo", "Bullock Cart", "Other"]
                                              .map((type) => DropdownMenuItem(
                                                    value: type,
                                                    child: Text(type,
                                                        style: TextStyle(
                                                            fontSize: 14.sp,
                                                            fontFamily:
                                                                FontFamily
                                                                    .jost)),
                                                  ))
                                              .toList(),
                                          onChanged: (value) {
                                            if (value != null) {
                                              controller.setVehicleType(value);
                                            }
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildFieldLabel('Driver Name'),
                                    _buildTextField(
                                      controller: _driverNameController,
                                      keyboardType: TextInputType.name,
                                      onChanged: (val) {
                                        controller.setDriverName(val);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ]

                        // STEP 1: WEIGHTS & BAGS
                        else if (_currentStep == 1) ...[
                          _buildFieldLabel('Select Bag Type'),
                          _buildGoniTypeDropdown(controller),
                          SizedBox(height: 16.h),
                          _buildFieldLabel('Number of Bags'),
                          _buildTextField(
                              controller: _numBagsController,
                              keyboardType: TextInputType.number,
                              onChanged: (val) {
                                setState(() {}); // Trigger rebuild
                              }),
                          SizedBox(height: 16.h),
                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                if (controller.selectedGoniType != null &&
                                    _numBagsController.text.isNotEmpty) {
                                  int count =
                                      int.tryParse(_numBagsController.text) ??
                                          0;
                                  if (count > 0) {
                                    controller.addBag(
                                        controller.selectedGoniType!, count);
                                    _numBagsController.clear();
                                    controller.selectGoniType(null);
                                  }
                                } else {
                                  ToastMessage.show(context,
                                      message:
                                          'Select Bag Type and enter Count',
                                      isError: true);
                                }
                              },
                              icon: Icon(Icons.add,
                                  color: whiteColor, size: 18.sp),
                              label: Text('Add Bag',
                                  style: TextStyle(
                                      color: whiteColor,
                                      fontFamily: FontFamily.jost)),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: primeryColor,
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(8.r))),
                            ),
                          ),
                          if (controller.selectedBags.isNotEmpty) ...[
                            SizedBox(height: 16.h),
                            _buildFieldLabel('Added Bags'),
                            ...controller.selectedBags
                                .asMap()
                                .entries
                                .map((entry) {
                              int idx = entry.key;
                              SelectedBag bag = entry.value;
                              return Container(
                                margin: EdgeInsets.only(bottom: 8.h),
                                padding: EdgeInsets.all(12.w),
                                decoration: BoxDecoration(
                                  color: whiteColor,
                                  borderRadius: BorderRadius.circular(8.r),
                                  border: Border.all(
                                      color: Colors.grey.withOpacity(0.3)),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                              "${bag.goniType.name ?? 'Unknown'} (${bag.goniType.weightPerBag} Kg)",
                                              style: TextStyle(
                                                  fontSize: 14.sp,
                                                  fontWeight: FontWeight.bold,
                                                  fontFamily: FontFamily.jost,
                                                  color: blackColor)),
                                          Text("${bag.bagCount} Bags",
                                              style: TextStyle(
                                                  fontSize: 12.sp,
                                                  color: greyColor,
                                                  fontFamily: FontFamily.jost)),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                            "${((bag.goniType.weightPerBag ?? 0) * bag.bagCount).toStringAsFixed(2)} Kg",
                                            style: TextStyle(
                                                fontSize: 14.sp,
                                                fontWeight: FontWeight.bold,
                                                color: primeryColor,
                                                fontFamily: FontFamily.jost)),
                                        Text(
                                            "(${(((bag.goniType.weightPerBag ?? 0) * bag.bagCount) / 100).toStringAsFixed(4)} QTL)",
                                            style: TextStyle(
                                                fontSize: 10.sp,
                                                color: primeryColor,
                                                fontFamily: FontFamily.jost)),
                                      ],
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red),
                                      onPressed: () =>
                                          controller.removeBag(idx),
                                    ),
                                  ],
                                ),
                              );
                            }),
                            SizedBox(height: 12.h),
                            Container(
                              padding: EdgeInsets.all(12.w),
                              decoration: BoxDecoration(
                                color: primeryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8.r),
                                border: Border.all(
                                    color: primeryColor.withOpacity(0.3)),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("Total Estimated Deduction:",
                                      style: TextStyle(
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w500,
                                          fontFamily: FontFamily.jost,
                                          color: blackColor)),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                            "${controller.selectedBags.fold(0.0, (sum, b) => sum.toDouble() + ((b.goniType.weightPerBag ?? 0) * b.bagCount)).toStringAsFixed(2)} Kg",
                                            style: TextStyle(
                                                fontSize: 16.sp,
                                                fontWeight: FontWeight.bold,
                                                fontFamily: FontFamily.jost,
                                                color: primeryColor)),
                                        Text(
                                            "(${controller.selectedBags.fold(0.0, (sum, b) => sum.toDouble() + (((b.goniType.weightPerBag ?? 0) * b.bagCount) / 100)).toStringAsFixed(4)} QTL)",
                                            style: TextStyle(
                                                fontSize: 12.sp,
                                                fontWeight: FontWeight.w600,
                                                fontFamily: FontFamily.jost,
                                                color: primeryColor)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ]

                        // STEP 2: DEDUCTIONS
                        else if (_currentStep == 2) ...[
                          if (controller.deductionMasters.isNotEmpty) ...[
                            Center(
                              child: Padding(
                                padding: EdgeInsets.only(bottom: 12.h),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Quality Analysis Details",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 18.sp,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: FontFamily.jost,
                                        color: blackColor,
                                      ),
                                    ),
                                    if (controller.currentDeductionAmount > 0)
                                      Text(
                                        " - ₹${controller.currentDeductionAmount.toStringAsFixed(4)}",
                                        style: TextStyle(
                                          fontSize: 18.sp,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: FontFamily.jost,
                                          color: redColor,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            // Consolidated Variation Dropdown
                            _buildSingleVariationDropdown(controller),

                            if (controller.selectedVariationMaster != null)
                              _buildQualityAnalysisTable(controller,
                                  controller.selectedVariationMaster!),
                          ] else
                            SizedBox(
                              height: 100.h,
                              child: Center(
                                  child: Text("No deductions required",
                                      style: TextStyle(fontSize: 16.sp))),
                            ),
                        ],

                        SizedBox(height: 32.h),

                        // Navigation Buttons
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: controller.isLoading
                                    ? null
                                    : () => _handleStepNavigation(controller),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: controller.isLoading
                                      ? whiteColor
                                      : primeryColor,
                                  minimumSize: Size(double.infinity, 50.h),
                                  shape: RoundedRectangleBorder(
                                    side: controller.isLoading
                                        ? BorderSide(color: primeryColor)
                                        : BorderSide.none,
                                  ),
                                ),
                                child: controller.isLoading
                                    ? SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                            color: primeryColor,
                                            strokeWidth: 2))
                                    : Text(
                                        _currentStep == 2 ? 'Next' : 'Next',
                                        style: TextStyle(
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.bold,
                                          color: whiteColor,
                                          fontFamily: FontFamily.jost,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 40.h),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w500,
          color: blackColor,
          fontFamily: FontFamily.jost,
        ),
      ),
    );
  }

  Widget _buildTextField({
    TextEditingController? controller,
    Function(String)? onChanged,
    FocusNode? focusNode,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    bool readOnly = false,
  }) {
    return Container(
      height: 48.h,
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(
          color: Colors.grey.withOpacity(0.4),
          width: 0.5,
        ),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        focusNode: focusNode,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        readOnly: readOnly,
        decoration: InputDecoration(
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6.r),
              borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6.r),
              borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6.r),
            borderSide: BorderSide(color: primeryColor, width: 1),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 12.w),
          fillColor: const Color(0xFFFCFCFC),
          filled: true,
        ),
        style: TextStyle(fontSize: 14.sp, fontFamily: FontFamily.jost),
      ),
    );
  }

  // Widget _buildSearchTypeRadioButton(
  //     BillingController controller, FarmerSearchType value, String label) {
  //   return InkWell(
  //     onTap: () {
  //       controller.setSearchType(value);
  //       _farmerNameController.clear();
  //     },
  //     child: Row(
  //       mainAxisSize: MainAxisSize.min,
  //       children: [
  //         Radio<FarmerSearchType>(
  //           value: value,
  //           groupValue: controller.searchType,
  //           activeColor: primeryColor,
  //           onChanged: (val) {
  //             if (val != null) {
  //               controller.setSearchType(val);
  //               _farmerNameController.clear();
  //             }
  //           },
  //         ),
  //         Text(label,
  //             style: TextStyle(fontSize: 14.sp, fontFamily: FontFamily.jost)),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildGoniTypeDropdown(BillingController controller) {
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
        child: DropdownButton<GoniType>(
          value: controller.selectedGoniType,
          isExpanded: true,
          hint: Text('Select Bag Type',
              style: TextStyle(fontSize: 14.sp, fontFamily: FontFamily.jost)),
          items: controller.goniTypes
              .map((goni) => DropdownMenuItem(
                  value: goni,
                  child: Text(
                      "${goni.name ?? 'Unknown'} (${goni.weightPerBag} kg)",
                      style: TextStyle(
                          fontSize: 14.sp, fontFamily: FontFamily.jost))))
              .toList(),
          onChanged: (value) =>
              value != null ? controller.selectGoniType(value) : null,
        ),
      ),
    );
  }

  Widget _buildUnitRadioButton(
      BillingController controller, String value, String label) {
    return InkWell(
      onTap: () {
        controller.setUnit(value);
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Radio<String>(
            value: value,
            groupValue: controller.selectedUnit,
            activeColor: primeryColor,
            onChanged: (val) {
              if (val != null) {
                controller.setUnit(val);
              }
            },
          ),
          Text(label,
              style: TextStyle(fontSize: 14.sp, fontFamily: FontFamily.jost)),
        ],
      ),
    );
  }

  Widget _buildFarmerSearchField(BillingController controller) {
    return Container(
      height: 48.h,
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(
          color: Colors.grey.withOpacity(0.4),
          width: 0.5,
        ),
      ),
      child: TextField(
        controller: _farmerNameController,
        focusNode: _farmerFocusNode,
        onChanged: (value) => controller.onSearchChanged(value),
        keyboardType: TextInputType.text,
        decoration: InputDecoration(
          hintText: 'Search farmer',
          hintStyle: TextStyle(
              fontSize: 14.sp,
              fontFamily: FontFamily.jost,
              color: greyColor.withOpacity(0.6)),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6.r),
              borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6.r),
              borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6.r),
              borderSide: BorderSide(color: primeryColor, width: 1)),
          contentPadding: EdgeInsets.symmetric(horizontal: 12.w),
          fillColor: const Color(0xFFFCFCFC),
          filled: true,
        ),
        style: TextStyle(fontSize: 14.sp, fontFamily: FontFamily.jost),
      ),
    );
  }

  Widget _buildSuggestionsList(BillingController controller) {
    return Container(
      margin: EdgeInsets.only(top: 4.h),
      constraints: BoxConstraints(maxHeight: 200.h),
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: BorderRadius.circular(8.r),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2))
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const ClampingScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: controller.searchedFarmers.length,
        separatorBuilder: (context, index) =>
            Divider(height: 1.h, color: Colors.grey.withOpacity(0.2)),
        itemBuilder: (context, index) {
          final farmer = controller.searchedFarmers[index];
          return ListTile(
            dense: true,
            title: Text(farmer.name ?? 'Unknown',
                style: TextStyle(
                    fontSize: 14.sp,
                    fontFamily: FontFamily.jost,
                    fontWeight: FontWeight.w500)),
            subtitle: Text('Aadhaar: ${farmer.aadhaarNo ?? 'N/A'}',
                style: TextStyle(
                    fontSize: 12.sp,
                    fontFamily: FontFamily.jost,
                    color: greyColor)),
            onTap: () {
              controller.selectFarmer(farmer);
              _farmerNameController.text = farmer.name ?? '';
              _farmerFocusNode.unfocus();
            },
          );
        },
      ),
    );
  }

  Widget _buildSelectedFarmerCard(FarmerData farmer) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: primeryColor.withOpacity(0.3), width: 1.h),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              NameInitialsAvatar(
                name: farmer.name ?? '',
                profileUrl: farmer.profileUrl,
                radius: 20.r,
                fontSize: 16.sp,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      farmer.name ?? 'Unknown',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        fontFamily: FontFamily.jost,
                        color: blackColor,
                      ),
                    ),
                    Text(
                      "Village: ${farmer.villageAdd ?? 'N/A'}",
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: greyColor,
                        fontFamily: FontFamily.jost,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.billingReport,
                        arguments: {
                          'search': farmer.name,
                          'ignoreVendorId': true,
                        },
                      );
                    },
                    icon: Icon(Icons.remove_red_eye_outlined,
                        size: 22.sp, color: primeryColor),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  SizedBox(width: 2.w),
                  IconButton(
                    onPressed: () {
                      context.read<BillingController>().reset();
                      _farmerNameController.clear();
                    },
                    icon: Icon(Icons.edit_outlined,
                        size: 22.sp, color: primeryColor),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 12.h),
          const Divider(height: 1),
          SizedBox(height: 12.h),
          Row(
            children: [
              _buildFarmerDetailItem(
                  Icons.badge_outlined, "Aadhaar", farmer.aadhaarNo ?? 'N/A'),
              SizedBox(width: 20.w),
              _buildFarmerDetailItem(Icons.phone_android_outlined, "Mobile",
                  farmer.phone ?? 'N/A'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFarmerDetailItem(IconData icon, String label, String value) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 14.sp, color: greyColor),
          SizedBox(width: 8.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10.sp,
                  color: greyColor,
                  fontFamily: FontFamily.jost,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: blackColor,
                  fontFamily: FontFamily.jost,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepperHeader() {
    return Row(
      children: [
        _buildStepItem(0, "Draft"),
        _buildStepDivider(),
        _buildStepItem(1, "Weights"),
        _buildStepDivider(),
        _buildStepItem(2, "Deduction"),
      ],
    );
  }

  Widget _buildStepItem(int step, String label) {
    bool isActive = _currentStep == step;
    bool isCompleted = _currentStep > step;

    return Expanded(
      child: Column(
        children: [
          Container(
            height: 32.h,
            width: 32.h,
            decoration: BoxDecoration(
              color: isCompleted
                  ? primeryColor
                  : (isActive ? primeryColor : whiteColor),
              shape: BoxShape.circle,
              border: Border.all(
                  color: isActive || isCompleted
                      ? primeryColor
                      : greyColor.withOpacity(0.4)),
            ),
            child: Center(
              child: isCompleted
                  ? Icon(Icons.check, color: whiteColor, size: 16.sp)
                  : Text(
                      "${step + 1}",
                      style: TextStyle(
                        color: isActive ? whiteColor : greyColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14.sp,
                      ),
                    ),
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.sp,
              color: isActive ? primeryColor : greyColor,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              fontFamily: FontFamily.jost,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepDivider() {
    return Container(
      width: 30.w,
      height: 1.h,
      color: greyColor.withOpacity(0.2),
      margin: EdgeInsets.only(bottom: 16.h),
    );
  }

  Future<void> _handleStepNavigation(BillingController controller) async {
    if (_currentStep == 0) {
      if (controller.selectedFarmer == null) {
        ToastMessage.show(context, message: 'Select a farmer', isError: true);
        return;
      }
      if (_netWeightController.text.isEmpty || _rateController.text.isEmpty) {
        ToastMessage.show(context,
            message: 'Quantity and Rate are required', isError: true);
        return;
      }

      final qty = double.tryParse(_netWeightController.text) ?? 0.0;
      final rate = double.tryParse(_rateController.text) ?? 0.0;

      final billDateVal = controller.selectedBillingDate ?? DateTime.now();
      final dateStr =
          "${billDateVal.year}-${billDateVal.month.toString().padLeft(2, '0')}-${billDateVal.day.toString().padLeft(2, '0')}";

      final request = SaveBillRequest(
        billId: controller.editingBillId,
        farmerId: controller.selectedFarmer!.id!,
        billDate: dateStr,
        productId: '',
        quantity: qty,
        unit: 'KG', // Default to KG as per request
        rate: rate,
        vehicleNumber: _vehicleNumberController.text,
        vehicleType: controller.vehicleType,
        driverName: _driverNameController.text,
      );

      final success =
          await controller.createDraftBill(context: context, request: request);
      if (success) setState(() => _currentStep = 1);
    } else if (_currentStep == 1) {
      if (controller.selectedBags.isEmpty) {
        ToastMessage.show(context,
            message: 'Please add at least one bag', isError: true);
        return;
      }

      final success = await controller.applyDraftGoniDeduction(
        context: context,
      );

      if (success) setState(() => _currentStep = 2);
    } else if (_currentStep == 2) {
      if (controller.deductionMasters.isNotEmpty) {
        final success = await controller.calculateDraftDeductions(
          context: context,
          silent: false,
        );
        if (success && mounted) {
          await controller.fetchBillPreview(controller.draftBillId!);
          if (!mounted) return;
          Navigator.pushNamed(
            context,
            AppRoutes.billSummary,
            arguments: controller.draftBillId!,
          );
        }
      } else {
        await controller.fetchBillPreview(controller.draftBillId!);
        if (!mounted) return;
        Navigator.pushNamed(
          context,
          AppRoutes.billSummary,
          arguments: controller.draftBillId!,
        );
      }
    }
  }

  String _getDisplayLabel(String? code, String? originalLabel) {
    if (code == 'mati') return 'FM';
    if (code == 'dagi') return 'Damage';
    if (code == 'moisture') return 'Moisture';

    if (originalLabel?.toLowerCase().contains('mati') == true ||
        originalLabel?.toLowerCase().contains('kadi') == true) {
      return 'FM';
    }
    if (originalLabel?.toLowerCase().contains('dagi') == true) {
      return 'Damage';
    }

    return originalLabel ?? code ?? '';
  }

  double _parseUnitHint(String? hint) {
    if (hint == null || hint.isEmpty) return 1.0;
    try {
      if (hint.contains('/')) {
        final parts = hint.split('/');
        if (parts.length == 2) {
          final num = double.tryParse(parts[0]) ?? 1.0;
          final den = double.tryParse(parts[1]) ?? 1.0;
          return num / den;
        }
      }
      return double.tryParse(hint) ?? 1.0;
    } catch (e) {
      return 1.0;
    }
  }

  double _calculateDeductionLocal(double actual, double allowed, String? hint) {
    if (actual <= allowed) return 0.0;

    if (hint != null && hint.startsWith('range:')) {
      final rulesStr = hint.replaceFirst('range:', '').split(',');
      double multiplier = 1.0;
      for (var rule in rulesStr) {
        if (rule.contains(':')) {
          final parts = rule.split(':');
          final condition = parts[0];
          final value = double.tryParse(parts[1]) ?? 1.0;

          if (condition.contains('-')) {
            final rangeParts = condition.split('-');
            if (rangeParts.length == 2) {
              final min = double.tryParse(rangeParts[0]) ?? 0;
              final max = double.tryParse(rangeParts[1]) ?? double.infinity;
              if (actual > min && actual <= max) {
                multiplier = value;
              }
            }
          } else if (condition.startsWith('>')) {
            final min = double.tryParse(condition.substring(1)) ?? 0;
            if (actual > min) {
              multiplier = value;
            }
          }
        }
      }
      return (actual - allowed) * multiplier;
    }

    return (actual - allowed) * _parseUnitHint(hint);
  }

  String _formatUnitHint(String hint) {
    if (hint.isEmpty) return "";
    if (hint.startsWith('range:')) {
      final rules = hint.replaceFirst('range:', '').split(',');
      List<String> formatted = [];
      for (var rule in rules) {
        if (rule.startsWith('<=variableValue')) continue;
        if (rule.contains(':')) {
          final parts = rule.split(':');
          final condition = parts[0];
          final multiplier = parts[1];

          if (condition.contains('-')) {
            formatted.add("$condition% ➔ ${multiplier}x");
          } else if (condition.startsWith('>')) {
            formatted.add("Above ${condition.substring(1)}% ➔ ${multiplier}x");
          }
        }
      }
      return "Rules: ${formatted.join(', ')}";
    }

    if (hint.contains('/')) {
      final val = _parseUnitHint(hint);
      return "Rule: ${(val * 100).toStringAsFixed(0)}% deduction per 1% excess";
    }

    return "Rule: ${hint}x deduction per 1% excess";
  }

  Widget _buildSingleVariationDropdown(BillingController controller) {
    final formulaMasters = controller.deductionMasters
        .where((m) => m.type == "FORMULA" && m.isActive == true)
        .toList();
    if (formulaMasters.isEmpty) return const SizedBox.shrink();

    // Create a list of all variations with their masters
    final List<MapEntry<String, DeductionMaster>> allVariations = [];
    for (var master in formulaMasters) {
      if (master.variableValues != null) {
        for (var val in master.variableValues!) {
          allVariations.add(MapEntry(val, master));
        }
      }
    }

    if (allVariations.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Select Formula",
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                fontFamily: FontFamily.jost,
                color: greyColor,
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        Container(
          height: 48.h,
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          decoration: BoxDecoration(
            color: whiteColor,
            borderRadius: BorderRadius.circular(6.r),
            border: Border.all(color: Colors.grey.withOpacity(0.4), width: 0.5),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<MapEntry<String, DeductionMaster>>(
              value: controller.selectedVariationValue != null &&
                      controller.selectedVariationMaster != null
                  ? allVariations.firstWhere(
                      (e) =>
                          e.key == controller.selectedVariationValue &&
                          e.value.id == controller.selectedVariationMaster!.id,
                      orElse: () => allVariations.first)
                  : allVariations.first,
              isExpanded: true,
              hint: Text('Select Formula',
                  style:
                      TextStyle(fontSize: 14.sp, fontFamily: FontFamily.jost)),
              items: allVariations.map((entry) {
                final variation = entry.key;
                final master = entry.value;
                final masterIndex = formulaMasters.indexOf(master) + 1;

                final label =
                    "Formula $masterIndex: $variation (${master.name ?? ''})";

                return DropdownMenuItem<MapEntry<String, DeductionMaster>>(
                  value: entry,
                  child: Text(label,
                      style: TextStyle(
                          fontSize: 14.sp, fontFamily: FontFamily.jost)),
                );
              }).toList(),
              onChanged: (entry) {
                if (entry != null) {
                  controller.selectDeductionVariation(entry.key, entry.value);
                  controller.calculateDraftDeductions(
                      context: context, silent: true);
                }
              },
            ),
          ),
        ),
        SizedBox(height: 16.h),
      ],
    );
  }

  Widget _buildQualityAnalysisTable(
      BillingController controller, DeductionMaster master) {
    return Container(
      margin: EdgeInsets.only(top: 10.h),
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          // Table Header
          Container(
            padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 10.w),
            decoration: BoxDecoration(
              color: greyColor.withOpacity(0.05),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12.r),
                topRight: Radius.circular(12.r),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                    flex: 3,
                    child: Text(master.name ?? "Analysis",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13.sp))),
                Expanded(
                    flex: 2,
                    child: Text("Allowed",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13.sp))),
                Expanded(
                    flex: 2,
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 4.h),
                      decoration: BoxDecoration(
                        color: primeryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Text("Actual",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13.sp,
                              color: primeryColor)),
                    )),
                // Expanded(
                //     flex: 2,
                //     child: Text("Deduction",
                //         textAlign: TextAlign.center,
                //         style: TextStyle(
                //             fontWeight: FontWeight.bold, fontSize: 13.sp))),
              ],
            ),
          ),
          const Divider(height: 1),
          // Rows
          // Dynamic Rows based on Deduction Master Variables
          if (master.variables != null) ...[
            ...master.variables!.map((variable) {
              final code = variable.code!;
              final label = _getDisplayLabel(code, variable.label);

              // Ensure we have a controller for this variable
              if (!_qualityControllers.containsKey(code)) {
                _qualityControllers[code] = TextEditingController();
                // Pre-fill from restored deduction values
                final restored = controller.deductionVariableValues[code] ??
                    controller.deductionVariableValues[variable.label];
                if (restored != null && restored > 0) {
                  _qualityControllers[code]!.text = restored.toStringAsFixed(2);
                  controller.updateQualityValue(code, restored);
                }
              }

              final rowController = _qualityControllers[code]!;
              final allowed =
                  controller.allowedValueByCode(code, master: master);
              final actual = double.tryParse(rowController.text) ?? 0.0;
              final deductionVal =
                  _calculateDeductionLocal(actual, allowed, variable.unitHint);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildQualityRow(
                    label: label,
                    allowed: allowed.toStringAsFixed(2),
                    controller: rowController,
                    deductionVal: deductionVal,
                    onChanged: (val) {
                      controller.updateQualityValue(
                          code, double.tryParse(val) ?? 0.0);
                      _onQualityInputChanged(controller, code);
                    },
                  ),
                  if (variable.unitHint != null &&
                      variable.unitHint!.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(left: 14.w, bottom: 8.h),
                      child: Text(_formatUnitHint(variable.unitHint!),
                          style: TextStyle(
                              color: greyColor,
                              fontSize: 11.sp,
                              fontFamily: FontFamily.jost)),
                    ),
                  const Divider(height: 1),
                ],
              );
            }),
            _buildTotalDeductionRow(controller, master),
          ],
        ],
      ),
    );
  }

  Widget _buildTotalDeductionRow(
      BillingController controller, DeductionMaster master) {
    // double totalDeductionVal = 0.0;
    // if (master.variables != null) {
    //   for (var variable in master.variables!) {
    //     final code = variable.code!;
    //     final rowController = _qualityControllers[code];
    //     if (rowController != null) {
    //       final allowed = controller.allowedValueByCode(code, master: master);
    //       final actual = double.tryParse(rowController.text) ?? 0.0;
    //       totalDeductionVal +=
    //           _calculateDeductionLocal(actual, allowed, variable.unitHint);
    //     }
    //   }
    // }

    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 10.w),
      decoration: BoxDecoration(
        color: primeryColor.withOpacity(0.05),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(12.r),
          bottomRight: Radius.circular(12.r),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              "Total",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14.sp,
                color: blackColor,
                fontFamily: FontFamily.jost,
              ),
            ),
          ),
          const Expanded(flex: 2, child: SizedBox()),
          const Expanded(flex: 2, child: SizedBox()),
          // Expanded(
          //   flex: 2,
          //   child: Text(
          //     totalDeductionVal.toStringAsFixed(2),
          //     textAlign: TextAlign.center,
          //     style: TextStyle(
          //       fontSize: 15.sp,
          //       fontWeight: FontWeight.bold,
          //       color: totalDeductionVal > 0 ? redColor : greyColor,
          //       fontFamily: FontFamily.jost,
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }

  void _onQualityInputChanged(BillingController controller, String code) {
    if (_qualityDebounce?.isActive ?? false) _qualityDebounce?.cancel();
    _qualityDebounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        controller.calculateDraftDeductions(context: context, silent: true);
      }
    });
  }

  Widget _buildQualityRow({
    required String label,
    required String allowed,
    required TextEditingController controller,
    required double deductionVal,
    required Function(String) onChanged,
    bool isLast = false,
  }) {
    // Use the passed deductionVal (which contains the unitHint logic)
    // final double displayDeduction = deductionVal;

    return Container(
      padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 10.w),
      decoration: BoxDecoration(
        color: isLast ? Colors.transparent : Colors.white,
      ),
      child: Row(
        children: [
          Expanded(
              flex: 3, child: Text(label, style: TextStyle(fontSize: 14.sp))),
          Expanded(
              flex: 2,
              child: Text(allowed,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14.sp, color: greyColor))),
          Expanded(
            flex: 2,
            child: Container(
              height: 38.h,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: primeryColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                textAlign: TextAlign.center,
                textAlignVertical: TextAlignVertical.center,
                keyboardType: TextInputType.number,
                style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                    fontFamily: FontFamily.jost,
                    color: primeryColor),
                decoration: InputDecoration(
                  hintText: "0.00",
                  fillColor: Colors.transparent,
                  filled: true,
                  hintStyle: TextStyle(color: greyColor.withOpacity(0.5)),
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
              ),
            ),
          ),
          // Expanded(
          //   flex: 2,
          //   child: Text(
          //     displayDeduction.toStringAsFixed(2),
          //     textAlign: TextAlign.center,
          //     style: TextStyle(
          //       fontSize: 14.sp,
          //       fontWeight: FontWeight.bold,
          //       color: displayDeduction > 0 ? redColor : greyColor,
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }
}
