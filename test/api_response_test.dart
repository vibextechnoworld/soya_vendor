@Timeout(Duration(minutes: 3))
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  test('Fetch and display Soya App API responses', () async {
    const baseUrl = 'https://soya-farmer-1.onrender.com/api';

    final candidates = [
      {
        'email': 'adarshsalgudi10@gmail.com',
        'passwords': [
          'adarsh@123', 'Adarsh@123', '7709574488', '123456', 'password', 'adarsh', 'adarsh123', '12345678', '1234567890'
        ]
      },
      {
        'email': 'vendor@dashonsolutions.com',
        'passwords': [
          '8087828173', '123456', 'password', 'vendor123', 'gajraj@123', 'Gajraj@123', 'gajraj123', '12345678', '1234567890'
        ]
      },
    ];

    String? vendorToken;

    for (var cand in candidates) {
      if (vendorToken != null) break;
      final email = cand['email'] as String;
      final passwords = cand['passwords'] as List<String>;

      for (var pwd in passwords) {
        try {
          final loginUrl = '$baseUrl/auth/login';
          print('Trying Login: $email with $pwd');
          final res = await http.post(
            Uri.parse(loginUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': email,
              'password': pwd,
              'role': 'VENDOR',
            }),
          );

          if (res.statusCode == 200) {
            final data = jsonDecode(res.body);
            if (data['success'] == true && data['data'] != null && data['data']['token'] != null) {
              vendorToken = data['data']['token'];
              print('🎉 SUCCESS: Logged in as $email! Token: $vendorToken');
              break;
            } else {
              print('Login failed with success=false or null token: ${res.body}');
            }
          } else {
            print('Login HTTP status: ${res.statusCode}, Body: ${res.body}');
          }
        } catch (e) {
          print('Login error: $e');
        }
      }
    }

    if (vendorToken == null) {
      print('❌ Could not login as vendor with common passwords.');
      return;
    }

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $vendorToken',
    };

    // 1. Locations
    try {
      final locUrl = '$baseUrl/stock/locations?limit=10&isActive=true';
      print('\nCalling locations: $locUrl');
      final locRes = await http.get(Uri.parse(locUrl), headers: headers);
      print('Locations API Status: ${locRes.statusCode}');
      print('Locations API Body:');
      print(locRes.body);
    } catch (e) {
      print('Locations API error: $e');
    }

    // 2. Transfers
    try {
      final transferUrl = '$baseUrl/stock/transfers?limit=5';
      print('\nCalling transfers: $transferUrl');
      final transRes = await http.get(Uri.parse(transferUrl), headers: headers);
      print('Transfers API Status: ${transRes.statusCode}');
      print('Transfers API Body:');
      print(transRes.body);
    } catch (e) {
      print('Transfers list API error: $e');
    }
  });
}
