
import 'dart:collection';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:fittl/Modals/Community.dart';
import 'package:fittl/Modals/UserPreference.dart';
import 'package:fittl/Modals/UserProfile.dart';
import 'package:flutter/cupertino.dart';
import '../Modals/EventInfo.dart';
import '../Modals/PublicProfile.dart';
import '../Modals/Requests.dart';
import '../Modals/ExploreUsers.dart';
import 'package:http/http.dart' as http;


class DatabaseService extends ChangeNotifier{
  final String uid;

  DatabaseService({required this.uid});

  final CollectionReference userData = FirebaseFirestore.instance.collection(
      'user-profile');
  final CollectionReference events = FirebaseFirestore.instance.collection(
      'events');
  final CollectionReference requests = FirebaseFirestore.instance.collection(
      'requests');
  final CollectionReference connection = FirebaseFirestore.instance.collection(
      'connection');
  final CollectionReference communities = FirebaseFirestore.instance.collection(
      'communities');
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future updateUserProfile(String username, String firstName, String lastName, GeoPoint location,
      DateTime dob, String profileURL, String gender) async {
    await userData.doc(uid).set({
      'username': username,
      'firstName': firstName,
      'lastName': lastName,
      'location': location,
      'dateOfBirth': dob,
      'profileURL': profileURL,
      'gender': gender
    });
  }

  Future<UserProfile> getUserProfile(String uid) async {
    var profileDoc = await FirebaseFirestore.instance.collection('user-profile')
        .doc(uid)
        .get();
    Map<String, dynamic>? userMap = profileDoc.data();
    UserProfile profile = UserProfile(
        username: userMap!['username'],
        firstName: userMap['firstName'],
        lastName: userMap['lastName'],
        dateOfBirth: userMap['dateOfBirth'].toDate(),
        location: userMap['location'],
        profilePicture: userMap['profileURL'],
        gender: userMap['gender'],
        userId: uid
    );
    //log('user: $profile');
    return profile;
  }

  Future<PublicProfile> getPublicProfile(String userId) async {
    var profileDoc = await FirebaseFirestore.instance.collection('user-profile')
        .doc(userId)
        .get();
    var friendStatus = await checkFriendStatus(userId);
    Map<String, dynamic>? userMap = profileDoc.data();
    var communities = await getOwnedCommunities(userId);

    PublicProfile publicProfile = PublicProfile(
        userId: userId,
        username: userMap!['username'],
        firstName: userMap!['firstName'],
        lastName: userMap!['lastName'],
        friendStatus: friendStatus,
        gender: userMap['gender'],
        profilePicture: userMap['profileURL'],
        communities: communities
    );
    //log('user: $profile');
    return publicProfile;
  }
  
  Future<List<UserProfile>> getUsers() async {
    var userSnapshot = await FirebaseFirestore.instance.collection('user-profile')
        .get();
    //log('list: ${userSnapshot.docs[0].data()!['firstName']}');
    List<UserProfile> users = [];
    for(var user in userSnapshot.docs){
      var userId = user.id;
      Map<String, dynamic>? userMap = user.data();
      //log('id: ${user.data()!['dateOfBirth']}');
      if(userId != uid){
      UserProfile userProfile = UserProfile(userId:userId,
          username: userMap['username'],
          firstName: userMap['firstName'],
          lastName: userMap['lastName'],
          dateOfBirth: userMap['dateOfBirth'].toDate(),
          location: userMap['location'],
          profilePicture: userMap['profileURL']);
      //log('user: $userProfile');
        users.add(userProfile);

      }
    }
    return users;
  }

  Future<void> addPreference(double distance, List<String> sports) async{

    //creating preference
    UserPreference preference = UserPreference(distance: distance, sports: sports);


    //adding to database
    await _firestore
        .collection('user-preferences')
        .doc(uid)
        .set(preference.userPreferenceToMap());

  }


  Future<UserPreference> getPreference() async {
    try {
      var preferenceDoc = await _firestore
          .collection('user-preferences')
          .doc(uid)
          .get();

      if (preferenceDoc.exists) {
        var preferenceMap = preferenceDoc.data();

        if (preferenceMap != null) {
          UserPreference userPreference = UserPreference(
            distance: preferenceMap['distance'],
            sports: preferenceMap['sports'],
          );

          return userPreference;
        } else {
          // Handle the case where preferenceMap is null (empty document)
          // You can choose to return a default preference or throw an error.
          return UserPreference(distance: 0, sports: []); // Default preference
        }
      } else {
        // Handle the case where the document doesn't exist
        // You can choose to return a default preference or throw an error.
        return UserPreference(distance: 0, sports: []); // Default preference
      }
    } catch (e) {
      // Handle any potential exceptions that might occur during the data retrieval
      print("Error getting user preferences: $e");
      // You can choose to return a default preference or throw an error.
      return UserPreference(distance: 0, sports: []); // Default preference
    }
  }


  Future<List<ExploreUsers>> exploreConnections(String userId) async{
    List<UserProfile> users= await getUsers();
    //log('bool: $users');
    var connectionDoc = await FirebaseFirestore.instance.collection('connection').doc(userId).get();

    // Create a new connection document if it doesn't exist
    if (!connectionDoc.exists) {
      await FirebaseFirestore.instance.collection('connection').doc(userId).set({
        'friends': [],
        'sentRequests': [],
        'receivedRequests': [],
      });
      connectionDoc = await FirebaseFirestore.instance.collection('connection').doc(userId).get();
    }
    List<dynamic> friends = List.from(connectionDoc.data()!['friends'] ?? []);
    List<dynamic> sentRequest = List.from(connectionDoc.data()!['sentRequests'] ?? []);
    List<dynamic> receivedRequest = List.from(connectionDoc.data()!['receivedRequests'] ?? []);

    var friendsSet = HashSet.from(friends);
    var sentRequestSet = HashSet.from(sentRequest);
    var receivedRequestSet = HashSet.from(receivedRequest);
    //log('bool: ${sentRequestSet}');
    List<ExploreUsers> exploreUsers = [];

    for(var user in users){
      bool friendCheck = false;
      bool sentReqCheck = false;
      bool receivedReqCheck = false;

      if(friendsSet.contains(user.userId)) {
        friendCheck = true;
      }
      else if(sentRequestSet.contains(user.userId)){
        sentReqCheck = true;
      }else if(receivedRequestSet.contains(user.userId)){
        receivedReqCheck = true;
      }
      else{}

      ExploreUsers eu = ExploreUsers(userId: user.userId!, firstName: user.firstName, lastName: user.lastName,
                        profilePicture: user.profilePicture, friends: friendCheck, receivedRequest: receivedReqCheck,
                        sentRequest: sentReqCheck);
      exploreUsers.add(eu);
      //log('users: ${eu}');

    }

    return exploreUsers;

  }



  Future<void> deleteEvent(String eventId, String hostId) async{
    await _firestore.collection('events').doc(eventId).delete();

    var snapRec = await _firestore.collection('event-notifications').doc(hostId).collection('receivedRequests').where('eventId', isEqualTo:eventId).get();
    for(var s in snapRec.docs){
      await _firestore.collection('event-notifications').doc(hostId).collection('receivedRequests').doc(s.id).delete();
    }
    var snapAcc = await _firestore.collection('event-notifications').doc(hostId).collection('acceptedRequests').where('eventId', isEqualTo:eventId).get();
    for(var s in snapAcc.docs){
      await _firestore.collection('event-notifications').doc(hostId).collection('acceptedRequests').doc(s.id).delete();
    }


  }



  Future addEventToUser(String eventId) async {
    var profileDoc = await FirebaseFirestore.instance.collection('user-profile')
        .doc(uid)
        .get();
    Map<String, dynamic>? userMap = profileDoc.data();
    List<dynamic> events;
    if (userMap!['eventsHosted'] == null) {
      events = [eventId];
    }
    else {
      events = userMap['eventsHosted'];
      events.add(eventId);
    }
    await userData.doc(uid).update({
      'eventsHosted': events
    });
  }



  Future addEvent(String sport, GeoPoint location, DateTime dateTime,
      int players, double duration) async {
    List<String> playersJoined = [];
    String eventId = '${DateTime
        .now()
        .millisecondsSinceEpoch}';
    await events.doc(eventId).set({
      'hostId': uid,
      'sport': sport,
      'location': location,
      'date_time': dateTime,
      'players': players,
      'duration': duration,
      'playersJoined':playersJoined
    }
    );
    await addEventToUser(eventId);
  }



  Future updateEvent(String playerId, String eventId) async {

    var eventDoc = await FirebaseFirestore.instance.collection('events')
        .doc(eventId)
        .get();
    Map<String, dynamic>? eventMap = eventDoc.data();
    //var playersJoined = eventMap!['playersJoined'];

    List<dynamic> playersJoined;
    if (eventMap!['playersJoined'] == null) {
      playersJoined = [playerId];
    }
    else {
      playersJoined = eventMap['playersJoined'];
      playersJoined.add(playerId);
    }

    var players = eventMap['players'];
    await events.doc(eventId).update({
      'playersJoined' : playersJoined,
      'players':players-1
    });

  }

  Future<List<EventInfo>> getJoinedEvents(String userId) async {
    var eventSnapshot = await FirebaseFirestore.instance.collection('events')
        .where('playersJoined', arrayContains: userId)
        .orderBy('date_time', descending: false)
        .get();


    List<EventInfo> events = [];
    for (var event in eventSnapshot.docs) {

      String hostId = event.data()['hostId'];
      int players= event.data()['players'];

      UserProfile userProfile = await getUserProfile(hostId);
      EventInfo eventInfo = EventInfo(eventId: event.id,
          url: userProfile.profilePicture!,
          userFirstName: userProfile.firstName,
          username: userProfile.username,
          sport: event.data()['sport'],
          date_time: event.data()['date_time'].toDate(),
          duration: event.data()['duration'],
          players: event.data()['players'],
          location: event.data()['location'],
          hostId: userProfile.userId!
      );
      eventInfo.getAddress();
      events.add(eventInfo);
      //log('data: $eventInfo');

    }

    return events;

  }


  Future<List<EventInfo>> getEventsByHostId(String userId) async {
    var eventSnapshot = await FirebaseFirestore.instance.collection('events')
        .where('hostId', isEqualTo:userId)
        .orderBy('date_time', descending: true)
        .get();


    List<EventInfo> events = [];
    for (var event in eventSnapshot.docs) {

      String hostId = event.data()['hostId'];
      int players= event.data()['players'];

        UserProfile userProfile = await getUserProfile(hostId);
        EventInfo eventInfo = EventInfo(eventId: event.id,
            url: userProfile.profilePicture!,
            userFirstName: userProfile.firstName,
            username: userProfile.username,
            sport: event.data()['sport'],
            date_time: event.data()['date_time'].toDate(),
            duration: event.data()['duration'],
            players: event.data()['players'],
            location: event.data()['location'],
            hostId: userProfile.userId!
        );
        eventInfo.getAddress();
        events.add(eventInfo);
        //log('data: $eventInfo');

    }

    return events;

  }

  Future<List<String>> getSentRequests() async {
    List<String> sentRequests = [];
    var reqSnapshot = await _firestore.collection('event-notifications').doc(uid).collection('sentRequests').get();
    for(var req in reqSnapshot.docs){
      sentRequests.add(req.id);
    }
    return sentRequests;
  }


  Future<List<EventInfo>> getEvent(bool distanceSort) async {

    var preference = await getPreference();
    QuerySnapshot<Map<String, dynamic>> eventSnapshot;
    if(preference.sports.isNotEmpty){
      eventSnapshot = await FirebaseFirestore.instance.collection('events')
          .orderBy('date_time', descending: false).where('sports',whereIn: preference.sports)
          .get();
    }
    else{
      eventSnapshot = await FirebaseFirestore.instance.collection('events')
          .orderBy('date_time', descending: false)
          .get();
    }

    if(preference.distance==0) preference.distance = double.infinity;


    List<EventInfo> events = [];
    GeoPoint myLocation = (await getUserProfile(uid)).location;
    for (var event in eventSnapshot.docs) {

      String hostId = event.data()['hostId'];
      int players= event.data()['players'];
      var playersJoined = event.data()['playersJoined'];
      var sentRequests = await getSentRequests();
      playersJoined ??= [];
      var distance =getDistance(myLocation.latitude,myLocation.longitude,  event.data()['location'].latitude, event.data()['location'].longitude);
      if(hostId!=uid && players>0 && !playersJoined.contains(uid) && !sentRequests.contains(event.id) && distance <= preference.distance) {

        UserProfile userProfile = await getUserProfile(hostId);
        EventInfo eventInfo = EventInfo(eventId: event.id,
            url: userProfile.profilePicture!,
            userFirstName: userProfile.firstName,
            username: userProfile.username,
            sport: event.data()['sport'],
            date_time: event.data()['date_time'].toDate(),
            duration: event.data()['duration'],
            players: event.data()['players'],
            location: event.data()['location'],
            hostId: userProfile.userId!
        );
        eventInfo.getAddress();


        //var distance = await calculateDistance(myLocation, event.data()['location']);
        eventInfo.distance = distance;
        events.add(eventInfo);
      }
    }
    if(distanceSort) {
      events.sort((a, b) => a.distance!.compareTo(b.distance!));
    } else {
      //events.sort((a, b) => a.date_time!.compareTo(b.date_time!));
    }



    return events;
  }
  double getDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Earth radius in kilometers

    // Convert latitude and longitude from degrees to radians
    double lat1Rad = _degreesToRadians(lat1);
    double lon1Rad = _degreesToRadians(lon1);
    double lat2Rad = _degreesToRadians(lat2);
    double lon2Rad = _degreesToRadians(lon2);

    // Calculate the change in coordinates
    double dLat = lat2Rad - lat1Rad;
    double dLon = lon2Rad - lon1Rad;

    // Apply Haversine formula
    double a = pow(sin(dLat / 2), 2) +
        cos(lat1Rad) * cos(lat2Rad) * pow(sin(dLon / 2), 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    double distance = earthRadius * c; // Distance in kilometers

    return distance;
  }

  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }


  Future<double> calculateDistance(GeoPoint g1, GeoPoint g2) async {
    double distance = 0;
    String apiUrl = "https://maps.googleapis.com/maps/api/distancematrix/json?"
        "origins=${g1.latitude},${g1.longitude}&"
        "destinations=${g2.latitude},${g2.longitude}&"
        "key=AIzaSyBQ2hIN6nTS5FKQzWAZcmX3jNF_ItGj2OA";

    var response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      var data = json.decode(response.body);

      var dist = data['rows'][0]['elements'][0]['distance']['value']; // Distance in meters
      distance = dist.toDouble() / 1000.0; // Convert meters to kilometers and store in EventInfo object

    } else {
      // Handle error
      print("Error fetching distance: ${response.statusCode}");
    }
    return distance;
  }

  Stream<QuerySnapshot> getEventsSnapshotByHostId(String userId){

    return _firestore
        .collection('events')
        .where('hostId', isEqualTo:userId)
        .orderBy('date_time', descending: true)
        .snapshots();

  }


  Future<EventInfo> getEventById(String eventId) async {
    var eventDoc = await FirebaseFirestore.instance.collection('events').doc(
        eventId).get();
    Map<String, dynamic>? eventMap = eventDoc.data();
    UserProfile host = await getUserProfile(eventMap!['hostId']);
    EventInfo eventInfo = EventInfo(eventId: eventId,
        url: host.profilePicture!,
        userFirstName: host.firstName,
        username: host.username,
        sport: eventMap['sport'],
        date_time: eventMap['date_time'].toDate(),
        duration: eventMap['duration'],
        players: eventMap['players'],
        location: eventMap['location'],
        hostId: host.userId!
    );

    return eventInfo;
  }



  Future<String> getHostByEventId(String eventId) async {
    var eventDoc = await FirebaseFirestore.instance.collection('events').doc(
        eventId).get();
    Map<String, dynamic>? eventMap = eventDoc.data();
    return eventMap!['hostId'];
  }



  Future createRequest(String uid, String activityId, bool isAccepted) async {
    String reqId = 'request${DateTime
        .now()
        .millisecondsSinceEpoch}';
    await requests.doc(reqId).set({
      'userId': uid,
      'activityId': activityId,
      'isAccepted': isAccepted,
    }
    );
  }


  Future<List<Requests>> getRequests() async {
    var reqSnapshot = await FirebaseFirestore.instance.collection('requests')
        .get();
    final reqData = reqSnapshot.docs.map((doc) => doc.data()).toList();
    List<Requests> requestList = [];
    for (var req in reqSnapshot.docs) {
      String eventId = req.data()['activityId'];
      String userId = req.data()['userId'];
      bool isAccepted = req.data()['isAccepted'];
      UserProfile userProfile = await getUserProfile(userId);
      EventInfo eventInfo = await getEventById(eventId);
      String hostId = await getHostByEventId(eventId);
      if (hostId == uid && isAccepted==false) {
        Requests requests = Requests(
            requestId: req.id, eventId: eventId, userId: userId, isAccepted: isAccepted, user: userProfile, event: eventInfo);
        requestList.add(requests);
      }
    }
    return requestList;
  }


  Future<Requests> getRequestById(String requestId) async {
    var reqDoc = await FirebaseFirestore.instance.collection('requests').doc(
        requestId).get();
    Map<String, dynamic>? reqMap = reqDoc.data();
    UserProfile userProfile = await getUserProfile(reqMap!['userId']);
    EventInfo eventInfo = await getEventById(reqMap['eventId']);

    Requests request = Requests(requestId: requestId, eventId: reqMap['eventId'],
        userId: reqMap['userId'], isAccepted: reqMap['isAccepted'], user: userProfile, event: eventInfo);

    return request;
  }



  Future acceptRequest(String userId, String activityId, String requestId) async{


    await requests.doc(requestId).update({
      'isAccepted':true
    });
    await updateEvent(userId, activityId);

  }
  Future rejectRequest(String requestId) async{

    await requests.doc(requestId).delete();

  }


  Future sendFriendRequest(String senderId, String receiverId) async{

    var senderConnectionDoc = await FirebaseFirestore.instance.collection('connection').doc(senderId).get();
    var receiverConnectionDoc = await FirebaseFirestore.instance.collection('connection').doc(receiverId).get();

    Map<String, dynamic>? senderConnectionMap = senderConnectionDoc.data();

    Map<String, dynamic>? receiverConnectionMap = receiverConnectionDoc.data();

    List<dynamic> senderSentRequests = List.from(senderConnectionMap?['sentRequests'] ?? []);
    List<dynamic> senderReceivedRequests = List.from(senderConnectionMap?['receivedRequests'] ?? []);
    List<dynamic> senderFriends = List.from(senderConnectionMap?['friends'] ?? []);
    List<dynamic> receiverReceivedRequests = List.from(receiverConnectionMap?['receivedRequests'] ?? []);
    List<dynamic> receiverSentRequests = List.from(receiverConnectionMap?['sentRequests'] ?? []);
    List<dynamic> receiverFriends = List.from(receiverConnectionMap?['friends'] ?? []);

    senderSentRequests.add(receiverId);
    receiverReceivedRequests.add(senderId);

    await connection.doc(senderId).set({
      'sentRequests' : senderSentRequests,
      'receivedRequests': senderReceivedRequests,
      'friends': senderFriends,
    });

    await connection.doc(receiverId).set({
      'sentRequests': receiverSentRequests,
      'receivedRequests' : receiverReceivedRequests,
      'friends': receiverFriends,
    });
    
  }

  Future unsendFriendRequest(String senderId, String receiverId) async{

    var senderConnectionDoc = await FirebaseFirestore.instance.collection('connection').doc(senderId).get();
    var receiverConnectionDoc = await FirebaseFirestore.instance.collection('connection').doc(receiverId).get();

    Map<String, dynamic>? senderConnectionMap = senderConnectionDoc.data();

    Map<String, dynamic>? receiverConnectionMap = receiverConnectionDoc.data();

    List<dynamic> senderSentRequests = List.from(senderConnectionMap?['sentRequests'] ?? []);
    List<dynamic> receiverReceivedRequests = List.from(receiverConnectionMap?['receivedRequests'] ?? []);

    if(senderSentRequests.contains(receiverId)) {
      senderSentRequests.remove(receiverId);
    }
    if(receiverReceivedRequests.contains(senderId)) {
      receiverReceivedRequests.remove(senderId);
    }

    await connection.doc(senderId).update({
      'sentRequests' : senderSentRequests,
    });

    await connection.doc(receiverId).update({
      'receivedRequests' : receiverReceivedRequests,
    });

  }



  Future acceptFriendRequest(String senderId, String receiverId) async{

    var senderConnectionDoc = await FirebaseFirestore.instance.collection('connection').doc(senderId).get();
    var receiverConnectionDoc = await FirebaseFirestore.instance.collection('connection').doc(receiverId).get();

    Map<String, dynamic>? senderConnectionMap = senderConnectionDoc.data();
    Map<String, dynamic>? receiverConnectionMap = receiverConnectionDoc.data();

    List<dynamic> senderSentRequests = senderConnectionMap?['sentRequests'];
    List<dynamic> receiverReceivedRequests = receiverConnectionMap?['receivedRequests'];

    List<dynamic> senderFriends = senderConnectionMap?['friends'];
    List<dynamic> receiverFriends = receiverConnectionMap?['friends'];

    senderSentRequests.remove(receiverId);
    receiverReceivedRequests.remove(senderId);
    
    senderFriends.add(receiverId);
    receiverFriends.add(senderId);

    await connection.doc(senderId).update({
      'sentRequests' : senderSentRequests,
      'friends' : senderFriends,
    });

    await connection.doc(receiverId).update({
      'receivedRequests' : receiverReceivedRequests,
      'friends':receiverFriends,
    });
    
  }


  Future rejectFriendRequest(String senderId, String receiverId) async{

    var senderConnectionDoc = await FirebaseFirestore.instance.collection('connection').doc(senderId).get();
    var receiverConnectionDoc = await FirebaseFirestore.instance.collection('connection').doc(receiverId).get();

    Map<String, dynamic>? senderConnectionMap = senderConnectionDoc.data();
    Map<String, dynamic>? receiverConnectionMap = receiverConnectionDoc.data();

    List<dynamic> senderSentRequests = senderConnectionMap?['sentRequests'];
    List<dynamic> receiverReceivedRequests = receiverConnectionMap?['receivedRequests'];

    senderSentRequests.remove(receiverId);
    receiverReceivedRequests.remove(senderId);


    await connection.doc(senderId).update({
      'sentRequests' : senderSentRequests,      
    });

    await connection.doc(receiverId).update({
      'receivedRequests' : receiverReceivedRequests,
    });
    
  }

  Future<String> checkFriendStatus(String userId) async{
    var connectionDoc = await FirebaseFirestore.instance.collection('connection').doc(uid).get();
    var friends = List.from(connectionDoc.data()!['friends'] ?? []);
    var receivedRequests = List.from(connectionDoc.data()!['receivedRequests'] ?? []);
    var sentRequests = List.from(connectionDoc.data()!['sentRequests'] ?? []);

    if(friends.contains(userId)) return 'friends';
    if(receivedRequests.contains(userId)) return 'received';
    if(sentRequests.contains(userId)) return 'sent';
    return 'addFriend';
  }


  Future<List> getFriends(String userId) async{

    var connectionDoc = await FirebaseFirestore.instance.collection('connection').doc(userId).get();
    var friends = List.from(connectionDoc.data()!['friends'] ?? []);
    //log('$friends');

    return friends;

  }

  Future<Stream<QuerySnapshot>> getFriendsSnapshot() async {
    List<dynamic> friends = await getFriends(uid);
    if(friends.isEmpty) friends = [""];
    return FirebaseFirestore.instance.collection('user-profile')
        .where(FieldPath.documentId, whereIn: friends)
        .snapshots();
  }

  Future<List> getChatRooms(String userId) async{

    var connectionSnapshot = await FirebaseFirestore.instance.collection('chats')
        .get();


    List<String> documentIds = [];
    //log('id-${connectionSnapshot.docs}');
    for (var doc in connectionSnapshot.docs) {
      var temp = (doc.id).split('-');

      if(temp.contains(uid)){
        temp.remove(uid);
        documentIds.add(temp.first);
      }

    }

    return documentIds;

  }

  Future<Stream<QuerySnapshot<Object?>>> getChatList() async {

    var chatRooms = await getChatRooms(uid);
    return FirebaseFirestore.instance.collection('user-profile')
        .where(FieldPath.documentId, whereIn: chatRooms)
        .snapshots();
  }



  //creates a new community
  Future<String> createCommunity(String communityName, String ownerId, String communityDescription, List<String> tags, File displayPicture) async{

    String communityId = 'community$ownerId${DateTime
        .now()
        .millisecondsSinceEpoch}';
    String url="";
    final fileName = '${DateTime.now().millisecondsSinceEpoch}';
    Reference ref = FirebaseStorage.instance.ref();
    Reference refDir = ref.child('communityDP');
    Reference refImg = refDir.child(fileName);

    try{

      await refImg.putFile(displayPicture);
      url = await refImg.getDownloadURL();

    }catch(e){
      print(e);
    }

    List<String> members = [];
    await communities.doc(communityId).set({
      'communityName': communityName,
      'communityDescription': communityDescription,
      'tags': tags,
      'ownerId':ownerId,
      'members': members,
      'dateCreated':DateTime.now(),
      'displayPicture': url

    }
    );
    //adding community id to the user table with owner access
    addCommunityToUser(communityId, ownerId, true);
    return communityId;

  }

  /*
  adds the community id to user-profile table
  if user is the owner of the community then the id is stored in ownedCommunities
  if user is a member of the community then the id is stored in joinedCommunities
  */
  Future addCommunityToUser(String communityId, String userId, bool owner) async{

    var userDoc = await FirebaseFirestore.instance.collection('user-profile')
        .doc(userId)
        .get();
    Map<String, dynamic>? userMap = userDoc.data();

    List<dynamic> ownedCommunities = List.from(userMap?['ownedCommunities'] ?? []);
    List<dynamic> joinedCommunities = List.from(userMap?['joinedCommunities'] ?? []);

    if(owner){
      ownedCommunities.add(communityId);
      await userData.doc(userId).update({
        'ownedCommunities' : ownedCommunities,
      });
    }
    else{
      joinedCommunities.add(communityId);
      await userData.doc(userId).update({
        'joinedCommunities' : joinedCommunities,
      });
    }
  }

  Future<Community> getCommunityById(String id) async{
    var communityDoc = await FirebaseFirestore.instance.collection('communities')
        .doc(id)
        .get();
    var communityMap = communityDoc.data();
    //log('message $communityDoc');
    //log('message ${communityMap!['tags']}');

    Community c = Community(
        communityId: id,
        communityName: communityMap!['communityName'],
        communityDescription: communityMap['communityDescription'],
        displayPicture: communityMap['displayPicture'],
        dateCreated: communityMap['dateCreated'].toDate(),
        ownerId: communityMap['ownerId'],
        members: communityMap['members'].cast<String>(),
        tags: communityMap['tags'].cast<String>()
    );

    return c;
  }



  //Owned communities
  Future<List<Community>> getOwnedCommunities(String userId) async{
    var userDoc = await FirebaseFirestore.instance.collection('user-profile').doc(userId).get();
    List<Community> communityList = [];
    var ownedCommunities = userDoc.data()!['ownedCommunities'];
    if(ownedCommunities!=null){
      for(var data in ownedCommunities){

        Community c = await getCommunityById(data);
        communityList.add(c);
      }
    }
    return communityList;
  }

  //already joined communities
  Future<List<Community>> getJoinedCommunities() async{
    var userDoc = await FirebaseFirestore.instance.collection('user-profile').doc(uid).get();
    List<Community> communityList = [];
    var joinedCommunities = userDoc.data()!['joinedCommunities'];
    if(joinedCommunities!=null){
      for(var data in joinedCommunities){
        Community c = await getCommunityById(data);
        communityList.add(c);
      }
    }
    return communityList;
  }

  //Exploring all communities (except for already joined ones)
  Future<List<Community>> exploreCommunities() async{
    var userDoc = await FirebaseFirestore.instance.collection('user-profile').doc(uid).get();

    //Set to store community id of already joined/owned communities
    Set<String> myCommunities = <String>{};
    var joinedCommunities = userDoc.data()!['joinedCommunities'];
    var ownedCommunities = userDoc.data()!['ownedCommunities'];
    if(joinedCommunities!=null) {
      myCommunities.addAll(List<String>.from(joinedCommunities));
    }
    if(ownedCommunities!=null) {
      myCommunities.addAll(List<String>.from(ownedCommunities));
    }

    List<Community> communityList = [];
    var communitySnapshot = await FirebaseFirestore.instance.collection('communities').get();

    for(var community in communitySnapshot.docs){
      var communityId = community.id;
      //if(!myCommunities.contains(communityId)){
        var communityMap = community.data();
        Community c = Community(
            communityId: communityId,
            communityName: communityMap['communityName'],
            communityDescription: communityMap['communityDescription'],
            displayPicture: communityMap['displayPicture'],
            dateCreated: communityMap['dateCreated'].toDate(),
            ownerId: communityMap['ownerId'],
            members: communityMap['members'].cast<String>(),
            tags: communityMap['tags'].cast<String>()
        );
        communityList.add(c);
      }
    //}

    return communityList;
  }





}
