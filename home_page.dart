import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fittl/Modals/UserProfile.dart';
import 'package:fittl/Services/NotificationService.dart';
import 'package:fittl/pages/view_event_details.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_api_headers/google_api_headers.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_google_places_hoc081098/flutter_google_places_hoc081098.dart';
import 'package:intl/intl.dart';

import 'Modals/EventInfo.dart';
import 'Services/DatabaseService.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fittl',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home:  const Home(title: 'Home Page'),
    );
  }
}

class Home extends StatefulWidget {
  const Home({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {

  // void updateMapWithEventLocation(GeoPoint eventLocation) {
  //   _eventLocation(eventLocation, );
  // }
  Future<List<EventInfo>> fetchData(String docID) async {
    final user = FirebaseAuth.instance.currentUser!;

    List<EventInfo> list = await DatabaseService(uid: user.uid).getEvent(true);
    return list;
  }
  String googleApikey = "AIzaSyBQ2hIN6nTS5FKQzWAZcmX3jNF_ItGj2OA";
  GoogleMapController? mapController; //controller for Google map
  CameraPosition? cameraPosition;
  LatLng currentLocation = const LatLng(43.589848583409015, -79.7040416309252);
  String location = "Search Location";
  Position? _currentPosition;
  List<Marker> markers = [];
  Marker? currentMarker;
  final List<bool> _isSelected = [true, false];
  bool distanceSort = true;

  Future<LatLng> fetchCurrentLocationFromDatabase()async{
    final user = FirebaseAuth.instance.currentUser!;
    UserProfile userProfile = await DatabaseService(uid: user.uid).getUserProfile(user.uid);

    return LatLng(userProfile.location.latitude,userProfile.location.longitude);
  }


  //current user location
  Future<void> _currentLocation() async {
    final hasPermission = await _handleLocationPermission();
    if (!hasPermission) return;
    await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high)
        .then((Position position) async {
      setState(() => _currentPosition = position);
      final lat = _currentPosition?.latitude;
      final long = _currentPosition?.longitude;
      currentLocation = LatLng(lat!, long!);
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, long);
      Placemark place = placemarks[0];
      location =
      "${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.country}";
      setState(() {
        //refresh UI
      });
      mapController?.animateCamera(CameraUpdate.newCameraPosition(
          CameraPosition(target: currentLocation, zoom: 17)));
    }).catchError((e) {
      debugPrint(e);
    });
  }

  Future<void> _eventLocation(GeoPoint location, String id) async {
    final lat = location.latitude;
    final long = location.longitude;
    LatLng newLatLng = LatLng(lat, long);

    // Add a new marker at the new coordinates without clearing existing markers
    Marker newMarker = Marker(
      markerId: MarkerId(id),
      position: newLatLng,
      infoWindow: const InfoWindow(title: "Event Marker"),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
    );

    setState(() {
      markers.add(newMarker);
    });

    // Move the camera to the new coordinates with animation
    mapController?.animateCamera(CameraUpdate.newLatLngZoom(newLatLng, 17));
  }




  //check if location services are enabled
  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Location services are disabled. Please enable the services')));
      return false;
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are denied')));
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Location permissions are permanently denied, we cannot request permissions.')));
      return false;
    }
    return true;
  }

  final _textController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body:
      Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Container(

              child: InkWell(
                  onTap: () async {
                    var place = await PlacesAutocomplete.show(
                        context: context,
                        //Self Reminder: It is using my second accounts API key (vansh24tyagi24)
                        apiKey: googleApikey,
                        mode: Mode.overlay,
                        types: [],
                        strictbounds: false,
                        components: [Component(Component.country, 'ca')],
                        onError: (err) {
                          print(err);
                        });

                    if (place != null) {
                      setState(() {
                        //again update UI
                        location = place.description.toString();
                      });

                      //form google_maps_webservice package
                      final plist = GoogleMapsPlaces(
                        apiKey: googleApikey,
                        apiHeaders: await const GoogleApiHeaders().getHeaders(),
                        //from google_api_headers package
                      );
                      String placeid = place.placeId ?? "0";
                      final detail = await plist.getDetailsByPlaceId(placeid);
                      final geometry = detail.result.geometry!;
                      final lat = geometry.location.lat;
                      final long = geometry.location.lng;
                      var newlatlong = LatLng(lat, long);
                      currentLocation = newlatlong;
                      currentMarker = Marker(
                        markerId: const MarkerId("current"),
                        position: newlatlong,
                        infoWindow: const InfoWindow(title: "Current Marker"),
                        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                      );

                      setState(() {
                        markers.add(currentMarker!);
                      });
                      setState(() {
                        //refresh UI
                      });

                      //move map camera to selected place with animation and zoom in
                      mapController?.animateCamera(
                          CameraUpdate.newCameraPosition(
                              CameraPosition(target: newlatlong, zoom: 17)));
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(3),
                    child: Card(
                      child: Container(
                          padding: const EdgeInsets.all(0),
                          width: MediaQuery.of(context).size.width - 40,
                          child: ListTile(
                            title: Text(
                              location,
                              style: const TextStyle(fontSize: 18),
                            ),
                            trailing: const Icon(Icons.search),
                            dense: true,
                          )),
                    ),
                  )
              ),

            ),

            FutureBuilder<LatLng>(
              future: fetchCurrentLocationFromDatabase(), // replace with your database call function
              builder: (context, snapshot) {
                // if (snapshot.connectionState == ConnectionState.waiting) {
                //   return CircularProgressIndicator(); // Show loading indicator while fetching data
                // } else
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}'); // Show error if data fetch fails
                } else if (snapshot.hasData) {
                  currentLocation = snapshot.data!; // Set current location from database data
                  currentMarker = Marker(
                    markerId: const MarkerId("home"),
                    position: snapshot.data!,
                    infoWindow: const InfoWindow(title: "Home Marker"),
                    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                  );
                  markers.add(currentMarker!);
                  return Container(
                    height: 230,
                    margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(20.0)),
                    child: GoogleMap(
                      myLocationButtonEnabled: true,
                      zoomControlsEnabled: true,
                      zoomGesturesEnabled: true,
                      initialCameraPosition: CameraPosition(
                        target: currentLocation,
                        zoom: 15.0,
                      ),
                      markers: Set<Marker>.from(markers),
                      mapType: MapType.normal,
                      onMapCreated: (controller) {
                        setState(() {
                          mapController = controller;
                        });
                      },
                    ),
                  );
                } else {
                  return const Text('No data available'); // Show message if there is no data
                }
              },
            ),
            Container(
              margin: const EdgeInsets.only(left: 16, right: 20, bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text("Sort By:"),
                  const SizedBox(width: 10,),
                  ToggleButtons(
                    isSelected: _isSelected,
                    onPressed: (int index) {
                      setState(() {
                        for (int buttonIndex = 0; buttonIndex < _isSelected.length; buttonIndex++) {
                          if (buttonIndex == index) {
                            _isSelected[buttonIndex] = true;
                          } else {
                            _isSelected[buttonIndex] = false;
                          }
                        }
                        // Perform sorting logic based on index (0 for 'Distance', 1 for 'Time')
                        if (index == 0) {
                          distanceSort = true;
                        } else {
                          distanceSort = false;
                        }
                      });
                    },
                      constraints: const BoxConstraints.tightFor(height: 30),
                      borderRadius: BorderRadius.circular(20),
                    fillColor: Color(0xFF5A75FF).withOpacity(0.9),
                      children: const <Widget>[
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 3, horizontal: 10), // Adjust vertical padding here
                          child: Text('Distance'),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 3, horizontal: 20), // Adjust vertical padding here
                          child: Text('Time'),
                        ),
                      ],
                      selectedColor: Colors.white,
                    color: Color(0xFF5A75FF),
                  ),
                ],
              ),
            ),


             MyListPage(this, distanceSort),
          ],
        ),
      ),
    );
  }
}



class MyListPage extends StatefulWidget {
  final _HomeState homeState;
  final bool distanceSort;
  const MyListPage(this.homeState, this.distanceSort, {Key? key}) : super(key: key);

  @override
  State<MyListPage> createState() => _MyListPageState();
}

class _MyListPageState extends State<MyListPage> {

  final NotificationService _notificationService = NotificationService();
  Future<List<EventInfo>> fetchData() async {
    final user = FirebaseAuth.instance.currentUser!;

    List<EventInfo> list = await DatabaseService(uid: user.uid).getEvent(widget.distanceSort);
    log('list: $list');
    return list;
  }

  void _join({required String activityId}) async{

    _notificationService.sendJoinRequest(activityId);
    // await DatabaseService(uid: user.uid)
    //     .createRequest(user.uid, activityId, false);
  }


  void _showJoinSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.celebration, // Replace with an appropriate celebration icon
                color: Colors.green,
                size: 28.0, // Adjust the size as needed
              ),
              SizedBox(width: 10.0), // Add spacing between the icon and text
              Text(
                'Hooray!',
                style: TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Your request to join the event has been sent successfully!',
                style: TextStyle(
                  fontSize: 16.0,
                  color: Colors.blueAccent,
                ),
              ),
            ],
          ),
          actions: <Widget>[
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                elevation: 2,
              ),
              child: const Text(
                'OK',
                style: TextStyle(
                  fontSize: 16.0,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
  void _showJoinSuccessDialog2(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.sentiment_very_satisfied, // Replace with an appropriate celebration icon
                color: Colors.purpleAccent,
                size: 28.0, // Adjust the size as needed
              ),
              SizedBox(width: 10.0), // Add spacing between the icon and text
              Text(
                'Dont Worry!',
                style: TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.purpleAccent,
                ),
              ),
            ],
          ),
          content:Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Not interested in this one, we have got more for you',
                style: TextStyle(
                  fontSize: 16.0,
                  color: Colors.blueAccent,
                ),
              ),
            ],
          ),
          actions: <Widget>[
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purpleAccent,
                elevation: 2,
              ),
              child: const Text(
                'OK',
                style: TextStyle(
                  fontSize: 16.0,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  final bool _isButtonClicked = false;
  @override
  Widget build(BuildContext context) {
    return
      Expanded(
        child: FutureBuilder<List<EventInfo>>(
            future: fetchData(), // define your future method here
            builder: (BuildContext context, AsyncSnapshot snapshot) {
              // assuming your data is stored in snapshot.data
              // List<EventInfo> eventData = [];
              List<EventInfo> eventData=<EventInfo>[];
              // if(snapshot.connectionState == ConnectionState.waiting){
              //   return Center(
              //     child: Image.asset(
              //       'assets/loading.gif',
              //       height: 150,
              //       width: 200,
              //     ),
              //   );
              // }
              if(snapshot.hasData){
                eventData = snapshot.data;
              }


              return ListView.builder(
                itemCount: eventData.length,
                itemBuilder: (BuildContext context, int index) {
                  return GestureDetector(
                    onTap: () {
                      // Navigate to the event details page and pass the event information
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              viewEventDetailsPage(eventInfo: eventData[index]),
                        ),
                      );
                    },


                  child: Dismissible(
                    key: Key(eventData[index].eventId), // Unique key for each event
                    direction: DismissDirection.horizontal,
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: const Icon(
                        Icons.delete,
                        color: Colors.white,
                      ),
                    ),
                    secondaryBackground: Container(
                      color: Colors.green,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                      ),
                    ),
                    onDismissed: (direction) {
                      if (direction == DismissDirection.startToEnd) {
                        // Swipe left (remove)
                        //  eventData.removeAt(index);
                        _showJoinSuccessDialog2(context);

                        // Show success dialog
                      } else if (direction == DismissDirection.endToStart) {
                        // Swipe Right (join)
                        _showJoinSuccessDialog(context);
                        _join(activityId: eventData[index].eventId);
                      }

                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 5.0),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8.0, vertical: 3.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.3),
                            spreadRadius: 1.0,
                            blurRadius: 5.0,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            margin: const EdgeInsets.only(
                                top: 8.0, bottom: 8.0, left: 8.0, right: 10.0),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF5A75FF).withOpacity(0.2),
                              image: DecorationImage(
                                image: NetworkImage(eventData[index].url),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 8.0),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment: MainAxisAlignment
                                      .spaceBetween,
                                  children: [
                                    Text(
                                      eventData[index].userFirstName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15.0,
                                      ),
                                    ),
                                    Text(
                                      '@${eventData[index].username}',
                                      style: const TextStyle(
                                        fontSize: 13.0,
                                      ),
                                    ),
                                    Text(
                                      "${eventData[index].date_time.hour}:${eventData[index].date_time.minute}",
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12.0,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4.0),

                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment
                                  .spaceBetween,
                              children: [
                                Text(
                                  eventData[index].sport,
                                  style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12.0,
                                      fontWeight: FontWeight.bold
                                  ),
                                ),

                                Text(
                                  '${eventData[index].players} spot(s) available',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12.0,
                                  ),
                                ),
                              ],
                            ),

                                const SizedBox(height: 4.0),
                                Text(
                                  DateFormat('dd MMM yyyy h:mm a').format(eventData[index].date_time),
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12.0,
                                  ),
                                ),
                                const SizedBox(height: 8.0),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                                right: 12.0, left: 20.0),
                            child: ElevatedButton(

                              onPressed: ()=> {
                                widget.homeState._eventLocation(eventData[index].location,eventData[index].eventId )
                              },


                              style: ElevatedButton.styleFrom(
                                backgroundColor: !_isButtonClicked ? const Color(0xFF5A75FF):const Color(0xFFFFFFFF),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                              ),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(vertical: 4.0),
                                child: Icon(
                                  Icons.location_pin, // Use the location pin icon
                                  color: Colors.white,
                                  size: 20.0, // Set the icon size to your preference
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  );
                },

              );
            }

        )
    );
  }
}


