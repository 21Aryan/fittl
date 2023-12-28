import 'package:firebase_auth/firebase_auth.dart';
import 'package:fittl/Modals/EventInfo.dart';
import 'package:fittl/pages/create_community_page.dart';
import 'package:fittl/pages/preferences_page.dart';
import 'package:fittl/pages/view_hosted_events.dart';
import 'package:flutter/material.dart';

import 'Services/DatabaseService.dart';


class UserSettingsPage extends StatelessWidget {
  const UserSettingsPage({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const UserSettings(title: 'Flutter Demo Home Page'),
    );
  }
}

class UserSettings extends StatefulWidget {
  const UserSettings({super.key, required this.title});
  final String title;

  @override
  State<UserSettings> createState() => _UserSettingsState();
}

class _UserSettingsState extends State<UserSettings> {
  void _signout(){
    FirebaseAuth.instance.signOut();
  }


  void _openCreateCommunityPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateCommunityPage(userId: FirebaseAuth.instance.currentUser!.uid),
      ),
    );
  }

  void _viewHostedEvents() {
    // Navigate to the HostedEventsScreen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const HostedEventsScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0, // Remove app bar shadow
        backgroundColor: Colors.white, // Match background color
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: const Text(
            'Settings',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 27.0,
            ),
          ),
        ),
      ),
      body: ListView(
        children: [
          SizedBox(height: 10,),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 30.0, vertical: 3.0),
            leading: Icon(
              Icons.settings, // Use the person icon or any other icon you prefer
              size: 30,
              color: Color(0xFF5A75FF),// Set the size as needed
            ),
            title: Container(
              padding: const EdgeInsets.only(right: 30.0),
              child: GestureDetector(
                onTap: () {
                  // Navigate to the PreferencesPage
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PreferencesPage(),
                    ),
                  );
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      'Preferences',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            subtitle: const Padding(
              padding: EdgeInsets.only(top: 5.0), // Add top padding
              child: Text(
                "Set or update your preferences",
                style: TextStyle(color: Colors.grey),
              ),
            ),
            // Add a Divider between each ListTile
            // Or you can use other decorations to separate the chat items
            //tileColor: Colors.grey[200],
            //shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
            //trailing: Icon(Icons.chevron_right),
          ),
          SizedBox(height: 3),
      ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 3.0),
        leading: Icon(
          Icons.person,
          size: 30,
          color: Color(0xFF5A75FF),
        ),
        title: Container(
          padding: const EdgeInsets.only(right: 30.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                'Account Settings',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        subtitle: const Padding(
          padding: EdgeInsets.only(top: 5.0),
          child: Text(
            "Change username, password, and email preferences",
            style: TextStyle(color: Colors.grey),
          ),
        ),
      ),
          SizedBox(height: 3),
      ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 3.0),
        leading: Icon(
          Icons.notifications,
          size: 30,
          color: Color(0xFF5A75FF),
        ),
        title: Container(
          padding: const EdgeInsets.only(right: 30.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                'Notification Settings',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        subtitle: const Padding(
          padding: EdgeInsets.only(top: 5.0),
          child: Text(
            "Configure push, email, and in-app notifications",
            style: TextStyle(color: Colors.grey),
          ),
        ),
      ),
          SizedBox(height: 3),
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 3.0),
          leading: Icon(
            Icons.color_lens,
            size: 30,
            color: Color(0xFF5A75FF),
          ),
          title: Container(
            padding: const EdgeInsets.only(right: 30.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  'Appearance',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          subtitle: const Padding(
            padding: EdgeInsets.only(top: 5.0),
            child: Text(
              "Choose your theme, font size, and app icon",
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
        SizedBox(height: 3),
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 3.0),
          leading: Icon(
            Icons.lock,
            size: 30,
            color: Color(0xFF5A75FF),
          ),
          title: Container(
            padding: const EdgeInsets.only(right: 30.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  'Privacy',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          subtitle: const Padding(
            padding: EdgeInsets.only(top: 5.0),
            child: Text(
              "Manage public profile, location settings, and data usage",
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      SizedBox(height: 20,),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 30),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: GestureDetector(
                onTap: () =>
                    _signout(), // Call the sign-out function
                child:  Padding(
                  padding: EdgeInsets.symmetric(horizontal: 30.0, vertical: 17),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Sign Out',
                        style: TextStyle(color: Colors.white),
                      ),
                      SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.white,
                        size: 15,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      // Add more settings options as needed
        ],

      ),







      // Center(
      //   child: Column(
      //     mainAxisAlignment: MainAxisAlignment.center,
      //     children: <Widget>[
      //       Text(
      //         'This is a settings page',
      //       ),
      //       SizedBox(height: 20),
      //       ElevatedButton(
      //         onPressed: _openCreateCommunityPage,
      //         child: Text('Create Community'),
      //       ),
      //     ],
      //   ),
      // ),
    );
  }
}
