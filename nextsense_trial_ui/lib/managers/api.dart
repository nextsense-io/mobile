import 'dart:convert';

import 'package:http/http.dart' as http;
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

  final CustomLogPrinter _logger = CustomLogPrinter('NextsenseApi');

  final String baseUrl = Config.nextsenseApiUrl;

  Uri get endpointAuth => Uri.parse('$baseUrl/auth');

  final client = http.Client();

  NextsenseApi() {}

  // Returns `token` that app can use to authorize in Firebase
  Future<ApiResponse> auth(String username, String password) async {

    var data = {
      'username': username,
      'password': password
    };

    var response;
    try {
      response = await client.post(endpointAuth, headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      }, body: jsonEncode(data)).timeout(const Duration(seconds: 5));
    } catch (e) {
      _logger.log(Level.WARNING, e);
      return ApiResponse(
        isError: true,
        isConnectionError: true,
      );
    }

    _logger.log(Level.INFO, "Api::auth()::response: ${response.body}");

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
        errorMsg = "Authentication request failed";
      }
      return ApiResponse(
          data: responseJson,
          isError: true,
          error: errorMsg
      );
    }
  }

}