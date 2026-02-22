import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart'; // [NEW]
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'cloud_storage_service.dart';

// ...

class StorageService {
  static const String _storiesBoxName = 'tellulu_stories';
      static const String _castBoxName = 'tellulu_cast';

  static final StorageService _instance = StorageService._internal();

  factory StorageService() {
    return _instance;
  }

  StorageService._internal();
  
  bool _initialized = false;
  Completer<void>? _initLock; // [FIX] Prevent concurrent init() calls
  late Box _storiesBox;
  late Box _castBox;
  late Box _settingsBox;
  late Box _historyBox; // [NEW] Phase 3
  
  String? _currentUserId; // Track who we are initialized for

  Future<void> init() async {
    // [FIX] Serialize concurrent init() calls with a lock
    if (_initLock != null) {
      debugPrint('StorageService: init() already in progress. Waiting...');
      await _initLock!.future;
      return;
    }

    // [FIX] Check if user changed. If so, re-init.
    final currentUser = FirebaseAuth.instance.currentUser;
    final newUserId = currentUser?.uid;

    if (_initialized && _currentUserId == newUserId) return; // Already ready for this user

    // Acquire lock
    _initLock = Completer<void>();

    try {
      if (_initialized && _currentUserId != newUserId) {
          // Switching user? Close old boxes.
          debugPrint('StorageService: Switching user from $_currentUserId to $newUserId');
          await _closeBoxes();
      }

      _currentUserId = newUserId;
      
      if (!kIsWeb) {
        await Hive.initFlutter();
      } else {
        try {
          await Hive.initFlutter();
        } catch (e) {
          debugPrint('StorageService: Hive.initFlutter() failed on Web: $e');
        }
      }
      
      // [FIX] User-Scoped Box Names
      String suffix = "";
      if (_currentUserId != null) {
          suffix = "_$_currentUserId";
      }

      final storiesName = "tellulu_stories$suffix";
      final castName = "tellulu_cast$suffix";
      final settingsName = "tellulu_settings$suffix";

      // Open Boxes
      _storiesBox = await Hive.openBox(storiesName);
      _castBox = await Hive.openBox(castName);
      _settingsBox = await Hive.openBox(settingsName);
      
      // [NEW] Version History — open BEFORE migration so _historyBox is ready
      final historyName = "tellulu_history$suffix";
      _historyBox = await Hive.openBox(historyName);
      
      _initialized = true;
      debugPrint('StorageService: Hive Initialized for user: ${_currentUserId ?? "Guest"} (Box: $storiesName)');
      
      // [FIX] Migration from Legacy Global Box to User Box
      if (_currentUserId != null) {
          await _migrateLegacyGlobalToUser();
          
          // [FIX] Process Offline Queue on Startup
          try {
             final cloud = CloudStorageService();
             await cloud.processSyncQueue();
          } catch (e) {
             debugPrint('StorageService: Failed to process offline queue on init: $e');
          }
      } else {
          // Guest mode / Legacy mode -> Auto-migrate from Prefs
          await _autoMigrate();
      }
    } finally {
      // Release lock
      _initLock!.complete();
      _initLock = null;
    }
  }

  Future<void> _closeBoxes() async {
      await _storiesBox.close();
      await _castBox.close();
      await _settingsBox.close();
      await _historyBox.close(); // Close history
      _initialized = false;
  }
  
  // [NEW] Migrate data from "tellulu_stories" (Global) to "tellulu_stories_$uid"
  Future<void> _migrateLegacyGlobalToUser() async {
     // Only run if we haven't done it? 
     // Or check if global box has data and local box is empty?
     // Risk: If I log out and log in, GLOBAL box is still there?
     // We need to KNOW if the data in Global Box belongs to THIS user.
     // In V1, we only had one user. So YES, it belongs to them.
     // Strategy: Move everything, then Clear Global.
     
     if (await Hive.boxExists(_storiesBoxName)) {
         final globalStories = await Hive.openBox(_storiesBoxName);
         if (globalStories.isNotEmpty) {
             debugPrint('📦 StorageService: Found legacy GLOBAL data. Migrating to USER scope...');
             
             // Move Stories
             for (var i = 0; i < globalStories.length; i++) {
                 try {
                   final item = globalStories.getAt(i);
                   if (item is Map) {
                       final id = item['id']; // Assumes ID exists
                       if (id != null && !_storiesBox.containsKey(id)) {
                           await _storiesBox.put(id, item);
                       }
                   }
                 } catch (e) {
                   debugPrint('⚠️ Migration Error (Story $i): $e');
                 }
             }
             // Clear Global
             await globalStories.clear();
             debugPrint('✅ StorageService: Legacy Stories Migrated & Cleared.');
         }
         // Close it
         await globalStories.close();
     }

     if (await Hive.boxExists(_castBoxName)) {
         final globalCast = await Hive.openBox(_castBoxName);
         if (globalCast.isNotEmpty) {
             debugPrint('📦 StorageService: Found legacy CAST data. Migrating...');
             for (var i = 0; i < globalCast.length; i++) {
                 try {
                    final item = globalCast.getAt(i);
                    // Defensive check before add
                    if (item is Map) {
                       await _castBox.add(item);
                    } else {
                       debugPrint('⚠️ StartService: Skipping invalid legacy cast item at $i (Type: ${item.runtimeType})');
                    }
                 } catch (e) {
                    debugPrint('⚠️ Migration Error (Cast $i): $e');
                 }
             }
             await globalCast.clear();
         }
         await globalCast.close();
     }
  }

  Future<void> _autoMigrate() async {
      try {
        final prefs = await SharedPreferences.getInstance();
        
        // 1. Cast Migration
        if (_castBox.isEmpty) {
             final String? castJson = prefs.getString('cast_data');
             if (castJson != null && castJson.length > 5) {
                 debugPrint('StorageService: Found legacy CAST data. Migrating...');
                 await migrateCastFromPrefs(castJson);
             }
        }
        
        // 2. Stories Migration
        if (_storiesBox.isEmpty) {
             final String? storiesJson = prefs.getString('stories_data');
             if (storiesJson != null && storiesJson.length > 5) {
                 debugPrint('StorageService: Found legacy STORIES data. Migrating...');
                 await migrateFromPrefs(storiesJson);
             }
        }
      } catch (e) {
         debugPrint('StorageService: Auto-migration check failed: $e');
      }
  }

  // --- STORIES ---

  Future<List<Map<String, dynamic>>> loadStories() async {
    if (!_initialized) await init();
    
    // Hive stores dynamic keys, typically int indexes if add() is used, or string keys if put() is used.
    // We will store the list as a single JSON blob OR as individual items?
    // Individual items is better for partial corruption protection, but 'stories_data' was a single list.
    // Let's store individual stories by ID for robustness.
    
    final stories = <Map<String, dynamic>>[];
    for (var i = 0; i < _storiesBox.length; i++) {
       final story = _storiesBox.getAt(i);
       if (story != null) {
          try {
             // Hive returns Map<dynamic, dynamic> often, need casting
             if (story is Map) {
                final map = Map<String, dynamic>.from(story);
                stories.add(map);
             }
          } catch (e) {
             debugPrint('Error parsing story at index $i: $e');
          }
       }
    }
    // Sort by date descending (newest first)? 
    // The previous implementation added to top.
    // Let's rely on the order in the box or sort by date if needed.
    // For now, reverse the list to show newest first if we use add().
    return stories.reversed.toList();
  }

  // [NEW] Fetch single story for safe merging
  Map<String, dynamic>? getStory(String id) {
    if (!_initialized) return null; // Should be init
    final data = _storiesBox.get(id);
    if (data != null && data is Map) {
       return Map<String, dynamic>.from(data);
    }
    return null;
  }

  Future<void> saveStory(Map<String, dynamic> story) async {
    if (!_initialized) await init();
    
    final id = story['id'] as String;

    // [NEW] Phase 3: Version History (Safety Net)
    // Before overwriting, save CURRENT version to history
    if (_storiesBox.containsKey(id)) {
        final current = _storiesBox.get(id);
        if (current is Map) {
            await _saveToHistory(id, Map<String, dynamic>.from(current));
        }
    }

    // We use put(id, story) to update or create
    await _storiesBox.put(id, story);
    debugPrint('StorageService: Saved story $id');
    // CLOUD SYNC
    await CloudStorageService().uploadStory(story);
  }

  // [NEW] Phase 3: History Implementation
  Future<void> _saveToHistory(String id, Map<String, dynamic> previousVersion) async {
      try {
         // History Structure: Key = storyId, Value = List<Map> (Versions)
         List<dynamic> history = _historyBox.get(id, defaultValue: []) as List;
         // Clone list to modify
         history = List<dynamic>.from(history);
         
         // Add timestamp to version for debugging
         previousVersion['_snapshot_date'] = DateTime.now().toIso8601String();
         
         // Add to end
         history.add(previousVersion);
         
         // Limit to last 3 versions (FIFO)
         if (history.length > 3) {
             history.removeAt(0);
         }
         
         await _historyBox.put(id, history);
         debugPrint('📜 StorageService: Archived version for $id. History size: ${history.length}');
      } catch (e) {
         debugPrint('⚠️ StorageService: History backup failed: $e');
      }
  }

  Future<bool> restorePreviousVersion(String id) async {
      if (!_initialized) await init();
      
      try {
          final List<dynamic> history = _historyBox.get(id, defaultValue: []) as List;
          if (history.isEmpty) {
              debugPrint('StorageService: No history to restore for $id');
              return false;
          }
          
          final modifiableHistory = List<Map<String,dynamic>>.from(history.map((e) => Map<String,dynamic>.from(e as Map)));
          
          // Pop last version
          final versionToRestore = modifiableHistory.removeLast();
          
          // Save back to main box (Archiving CURRENT state to history? Or just strict undo?)
          // Strict Undo: Pop from history, apply to main.
          // Side effect: The "bad" version is lost forever unless we push it to a "Redo" stack.
          // For safety, let's just Restore.
          
          await _storiesBox.put(id, versionToRestore); // Restores old state
          await _historyBox.put(id, modifiableHistory); // Updates history (removed last item)
          
          // Sync restored version to cloud
          await CloudStorageService().uploadStory(versionToRestore);
          
          debugPrint('✅ StorageService: Restored previous version for $id');
          // Notify listeners? 
          return true;
      } catch (e) {
          debugPrint('⚠️ StorageService: Restore failed: $e');
          return false;
      }
  }

  Future<void> deleteStory(String id) async {
    if (!_initialized) await init();
    await _storiesBox.delete(id);
    debugPrint('StorageService: Deleted story $id');
    // CLOUD SYNC
    await CloudStorageService().deleteStory(id);
  }
  
  // Legacy Migration Helper
  Future<void> migrateFromPrefs(String storiesJson) async {
     if (!_initialized) await init();
     if (_storiesBox.isNotEmpty) return; // Already data in Hive

     try {
       final List<dynamic> list = jsonDecode(storiesJson);
       for (var item in list) {
          final map = Map<String, dynamic>.from(item as Map);
          final id = map['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString();
          map['id'] = id; // Ensure ID exists
          await _storiesBox.put(id, map);
       }
       debugPrint('StorageService: Migrated ${list.length} stories from Prefs.');
     } catch (e) {
       debugPrint('StorageService: Migration failed: $e');
     }
  }

  Future<void> migrateCastFromPrefs(String castJson) async {
     if (!_initialized) await init();
     if (_castBox.isNotEmpty) return; // Already data in Hive

     try {
       final List<dynamic> list = jsonDecode(castJson);
       for (var item in list) {
          final map = Map<String, dynamic>.from(item as Map);
          await _castBox.add(map);
       }
       debugPrint('StorageService: Migrated ${list.length} cast members from Prefs.');
       // Sync to cloud after migration
       await CloudStorageService().uploadCast(await loadCast());
     } catch (e) {
       debugPrint('StorageService: Cast migration failed: $e');
     }
  }

  // --- CAST ---

  Future<List<Map<String, dynamic>>> loadCast() async {
     if (!_initialized) await init();
     
     final cast = <Map<String, dynamic>>[];
      for (var i = 0; i < _castBox.length; i++) {
        try {
           final member = _castBox.getAt(i);
           if (member != null && member is Map) {
              final map = Map<String, dynamic>.from(member);
              
              // Ensure imageBytes are present (Consistency Fix)
              if (map['imageBytes'] == null && map['imageBase64'] != null) {
                  try {
                    map['imageBytes'] = base64Decode(map['imageBase64'] as String);
                  } catch (e) {
                    debugPrint('StorageService: Error decoding image for ${map['name']}: $e');
                  }
              }
               if (map['originalImageBytes'] == null && map['originalImageBase64'] != null) {
                  try {
                    map['originalImageBytes'] = base64Decode(map['originalImageBase64'] as String);
                  } catch (e) {
                    debugPrint('StorageService: Error decoding original image for ${map['name']}: $e');
                  }
              }
              
              // Ensure color is int
              if (map['color'] is String) {
                 map['color'] = int.tryParse(map['color']) ?? 0xFFE0F7FA;
              }

              cast.add(map);
           }
        } catch (e) {
           debugPrint('⚠️ LoadCast Error (Index $i): $e');
        }
    }
    return cast;
  }

  Future<void> saveCast(List<Map<String, dynamic>> castList) async {
    if (!_initialized) await init();
    // Clear and Rewrite Cast list (simple approach)
    await _castBox.clear();
    for (var member in castList) {
       await _castBox.add(member);
    }
    // CLOUD SYNC
    await CloudStorageService().uploadCast(castList);
  }

  // --- SETTINGS ---
  
  dynamic getSetting(String key, {dynamic defaultValue}) {
    if (!_initialized) return defaultValue; // Should init first really
    return _settingsBox.get(key, defaultValue: defaultValue);
  }

  Future<void> saveSetting(String key, dynamic value) async {
    if (!_initialized) await init();
    await _settingsBox.put(key, value);
    // CLOUD SYNC
    await CloudStorageService().uploadSetting(key, value);
  }

  // --- SYNC ---

  // [NEW] Background Sync Notification
  final _syncCompleteController = StreamController<void>.broadcast();
  Stream<void> get onSyncComplete => _syncCompleteController.stream;

  Future<String> syncWithCloud() async {
    if (!_initialized) await init();
    debugPrint('StorageService: Triggering Cloud Sync...');
    final result = await CloudStorageService().transformCloudToLocal(_storiesBox, _castBox, _settingsBox);
    // [NEW] Notify listeners that sync is done
    _syncCompleteController.add(null);
    return result;
  }

  Future<String> inspectCloudData() async {
    return await CloudStorageService().inspectCloudData();
  }

  Future<String> rescueCast() async {
    if (!_initialized) await init();
    debugPrint('StorageService: Attempting Cast Rescue...');
    return await CloudStorageService().rescueCast(_castBox);
  }

  // [NEW] Safe Logout: Clear memory and close boxes
  Future<void> reset() async {
      debugPrint('StorageService: Resetting for Logout...');
      if (_initialized) {
        await _closeBoxes();
      }
      _currentUserId = null;
      _initialized = false;
  }
}
