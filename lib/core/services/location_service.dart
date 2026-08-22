import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/foundation.dart';

class LocationService {
  LocationService._();
  
  static Future<String?> getCurrentLocation() async {
    try {
      bool serviceEnabled;
      LocationPermission permission;

      // Test if location services are enabled.
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location services are disabled.');
        return null;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Location permissions are denied');
          return null;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        debugPrint('Location permissions are permanently denied, we cannot request permissions.');
        return null;
      } 

      // When we reach here, permissions are granted and we can
      // continue accessing the position of the device.
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );
      
      debugPrint('Generated Coordinates: ${position.latitude},${position.longitude}');
      return "${position.latitude},${position.longitude}";
    } catch (e) {
      debugPrint('Error getting current location: $e');
      return null;
    }
  }

  static Future<String?> getCurrentLocationAddress() async {
    try {
      Position? position;
      
      // 1. Get Coordinates
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return "Location Services Disabled";

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return "Location Permission Denied";
      }
      
      if (permission == LocationPermission.deniedForever) return "Location Permission Permanently Denied";

      position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );

      // 2. Reverse Geocode
      return await getLocationName(position.latitude, position.longitude);
    } catch (e) {
      debugPrint('Error getting location address: $e');
      return "Unknown Location";
    }
  }

  static Future<String?> getLocationName(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        // Construct a clean address string
        String address = [
          if (place.street != null && place.street!.isNotEmpty) place.street,
          if (place.subLocality != null && place.subLocality!.isNotEmpty) place.subLocality,
          if (place.locality != null && place.locality!.isNotEmpty) place.locality,
          
          if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) place.administrativeArea,
          if (place.postalCode != null && place.postalCode!.isNotEmpty) place.postalCode,
        ].join(", ");
        
        return address.isNotEmpty ? address : "Unknown Location";
      }
      return "Unknown Location";
    } catch (e) {
      debugPrint('Error reverse geocoding: $e');
      return "Unknown Location";
    }
  }
}
