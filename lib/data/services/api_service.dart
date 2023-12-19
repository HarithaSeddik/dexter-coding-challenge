import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

//Decorator pattern, this makes it cleaner to make Mock implementations for our API and other service classes
abstract class DataService {
  Future<Map<String, dynamic>> sendAudioFile(String filePath);
}

class SttApiService implements DataService {
  @override
  Future<Map<String, dynamic>> sendAudioFile(String filePath) async {
    // Create a multipart request
    var request = http.MultipartRequest('POST',
        Uri.parse('https://35.207.149.36:443/stt_flutter_tech_assignment'));

    // Add headers
    request.headers.addAll({
      'Authorization': 'Bearer KsJ5Ag3',
    });

    // Add the file
    var file = await http.MultipartFile.fromPath('file', filePath);
    request.files.add(file);

    try {
      // Send the request
      var streamedResponse = await request.send();

      // Convert StreamedResponse to Response
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        print('File uploaded successfully');
      } else {
        print('Failed to upload file');
      }

      // Return the http.Response
      final responseBody = response.body;
      return jsonDecode(responseBody);
    } catch (e) {
      print(e);
      // In case of an error, throw an exception or return an appropriate response
      throw Exception('Failed to upload file: $e');
    }
  }
}

class CustomHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}
