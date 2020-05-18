class GetDataCovidResult {
  int totalInfecteds;
  int totalWishes;
  int totalRecovered;

  GetDataCovidResult() {
    this.totalInfecteds = 0;
    this.totalWishes = 0;
    this.totalRecovered = 0;
  }

  GetDataCovidResult.fromJson(Map json)
      : totalInfecteds = json['totalInfecteds'],
        totalWishes = json['totalWishes'],
        totalRecovered = json['totalRecovered'];

  dynamic toJson() {
    return {
      'totalInfecteds': totalInfecteds,
      'totalWishes': totalWishes,
      'totalRecovered': totalRecovered,
    };
  }
}
