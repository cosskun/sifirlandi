import 'dart:async';
import 'dart:math';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/counter_profile.dart';
import '../models/reset_entry.dart';
import 'firebase_config.dart';

class FirebaseService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static String? _cachedUserId;
  static String? _cachedDisplayName;

  static const String _userNameKey = "shared_user_display_name";
  static const String _mockRoomsKey = "mock_firebase_rooms";

  // Returns true if Firebase is configured
  static bool get isConfigured => FirebaseConfig.isValid;

  // Get current user ID
  static String get userId {
    if (_cachedUserId != null) return _cachedUserId!;
    return "guest_user_local";
  }

  // Get current display name
  static String get displayName {
    if (_cachedDisplayName != null) return _cachedDisplayName!;
    return "Misafir";
  }

  // Initializes auth session (anonymous sign-in or mock local)
  static Future<void> initializeAuth() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load cached display name or generate a random one
    String savedName = prefs.getString(_userNameKey) ?? "";
    if (savedName.isEmpty) {
      final rand = Random().nextInt(9000) + 1000;
      savedName = "Misafir#$rand";
      await prefs.setString(_userNameKey, savedName);
    }
    _cachedDisplayName = savedName;

    if (isConfigured) {
      try {
        final credential = await FirebaseAuth.instance.signInAnonymously();
        _cachedUserId = credential.user?.uid;
        // Optionally update display name in Firebase if supported
      } catch (e) {
        debugPrint("Firebase Auth Error: $e. Falling back to Local Guest ID.");
        _cachedUserId = "guest_${Random().nextInt(100000)}";
      }
    } else {
      _cachedUserId = "guest_${Random().nextInt(100000)}";
    }
  }

  // Update visible nickname
  static Future<void> updateDisplayName(String newName) async {
    final clean = newName.trim();
    if (clean.isEmpty) return;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userNameKey, clean);
    _cachedDisplayName = clean;

    // In a real app we'd also update the Firestore member lists or auth profile
    if (isConfigured && FirebaseAuth.instance.currentUser != null) {
      try {
        // Trigger a background run to update member names across user's counters
        final uid = userId;
        final rooms = await _db.collection('rooms').where('members.$uid', isNotEqualTo: null).get();
        final batch = _db.batch();
        for (var doc in rooms.docs) {
          batch.update(doc.reference, {'memberNames.$uid': clean});
        }
        await batch.commit();
      } catch (e) {
        debugPrint("Error updating display name in Firestore: $e");
      }
    }
  }

  // Generates 6-digit uppercase alphanumeric room code
  static String _generateRoomCode() {
    const chars = "ABCDEFGHJKLMNOPQRSTUVWXYZ23456789"; // Removed ambiguous characters
    final rand = Random();
    return List.generate(6, (index) => chars[rand.nextInt(chars.length)]).join();
  }

  // 1. Create a multiplayer room
  static Future<CounterProfile> createSharedRoom(String name, String title, String category, String emoji) async {
    final roomCode = _generateRoomCode();
    final uid = userId;
    final dName = displayName;

    final CounterProfile room = CounterProfile(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      title: title,
      category: category,
      avatarEmoji: emoji,
      longestStreakSeconds: 0,
      resets: [],
      isShared: true,
      roomCode: roomCode,
      creatorId: uid,
      members: {uid: 'admin'},
      memberNames: {uid: dName},
    );

    if (isConfigured) {
      await _db.collection('rooms').doc(roomCode).set(room.toMap());
    } else {
      // Offline simulation: Save to SharedPreferences
      await _saveMockRoomLocally(room);
    }

    return room;
  }

  // 2. Join a multiplayer room by 6-digit code
  static Future<CounterProfile> joinSharedRoom(String roomCode) async {
    final cleanCode = roomCode.trim().toUpperCase();
    final uid = userId;
    final dName = displayName;

    if (isConfigured) {
      final doc = await _db.collection('rooms').doc(cleanCode).get();
      if (!doc.exists) {
        throw Exception("room_not_found");
      }

      final profile = CounterProfile.fromMap(doc.data()!);
      
      // Add member to list if not already present
      final updatedMembers = Map<String, String>.from(profile.members);
      final updatedNames = Map<String, String>.from(profile.memberNames);

      if (!updatedMembers.containsKey(uid)) {
        updatedMembers[uid] = 'viewer'; // Default role is Viewer
        updatedNames[uid] = dName;
        
        await _db.collection('rooms').doc(cleanCode).update({
          'members': updatedMembers,
          'memberNames': updatedNames,
        });
      }

      return profile.copyWith(members: updatedMembers, memberNames: updatedNames);
    } else {
      // Offline simulation: Load local mock rooms
      final list = await _loadMockRoomsLocally();
      final idx = list.indexWhere((p) => p.roomCode == cleanCode);
      if (idx == -1) {
        throw Exception("room_not_found");
      }

      final profile = list[idx];
      final updatedMembers = Map<String, String>.from(profile.members);
      final updatedNames = Map<String, String>.from(profile.memberNames);

      if (!updatedMembers.containsKey(uid)) {
        updatedMembers[uid] = 'viewer';
        updatedNames[uid] = dName;
        final updatedProfile = profile.copyWith(members: updatedMembers, memberNames: updatedNames);
        list[idx] = updatedProfile;
        await _saveMockRoomsList(list);
        return updatedProfile;
      }
      return profile;
    }
  }

  // 3. Reset a shared counter
  static Future<void> resetSharedCounter(CounterProfile room, String note, String roastMessage) async {
    final cleanNote = note.trim().isEmpty ? "Sebep belirtilmedi 🤫" : note.trim();
    
    // Calculate new streak
    final Duration elapsed = room.resets.isEmpty 
        ? Duration.zero 
        : DateTime.now().difference(room.resets.first.timestamp);

    final newReset = ResetEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      note: cleanNote,
      roastMessage: roastMessage,
      durationSincePrevious: elapsed,
    );

    int newLongest = room.longestStreakSeconds;
    if (elapsed.inSeconds > newLongest) {
      newLongest = elapsed.inSeconds;
    }

    final updatedResets = List<ResetEntry>.from(room.resets)..insert(0, newReset);
    final updatedProfile = room.copyWith(
      longestStreakSeconds: newLongest,
      resets: updatedResets,
    );

    if (isConfigured && room.roomCode != null) {
      await _db.collection('rooms').doc(room.roomCode).update({
        'longestStreakSeconds': newLongest,
        'resets': updatedResets.map((r) => r.toMap()).toList(),
      });
    } else if (room.roomCode != null) {
      // Offline mock update
      final list = await _loadMockRoomsLocally();
      final idx = list.indexWhere((p) => p.roomCode == room.roomCode);
      if (idx != -1) {
        list[idx] = updatedProfile;
        await _saveMockRoomsList(list);
      }
    }
  }

  // 4. Update member role
  static Future<void> updateMemberRole(String roomCode, String targetUserId, String newRole) async {
    if (isConfigured) {
      await _db.collection('rooms').doc(roomCode).update({
        'members.$targetUserId': newRole,
      });
    } else {
      final list = await _loadMockRoomsLocally();
      final idx = list.indexWhere((p) => p.roomCode == roomCode);
      if (idx != -1) {
        final profile = list[idx];
        final updatedMembers = Map<String, String>.from(profile.members);
        updatedMembers[targetUserId] = newRole;
        list[idx] = profile.copyWith(members: updatedMembers);
        await _saveMockRoomsList(list);
      }
    }
  }

  // 4b. Remove member (Kick out)
  static Future<void> removeMember(String roomCode, String targetUserId) async {
    if (isConfigured) {
      final docRef = _db.collection('rooms').doc(roomCode);
      final doc = await docRef.get();
      if (doc.exists) {
        final profile = CounterProfile.fromMap(doc.data()!);
        final updatedMembers = Map<String, String>.from(profile.members)..remove(targetUserId);
        final updatedNames = Map<String, String>.from(profile.memberNames)..remove(targetUserId);
        await docRef.update({
          'members': updatedMembers,
          'memberNames': updatedNames,
        });
      }
    } else {
      final list = await _loadMockRoomsLocally();
      final idx = list.indexWhere((p) => p.roomCode == roomCode);
      if (idx != -1) {
        final profile = list[idx];
        final updatedMembers = Map<String, String>.from(profile.members)..remove(targetUserId);
        final updatedNames = Map<String, String>.from(profile.memberNames)..remove(targetUserId);
        list[idx] = profile.copyWith(members: updatedMembers, memberNames: updatedNames);
        await _saveMockRoomsList(list);
      }
    }
  }

  // 5. Delete a room
  static Future<void> deleteSharedRoom(String roomCode) async {
    if (isConfigured) {
      await _db.collection('rooms').doc(roomCode).delete();
    } else {
      final list = await _loadMockRoomsLocally();
      list.removeWhere((p) => p.roomCode == roomCode);
      await _saveMockRoomsList(list);
    }
  }

  // 6. Leave a room
  static Future<void> leaveSharedRoom(String roomCode) async {
    final uid = userId;
    if (isConfigured) {
      final docRef = _db.collection('rooms').doc(roomCode);
      final doc = await docRef.get();
      if (doc.exists) {
        final profile = CounterProfile.fromMap(doc.data()!);
        final updatedMembers = Map<String, String>.from(profile.members)..remove(uid);
        final updatedNames = Map<String, String>.from(profile.memberNames)..remove(uid);
        await docRef.update({
          'members': updatedMembers,
          'memberNames': updatedNames,
        });
      }
    } else {
      final list = await _loadMockRoomsLocally();
      final idx = list.indexWhere((p) => p.roomCode == roomCode);
      if (idx != -1) {
        final profile = list[idx];
        final updatedMembers = Map<String, String>.from(profile.members)..remove(uid);
        final updatedNames = Map<String, String>.from(profile.memberNames)..remove(uid);
        list[idx] = profile.copyWith(members: updatedMembers, memberNames: updatedNames);
        await _saveMockRoomsList(list);
      }
    }
  }

  // 7. Watch single room in real-time
  static Stream<CounterProfile> streamRoom(String roomCode) {
    if (isConfigured) {
      return _db.collection('rooms').doc(roomCode).snapshots().map((snapshot) {
        if (!snapshot.exists) {
          throw Exception("room_deleted");
        }
        return CounterProfile.fromMap(snapshot.data()!);
      });
    } else {
      // Simulate real-time stream using periodic polling for mock database
      return Stream.periodic(const Duration(seconds: 1)).asyncMap((_) async {
        final list = await _loadMockRoomsLocally();
        final idx = list.indexWhere((p) => p.roomCode == roomCode);
        if (idx == -1) {
          throw Exception("room_deleted");
        }
        return list[idx];
      });
    }
  }

  // 8. Watch all shared rooms of current user
  static Stream<List<CounterProfile>> streamSharedRooms() {
    final uid = userId;
    if (isConfigured) {
      // Query Firestore for documents where 'members.<uid>' exists
      return _db
          .collection('rooms')
          .where('members.$uid', isNull: false)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs.map((doc) => CounterProfile.fromMap(doc.data())).toList();
          });
    } else {
      // Offline polling simulator
      return Stream.periodic(const Duration(seconds: 1)).asyncMap((_) async {
        final list = await _loadMockRoomsLocally();
        return list.where((p) => p.members.containsKey(uid)).toList();
      });
    }
  }

  // Offline mock local persistence helpers
  static Future<List<CounterProfile>> _loadMockRoomsLocally() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_mockRoomsKey) ?? [];
    
    // Mock default room if list is empty, just for testing
    if (jsonList.isEmpty) {
      final uid = userId;
      final defaultMock = CounterProfile(
        id: "mock_demo_1",
        name: "Ahmet",
        title: "Espri Yapıp Ortamı Soğutmadığı Süre",
        category: "meeting",
        avatarEmoji: "❄️",
        isShared: true,
        roomCode: "SF-DEMO",
        creatorId: "demo_creator",
        members: {uid: 'editor', 'demo_creator': 'admin'},
        memberNames: {uid: displayName, 'demo_creator': 'Ahmet'},
        resets: [],
      );
      await _saveMockRoomLocally(defaultMock);
      return [defaultMock];
    }
    
    return _loadMockRoomsJson();
  }

  static Future<List<CounterProfile>> _loadMockRoomsJson() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> listStr = prefs.getStringList(_mockRoomsKey) ?? [];
    final List<CounterProfile> list = [];
    for (var s in listStr) {
      try {
        if (s.startsWith('{')) {
          final decoded = jsonDecode(s);
          if (decoded is Map<String, dynamic>) {
            list.add(CounterProfile.fromMap(decoded));
          }
        }
      } catch (_) {}
    }
    
    // Add default mock if empty
    if (list.isEmpty) {
      final uid = userId;
      final defaultMock = CounterProfile(
        id: "mock_demo_1",
        name: "Ahmet",
        title: "Espri Yapıp Ortamı Soğutmadığı Süre",
        category: "meeting",
        avatarEmoji: "❄️",
        isShared: true,
        roomCode: "SF-DEMO",
        creatorId: "demo_creator",
        members: {uid: 'editor', 'demo_creator': 'admin'},
        memberNames: {uid: displayName, 'demo_creator': 'Ahmet'},
        resets: [],
      );
      list.add(defaultMock);
      await _saveMockRoomsList(list);
    }
    return list;
  }

  static Future<void> _saveMockRoomLocally(CounterProfile room) async {
    final list = await _loadMockRoomsJson();
    list.removeWhere((p) => p.roomCode == room.roomCode);
    list.add(room);
    await _saveMockRoomsList(list);
  }

  static Future<void> _saveMockRoomsList(List<CounterProfile> list) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> listStr = list.map((p) => jsonEncode(p.toMap())).toList();
    await prefs.setStringList(_mockRoomsKey, listStr);
  }
}
