import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

/// HTTP client for the application
/// For production use, proper certificate validation is enforced
class DevHttpClient {
  static http.Client? _instance;

  static http.Client get instance {
    if (_instance == null) {
      // Create standard HttpClient with proper certificate validation
      HttpClient httpClient = HttpClient();

      // Proper certificate validation for production
      httpClient.badCertificateCallback = null; // Use default validation

      _instance = IOClient(httpClient);
    }
    return _instance!;
  }

  /// Reset the client instance (useful for testing)
  static void reset() {
    _instance?.close();
    _instance = null;
  }

  // Override standard HTTP methods to use our custom client
  static Future<http.Response> get(Uri url, {Map<String, String>? headers}) {
    return instance.get(url, headers: headers);
  }

  static Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) {
    return instance.post(url, headers: headers, body: body, encoding: encoding);
  }

  static Future<http.Response> put(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) {
    return instance.put(url, headers: headers, body: body, encoding: encoding);
  }

  static Future<http.Response> delete(Uri url, {Map<String, String>? headers}) {
    return instance.delete(url, headers: headers);
  }
}
