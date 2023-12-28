import 'dart:io';

import 'package:fittl/pages/community_page.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../Services/DatabaseService.dart';

class CreateCommunityPage extends StatefulWidget {
  final String userId;

  const CreateCommunityPage({required this.userId, Key? key}) : super(key: key);

  @override
  State<CreateCommunityPage> createState() => _CreateCommunityPageState();
}

class _CreateCommunityPageState extends State<CreateCommunityPage> {
  final TextEditingController _communityNameController =
      TextEditingController();
  final TextEditingController _communityDescriptionController =
      TextEditingController();
  String? _selectedSport; // Variable to store the selected sport/tag
  final List<String> _selectedSports =
      []; // List to store multiple selected sports/tags
  File? _image; // Variable to store the selected display picture
  // List of available sports/tags
  final List<String> sports = [
    'Football', 'Basketball', 'Baseball', 'Soccer', 'Tennis','Badminton'
  ];

  Future<void> _createCommunity() async {
    String communityName = _communityNameController.text;
    String communityDescription = _communityDescriptionController.text;
    String communityId = "";
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(
          child: Image.asset(
            'assets/loading.gif',
            height: 150,
            width: 200,
          ),
        );
      },
    );
    try {
       communityId = await DatabaseService(uid: widget.userId)
          .createCommunity(communityName,
          widget.userId, communityDescription, _selectedSports, _image!);
      // Close the loading indicator dialog

    }catch(error){
      return;
    }
    finally{
      Navigator.of(context).pop();
    }
    Navigator.of(context).pop();
    await _openCommunityModal(context, communityId);
  }
  Future<void> _openCommunityModal(BuildContext context, String communityId) async{
    showModalBottomSheet(
      backgroundColor: const Color(0xFFF2F3F7),
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return FractionallySizedBox(
          heightFactor: 0.9,
          child: Container(
            color: const Color(0xFFF2F3F7),
            padding: const EdgeInsets.all(16.0),
            child: CommunityPage(communityId: communityId),
          ),
        );
      },
    );
  }

  final ImagePicker _picker = ImagePicker();

  Future<void> _selectImage() async {
    PickedFile? pickedImage =
        await _picker.getImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() {
        _image = File(pickedImage.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.white,
        toolbarHeight: 70,
        elevation: 0,
        leading: InkWell(
          onTap: () {
            Navigator.pop(context);
          },
          child: const Icon(Icons.close, color: Colors.black, size: 30),
        ),
        title: const Text(
          'Create a community',
          style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              color: Color(0xFF5A75FF),
              fontSize: 20),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 15),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 5),
                child: Text(
                  'Fuel your fitness journey! Create your \nvibrant community—where goals \nbecome gains',
                  style: TextStyle(
                      fontSize: 13.5,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w400),
                ),
              ),
              const SizedBox(
                height: 30,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 37.0,
                    backgroundColor: const Color(0xFF5A75FF).withOpacity(0.7),
                    backgroundImage: _image != null ? FileImage(_image!) : null,
                    child: _image == null
                        ? const Icon(
                            Icons.people,
                            size: 25.0,
                            color: Colors.white,
                          )
                        : null,
                  ),
                  TextButton(
                    onPressed: _selectImage,
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFF5A75FF),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(50), // Add border radius
                      ),
                    ),
                    child:  SizedBox(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(
                                vertical: 2, horizontal: 10.0),
                            child: Text(
                              'Choose display picture',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'Poppins',
                                  fontSize: 13),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              const Text(
                'Community Name',
              ),
              const SizedBox(height: 2),
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
                ),
                controller: _communityNameController,
              ),
              const SizedBox(height: 12),
              const Text(
                'Description',
              ),
              const SizedBox(height: 2),
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
                ),
                controller: _communityDescriptionController,
              ),
              const SizedBox(height: 12),
              const Text(
                'Sports (Tags)',
              ),
              const SizedBox(height: 2),
              DropdownButtonFormField<String>(
                value: _selectedSport,
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedSport = newValue;
                    if (_selectedSport != null &&
                        !_selectedSports.contains(_selectedSport)) {
                      _selectedSports.add(_selectedSport!);
                    }
                  });
                },
                items: sports.map((sport) {
                  return DropdownMenuItem<String>(
                    value: sport,
                    child: Text(
                      sport, // Apply the same style here
                    ),
                  );
                }).toList(),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.only(
                      left: 15, right: 10, top: 10, bottom: 10),
                  floatingLabelStyle: TextStyle(
                    color: const Color(0xFF5A75FF).withOpacity(0.6),
                  ),
                  labelStyle: TextStyle(
                    color: const Color(0xFF5A75FF).withOpacity(0.6),
                    fontSize: 13,
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF5A75FF), width: 2),
                    borderRadius: BorderRadius.all(Radius.circular(15.0)),
                  ),
                  border: const OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Color(0xFF5A75FF),
                      width: 2,
                      style: BorderStyle.solid,
                    ),
                    borderRadius: BorderRadius.all(Radius.circular(15.0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: const Color(0xFF5A75FF).withOpacity(0.3),
                      width: 1.5,
                      style: BorderStyle.solid,
                    ),
                    borderRadius: const BorderRadius.all(Radius.circular(15.0)),
                  ),
                ),
              ),
              const SizedBox(height: 20), // Display selected sports
              const SizedBox(height: 20),
              TextButton(
                onPressed: _createCommunity,
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFF5A75FF),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(20), // Add border radius
                  ),
                ),
                child: SizedBox(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(
                            vertical: 10, horizontal: 20.0),
                        child: Text(
                          'Create!',
                          style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'Poppins',
                              fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void main() => runApp(const MaterialApp(
      home: CreateCommunityPage(userId: 'yourUserId'),
    ));
