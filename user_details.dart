import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_google_places_hoc081098/flutter_google_places_hoc081098.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_api_headers/google_api_headers.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'Services/DatabaseService.dart';

class FittlPage extends StatefulWidget {
  const FittlPage({Key? key}) : super(key: key);


  @override
  _FittlPageState createState() => _FittlPageState();
}

class _FittlPageState extends State<FittlPage> {

  String _selectedGender = "male";
  firebase_storage.FirebaseStorage storage =
      firebase_storage.FirebaseStorage.instance;
  final _formKey = GlobalKey<FormState>();
  String? _firstName, _lastName, _location, _phoneNumber, _username;
  DateTime? _selectedDate;
  File? _imageFile;
  String Url = '';
  String googleApikey = "AIzaSyBQ2hIN6nTS5FKQzWAZcmX3jNF_ItGj2OA";
  GoogleMapController? mapController; //controller for Google map
  CameraPosition? cameraPosition;
  bool _isKeyboardVisible = false;

  LatLng currentLocation = const LatLng(43.589848583409015, -79.7040416309252);
  GeoPoint? gp;
  String location = "Search Location";
  Position? _currentPosition;
  List<Marker> markers = [];
  final textController = TextEditingController();


  //current user location
  Future<void> _currentLocation() async {
    final hasPermission = await _handleLocationPermission();
    if (!hasPermission) return;
    await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high)
        .then((Position position) async {
      setState(() => _currentPosition = position);
      final lat = _currentPosition?.latitude;
      final long = _currentPosition?.longitude;
      currentLocation = LatLng(lat!, long!);
      List<Placemark> placemarks = await placemarkFromCoordinates(
          lat, long);
      Placemark place = placemarks[0];
      setState(() {
        location = "${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.country}";
        textController.text = location;
        gp = GeoPoint(lat, long);
      });
      mapController?.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(target: currentLocation, zoom: 17)));

    }).catchError((e) {
      debugPrint(e);
    });
  }

  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Location services are disabled. Please enable the services')));
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
          content: Text('Location permissions are permanently denied, we cannot request permissions.')));
      return false;
    }
    return true;
  }

  Future<void> _selectDate(BuildContext context) async {
    setState(() {
      _isKeyboardVisible = false;
    });
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }


  void _createProfile() async{
    if (_formKey.currentState!.validate()) {
      showDialog(
        context: context,
        builder: (context) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      );
      _formKey.currentState!.save();

      if(_imageFile!=null){
        final fileName = '${DateTime.now().millisecondsSinceEpoch}';
        Reference ref = FirebaseStorage.instance.ref();
        Reference refDir = ref.child('images');
        Reference refImg = refDir.child(fileName);

        try{

          await refImg.putFile(_imageFile!);
          Url = await refImg.getDownloadURL();

        }catch(e){
          print(e);
        }

      }

      // final userProfile = UserProfile(
      //   userName: _username!,
      //   firstName: _firstName!,
      //   lastName: _lastName!,
      //   phoneNumber: _phoneNumber,
      //   dateOfBirth: _selectedDate!,
      //   location: gp!,
      //   profilePicture: Url,
      // );

      final user = FirebaseAuth.instance.currentUser!;
      await DatabaseService(uid: user.uid).updateUserProfile(_username!, _firstName!,_lastName!,gp!,_selectedDate!, Url, _selectedGender);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Profile Created"),
        ),
      );
      Navigator.of(context).pushNamed('/');
      //Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: GestureDetector(
        onTap: () {
          if (_isKeyboardVisible) {
            FocusScope.of(context).unfocus();
            setState(() {
              _isKeyboardVisible = false;
            });
          }
        },
        child: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/images/CreateUseBkgImg.png"),
              fit: BoxFit.cover,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.only(left: 20, right: 20, top: _isKeyboardVisible ? 0 : 40, bottom: 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20.0),
                if (!_isKeyboardVisible)
                  Center(
                      child: Image.asset("assets/images/FittlWhiteLogo.png",
                        height: 70,)
                  ),
                const SizedBox(height: 20.0),
                Container(
                  height: _isKeyboardVisible ? MediaQuery.of(context).size.height * 0.9 - MediaQuery.of(context).viewInsets.bottom : MediaQuery. of(context). size.height * 0.75,
                  // height:  MediaQuery. of(context). size.height * 0.75 - MediaQuery.of(context).viewInsets.bottom,
                  margin: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
                  padding: const EdgeInsets.only(top: 50, left: 30.0, right: 30),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(70.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        spreadRadius: 1.0,
                        blurRadius: 5.0,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!_isKeyboardVisible)
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Center(
                            child: Image.asset("assets/images/CreateYourProfile.png",
                                height: 32),
                          ),
                          const SizedBox(height: 5.0),
                          const Center(
                            child: Text(
                              'Ready. Set. Go!',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 14.0, color: Color(0xFF2FB9C5)),
                            ),
                          ),
                          const SizedBox(height: 20.0),
                        ],
                      ),
                      Flexible(
                        fit: FlexFit.loose,
                        child: SingleChildScrollView(
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 25.0,
                                      backgroundColor: const Color(0xFF5A75FF).withOpacity(0.7),
                                      backgroundImage: _imageFile != null
                                          ? FileImage(_imageFile!)
                                          : null,
                                      child: _imageFile == null
                                          ? const Icon(
                                        Icons.person,
                                        size: 25.0,
                                        color: Colors.white,
                                      )
                                          : null,
                                    ),
                                    const SizedBox(width: 16.0),
                                    Expanded(
                                      child: TextButton(
                                        onPressed: () {
                                          showModalBottomSheet(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return SafeArea(
                                                child: Column(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    ListTile(
                                                      leading: const Icon(Icons.camera_alt),
                                                      title: const Text('Take a picture'),
                                                      onTap: () {
                                                        _pickImage(ImageSource.camera);
                                                        Navigator.pop(context);
                                                      },
                                                    ),
                                                    ListTile(
                                                      leading: const Icon(Icons.image),
                                                      title:
                                                      const Text('Choose from gallery'),
                                                      onTap: () {
                                                        _pickImage(ImageSource.gallery);
                                                        Navigator.pop(context);
                                                      },
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          );
                                        },
                                        child: const Text(
                                          'Upload Profile Picture',
                                          style: TextStyle(
                                            color: Color(0xFF5A75FF),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 25.0),
                                InkWell(
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
                                    gp = GeoPoint(lat, long);
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
                                const SizedBox(height: 15.0),
                                SizedBox(
                                  width:  MediaQuery. of(context). size. width/3,
                                  child: TextFormField(
                                    cursorColor: const Color(0xFF5A75FF),
                                    decoration:  InputDecoration(
                                      contentPadding: const EdgeInsets.only(left: 15, right: 10, top: 10, bottom: 10),
                                      floatingLabelStyle:
                                      TextStyle(color: const Color(0xFF5A75FF).withOpacity(0.6)),
                                      labelStyle:
                                      TextStyle(color: const Color(0xFF5A75FF).withOpacity(0.6), fontSize: 13),
                                      focusedBorder: const OutlineInputBorder(
                                          borderSide: BorderSide(
                                              color: Color(0xFF5A75FF),
                                              width: 2
                                          ),
                                          borderRadius:
                                          BorderRadius.all(Radius.circular(15.0))
                                      ),
                                      border: const OutlineInputBorder(
                                        borderSide: BorderSide(
                                            color: Color(0xFF5A75FF), width: 2,
                                            style: BorderStyle.solid),
                                        borderRadius: BorderRadius.all(Radius.circular(15.0)),

                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                            color: const Color(0xFF5A75FF).withOpacity(0.3), width: 1.5,
                                            style: BorderStyle.solid),
                                        borderRadius: const BorderRadius.all(Radius.circular(15.0)),

                                      ),
                                      labelText: 'Username',
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Enter username';
                                      }
                                      return null;
                                    },
                                    onSaved: (value) {
                                      _username = value;
                                    },
                                    onTap: () {
                                      setState(() {
                                        _isKeyboardVisible = true;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(height: 16.0),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    SizedBox(
                                      width:  MediaQuery. of(context). size. width/3,
                                      child: TextFormField(
                                        cursorColor: const Color(0xFF5A75FF),
                                        decoration:  InputDecoration(
                                          contentPadding: const EdgeInsets.only(left: 15, right: 10, top: 10, bottom: 10),
                                          floatingLabelStyle:
                                          TextStyle(color: const Color(0xFF5A75FF).withOpacity(0.6)),
                                          labelStyle:
                                          TextStyle(color: const Color(0xFF5A75FF).withOpacity(0.6), fontSize: 13),
                                          focusedBorder: const OutlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: Color(0xFF5A75FF),
                                                  width: 2
                                              ),
                                              borderRadius:
                                              BorderRadius.all(Radius.circular(15.0))
                                          ),
                                          border: const OutlineInputBorder(
                                            borderSide: BorderSide(
                                                color: Color(0xFF5A75FF), width: 2,
                                                style: BorderStyle.solid),
                                            borderRadius: BorderRadius.all(Radius.circular(15.0)),

                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                                color: const Color(0xFF5A75FF).withOpacity(0.3), width: 1.5,
                                                style: BorderStyle.solid),
                                            borderRadius: const BorderRadius.all(Radius.circular(15.0)),

                                          ),
                                          labelText: 'First Name',
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Enter first name';
                                          }
                                          return null;
                                        },
                                        onSaved: (value) {
                                          _firstName = value;
                                        },
                                        onTap: () {
                                          setState(() {
                                            _isKeyboardVisible = true;
                                          });
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 1.0),
                                    SizedBox(
                                      width: MediaQuery. of(context). size. width/3,
                                      child: TextFormField(
                                        cursorColor: const Color(0xFF5A75FF),
                                        decoration:  InputDecoration(
                                          contentPadding: const EdgeInsets.only(left: 15, right: 10, top: 10, bottom: 10),
                                          floatingLabelStyle:
                                          TextStyle(color: const Color(0xFF5A75FF).withOpacity(0.6)),
                                          labelStyle:
                                          TextStyle(color: const Color(0xFF5A75FF).withOpacity(0.6), fontSize: 13),
                                          focusedBorder: const OutlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: Color(0xFF5A75FF),
                                                  width: 2
                                              ),
                                              borderRadius:
                                              BorderRadius.all(Radius.circular(15.0))
                                          ),
                                          border: const OutlineInputBorder(
                                            borderSide: BorderSide(
                                                color: Color(0xFF5A75FF), width: 2,
                                                style: BorderStyle.solid),
                                            borderRadius: BorderRadius.all(Radius.circular(15.0)),

                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                                color: const Color(0xFF5A75FF).withOpacity(0.3), width: 1.5,
                                                style: BorderStyle.solid),
                                            borderRadius: const BorderRadius.all(Radius.circular(15.0)),

                                          ),
                                          labelText: 'Last Name',
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Enter last name';
                                          }
                                          return null;
                                        },
                                        onSaved: (value) {
                                          _lastName = value;
                                        },
                                        onTap: () {
                                          setState(() {
                                            _isKeyboardVisible = true;
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16.0),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    SizedBox(
                                      width: MediaQuery. of(context). size. width/2.6,
                                      child: TextFormField(
                                        cursorColor: const Color(0xFF5A75FF),
                                        decoration: InputDecoration(
                                          contentPadding: const EdgeInsets.only(left: 15, right: 10, top: 10, bottom: 10),
                                          floatingLabelStyle:
                                          TextStyle(color: const Color(0xFF5A75FF).withOpacity(0.6)),
                                          labelStyle:
                                          TextStyle(color: const Color(0xFF5A75FF).withOpacity(0.6), fontSize: 13),
                                          focusedBorder: const OutlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: Color(0xFF5A75FF),
                                                  width: 2
                                              ),
                                              borderRadius:
                                              BorderRadius.all(Radius.circular(15.0))
                                          ),
                                          border: const OutlineInputBorder(
                                            borderSide: BorderSide(
                                                color: Color(0xFF5A75FF), width: 2,
                                                style: BorderStyle.solid),
                                            borderRadius: BorderRadius.all(Radius.circular(15.0)),

                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                                color: const Color(0xFF5A75FF).withOpacity(0.3), width: 1.5,
                                                style: BorderStyle.solid),
                                            borderRadius: const BorderRadius.all(Radius.circular(15.0)),

                                          ),
                                          labelText: 'Birth date',
                                          suffixIcon: Icon(Icons.calendar_today, color: const Color(0xFF5A75FF).withOpacity(0.6)),
                                        ),
                                        readOnly: true,
                                        onTap: () => _selectDate(context),
                                        validator: (value) {
                                          if (_selectedDate == null) {
                                            return 'Please select your date of birth';
                                          }
                                          return null;
                                        },
                                        controller: TextEditingController(
                                          text: _selectedDate != null
                                              ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                                              : '',
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 1.0),
                                    SizedBox(
                                      width: MediaQuery. of(context). size. width/3.5,
                                      child: DropdownButtonFormField<String>(
                                        decoration: InputDecoration(
                                          contentPadding: const EdgeInsets.only(left: 15, right: 10, top: 10, bottom: 10),
                                          floatingLabelStyle:
                                          TextStyle(color: const Color(0xFF5A75FF).withOpacity(0.6)),
                                          labelStyle:
                                          TextStyle(color: const Color(0xFF5A75FF).withOpacity(0.6), fontSize: 13),
                                          focusedBorder: const OutlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: Color(0xFF5A75FF),
                                                  width: 2
                                              ),
                                              borderRadius:
                                              BorderRadius.all(Radius.circular(15.0))
                                          ),
                                          border: const OutlineInputBorder(
                                            borderSide: BorderSide(
                                                color: Color(0xFF5A75FF), width: 2,
                                                style: BorderStyle.solid),
                                            borderRadius: BorderRadius.all(Radius.circular(15.0)),

                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                                color: const Color(0xFF5A75FF).withOpacity(0.3), width: 1.5,
                                                style: BorderStyle.solid),
                                            borderRadius: const BorderRadius.all(Radius.circular(15.0)),

                                          ),
                                          labelText: 'Gender',
                                        ),
                                        value: _selectedGender,
                                        items: const [
                                          DropdownMenuItem<String>(
                                            value: 'male',
                                            child: Text('Male'),
                                          ),
                                          DropdownMenuItem<String>(
                                            value: 'female',
                                            child: Text('Female'),
                                          ),
                                        ],
                                        onTap: () {
                                          setState(() {
                                            _isKeyboardVisible = false;
                                          });
                                        },
                                        onChanged: (value) {
                                          setState(() {
                                            _selectedGender = value!;
                                          });
                                        },
                                        validator: (value) {
                                          if (value == null) {
                                            return 'Please select a gender';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16.0),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32.0),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            backgroundColor: const Color(0xFF5A75FF),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                          ),
                          onPressed: _createProfile,
                          child: const Text('Create Profile'),
                        ),
                      ),
                      const SizedBox(height: 32.0),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
