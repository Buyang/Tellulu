import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

class CloudStorageService {
  static final CloudStorageService _instance = CloudStorageService._internal();

  factory CloudStorageService() {
    return _instance;
  }

  CloudStorageService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- SYNC ON LOGIN ---

  /// Downloads all cloud data and merges it into local Hive boxes.
  /// Strategy: Last Write Wins (Cloud overwrites Local if ID exists).
  Future<String> transformCloudToLocal(Box storiesBox, Box castBox, Box settingsBox) async {
    final sb = StringBuffer();
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint('☁️ CloudSync: No user logged in. Skipping download.');
      return "Not logged in";
    }

    // [NEW] Process Offline Queue BEFORE downloading to avoid overwriting our own offline work
    await processSyncQueue();

    final uid = user.uid;
    sb.writeln('☁️ Sync for $uid...');
    debugPrint('☁️ CloudSync: Starting sync for user $uid...');

    try {
      // 1. Sync Stories
      final storiesSnapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('stories')
          .get();
      
      int storiesCount = 0;
      for (var doc in storiesSnapshot.docs) {
        final data = doc.data();
        final id = doc.id;
        // Ensure ID is consistent
        data['id'] = id; 
        
        bool fetchSuccess = true;
        
        // Fetch Pages Sub-collection
        try {
            final pagesSnapshot = await doc.reference.collection('pages').get();
            if (pagesSnapshot.docs.isNotEmpty) {
                 // Map both data AND id to allow sorting
                 final pagesList = pagesSnapshot.docs.map((p) => {
                    ...p.data(),
                    '_params_docId': p.id // Internal helper key
                 }).toList();
                 
                 // Sort by 'page_X' index
                 pagesList.sort((a, b) {
                     final idA = a['_params_docId'] as String;
                     final idB = b['_params_docId'] as String;
                     // Extract integer from 'page_X'
                     final idxA = int.tryParse(idA.split('_').last) ?? 999;
                     final idxB = int.tryParse(idB.split('_').last) ?? 999;
                     return idxA.compareTo(idxB);
                 });
                 
                 // Clean up helper key
                 for (var p in pagesList) { p.remove('_params_docId'); }
                 
                 data['pages'] = pagesList;
            }
        } catch (e) {
            debugPrint('⚠️ CloudSync: Failed to fetch pages for story $id: $e');
            fetchSuccess = false; // Mark as failed
        }

        if (fetchSuccess) {
           await storiesBox.put(id, data);
           storiesCount++;
        } else {
           debugPrint('⚠️ CloudSync: Skipping local update for $id due to partial fetch failure.');
           sb.writeln('❌ Skipped ${data['title']} (Fetch Failed)');
        }
      }
      debugPrint('☁️ CloudSync: Synced $storiesCount stories.');
      sb.writeln('✅ Checked ${storiesSnapshot.docs.length} cloud stories.');

      sb.writeln('✅ Synced $storiesCount stories locally.');

      // 2. Sync Cast
      final castSnapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('cast')
          .get();

      int castCount = 0;
      // Atomic merge: collect all data first, then clear and write once
      final castData = castSnapshot.docs.map((doc) => doc.data()).toList();
      castCount = castData.length;
      if (castCount > 0) {
         await castBox.clear(); 
         for (final data in castData) {
            await castBox.add(data);
         }
      }
      sb.writeln('✅ Synced $castCount cast members.');

      // 3. Sync Settings
      final settingsSnapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('settings')
          .get();
          
      for (var doc in settingsSnapshot.docs) {
         await settingsBox.put(doc.id, doc.data()['value']);
      }
      
      return sb.toString();

    } catch (e) {
      debugPrint('⚠️ CloudSync Error: $e');
      return "❌ Sync Failed: $e";
    }
  }

  // --- OFFLINE QUEUE ---

  Future<Box> _getQueueBox() async {
      final user = _auth.currentUser;
      if (user == null) throw Exception("No user");
      return await Hive.openBox('tellulu_sync_queue_${user.uid}');
  }

  Future<void> processSyncQueue() async {
     try {
        final user = _auth.currentUser;
        if (user == null) return;
        
        final box = await _getQueueBox();
        if (box.isEmpty) return;

        debugPrint('🔄 CloudSync: Processing ${box.length} offline items...');
        
        final keysToDelete = <dynamic>[];
        
        for (var i = 0; i < box.length; i++) {
            final key = box.keyAt(i);
            final item = box.getAt(i) as Map;
            
            try {
                if (item['action'] == 'upload_story') {
                    await uploadStory(Map<String,dynamic>.from(item['data']), isRetry: true);
                } else if (item['action'] == 'delete_story') {
                    await deleteStory(item['id'], isRetry: true);
                }
                keysToDelete.add(key);
            } catch (e) {
                debugPrint('⚠️ CloudSync: Queue item failed again: $e');
                // Keep in queue?
            }
        }
        
        await box.deleteAll(keysToDelete);
        debugPrint('✅ CloudSync: Processed ${keysToDelete.length} queue items.');
        
     } catch (e) {
         debugPrint('⚠️ CloudSync: Queue processing error: $e');
     }
  }

  // Debug Tool
  Future<String> inspectCloudData() async {
     final user = _auth.currentUser;
     if (user == null) return "No user logged in.";
     
     final sb = StringBuffer();
     sb.writeln("🕵️ CLOUD INSPECTOR REPORT");
     sb.writeln("User: ${user.uid.substring(0,6)}...");
     
     try {
        final stories = await _firestore.collection('users').doc(user.uid).collection('stories').get();
        sb.writeln("Found ${stories.docs.length} Stories:");
        
        for (var doc in stories.docs) {
           final title = doc.data()['title'] ?? 'Untitled';
           final pages = await doc.reference.collection('pages').get();
           sb.writeln("- '$title' (ID: ${doc.id.substring(0,4)}...): ${pages.docs.length} Pages");
        }
        
     } catch(e) {
        sb.writeln("Error inspecting: $e");
     }
     
     return sb.toString();
  }

  // --- REAL-TIME UPLOADS ---

  Future<void> uploadStory(Map<String, dynamic> story, {bool isRetry = false}) async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    try {
      final id = story['id'] as String;
      
      // DEEP CLONE to avoid modifying local object
      final storyData = Map<String, dynamic>.from(story);
      
      // Extract Pages to avoid 1MB Limit
      List<dynamic>? pages;
      if (storyData.containsKey('pages')) {
        pages = List<dynamic>.from(storyData['pages'] as List);
        storyData.remove('pages'); // Remove from main doc
      }

      // 1. Upload Main Story Metadata/Cover
      final storyRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('stories')
          .doc(id);
          
      await storyRef.set(storyData);
      debugPrint('☁️ Uploaded Story Metadata: $id');
      
      // 2. Upload Pages to Sub-collection
      if (pages != null && pages.isNotEmpty) {
          final pagesRef = storyRef.collection('pages');
          final batch = _firestore.batch();
          
          // Delete existing pages first (simple sync)? Or just overwrite by index?
          // Let's overwrite safely
          for (int i = 0; i < pages.length; i++) {
             final pageData = Map<String, dynamic>.from(pages[i] as Map);
             final pageDoc = pagesRef.doc('page_$i'); // Deterministic ID
             batch.set(pageDoc, pageData);
          }
          await batch.commit();
          debugPrint('☁️ Uploaded ${pages.length} Pages for Story: $id');
      }

    } catch (e) {
      debugPrint('⚠️ Upload Story Failed: $e');
      if (!isRetry) {
          // [NEW] Queue for Offline Support
          try {
             final box = await _getQueueBox();
             await box.add({
                 'action': 'upload_story',
                 'data': story,
                 'timestamp': DateTime.now().millisecondsSinceEpoch
             });
             debugPrint('📥 Added to Offline Queue');
          } catch (qError) {
             debugPrint('💀 Failed to queue offline item: $qError');
          }
      } else {
          // Re-throw if it's a retry so we don't clear from queue ??
          // No, processSyncQueue swallows errors to keep it in queue.
          throw Exception("Retry failed");
      }
    }
  }

  Future<void> deleteStory(String id, {bool isRetry = false}) async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('stories')
          .doc(id)
          .delete();
      debugPrint('☁️ Deleted Cloud Story: $id');
    } catch (e) {
      debugPrint('⚠️ Delete Cloud Story Failed: $e');
      if (!isRetry) {
          try {
             final box = await _getQueueBox();
             await box.add({
                 'action': 'delete_story',
                 'id': id,
                 'timestamp': DateTime.now().millisecondsSinceEpoch
             });
             debugPrint('📥 Added Delete to Offline Queue');
          } catch (qError) {
             debugPrint('💀 Failed to queue offline item: $qError');
          }
      } else {
         throw Exception("Retry failed");
      }
    }
  }

  Future<void> uploadCast(List<Map<String, dynamic>> castList) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // For Cast, it's a list. Hard to sync individual items.
      // Strategy: Delete all cloud cast, re-upload all. (Inefficient but simple for V1)
      final batch = _firestore.batch();
      final castRef = _firestore.collection('users').doc(user.uid).collection('cast');
      
      // 1. Get all current docs to delete
      final existing = await castRef.get();
      for (var doc in existing.docs) {
        batch.delete(doc.reference);
      }
      
      // 2. Add new docs
      for (var member in castList) {
        final newDoc = castRef.doc(); // Auto ID
        batch.set(newDoc, member);
      }
      
      await batch.commit();
      debugPrint('☁️ Uploaded Cast Library (${castList.length} items)');
    } catch (e) {
      debugPrint('⚠️ Upload Cast Failed: $e');
    }
  }

  Future<void> uploadSetting(String key, dynamic value) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('settings')
          .doc(key)
          .set({'value': value});
      debugPrint('☁️ Uploaded Setting: $key');
    } catch (e) {
      debugPrint('⚠️ Upload Setting Failed: $e');
    }
  }

  // --- DATA RESCUE ---

  Future<String> rescueCast(Box castBox) async {
    final user = _auth.currentUser;
    if (user == null) return "Error: No user logged in.";

    final sb = StringBuffer();
    sb.writeln("🔍 Rescue Log for User: ${user.uid.substring(0, 5)}...");
    
    int rescuedCount = 0;
    try {
      final castRef = _firestore.collection('users').doc(user.uid).collection('cast');
      final castSnapshot = await castRef.get(); // [FIX] Use ref for clarity

      sb.writeln("☁️ Cloud Items Found: ${castSnapshot.docs.length}");

      if (castSnapshot.docs.isEmpty) {
        return "${sb.toString()}\n❌ No data found in Cloud Storage.";
      }

      // We don't want to wipe local if Cloud is empty/broken.
      // We only want to MERGE better data.
      
      final localMap = <String, Map>{};
      for (var i = 0; i < castBox.length; i++) {
        final item = castBox.getAt(i) as Map?;
        if (item != null) {
           final name = item['name'] as String?;
           if (name != null) localMap[name] = Map<String, dynamic>.from(item);
        }
      }

      for (var doc in castSnapshot.docs) {
        final cloudData = doc.data();
        final name = cloudData['name'] as String?;
        if (name == null) {
           sb.writeln("⚠️ Skipped item with no name.");
           continue;
        }

        bool isBetter = false;
        String reason = "";
        
        final localData = localMap[name];

        if (localData == null) {
           isBetter = true;
           reason = "Missing locally";
        } else if (cloudData['imageBase64'] != null && localData['imageBase64'] == null) {
           isBetter = true;
           reason = "Recovering lost image";
        } else {
           reason = "Local version exists & has image";
        }

        if (isBetter) {
          localMap[name] = cloudData;
          rescuedCount++;
          sb.writeln("✅ RESCUED '$name': $reason");
        } else {
          sb.writeln("⏺️ Skipped '$name': $reason");
        }
      }

      if (rescuedCount > 0) {
        await castBox.clear();
        for (var item in localMap.values) {
          await castBox.add(item);
        }
        sb.writeln("\n🎉 Successfully rescued $rescuedCount characters!");
      } else {
        sb.writeln("\n✅ No rescues needed. Local data is up to date.");
      }
      
    } catch (e) {
      sb.writeln("❌ Rescue Failed: $e");
      debugPrint('⚠️ Rescue Failed: $e');
    }
    return sb.toString();
  }
}
