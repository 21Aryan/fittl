import 'package:fittl/pages/explore_users_page.dart';
import 'package:fittl/pages/friend_requests_page.dart';
import 'package:fittl/pages/friends_page.dart';
import 'package:flutter/material.dart';

class ConnectionsPage extends StatefulWidget {
  const ConnectionsPage({super.key});

  @override
  State<ConnectionsPage> createState() => _ConnectionsPageState();
}

class _ConnectionsPageState extends State<ConnectionsPage> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          backgroundColor: const Color(0xFFF8F8F8),
          toolbarHeight: 120,
          elevation: 0, // Remove the elevation (shadow) from the app bar
          flexibleSpace: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 29),
            child: Column(
              children: [
                Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Friends',
                      style:
                          TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                    )),
                Container(
                  padding: const EdgeInsets.only(
                      left: 7.0, right: 7, top: 7.0, bottom: 10),
                ),
                SizedBox(
                    width: double.infinity,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 2, horizontal: 7),
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
                        indicatorPadding:
                            const EdgeInsets.symmetric(vertical: 4),
                        indicator: BoxDecoration(
                          borderRadius: BorderRadius.circular(50),
                          color: const Color(0xFF5A75FF),
                        ),
                        tabs: const [
                          Tab(
                            child: Text('Explore',
                                style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w400)),
                          ),
                          Tab(
                            child: Text('Friends',
                                style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w400)),
                          ),
                          Tab(
                            child: Text('Requests',
                                style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w400)),
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
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Center(
                  child: ExploreUsersPage(title: 'Explore Users'),
                )),
            Container(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Center(child: FriendsPage(title: 'Friends'))),
            Container(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Center(
                    child: FriendRequestsPage(title: 'Friend Requests'))),
          ],
        ),
      ),
    );
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Connections'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Friends'),
              Tab(text: 'Requests'),
              Tab(
                text: 'Explore',
              )
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            Center(child: FriendsPage(title: 'Friends')),
            Center(child: FriendRequestsPage(title: 'Friend Requests')),
            Center(
              child: ExploreUsersPage(title: 'Explore Users'),
            )
          ],
        ),
      ),
    );
  }
}
