class QrDto {
  String codigo;
  double latitud;
  double longitud;

  QrDto() {
    this.codigo = '';
    this.latitud = 0;
    this.longitud = 0;
  }

  QrDto.fromJson(Map json)
      : codigo = json['codigo'],
        latitud = json['latitud'],
        longitud = json['longitud'];

  dynamic toJson() {
    return {
      'codigo': codigo,
      'latitud': latitud,
      'longitud': longitud,
    };
  }
}
