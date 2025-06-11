import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> main() async {
  // Test the API connectivity
  print('Testing EduVision API...');
  
  const String baseUrl = 'https://eduvision-api-accscqa6f5d6dha5.southeastasia-01.azurewebsites.net/api/Auth';
  
  try {
    // Test 1: Try to register a test email
    print('\n1. Testing registration endpoint...');
    final registerResponse = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {
        'Content-Type': 'application/json',
        'accept': '*/*',
      },
      body: jsonEncode({
        'email': 'test@example.com',
      }),
    );
    
    print('Register Status: ${registerResponse.statusCode}');
    print('Register Response: ${registerResponse.body}');
    
    // Test 2: Try to login with invalid credentials (should fail)
    print('\n2. Testing login endpoint with invalid credentials...');
    final loginResponse = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {
        'Content-Type': 'application/json',
        'accept': '*/*',
      },
      body: jsonEncode({
        'username': 'invalid@example.com',
        'password': 'invalidpassword',
      }),
    );
    
    print('Login Status: ${loginResponse.statusCode}');
    print('Login Response: ${loginResponse.body}');
    
    print('\nAPI test completed!');
    
  } catch (e) {
    print('Error testing API: $e');
  }
}
