import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  SharedPreferences? preferences;
  Timer? timer;

  void initState(){
    // timer = Timer.periodic(Duration(seconds: 5), (Timer t) => _checkRadius(5.543633011017073, 95.3121756820617));
  }

  Completer<GoogleMapController> _controller = Completer();
// on below line we have specified camera position
  static final CameraPosition _kGoogle = const CameraPosition(
    target: LatLng(5.543577914626673, 95.31220741678517),
    zoom: 17.4746,
  );

  final List<Marker> _markers = <Marker>[
    Marker(
        markerId: MarkerId('1'),
        position: LatLng(20.42796133580664, 75.885749655962),
        infoWindow: InfoWindow(  
          title: 'My Position',
        )
    ),
  ];

  Future<Position> getUserCurrentLocation() async {

    await Geolocator.requestPermission().then((value){
    }).onError((error, stackTrace) async {
    await Geolocator.requestPermission();
    print("ERROR"+error.toString());
    });
    
    return await Geolocator.getCurrentPosition();
  }

  late GoogleMapController mapController;
  GeolocatorPlatform _geo = new PresenceGeo( );
  bool _inRadius = true;
  final LatLng _center = const LatLng(5.543633011017073, 95.3121756820617);
  Map<MarkerId, Marker> markers = <MarkerId, Marker>{};

  void _checkRadius() async {

    getUserCurrentLocation().then((value) async {
      final double distance = _geo.distanceBetween(
        5.543633011017073, 95.3121756820617,
        value.latitude,
        value.longitude,
      );

      print(distance);

      setState(() {
        this._inRadius = distance < 50;
      });

      _absen(value.latitude, value.longitude);
    });

    print(this._inRadius);

  }

  Future<void> _onMapCreated(GoogleMapController controller) async {
    setState(() {
        final marker = Marker(
          markerId: MarkerId("123"),
          position: LatLng(5.543577914626673, 95.31220741678517),
          infoWindow: InfoWindow(
            title: "Pusdiklat PT. Bank Aceh",
            snippet: "G8V6+CVF, Jl. Patimura, Sukaramai, Kec. Baiturrahman, Kota Banda Aceh, Aceh 23116",
          ),
        );
        // _markers = marker;
        markers[MarkerId('place_name')] = marker;
      // }
    });
  }

  Set<Circle> circles = Set.from([Circle(
    circleId: CircleId("2343"),
    center: LatLng(5.543577914626673, 95.31220741678517),
    radius: 50,
    fillColor: Colors.orange.shade100.withOpacity(0.5),
    strokeColor:  Colors.orange.shade100.withOpacity(0.1)
  )]);

  final ButtonStyle raisedButtonStyle = ElevatedButton.styleFrom(
    onPrimary: Colors.white,
    primary: Colors.blueAccent[300],
    minimumSize: Size(10, 36),

    padding: EdgeInsets.symmetric(horizontal: 10),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(2)),
    ),
  );

  Future<String> _absen(double lat, double long) async {

    final prefs = await SharedPreferences.getInstance();
    final branch_id = prefs.getString("kode_kantor").toString();
    final nrk = prefs.getString("npp");
    final nrk2 = jsonDecode(nrk!);
    String nrk3 = nrk2.toString();

    print(this._inRadius);

    DateTime dtNow = DateTime.now();
    DateTime dtAbsen = DateTime.parse("2023-01-09 06:45:00");
    DateTime dtAbsenPulang = DateTime.parse("2023-01-11 04:00:00");

    if(this._inRadius) {

      // getUserCurrentLocation().then((value) async {

        final getResult = await http.post(
            Uri.parse("http://192.168.100.16/mobile-auth-api/public/api/simpanabsen"),
            headers: <String, String> {
              'Content-Type': 'application/json; charset=UTF-8',
            },
            body: jsonEncode(<String, String>{
              'npp': nrk3,
              // 'latitude' : value.latitude.toString(),
              'latitude' : lat.toString(),
              'longitude' : long.toString(),
              'device_info': '00:1b:63:84:45:e6',
              'branch_id': branch_id
            })
        );

        // print(value.latitude.toString() + " " + value.longitude.toString());

        String result = getResult.body.toString().replaceAll('""',"");

        print(result);

        if(jsonDecode(result)['rcode'] == "00") {

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                jsonDecode(result)['message'],
                style: const TextStyle(fontSize: 16),
              ),
              backgroundColor: Colors.greenAccent,
            ),
          );

        }else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                jsonDecode(result)['message'],
                style: const TextStyle(fontSize: 16),
              ),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      // });

    }else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            " Ditolak, Anda berada di luar area absensi",
            style: const TextStyle(fontSize: 16),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    }

    return "nrk";
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Absensi'),
          backgroundColor: Colors.green[700],
        ),
        body:
        Stack(
          children: [
            Container (
              child: SafeArea(
                // on below line creating google maps
                child: GoogleMap(
                  // on below line setting camera position
                  initialCameraPosition: _kGoogle,
                  // on below line we are setting markers on the map
                  markers: Set<Marker>.of(_markers),
                  circles: circles,
                  // on below line specifying map type.
                  mapType: MapType.normal,
                  // on below line setting user location enabled.
                  myLocationEnabled: true,
                  // on below line setting compass enabled.
                  compassEnabled: true,
                  // on below line specifying controller on map complete.
                  onMapCreated: (GoogleMapController controller){
                    _controller.complete(controller);
                  },
                ),
              ),
            ),

            // Container(
            //   height: 320,
            //   child:  GoogleMap(
            //     mapType: MapType.normal,
            //     myLocationEnabled: true,
            //     myLocationButtonEnabled: true,
            //     onMapCreated: _onMapCreated,
            //     initialCameraPosition: CameraPosition(
            //       target: _center,
            //       zoom: 17,
            //     ),
            //     markers: markers.values.toSet(),
            //     circles: circles,
            //   ),
            // ),

            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                  margin: const EdgeInsets.only(left: 0.0, right: 0.0),
                  height: 240,
                  child: Card(
                    margin: EdgeInsets.zero,
                    color: Colors.orangeAccent[600],
                    elevation: 20,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(topLeft:Radius.circular(50),topRight: Radius.circular(50))
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: Padding(
                      padding: EdgeInsets.all(0.0),
                      child:
                      // InkWell(
                      //   splashColor: Colors.blue.withAlpha(30),
                      //   onTap: () {
                      //     debugPrint('Card tapped.');
                      //   },
                      //   child:
                        SizedBox(
                          height: 100,
                          width: double.infinity,
                          child: 
                          Padding(
                            padding: EdgeInsets.all(20),
                            child:  Column(
                              children: [
                                Text(
                                  'Silahkan Melakukan Absensi',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                SizedBox(
                                  width: 10,
                                  height: 15,
                                ),
                                Text(
                                  DateFormat('kk:mm:ss \n EEE d MMM').format(DateTime.now()), textAlign: TextAlign.center,
                                ),
                                SizedBox(
                                  width: 10,
                                  height: 30,
                                ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      ElevatedButton(
                                          onPressed: () {
                                            _checkRadius();
                                            // _absen();
                                          } ,
                                          child: Text("Absen"),
                                          style:
                                          // raisedButtonStyle
                                          ElevatedButton.styleFrom(
                                            onPrimary: Colors.white,
                                            primary: Colors.blueAccent,
                                            minimumSize: Size(120, 40),
                                          ),
                                      ),
                                      // SizedBox(
                                      //   width: 20,
                                      // ),
                                      // ElevatedButton(
                                      //     onPressed: (){},
                                      //     child: Text("Pulang"),
                                      //
                                      //     style: ElevatedButton.styleFrom(
                                      //         onPrimary: Colors.white,
                                      //         primary: Colors.orangeAccent[400],
                                      //         minimumSize: Size(100, 40),
                                      //     ),
                                      // )
                                    ],
                                  ),
                              ],
                            )
                          ),
                        ),
                    )
                  )
              ),
            )
          ],
        ),
          floatingActionButton: FloatingActionButton(
          onPressed: () async{
    getUserCurrentLocation().then((value) async {
    print(value.latitude.toString() +" "+value.longitude.toString());

    // marker added for current users location
    _markers.add(
    Marker(
    markerId: MarkerId("2"),
    position: LatLng(value.latitude, value.longitude),
    infoWindow: InfoWindow(
    title: 'My Current Location',
    ),
    )
    );

    // specified current users location
    CameraPosition cameraPosition = new CameraPosition(
    target: LatLng(value.latitude, value.longitude),
    zoom: 14,
    );

    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(cameraPosition));
    setState(() {
    });
    });
    },
      child: Icon(Icons.my_location),
    ),
      ),
    );
  }
}

class PresenceGeo extends GeolocatorPlatform {}
