
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fittl/pages/landing_page.dart';
import 'package:flutter/material.dart';
import '../user_details.dart';
import 'login_or_registration_page.dart';
class AuthPage extends StatefulWidget{
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
   Future<bool> checkDocument(String docID) async {
    final s = await FirebaseFirestore.instance
        .collection('user-profile')
        .doc(docID)
        .get();

    if (!s.exists) {

      return false;
    } else {
      return true;
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: false,
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          //user logged in
          if(snapshot.hasData){

            final user = FirebaseAuth.instance.currentUser!;
            final uid = user.uid;

            return FutureBuilder<bool>(
              future: checkDocument(uid),
              builder: (context, AsyncSnapshot<bool> snapshot2) {
                if (snapshot2.connectionState == ConnectionState.waiting) {
                  // Loading state while waiting for the future to complete
                  return Center(
                    child: Image.asset(
                      'assets/loading.gif',
                      height: 150,
                      width: 200,
                    ),
                  );
                }

                if (snapshot2.hasError || !snapshot2.data!) {
                  // Error state or document doesn't exist, show FittlPage
                  return const FittlPage();
                }

                // Document exists, show HomePage
                return const LandingPage();
              },
    );
    }
          else {
            return const LoginOrRegisterPage();
          }

          //user not logged in
        },
      ),
    );
  }
}