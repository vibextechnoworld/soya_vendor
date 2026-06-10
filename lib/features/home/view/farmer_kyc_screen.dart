import 'dart:async';
import 'dart:io';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soya_app/core/services/image_picker_service.dart';
import 'package:soya_app/features/bottom_navigation_bar/controller/bottom_navbar_controller.dart';
import 'package:soya_app/core/widgets/header_widget.dart';
import 'package:soya_app/core/widgets/tost_message.dart';
import 'package:soya_app/features/home/controller/farmer_kyc_controller.dart';
import 'package:soya_app/features/home/controller/land_controller.dart';
import 'package:soya_app/features/home/model/bank_detail_model.dart';
import 'package:soya_app/features/home/model/farmer_bank_model.dart';
import 'package:soya_app/features/home/model/farmer_land_model.dart';
import 'package:soya_app/features/home/model/farmer_model.dart';
import 'package:soya_app/core/constants/api_constants.dart';
import 'package:soya_app/util/colors.dart';
import 'package:soya_app/util/font_family.dart';
import 'package:soya_app/features/location/controller/location_provider.dart';
import 'package:soya_app/features/location/model/location_model.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:soya_app/features/home/view/farmer_kyc_list_screen.dart';

class FarmerKYCScreen extends StatefulWidget {
  const FarmerKYCScreen({super.key});

  @override
  State<FarmerKYCScreen> createState() => _FarmerKYCScreenState();
}

class _FarmerKYCScreenState extends State<FarmerKYCScreen> {
  // Form keys for validation
  final _farmerFormKey = GlobalKey<FormState>();
  final _documentFormKey = GlobalKey<FormState>();
  final _landFormKey = GlobalKey<FormState>();
  final _bankFormKey = GlobalKey<FormState>();

  // Farmer Details Controllers
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _aadhaarController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _gutNumberController = TextEditingController();

  // Document Controllers
  final _panNoController = TextEditingController();
  File? _profileImage;
  File? _aadhaarImage;
  File? _panImage;
  File? _licenseImage;

  // Land Details Controllers
  final _landTypeController = TextEditingController(text: 'OWN');
  final _areaController = TextEditingController();
  final _landOwnerNameController = TextEditingController();
  final _landRelationTypeController = TextEditingController();
  File? _landDocument;
  final _bloodRelationAreaController = TextEditingController();
  final _bloodRelationOwnerNameController = TextEditingController();
  final _bloodRelationRelationTypeController = TextEditingController();
  File? _bloodRelationLandDocument;

  // Land Address Controllers (New)
  final _landVillageController = TextEditingController();
  final _landTalukaController = TextEditingController();
  final _landDistrictController = TextEditingController();
  final _otherVillageController = TextEditingController();
  final _otherLandVillageController = TextEditingController();
  final _otherBankNameController = TextEditingController();

  // Bank Details Controllers
  final _bankNameController = TextEditingController();
  final _accountNoController = TextEditingController();
  final _confirmAccountNoController = TextEditingController();
  final TextEditingController _ifscController = TextEditingController();
  final _holderNameController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final _branchNameController = TextEditingController();
  String? _selectedBankId; // Master bank UUID from /bank-details/
  String?
      _farmerBankRecordId; // Farmer's own bank record UUID (from fetched BankData.id)
  File? _passbookImage;

  // Remote Image URLs for already uploaded documents
  String? _profileImageUrl;
  String? _aadhaarImageUrl;
  String? _panImageUrl;
  String? _licenseImageUrl;
  String? _landDocumentUrl;
  String? _bloodRelationLandDocumentUrl;
  String? _passbookImageUrl;

  bool _showBloodRelationLand = false;

  String? _authToken;
  String? _lastFarmerId;

  // Section expansion states
  // Section expansion states handled by currentStep in controller

  late FarmerKycController _controller;
  final LocationProvider _landLocationProvider = LocationProvider();

  @override
  void initState() {
    super.initState();
    _loadAuthToken();
    _controller = Provider.of<FarmerKycController>(context, listen: false);
    _setupControllerListener();
    _setupExistingCheckListeners();
    _landLocationProvider.loadData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<LocationProvider>(context, listen: false).loadData();
      _controller.fetchBankDetails();
      _controller.fetchNonKycFarmers();
    });
  }

  void _setupControllerListener() {
    _controller.addListener(_onControllerUpdate);
  }

  void _setupExistingCheckListeners() {
    _aadhaarController.addListener(_onAadhaarOrPhoneChanged);
    _phoneController.addListener(_onAadhaarOrPhoneChanged);
  }

  Timer? _existenceCheckDebounce;
  void _onAadhaarOrPhoneChanged() {
    if (_controller.createdFarmerId != null) return; // Already editing someone

    final aadhaar = _aadhaarController.text;
    final phone = _phoneController.text;

    if (aadhaar.length < 12 && phone.length < 10) return;

    _existenceCheckDebounce?.cancel();
    _existenceCheckDebounce = Timer(const Duration(milliseconds: 1000), () {
      if (aadhaar.length == 12) {
        _controller.searchFarmers(aadhaar).then((results) {
          if (results.isNotEmpty && _controller.createdFarmerId == null) {
            final match = results.firstWhere((f) => f.aadhaarNo == aadhaar,
                orElse: () => results.first);
            _showExistsSuggestion(match);
          }
        });
      } else if (phone.length == 10) {
        _controller.searchFarmers(phone).then((results) {
          if (results.isNotEmpty && _controller.createdFarmerId == null) {
            final match = results.firstWhere((f) => f.phone == phone,
                orElse: () => results.first);
            _showExistsSuggestion(match);
          }
        });
      }
    });
  }

  void _showExistsSuggestion(FarmerData farmer) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Farmer "${farmer.name}" already exists.'),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  Future<void> _loadAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _authToken = prefs.getString('token');
    });
  }

  void _onControllerUpdate() {
    if (!mounted) return;
    final controller = Provider.of<FarmerKycController>(context, listen: false);

    // If farmer changed (or cleared), reset local tracking and potentially controllers
    if (controller.createdFarmerId != _lastFarmerId) {
      if (controller.createdFarmerId != null && !controller.isJustCreated) {
        // Switching/selecting farmer - clear local controllers to force fresh fill
        _clearFormForNewSelection();
      }
      _lastFarmerId = controller.createdFarmerId;
    }

    if (controller.createdFarmerId != null) {
      // Check if data actually changed to avoid redundant setState
      final detail = controller.fetchedFarmerDetail;

      setState(() {
        if (detail != null) {
          final farmer = detail;

          // 1. Update root fields (Step 1)
          if (_firstNameController.text.isEmpty &&
              farmer.name != null &&
              farmer.name!.isNotEmpty) {
            final parts = farmer.name!.trim().split(RegExp(r'\s+'));
            _firstNameController.text = parts.isNotEmpty ? parts.first : '';
            if (parts.length > 1) {
              _lastNameController.text = parts.last;
            }
            if (parts.length > 2) {
              _middleNameController.text =
                  parts.sublist(1, parts.length - 1).join(' ');
            }
          }
          if (_gutNumberController.text.isEmpty) {
            _gutNumberController.text = farmer.gutNumber ?? '';
          }
          if (_emailController.text.isEmpty) {
            _emailController.text = farmer.email ?? '';
          }
          if (_aadhaarController.text.isEmpty) {
            _aadhaarController.text = farmer.aadhaarNo ?? '';
          }
          if (_phoneController.text.isEmpty) {
            _phoneController.text = farmer.phone ?? '';
          }
          if (_panNoController.text.isEmpty &&
              farmer.panNo != null &&
              farmer.panNo!.isNotEmpty) {
            _panNoController.text = farmer.panNo!;
          }

          // Initialize location provider if not already set or if we are loading existing data
          final locProvider =
              Provider.of<LocationProvider>(context, listen: false);
          if (locProvider.selectedDistrict == null && farmer.district != null) {
            locProvider.initializeValues(
              district: farmer.district,
              taluka: farmer.taluka,
              village: farmer.villageAdd,
            );

            // If the provider selected "Other", fill the custom controller
            if (locProvider.selectedVillage == LocationModel.other) {
              _otherVillageController.text = farmer.villageAdd ?? '';
            }
          }
        }

        if (controller.fetchedDocuments != null) {
          // Extract identification images and panNo if in docs
          final aadhaarDoc = controller.fetchedDocuments!
              .where((d) => d.type == 'AADHAAR')
              .firstOrNull;
          _aadhaarImageUrl = aadhaarDoc?.imageUrl;

          final panDoc = controller.fetchedDocuments!
              .where((d) => d.type == 'PAN')
              .firstOrNull;
          _panImageUrl = panDoc?.imageUrl;
          if (_panNoController.text.isEmpty && panDoc?.panNo != null) {
            _panNoController.text = panDoc!.panNo!;
          }

          final licenseDoc = controller.fetchedDocuments!
              .where((d) => d.type == 'DRIVING_LICENSE')
              .firstOrNull;
          _licenseImageUrl = licenseDoc?.imageUrl;

          // Land doc from documents list
          final landDoc = controller.fetchedDocuments!
              .where((d) => d.type == 'LAND_712' || d.type == 'LAND')
              .firstOrNull;
          if (landDoc != null) {
            if (_landTypeController.text.isEmpty ||
                _landTypeController.text == 'LAND_712') {
              _landTypeController.text = landDoc.type ?? 'OWN';
            }
            _landDocumentUrl = landDoc.imageUrl;
          }
        }

        if (controller.fetchedLands != null &&
            controller.fetchedLands!.isNotEmpty) {
          if (_areaController.text.isEmpty) {
            _fillLandData(controller.fetchedLands!.first);
          }
          _landDocumentUrl = controller.fetchedLands!.first.documentUrl;

          // Check for Blood Relation land in searched lands
          final bloodLand = controller.fetchedLands!
              .where((l) => l.landType == 'BLOOD_RELATION')
              .firstOrNull;
          if (bloodLand != null) {
            if (_bloodRelationAreaController.text.isEmpty) {
              _bloodRelationAreaController.text =
                  bloodLand.area?.toString() ?? '';
            }
            if (_bloodRelationOwnerNameController.text.isEmpty) {
              _bloodRelationOwnerNameController.text =
                  bloodLand.landOwnerName ?? '';
            }
            if (_bloodRelationRelationTypeController.text.isEmpty) {
              _bloodRelationRelationTypeController.text =
                  bloodLand.relationType ?? '';
            }
            _bloodRelationLandDocumentUrl = bloodLand.documentUrl;
            _showBloodRelationLand = true;
          }
        }

        if (controller.fetchedBank != null &&
            controller.fetchedBank!.isNotEmpty) {
          if (_bankNameController.text.isEmpty) {
            _fillBankData(controller.fetchedBank!.first);
          }
          if (_confirmAccountNoController.text.isEmpty) {
            _confirmAccountNoController.text =
                detail!.banks!.first.accountNo ?? '';
          }
          _passbookImageUrl = detail!.banks!.first.passbookImage;
        }

        if (controller.fetchedFarmerDetail != null) {
          _profileImageUrl = controller.fetchedFarmerDetail!.profileUrl;
        }
      });
    }
  }

  void _fillLandData(LandData land) {
    setState(() {
      _landTypeController.text = land.landType ?? 'OWN';
      _areaController.text = land.area?.toString() ?? '';
      _landOwnerNameController.text = land.landOwnerName ?? '';
      _landRelationTypeController.text = land.relationType ?? '';
      _landVillageController.text = land.villageAdd ?? '';
      _landTalukaController.text = land.taluka ?? '';
      _landDistrictController.text = land.district ?? '';

      // Initialize land location provider
      _landLocationProvider.initializeValues(
        district: land.district,
        taluka: land.taluka,
        village: land.villageAdd,
      );

      if (_landLocationProvider.selectedVillage == LocationModel.other) {
        _otherLandVillageController.text = land.villageAdd ?? '';
      }
    });
  }

  void _fillBankData(BankData bank) {
    setState(() {
      _bankNameController.text = bank.bankName ?? '';
      _accountNoController.text = bank.accountNo ?? '';
      _confirmAccountNoController.text = bank.accountNo ?? '';
      _ifscController.text = bank.ifsc ?? '';
      _holderNameController.text = bank.holderName ?? '';
      _branchNameController.text = bank.branchName ?? '';

      // Store farmer's bank record ID for update URL
      _farmerBankRecordId = bank.id;

      // Resolve master bank ID from bank name for update calls
      final masterBanks = _controller.bankDetails;
      final match = masterBanks.where(
          (b) => b.bankName?.toLowerCase() == bank.bankName?.toLowerCase());
      if (match.isNotEmpty) {
        _selectedBankId = match.first.id;
        if (_branchNameController.text.isEmpty) {
          _branchNameController.text = match.first.branchName ?? '';
        }
        _otherBankNameController.clear();
      } else {
        if (bank.bankName != null && bank.bankName!.isNotEmpty) {
          _selectedBankId = 'other';
          _otherBankNameController.text = bank.bankName!;
        } else {
          _selectedBankId = null;
          _otherBankNameController.clear();
        }
      }
      debugPrint(
          '🏦 _fillBankData - bankRecordId: ${bank.id}, bankName: ${bank.bankName}, resolved masterBankId: $_selectedBankId, branch: ${_branchNameController.text}');
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _aadhaarController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _gutNumberController.dispose();
    _panNoController.dispose();
    _landTypeController.dispose();
    _areaController.dispose();
    _landOwnerNameController.dispose();
    _landRelationTypeController.dispose();
    _bloodRelationAreaController.dispose();
    _bloodRelationOwnerNameController.dispose();
    _bloodRelationRelationTypeController.dispose();
    _landVillageController.dispose();
    _landTalukaController.dispose();
    _landDistrictController.dispose();
    _bankNameController.dispose();

    _accountNoController.dispose();
    _confirmAccountNoController.dispose();
    _ifscController.dispose();
    _holderNameController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    _branchNameController.dispose();
    _otherVillageController.dispose();
    _otherLandVillageController.dispose();
    _otherBankNameController.dispose();
    _landLocationProvider.dispose();
    _existenceCheckDebounce?.cancel();
    _aadhaarController.removeListener(_onAadhaarOrPhoneChanged);
    _phoneController.removeListener(_onAadhaarOrPhoneChanged);
    super.dispose();
  }

  Future<void> _pickImage(String type) async {
    try {
      final pickedFile = await ImagePickerService.pickFile(context);
      if (pickedFile != null) {
        // Save file permanently to avoid PathNotFoundException from cache clearing
        final persistentFile = await _saveFilePermanently(pickedFile, type);
        if (persistentFile == null) return;

        setState(() {
          if (type == 'PROFILE') {
            _profileImage = persistentFile;
          } else if (type == 'AADHAAR') {
            _aadhaarImage = persistentFile;
          } else if (type == 'PAN') {
            _panImage = persistentFile;
          } else if (type == 'LICENSE') {
            _licenseImage = persistentFile;
          } else if (type == 'LAND' || type == 'LAND_712') {
            _landDocument = persistentFile;
          } else if (type == 'PASSBOOK') {
            _passbookImage = persistentFile;
          } else if (type == 'BLOOD_RELATION' ||
              type == 'BLOOD_RELATION_LAND' ||
              type == 'BLOOD_RELATION_712') {
            _bloodRelationLandDocument = persistentFile;
          }
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ToastMessage.show(context,
            message: 'Error picking image: $e', isError: true);
      }
    }
  }

  Future<File?> _saveFilePermanently(File sourceFile, String prefix) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final name = p.basename(sourceFile.path);
      // Add timestamp to ensure uniqueness and avoid collision if same file name exists
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final permanentPath =
          p.join(directory.path, '${prefix}_${timestamp}_$name');
      return await sourceFile.copy(permanentPath);
    } catch (e) {
      debugPrint('Error saving file permanently: $e');
      if (mounted) {
        ToastMessage.show(context,
            message: 'Failed to save image locally', isError: true);
      }
      return null;
    }
  }

  Future<void> _handleNextStep() async {
    final controller = Provider.of<FarmerKycController>(context, listen: false);
    final currentStep = controller.currentStep;

    if (currentStep == 0) {
      // Step 1: Submit Farmer Details
      if (!_farmerFormKey.currentState!.validate()) return;

      final locProvider = Provider.of<LocationProvider>(context, listen: false);
      final district = locProvider.selectedDistrict;
      final taluka = locProvider.selectedTaluka;
      final isOtherVillage = locProvider.selectedVillage == LocationModel.other;
      final villageName = isOtherVillage
          ? _otherVillageController.text.trim()
          : locProvider.selectedVillage?.name ?? '';

      if (district == null ||
          taluka == null ||
          (isOtherVillage
              ? villageName.isEmpty
              : locProvider.selectedVillage == null)) {
        if (mounted) {
          ToastMessage.show(context,
              message: 'Please select District, Taluka and Village',
              isError: true);
        }
        return;
      }

      bool success;
      if (controller.createdFarmerId != null) {
        success = await controller.updateFarmer(
          context: context,
          farmerId: controller.createdFarmerId!,
          name:
              '${_firstNameController.text.trim()} ${_middleNameController.text.trim()} ${_lastNameController.text.trim()}'
                  .trim()
                  .replaceAll(RegExp(r'\s+'), ' '),
          aadhaarNo: _aadhaarController.text.trim(),
          phone: _phoneController.text.trim(),
          email: _emailController.text.trim(),
          district: district.name,
          taluka: taluka.name,
          villageAdd: villageName,
          gutNumber: _gutNumberController.text.trim(),
          panNo: _panNoController.text.trim(),
          profileImage: _profileImage,
        );
      } else {
        success = await controller.createFarmer(
          context: context,
          name:
              '${_firstNameController.text.trim()} ${_middleNameController.text.trim()} ${_lastNameController.text.trim()}'
                  .trim()
                  .replaceAll(RegExp(r'\s+'), ' '),
          aadhaarNo: _aadhaarController.text.trim(),
          phone: _phoneController.text.trim(),
          email: _emailController.text.trim(),
          district: district.name,
          taluka: taluka.name,
          villageAdd: villageName,
          gutNumber: _gutNumberController.text.trim(),
          panNo: _panNoController.text.trim(),
          profileImage: _profileImage,
        );
      }

      if (success) {
        // Auto-fill Land Address from Farmer Address if empty
        if (_landVillageController.text.isEmpty) {
          _landVillageController.text = villageName;
          if (isOtherVillage) {
            _otherLandVillageController.text = villageName;
          }
        }
        if (_landTalukaController.text.isEmpty) {
          _landTalukaController.text = taluka.name;
        }
        if (_landDistrictController.text.isEmpty) {
          _landDistrictController.text = district.name;
        }
        _landLocationProvider.initializeValues(
          district: district.name,
          taluka: taluka.name,
          village: villageName,
        );
        controller.nextStep();
      }
    } else if (currentStep == 1) {
      // Step 2: Identification Details
      if (!_documentFormKey.currentState!.validate()) return;

      final isUpdate = controller.isIdSubmitted;

      // Only require Aadhaar image for new submission
      if (!isUpdate && _aadhaarImage == null && _aadhaarImageUrl == null) {
        if (mounted) {
          ToastMessage.show(
            context,
            message: 'Please upload Aadhaar image',
            isError: true,
          );
        }
        return;
      }

      final farmerId = controller.createdFarmerId!;
      final existingPanNo = controller.fetchedFarmerDetail?.panNo ?? '';
      final currentPanNo = _panNoController.text.trim();

      bool hasNewFiles = _aadhaarImage != null || _panImage != null || _licenseImage != null;
      bool panNoChanged = currentPanNo != existingPanNo;

      bool success = true;
      if (hasNewFiles || panNoChanged) {
        success = await controller.uploadFarmerIdentificationDocuments(
          context: context,
          farmerId: farmerId,
          aadhaar: _aadhaarImage,
          pan: _panImage,
          license: _licenseImage,
          panNo: currentPanNo,
          isUpdate: isUpdate,
        );
      } else {
        controller.setIdSubmitted(true);
      }

      if (success) {
        controller.nextStep();
      }
    } else if (currentStep == 2) {
      // Step 3: Land Details
      if (!_landFormKey.currentState!.validate()) return;

      final farmerId = controller.createdFarmerId!;
      final landType = _landTypeController.text.trim();

      // Flags to track partial completion during this session
      // Note: Ideally these should be part of the state to persist across transient re-renders,
      // but assuming the user stays on the screen during retry, we can use checks.
      // Better approach: Check if we have already successfully uploaded by checking controller state or local flags.
      // Since we don't have explicit "PrimaryLandId" in controller for this session easily accessible without refetch,
      // we will use a more robust flow:
      // 1. Upload Primary if not already flagged as done (we can assume if user is clicking next, they want to save).
      // But to prevent duplicates, we really should track it.
      // Let's rely on the `success` result. If it fails, we stop.

      bool primarySuccess = false;

      // Check if we need to upload Primary Land
      // If we are strictly "creating" new entries, we risk duplicates if we retry.
      // However, the API `createFarmerLands` creates a new entry.
      // If `_landDocument` is null and `_landDocumentUrl` is accessible, it means it's already there (VIEW/UPDATE mode).
      // If it is 'UPDATE' mode (`controller.isLandSubmitted` is true), we use `updateFarmerLand`?
      // Wait, the previous logic had strict checks.

      if (landType == 'LAND_712') {
        if (_landDocument == null && _landDocumentUrl == null) {
          if (mounted) {
            ToastMessage.show(context,
                message: 'Please upload land document (7/12)', isError: true);
          }
          return;
        }

        if (_landDocument != null) {
          // Uploading new document
          primarySuccess = await controller.uploaddocuments(
            context: context,
            farmerId: farmerId,
            type: 'LAND_712',
            document: _landDocument!,
            area: _areaController.text.trim(),
            isUpdate: controller.isLandSubmitted,
          );
        } else {
          // Already has document
          primarySuccess = true;
        }
      } else {
        // OWN or other types handled by LandController
        final landController =
            Provider.of<LandController>(context, listen: false);

        if (_landDocument == null && _landDocumentUrl == null) {
          if (mounted) {
            ToastMessage.show(context,
                message: 'Please upload land document', isError: true);
          }
          return;
        }

        if (_landDocument != null) {
          primarySuccess = await landController.addFarmerLands(
            context: context,
            farmerId: farmerId,
            villageAdd: _landVillageController.text.trim(),
            taluka: _landTalukaController.text.trim(),
            district: _landDistrictController.text.trim(),
            landType: landType,
            area: _areaController.text.trim(),
            landOwnerName: landType == 'BLOOD_RELATION' ? _landOwnerNameController.text.trim() : null,
            relationType: landType == 'BLOOD_RELATION' ? _landRelationTypeController.text.trim().toUpperCase() : null,
            landImage: _landDocument!,
          );
        } else {
          primarySuccess = true;
        }
      }

      if (!primarySuccess) return; // Stop if primary failed

      // Step 3b: Optional Blood Relation Land Details
      bool bloodSuccess = true; // Default to true if not applicable

      if (_bloodRelationAreaController.text.trim().isNotEmpty ||
          _bloodRelationLandDocument != null) {
        final landController =
            Provider.of<LandController>(context, listen: false);

        if (_bloodRelationLandDocument != null) {
          bloodSuccess = await landController.addFarmerLands(
            context: context,
            farmerId: farmerId,
            villageAdd: _landVillageController.text.trim(),
            taluka: _landTalukaController.text.trim(),
            district: _landDistrictController.text.trim(),
            landType: 'BLOOD_RELATION',
            area: _bloodRelationAreaController.text.trim(),
            landOwnerName: _bloodRelationOwnerNameController.text.trim(),
            relationType: _bloodRelationRelationTypeController.text.trim().toUpperCase(),
            landImage: _bloodRelationLandDocument!,
          );
        } else if (_bloodRelationAreaController.text.trim().isNotEmpty &&
            _bloodRelationLandDocument == null &&
            _bloodRelationLandDocumentUrl == null) {
          if (mounted) {
            ToastMessage.show(context,
                message: 'Please upload blood relation land document',
                isError: true);
          }
          bloodSuccess = false;
        }
      }

      if (primarySuccess && bloodSuccess) {
        controller.setLandSubmitted(true);
        controller.nextStep();
      }
    } else if (currentStep == 3) {
      // Step 4: Bank Details
      if (!_bankFormKey.currentState!.validate()) return;

      if (_accountNoController.text != _confirmAccountNoController.text) {
        if (mounted) {
          ToastMessage.show(
            context,
            message: 'Account numbers do not match!',
            isError: true,
          );
        }
        return;
      }

      if (!controller.isBankSubmitted &&
          _passbookImage == null &&
          _passbookImageUrl == null) {
        if (mounted) {
          ToastMessage.show(
            context,
            message: 'Please upload bank passbook photo',
            isError: true,
          );
        }
        return;
      }

      final farmerId = controller.createdFarmerId!;
      bool bankSuccess = true;

      bool bankDetailsChanged = true;
      if (controller.isBankSubmitted &&
          controller.fetchedBank != null &&
          controller.fetchedBank!.isNotEmpty) {
        final existingBank = controller.fetchedBank!.first;
        final currentBankName = _bankNameController.text.trim();
        final currentAccountNo = _accountNoController.text.trim();
        final currentIfsc = _ifscController.text.trim();
        final currentHolderName = _holderNameController.text.trim();
        final currentBranchName = _branchNameController.text.trim();

        bool fieldsChanged = currentBankName != (existingBank.bankName ?? '') ||
            currentAccountNo != (existingBank.accountNo ?? '') ||
            currentIfsc != (existingBank.ifsc ?? '') ||
            currentHolderName != (existingBank.holderName ?? '') ||
            currentBranchName != (existingBank.branchName ?? '');

        bool newImageSelected = _passbookImage != null;

        bankDetailsChanged = fieldsChanged || newImageSelected;
      }

      if (bankDetailsChanged) {
        debugPrint('🏦 Bank Submit - farmerId: $farmerId');
        debugPrint('🏦 Bank Submit - farmerBankRecordId: $_farmerBankRecordId');
        debugPrint('🏦 Bank Submit - selectedBankId: $_selectedBankId');
        debugPrint(
            '🏦 Bank Submit - bankName: ${_bankNameController.text.trim()}');
        debugPrint(
            '🏦 Bank Submit - accountNo: ${_accountNoController.text.trim()}');
        debugPrint('🏦 Bank Submit - ifsc: ${_ifscController.text.trim()}');
        debugPrint(
            '🏦 Bank Submit - holderName: ${_holderNameController.text.trim()}');
        debugPrint(
            '🏦 Bank Submit - isBankSubmitted (isUpdate): ${controller.isBankSubmitted}');

        if (controller.isBankSubmitted) {
          bankSuccess = await controller.updateFarmerBank(
            context: context,
            farmerId: farmerId,
            bankId: _selectedBankId,
            farmerBankRecordId: _farmerBankRecordId,
            bankName: _bankNameController.text.trim(),
            accountNo: _accountNoController.text.trim(),
            ifsc: _ifscController.text.trim(),
            holderName: _holderNameController.text.trim(),
            branchName: _branchNameController.text.trim(),
            passbookImage: _passbookImage,
            isPrimary: true,
          );
        } else {
          bankSuccess = await controller.addFarmerBank(
            context: context,
            farmerId: farmerId,
            bankId: _selectedBankId,
            bankName: _bankNameController.text.trim(),
            accountNo: _accountNoController.text.trim(),
            ifsc: _ifscController.text.trim(),
            holderName: _holderNameController.text.trim(),
            branchName: _branchNameController.text.trim(),
            passbookImage: _passbookImage!,
            isPrimary: true,
          );
        }
      }

      if (bankSuccess) {
        await controller.finishKyc();
        if (mounted) {
          _resetForm();
          Provider.of<BottomNavBarController>(context, listen: false)
              .updateFormView(FormView.selection);
        }
      }
    }
  }

  Widget _buildSearchTypeRadioButton(
      FarmerKycController controller, FarmerSearchType value, String label) {
    return InkWell(
      onTap: () {
        controller.setSearchType(value);
        _searchController.clear();
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Radio<FarmerSearchType>(
            value: value,
            groupValue: controller.searchType,
            activeColor: primeryColor,
            onChanged: (val) {
              if (val != null) {
                controller.setSearchType(val);
              }
            },
          ),
          Text(label,
              style: TextStyle(fontSize: 12.sp, fontFamily: FontFamily.jost)),
        ],
      ),
    );
  }

  Widget _buildFarmerSearchField(FarmerKycController controller) {
    final hintText = controller.searchType == FarmerSearchType.name
        ? 'Search by name'
        : controller.searchType == FarmerSearchType.aadhaar
            ? 'Search by Aadhaar no.'
            : 'Search by Phone no.';

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
        key: ValueKey(controller.searchType),
        controller: _searchController,
        onChanged: (value) => controller.onSuggestionSearchChanged(value),
        autofocus:
            true, // Auto-focus when type changes to show correct keyboard
        keyboardType: controller.searchType == FarmerSearchType.name
            ? TextInputType.text
            : TextInputType.number,
        inputFormatters: controller.searchType == FarmerSearchType.name
            ? []
            : [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(
                    controller.searchType == FarmerSearchType.aadhaar
                        ? 12
                        : 10),
              ],
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
              fontSize: 14.sp,
              fontFamily: FontFamily.jost,
              color: greyColor.withOpacity(0.6)),
          border: InputBorder.none,
          prefixIcon: Icon(Icons.search, color: primeryColor, size: 20.sp),
          suffixIcon: controller.isSearching
              ? Container(
                  width: 20.w,
                  height: 20.h,
                  padding: EdgeInsets.all(12.r),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: primeryColor,
                  ),
                )
              : null,
          contentPadding:
              EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
          fillColor: const Color(0xFFFCFCFC),
          filled: true,
        ),
        style: TextStyle(fontSize: 14.sp, fontFamily: FontFamily.jost),
      ),
    );
  }

  Widget _buildSuggestionsList(FarmerKycController controller) {
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
        itemCount: controller.searchResults.length,
        separatorBuilder: (context, index) =>
            Divider(height: 1.h, color: Colors.grey.withOpacity(0.2)),
        itemBuilder: (context, index) {
          final farmer = controller.searchResults[index];
          return ListTile(
            dense: true,
            title: Text(farmer.name ?? 'Unknown',
                style: TextStyle(
                    fontSize: 14.sp,
                    fontFamily: FontFamily.jost,
                    fontWeight: FontWeight.w500)),
            subtitle: Text(
                'Aadhaar: ${farmer.aadhaarNo ?? 'N/A'} | Phone: ${farmer.phone ?? 'N/A'}',
                style: TextStyle(
                    fontSize: 12.sp,
                    fontFamily: FontFamily.jost,
                    color: greyColor)),
            onTap: () {
              controller.setSelectedFarmer(farmer);
              _searchController.text = farmer.name ?? '';
              FocusScope.of(context).unfocus();
            },
          );
        },
      ),
    );
  }

  Widget _buildActionRequiredBanner(FarmerKycController controller) {
    if (controller.isLoadingNonKycFarmers) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 20.h),
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    final farmers = controller.nonKycFarmers
        .where((f) =>
            f.kycStatus == 'PENDING_VERIFICATION' || f.kycStatus == 'REJECTED')
        .toList();

    if (farmers.isEmpty) {
      return const SizedBox.shrink();
    }

    final hasRejected = farmers.any((f) => f.kycStatus == 'REJECTED');

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(top: 16.h),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: hasRejected
            ? Colors.red.withOpacity(0.05)
            : Colors.orange.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: hasRejected
              ? Colors.red.withOpacity(0.2)
              : Colors.orange.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasRejected ? Icons.error_outline : Icons.warning_amber_rounded,
                color: hasRejected ? Colors.red : Colors.orange.shade800,
                size: 24.sp,
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "ACTION REQUIRED",
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        fontFamily: FontFamily.jost,
                        color: hasRejected
                            ? Colors.red.shade900
                            : Colors.orange.shade900,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      hasRejected
                          ? "You have farmers whose KYC was rejected by the admin. Please correct and resubmit."
                          : "You have pending farmer KYC verifications.",
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontFamily: FontFamily.jost,
                        color: hasRejected
                            ? Colors.red.shade700
                            : Colors.orange.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          SizedBox(
            width: double.infinity,
            height: 40.h,
            child: ElevatedButton(
              onPressed: () async {
                final selected = await Navigator.push<FarmerData>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FarmerKycListScreen(),
                  ),
                );
                if (selected != null) {
                  controller.setSelectedFarmer(selected);
                  _searchController.text = selected.name ?? '';
                  FocusScope.of(context).unfocus();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    hasRejected ? Colors.red.shade700 : Colors.orange.shade800,
                foregroundColor: whiteColor,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              child: Text(
                "Resolve KYC Actions (${farmers.length})",
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.bold,
                  fontFamily: FontFamily.jost,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRejectionReasonBanner(FarmerKycController controller) {
    final farmer = controller.fetchedFarmerDetail;
    if (farmer == null || farmer.kycStatus != 'REJECTED') {
      return const SizedBox.shrink();
    }

    final reason = farmer.kycRejectionReason ?? "No reason specified";

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(top: 10.h, bottom: 8.h),
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: Colors.red.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 20.sp,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 13.sp,
                  fontFamily: FontFamily.jost,
                  color: Colors.red.shade800,
                ),
                children: [
                  const TextSpan(
                    text: 'KYC REJECTED BY ADMIN\n',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const TextSpan(
                    text: 'Reason: ',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(text: reason),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getButtonText(FarmerKycController controller) {
    final step = controller.currentStep;
    if (step == 0) {
      return controller.isFarmerSubmitted ? 'Update & Next' : 'Next';
    }
    if (step == 1) return controller.isIdSubmitted ? 'Update & Next' : 'Next';
    if (step == 2) return controller.isLandSubmitted ? 'Update & Next' : 'Next';
    if (step == 3) {
      return controller.isBankSubmitted ? 'Update & Submit' : 'Submit';
    }
    return 'Next';
  }

  void _resetForm() {
    _firstNameController.clear();
    _middleNameController.clear();
    _lastNameController.clear();
    _aadhaarController.clear();
    _phoneController.clear();
    _emailController.clear();
    _gutNumberController.clear();
    _panNoController.clear();
    _areaController.clear();
    _landOwnerNameController.clear();
    _landRelationTypeController.clear();
    _bloodRelationAreaController.clear();
    _bloodRelationOwnerNameController.clear();
    _bloodRelationRelationTypeController.clear();
    _landVillageController.clear();
    _landTalukaController.clear();
    _landDistrictController.clear();
    _otherVillageController.clear();
    _otherLandVillageController.clear();
    _bankNameController.clear();
    _otherBankNameController.clear();
    _accountNoController.clear();
    _confirmAccountNoController.clear();
    _ifscController.clear();
    _holderNameController.clear();
    _branchNameController.clear();

    setState(() {
      _profileImage = null;
      _aadhaarImage = null;
      _panImage = null;
      _licenseImage = null;
      _landDocument = null;
      _bloodRelationLandDocument = null;
      _passbookImage = null;

      _profileImageUrl = null;
      _aadhaarImageUrl = null;
      _panImageUrl = null;
      _licenseImageUrl = null;
      _landDocumentUrl = null;
      _bloodRelationLandDocumentUrl = null;
      _passbookImageUrl = null;

      _showBloodRelationLand = false;
      _selectedBankId = null;
      _farmerBankRecordId = null;
    });

    _controller.reset();
    Provider.of<LocationProvider>(context, listen: false).reset();
    _landLocationProvider.reset();
  }

  void _fillFarmerData(FarmerData farmer) {
    setState(() {
      if (farmer.name != null && farmer.name!.isNotEmpty) {
        final parts = farmer.name!.trim().split(RegExp(r'\s+'));
        _firstNameController.text = parts.isNotEmpty ? parts.first : '';
        if (parts.length > 1) {
          _lastNameController.text = parts.last;
        } else {
          _lastNameController.text = '';
        }
        if (parts.length > 2) {
          _middleNameController.text =
              parts.sublist(1, parts.length - 1).join(' ');
        } else {
          _middleNameController.text = '';
        }
      } else {
        _firstNameController.text = '';
        _middleNameController.text = '';
        _lastNameController.text = '';
      }
      _aadhaarController.text = farmer.aadhaarNo ?? '';
      _phoneController.text = farmer.phone ?? '';
      _emailController.text = farmer.email ?? '';
      _gutNumberController.text = farmer.gutNumber ?? '';
      _panNoController.text = farmer.panNo ?? '';
      _profileImageUrl = farmer.profileUrl;
      _profileImage = null; // Reset local image if filling from remote
    });
    Provider.of<LocationProvider>(context, listen: false).initializeValues(
      district: farmer.district,
      taluka: farmer.taluka,
      village: farmer.villageAdd,
    );
    _landLocationProvider.initializeValues(
      district: farmer.district,
      taluka: farmer.taluka,
      village: farmer.villageAdd,
    );

    // Check if provider selected "Other"
    final lp = Provider.of<LocationProvider>(context, listen: false);
    if (lp.selectedVillage == LocationModel.other) {
      _otherVillageController.text = farmer.villageAdd ?? '';
    }
  }

  void _clearFormForNewSelection() {
    _firstNameController.clear();
    _middleNameController.clear();
    _lastNameController.clear();
    _aadhaarController.clear();
    _phoneController.clear();
    _emailController.clear();
    _gutNumberController.clear();
    _panNoController.clear();
    _areaController.clear();
    _landOwnerNameController.clear();
    _landRelationTypeController.clear();
    _bloodRelationAreaController.clear();
    _bloodRelationOwnerNameController.clear();
    _bloodRelationRelationTypeController.clear();
    _landVillageController.clear();
    _landTalukaController.clear();
    _landDistrictController.clear();
    _otherVillageController.clear();
    _otherLandVillageController.clear();
    _bankNameController.clear();
    _accountNoController.clear();
    _confirmAccountNoController.clear();
    _ifscController.clear();
    _holderNameController.clear();
    _branchNameController.clear();

    _profileImage = null;
    _aadhaarImage = null;
    _panImage = null;
    _licenseImage = null;
    _landDocument = null;
    _bloodRelationLandDocument = null;
    _passbookImage = null;

    _profileImageUrl = null;
    _aadhaarImageUrl = null;
    _panImageUrl = null;
    _licenseImageUrl = null;
    _landDocumentUrl = null;
    _bloodRelationLandDocumentUrl = null;
    _passbookImageUrl = null;

    _showBloodRelationLand = false;

    _selectedBankId = null;
    _farmerBankRecordId = null;

    // Reset location providers to prevent old address leakage
    Provider.of<LocationProvider>(context, listen: false).reset();
    _landLocationProvider.reset();
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
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                child: Column(
                  children: [
                    SizedBox(height: 10.h),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            onPressed: () {
                              Provider.of<BottomNavBarController>(context,
                                      listen: false)
                                  .updateFormView(FormView.selection);
                            },
                            icon: Icon(Icons.arrow_back_ios,
                                color: blackColor, size: 24.sp),
                          ),
                        ),
                        Text(
                          'Farmer KYC',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 28.sp,
                            fontWeight: FontWeight.bold,
                            fontFamily: FontFamily.georgia,
                            color: blackColor,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20.h),
                    Consumer<FarmerKycController>(
                      builder: (context, controller, child) {
                        return Column(
                          children: [
                            Padding(
                              padding: EdgeInsets.only(bottom: 16.h),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "KYC PROGRESS",
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.bold,
                                      color: greyColor,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 10.w, vertical: 4.h),
                                    decoration: BoxDecoration(
                                      color: primeryColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20.r),
                                    ),
                                    child: Text(
                                      "Step ${controller.currentStep + 1} of 4",
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.bold,
                                        color: primeryColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Search Existing Farmer Section (Billing Screen Style)
                            Padding(
                              padding: EdgeInsets.only(bottom: 16.h),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildFieldLabel('Search Existing Farmer By'),
                                  Row(
                                    children: [
                                      _buildSearchTypeRadioButton(controller,
                                          FarmerSearchType.aadhaar, 'Aadhaar'),
                                      SizedBox(width: 12.w),
                                      _buildSearchTypeRadioButton(controller,
                                          FarmerSearchType.name, 'Name'),
                                      SizedBox(width: 12.w),
                                      
                                      _buildSearchTypeRadioButton(controller,
                                          FarmerSearchType.phone, 'Phone'),
                                    ],
                                  ),
                                  SizedBox(height: 10.h),
                                  _buildFarmerSearchField(controller),

                                  // Suggestions List (Appears below field)
                                  if (controller.searchResults.isNotEmpty)
                                    _buildSuggestionsList(controller),

                                  if (controller.isLoading &&
                                      controller.searchResults.isEmpty)
                                    Padding(
                                      padding: EdgeInsets.all(8.r),
                                      child: const Center(
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2)),
                                    ),

                                  if (!controller.isLoading &&
                                      controller.searchQuery.isNotEmpty &&
                                      controller.searchResults.isEmpty &&
                                      controller.createdFarmerId == null)
                                    Padding(
                                      padding: EdgeInsets.only(top: 8.h),
                                      child: Text(
                                        "No farmers found",
                                        style: TextStyle(
                                          color: Colors.red.shade400,
                                          fontSize: 12.sp,
                                          fontFamily: FontFamily.jost,
                                        ),
                                      ),
                                    ),

                                  if (controller.createdFarmerId == null &&
                                      controller.searchQuery.isEmpty)
                                    _buildActionRequiredBanner(controller),

                                  if (controller.createdFarmerId != null) ...[
                                    Padding(
                                      padding: EdgeInsets.only(top: 8.h),
                                      child: Row(
                                        children: [
                                          Icon(Icons.check_circle,
                                              color: Colors.green, size: 16.sp),
                                          SizedBox(width: 4.w),
                                          Expanded(
                                            child: Text(
                                              "Editing: ${controller.fetchedFarmerDetail?.name ?? 'Farmer'}",
                                              style: TextStyle(
                                                fontSize: 12.sp,
                                                color: Colors.green.shade700,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: () => _resetForm(),
                                            style: TextButton.styleFrom(
                                              padding: EdgeInsets.zero,
                                              minimumSize: Size.zero,
                                              tapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                            ),
                                            child: Text(
                                              "Clear / New",
                                              style: TextStyle(
                                                fontSize: 12.sp,
                                                color: primeryColor,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    _buildRejectionReasonBanner(controller),
                                  ],
                                ],
                              ),
                            ),

                            // Farmer Details Section
                            _buildSection(
                              title: 'Farmer Details Card',
                              icon: Icons.person,
                              isExpanded: controller.currentStep == 0,
                              onToggle: () {
                                controller.setCurrentStep(0);
                              },
                              child: _buildFarmerDetailsForm(),
                            ),
                            if (controller.currentStep == 0) ...[
                              SizedBox(height: 20.h),
                              _buildNavigationButtons(controller),
                            ],
                            SizedBox(height: 12.h),

                            // Identification Details Section
                            _buildSection(
                              title: 'Identification Details',
                              icon: Icons.badge,
                              isExpanded: controller.currentStep == 1,
                              onToggle: () {
                                controller.setCurrentStep(1);
                              },
                              child: _buildIdentificationForm(),
                            ),
                            if (controller.currentStep == 1) ...[
                              SizedBox(height: 20.h),
                              _buildNavigationButtons(controller),
                            ],
                            SizedBox(height: 12.h),

                            // Land Details Section
                            _buildSection(
                              title: 'Land Details',
                              icon: Icons.landscape,
                              isExpanded: controller.currentStep == 2,
                              onToggle: () {
                                controller.setCurrentStep(2);
                              },
                              child: _buildLandDetailsForm(),
                            ),
                            if (controller.currentStep == 2) ...[
                              SizedBox(height: 20.h),
                              _buildNavigationButtons(controller),
                            ],
                            SizedBox(height: 12.h),

                            // Bank Details Section
                            _buildSection(
                              title: 'Bank Details',
                              icon: Icons.account_balance,
                              isExpanded: controller.currentStep == 3,
                              onToggle: () {
                                controller.setCurrentStep(3);
                              },
                              child: _buildBankDetailsForm(),
                            ),
                            if (controller.currentStep == 3) ...[
                              SizedBox(height: 20.h),
                              _buildNavigationButtons(controller),
                            ],
                          ],
                        );
                      },
                    ),
                    SizedBox(height: 30.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationButtons(FarmerKycController controller) {
    // Also listen to LandController for loading state
    final landController = Provider.of<LandController>(context);
    final isLoading = controller.isLoading || landController.isLoading;

    return Padding(
      padding: EdgeInsets.only(bottom: 20.h),
      child: Row(
        children: [
          // Back button removed to prevent editing previous sections

          Expanded(
            child: SizedBox(
              height: 50.h,
              child: ElevatedButton(
                onPressed: isLoading ? null : _handleNextStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isLoading ? lightGreenColor : primeryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  elevation: isLoading ? 0 : 2,
                ),
                child: isLoading
                    ? SizedBox(
                        width: 20.w,
                        height: 20.h,
                        child: CircularProgressIndicator(
                          color: primeryColor,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        _getButtonText(controller),
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: whiteColor,
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

  Widget _buildSection({
    required String title,
    required IconData icon,
    required bool isExpanded,
    required VoidCallback onToggle,
    required Widget child,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onToggle,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            decoration: BoxDecoration(
              color: whiteColor,
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Icon(icon, color: primeryColor, size: 22.sp),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                      color: blackColor,
                      fontFamily: FontFamily.jost,
                    ),
                  ),
                ),
                Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: const Color(0xFF1E3A5F),
                  size: 24.sp,
                ),
              ],
            ),
          ),
        ),
        if (isExpanded)
          Container(
            color: Colors.transparent,
            child: child,
          ),
      ],
    );
  }

  Widget _buildFarmerDetailsForm() {
    return Form(
      key: _farmerFormKey,
      child: Padding(
        padding: EdgeInsets.only(top: 10.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 100.r,
                    height: 100.r,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      shape: BoxShape.circle,
                      border: Border.all(color: primeryColor, width: 2),
                      image: _profileImage != null
                          ? DecorationImage(
                              image: FileImage(_profileImage!),
                              fit: BoxFit.cover,
                            )
                          : (_profileImageUrl != null &&
                                  _profileImageUrl!.isNotEmpty
                              ? DecorationImage(
                                  image: NetworkImage(
                                    _profileImageUrl!.startsWith('http')
                                        ? _profileImageUrl!
                                        : '${ApiConstants.imageBaseUrl}${_profileImageUrl!.startsWith('/') ? '' : '/'}$_profileImageUrl',
                                    headers: _authToken != null
                                        ? {
                                            'Authorization':
                                                'Bearer $_authToken'
                                          }
                                        : null,
                                  ),
                                  fit: BoxFit.cover,
                                )
                              : null),
                    ),
                    child: (_profileImage == null &&
                            (_profileImageUrl == null ||
                                _profileImageUrl!.isEmpty))
                        ? Icon(Icons.person, size: 50.r, color: Colors.grey)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () => _pickImage('PROFILE'),
                      child: Container(
                        padding: EdgeInsets.all(8.r),
                        decoration: BoxDecoration(
                          color: primeryColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: whiteColor, width: 2),
                        ),
                        child: Icon(Icons.camera_alt,
                            size: 16.sp, color: whiteColor),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20.h),
            _buildFieldLabel('Aadhaar Card No. *'),
            _buildTextField(
              controller: _aadhaarController,
              keyboardType: TextInputType.number,
              maxLength: 12,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter Aadhaar number';
                }
                if (value.length != 12) {
                  return 'Aadhaar number must be 12 digits';
                }
                return null;
              },
            ),
            SizedBox(height: 12.h),
            _buildFieldLabel('First Name *'),
            Consumer<FarmerKycController>(
              builder: (context, controller, child) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTextField(
                      controller: _firstNameController,
                      onChanged: (value) {},
                      inputFormatters: [
                        FilteringTextInputFormatter.deny(RegExp(r'\s')),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter first name';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 12.h),
                    _buildFieldLabel('Middle Name *'),
                    _buildTextField(
                      controller: _middleNameController,
                      onChanged: (value) {},
                      inputFormatters: [
                        FilteringTextInputFormatter.deny(RegExp(r'\s')),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter middle name';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 12.h),
                    _buildFieldLabel('Last Name *'),
                    _buildTextField(
                      controller: _lastNameController,
                      onChanged: (value) {},
                      inputFormatters: [
                        FilteringTextInputFormatter.deny(RegExp(r'\s')),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter last name';
                        }
                        return null;
                      },
                    ),
                    if (controller.searchResults.isNotEmpty)
                      Container(
                        margin: EdgeInsets.only(top: 4.h),
                        constraints: BoxConstraints(maxHeight: 200.h),
                        decoration: BoxDecoration(
                          color: whiteColor,
                          borderRadius: BorderRadius.circular(8.r),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          itemCount: controller.searchResults.length,
                          itemBuilder: (context, index) {
                            final farmer = controller.searchResults[index];
                            return ListTile(
                              title: Text(farmer.name ?? '',
                                  style: TextStyle(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: FontFamily.jost)),
                              subtitle: Text(
                                  'Aadhaar: ${farmer.aadhaarNo ?? "N/A"}',
                                  style: TextStyle(
                                      fontSize: 12.sp,
                                      color: Colors.grey,
                                      fontFamily: FontFamily.jost)),
                              onTap: () {
                                _fillFarmerData(farmer);
                                controller.setSelectedFarmer(farmer);
                              },
                            );
                          },
                        ),
                      ),
                  ],
                );
              },
            ),
            SizedBox(height: 12.h),
            _buildFieldLabel('Pan No. (Optional)'),
            _buildTextField(
              controller: _panNoController,
              maxLength: 10,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [
                UpperCaseTextFormatter(),
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
              ],
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  final panRegex = RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$');
                  if (!panRegex.hasMatch(value)) {
                    return 'Invalid PAN (e.g., ABCDE1234F)';
                  }
                }
                return null;
              },
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldLabel('Mobile Number *'),
                      _buildTextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        maxLength: 10,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Required';
                          }
                          if (value.length != 10) {
                            return 'Must be 10 digits';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldLabel('Email ID (Optional)'),
                      _buildTextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          // Optional field
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Consumer<LocationProvider>(
              builder: (context, locationProvider, child) {
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel('District *'),
                              DropdownSearch<LocationModel>(
                                popupProps: PopupProps.menu(
                                  showSearchBox: true,
                                  searchFieldProps: TextFieldProps(
                                    decoration: InputDecoration(
                                      hintText: "Search District",
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: 12.w, vertical: 12.h),
                                      border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(6.r),
                                      ),
                                    ),
                                  ),
                                ),
                                asyncItems: (filter) =>
                                    Future.value(locationProvider.districts),
                                itemAsString: (item) => item.name,
                                compareFn: (i1, i2) => i1.id == i2.id,
                                dropdownDecoratorProps: DropDownDecoratorProps(
                                  dropdownSearchDecoration: InputDecoration(
                                    filled: true,
                                    fillColor: whiteColor,
                                    isDense: true,
                                    hintText: "Select District",
                                    hintStyle: const TextStyle(
                                        overflow: TextOverflow.ellipsis),
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 12.w, vertical: 12.h),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6.r),
                                      borderSide: BorderSide(
                                          color: Colors.grey.withOpacity(0.4)),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6.r),
                                      borderSide: BorderSide(
                                          color: Colors.grey.withOpacity(0.4)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6.r),
                                      borderSide: BorderSide(
                                          color: primeryColor, width: 1.5),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6.r),
                                      borderSide:
                                          const BorderSide(color: Colors.red),
                                    ),
                                  ),
                                  baseStyle: TextStyle(
                                      fontSize: 14.sp,
                                      fontFamily: FontFamily.jost,
                                      color: blackColor),
                                ),
                                onChanged: locationProvider.selectDistrict,
                                selectedItem: locationProvider.selectedDistrict,
                                validator: (value) =>
                                    value == null ? 'Required' : null,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel('Taluka *'),
                              DropdownSearch<LocationModel>(
                                popupProps: PopupProps.menu(
                                  showSearchBox: true,
                                  searchFieldProps: TextFieldProps(
                                    decoration: InputDecoration(
                                      hintText: "Search Taluka",
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: 12.w, vertical: 12.h),
                                      border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(6.r),
                                      ),
                                    ),
                                  ),
                                ),
                                asyncItems: (filter) =>
                                    Future.value(locationProvider.talukas),
                                itemAsString: (item) => item.name,
                                compareFn: (i1, i2) => i1.id == i2.id,
                                enabled:
                                    locationProvider.selectedDistrict != null,
                                dropdownDecoratorProps: DropDownDecoratorProps(
                                  dropdownSearchDecoration: InputDecoration(
                                    filled: true,
                                    fillColor: whiteColor,
                                    isDense: true,
                                    hintText: "Select Taluka",
                                    hintStyle: const TextStyle(
                                        overflow: TextOverflow.ellipsis),
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 12.w, vertical: 12.h),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6.r),
                                      borderSide: BorderSide(
                                          color: Colors.grey.withOpacity(0.4)),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6.r),
                                      borderSide: BorderSide(
                                          color: Colors.grey.withOpacity(0.4)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6.r),
                                      borderSide: BorderSide(
                                          color: primeryColor, width: 1.5),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6.r),
                                      borderSide:
                                          const BorderSide(color: Colors.red),
                                    ),
                                  ),
                                  baseStyle: TextStyle(
                                      fontSize: 14.sp,
                                      fontFamily: FontFamily.jost,
                                      color: blackColor),
                                ),
                                onChanged: locationProvider.selectTaluka,
                                selectedItem: locationProvider.selectedTaluka,
                                validator: (value) =>
                                    value == null ? 'Required' : null,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel('Village Address *'),
                              DropdownSearch<LocationModel>(
                                popupProps: PopupProps.menu(
                                  showSearchBox: true,
                                  searchFieldProps: TextFieldProps(
                                    decoration: InputDecoration(
                                      hintText: "Search Village",
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: 12.w, vertical: 12.h),
                                      border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(6.r),
                                      ),
                                    ),
                                  ),
                                ),
                                asyncItems: (filter) =>
                                    Future.value(locationProvider.villages),
                                itemAsString: (item) => item.name,
                                compareFn: (i1, i2) => i1.id == i2.id,
                                enabled:
                                    locationProvider.selectedTaluka != null,
                                dropdownDecoratorProps: DropDownDecoratorProps(
                                  dropdownSearchDecoration: InputDecoration(
                                    filled: true,
                                    fillColor: whiteColor,
                                    isDense: true,
                                    hintText: "Select Village",
                                    hintStyle: const TextStyle(
                                        overflow: TextOverflow.ellipsis),
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 12.w, vertical: 12.h),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6.r),
                                      borderSide: BorderSide(
                                          color: Colors.grey.withOpacity(0.4)),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6.r),
                                      borderSide: BorderSide(
                                          color: Colors.grey.withOpacity(0.4)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6.r),
                                      borderSide: BorderSide(
                                          color: primeryColor, width: 1.5),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6.r),
                                      borderSide:
                                          const BorderSide(color: Colors.red),
                                    ),
                                  ),
                                  baseStyle: TextStyle(
                                      fontSize: 14.sp,
                                      fontFamily: FontFamily.jost,
                                      color: blackColor),
                                ),
                                onChanged: (value) {
                                  locationProvider.selectVillage(value);
                                  if (value != LocationModel.other) {
                                    _otherVillageController.clear();
                                  }
                                },
                                selectedItem: locationProvider.selectedVillage,
                                validator: (value) =>
                                    value == null ? 'Required' : null,
                              ),
                              if (locationProvider.selectedVillage ==
                                  LocationModel.other) ...[
                                SizedBox(height: 12.h),
                                _buildFieldLabel('Enter Village Name *'),
                                _buildTextField(
                                  controller: _otherVillageController,
                                  validator: (value) =>
                                      (value == null || value.isEmpty)
                                          ? 'Required'
                                          : null,
                                ),
                              ],
                            ],
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel('Gut No. *'),
                              _buildTextField(
                                controller: _gutNumberController,
                                validator: (value) =>
                                    value?.isEmpty == true ? 'Required' : null,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIdentificationForm() {
    return Form(
      key: _documentFormKey,
      child: Padding(
        padding: EdgeInsets.only(top: 10.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFieldLabel('Aadhaar Card No. *'),
            _buildTextField(
              controller: _aadhaarController,
              keyboardType: TextInputType.number,
              maxLength: 12,
              enabled: false,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter Aadhaar number';
                }
                if (value.length != 12) {
                  return 'Aadhaar number must be 12 digits';
                }
                return null;
              },
            ),
            SizedBox(height: 10.h),
            _buildFieldLabel('Aadhaar Card Photo *'),
            _buildImageUpload(
              onTap: () => _pickImage('AADHAAR'),
              selectedFile: _aadhaarImage,
              remoteUrl: _aadhaarImageUrl,
            ),
            SizedBox(height: 12.h),
            _buildFieldLabel('Pan Card (Optional)'),
            _buildTextField(
              controller: _panNoController,
              maxLength: 10,
              enabled: false,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [
                UpperCaseTextFormatter(),
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
              ],
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  final panRegex = RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$');
                  if (!panRegex.hasMatch(value)) {
                    return 'Invalid PAN';
                  }
                }
                return null;
              },
            ),
            SizedBox(height: 10.h),
            _buildImageUpload(
              onTap: () => _pickImage('PAN'),
              selectedFile: _panImage,
              remoteUrl: _panImageUrl,
            ),
            SizedBox(height: 12.h),
            _buildFieldLabel('Driving License (Optional)'),
            SizedBox(height: 10.h),
            _buildImageUpload(
              onTap: () => _pickImage('LICENSE'),
              selectedFile: _licenseImage,
              remoteUrl: _licenseImageUrl,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLandDetailsForm() {
    return Form(
      key: _landFormKey,
      child: Padding(
        padding: EdgeInsets.only(top: 10.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFieldLabel('Land Location *'),
            ChangeNotifierProvider.value(
              value: _landLocationProvider,
              child: Consumer<LocationProvider>(
                builder: (context, lp, child) {
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel('District *'),
                                DropdownSearch<LocationModel>(
                                  popupProps: PopupProps.menu(
                                    showSearchBox: true,
                                    searchFieldProps: TextFieldProps(
                                      decoration: InputDecoration(
                                        hintText: "Search District",
                                        contentPadding: EdgeInsets.symmetric(
                                            horizontal: 12.w, vertical: 12.h),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(6.r),
                                        ),
                                      ),
                                    ),
                                  ),
                                  asyncItems: (filter) =>
                                      Future.value(lp.districts),
                                  itemAsString: (item) => item.name,
                                  compareFn: (i1, i2) => i1.id == i2.id,
                                  dropdownDecoratorProps:
                                      DropDownDecoratorProps(
                                    dropdownSearchDecoration: InputDecoration(
                                      filled: true,
                                      fillColor: whiteColor,
                                      isDense: true,
                                      hintText: "Select District",
                                      hintStyle: const TextStyle(
                                          overflow: TextOverflow.ellipsis),
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: 12.w, vertical: 11.h),
                                      border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(6.r),
                                        borderSide: BorderSide(
                                            color:
                                                Colors.grey.withOpacity(0.4)),
                                      ),
                                    ),
                                  ),
                                  onChanged: (value) {
                                    lp.selectDistrict(value);
                                    if (value != null) {
                                      _landDistrictController.text = value.name;
                                    }
                                  },
                                  selectedItem: lp.selectedDistrict,
                                  validator: (value) =>
                                      value == null ? 'Required' : null,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel('Taluka *'),
                                DropdownSearch<LocationModel>(
                                  popupProps: PopupProps.menu(
                                    showSearchBox: true,
                                    searchFieldProps: TextFieldProps(
                                      decoration: InputDecoration(
                                        hintText: "Search Taluka",
                                        contentPadding: EdgeInsets.symmetric(
                                            horizontal: 12.w, vertical: 12.h),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(6.r),
                                        ),
                                      ),
                                    ),
                                  ),
                                  asyncItems: (filter) =>
                                      Future.value(lp.talukas),
                                  itemAsString: (item) => item.name,
                                  compareFn: (i1, i2) => i1.id == i2.id,
                                  dropdownDecoratorProps:
                                      DropDownDecoratorProps(
                                    dropdownSearchDecoration: InputDecoration(
                                      filled: true,
                                      fillColor: whiteColor,
                                      isDense: true,
                                      hintText: "Select Taluka",
                                      hintStyle: const TextStyle(
                                          overflow: TextOverflow.ellipsis),
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: 12.w, vertical: 11.h),
                                      border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(6.r),
                                        borderSide: BorderSide(
                                            color:
                                                Colors.grey.withOpacity(0.4)),
                                      ),
                                    ),
                                  ),
                                  onChanged: (value) {
                                    lp.selectTaluka(value);
                                    if (value != null) {
                                      _landTalukaController.text = value.name;
                                    }
                                  },
                                  selectedItem: lp.selectedTaluka,
                                  enabled: lp.selectedDistrict != null,
                                  validator: (value) =>
                                      value == null ? 'Required' : null,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12.h),
                      _buildFieldLabel('Village *'),
                      DropdownSearch<LocationModel>(
                        popupProps: PopupProps.menu(
                          showSearchBox: true,
                          searchFieldProps: TextFieldProps(
                            decoration: InputDecoration(
                              hintText: "Search Village",
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12.w, vertical: 12.h),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                            ),
                          ),
                        ),
                        asyncItems: (filter) => Future.value(lp.villages),
                        itemAsString: (item) => item.name,
                        compareFn: (i1, i2) => i1.id == i2.id,
                        dropdownDecoratorProps: DropDownDecoratorProps(
                          dropdownSearchDecoration: InputDecoration(
                            filled: true,
                            fillColor: whiteColor,
                            isDense: true,
                            hintText: "Select Village",
                            hintStyle: const TextStyle(
                                overflow: TextOverflow.ellipsis),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12.w, vertical: 11.h),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6.r),
                              borderSide: BorderSide(
                                  color: Colors.grey.withOpacity(0.4)),
                            ),
                          ),
                        ),
                        onChanged: (value) {
                          lp.selectVillage(value);
                          if (value != null) {
                            if (value == LocationModel.other) {
                              _landVillageController.text =
                                  _otherLandVillageController.text;
                            } else {
                              _landVillageController.text = value.name;
                              _otherLandVillageController.clear();
                            }
                          }
                        },
                        selectedItem: lp.selectedVillage,
                        enabled: lp.selectedTaluka != null,
                        validator: (value) => value == null ? 'Required' : null,
                      ),
                      if (lp.selectedVillage == LocationModel.other) ...[
                        SizedBox(height: 12.h),
                        _buildFieldLabel('Enter Village Name *'),
                        _buildTextField(
                          controller: _otherLandVillageController,
                          onChanged: (value) {
                            _landVillageController.text = value.trim();
                          },
                          validator: (value) => (value == null || value.isEmpty)
                              ? 'Required'
                              : null,
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
            SizedBox(height: 12.h),
            _buildFieldLabel('Land Type *'),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              decoration: BoxDecoration(
                color: whiteColor,
                borderRadius: BorderRadius.circular(6.r),
                border: Border.all(color: Colors.grey.withOpacity(0.4)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: ['OWN', 'BLOOD_RELATION']
                          .contains(_landTypeController.text)
                      ? _landTypeController.text
                      : 'OWN',
                  isExpanded: true,
                  items: [
                    DropdownMenuItem(
                      value: 'OWN',
                      child: Text('OWN',
                          style: TextStyle(
                              fontSize: 14.sp, fontFamily: FontFamily.jost)),
                    ),
                    DropdownMenuItem(
                      value: 'BLOOD_RELATION',
                      child: Text('BLOOD_RELATION',
                          style: TextStyle(
                              fontSize: 14.sp, fontFamily: FontFamily.jost)),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _landTypeController.text = value;
                      });
                    }
                  },
                ),
              ),
            ),
            if (_landTypeController.text == 'BLOOD_RELATION') ...[
              SizedBox(height: 12.h),
              _buildFieldLabel('Land Owner Name *'),
              _buildTextField(
                controller: _landOwnerNameController,
                validator: (value) {
                  if (_landTypeController.text == 'BLOOD_RELATION') {
                    if (value == null || value.isEmpty) {
                      return 'Please enter land owner name';
                    }
                  }
                  return null;
                },
              ),
              SizedBox(height: 12.h),
              _buildFieldLabel('Relation with Farmer *'),
              _buildTextField(
                controller: _landRelationTypeController,
                validator: (value) {
                  if (_landTypeController.text == 'BLOOD_RELATION') {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter relation (e.g. FATHER, MOTHER)';
                    }
                  }
                  return null;
                },
              ),
            ],
            SizedBox(height: 12.h),
            _buildFieldLabel('Area (in acres) *'),
            _buildTextField(
              controller: _areaController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter area';
                }
                final area = double.tryParse(value);
                if (area == null || area <= 0) {
                  return 'Please enter valid area';
                }
                return null;
              },
            ),
            SizedBox(height: 10.h),
            _buildFieldLabel('Land Document Photo *'),
            _buildImageUpload(
              onTap: () => _pickImage('LAND'),
              selectedFile: _landDocument,
              remoteUrl: _landDocumentUrl,
            ),
            SizedBox(height: 16.h),
            if (!_showBloodRelationLand)
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _showBloodRelationLand = true;
                    });
                  },
                  icon: Icon(Icons.add_circle_outline, color: primeryColor),
                  label: Text(
                    'Add More Land',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: primeryColor,
                      fontWeight: FontWeight.w600,
                      fontFamily: FontFamily.jost,
                    ),
                  ),
                ),
              ),
            if (_showBloodRelationLand) ...[
              const Divider(),
              SizedBox(height: 12.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSectionLabel('Blood Relation Land Details'),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _showBloodRelationLand = false;
                        _bloodRelationAreaController.clear();
                        _bloodRelationOwnerNameController.clear();
                        _bloodRelationRelationTypeController.clear();
                        _bloodRelationLandDocument = null;
                        // Note: Not clearing _bloodRelationLandDocumentUrl here to avoid accidental loss
                        // but visibility will hide it.
                      });
                    },
                    icon: Icon(Icons.close,
                        color: Colors.red.shade400, size: 20.sp),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              _buildFieldLabel('Land Type'),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w),
                decoration: BoxDecoration(
                  color: whiteColor,
                  borderRadius: BorderRadius.circular(6.r),
                  border: Border.all(color: Colors.grey.withOpacity(0.4)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: 'BLOOD_RELATION',
                    isExpanded: true,
                    items: [
                      DropdownMenuItem(
                        value: 'BLOOD_RELATION',
                        child: Text('BLOOD_RELATION',
                            style: TextStyle(
                                fontSize: 14.sp, fontFamily: FontFamily.jost)),
                      ),
                    ],
                    onChanged: (value) {},
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              _buildFieldLabel('Land Owner Name *'),
              _buildTextField(
                controller: _bloodRelationOwnerNameController,
                validator: (value) {
                  if (_showBloodRelationLand &&
                      (_bloodRelationAreaController.text.trim().isNotEmpty ||
                          _bloodRelationLandDocument != null ||
                          _bloodRelationLandDocumentUrl != null)) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter land owner name';
                    }
                  }
                  return null;
                },
              ),
              SizedBox(height: 12.h),
              _buildFieldLabel('Relation with Farmer *'),
              _buildTextField(
                controller: _bloodRelationRelationTypeController,
                validator: (value) {
                  if (_showBloodRelationLand &&
                      (_bloodRelationAreaController.text.trim().isNotEmpty ||
                          _bloodRelationLandDocument != null ||
                          _bloodRelationLandDocumentUrl != null)) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter relation (e.g. FATHER, MOTHER)';
                    }
                  }
                  return null;
                },
              ),
              SizedBox(height: 12.h),
              _buildFieldLabel('Area (in acres)'),
              _buildTextField(
                controller: _bloodRelationAreaController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              SizedBox(height: 10.h),
              _buildImageUpload(
                onTap: () => _pickImage('BLOOD_RELATION_LAND'),
                selectedFile: _bloodRelationLandDocument,
                remoteUrl: _bloodRelationLandDocumentUrl,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.bold,
        color: primeryColor,
        fontFamily: FontFamily.jost,
      ),
    );
  }

  Widget _buildBankDetailsForm() {
    return Form(
      key: _bankFormKey,
      child: Padding(
        padding: EdgeInsets.only(top: 10.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFieldLabel('Bank Name *'),
            DropdownSearch<BankDetailData>(
              popupProps: PopupProps.menu(
                showSearchBox: true,
                searchFieldProps: TextFieldProps(
                  decoration: InputDecoration(
                    hintText: "Search Bank",
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                  ),
                ),
              ),
              asyncItems: (filter) {
                final banks = _controller.bankDetails;
                return Future.value(
                    banks + [BankDetailData(id: 'other', bankName: 'Other')]);
              },
              itemAsString: (item) {
                final name = item.bankName ?? '';
                final ifsc = item.ifsc ?? '';
                final branch = item.branchName ?? '';

                String display = name;
                if (branch.isNotEmpty) {
                  display += ' - $branch';
                }
                if (ifsc.isNotEmpty) {
                  display += ' ($ifsc)';
                }
                return display;
              },
              compareFn: (i1, i2) => i1.id == i2.id,
              dropdownDecoratorProps: DropDownDecoratorProps(
                dropdownSearchDecoration: InputDecoration(
                  filled: true,
                  fillColor: whiteColor,
                  isDense: true,
                  hintText: "Select Bank",
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 11.h),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6.r),
                    borderSide: BorderSide(color: Colors.grey.withOpacity(0.4)),
                  ),
                ),
              ),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedBankId = value.id;
                    if (value.id == 'other') {
                      _bankNameController.text = _otherBankNameController.text;
                      _ifscController.clear();
                      _branchNameController.clear();
                    } else {
                      _bankNameController.text = value.bankName ?? '';
                      _ifscController.text = value.ifsc ?? '';
                      _branchNameController.text = value.branchName ?? '';
                      _otherBankNameController.clear();
                    }
                  });
                  debugPrint(
                      '🏦 Selected bank: id=${value.id}, name=${value.bankName}, ifsc=${value.ifsc}, branch=${value.branchName}');
                }
              },
              selectedItem: _selectedBankId == 'other'
                  ? BankDetailData(id: 'other', bankName: 'Other')
                  : (_controller.bankDetails.any((b) => b.id == _selectedBankId)
                      ? _controller.bankDetails
                          .firstWhere((b) => b.id == _selectedBankId)
                      : (_bankNameController.text.isNotEmpty
                          ? BankDetailData(
                              id: _selectedBankId,
                              bankName: _bankNameController.text,
                              ifsc: _ifscController.text,
                              branchName: _branchNameController.text,
                            )
                          : null)),
              validator: (value) => (value == null ||
                      value.bankName == null ||
                      value.bankName!.isEmpty)
                  ? 'Please select bank name'
                  : null,
            ),
            if (_selectedBankId == 'other') ...[
              SizedBox(height: 12.h),
              _buildFieldLabel('Enter Bank Name *'),
              _buildTextField(
                controller: _otherBankNameController,
                onChanged: (value) {
                  _bankNameController.text = value.trim();
                },
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Please enter bank name'
                    : null,
              ),
            ],
            SizedBox(height: 12.h),
            _buildFieldLabel('Account Holder Name *'),
            _buildTextField(
              controller: _holderNameController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter account holder name';
                }
                return null;
              },
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldLabel('Account Number *'),
                      _buildTextField(
                        controller: _accountNoController,
                        keyboardType: TextInputType.number,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        onChanged: (value) {
                          if (_confirmAccountNoController.text.isNotEmpty) {
                            _bankFormKey.currentState?.validate();
                          }
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Required';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldLabel('Confirm Account No. *'),
                      _buildTextField(
                        controller: _confirmAccountNoController,
                        keyboardType: TextInputType.number,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        onChanged: (value) {
                          if (_accountNoController.text.isNotEmpty) {
                            _bankFormKey.currentState?.validate();
                          }
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Required';
                          }
                          if (value != _accountNoController.text) {
                            return 'Numbers do not match';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            _buildFieldLabel('IFSC Code *'),
            _buildTextField(
              controller: _ifscController,
              readOnly: _selectedBankId != 'other',
              textCapitalization: TextCapitalization.characters,
              maxLength: 11,
              inputFormatters: [UpperCaseTextFormatter()],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter IFSC code';
                }
                if (value.length != 11) {
                  return 'IFSC code must be 11 characters';
                }
                return null;
              },
            ),
            SizedBox(height: 12.h),
            _buildFieldLabel('Branch Name'),
            _buildTextField(
              controller: _branchNameController,
              readOnly: _selectedBankId != 'other',
              validator: (value) {
                return null;
              },
            ),
            SizedBox(height: 12.h),
            _buildFieldLabel('Bank Passbook Photo *'),
            _buildImageUpload(
              onTap: () => _pickImage('PASSBOOK'),
              selectedFile: _passbookImage,
              remoteUrl: _passbookImageUrl,
            ),
          ],
        ),
      ),
    );
  }

  /*
  void _showAddBankDialog() {
    final TextEditingController newBankController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: whiteColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
          title: Text(
            'Add New Bank',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              fontFamily: FontFamily.jost,
            ),
          ),
          content: TextField(
            controller: newBankController,
            decoration: InputDecoration(
              hintText: 'Enter bank name',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: greyColor),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (newBankController.text.isNotEmpty) {
                  final newBank = await _controller
                      .createMasterBankDetail(newBankController.text);
                  if (newBank != null) {
                    setState(() {
                      _bankNameController.text = newBank.bankName ?? '';
                    });
                    if (context.mounted) Navigator.pop(context);
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: appColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              child: Text(
                'Add',
                style: TextStyle(color: whiteColor),
              ),
            ),
          ],
        );
      },
    );
  }
  */

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Text(
        label,
        overflow: TextOverflow.ellipsis,
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
    required TextEditingController controller,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int? maxLength,
    bool readOnly = false,
    bool enabled = true,
    TextCapitalization textCapitalization = TextCapitalization.none,
    List<TextInputFormatter>? inputFormatters,
    Function(String)? onChanged,
    VoidCallback? onTap,
    AutovalidateMode? autovalidateMode,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      autovalidateMode: autovalidateMode,
      keyboardType: keyboardType,
      maxLength: maxLength,
      onChanged: onChanged,
      onTap: onTap,
      readOnly: readOnly,
      enabled: enabled,
      textCapitalization: textCapitalization,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        counterText: '',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6.r),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.4)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6.r),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.4)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6.r),
          borderSide: BorderSide(color: primeryColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6.r),
          borderSide: const BorderSide(color: Colors.red),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
        fillColor: whiteColor,
        filled: true,
      ),
      style: TextStyle(
        fontSize: 14.sp,
        fontFamily: FontFamily.jost,
      ),
    );
  }

  bool _isImageFile(String path) {
    final mimeType = p.extension(path).toLowerCase();
    return ['.jpg', '.jpeg', '.png', '.bmp'].contains(mimeType);
  }

  Widget _buildImageUpload({
    required VoidCallback onTap,
    File? selectedFile,
    String? remoteUrl,
  }) {
    // Construct full URL if it's a relative path
    String? fullUrl;
    if (remoteUrl != null && remoteUrl.isNotEmpty) {
      if (remoteUrl.startsWith('http')) {
        fullUrl = remoteUrl;
      } else {
        // Use baseHost from ApiConstants for robust joining
        final path = remoteUrl.startsWith('/') ? remoteUrl : '/$remoteUrl';
        fullUrl = '${ApiConstants.imageBaseUrl}$path';
      }
    }

    final bool isSelectedFileImage =
        selectedFile != null && _isImageFile(selectedFile.path);
    final bool isRemoteUrlImage = fullUrl != null && _isImageFile(fullUrl);

    return GestureDetector(
      onTap: onTap,
      child: DottedBorder(
        color: Colors.grey.withOpacity(0.4),
        strokeWidth: 2,
        dashPattern: const [6, 3],
        borderType: BorderType.RRect,
        radius: Radius.circular(8.r),
        child: Container(
          width: double.infinity,
          height: 150.h,
          decoration: BoxDecoration(
            color: whiteColor,
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: selectedFile != null
              ? (isSelectedFileImage
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8.r),
                      child: Image.file(
                        selectedFile,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            p.extension(selectedFile.path).toLowerCase() ==
                                    '.pdf'
                                ? Icons.picture_as_pdf_rounded
                                : Icons.insert_drive_file_rounded,
                            color: Colors.red.shade400,
                            size: 40.sp,
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            p.basename(selectedFile.path),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10.sp,
                              fontFamily: FontFamily.jost,
                              color: greyColor,
                            ),
                          ),
                        ],
                      ),
                    ))
              : (fullUrl != null
                  ? (isRemoteUrlImage
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8.r),
                          child: Image.network(
                            fullUrl,
                            fit: BoxFit.cover,
                            headers: _authToken != null
                                ? {'Authorization': 'Bearer $_authToken'}
                                : null,
                            errorBuilder: (context, error, stackTrace) {
                              debugPrint(
                                  'Image load error for $fullUrl: $error');
                              return const Center(
                                  child: Icon(Icons.error_outline));
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  color: primeryColor,
                                ),
                              );
                            },
                          ),
                        )
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                fullUrl.toLowerCase().endsWith('.pdf')
                                    ? Icons.picture_as_pdf_rounded
                                    : Icons.insert_drive_file_rounded,
                                color: Colors.red.shade400,
                                size: 40.sp,
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                'Document Attached',
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  fontFamily: FontFamily.jost,
                                  color: greyColor,
                                ),
                              ),
                            ],
                          ),
                        ))
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.upload_outlined,
                              color: Colors.grey.shade400, size: 28.sp),
                          SizedBox(height: 8.h),
                          Text(
                            'Tap to select image or document',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.grey.shade400,
                              fontFamily: FontFamily.jost,
                            ),
                          ),
                        ],
                      ),
                    )),
        ),
      ),
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}
