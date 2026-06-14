class ApiConstants {
  // Private constructor to prevent instantiation
  ApiConstants._();
  //------------------------ Vender APIs Endpoints --------------------------//

  // Base URL and Host
  static const String baseHost = 'https://soya-farmer-1.onrender.com'; //old url
  //static const String baseHost = 'http://59.94.35.174:8081';
  static const String baseUrl = '$baseHost/api';
  static String get imageBaseUrl => baseHost;

  // Auth Endpoints
  static const String login = '$baseUrl/auth/login'; //post
  static const String forgotPassword = '$baseUrl/auth/forgot-password';

  //----------------Farmer modeul Endpoints(KYC)--------------------------//

  //create farmer,update,fetch farmer by id({{farmerId}})
  static const String createFarmer = '$baseUrl/farmer/create-farmer'; //post
  static const String farmerProfile = '$baseUrl/farmer/list'; //get
  static const String nonKycFarmerList = '$baseUrl/farmer/list/non-kyc'; //get
  static const String getFarmerById = '$baseUrl/farmer/{{farmerId}}'; //get
  static const String updateFarmerById =
      '$baseUrl/farmer/update/{{farmerId}}'; //put

  //farmer documents
  static const String createFarmerDocument =
      '$baseUrl/farmer/document'; //post(LAND,other) - {{farmerId}} currently not required

  static const String createFarmerDocuments =
      '$baseUrl/farmer/documents/{{farmerId}}'; //identification data upload(adhar pan and driving license)
  static const String getFarmerDocumentById =
      '$baseUrl/farmer/document/{{farmerId}}'; //get
  static const String updateFarmerDocumentById =
      '$baseUrl/farmer/document/{{farmerId}}'; //put

  //farmer land details

//   static const String createFarmerLand =
//       '$baseUrl/farmer/{{farmerId}}/land'; //post
  static const String createFarmerLands =
      '$baseUrl/farmer/{{farmerId}}/lands'; //post (plural)
  static const String getFarmerLandById =
      '$baseUrl/farmer/{{farmerId}}/land'; //get
  static const String updateFarmerLandById =
      '$baseUrl/farmer/{{farmerId}}/land'; //put

  //farmer bank
  static const String createFarmerBank =
      '$baseUrl/farmer/{{farmerId}}/bank'; //post
  static const String getFarmerBankById =
      '$baseUrl/farmer/{{farmerId}}/bank'; //get
  static const String updateFarmerBankById =
      '$baseUrl/farmer/{{farmerId}}/bank/{{bankRecordId}}'; //put

  // ---------------------- Stock Api module Endpoints -------------------------- //

  static const String addStock = '$baseUrl/stock/add'; //post
  static const String getStockSummary =
      '$baseUrl/stock/farmer/{{farmerId}}'; //get
  static const String getVendorStockSummary = '$baseUrl/stock/summary'; //get
  static const String getVendorStock = '$baseUrl/stock/'; //get
  static const String adjustStock = '$baseUrl/stock/adjust'; //post
  static const String stockTransfer = '$baseUrl/stock/transfers'; //post
  static const String getVendorTransferList = '$baseUrl/stock/transfers'; //get
  static const String returnBagsToFarmer =
      '$baseUrl/stock/bags/return-to-farmer'; //post
  static const String getBagSummary = '$baseUrl/stock/bags/summary'; //get
  static const String getFarmerBagReturnDue =
      '$baseUrl/stock/bags/return-due/{{farmerId}}'; //get
  static const String addOwnOpeningBags = '$baseUrl/stock/bags/own-add'; //post
  //newApis
  static const String getInventoryLocations = '$baseUrl/stock/locations'; //get
  static const String getThappis = '$baseUrl/stock/thappis'; //get
  static const String deleteThappi = '$baseUrl/stock/thappis/{{thappiId}}'; //delete
  static const String splitThappi =
      '$baseUrl/stock/thappis/{{thappiId}}/split'; //post
  static const String mergeThappis = '$baseUrl/stock/thappis/merge'; //post
  static const String dispatchTransfer =
      '$baseUrl/admin/transfers/{{transferId}}/complete'; //put
  static const String receiveTransfer =
      '$baseUrl/stock/transfers/{{transferId}}/receive'; //put

  //------------------------- Product Api  -------------------------- //

  static const String getAllProduc = '$baseUrl/product'; //get
  static const String getProductById = '$baseUrl/product/{{id}}'; //get

  //-------------------------Billing Api  -------------------------- //

  //bill crud and finalize api vendor
  // static const String createBill = '$baseUrl/bill/save'; //post
  static const String getBills = '$baseUrl/bill'; //get
  static const String getbillDetails = '$baseUrl/bill/{{billId}}'; //get
  // static const String billFinalize = '$baseUrl/bill/{{billId}}/finalize'; //post

  // New Billing Flow (Draft, Calculate, Apply, Preview, Confirm)
  static const String createBillDraft = '$baseUrl/bill/draft'; //post
  static const String calculateDeductions =
      '$baseUrl/bill/{{billId}}/deductions/calc'; //post
  static const String applyGoniDeduction =
      '$baseUrl/bill/{{billId}}/goni'; //post
  static const String previewBillDraft =
      '$baseUrl/bill/{{billId}}/preview'; //get
  static const String confirmBillDraft =
      '$baseUrl/bill/{{billId}}/confirm'; //post
  static const String getBillGraph =
      '$baseUrl/bill/graph/last-six-months'; //get

  // ---------------------- Product Api module Endpoints (Vendor) -------------------------- //

  static const String getProductsVendor =
      '$baseUrl/vendor/product/products'; //get
  static const String getProductByIdVendor =
      '$baseUrl/vendor/product/{{productId}}'; //get
  static const String createProductVendor =
      '$baseUrl/vendor/product/create'; //post
  static const String updateProductVendor =
      '$baseUrl/vendor/product/{{productId}}'; //put
  //------------------------------------------------------------------------//
  //-------------------------Admin APIs Endpoints-----------------------------//
  //------------------------------------------------------------------------//
  //2.location api
  static const String getLocations = '$baseUrl/location'; //get
  static const String createLocation = '$baseUrl/location'; //post
  static const String updateLocation = '$baseUrl/location/{{locationId}}'; //put

  //1. mill api
  static const String getMills = '$baseUrl/mill'; //get
  static const String createMill = '$baseUrl/mill'; //post
  static const String updateMill = '$baseUrl/mill/{{millId}}'; //put

  //3.user(vendor) api
  static const String getVendors =
      '$baseUrl/auth/vendor/list?page=1&limit=5&search=John&isActive=true'; //get
  static const String createVendor = '$baseUrl/auth/vendor-register'; //post
  static const String updateVendor =
      '$baseUrl/auth/vendor/{{vendor_id}}/status'; //patch
  static const String updateVendorById =
      '$baseUrl/auth/vendor/{{vendor_id}}'; //put

  //4.product api
  static const String getProducts = '$baseUrl/product'; //get
  static const String getProductByIdAdmin =
      '$baseUrl/product/{{productId}}'; //get
  static const String getProductsAdmin = '$baseUrl/product/admin'; //get
  static const String createProduct = '$baseUrl/product'; //post
  static const String updateProductAdmin =
      '$baseUrl/product/{{productId}}'; //put
  static const String patchProductAdmin =
      '$baseUrl/product/{{productId}}'; //patch

  //5.vehicle api
  static const String getVehicles = '$baseUrl/vehicle'; //get
  static const String getVehicleById = '$baseUrl/vehicle/{{vehicleId}}'; //get
  static const String createVehicle = '$baseUrl/vehicle'; //post
  static const String updateVehicle = '$baseUrl/vehicle/{{vehicleId}}'; //put
  static const String deleteVehicle = '$baseUrl/vehicle/{{vehicleId}}'; //delete

//6.payment api
  static const String adminPayBill = '$baseUrl/admin/{{billId}}/pay'; //post
  static const String adminRejectbill =
      '$baseUrl/admin/{{billId}}/reject'; //post

  //7. Deductions & Goni Types (Admin Management)
  static const String getDeductionMasters = '$baseUrl/admin/deductions'; //get
  static const String getGoniTypes = '$baseUrl/admin/goni-types'; //get

  //8. todays rate
  static const String getTodaysRate = '$baseUrl/stock/quality-rates'; //get

  // 9. Bank Details
  static const String getBankDetails = '$baseUrl/bank-details/'; //get
  static const String createBankDetail = '$baseUrl/bank-details'; //post

  // 10. Farmer Advances API
  static const String getFarmerAdvances =
      '$baseUrl/admin/farmers/{{farmerId}}/advances'; //get
  static const String addFarmerAdvance =
      '$baseUrl/admin/farmers/{{farmerId}}/advances'; //post
  static const String getFarmerAdvanceBalance =
      '$baseUrl/admin/farmers/{{farmerId}}/advance-balance'; //get
  static const String disclaimer = '$baseUrl/disclaimer';
}
