import 'dart:convert';
import 'package:appsammybot/Models/ci_dto.dart';
import 'package:appsammybot/Models/qr_dto.dart';
import 'package:http/http.dart' as http;

class QueriesService {
  static Future getQrDates(QrDto dto) {
    var baseUrl =
        "https://doctorvirtual.ngrok.io/DoctorVirtual.IdentificacionBiologica.Api/api/Qr";
    var bodyEncoded = json.encode(dto);
    return http.post(
      baseUrl,
      body: bodyEncoded,
      headers: {
        "Content-Type": "application/json",
        //HttpHeaders.authorizationHeader: 'Bearer ' + token
      },
    );
  }

   static Future getCIDates(CiDto dto) {
    var baseUrl =
        "https://doctorvirtual.ngrok.io/DoctorVirtual.IdentificacionBiologica.Api/api/CI";
    var bodyEncoded = json.encode(dto);
    return http.post(
      baseUrl,
      body: bodyEncoded,
      headers: {
        "Content-Type": "application/json",
        //HttpHeaders.authorizationHeader: 'Bearer ' + token
      },
    );
  }
}
