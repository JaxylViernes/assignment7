import 'package:assignment7/placemanage.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static final initialPosition =
      const LatLng(16.12897404340456, 120.55960256109897);

  late GoogleMapController? mapController;
  Set<Marker> markers = {};

  FirebaseFirestore firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    fetchFavoritePlaces();
  }

  Future<void> fetchFavoritePlaces() async {
    try {
      QuerySnapshot favoritePlaces =
          await firestore.collection('favoritePlaces').get();
      setState(() {
        markers = favoritePlaces.docs.map((doc) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          return Marker(
            markerId: MarkerId(doc.id),
            position: LatLng(data['latitude'], data['longitude']),
            infoWindow:
                InfoWindow(title: data['name'], snippet: data['description']),
          );
        }).toSet();
      });
    } catch (e) {
      print('Error fetching favorite places: $e');
    }
  }

  Future<void> addFavoritePlace(
      LatLng position, String name, String description) async {
    try {
      Marker newMarker = Marker(
        markerId: MarkerId(position.toString()),
        position: position,
        infoWindow: InfoWindow(title: name, snippet: description),
      );

      setState(() {
        markers.add(newMarker);
      });

      await firestore.collection('favoritePlaces').add({
        'latitude': position.latitude,
        'longitude': position.longitude,
        'name': name,
        'description': description,
      });
    } catch (e) {
      print('Error adding favorite place: $e');
    }
  }

  void deleteFavoritePlace(String markerId) async {
    try {
      setState(() {
        markers.removeWhere((marker) => marker.markerId.value == markerId);
      });

      await firestore.collection('favoritePlaces').doc(markerId).delete();
    } catch (e) {
      print('Error deleting favorite place: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: GoogleMap(
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          mapType: MapType.normal,
          onMapCreated: (controller) {
            mapController = controller;
          },
          markers: markers,
          initialCameraPosition: CameraPosition(
            target: initialPosition,
            zoom: 12,
          ),
          onTap: (LatLng position) {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                TextEditingController nameController = TextEditingController();
                TextEditingController descriptionController =
                    TextEditingController();

                return AlertDialog(
                  title: Text('Add Favorite Place'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(labelText: 'Name'),
                      ),
                      TextField(
                        controller: descriptionController,
                        decoration: InputDecoration(labelText: 'Description'),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        String name = nameController.text;
                        String description = descriptionController.text;
                        addFavoritePlace(position, name, description);
                        Navigator.pop(context);
                      },
                      child: Text('Add'),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: markers.isEmpty
          ? FloatingActionButton.extended(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('No pinned locations yet!'),
                    duration: Duration(seconds: 3),
                  ),
                );
              },
              icon: Icon(Icons.add_location),
              label: Text('Add Favorite Place'),
            )
          : FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ManagePlacesScreen()),
                );
              },
              child: Icon(Icons.list),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MaterialApp(home: HomeScreen()));
}
