import 'dart:convert';
import 'dart:io';
import 'package:appsammybot/Models/ci_dto.dart';
import 'package:appsammybot/Models/get_data_covid_dto.dart';
import 'package:appsammybot/Models/get_data_covid_result.dart';
import 'package:appsammybot/Models/qr_dto.dart';
import 'package:appsammybot/Models/qr_response.dart';
import 'package:appsammybot/Services/queries_service.dart';
import 'package:appsammybot/constant.dart';
import 'package:appsammybot/widgets/counter.dart';
import 'package:appsammybot/widgets/my_header.dart';
import 'package:device_info/device_info.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get_ip/get_ip.dart';
import 'package:location/location.dart';
import 'package:qrscan/qrscan.dart' as scanner;
import 'package:url_launcher/url_launcher.dart';

class PrincipalView extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sammy Bot',
      theme: ThemeData(
          scaffoldBackgroundColor: kBackgroundColor,
          fontFamily: "Poppins",
          textTheme: TextTheme(
            bodyText1: TextStyle(color: kBodyTextColor),
          )),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final controller = ScrollController();
  double offset = 0;
  String barCode = '';
  QrDto dtoQr = new QrDto();
  CiDto cidto = new CiDto();
  QrResponse resultQr = new QrResponse();
  TextEditingController _textFieldCiController =
      TextEditingController(text: '');
  bool _isFetching = false;
  Location location = new Location();
  PermissionStatus _permissionGranted;
  LocationData _locationData;
  static final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
  Map<String, dynamic> _deviceData = <String, dynamic>{};
  String _ip = 'Unknown';
  GetDataCovidDto dtoQueriesCovid = new GetDataCovidDto();
  GetDataCovidResult resultCountry = new GetDataCovidResult();
  GetDataCovidResult resultState = new GetDataCovidResult();

  List<BranchOffice> _branchOffices = BranchOffice.getBranchOffices();
  List<DropdownMenuItem<BranchOffice>> _dropdownItemsBranchOffice;
  BranchOffice _selectedBranchOffice;

  List<DropdownMenuItem<BranchOffice>> buildDropdownMenuItemsBranchOffice(
      List branchs) {
    List<DropdownMenuItem<BranchOffice>> items = List();
    for (BranchOffice branch in branchs) {
      items.add(
        DropdownMenuItem(
          value: branch,
          child: Text(branch.description),
        ),
      );
    }
    return items;
  }

  onChangeDropdownItemBranchOffice(BranchOffice selectedBranchOffice) {
    setState(() {
      _selectedBranchOffice = selectedBranchOffice;
      dtoQueriesCovid.state = _selectedBranchOffice.code;
      reconsultDates();
    });
  }

  Future<void> _initPlatformState() async {
    String ipAddress;
    try {
      ipAddress = await GetIp.ipAddress;
    } on PlatformException {
      ipAddress = 'Failed to get ipAddress.';
    }

    if (!mounted) return;

    setState(() {
      _ip = ipAddress;
    });
  }

  Future<void> _initPlatformStateDevice() async {
    Map<String, dynamic> deviceData;

    try {
      if (Platform.isAndroid) {
        deviceData = _readAndroidBuildData(await deviceInfoPlugin.androidInfo);
      } else if (Platform.isIOS) {
        deviceData = _readIosDeviceInfo(await deviceInfoPlugin.iosInfo);
      }
    } on PlatformException {
      deviceData = <String, dynamic>{
        'Error:': 'Failed to get platform version.'
      };
    }

    if (!mounted) return;

    setState(() {
      _deviceData = deviceData;
    });
  }

  Map<String, dynamic> _readAndroidBuildData(AndroidDeviceInfo build) {
    return <String, dynamic>{
      'version.securityPatch': build.version.securityPatch,
      'version.sdkInt': build.version.sdkInt,
      'version.release': build.version.release,
      'version.previewSdkInt': build.version.previewSdkInt,
      'version.incremental': build.version.incremental,
      'version.codename': build.version.codename,
      'version.baseOS': build.version.baseOS,
      'fingerprint': build.fingerprint,
      'board': build.board,
      'bootloader': build.bootloader,
      'brand': build.brand,
      'device': build.device,
      'display': build.display,
      'fingerprint': build.fingerprint,
      'hardware': build.hardware,
      'host': build.host,
      'id': build.id,
      'manufacturer': build.manufacturer,
      'model': build.model,
      'product': build.product,
      'supported32BitAbis': build.supported32BitAbis,
      'supported64BitAbis': build.supported64BitAbis,
      'supportedAbis': build.supportedAbis,
      'tags': build.tags,
      'type': build.type,
      'isPhysicalDevice': build.isPhysicalDevice,
      'androidId': build.androidId,
      'systemFeatures': build.systemFeatures,
    };
  }

  Map<String, dynamic> _readIosDeviceInfo(IosDeviceInfo data) {
    return <String, dynamic>{
      'name': data.name,
      'systemName': data.systemName,
      'systemVersion': data.systemVersion,
      'model': data.model,
      'localizedModel': data.localizedModel,
      'identifierForVendor': data.identifierForVendor,
      'isPhysicalDevice': data.isPhysicalDevice,
      'utsname.sysname:': data.utsname.sysname,
      'utsname.nodename:': data.utsname.nodename,
      'utsname.release:': data.utsname.release,
      'utsname.version:': data.utsname.version,
      'utsname.machine:': data.utsname.machine,
    };
  }

  Future getPermissions() async {
    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return;
      }
    }
  }

  void reconsultDates() {
    _getDatesCovid(dtoQueriesCovid);
  }

  @override
  void initState() {
    super.initState();
    getPermissions();
    _dropdownItemsBranchOffice =
        buildDropdownMenuItemsBranchOffice(_branchOffices);
    _selectedBranchOffice = _dropdownItemsBranchOffice[0].value;
    _initPlatformStateDevice();
    _initPlatformState();
    this.dtoQueriesCovid.country = 1;
    this.dtoQueriesCovid.state = 1;
    _getDatesCovid(dtoQueriesCovid);
    controller.addListener(onScroll);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void onScroll() {
    setState(() {
      offset = (controller.hasClients) ? controller.offset : 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        controller: controller,
        child: Column(
          children: <Widget>[
            MyHeader(
              image: "assets/images/botimage-removebg-preview.png",
              textTop: "Bolivia Unida",
              textBottom: "#QuedateEnCasa",
              offset: offset,
            ),
            Container(
              margin: EdgeInsets.symmetric(horizontal: 20),
              padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              height: 60,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: Color(0xFFE5E5E5),
                ),
              ),
              child: Row(
                children: <Widget>[
                  SvgPicture.asset("assets/icons/maps-and-flags.svg"),
                  SizedBox(width: 20),
                  Expanded(
                    child: DropdownButton(
                        isExpanded: true,
                        underline: SizedBox(),
                        icon: SvgPicture.asset("assets/icons/dropdown.svg"),
                        value: _selectedBranchOffice,
                        items: _dropdownItemsBranchOffice,
                        onChanged: onChangeDropdownItemBranchOffice),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: "Seleccione Método de Verificación\n",
                              style: kTitleTextstyle,
                            ),
                            // TextSpan(
                            //   text: "Actualizado a 8 de mayo",
                            //   style: TextStyle(
                            //     color: kTextLightColor,
                            //   ),
                            // ),
                          ],
                        ),
                      ),
                      Spacer(),
                      // Text(
                      //   "Ver Detalles",
                      //   style: TextStyle(
                      //     color: kPrimaryColor,
                      //     fontWeight: FontWeight.w600,
                      //   ),
                      // ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          offset: Offset(0, 4),
                          blurRadius: 30,
                          color: kShadowColor,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Column(
                          children: <Widget>[
                            Container(
                              width: 55,
                              height: 55,
                              decoration: BoxDecoration(
                                color: Colors.black, //HexColor('014B8E'),
                                borderRadius: BorderRadius.all(
                                  Radius.circular(100.0),
                                ),
                                border: new Border.all(
                                    width: 4,
                                    color: Colors.black), //HexColor('014B8E')),
                              ),
                              child: InkWell(
                                onTap: () {
                                  getLocation();
                                  _scan();
                                },
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: <Widget>[
                                    Icon(
                                      FontAwesome.qrcode,
                                      color: Colors.white,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: 1),
                            Text(
                              "QR / CI",
                              style: TextStyle(
                                fontSize: 20,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          children: <Widget>[
                            Container(
                              width: 55,
                              height: 55,
                              decoration: BoxDecoration(
                                color: Colors.black, //HexColor('014B8E'),
                                borderRadius: BorderRadius.all(
                                  Radius.circular(100.0),
                                ),
                                border: new Border.all(
                                    width: 4,
                                    color: Colors.black), //HexColor('014B8E')),
                              ),
                              child: InkWell(
                                onTap: () {
                                  getLocation();
                                  _displayCi(context);
                                },
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: <Widget>[
                                    Icon(
                                      FontAwesome.user_circle_o,
                                      color: Colors.white,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: 1),
                            Text(
                              "Documento",
                              style: TextStyle(
                                fontSize: 20,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          children: <Widget>[
                            Container(
                              width: 55,
                              height: 55,
                              decoration: BoxDecoration(
                                color: Colors.black, //HexColor('014B8E'),
                                borderRadius: BorderRadius.all(
                                  Radius.circular(100.0),
                                ),
                                border: new Border.all(
                                    width: 4,
                                    color: Colors.black), //HexColor('014B8E')),
                              ),
                              child: InkWell(
                                onTap: () {
                                  _launchURL();
                                },
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: <Widget>[
                                    Icon(
                                      FontAwesome.whatsapp,
                                      color: Colors.white,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: 1),
                            Text(
                              "Test",
                              style: TextStyle(
                                fontSize: 20,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  Row(
                    children: <Widget>[
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: "Casos Registrados\n",
                              style: kTitleTextstyle,
                            ),
                            TextSpan(
                              text: _selectedBranchOffice.description,
                              style: TextStyle(
                                color: kTextLightColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Spacer(),
                      Text(
                        "Ver Detalles",
                        style: TextStyle(
                          color: kPrimaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          offset: Offset(0, 4),
                          blurRadius: 30,
                          color: kShadowColor,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Counter(
                          color: kInfectedColor,
                          number: resultState.totalInfecteds,
                          title: "Infectados",
                        ),
                        Counter(
                          color: kDeathColor,
                          number: resultState.totalWishes,
                          title: "Muertes",
                        ),
                        Counter(
                          color: kRecovercolor,
                          number: resultState.totalRecovered,
                          title: "Recuperados",
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  Row(
                    children: <Widget>[
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: "Casos Registrados\n",
                              style: kTitleTextstyle,
                            ),
                            TextSpan(
                              text: "Bolivia",
                              style: TextStyle(
                                color: kTextLightColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Spacer(),
                      Text(
                        "Ver Detalles",
                        style: TextStyle(
                          color: kPrimaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          offset: Offset(0, 4),
                          blurRadius: 30,
                          color: kShadowColor,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Counter(
                          color: kInfectedColor,
                          number: resultCountry.totalInfecteds,
                          title: "Infectados",
                        ),
                        Counter(
                          color: kDeathColor,
                          number: resultCountry.totalWishes,
                          title: "Muertes",
                        ),
                        Counter(
                          color: kRecovercolor,
                          number: resultCountry.totalRecovered,
                          title: "Recuperados",
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future _scan() async {
    String barcode = await scanner.scan();
    if (barcode.length > 15) {
      dtoQr.codigo = barcode;
      this._getQrDates(dtoQr);
    } else {
      cidto.ci = barcode;
      this._displayBarCode(context);
    }
  }

  _launchURL() async {
    const url =
        'https://api.whatsapp.com/send?phone=59172007455&text=Hola%2C%20quiero%20empezar%20un%20test%20r%C3%A1pido.';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  Future<dynamic> _getDatesCovid(GetDataCovidDto dto) async {
    QueriesService.apiPostGetdataCovid(dto).then((dynamic response) {
      setState(() {
        _isFetching = false;
        dynamic aux = response;
        Map<String, dynamic> aux2 = jsonDecode(aux);
        dynamic isOk = aux2["isOk"];
        if (isOk == true) {
          resultCountry =
              GetDataCovidResult.fromJson(aux2['body']['totalCasesCountry']);
          resultState =
              GetDataCovidResult.fromJson(aux2['body']['totalCasesState']);
        } else {
          resultCountry = new GetDataCovidResult();
          resultState = new GetDataCovidResult();
        }
      });
    });
  }

  Future<dynamic> _getQrDates(QrDto dto) async {
    QueriesService.getQrDates(dto).then((dynamic response) {
      setState(() {
        _isFetching = false;
        if (response.statusCode == 200) {
          this._displayQrModal(
              context, QrResponse.fromJson(jsonDecode(response.body)));
        } else {
          _displayErrorQrModal(context);
        }
      });
    });
  }

  Future<dynamic> getLocation() async {
    _locationData = await location.getLocation();
    setState(() {
      dtoQr.latitud = _locationData.latitude;
      dtoQr.longitud = _locationData.longitude;
      cidto.latitud = _locationData.latitude;
      cidto.longitud = _locationData.longitude;
    });
  }

  Future<dynamic> _getCiDates(String ci) async {
    cidto.ci = ci;
    QueriesService.getCIDates(cidto).then((dynamic response) {
      setState(() {
        _isFetching = false;
        if (response.statusCode == 200) {
          this._displayQrModal(
              context, QrResponse.fromJson(jsonDecode(response.body)));
        } else {
          _displayErrorQrModal(context);
        }
      });
    });
  }

  TextEditingController _textFieldbarController = new TextEditingController();

  _displayBarCode(BuildContext context) async {
    this._textFieldbarController.text = cidto.ci;
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Ingresar Datos',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.blue[900])),
            content: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.only(left: 0.0, right: 0.0, top: 0.0),
                child: Column(
                  children: <Widget>[
                    TextField(
                      controller: _textFieldbarController,
                      maxLength: 12,
                      decoration: InputDecoration(
                        icon: new Icon(
                          FontAwesome.user_circle_o,
                          color: Colors.blue[900],
                        ),
                        hintText: "Cedula de identidad",
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.blue[900]),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: <Widget>[
              new FlatButton(
                child: new Text('Cancelar',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.red)),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              new FlatButton(
                child: new Text('Aceptar',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.blue[900])),
                onPressed: () {
                  _getCiDates(_textFieldbarController.text);
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        });
  }

  _displayCi(BuildContext context) async {
    this._textFieldCiController = new TextEditingController();
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Ingresar Datos',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.blue[900])),
            content: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.only(left: 0.0, right: 0.0, top: 0.0),
                child: Column(
                  children: <Widget>[
                    TextField(
                      controller: _textFieldCiController,
                      maxLength: 12,
                      decoration: InputDecoration(
                        icon: new Icon(
                          FontAwesome.user_circle_o,
                          color: Colors.blue[900],
                        ),
                        hintText: "Cedula de identidad",
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.blue[900]),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: <Widget>[
              new FlatButton(
                child: new Text('Cancelar',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.red)),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              new FlatButton(
                child: new Text('Aceptar',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.blue[900])),
                onPressed: () {
                  _getCiDates(_textFieldCiController.text);
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        });
  }

  _displayErrorQrModal(BuildContext context) async {
    return showDialog(
        context: context,
        builder: (context) {
          return Dialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0)), //this right here
            child: Container(
              height: 200,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.cancel,
                      color: Color(0xFF1BC0C5),
                    ),
                    TextField(
                      decoration: InputDecoration(
                          border: InputBorder.none, hintText: 'Qr Inválido'),
                    ),
                    SizedBox(
                      width: 320.0,
                      child: RaisedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text(
                          "Aceptar",
                          style: TextStyle(color: Colors.white),
                        ),
                        color: const Color(0xFF1BC0C5),
                      ),
                    )
                  ],
                ),
              ),
            ),
          );
        });
  }

  _displayQrModal(BuildContext context, QrResponse result) async {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Resultados',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[900] /*HexColor('014B8E')*/)),
            content: Column(
              children: <Widget>[
                result.numeroCel != null
                    ? TextFormField(
                        enabled: false,
                        initialValue: result.numeroCel,
                        decoration: InputDecoration(
                            icon: new Icon(FontAwesome.phone),
                            hintStyle:
                                TextStyle(color: Colors.grey, fontSize: 10.0)),
                      )
                    : Container(),
                TextFormField(
                  enabled: false,
                  initialValue: result.ci,
                  decoration: InputDecoration(
                      icon: new Icon(FontAwesome.user),
                      hintStyle: TextStyle(color: Colors.grey, fontSize: 10.0)),
                ),
                TextFormField(
                  enabled: false,
                  maxLines: 3,
                  initialValue: result.descripcionAlerta,
                  decoration: InputDecoration(
                      icon: new Icon(FontAwesome.desktop),
                      hintStyle: TextStyle(color: Colors.grey, fontSize: 10.0)),
                ),
                TextFormField(
                  enabled: false,
                  initialValue: result.observaciones,
                  maxLines: 3,
                  decoration: InputDecoration(
                      icon: new Icon(FontAwesome.object_group),
                      hintStyle: TextStyle(color: Colors.grey, fontSize: 10.0)),
                ),
              ],
            ),
            actions: <Widget>[
              SizedBox(
                width: 320.0,
                child: RaisedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    "Aceptar",
                    style: TextStyle(color: Colors.white),
                  ),
                  color: const Color(0xFF1BC0C5),
                ),
              ),
            ],
          );
        });
  }

  Widget viewCharge() {
    return _isFetching
        ? Positioned.fill(
            child: Container(
            child: CupertinoActivityIndicator(
              radius: 15,
              animating: true,
            ),
          ))
        : Container();
  }
}

class BranchOffice {
  int code;
  String description;

  BranchOffice(this.code, this.description);

  static List<BranchOffice> getBranchOffices() {
    return <BranchOffice>[
      BranchOffice(1, 'LA PAZ'),
      BranchOffice(2, 'SANTA CRUZ'),
      BranchOffice(3, 'COCHABAMBA'),
      BranchOffice(4, 'CHUQUISACA'),
      BranchOffice(5, 'ORURO'),
      BranchOffice(6, 'POTOSI'),
      BranchOffice(7, 'BENI'),
      BranchOffice(8, 'PANDO'),
      BranchOffice(9, 'TARIJA'),
    ];
  }
}
