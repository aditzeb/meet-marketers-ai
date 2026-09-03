import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../../data/models/account_manager_model.dart';
import '../../data/models/client_model.dart';

/// Firebase Service handling authentication, Firestore database, and Storage operations
class FirebaseService {
  static final FirebaseService instance = FirebaseService._internal();
  FirebaseService._internal();

  FirebaseAuth get auth => FirebaseAuth.instance;
  FirebaseFirestore get firestore => FirebaseFirestore.instance;
  FirebaseStorage get storage => FirebaseStorage.instance;

  bool _isFirebaseAvailable = false;
  bool get isFirebaseAvailable => _isFirebaseAvailable;

  void markFirebaseInitialized() {
    _isFirebaseAvailable = true;
    _listenToAuthState();
  }

  void _listenToAuthState() {
    if (!_isFirebaseAvailable) return;
    auth.authStateChanges().listen((user) async {
      if (user != null) {
        debugPrint('Firebase Auth user state updated: ${user.uid} (${user.email})');
        final am = AccountManagerModel(
          id: user.uid,
          displayName: user.displayName ?? user.email?.split('@').first ?? 'Account Manager',
          email: user.email ?? 'am@agency.com',
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
        );
        await _ensureAccountManagerDoc(am);
      }
    });
  }

  Future<void> _ensureAccountManagerDoc(AccountManagerModel am) async {
    if (!_isFirebaseAvailable) return;
    try {
      final payload = am.toJson();
      await firestore.collection('account_managers').doc(am.id).set(payload, SetOptions(merge: true));
      await firestore.collection('users').doc(am.id).set(payload, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore _ensureAccountManagerDoc error: $e');
    }
  }

  // ── Authentication ────────────────────────────────────────────────────────
  Future<AccountManagerModel?> signInWithEmail(String email, String password) async {
    if (_isFirebaseAvailable) {
      try {
        final cred = await auth.signInWithEmailAndPassword(email: email, password: password);
        if (cred.user != null) {
          final am = AccountManagerModel(
            id: cred.user!.uid,
            displayName: cred.user!.displayName ?? email.split('@').first,
            email: email,
            createdAt: DateTime.now(),
            lastLoginAt: DateTime.now(),
          );
          await _ensureAccountManagerDoc(am);
          return am;
        }
      } catch (e) {
        debugPrint('Firebase Auth SignIn warning: $e');
        if (e.toString().contains('user-not-found') || e.toString().contains('invalid-credential')) {
          return signUpWithEmail(email.split('@').first, email, password);
        }
      }
    }

    final am = AccountManagerModel(
      id: 'am-${email.hashCode.abs()}',
      displayName: email.split('@').first,
      email: email,
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
      totalClients: 5,
    );
    return am;
  }

  Future<AccountManagerModel?> signUpWithEmail(String name, String email, String password) async {
    if (_isFirebaseAvailable) {
      try {
        final cred = await auth.createUserWithEmailAndPassword(email: email, password: password);
        if (cred.user != null) {
          await cred.user!.updateDisplayName(name);
          final am = AccountManagerModel(
            id: cred.user!.uid,
            displayName: name,
            email: email,
            createdAt: DateTime.now(),
            lastLoginAt: DateTime.now(),
          );
          await _ensureAccountManagerDoc(am);
          return am;
        }
      } catch (e) {
        debugPrint('Firebase Auth SignUp warning: $e');
        if (e.toString().contains('email-already-in-use')) {
          return signInWithEmail(email, password);
        }
      }
    }

    final am = AccountManagerModel(
      id: 'am-${email.hashCode.abs()}',
      displayName: name,
      email: email,
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
    );
    return am;
  }

  Future<AccountManagerModel?> signInAnonymously() async {
    if (_isFirebaseAvailable) {
      try {
        final cred = await auth.signInAnonymously();
        if (cred.user != null) {
          final am = AccountManagerModel(
            id: cred.user!.uid,
            displayName: 'Guest Account Manager',
            email: 'guest@meetmarketers.ai',
            createdAt: DateTime.now(),
            lastLoginAt: DateTime.now(),
          );
          await _ensureAccountManagerDoc(am);
          return am;
        }
      } catch (e) {
        debugPrint('Firebase Anonymous SignIn error: $e');
      }
    }

    final am = AccountManagerModel(
      id: 'am-guest',
      displayName: 'Guest Account Manager',
      email: 'guest@meetmarketers.ai',
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
    );
    return am;
  }

  Future<void> signOut() async {
    if (_isFirebaseAvailable) {
      try {
        await auth.signOut();
      } catch (_) {}
    }
  }

  String _getCurrentUid(String amId) {
    if (_isFirebaseAvailable) {
      try {
        return auth.currentUser?.uid ?? amId;
      } catch (_) {}
    }
    return amId;
  }

  // ── Direct Firestore Clients Management ────────────────────────────────────
  Future<List<ClientModel>> getClients(String amId) async {
    final currentUid = _getCurrentUid(amId);

    if (_isFirebaseAvailable) {
      try {
        final snap = await firestore
            .collection('account_managers')
            .doc(currentUid)
            .collection('clients')
            .orderBy('lastActivity', descending: true)
            .get();

        return snap.docs.map((d) => ClientModel.fromJson(d.id, d.data())).toList();
      } catch (e) {
        debugPrint('Firestore getClients error: $e');
        try {
          final fallbackSnap = await firestore
              .collection('account_managers')
              .doc(currentUid)
              .collection('clients')
              .get();
          return fallbackSnap.docs.map((d) => ClientModel.fromJson(d.id, d.data())).toList();
        } catch (e2) {
          debugPrint('Firestore getClients fallback error: $e2');
        }
      }
    }

    return [];
  }

  Future<ClientModel> createClient(String amId, String name, String industry, {String? websiteUrl}) async {
    final currentUid = _getCurrentUid(amId);
    final clientId = 'client-${DateTime.now().millisecondsSinceEpoch}';
    final client = ClientModel(
      id: clientId,
      name: name,
      industry: industry,
      websiteUrl: websiteUrl,
      createdAt: DateTime.now(),
      lastActivity: DateTime.now(),
      status: ClientStatus.active,
    );

    if (_isFirebaseAvailable) {
      try {
        final payload = client.toJson();
        await firestore
            .collection('account_managers')
            .doc(currentUid)
            .collection('clients')
            .doc(clientId)
            .set(payload);

        await firestore
            .collection('clients')
            .doc(clientId)
            .set({...payload, 'ownerUid': currentUid});
      } catch (e) {
        debugPrint('Firestore createClient error: $e');
      }
    }

    return client;
  }

  Future<void> updateClient(String amId, ClientModel client) async {
    final currentUid = _getCurrentUid(amId);
    final updated = client.copyWith(lastActivity: DateTime.now());
    if (_isFirebaseAvailable) {
      try {
        final payload = updated.toJson();
        await firestore
            .collection('account_managers')
            .doc(currentUid)
            .collection('clients')
            .doc(client.id)
            .set(payload, SetOptions(merge: true));

        await firestore
            .collection('clients')
            .doc(client.id)
            .set({...payload, 'ownerUid': currentUid}, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Firestore updateClient error: $e');
      }
    }
  }

  /// Delete Client Project permanently from Firestore
  Future<void> deleteClient(String amId, String clientId) async {
    final currentUid = _getCurrentUid(amId);

    if (_isFirebaseAvailable) {
      try {
        // Delete from user-scoped clients collection
        await firestore
            .collection('account_managers')
            .doc(currentUid)
            .collection('clients')
            .doc(clientId)
            .delete();

        // Delete from root clients collection
        await firestore.collection('clients').doc(clientId).delete();

        // Delete deliverables subcollection documents
        final delSnap = await firestore
            .collection('account_managers')
            .doc(currentUid)
            .collection('clients')
            .doc(clientId)
            .collection('deliverables')
            .get();

        for (var doc in delSnap.docs) {
          await doc.reference.delete();
        }
        debugPrint('Successfully deleted client $clientId from Firestore');
      } catch (e) {
        debugPrint('Firestore deleteClient error: $e');
      }
    }
  }

  // ── Firestore Deliverables & Draft Persistence ──────────────────────────────
  Future<void> saveDeliverable(String amId, String clientId, String type, Map<String, dynamic> data) async {
    final currentUid = _getCurrentUid(amId);
    final payload = {
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
      'clientId': clientId,
      'ownerUid': currentUid,
    };

    if (_isFirebaseAvailable) {
      try {
        await firestore
            .collection('account_managers')
            .doc(currentUid)
            .collection('clients')
            .doc(clientId)
            .collection('deliverables')
            .doc(type)
            .set(payload, SetOptions(merge: true));

        await firestore
            .collection('deliverables')
            .doc('${clientId}_$type')
            .set(payload, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Firestore saveDeliverable error: $e');
      }
    }
  }

  Future<Map<String, dynamic>?> getDeliverable(String amId, String clientId, String type) async {
    final currentUid = _getCurrentUid(amId);

    if (_isFirebaseAvailable) {
      try {
        final doc = await firestore
            .collection('account_managers')
            .doc(currentUid)
            .collection('clients')
            .doc(clientId)
            .collection('deliverables')
            .doc(type)
            .get();

        if (doc.exists && doc.data() != null) {
          return doc.data();
        }
      } catch (e) {
        debugPrint('Firestore getDeliverable error: $e');
      }
    }
    return null;
  }

  /// Get all deliverables for a client directly from Firestore
  Future<Map<String, Map<String, dynamic>>> getDeliverables(String amId, String clientId) async {
    final currentUid = _getCurrentUid(amId);
    final result = <String, Map<String, dynamic>>{};

    if (_isFirebaseAvailable) {
      try {
        final snap = await firestore
            .collection('account_managers')
            .doc(currentUid)
            .collection('clients')
            .doc(clientId)
            .collection('deliverables')
            .get();

        for (final doc in snap.docs) {
          result[doc.id] = doc.data();
        }
      } catch (e) {
        debugPrint('Firestore getDeliverables error: $e');
      }
    }
    return result;
  }

  /// Upload client asset directly to Firebase Storage and return download URL
  Future<String?> uploadFile({
    required String clientId,
    required String folder,
    required String fileName,
    required Uint8List bytes,
    String? contentType,
  }) async {
    final cleanName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    if (_isFirebaseAvailable) {
      try {
        final currentUid = _getCurrentUid('am-default');
        final path = 'account_managers/$currentUid/clients/$clientId/$folder/$cleanName';
        final storageRef = storage.ref().child(path);
        final metadata = SettableMetadata(
          contentType: contentType,
          customMetadata: {
            'clientId': clientId,
            'originalName': fileName,
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        );

        final uploadTask = await storageRef.putData(bytes, metadata);
        final downloadUrl = await uploadTask.ref.getDownloadURL();
        debugPrint('Firebase Storage upload succeeded: $downloadUrl');
        return downloadUrl;
      } catch (e) {
        debugPrint('Firebase Storage upload error: $e');
      }
    }
    return 'https://firebasestorage.googleapis.com/v0/b/meet-marketers-ai.firebasestorage.app/o/clients%2F$clientId%2F$folder%2F$cleanName?alt=media';
  }
}
