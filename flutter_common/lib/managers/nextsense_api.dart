import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:logging/logging.dart';
import 'package:flutter_common/utils/android_logger.dart';

class ApiResponse {
  final Map<String, dynamic> data;
  final bool isError;
  final bool isConnectionError;
  final String error;

  ApiResponse({
    this.data = const {},
    this.isError = false,
    this.isConnectionError = false,
    this.error = '',
  });
}

enum SignInEmailType {
  signUp,
  resetPassword
}

class NextsenseApi {
  static const Duration _timeout = Duration(seconds: 10);
  static const int _maxRetries = 3;

  final String _baseUrl;
  final _client = http.Client();
  final CustomLogPrinter _logger = CustomLogPrinter('NextsenseApi');

  Uri get _endpointAuth => Uri.parse('$_baseUrl/auth');
  Uri get _endpointChangePassword => Uri.parse('$_baseUrl/change_password');
  Uri get _endpointSendSignInEmail => Uri.parse('$_baseUrl/send_signin_email');

  NextsenseApi(String baseUrl) : _baseUrl = baseUrl;

  Future<ApiResponse> _callApi({required Map<String, dynamic> data, required Uri endpoint,
    required String defaultErrorMsg}) async {
    Response? response;
    int attemptNumber = 0;
    while (response == null && attemptNumber < _maxRetries) {
      try {
        response = await _client.post(endpoint, headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        }, body: jsonEncode(data)).timeout(_timeout);
      } catch (e) {
        attemptNumber++;
        _logger.log(Level.WARNING, e);
      }
    }
    if (response == null) {
      return ApiResponse(
        isError: true,
        isConnectionError: true,
      );
    }

    _logger.log(Level.INFO, "${endpoint.path}::response: ${response.body}");

    if (response.statusCode == 200) {
      var responseJson = json.decode(response.body) as Map<String, dynamic>;
      return ApiResponse(data: responseJson);
    } else {
      Map<String, dynamic> responseJson = {};
      String errorMsg = defaultErrorMsg;
      try {
        responseJson = json.decode(response.body) as Map<String, dynamic>;
        errorMsg = responseJson['error'];
      } catch (e) {
        _logger.log(Level.WARNING, e);
      }
      return ApiResponse(
          data: responseJson,
          isError: true,
          error: errorMsg
      );
    }
  }

  // Returns `token` that app can use to authorize in Firebase
  Future<ApiResponse> auth(String username, String password) async {
    var data = {
      'username': username,
      'password': password
    };
    return _callApi(endpoint: _endpointAuth, data: data,
        defaultErrorMsg: "Authentication request failed");
  }

  // Changes the user password.
  Future<ApiResponse> changePassword(String token, String username, String newPassword) async {
    var data = {
      'token': token,
      'username': username,
      'new_password': newPassword
    };
    return _callApi(endpoint: _endpointChangePassword, data: data,
        defaultErrorMsg: "Password change request failed");
  }

  // Changes the user password.
  Future<ApiResponse> sendSignInEmail(
      {required String email, required SignInEmailType emailType}) async {
    var data = {
      'email': email,
      'email_type': emailType.name.toLowerCase()
    };
    _logger.log(Level.INFO, "Calling API to send signin email: $data");
    return _callApi(endpoint: _endpointSendSignInEmail, data: data,
        defaultErrorMsg: "Password change request failed");
  }
}