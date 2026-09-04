import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:soya_app/core/services/navigation_service.dart';
import 'package:soya_app/routes/app_routes.dart';

/// Centralized API service that automatically adds authentication token to all requests
class ApiService {
  // Private constructor for singleton pattern
  ApiService._();
  static final ApiService instance = ApiService._();

  // Timeout duration
  static const Duration _timeout = Duration(seconds: 30);

  /// Check internet connectivity
  Future<bool> _isConnected() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.none)) {
      return false;
    }
    return true;
  }

  /// Wrapper for all HTTP requests to handle exceptions and timeouts
  Future<http.Response> _handleRequest(
      Future<http.Response> Function() request,
      {Duration? timeout}) async {
    if (!await _isConnected()) {
      throw const SocketException('No internet connection');
    }

    try {
      final response = await request().timeout(timeout ?? _timeout);

      if (response.statusCode == 401) {
        _logout();
      }

      return response;
    } on SocketException catch (e) {
      throw Exception('Failed to connect to server: ${e.message}');
    } on http.ClientException catch (e) {
      throw Exception('Client error: ${e.message}');
    } on TimeoutException {
      throw Exception('Request timed out. Please try again.');
    } on Exception catch (e) {
      throw Exception('An unexpected error occurred: ${e.toString()}');
    }
  }

  /// Logout and redirect to login screen
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    // Redirect to login using global navigator key
    NavigationService.state?.pushNamedAndRemoveUntil(
      AppRoutes.login,
      (route) => false,
    );
  }

  /// Get the stored authentication token (centralized)
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    print('🔑 USER AUTH TOKEN: $token');
    return token;
  }

  /// Get headers with authentication token
  Future<Map<String, String>> _getHeaders({
    Map<String, String>? additionalHeaders,
    bool includeAuth = true,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    // Add authentication token if required
    if (includeAuth) {
      final token = await getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    // Add any additional headers
    if (additionalHeaders != null) {
      headers.addAll(additionalHeaders);
    }

    return headers;
  }

  /// GET request
  Future<http.Response> get(
    String url, {
    Map<String, String>? headers,
    bool includeAuth = true,
  }) async {
    return await _handleRequest(() async {
      final requestHeaders = await _getHeaders(
        additionalHeaders: headers,
        includeAuth: includeAuth,
      );
      print('🌐 API GET REQUEST: $url');
      print('🌐 Headers: $requestHeaders');
      final response = await http.get(
        Uri.parse(url),
        headers: requestHeaders,
      );
      print('🌐 GET Response [${response.statusCode}]: ${response.body}');
      return response;
    });
  }

  /// POST request
  Future<http.Response> post(
    String url, {
    Map<String, String>? headers,
    dynamic body,
    bool includeAuth = true,
  }) async {
    return await _handleRequest(() async {
      final requestHeaders = await _getHeaders(
        additionalHeaders: headers,
        includeAuth: includeAuth,
      );
      final requestBody = body != null ? jsonEncode(body) : null;
      print('🌐 API POST REQUEST: $url');
      print('🌐 Headers: $requestHeaders');
      print('🌐 Request Body: $requestBody');
      final response = await http.post(
        Uri.parse(url),
        headers: requestHeaders,
        body: requestBody,
      );
      print('🌐 POST Response [${response.statusCode}]: ${response.body}');
      return response;
    });
  }

  /// PUT request
  Future<http.Response> put(
    String url, {
    Map<String, String>? headers,
    dynamic body,
    bool includeAuth = true,
  }) async {
    return await _handleRequest(() async {
      final requestHeaders = await _getHeaders(
        additionalHeaders: headers,
        includeAuth: includeAuth,
      );
      final requestBody = body != null ? jsonEncode(body) : null;
      print('🌐 API PUT REQUEST: $url');
      print('🌐 Headers: $requestHeaders');
      print('🌐 Request Body: $requestBody');
      final response = await http.put(
        Uri.parse(url),
        headers: requestHeaders,
        body: requestBody,
      );
      print('🌐 PUT Response [${response.statusCode}]: ${response.body}');
      return response;
    });
  }

  /// DELETE request
  Future<http.Response> delete(
    String url, {
    Map<String, String>? headers,
    dynamic body,
    bool includeAuth = true,
  }) async {
    return await _handleRequest(() async {
      final requestHeaders = await _getHeaders(
        additionalHeaders: headers,
        includeAuth: includeAuth,
      );
      return await http.delete(
        Uri.parse(url),
        headers: requestHeaders,
        body: body != null ? jsonEncode(body) : null,
      );
    });
  }

  /// PATCH request
  Future<http.Response> patch(
    String url, {
    Map<String, String>? headers,
    dynamic body,
    bool includeAuth = true,
  }) async {
    return await _handleRequest(() async {
      final requestHeaders = await _getHeaders(
        additionalHeaders: headers,
        includeAuth: includeAuth,
      );
      return await http.patch(
        Uri.parse(url),
        headers: requestHeaders,
        body: body != null ? jsonEncode(body) : null,
      );
    });
  }

  /// Multipart request for file uploads
  Future<http.Response> multipartRequest(
    String url, {
    String method = 'POST',
    Map<String, String>? headers,
    Map<String, String>? fields,
    List<http.MultipartFile>? files,
    bool includeAuth = true,
    Duration? timeout,
  }) async {
    final effectiveTimeout = timeout ??
        const Duration(seconds: 180);
    return await _handleRequest(() async {
      final request = http.MultipartRequest(method, Uri.parse(url));

      // Add authentication
      if (includeAuth) {
        final token = await getToken();
        if (token != null && token.isNotEmpty) {
          request.headers['Authorization'] = 'Bearer $token';
        }
      }

      // Add additional headers
      if (headers != null) {
        request.headers.addAll(headers);
      }

      // Add fields
      if (fields != null) {
        request.fields.addAll(fields);
      }

      // Add files
      if (files != null) {
        request.files.addAll(files);
      }

      print('🌐 API MULTIPART REQUEST ($method): $url');
      print('🌐 Multipart Headers: ${request.headers}');
      print('🌐 Multipart Fields: ${request.fields}');
      print('🌐 Multipart Files count: ${request.files.length}');

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      print('🌐 MULTIPART Response [${response.statusCode}]: ${response.body}');
      return response;
    }, timeout: effectiveTimeout);
  }
}
