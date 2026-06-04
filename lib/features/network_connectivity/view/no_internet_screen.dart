// ignore_for_file: library_private_types_in_public_api, use_super_parameters

import 'package:flutter/material.dart';
import 'package:soya_app/util/colors.dart';
import 'package:soya_app/util/connectivity_service.dart';

class NoInternetScreen extends StatefulWidget {
  final VoidCallback? onConnected;

  const NoInternetScreen({Key? key, this.onConnected}) : super(key: key);

  @override
  _NoInternetScreenState createState() => _NoInternetScreenState();
}

class _NoInternetScreenState extends State<NoInternetScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final ConnectivityService _connectivityService = ConnectivityService();

  @override
  void initState() {
    super.initState();

    // Setup animation
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();

    // Listen for connectivity changes
    _connectivityService.isConnected.addListener(_onConnectivityChanged);
  }

  void _onConnectivityChanged() {
    if (_connectivityService.isConnected.value) {
      // Connection restored, dismiss screen
      if (widget.onConnected != null) {
        widget.onConnected!();
      }
    }
  }

  @override
  void dispose() {
    _connectivityService.isConnected.removeListener(_onConnectivityChanged);
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightGreenColor,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // No Internet Icon
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: yelloColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.wifi_off_rounded,
                      size: 60,
                      color: yelloColor,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Main Message
                  Text(
                    'No Internet Connection',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Gilroy Bold',
                      fontSize: 24,
                      color: blackColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Description
                  Text(
                    'Please check your internet connection\nand try again.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Gilroy Medium',
                      fontSize: 16,
                      color: greyColor,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Retry Button
                  ElevatedButton(
                    onPressed: () async {
                      // Check connectivity again
                      await _connectivityService.checkConnectivity();

                      // If connected now, trigger callback
                      if (_connectivityService.hasConnection) {
                        if (widget.onConnected != null) {
                          widget.onConnected!();
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: yelloColor,
                      foregroundColor: whiteColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 48,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Retry',
                      style: TextStyle(fontFamily: 'Gilroy Bold', fontSize: 16),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Auto-check indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(yelloColor),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Checking connection...',
                        style: TextStyle(
                          fontFamily: 'Gilroy Regular',
                          fontSize: 14,
                          color: greyColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
