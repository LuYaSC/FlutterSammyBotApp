import 'dart:convert';
import 'dart:io';
import 'package:appsammybot/Models/ci_dto.dart';
import 'package:appsammybot/Models/get_data_covid_dto.dart';
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
  static Future getDatesCovid(GetDataCovidDto dto) {
    var baseUrl =
        "https://40.71.92.46:443/SitiosApi/GetDatesCovid/api/GetDataCovid/GetCasesCovid";
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

  static Future<String> apiPostGetdataCovid(GetDataCovidDto data) async {
    HttpClient client = new HttpClient();
    client.badCertificateCallback =
        (X509Certificate cert, String host, int port) => true;
    HttpClientRequest request = await client.postUrl(Uri.parse(
        "https://40.71.92.46:443/SitiosApi/GetDatesCovid/api/GetDataCovid/GetCasesCovid"));
    request.headers.set(HttpHeaders.contentTypeHeader, "application/json");
    request.add(utf8.encode(json.encode(data)));
    HttpClientResponse response = await request.close();
    return await response.transform(utf8.decoder).join();
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
