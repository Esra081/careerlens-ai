import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';

class ApiService {
  final Dio _dio = Dio();
  final String _baseUrl = "http://192.168.1.102:8000";

  // DÖNÜŞ TİPİ DEĞİŞTİ: Artık bool değil, verinin kendisi (Map) dönüyor
  Future<Map<String, dynamic>?> uploadCv(PlatformFile file) async {
    try {
      FormData formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(
          file.path!,
          filename: file.name,
        ),
      });

      Response response = await _dio.post(
        "$_baseUrl/api/v1/analyze-cv",
        data: formData,
        options: Options(
          headers: {
            "Content-Type": "multipart/form-data",
          },
        ),
      );

      if (response.statusCode == 200) {
        // Backend'deki "data" objesinin içindekileri direkt geri yolluyoruz
        return response.data['data'];
      }
      return null; // Başarısızsa boş (null) dön

    } catch (e) {
      print("Dosya yükleme hatası: $e");
      return null;
    }
  }
}