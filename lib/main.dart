import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: "AIzaSyDaebEE00Qx5KnK83_GLeh5Dbg7S_4Dyec",
        appId: "1:774296923413:web:1bedb7909c24c1158e8d1c",
        messagingSenderId: "774296923413",
        projectId: "first-7333",
      ),
    );
  }
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  LatLng myLocation = LatLng(0, 0); // Default location
  List<LatLng> specifiedLocations = [];
  MapController mapController = MapController();

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _updateLocation(position.latitude, position.longitude);
    } catch (e) {
      print("Error getting location: $e");
    }
  }

  void _updateLocation(double latitude, double longitude) {
    setState(() {
      myLocation = LatLng(latitude, longitude);
    });
    mapController.move(myLocation, 15.0);
  }

  Future<void> _saveLocationToFirestore(double latitude, double longitude) async {
    try {
      await FirebaseFirestore.instance.collection('locations').add({
        'latitude': latitude,
        'longitude': longitude,
        'timestamp': FieldValue.serverTimestamp(),
      });
      print('Location saved to Firestore.');
    } catch (e) {
      print('Error saving location to Firestore: $e');
    }
  }

  Future<void> _displayLocationsFromFirestore() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('locations').get();
      List<QueryDocumentSnapshot> documents = querySnapshot.docs;

      List<LatLng> locations = documents.map((doc) {
        double latitude = doc['latitude'];
        double longitude = doc['longitude'];
        return LatLng(latitude, longitude);
      }).toList();

      setState(() {
        specifiedLocations.clear();
        specifiedLocations.addAll(locations);
      });
    } catch (e) {
      print('Error fetching locations from Firestore: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Flutter Map Example'),
        ),
        body: Stack(
          children: [
            FlutterMap(
              mapController: mapController,
              options: MapOptions(
                center: myLocation,
                zoom: 1.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.app',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      width: 40.0,
                      height: 40.0,
                      point: myLocation,
                      builder: (ctx) => Container(
                        child: Icon(
                          Icons.location_on,
                          color: Colors.red,
                          size: 40.0,
                        ),
                      ),
                    ),
                    for (LatLng location in specifiedLocations)
                      Marker(
                        width: 40.0,
                        height: 40.0,
                        point: location,
                        builder: (ctx) => Container(
                          child: Icon(
                            Icons.location_on,
                            color: Colors.blue,
                            size: 40.0,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            Positioned(
              top: 16.0,
              left: 16.0,
              child: Container(
                padding: EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Text(
                  'My Location: ${myLocation.latitude}, ${myLocation.longitude}',
                  style: TextStyle(fontSize: 16.0),
                ),
              ),
            ),
            RichAttributionWidget(
              attributions: [
                TextSourceAttribution(
                  'OpenStreetMap contributors',
                  onTap: () => launch('https://openstreetmap.org/copyright'),
                ),
              ],
            ),
          ],
        ),
        floatingActionButton: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            FloatingActionButton(
              onPressed: () async {
                await _displayLocationsFromFirestore();
              },
              child: Icon(Icons.location_on, color: Colors.green),
            ),
          ],
        ),
      ),
    );
  }
}
