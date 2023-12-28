import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fittl/pages/view_hosted_events.dart';
import 'package:fittl/pages/view_my_activities.dart';
import 'package:flutter/material.dart';
import 'package:flutter_google_places_hoc081098/flutter_google_places_hoc081098.dart';
import 'package:google_api_headers/google_api_headers.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:number_inc_dec/number_inc_dec.dart';

import 'Services/DatabaseService.dart';

class Host extends StatefulWidget {
  const Host({super.key});

  @override
  _HostState createState() => _HostState();
}

class _HostState extends State<Host> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController sportsController = TextEditingController();

  String? _location;
  DateTime? _dateTime;
  int _numPlayers = 1;
  double? _duration;
  String? _selectedSport;
  List<String> _filteredSportsList = [];
  String googleApikey = "AIzaSyBQ2hIN6nTS5FKQzWAZcmX3jNF_ItGj2OA";
  GoogleMapController? mapController; //controller for Google map
  CameraPosition? cameraPosition;
  LatLng currentLocation = const LatLng(43.589848583409015, -79.7040416309252);
  String location = "Search Location";
  bool locFlag = false;
  GeoPoint? gp;
  final List<String> _sportsList = [
    'Basketball',
    'Football',
    'Baseball',
    'Tennis',
    'Swimming',
    'Volleyball',
  ];

  @override
  void initState() {
    _filteredSportsList = _sportsList;
    super.initState();
  }

  void _filterSportsList(String searchText) {
    setState(() {
      _filteredSportsList = _sportsList
          .where(
              (sport) => sport.toLowerCase().contains(searchText.toLowerCase()))
          .toList();
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(
          DateTime.now().year + 1, DateTime.now().month, DateTime.now().day),
    );
    if (picked != null && picked != _dateTime) {
      setState(() {
        _dateTime = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _dateTime = DateTime(
          _dateTime!.year,
          _dateTime!.month,
          _dateTime!.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  Future _host() async {
    if (locFlag == false) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Select a location"),
        ),
      );
      return;
    }
    if (_formKey.currentState!.validate()) {
      // Form is validated
      // Do something with the form data
      _formKey.currentState!.save();
      showDialog(
        context: context,
        builder: (context) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      );
      final user = FirebaseAuth.instance.currentUser!;

      await DatabaseService(uid: user.uid)
          .addEvent(_selectedSport!, gp!, _dateTime!, _numPlayers, _duration!);

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Event Created"),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<DropdownMenuEntry<String>> sportsEntries =
        <DropdownMenuEntry<String>>[];
    for (final String sport in _sportsList) {
      sportsEntries.add(DropdownMenuEntry<String>(value: sport, label: sport));
    }
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          margin: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                DropdownMenu<String>(
                  enableFilter: true,
                  initialSelection: _selectedSport,
                  controller: sportsController,
                  label: const Text('Sport'),
                  dropdownMenuEntries: sportsEntries,
                  onSelected: (String? sport) {
                    setState(() {
                      _selectedSport = sport;
                    });
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  'Location',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                InkWell(
                    onTap: () async {
                      var place = await PlacesAutocomplete.show(
                          context: context,
                          //Self Reminder: It is using my second accounts API key (vansh24tyagi24)
                          apiKey: googleApikey,
                          mode: Mode.overlay,
                          types: ['gym', 'park', 'stadium', 'bowling_alley'],
                          strictbounds: false,
                          components: [Component(Component.country, 'ca')],
                          onError: (err) {
                            print(err);
                          });

                      if (place != null) {
                        setState(() {
                          //again update UI
                          location = place.description.toString();
                          locFlag = true;
                        });

                        //form google_maps_webservice package
                        final plist = GoogleMapsPlaces(
                          apiKey: googleApikey,
                          apiHeaders:
                              await const GoogleApiHeaders().getHeaders(),
                          //from google_api_headers package
                        );
                        String placeid = place.placeId ?? "0";
                        final detail = await plist.getDetailsByPlaceId(placeid);
                        final types = detail.result.types;

                        final geometry = detail.result.geometry!;
                        final lat = geometry.location.lat;
                        final long = geometry.location.lng;
                        var newlatlong = LatLng(lat, long);
                        currentLocation = newlatlong;
                        gp = GeoPoint(lat, long);
                        setState(() {});

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
                    )),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Text(
                            'Date',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            cursorColor: const Color(0xFF5A75FF),
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.only(
                                  left: 15, right: 10, top: 10, bottom: 10),
                              floatingLabelStyle: TextStyle(
                                  color:
                                      const Color(0xFF5A75FF).withOpacity(0.6)),
                              labelStyle: TextStyle(
                                  color:
                                      const Color(0xFF5A75FF).withOpacity(0.6),
                                  fontSize: 13),
                              focusedBorder: const OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Color(0xFF5A75FF), width: 2),
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(15.0))),
                              border: const OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: Color(0xFF5A75FF),
                                    width: 2,
                                    style: BorderStyle.solid),
                                borderRadius:
                                    BorderRadius.all(Radius.circular(15.0)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: const Color(0xFF5A75FF)
                                        .withOpacity(0.3),
                                    width: 1.5,
                                    style: BorderStyle.solid),
                                borderRadius: const BorderRadius.all(
                                    Radius.circular(15.0)),
                              ),
                              labelText: 'Date',
                              suffixIcon: Icon(Icons.calendar_today,
                                  color:
                                      const Color(0xFF5A75FF).withOpacity(0.6)),
                            ),
                            readOnly: true,
                            onTap: () => _selectDate(context),
                            validator: (value) {
                              if (_dateTime == null) {
                                return 'Please select your date of birth';
                              }
                              return null;
                            },
                            controller: TextEditingController(
                              text: _dateTime != null
                                  ? '${_dateTime!.day}/${_dateTime!.month}/${_dateTime!.year}'
                                  : '',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Text(
                            'Time',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            cursorColor: const Color(0xFF5A75FF),
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.only(
                                  left: 15, right: 10, top: 10, bottom: 10),
                              floatingLabelStyle: TextStyle(
                                  color:
                                      const Color(0xFF5A75FF).withOpacity(0.6)),
                              labelStyle: TextStyle(
                                  color:
                                      const Color(0xFF5A75FF).withOpacity(0.6),
                                  fontSize: 13),
                              focusedBorder: const OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Color(0xFF5A75FF), width: 2),
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(15.0))),
                              border: const OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: Color(0xFF5A75FF),
                                    width: 2,
                                    style: BorderStyle.solid),
                                borderRadius:
                                    BorderRadius.all(Radius.circular(15.0)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: const Color(0xFF5A75FF)
                                        .withOpacity(0.3),
                                    width: 1.5,
                                    style: BorderStyle.solid),
                                borderRadius: const BorderRadius.all(
                                    Radius.circular(15.0)),
                              ),
                              labelText: 'Time',
                              suffixIcon: Icon(Icons.access_time_outlined,
                                  color:
                                      const Color(0xFF5A75FF).withOpacity(0.6)),
                            ),
                            readOnly: true,
                            onTap: () => _selectTime(context),
                            validator: (value) {
                              if (_dateTime == null) {
                                return 'Please select time';
                              }
                              return null;
                            },
                            controller: TextEditingController(
                              text: _dateTime != null
                                  ? '${_dateTime!.hour}:${_dateTime!.minute}'
                                  : '',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Number of Players',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                NumberInputPrefabbed.directionalButtons(
                    onDecrement: (value) {
                      setState(() {
                        _numPlayers = (value as int?)!;
                      });
                    },
                    onIncrement: (value) {
                      setState(() {
                        _numPlayers = (value as int?)!;
                      });
                    },
                    isInt: true,
                    controller: TextEditingController(),
                    incDecBgColor: Colors.blue,
                    initialValue: 1,
                    min: 1,
                    max: 10),
                const SizedBox(height: 8),
                const Text(
                  'Duration',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    hintText: 'Enter the duration of the event',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _duration = double.tryParse(value);
                    });
                  },
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Please enter the duration';
                    } else if (_duration == null ||
                        _duration! <= 0 ||
                        _duration! > 5) {
                      return 'Please enter a valid duration';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Center(
                  child: ElevatedButton(
                    onPressed: _host,
                    child: const Text('Submit'),
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

class MyForm extends StatefulWidget {
  const MyForm({super.key});

  @override
  _MyFormState createState() => _MyFormState();
}

class _MyFormState extends State<MyForm> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController sportsController = TextEditingController();

  String? _location;
  DateTime? _dateTime;
  int _numPlayers = 1;
  double? _duration;
  String? _selectedSport;
  List<String> _filteredSportsList = [];
  String googleApikey = "AIzaSyBQ2hIN6nTS5FKQzWAZcmX3jNF_ItGj2OA";
  GoogleMapController? mapController; //controller for Google map
  CameraPosition? cameraPosition;
  LatLng currentLocation = const LatLng(43.589848583409015, -79.7040416309252);
  String location = "Search Location";
  bool locFlag = false;
  GeoPoint? gp;
  final List<String> _sportsList = [
    'Basketball',
    'Football',
    'Baseball',
    'Tennis',
    'Swimming',
    'Badminton',
  ];

  @override
  void initState() {
    _filteredSportsList = _sportsList;
    super.initState();
  }

  void _filterSportsList(String searchText) {
    setState(() {
      _filteredSportsList = _sportsList
          .where(
              (sport) => sport.toLowerCase().contains(searchText.toLowerCase()))
          .toList();
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(
          DateTime.now().year + 1, DateTime.now().month, DateTime.now().day),
    );
    if (picked != null && picked != _dateTime) {
      setState(() {
        _dateTime = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _dateTime = DateTime(
          _dateTime!.year,
          _dateTime!.month,
          _dateTime!.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  Future _host() async {
    print('${_selectedSport!} ${gp!} ${_dateTime!} $_numPlayers ${_duration!}');
    if (locFlag == false) {
      print("locflag == false");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Select a location"),
        ),
      );
      return;
    }
    if (_formKey.currentState!.validate()) {
      print("form is valid");
      // Form is validated
      // Do something with the form data
      _formKey.currentState!.save();

      final user = FirebaseAuth.instance.currentUser!;

      await DatabaseService(uid: user.uid)
          .addEvent(_selectedSport!, gp!, _dateTime!, _numPlayers, _duration!);
      // ScaffoldMessenger.of(context).showSnackBar(
      //   const SnackBar(
      //     content: Text("Event Created"),
      //   ),
      // );
    }
  }

  int _currentPage = 1;
  final PageController _pageController = PageController(initialPage: 0);

  final List<String> sports = [
    'Football', 'Basketball', 'Baseball', 'Soccer', 'Tennis',
    'Golf', 'Volleyball', 'Rugby', 'Cricket', 'Hockey', 'Swimming',
    'Wrestling', 'Athletics', 'Badminton', 'Table Tennis', 'Boxing',
    'Martial Arts', 'Cycling', 'Gymnastics', 'Archery', 'Diving',
    'Snooker', 'Billiards', 'Bowling', 'Canoeing', 'Rowing', 'Sailing',
    'Ice Hockey', 'Skiing', 'Snowboarding', 'Surfing', 'Skateboarding',
    'Climbing', 'Fencing', 'Horse Racing', 'Track and Field', 'Triathlon',
    'Bobsleigh', 'Curling', 'Luge', 'Skeleton', 'Motorsport', 'Softball',
    'Handball', 'Beach Volleyball', 'Water Polo', 'Taekwondo', 'Karate',
    'Judo', 'Polo', 'Squash', 'Racquetball', 'Roller Skating', 'Skate Racing',
    'Kiteboarding', 'Parkour', 'BMX', 'Canyoning', 'CrossFit', 'Weightlifting',
    'Cross Country Skiing', 'Biathlon', 'Figure Skating', 'Speed Skating',
    'Inline Skating', 'Ice Skating', 'Lacrosse', 'Ultimate Frisbee', 'Disc Golf',
    'Orienteering', 'Rhythmic Gymnastics', 'Trampoline', 'Slacklining', 'Paddleboarding',
    'Free Running', 'Base Jumping', 'Skydiving', 'Hang Gliding', 'Paragliding',
    'Windsurfing', 'Wakeboarding', 'Flowboarding', 'Bodyboarding', 'Bungee Jumping',
    'Cliff Diving', 'Mountain Biking', 'BMX Racing', 'BMX Freestyle', 'Mountain Boarding',
    'Sandboarding', 'Snowkiting', 'Land Sailing', 'Ultramarathon', 'Dragon Boat Racing',
    'Powerlifting', 'Rodeo', 'Sumo Wrestling', 'Crossfit Games', 'Strongman', 'Tug of War'

    // Add more sports as needed
  ];

  String getHeaderText() {
    switch (_currentPage) {
      case 1:
        return "Host an Activity";
      case 2:
        return "Step 1";
      case 3:
        return "Step 2";
      case 4:
        return "Step 3";
      case 5:
        return "Step 4";
      case -1:
        return "My Activities";
    }
    return "Unknown page";
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          toolbarHeight: 130,
          elevation: 0, // Remove the elevation (shadow) from the app bar
          flexibleSpace: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
                width: double.infinity,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 7),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(50),
                    color: const Color(0xFF5A75FF).withAlpha(60),
                  ),
                  child: TabBar(
                    onTap: (pageNum) {
                      if (pageNum == 0) {
                        setState(() {
                          // set page number to 1, indicated to Host an activities page
                          _currentPage = 1;
                        });
                      } else if (pageNum == 1) {
                        // set page number to 1, go back to the first host activity page
                        setState(() {
                          // set page number to -1, indicated to hosted activities page
                          _currentPage = -1;
                        });
                      }

                    },
                    automaticIndicatorColorAdjustment: true,
                    labelColor: Colors.white,
                    unselectedLabelColor: const Color(0xFF5A75FF),
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicatorPadding: const EdgeInsets.symmetric(vertical: 4),
                    indicator: BoxDecoration(
                      borderRadius: BorderRadius.circular(50),
                      color: const Color(0xFF5A75FF),
                    ),
                    tabs: const [
                      Tab(child: Text('Host an Activity',
                        style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w400
                        ),),
                      ),
                      Tab(
                        child: Text('View My Activities',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w400
                        ),),
                      ),
                    ],
                  ),
                )),
          ),
          title: Padding(
            padding:
                const EdgeInsets.only(top: 100.0, left: 10), // Add top padding
            child: Container(
              padding: const EdgeInsets.only(left: 20),
              child: Text(
                getHeaderText(),
                style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF5A75FF),
                  fontFamily: 'Poppins'
                ),
              ),
            ),
          ),
        ),
        body: TabBarView(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Form(
                key: _formKey,
                child: PageView(
                  //physics: const NeverScrollableScrollPhysics(),
                  controller: _pageController,
                  onPageChanged: (int page) {
                    setState(() {
                      _currentPage = page + 1;
                    });
                  },
                  children: [
                    _buildPage0(),
                    _buildPage1(),
                    _buildPage2(),
                    _buildPage3(),
                    _buildPage4(),
                  ],
                ),
              ),
            ),
            const MyActivityPage(),
          ],
        ),
      ),
    );
  }

  Widget _buildPage0() {
    final List<DropdownMenuEntry<String>> sportsEntries =
        <DropdownMenuEntry<String>>[];
    for (final String sport in _sportsList) {
      sportsEntries.add(DropdownMenuEntry<String>(value: sport, label: sport));
    }
    return Padding(
      padding:
          const EdgeInsets.only(left: 20.0, right: 20, bottom: 16, top: 23),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.only(left: 20),
              child: const Text('Meet-up with fitness partners\naround your area',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w400,
                fontSize: 15
              ),)),
          const SizedBox(height: 20),
          Image.asset('assets/images/WomanManRunning.png'),
          const Spacer(),
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildPage1() {
    final List<DropdownMenuEntry<String>> sportsEntries =
        <DropdownMenuEntry<String>>[];
    for (final String sport in _sportsList) {
      sportsEntries.add(DropdownMenuEntry<String>(value: sport, label: sport));
    }
    return Padding(
      padding:
          const EdgeInsets.only(left: 40.0, right: 40, bottom: 16, top: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Where and what is your \nactivity?',
            style: TextStyle(
                fontSize: 18, color: Colors.black),
          ),
          const SizedBox(height: 30),
          const Text(
            'Activity Name',
          ),
          const SizedBox(height: 8),
          DropdownMenu<String>(
            textStyle: const TextStyle(color: Color(0xFF5A75FF)),
            width: MediaQuery.of(context).size.width - 100,
            enableFilter: true,
            //requestFocusOnTap: true,
            initialSelection: _selectedSport,
            controller: sportsController,
            dropdownMenuEntries: sportsEntries,
            onSelected: (String? sport) {
              setState(() {
                _selectedSport = sport;
              });
            },
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.only(
                  left: 15, right: 10, top: 10, bottom: 10),
              floatingLabelStyle:
                  TextStyle(color: const Color(0xFF5A75FF).withOpacity(0.6)),
              labelStyle: TextStyle(
                  color: const Color(0xFF5A75FF).withOpacity(0.6),
                  fontSize: 13),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF5A75FF), width: 2),
                borderRadius: BorderRadius.all(Radius.circular(15.0)),
              ),
              border: const OutlineInputBorder(
                borderSide: BorderSide(
                    color: Color(0xFF5A75FF),
                    width: 2,
                    style: BorderStyle.solid),
                borderRadius: BorderRadius.all(Radius.circular(15.0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                    color: const Color(0xFF5A75FF).withOpacity(0.3),
                    width: 1.5,
                    style: BorderStyle.solid),
                borderRadius: const BorderRadius.all(Radius.circular(15.0)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Location',
          ),
          const SizedBox(height: 8),
          InkWell(
            borderRadius: const BorderRadius.all(Radius.circular(15.0)),
            onTap: () async {
              var place = await PlacesAutocomplete.show(
                context: context,
                apiKey: googleApikey,
                mode: Mode.overlay,
                types: ['gym', 'park', 'stadium', 'bowling_alley'],
                strictbounds: false,
                components: [Component(Component.country, 'ca')],
                onError: (err) {
                  print(err);
                },
              );

              if (place != null) {
                setState(() {
                  location = place.description.toString();
                  locFlag = true;
                });

                final plist = GoogleMapsPlaces(
                  apiKey: googleApikey,
                  apiHeaders: await const GoogleApiHeaders().getHeaders(),
                );

                String placeid = place.placeId ?? "0";
                final detail = await plist.getDetailsByPlaceId(placeid);
                final types = detail.result.types;

                final geometry = detail.result.geometry!;
                final lat = geometry.location.lat;
                final long = geometry.location.lng;
                var newlatlong = LatLng(lat, long);
                currentLocation = newlatlong;
                gp = GeoPoint(lat, long);
                setState(() {});

                mapController?.animateCamera(CameraUpdate.newCameraPosition(
                  CameraPosition(target: newlatlong, zoom: 17),
                ));
              }
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(
                    color: const Color(0xFF5A75FF).withOpacity(0.3),
                    width: 1.5),
                borderRadius: const BorderRadius.all(Radius.circular(15.0)),
              ),
              padding: const EdgeInsets.all(0),
              child: ListTile(
                title: Text(
                  location,
                  style: const TextStyle(
                      fontSize: 15, color: Color(0xFF5A75FF)),
                ),
                trailing: Icon(Icons.search,
                    color: const Color(0xFF5A75FF).withOpacity(0.6)),
                dense: true,
              ),
            ),
          ),
          const Spacer(),
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildPage2() {
    return Padding(
      padding: const EdgeInsets.only(left: 40.0, right: 40, bottom: 16, top: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'When would you like to do your \nactivity?',
                style: TextStyle(
                    fontSize: 18, color: Colors.black),
              ),
              const SizedBox(height: 30),
              const Text(
                'Date',
              ),
              const SizedBox(height: 8),
              TextFormField(
                style: const TextStyle(color: Color(0xFF5A75FF)),
                cursorColor: const Color(0xFF5A75FF),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.only(
                      left: 15, right: 10, top: 10, bottom: 10),
                  floatingLabelStyle: TextStyle(
                      color: const Color(0xFF5A75FF).withOpacity(0.6)),
                  labelStyle: TextStyle(
                      color: const Color(0xFF5A75FF).withOpacity(0.6),
                      fontSize: 13),
                  focusedBorder: const OutlineInputBorder(
                      borderSide:
                          BorderSide(color: Color(0xFF5A75FF), width: 2),
                      borderRadius: BorderRadius.all(Radius.circular(15.0))),
                  border: const OutlineInputBorder(
                    borderSide: BorderSide(
                        color: Color(0xFF5A75FF),
                        width: 2,
                        style: BorderStyle.solid),
                    borderRadius: BorderRadius.all(Radius.circular(15.0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                        color: const Color(0xFF5A75FF).withOpacity(0.3),
                        width: 1.5,
                        style: BorderStyle.solid),
                    borderRadius: const BorderRadius.all(Radius.circular(15.0)),
                  ),
                  suffixIcon: Icon(Icons.calendar_today,
                      color: const Color(0xFF5A75FF).withOpacity(0.6)),
                ),
                readOnly: true,
                onTap: () => _selectDate(context),
                validator: (value) {
                  if (_dateTime == null) {
                    return 'Please select a date';
                  }
                  return null;
                },
                controller: TextEditingController(
                  text: _dateTime != null
                      ? '${_dateTime!.day}/${_dateTime!.month}/${_dateTime!.year}'
                      : '',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'Time',
              ),
              const SizedBox(height: 8),
              TextFormField(
                style: const TextStyle(color: Color(0xFF5A75FF)),
                cursorColor: const Color(0xFF5A75FF),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.only(
                      left: 15, right: 10, top: 10, bottom: 10),
                  floatingLabelStyle: TextStyle(
                      color: const Color(0xFF5A75FF).withOpacity(0.6)),
                  labelStyle: TextStyle(
                      color: const Color(0xFF5A75FF).withOpacity(0.6),
                      fontSize: 13),
                  focusedBorder: const OutlineInputBorder(
                      borderSide:
                          BorderSide(color: Color(0xFF5A75FF), width: 2),
                      borderRadius: BorderRadius.all(Radius.circular(15.0))),
                  border: const OutlineInputBorder(
                    borderSide: BorderSide(
                        color: Color(0xFF5A75FF),
                        width: 2,
                        style: BorderStyle.solid),
                    borderRadius: BorderRadius.all(Radius.circular(15.0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                        color: const Color(0xFF5A75FF).withOpacity(0.3),
                        width: 1.5,
                        style: BorderStyle.solid),
                    borderRadius: const BorderRadius.all(Radius.circular(15.0)),
                  ),
                  suffixIcon: Icon(Icons.access_time_outlined,
                      color: const Color(0xFF5A75FF).withOpacity(0.6)),
                ),
                readOnly: true,
                onTap: () => _selectTime(context),
                validator: (value) {
                  if (_dateTime == null) {
                    return 'Please select time';
                  }
                  return null;
                },
                controller: TextEditingController(
                  text: _dateTime != null
                      ? '${_dateTime!.hour}:${_dateTime!.minute}'
                      : '',
                ),
              ),
            ],
          ),
          const Spacer(),
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildPage3() {
    return Padding(
      padding: const EdgeInsets.only(left: 40.0, right: 40, bottom: 16, top: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Attendees and duration \npreferences?',
            style: TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 30),
          const Text(
            'Duration',
          ),
          const SizedBox(height: 8),
          TextFormField(
            style: const TextStyle(color: Color(0xFF5A75FF)),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            cursorColor: const Color(0xFF5A75FF),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.only(
                  left: 15, right: 10, top: 10, bottom: 10),
              floatingLabelStyle:
                  TextStyle(color: const Color(0xFF5A75FF).withOpacity(0.6)),
              labelStyle: TextStyle(
                  color: const Color(0xFF5A75FF).withOpacity(0.6),
                  fontSize: 13),
              focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF5A75FF), width: 2),
                  borderRadius: BorderRadius.all(Radius.circular(15.0))),
              border: const OutlineInputBorder(
                borderSide: BorderSide(
                    color: Color(0xFF5A75FF),
                    width: 2,
                    style: BorderStyle.solid),
                borderRadius: BorderRadius.all(Radius.circular(15.0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                    color: const Color(0xFF5A75FF).withOpacity(0.3),
                    width: 1.5,
                    style: BorderStyle.solid),
                borderRadius: const BorderRadius.all(Radius.circular(15.0)),
              ),
              suffixIcon: Icon(Icons.access_alarms_rounded,
                  color: const Color(0xFF5A75FF).withOpacity(0.6)),
            ),
            onChanged: (value) {
              setState(() {
                _duration = double.tryParse(value);
              });
            },
            validator: (value) {
              if (value!.isEmpty) {
                return 'Please enter the duration';
              } else if (_duration == null ||
                  _duration! <= 0 ||
                  _duration! > 5) {
                return 'Please enter a valid duration';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          const Text(
            'Number of Players',
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                  color: const Color(0xFF5A75FF).withOpacity(0.2), width: 2),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.remove,
                      color: const Color(0xFF5A75FF).withOpacity(0.7)),
                  onPressed: () {
                    setState(() {
                      _numPlayers = (_numPlayers - 1).clamp(1, 10);
                    });
                  },
                ),
                Text(
                  '$_numPlayers',
                  style: const TextStyle(fontSize: 18, color: Color(0xFF5A75FF)),
                ),
                IconButton(
                  icon: Icon(Icons.add,
                      color: const Color(0xFF5A75FF).withOpacity(0.7)),
                  onPressed: () {
                    setState(() {
                      _numPlayers = (_numPlayers + 1).clamp(1, 10);
                    });
                  },
                ),
              ],
            ),
          ),
          const Spacer(),
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildPage4() {
    return Padding(
        padding: const EdgeInsets.only(left: 40.0, right: 40, bottom: 16, top: 5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Confirm your activity details:',
              style: TextStyle(
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 27),
            const Text(
              'Activity name',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              _selectedSport ?? 'f',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Location',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              location,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Date',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${_dateTime?.year}-${_dateTime?.month}-${_dateTime?.day}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Time',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${_dateTime?.hour}:${_dateTime?.minute}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    )
                  ],
                )
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Duration',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '$_duration',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 20),
                Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start, // added for clarity
                  children: [
                    const Text(
                      'Num of Players',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text('$_numPlayers',
                        style:
                            TextStyle(fontSize: 14, color: Colors.grey[600])),
                  ],
                ),
              ],
            ),
            const Spacer(),
            _buildNavigationButtons(),
          ],
        ));
  }

  bool isNextButtonDisabled() {
    if (((_currentPage == 2) &&
            (location == "Search Location" || _selectedSport == null)) ||
        ((_currentPage == 3) && (_dateTime == null)) ||
        ((_currentPage == 4) && (_duration == null))) {
      return true;
    }
    return false;
  }

  Widget _buildNavigationButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (_currentPage > 1)
          SizedBox(
            height: 50,
            child: TextButton(
              onPressed: () {
                _pageController.previousPage(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                );
              },
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF5A75FF).withAlpha(180),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20), // Add border radius
                ),
              ),
              child:SizedBox(
                width: double.infinity,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Previous',
                      style: TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        if (_currentPage > 1) const SizedBox(height: 15),
        SizedBox(
          height: 50,
          child: ElevatedButton(
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.resolveWith<Color>(
                (Set<MaterialState> states) {
                  if (states.contains(MaterialState.disabled)) {
                    return Colors.grey;
                  }
                  return const Color(0xFF5A75FF);
                },
              ),
              shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            onPressed: isNextButtonDisabled()
                ? null
                : () {
                    if (_currentPage < 5) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      if (_formKey.currentState?.validate() ?? false) {
                        setState(() {
                          _currentPage = 1;
                        });
                        _pageController.jumpToPage(0);

                        _host();
                        print('${_selectedSport!} ${gp!} ${_dateTime!} $_numPlayers ${_duration!}');
                        // Form submission logic goes here
                        // Display form data under the submit button

                        setState(() {
                          _selectedSport = '';
                          _location = null;
                          location = 'Select a location';
                          gp = null;
                          _dateTime = null;
                          _duration = null;
                          _numPlayers = 1;
                        });
                      }
                    }
                  },
            child: SizedBox(
              width: double.infinity,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                      _currentPage == 1
                          ? "Let's Go! >"
                          : _currentPage < 5
                              ? 'Next'
                              : 'Submit',
                      textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
