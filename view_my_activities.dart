import 'package:firebase_auth/firebase_auth.dart';
import 'package:fittl/pages/posts_page.dart';
import 'package:fittl/pages/view_hosted_events.dart';
import 'package:fittl/pages/view_joined_events.dart';
import 'package:flutter/material.dart';

import 'create_community_page.dart';
import 'list_communities_page.dart';

class MyActivityPage extends StatefulWidget {
  const MyActivityPage({super.key});

  @override
  State<MyActivityPage> createState() => _MyActivityPageState();
}

class _MyActivityPageState extends State<MyActivityPage> {
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
          toolbarHeight: 70,
          elevation: 0, // Remove the elevation (shadow) from the app bar
          flexibleSpace: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 29),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.only(left: 7.0, right: 7, top: 7.0, bottom: 10),
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
                            child: Text('Hosted', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w400)),
                          ),
                          Tab(
                            child: Text('Joined', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w400)),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        ),
        body: TabBarView(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 17),
                child: Center(child: HostedEventsScreen())),
            Container(
                padding: EdgeInsets.symmetric(horizontal: 17),
                child: Center(child: JoinedEventsScreen()))
          ],
        ),
      ),
    );
  }
}
