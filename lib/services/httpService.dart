import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

class HttpService {
  static final Logger logger = Logger("HttpService");

  static Future<dynamic> postRequest({required String path, required Map<String, dynamic> request}) async {
    final uri = Uri.parse(path);
    final headers = {
      'Content-Type': 'application/json',
    };

    try {
      logger.info("POST Request: URL=$uri, Body=${jsonEncode(request)} Headers=${headers.toString()}");

      final response = await http.post(uri, headers: headers, body: jsonEncode(request));

      return _handleResponse(response);
    } on http.ClientException catch (e) {
      logger.severe('Network error: ${e.message}');
      throw HttpRequestException('Network error: Unable to connect to server. Details: ${e.message}');
    } catch (e) {
      logger.severe('Unexpected error: ${e.toString()}');
      throw HttpRequestException(e.toString());
    }
  }

  static dynamic _handleResponse(http.Response response) {
    logger.info("Response Status Code: ${response.statusCode}");
    logger.info("Response Body: ${response.body}");
    if (response.statusCode == 200) {
      try {
        return jsonDecode(response.body);
      } catch (e) {
        logger.severe('JSON parsing error: ${e.toString()}');
        throw const HttpRequestException('Error parsing server response');
      }
    } else {
      throw HttpRequestException('Error from Server: ${response.statusCode}, Body: ${response.body}');
    }
  }
}

/// Custom exception for HTTP requests
class HttpRequestException implements Exception {
  final String message;
  const HttpRequestException(this.message);

  @override
  String toString() => 'HttpRequestException: $message';
}
