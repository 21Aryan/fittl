import 'package:firebase_auth/firebase_auth.dart';
import 'package:fittl/Services/DatabaseService.dart';
import 'package:fittl/pages/view_event_details.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../Modals/EventInfo.dart';

class HostedEventsScreen extends StatefulWidget {
  const HostedEventsScreen({super.key});

  @override
  State<HostedEventsScreen> createState() => _HostedEventsScreenState();
}

class _HostedEventsScreenState extends State<HostedEventsScreen> {
  List<EventInfo> eventData=[];
  Future<List<EventInfo>> fetchData() async {
    final user = FirebaseAuth.instance.currentUser!;

    List<EventInfo> list = await DatabaseService(uid: user.uid).getEventsByHostId(user.uid);
    //log('list: $list');
    return list;
  }

  Future<void> _delete(String eventId, String hostId) async{
    DatabaseService(uid: uid).deleteEvent(eventId, hostId);
    var data = await fetchData();
    setState(() {
      eventData = data;
    });
}
  String uid = FirebaseAuth.instance.currentUser!.uid;
  final bool _isButtonClicked = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Expanded(
                  child: FutureBuilder<List<EventInfo>>(
                      future: fetchData(), // define your future method here
                      builder: (BuildContext context, AsyncSnapshot snapshot) {
                        // assuming your data is stored in snapshot.data
                        // List<EventInfo> eventData = [];
                        List<EventInfo> eventData=<EventInfo>[];
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
                                            Text(
                                              "Looking to play ${eventData[index].sport}",
                                              style: const TextStyle(
                                                color: Colors.grey,
                                                fontSize: 12.0,
                                              ),
                                            ),
                                            const SizedBox(height: 4.0),
                                            Text(
                                              'Currently ${eventData[index].players} available',
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
                                            _delete(eventData[index].eventId, eventData[index].hostId)


                                          },


                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: !_isButtonClicked ? const Color(0xFF5A75FF):const Color(0xFFFFFFFF),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10.0),
                                            ),
                                          ),
                                          child: const Padding(
                                            padding: EdgeInsets.symmetric(vertical: 12.0),
                                            child: Text(
                                              'Delete',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 12.0,
                                              ),
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
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterOption(String option, {bool isSelected = false}) {
    return ElevatedButton(
      onPressed: () {
        // Implement the filtering logic here when needed
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.blue : null,
      ),
      child: Text(
        option,
        style: TextStyle(
          color: isSelected ? Colors.white : null,
        ),
      ),
    );
  }

  void _showPeopleJoinedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: contentBox(context),
        );
      },
    );
  }

  contentBox(context) {
    return Stack(
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(top: 16),
          decoration: BoxDecoration(
            shape: BoxShape.rectangle,
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Colors.black,
                offset: Offset(0, 10),
                blurRadius: 10,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text(
                'People Joined This Event',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 15),
              const ListTile(
                title: Text('Name: Aryan'),
                subtitle: Text('Gender: Male'),
              ),
              // Add more sample data as needed
              const SizedBox(height: 22),
              Align(
                alignment: Alignment.bottomRight,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                  ),
                  child: const Text(
                    'Close',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}