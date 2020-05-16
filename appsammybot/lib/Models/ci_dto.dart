class CiDto {
  String ci;
  double latitud;
  double longitud;

  CiDto() {
    this.ci = '';
    this.latitud = 0;
    this.longitud = 0;
  }

  CiDto.fromJson(Map json)
      : ci = json['CI'],
        latitud = json['Latitud'],
        longitud = json['Longitud'];

  dynamic toJson() {
    return {
      'ci': ci,
      'latitud': latitud,
      'longitud': longitud,
    };
  }
}
