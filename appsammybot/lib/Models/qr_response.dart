class QrResponse {
  String numeroCel;
  String ci;
  int nivelAlerta;
  String descripcionAlerta;
  String observaciones;

  QrResponse() {
    this.numeroCel = '';
    this.ci = '';
    this.nivelAlerta = 0;
    this.descripcionAlerta = '';
    this.observaciones = '';
  }

  QrResponse.fromJson(Map json)
      : numeroCel = json['NumeroCel'],
        ci = json['CI'],
        nivelAlerta = json['NivelAlerta'],
        descripcionAlerta = json['DescripcionAlerta'],
        observaciones = json['Observaciones'];

  dynamic toJson() {
    return {
      'numeroCel': numeroCel,
      'ci': ci,
      'nivelAlerta': nivelAlerta,
      'descripcionAlerta': descripcionAlerta,
      'observaciones': observaciones,
    };
  }
}
