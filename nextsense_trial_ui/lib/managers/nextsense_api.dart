import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:logging/logging.dart';
import 'package:nextsense_trial_ui/config.dart';
import 'package:nextsense_trial_ui/utils/android_logger.dart';

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

class NextsenseApi {
  static final Duration _timeout = Duration(seconds: 10);
  static final int _maxRetries = 3;

  final String _baseUrl = Config.nextsenseApiUrl;
  final _client = http.Client();
  final CustomLogPrinter _logger = CustomLogPrinter('NextsenseApi');

  Uri get _endpointAuth => Uri.parse('$_baseUrl/auth');
  Uri get _endpointChangePassword => Uri.parse('$_baseUrl/change_password');

  NextsenseApi() {}

  Future<ApiResponse> _callApi({required Map<String, dynamic> data, required Uri endpoint,
      required String errorMsg}) async {
    Response? response = null;
    int attemptNumber = 0;
    while (response == null && attemptNumber < _maxRetries) {
      try {
        response = await _client.post(endpoint, headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        }, body: jsonEncode(data)).timeout(_timeout);
      } catch (e) {
        _logger.log(Level.WARNING, e);
      }
    }
    if (response == null) {
      return ApiResponse(
        isError: true,
        isConnectionError: true,
      );
    }

    _logger.log(Level.INFO, endpoint.path + "::response: ${response.body}");

    if (response.statusCode == 200) {
      var responseJson = json.decode(response.body) as Map<String, dynamic>;
      return ApiResponse(data: responseJson);
    } else {
      Map<String, dynamic> responseJson = {};
      String errorMsg = '';
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
    return _callApi(endpoint: _endpointAuth, data: data, errorMsg: "Authentication request failed");
  }

  // Changes the user password.
  Future<ApiResponse> changePassword(String token, String username, String new_password) async {
    var data = {
      'token': token,
      'username': username,
      'new_password': new_password
    };
    return _callApi(endpoint: _endpointChangePassword, data: data,
        errorMsg: "Password change request failed");
  }
}