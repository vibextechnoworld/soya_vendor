import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiHelper {
  static const String _defaultErrorMessage =
      'Something went wrong. Please try again.';
  static const String _defaultSuccessMessage = 'Operation successful.';

  /// Parses the response and returns a record with success status, message, and decoded data (if any).
  static ({bool success, String message, dynamic data}) handleResponse(
    http.Response response, {
    String? defaultSuccessMessage,
    String? defaultErrorMessage,
  }) {
    try {
      final decodedBody = jsonDecode(response.body);

      // Check for success flag in response body
      bool isSuccess = false;
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (decodedBody is Map<String, dynamic>) {
          // Default to true if not present, but usually backend sends 'success'
          isSuccess = decodedBody['success'] ?? true;
        } else {
          isSuccess = true;
        }
      } else {
        isSuccess = false;
      }

      String message = '';
      if (decodedBody is Map<String, dynamic>) {
        message = decodedBody['message'] ?? '';
      }

      if (message.isEmpty) {
        message = isSuccess
            ? (defaultSuccessMessage ?? _defaultSuccessMessage)
            : (defaultErrorMessage ?? _defaultErrorMessage);
      }

      return (
        success: isSuccess,
        message: message,
        data: decodedBody,
      );
    } catch (e) {
      return (
        success: false,
        message: defaultErrorMessage ?? 'Failed to parse response: $e',
        data: null,
      );
    }
  }
}
