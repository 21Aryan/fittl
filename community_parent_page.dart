import 'package:firebase_auth/firebase_auth.dart';
import 'package:fittl/pages/posts_page.dart';
import 'package:flutter/material.dart';

import 'create_community_page.dart';
import 'list_communities_page.dart';

class CommunityParentPage extends StatefulWidget {
  const CommunityParentPage({super.key});

  @override
  State<CommunityParentPage> createState() => _CommunityParentPageState();
}

class _CommunityParentPageState extends State<CommunityParentPage> {
  void _openCreateCommunityModal(BuildContext context, String userId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return FractionallySizedBox(
          heightFactor: 0.9,
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16.0),
            child: CreateCommunityPage(userId: userId),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          backgroundColor: const Color(0xFFF8F8F8),
          toolbarHeight: 135,
          elevation: 0, // Remove the elevation (shadow) from the app bar
          flexibleSpace: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 29),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.only(left: 7.0, right: 7, top: 7.0, bottom: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'Fitfams',
                        style: TextStyle(
                            color: Color(0xFF5A75FF),
                            fontWeight: FontWeight.w600,
                            fontSize: 26,
                        fontFamily: 'Poppins'), // Set text color to cyan
                      ),
                      TextButton(
                        onPressed: () {
                          final user = FirebaseAuth.instance.currentUser!;
                          _openCreateCommunityModal(context, user.uid);
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 14.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                          backgroundColor: const Color(0xFF5A75FF),
                        ),
                        child: Row( // Wrap in a Row widget
                          children: [
                            Icon(
                              Icons.add, // Replace with the desired icon
                              color: Colors.white,
                              size: 15.0,
                            ),
                            SizedBox(width: 4.0), // Adjust the spacing between icon and text
                            Text(
                              'Create Community',
                              style: TextStyle(color: Colors.white, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                    width: double.infinity,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 7),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(80),
                        color: const Color(0xFF5A75FF).withOpacity(0.3),
                        // border: Border.all(
                        //   color: Color(0xFF5A75FF).withOpacity(0.3), // You can set the border color here
                        //   width: 2, // Set the border width to 2
                        // ),
                      ),
                      child: TabBar(
                        onTap: (pageNum) {
                          if (pageNum == 0) {
                            setState(() {
                              // set page number t
                            });
                          } else if (pageNum == 1) {
                            // set page number to 1, go back to the first host activity page
                            setState(() {
                              // set page numb
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
                          Tab(
                            child: Text('Communities', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w400)),
                          ),
                          Tab(
                            child: Text('Posts', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w400)),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        ),
        body: const TabBarView(
          children: [
              Center(child: Communities(title: 'Communities')),
              Center(child: PostsPage())
          ],
        ),
      ),
    );
  }
}
