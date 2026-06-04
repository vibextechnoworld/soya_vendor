import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:soya_app/features/home/controller/stock_controller.dart';
import 'package:soya_app/features/home/model/goni_type_model.dart';
import 'package:soya_app/util/colors.dart';
import 'package:soya_app/util/font_family.dart';
import 'package:soya_app/core/widgets/tost_message.dart';

class AddOpeningBagDialog extends StatefulWidget {
  const AddOpeningBagDialog({super.key});

  @override
  State<AddOpeningBagDialog> createState() => _AddOpeningBagDialogState();
}

class _AddOpeningBagDialogState extends State<AddOpeningBagDialog> {
  final TextEditingController _countController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  GoniType? _selectedGoniType;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StockController>().fetchGoniTypes();
    });
  }

  @override
  void dispose() {
    _countController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StockController>(
      builder: (context, controller, child) {
        // Auto-select "Kaltani Katta" as default if it exists and nothing is selected
        const defaultGoniId = "134b6ab2-1fd3-4ce9-ab39-fb13feec1096";
        if (_selectedGoniType == null && controller.goniTypes.isNotEmpty) {
          final defaultGoni = controller.goniTypes
              .where((e) => e.id == defaultGoniId)
              .firstOrNull;
          if (defaultGoni != null) {
            _selectedGoniType = defaultGoni;
          }
        }

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
          title: Text(
            'Add Opening Bags',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              fontFamily: FontFamily.jost,
              color: blackColor,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel('Select Bag Type'),
                SizedBox(height: 8.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w),
                  decoration: BoxDecoration(
                    color: whiteColor,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<GoniType>(
                      value: _selectedGoniType,
                      isExpanded: true,
                      hint: Text('Select Bag',
                          style: TextStyle(
                              fontSize: 14.sp,
                              fontFamily: FontFamily.jost,
                              color: greyColor)),
                      items: controller.goniTypes.map((type) {
                        return DropdownMenuItem<GoniType>(
                          value: type,
                          child: Text(
                            "${type.name ?? 'Unknown'} (${type.weightPerBag} kg)",
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontFamily: FontFamily.jost,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedGoniType = value;
                        });
                      },
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                _buildLabel('Bag Count'),
                SizedBox(height: 8.h),
                _buildTextField(
                  controller: _countController,
                  hint: 'Enter count',
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 16.h),
                _buildLabel('Notes (Optional)'),
                SizedBox(height: 8.h),
                _buildTextField(
                  controller: _notesController,
                  hint: 'Self added',
                  keyboardType: TextInputType.text,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(
                    color: greyColor,
                    fontFamily: FontFamily.jost,
                    fontSize: 14.sp),
              ),
            ),
            ElevatedButton(
              onPressed: controller.isLoading
                  ? null
                  : () async {
                      if (_selectedGoniType == null) {
                        ToastMessage.show(context,
                            message: 'Please select a bag type', isError: true);
                        return;
                      }
                      final count = int.tryParse(_countController.text) ?? 0;
                      if (count <= 0) {
                        ToastMessage.show(context,
                            message: 'Please enter a valid count', isError: true);
                        return;
                      }

                      final success = await controller.addOwnOpeningBags(
                        context: context,
                        goniTypeId: _selectedGoniType!.id!,
                        bagCount: count,
                        notes: _notesController.text,
                      );

                      if (success && mounted) {
                        Navigator.pop(context);
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: primeryColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r)),
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
              ),
              child: controller.isLoading
                  ? SizedBox(
                      height: 20.h,
                      width: 20.h,
                      child: CircularProgressIndicator(
                        color: whiteColor,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Submit',
                      style: TextStyle(
                          color: whiteColor,
                          fontFamily: FontFamily.jost,
                          fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.w500,
        fontFamily: FontFamily.jost,
        color: blackColor,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required TextInputType keyboardType,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: TextStyle(fontSize: 14.sp, fontFamily: FontFamily.jost),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: greyColor.withOpacity(0.5)),
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: 12.h),
        ),
      ),
    );
  }
}
