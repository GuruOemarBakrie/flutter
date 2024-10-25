import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  late String _baseUrl;

  AuthService() {
    _initializeBaseUrl();
  }

  Future<void> _initializeBaseUrl() async {
    _baseUrl = await getBaseUrl();
  }

  String get baseUrl => _baseUrl;

  static Future<String> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final serverUrl =
        prefs.getString('server_url') ?? 'http://192.168.1.2:8080';
    return '$serverUrl/api';
  }

  Future<Map<String, dynamic>?> login(String email, String password) async {
    final baseUrl = await getBaseUrl();

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['access_token'];
        final userData = data['user'];

        await _saveToken(token);
        await _saveUserData(userData);
        return userData;
      } else {
        throw Exception('Gagal login: ${response.body}');
      }
    } catch (e) {
      throw Exception('Gagal terhubung ke server: $e');
    }
  }

  Future<void> logout() async {
    final baseUrl = await getBaseUrl();
    final token = await getToken();

    try {
      if (token != null) {
        await http.post(
          Uri.parse('$baseUrl/logout'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
      }
    } finally {
      await _removeToken();
      await _removeUserData();
    }
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  Future<void> _removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> _saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', userData['id'].toString());
    await prefs.setString('user_name', userData['name']);
    await prefs.setString('user_email', userData['email']);
  }

  Future<void> _removeUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
    await prefs.remove('user_name');
    await prefs.remove('user_email');
  }

  Future<Map<String, String?>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'id': prefs.getString('user_id'),
      'name': prefs.getString('user_name'),
      'email': prefs.getString('user_email'),
    };
  }
}
