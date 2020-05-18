class GetDataCovidDto {
  int country;
	int state;

  GetDataCovidDto() {
    this.country = 0;
    this.state = 0;
  }

  GetDataCovidDto.fromJson(Map json)
      : country = json['country'],
        state = json['state'];

  dynamic toJson() {
    return {
      'country': country,
      'state': state,
    };
  }
}
