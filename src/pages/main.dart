import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';
import 'package:http/http.dart';
import 'package:kmed_app/get_it.dart';
import 'package:kmed_app/models/agora/agora_token_response.dart';
import 'package:kmed_app/models/chat/call_message.dart';
import 'package:kmed_app/models/chat/chat_room.dart';
import 'package:kmed_app/models/chat/chat_user.dart';
import 'package:kmed_app/models/chat/message.dart';
import 'package:kmed_app/models/notification/send_notification_request.dart';
import 'package:kmed_app/networks/firebase_types.dart';
import 'package:kmed_app/repositories/data_repository.dart';

class APIs {
  // for authentication
  static FirebaseAuth auth = FirebaseAuth.instance;

  // for accessing cloud firestore database
  static FirebaseFirestore firestore = FirebaseFirestore.instance;

  // for accessing firebase storage
  static FirebaseStorage storage = FirebaseStorage.instance;

  // for storing self information
  static ChatUser me = ChatUser(
      id: user.uid,
      name: user.displayName.toString(),
      email: user.email.toString(),
      about: "Hey, I'm using We Chat!",
      image: user.photoURL.toString(),
      createdAt: '',
      isOnline: false,
      lastActive: '',
      role: '',
      pushToken: '');

  // to return current user
  static User get user => auth.currentUser!;

  // for accessing firebase messaging (Push Notification)
  static FirebaseMessaging fMessaging = FirebaseMessaging.instance;

  // for getting firebase messaging token
  static Future<void> getFirebaseMessagingToken() async {
    await fMessaging.requestPermission();
    await fMessaging.getToken().then((t) {
      if (t != null) {
        me.pushToken = t;
        log('Push Token: $t');
      }
    });

    // for handling foreground messages
    // FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    //   log('Got a message whilst in the foreground!');
    //   log('Message data: ${message.data}');

    //   if (message.notification != null) {
    //     log('Message also contained a notification: ${message.notification}');
    //   }
    // });
  }

  static Future<String?> getFirebaseToken() async {
    await fMessaging.requestPermission();

    final fcmToken = await fMessaging.getToken();
    return fcmToken;
  }

  static Future<void> logoutFirebase() async {
    await fMessaging.deleteToken();
    await firestore
        .collection('users')
        .doc(user.uid)
        .update({"push_token": null});
  }

  static Future<void> updateFirebaseToken() async {
    if (auth.currentUser != null) {
      await fMessaging.getToken().then((t) async {
        if (t != null) {
          print("firebaseToken $t ");
          await firestore
              .collection('users')
              .doc(user.uid)
              .set({"push_token": t}, SetOptions(merge: true));
        }
      });
    }
  }

  // for sending push notification
  static Future<void> sendPushNotification(
      ChatUser chatUser, String msg) async {
    try {
      final body = {
        "to": chatUser.pushToken,
        "notification": {
          "title": me.name, //our name should be send
          "body": msg,
          "android_channel_id": "chats"
        },
        // "data": {
        //   "some_data": "User ID: ${me.id}",
        // },
      };
      final notification = {
        "title": me.name, //our name should be send
        "body": msg,
        "android_channel_id": "chats"
      };
      await sendFirebaseMessaging(chatUser.email, notification, null);
    } catch (e) {
      log('\nsendPushNotificationE: $e');
    }
  }

  static Future<void> sendCallNotification(
      ChatUser chatUser, CallMessage callJsonData) async {
    try {
      final body = {
        "to": chatUser.pushToken,
        "notification": {
          "title": "Cuộc gọi đến", //our name should be send
          "body": callJsonData.requestUser.name,
          "android_channel_id": "callkit_incoming_channel_id"
        },
        "data": callJsonData.toJson(),
      };
      final notification = {
        "title": "Cuộc gọi đến", //our name should be send
        "body": callJsonData.requestUser.name,
        "android_channel_id": "callkit_incoming_channel_id"
      };
      final data = callJsonData.toJson();
      sendFirebaseMessaging(chatUser.email, notification, data);
    } catch (e) {
      log('\nsendPushNotificationE: $e');
    }
  }

  static Future<void> sendEndCallNotification(
      ChatUser chatUser, CallMessage callJsonData) async {
    try {
      // final body = {
      //   "to": chatUser.pushToken,
      //   "notification": {
      //     "title": "Cuộc cuộc gọi bị huỷ", //our name should be send
      //     "body": callJsonData.requestUser.name,
      //     "android_channel_id": "video_call"
      //   },
      //   "data": callJsonData.toJson(),
      // };
      final notification = {
        "title": "Cuộc cuộc gọi bị huỷ", //our name should be send
        "body": callJsonData.requestUser.name,
        "android_channel_id": "callkit_missed_channel_id"
      };
      final data = callJsonData.toJson();
      sendFirebaseMessaging(chatUser.email, notification, data);
    } catch (e) {
      log('\nsendPushNotificationE: $e');
    }
  }

  static Future<void> sendFirebaseMessaging(
    String email,
    Map<String, dynamic>? data,
    Map<String, dynamic>? notification,
  ) async {
    final _dataRepository = getIt<DataRepository>();
    // var res = await post(Uri.parse('https://fcm.googleapis.com/fcm/send'),
    //     headers: {
    //       HttpHeaders.contentTypeHeader: 'application/json',
    //       HttpHeaders.authorizationHeader:
    //           'key=AAAAyguiJuU:APA91bGsPl4QTX8daVErKtWAfciHAqhYHc78PK4oLX-0B9rvcuZ7u1MXevObvmJ70l8AiE1UZmEqAP91Q11Y4OMIO7bvEIITs0Lz0I7vAigJlH80GutkQeVvH0hRLzVjMrcziGa7yxM0'
    //     },
    //     body: jsonEncode(body));
    // log('Response status: ${res.statusCode}');
    // log('Response body: ${res.body}');

    await _dataRepository.sendNotification(
        sendNotificationRequest: SendNotificationRequest(
            email: email, notification: data, data: notification));
  }

  // for checking if user exists or not?
  static Future<bool> userExists() async {
    return (await firestore.collection('users').doc(user.uid).get()).exists;
  }

  // for adding an chat user for our conversation
  static Future<bool> addChatUser(String email) async {
    final data = await firestore
        .collection('users')
        .where('email', isEqualTo: email)
        .get();

    log('data: ${data.docs}');

    if (data.docs.isNotEmpty && data.docs.first.id != user.uid) {
      //user exists

      log('user exists: ${data.docs.first.data()}');

      firestore
          .collection('users')
          .doc(user.uid)
          .collection('my_users')
          .doc(data.docs.first.id)
          .set({});

      return true;
    } else {
      //user doesn't exists

      return false;
    }
  }

  // for getting current user info
  static Future<void> getSelfInfo() async {
    await firestore.collection('users').doc(user.uid).get().then((user) async {
      if (user.exists) {
        me = ChatUser.fromJson(user.data()!);
        await getFirebaseMessagingToken();

        //for setting user status to active
        APIs.updateActiveStatus(true);
        log('My Data: ${user.data()}');
      } else {
        await createUser().then((value) => getSelfInfo());
      }
    });
  }

  // for creating a new user
  static Future<void> createUser() async {
    final time = DateTime.now().millisecondsSinceEpoch.toString();

    final chatUser = ChatUser(
        id: user.uid,
        name: user.displayName.toString(),
        email: user.email.toString(),
        about: "Hey, I'm using We Chat!",
        image: user.photoURL.toString(),
        createdAt: time,
        isOnline: false,
        lastActive: time,
        role: '',
        pushToken: '');

    return await firestore
        .collection('users')
        .doc(user.uid)
        .set(chatUser.toJson());
  }

  // for getting id's of known users from firestore database
  static Stream<QuerySnapshot<Map<String, dynamic>>> getMyUsersId() {
    // log('${firestore.collection('users').doc(user.uid).collection('my_users').snapshots()}');

    return firestore
        .collection('users')
        .doc(user.uid)
        .collection('my_users')
        .snapshots();
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> getMyUsersIsOnline() {
    return firestore
        .collection('users')
        .where('is_online', isEqualTo: true)
        // .where('role', isEqualTo: MedicalType.doctors)
        .snapshots();
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> getDoctorsIsOnline() {
    return firestore
        .collection('users')
        .where('id', isNotEqualTo: user.uid)
        .where('is_online', isEqualTo: true)
        .where('role', isEqualTo: MedicalType.doctors)
        .snapshots();
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>>
      getDoctorsIsOnlineByDePartment({required int id}) {
    return firestore
        .collection('users')
        .where('is_online', isEqualTo: true)
        .where('role', isEqualTo: MedicalType.doctors)
        .where('departmentId', isEqualTo: id)
        .snapshots();
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> getPharmacistIsOnline() {
    return firestore
        .collection('users')
        .where('id', isNotEqualTo: user.uid)
        .where('is_online', isEqualTo: true)
        .where('role', isEqualTo: MedicalType.pharmacist)
        .snapshots();
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> getClinicsIsOnline() {
    return firestore
        .collection('users')
        .where('id', isNotEqualTo: user.uid)
        .where('is_online', isEqualTo: true)
        .where('role', isEqualTo: BusinessType.clinics)
        .snapshots();
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> getHospitalsIsOnline() {
    return firestore
        .collection('users')
        .where('id', isNotEqualTo: user.uid)
        .where('is_online', isEqualTo: true)
        .where('role', isEqualTo: BusinessType.hospitals)
        .snapshots();
  }

  static Future<ChatUser> getUserByEmail({String? email}) async {
    final userData = await firestore
        .collection('users')
        .where('email', isEqualTo: email)
        .get();
    ChatUser chatUser = ChatUser.fromJson(userData.docs.first.data());
    return chatUser;
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> getDoctorByEmail(
      {String? email}) {
    return firestore
        .collection('users')
        .where('email', isEqualTo: email)
        .snapshots();
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> getDoctorByEmailOnline(
      {String? email}) {
    return firestore
        .collection('users')
        .where('email', isEqualTo: email)
        .where('is_online', isEqualTo: true)
        .snapshots();
  }

  // for getting all users from firestore database
  static Stream<QuerySnapshot<Map<String, dynamic>>> getAllUsers(
      List<String> userIds) {
    log('\nUserIds: $userIds');

    userIds.remove(user.uid);
    return firestore
        .collection('users')
        .where('id',
            whereIn: userIds.isEmpty
                ? ['']
                : userIds) //because empty list throws an error
        // .where('id', isNotEqualTo: user.uid)
        .snapshots();
  }

  // for adding an user to my user when first message is send
  static Future<void> sendFirstMessage(
      ChatUser chatUser, String msg, Type type) async {
    await firestore
        .collection('users')
        .doc(user.uid)
        .collection('my_users')
        .doc(chatUser.id)
        .set({});
    await firestore
        .collection('users')
        .doc(chatUser.id)
        .collection('my_users')
        .doc(user.uid)
        .set({}).then((value) => sendMessage(chatUser, msg, type));
  }

  // for updating user information
  static Future<void> updateUserInfo() async {
    await firestore.collection('users').doc(user.uid).update({
      'name': me.name,
      'about': me.about,
    });
  }

  // update profile picture of user
  static Future<void> updateProfilePicture(File file) async {
    //getting image file extension
    final ext = file.path.split('.').last;
    log('Extension: $ext');

    //storage file ref with path
    final ref = storage.ref().child('profile_pictures/${user.uid}.$ext');

    //uploading image
    await ref
        .putFile(file, SettableMetadata(contentType: 'image/$ext'))
        .then((p0) {
      log('Data Transferred: ${p0.bytesTransferred / 1000} kb');
    });

    //updating image in firestore database
    me.image = await ref.getDownloadURL();
    await firestore
        .collection('users')
        .doc(user.uid)
        .update({'image': me.image});
  }

  // for getting specific user info
  static Stream<QuerySnapshot<Map<String, dynamic>>> getUserInfo(
      String chatUserId) {
    return firestore
        .collection('users')
        .where('id', isEqualTo: chatUserId)
        .snapshots();
  }

  // update online or last active status of user
  static Future<void> updateActiveStatus(bool isOnline) async {
    firestore.collection('users').doc(user.uid).update({
      'is_online': isOnline,
      'last_active': DateTime.now().millisecondsSinceEpoch.toString(),
    });
  }

  ///************** Chat Screen Related APIs **************

  // chats (collection) --> conversation_id (doc) --> messages (collection) --> message (doc)

  // useful for getting conversation id
  static String getConversationID(String id) => user.uid.hashCode <= id.hashCode
      ? '${user.uid}_$id'
      : '${id}_${user.uid}';

  static String getAgoraChannelName(String requestEmail, String recieveEmail) {
    List<String> emails = [requestEmail, recieveEmail];
    emails.sort();
    String channelName = emails.join('_');

    return channelName;
  }

  // for getting all messages of a specific conversation from firestore database
  static Stream<QuerySnapshot<Map<String, dynamic>>> getAllMessages(
      ChatUser user) {
    return firestore
        .collection('chats/${getConversationID(user.id)}/messages/')
        .orderBy('sent', descending: true)
        .snapshots();
  }

  // for sending message
  static Future<void> sendMessage(
      ChatUser chatUser, String msg, Type type) async {
    //message sending time (also used as id)
    final time = DateTime.now().millisecondsSinceEpoch.toString();
    final reciverId = chatUser.id;
    //message to send
    final Message message = Message(
        toId: reciverId,
        msg: msg,
        read: '',
        type: type,
        fromId: user.uid,
        readUsers: {user.uid: true, reciverId: false},
        sent: time);

    final ref = firestore
        .collection('chats/${getConversationID(chatUser.id)}/messages/');
    await ref.doc(time).set(message.toJson()).then((value) =>
        sendPushNotification(chatUser, type == Type.text ? msg : 'image'));

    await updateLastMessage(chatUser, message);
  }

  static String _getTypeFromString(String typeString) {
    if (typeString == Type.normalCall.name) {
      return "voice_call";
    } else if (typeString == Type.normalVideoCall.name) {
      return "video_call";
    } else if (typeString == Type.cancelCall.name) {
      return "voice_call";
    } else if (typeString == Type.cancelVideoCall.name) {
      return "video_call";
    }
    return "";
  }

  //update read status of message
  static Future<void> updateMessageReadStatus(Message message) async {
    firestore
        .collection('chats/${getConversationID(message.fromId)}/messages/')
        .doc(message.sent)
        .update({'read': DateTime.now().millisecondsSinceEpoch.toString()});
  }

  //get only last message of a specific chat
  static Stream<QuerySnapshot<Map<String, dynamic>>> getLastMessage(
      ChatUser user) {
    return firestore
        .collection('chats/${getConversationID(user.id)}/messages/')
        .orderBy('sent', descending: true)
        .limit(1)
        .snapshots();
  }

  //send chat image
  static Future<void> sendChatImage(ChatUser chatUser, File file) async {
    //getting image file extension
    final ext = file.path.split('.').last;

    //storage file ref with path
    final ref = storage.ref().child(
        'images/${getConversationID(chatUser.id)}/${DateTime.now().millisecondsSinceEpoch}.$ext');

    //uploading image
    await ref
        .putFile(file, SettableMetadata(contentType: 'image/$ext'))
        .then((p0) {
      log('Data Transferred: ${p0.bytesTransferred / 1000} kb');
    });

    //updating image in firestore database
    final imageUrl = await ref.getDownloadURL();
    await sendMessage(chatUser, imageUrl, Type.image);
  }

  //delete message
  static Future<void> deleteMessage(Message message) async {
    await firestore
        .collection('chats/${getConversationID(message.toId)}/messages/')
        .doc(message.sent)
        .delete();

    if (message.type == Type.image) {
      await storage.refFromURL(message.msg).delete();
    }
  }

  //update message
  static Future<void> updateMessage(Message message, String updatedMsg) async {
    await firestore
        .collection('chats/${getConversationID(message.toId)}/messages/')
        .doc(message.sent)
        .update({'msg': updatedMsg});
  }

  //count unread message
  static Future<void> countUnreadMessages(
      ChatUser chatUser, Message message) async {
    // await firestore
    //     .collection('chats/${getConversationID(message.fromId)}/messages/')
    //     .where('fromId', isEqualTo: user.id)
    //     .where('read', isEqualTo: '')
    //     .get();
    final roomRef =
        firestore.collection("chats").doc(getConversationID(chatUser.id));
    final messagesRef = roomRef.collection("messages");
    final Map<String, dynamic>? roomData =
        await roomRef.get().then((value) => value.data());
    if (roomData != null) {
      final roomJson = ChatRoom.fromJson(roomData);
      final unreadUserId =
          roomJson.lastMessage?.fromId == chatUser.id ? user.uid : chatUser.id;

      final unreadCount = await messagesRef
          .where("readUsers.$unreadUserId", isEqualTo: false)
          .get()
          .then((value) => value.docs.length);
      roomRef.set({
        "unreadMessageCount": {user.uid: 0, unreadUserId: unreadCount}
      }, SetOptions(merge: true));
    }
  }

  static Future<void> initialChatRoom(ChatUser user) async {
    final currentChatRoom = await APIs.getChatGroup(user);
    final targetChannelType = user.role;
    final myChannelType = (APIs.me.role != MedicalType.pharmacist &&
            APIs.me.role != MedicalType.doctors &&
            APIs.me.role != BusinessType.clinics &&
            APIs.me.role != BusinessType.hospitals)
        ? user.role
        : APIs.me.role;
    if (currentChatRoom == null) {
      final chatRoomInfo = ChatRoom(
          userIds: [APIs.user.uid, user.id],
          groupId: APIs.getConversationID(user.id),
          createdBy: APIs.user.uid,
          unreadMessageCount: {APIs.user.uid: 0, user.id: 0},
          createdAt: DateTime.now().millisecondsSinceEpoch.toString(),
          channelTypes: [
            "${APIs.user.uid}_$targetChannelType",
            "${user.id}_$myChannelType"
          ]);
      APIs.createChatRoom(user, chatRoomInfo);
    }
  }

  static Future<void> createChatRoom(
      ChatUser chatUser, ChatRoom chatRoom) async {
    await firestore
        .collection('chats')
        .doc(getConversationID(chatUser.id))
        .set(chatRoom.toJson(), SetOptions(merge: true));
  }

  static Future<ChatRoom?> getChatGroup(ChatUser chatUser) async {
    final Map<String, dynamic>? snapshot = await firestore
        .collection('chats')
        .doc(getConversationID(chatUser.id))
        .get()
        .then((value) => value.data());
    print("snapshotsnapshot ${snapshot}");

    if (snapshot != null) {
      return ChatRoom.fromJson(snapshot);
    }
    return null;
  }

  static Future<void> updateLastMessage(
      ChatUser chatUser, Message lastMessage) async {
    final callType = _getTypeFromString(lastMessage.type.name);
    Message updatedMessage = Message.fromJson(lastMessage.toJson());
    if (callType.isNotEmpty) {
      updatedMessage.msg = callType;
    }

    await firestore
        .collection('chats')
        .doc(getConversationID(chatUser.id))
        .set({"lastMessage": updatedMessage.toJson()}, SetOptions(merge: true));
    await countUnreadMessages(chatUser, updatedMessage);
  }

  static Future<void> updateStatusForEachMessage(ChatUser chatUser) async {
    final roomRef =
        firestore.collection('chats').doc(getConversationID(chatUser.id));
    roomRef.update({"lastMessage.readUsers.${user.uid}": true});
    final messagesRef = roomRef.collection('messages');
    final listMessageNeedUpdate = await messagesRef
        .where("readUsers.${user.uid}", isEqualTo: false)
        .get();

    final batch = firestore.batch();
    for (var item in listMessageNeedUpdate.docs) {
      DocumentReference messageRef = messagesRef.doc(item.id);

      batch.set(
          messageRef,
          {
            'readUsers': {user.uid: true}
          },
          SetOptions(merge: true));
    }

    await batch.commit();
    await removeBadgeCount(chatUser);
  }

  static Future<void> removeBadgeCount(ChatUser chatUser) async {
    final roomRef =
        firestore.collection('chats').doc(getConversationID(chatUser.id));
    await roomRef.set({
      "unreadMessageCount": {user.uid: 0}
    }, SetOptions(merge: true));
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> getAllUnReadMessage() {
    if (auth.currentUser != null) {
      final unReadChatGroup = firestore
          .collection('chats')
          .where("unreadMessageCount.${user.uid}", isGreaterThan: 0)
          .snapshots();
      return unReadChatGroup;
    } else {
      return const Stream.empty();
    }
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> getAllDoctor() {
    if (auth.currentUser != null) {
      final doctorListQuery = firestore
          .collection('users')
          .where('id', isNotEqualTo: user.uid)
          .where('role', isEqualTo: MedicalType.doctors)
          .snapshots();
      return doctorListQuery;
    } else {
      return const Stream.empty();
    }
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> getAllPharmacist() {
    if (auth.currentUser != null) {
      final doctorListQuery = firestore
          .collection('users')
          .where('id', isNotEqualTo: user.uid)
          .where('role', isEqualTo: MedicalType.pharmacist)
          .snapshots();
      return doctorListQuery;
    } else {
      return const Stream.empty();
    }
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> getAllClinics() {
    if (auth.currentUser != null) {
      final doctorListQuery = firestore
          .collection('users')
          .where('id', isNotEqualTo: user.uid)
          .where('role', isEqualTo: BusinessType.clinics)
          .snapshots();
      return doctorListQuery;
    } else {
      return const Stream.empty();
    }
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> getAllHospitals() {
    if (auth.currentUser != null) {
      final doctorListQuery = firestore
          .collection('users')
          .where('id', isNotEqualTo: user.uid)
          .where('role', isEqualTo: BusinessType.hospitals)
          .snapshots();
      return doctorListQuery;
    } else {
      return const Stream.empty();
    }
  }

  static Future<ChatUser> getOnceUserInfo(String userId) async {
    final Map<String, dynamic>? snapshot = await firestore
        .collection('users')
        .doc(userId)
        .get()
        .then((value) => value.data());
    return ChatUser.fromJson(snapshot!);
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>>
      getAllChatRoomWithDoctor() {
    if (auth.currentUser != null) {
      final doctorChatListQuery = firestore
          .collection('chats')
          .where('channelTypes', arrayContains: '${user.uid}_DOCTORS')
          .orderBy('lastMessage.sent', descending: true)
          .snapshots();
      // doctorChatListQuery.forEach((element) {
      // print("doctorChatListQuery ${element.docs}");});
      return doctorChatListQuery;
    } else {
      return const Stream.empty();
    }
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>>
      getAllChatRoomWithPharmacist() {
    if (auth.currentUser != null) {
      final pharmacistChatListQuery = firestore
          .collection('chats')
          .where('channelTypes',
              arrayContains: '${user.uid}_${MedicalType.pharmacist}')
          .orderBy('lastMessage.sent', descending: true)
          .snapshots();
      return pharmacistChatListQuery;
    } else {
      return const Stream.empty();
    }
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>>
      getAllChatRoomWithClinics() {
    if (auth.currentUser != null) {
      final pharmacistChatListQuery = firestore
          .collection('chats')
          .where('channelTypes',
              arrayContains: '${user.uid}_${BusinessType.clinics}')
          .orderBy('lastMessage.sent', descending: true)
          .snapshots();
      return pharmacistChatListQuery;
    } else {
      return const Stream.empty();
    }
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>>
      getAllChatRoomWithHospitals() {
    if (auth.currentUser != null) {
      final pharmacistChatListQuery = firestore
          .collection('chats')
          .where('channelTypes',
              arrayContains: '${user.uid}_${BusinessType.hospitals}')
          .orderBy('lastMessage.sent', descending: true)
          .snapshots();
      return pharmacistChatListQuery;
    } else {
      return const Stream.empty();
    }
  }

  static Future<void> removeAllGroupChat() async {
    if (auth.currentUser != null) {
      final collectionRef = firestore.collection('chats');

      final snapshot = await collectionRef.get();

      snapshot.docs.forEach((element) async {
        collectionRef.doc(element.id).delete();
        // if (element.data().isEmpty) {
        //   collectionRef.doc(element.id).delete();
        // }
        // final messagesRef =
        //     collectionRef.doc(element.id).collection('messages');

        // await messagesRef.get().then((value) {
        //   if (value.docs.isEmpty) {
        //     collectionRef.doc(element.id).delete();
        //   }
        // });
      });
    } else {}
  }

  static Future<AgoraTempToken> getAgoraToken(
    String email_1,
    String email_2,
  ) async {
    final _dataRepository = getIt<DataRepository>();
    final tempTokenResponse =
        await _dataRepository.getAgoraToken(email_1: email_1, email_2: email_2);
    return tempTokenResponse;
  }
}
