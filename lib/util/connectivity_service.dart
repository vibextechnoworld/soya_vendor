// ignore_for_file: prefer_final_fields

import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Singleton service to manage network connectivity monitoring
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  // Current connectivity status
  ValueNotifier<bool> isConnected = ValueNotifier<bool>(true);

  /// Initialize the connectivity service and start listening
  void initialize() {
    // Check initial connectivity
    checkConnectivity();

    // Listen to connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      _updateConnectionStatus(results);
    });
  }

  /// Check current connectivity status
  Future<void> checkConnectivity() async {
    try {
      final List<ConnectivityResult> results = await _connectivity
          .checkConnectivity();
      _updateConnectionStatus(results);
    } catch (e) {
      if (kDebugMode) {
        print('Error checking connectivity: $e');
      }
      isConnected.value = false;
    }
  }

  /// Update connection status based on connectivity results
  void _updateConnectionStatus(List<ConnectivityResult> results) {
    // Check if there's any valid connection (wifi, mobile, ethernet, etc.)
    final hasConnection =
        results.isNotEmpty &&
        !results.every((result) => result == ConnectivityResult.none);

    isConnected.value = hasConnection;

    if (kDebugMode) {
      print(
        'Connectivity changed: ${results.map((r) => r.toString()).join(', ')} - Connected: $hasConnection',
      );
    }
  }

  /// Get current connectivity status synchronously
  bool get hasConnection => isConnected.value;

  /// Dispose the service and cancel subscriptions
  void dispose() {
    _connectivitySubscription?.cancel();
    isConnected.dispose();
  }
}
