import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../../data/models/account_manager_model.dart';
import '../../data/models/client_model.dart';
import '../../data/models/proposal_model.dart';

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
        final existing = await getAccountManager(user.uid);
        final cleanEmail = (user.email ?? '').toLowerCase().trim();
        final isOwner = cleanEmail == 'aditya@herbalties.com';

        if (existing == null) {
          final isFirst = await _isFirstRegisteredUser();
          final role = (isOwner || isFirst || cleanEmail.contains('admin')) ? 'admin' : 'pending';
          final am = AccountManagerModel(
            id: user.uid,
            displayName: user.displayName ?? user.email?.split('@').first ?? 'User',
            email: user.email ?? '',
            createdAt: DateTime.now(),
            lastLoginAt: DateTime.now(),
            role: role,
            assignedClientIds: const [],
          );
          await _ensureAccountManagerDoc(am);
        } else if (isOwner && existing.role != 'admin') {
          // Self-heal: ensure aditya@herbalties.com is permanently admin
          await _ensureAccountManagerDoc(existing.copyWith(role: 'admin'));
        }
      }
    });
  }

  Future<bool> _isFirstRegisteredUser() async {
    if (!_isFirebaseAvailable) return false;
    try {
      final snap = await firestore.collection('users').limit(2).get();
      if (snap.docs.isEmpty) {
        final amSnap = await firestore.collection('account_managers').limit(2).get();
        return amSnap.docs.isEmpty;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<AccountManagerModel?> getAccountManager(String uid) async {
    if (!_isFirebaseAvailable) return null;
    try {
      Map<String, dynamic>? data;

      // 1. Check 'users' collection first (preferred)
      final userDoc = await firestore.collection('users').doc(uid).get();
      if (userDoc.exists && userDoc.data() != null) {
        data = Map<String, dynamic>.from(userDoc.data()!);
      } else {
        // 2. Fallback to 'account_managers' collection
        final amDoc = await firestore.collection('account_managers').doc(uid).get();
        if (amDoc.exists && amDoc.data() != null) {
          data = Map<String, dynamic>.from(amDoc.data()!);
        }
      }

      if (data != null) {
        final email = (data['email'] as String? ?? '').toLowerCase().trim();
        // Guaranteed: aditya@herbalties.com is ALWAYS highest role (admin)
        if (email == 'aditya@herbalties.com') {
          data['role'] = 'admin';
        }
        return AccountManagerModel.fromJson(uid, data);
      }
    } catch (e) {
      debugPrint('Firestore getAccountManager error: $e');
    }
    return null;
  }

  Future<void> _ensureAccountManagerDoc(AccountManagerModel am) async {
    if (!_isFirebaseAvailable) return;
    try {
      final email = am.email.toLowerCase().trim();
      final isOwner = email == 'aditya@herbalties.com';
      final payload = am.toJson();

      // Check existing role in both collections to avoid rolling back admin edits
      final userDoc = await firestore.collection('users').doc(am.id).get();
      final amDoc = await firestore.collection('account_managers').doc(am.id).get();

      String role = am.role;
      List<dynamic> assignments = am.assignedClientIds;

      if (userDoc.exists && userDoc.data() != null) {
        final ud = userDoc.data()!;
        if (ud.containsKey('role') && ud['role'] != null) {
          role = ud['role'].toString();
        }
        if (ud.containsKey('assignedClientIds') && ud['assignedClientIds'] != null) {
          assignments = ud['assignedClientIds'] as List;
        }
      } else if (amDoc.exists && amDoc.data() != null) {
        final ad = amDoc.data()!;
        if (ad.containsKey('role') && ad['role'] != null) {
          role = ad['role'].toString();
        }
        if (ad.containsKey('assignedClientIds') && ad['assignedClientIds'] != null) {
          assignments = ad['assignedClientIds'] as List;
        }
      }

      // Hardcode highest role for aditya@herbalties.com
      if (isOwner) {
        role = 'admin';
      }

      payload['role'] = role;
      payload['assignedClientIds'] = assignments;
      payload['lastLoginAt'] = DateTime.now().toIso8601String();

      // Synchronize to BOTH collections so Firestore never desyncs
      await firestore.collection('users').doc(am.id).set(payload, SetOptions(merge: true));
      await firestore.collection('account_managers').doc(am.id).set(payload, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore _ensureAccountManagerDoc error: $e');
    }
  }

  // ── Authentication ────────────────────────────────────────────────────────
  Future<AccountManagerModel?> signInWithEmail(String email, String password) async {
    final cleanEmail = email.toLowerCase().trim();
    final isOwner = cleanEmail == 'aditya@herbalties.com';

    if (_isFirebaseAvailable) {
      try {
        final cred = await auth.signInWithEmailAndPassword(email: email, password: password);
        if (cred.user != null) {
          var am = await getAccountManager(cred.user!.uid);
          if (am == null) {
            final isFirst = await _isFirstRegisteredUser();
            final role = (isOwner || isFirst || cleanEmail.contains('admin')) ? 'admin' : 'pending';
            am = AccountManagerModel(
              id: cred.user!.uid,
              displayName: cred.user!.displayName ?? email.split('@').first,
              email: email,
              createdAt: DateTime.now(),
              lastLoginAt: DateTime.now(),
              role: role,
              assignedClientIds: const [],
            );
            await _ensureAccountManagerDoc(am);
          } else {
            if (isOwner && am.role != 'admin') {
              am = am.copyWith(role: 'admin');
            }
            await _ensureAccountManagerDoc(am);
          }
          return am;
        }
      } on FirebaseAuthException catch (e) {
        debugPrint('Firebase Auth SignIn error: ${e.code} - ${e.message}');
        String message = 'Authentication failed.';
        if (e.code == 'user-not-found') {
          message = 'No account found with this email. Please sign up first.';
        } else if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
          message = 'Incorrect password. Please verify your credentials and try again.';
        } else if (e.code == 'invalid-email') {
          message = 'Please enter a valid email address.';
        } else if (e.code == 'user-disabled') {
          message = 'This user account has been deactivated.';
        } else if (e.message != null && e.message!.isNotEmpty) {
          message = e.message!;
        }
        throw Exception(message);
      } catch (e) {
        debugPrint('Firebase Auth SignIn exception: $e');
        rethrow;
      }
    }

    // Fallback if offline
    return AccountManagerModel(
      id: 'am-${email.hashCode.abs()}',
      displayName: email.split('@').first,
      email: email,
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
      role: (isOwner || cleanEmail.contains('admin')) ? 'admin' : 'pending',
    );
  }

  Future<AccountManagerModel?> signUpWithEmail(String name, String email, String password) async {
    final cleanEmail = email.toLowerCase().trim();
    final isOwner = cleanEmail == 'aditya@herbalties.com';

    if (_isFirebaseAvailable) {
      try {
        final cred = await auth.createUserWithEmailAndPassword(email: email, password: password);
        if (cred.user != null) {
          await cred.user!.updateDisplayName(name);
          final isFirst = await _isFirstRegisteredUser();
          // Newly registered accounts must be assigned a role by Admin, unless owner/first
          final role = (isOwner || isFirst || cleanEmail.contains('admin')) ? 'admin' : 'pending';
          final am = AccountManagerModel(
            id: cred.user!.uid,
            displayName: name,
            email: email,
            createdAt: DateTime.now(),
            lastLoginAt: DateTime.now(),
            role: role,
            assignedClientIds: const [],
          );
          await _ensureAccountManagerDoc(am);
          return am;
        }
      } on FirebaseAuthException catch (e) {
        debugPrint('Firebase Auth SignUp error: ${e.code} - ${e.message}');
        String message = 'Registration failed.';
        if (e.code == 'email-already-in-use') {
          message = 'An account already exists for that email. Please sign in instead.';
        } else if (e.code == 'weak-password') {
          message = 'Password is too weak. Please use at least 6 characters.';
        } else if (e.code == 'invalid-email') {
          message = 'Please enter a valid email address.';
        } else if (e.message != null && e.message!.isNotEmpty) {
          message = e.message!;
        }
        throw Exception(message);
      } catch (e) {
        debugPrint('Firebase Auth SignUp exception: $e');
        rethrow;
      }
    }

    return AccountManagerModel(
      id: 'am-${email.hashCode.abs()}',
      displayName: name,
      email: email,
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
      role: (isOwner || cleanEmail.contains('admin')) ? 'admin' : 'pending',
    );
  }

  // ── User Management Methods (Admin Access) ─────────────────────────────────
  Future<List<AccountManagerModel>> getAllUsers() async {
    if (_isFirebaseAvailable) {
      try {
        final Map<String, AccountManagerModel> userMap = {};

        // 1. Fetch from 'users' collection
        try {
          final usersSnap = await firestore.collection('users').get();
          for (final d in usersSnap.docs) {
            userMap[d.id] = AccountManagerModel.fromJson(d.id, d.data());
          }
        } catch (e) {
          debugPrint('Firestore getAllUsers (users) error: $e');
        }

        // 2. Fetch from 'account_managers' collection and merge
        try {
          final amSnap = await firestore.collection('account_managers').get();
          for (final d in amSnap.docs) {
            if (!userMap.containsKey(d.id)) {
              userMap[d.id] = AccountManagerModel.fromJson(d.id, d.data());
            } else {
              // Merge assignments if missing
              final existing = userMap[d.id]!;
              final amModel = AccountManagerModel.fromJson(d.id, d.data());
              if (existing.assignedClientIds.isEmpty && amModel.assignedClientIds.isNotEmpty) {
                userMap[d.id] = existing.copyWith(assignedClientIds: amModel.assignedClientIds);
              }
            }
          }
        } catch (e) {
          debugPrint('Firestore getAllUsers (account_managers) error: $e');
        }

        // Guaranteed: aditya@herbalties.com has admin role
        final list = userMap.values.map((u) {
          if (u.email.toLowerCase().trim() == 'aditya@herbalties.com') {
            return u.copyWith(role: 'admin');
          }
          return u;
        }).toList();

        list.sort((a, b) {
          // Put owner and admins first, then pending, then AM
          if (a.isSuperAdmin) return -1;
          if (b.isSuperAdmin) return 1;
          if (a.isPending && !b.isPending) return -1;
          if (!a.isPending && b.isPending) return 1;
          return a.displayName.compareTo(b.displayName);
        });

        return list;
      } catch (e) {
        debugPrint('Firestore getAllUsers error: $e');
      }
    }
    return [];
  }

  Future<void> updateUserRoleAndAssignments(
    String userId, {
    required String role,
    required List<String> assignedClientIds,
  }) async {
    if (_isFirebaseAvailable) {
      try {
        final updatePayload = {
          'role': role,
          'assignedClientIds': assignedClientIds,
          'updatedAt': FieldValue.serverTimestamp(),
        };

        // Update BOTH collections so they are always in perfect sync
        await firestore.collection('users').doc(userId).set(updatePayload, SetOptions(merge: true));
        await firestore.collection('account_managers').doc(userId).set(updatePayload, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Firestore updateUserRoleAndAssignments error: $e');
        rethrow;
      }
    }
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

  /// Fetch all client projects across the entire agency (Admin / Central catalog)
  Future<List<ClientModel>> getAllAgencyClients() async {
    if (_isFirebaseAvailable) {
      try {
        final snap = await firestore.collection('clients').orderBy('lastActivity', descending: true).get();
        if (snap.docs.isNotEmpty) {
          return snap.docs.map((d) => ClientModel.fromJson(d.id, d.data())).toList();
        }
      } catch (e) {
        debugPrint('Firestore getAllAgencyClients error: $e');
        try {
          final fallbackSnap = await firestore.collection('clients').get();
          if (fallbackSnap.docs.isNotEmpty) {
            return fallbackSnap.docs.map((d) => ClientModel.fromJson(d.id, d.data())).toList();
          }
        } catch (_) {}
      }
    }
    return [];
  }

  // ── Direct Firestore Clients Management ────────────────────────────────────
  Future<List<ClientModel>> getClients(String amId, {AccountManagerModel? user}) async {
    final currentUid = _getCurrentUid(amId);

    if (_isFirebaseAvailable) {
      try {
        // 1. Check all agency clients from root collection
        final allClients = await getAllAgencyClients();

        if (allClients.isNotEmpty) {
          // If user provided and is NOT admin, filter by assignedClientIds
          if (user != null && !user.isAdmin) {
            return allClients.where((c) => user.canAccessClient(c.id)).toList();
          }
          // If admin, return all agency clients
          return allClients;
        }

        // Fallback to am-specific collection if root clients is empty
        final snap = await firestore
            .collection('account_managers')
            .doc(currentUid)
            .collection('clients')
            .orderBy('lastActivity', descending: true)
            .get();

        final list = snap.docs.map((d) => ClientModel.fromJson(d.id, d.data())).toList();
        if (user != null && !user.isAdmin) {
          return list.where((c) => user.canAccessClient(c.id)).toList();
        }
        return list;
      } catch (e) {
        debugPrint('Firestore getClients error: $e');
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

  /// Fetch Client Agentic Harness Profile from Firestore
  Future<Map<String, dynamic>?> getClientAgenticHarness(String amId, String clientId) async {
    final currentUid = _getCurrentUid(amId);
    if (_isFirebaseAvailable) {
      try {
        final doc = await firestore
            .collection('account_managers')
            .doc(currentUid)
            .collection('clients')
            .doc(clientId)
            .collection('agentic_harness')
            .doc('profile')
            .get();

        if (doc.exists && doc.data() != null) {
          return doc.data()!;
        }
      } catch (e) {
        debugPrint('Firestore getClientAgenticHarness error: $e');
      }
    }
    return null;
  }

  /// Save Client Agentic Harness Profile to Firestore
  Future<void> saveClientAgenticHarness(String amId, String clientId, Map<String, dynamic> data) async {
    final currentUid = _getCurrentUid(amId);
    if (_isFirebaseAvailable) {
      try {
        await firestore
            .collection('account_managers')
            .doc(currentUid)
            .collection('clients')
            .doc(clientId)
            .collection('agentic_harness')
            .doc('profile')
            .set(data, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Firestore saveClientAgenticHarness error: $e');
      }
    }
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

        final uploadTask = await storageRef.putData(bytes, metadata).timeout(const Duration(seconds: 15));
        final downloadUrl = await uploadTask.ref.getDownloadURL().timeout(const Duration(seconds: 8));
        debugPrint('Firebase Storage upload succeeded: $downloadUrl');
        return downloadUrl;
      } catch (e) {
        debugPrint('Firebase Storage upload error: $e');
      }
    }

    // Direct Data URI fallback: 100% reliable, zero CORS, zero 404
    final mime = fileName.endsWith('.png')
        ? 'image/png'
        : (fileName.endsWith('.webp')
            ? 'image/webp'
            : (fileName.endsWith('.mp4') ? 'video/mp4' : 'image/jpeg'));
    return 'data:$mime;base64,${base64Encode(bytes)}';
  }

  /// Upload proposal media asset (Reel, Instagram post, visual direction) to Firebase Storage
  Future<String> uploadProposalMedia({
    required String proposalId,
    required String fileName,
    required Uint8List bytes,
    String? contentType,
  }) async {
    final cleanName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    if (_isFirebaseAvailable) {
      try {
        final storageRef = storage.ref().child('proposals/$proposalId/media/$cleanName');
        final metadata = SettableMetadata(
          contentType: contentType ?? (fileName.endsWith('.mp4') ? 'video/mp4' : 'image/jpeg'),
          customMetadata: {
            'proposalId': proposalId,
            'fileName': fileName,
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        );
        final uploadTask = await storageRef.putData(bytes, metadata).timeout(const Duration(seconds: 15));
        final downloadUrl = await uploadTask.ref.getDownloadURL().timeout(const Duration(seconds: 8));
        debugPrint('Firebase Storage proposal media upload succeeded: $downloadUrl');
        return downloadUrl;
      } catch (e) {
        debugPrint('Firebase Storage uploadProposalMedia error: $e');
      }
    }

    // Direct Data URI fallback: 100% reliable, zero CORS, zero 404
    final mime = fileName.endsWith('.png')
        ? 'image/png'
        : (fileName.endsWith('.webp')
            ? 'image/webp'
            : (fileName.endsWith('.mp4') ? 'video/mp4' : 'image/jpeg'));
    return 'data:$mime;base64,${base64Encode(bytes)}';
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Proposal Engine & Lead Management Methods (Online Firestore)
  // ───────────────────────────────────────────────────────────────────────────

  /// Fetch all Proposals for an Account Manager
  Future<List<ProposalModel>> getProposals(String amId) async {
    final currentUid = _getCurrentUid(amId);
    if (_isFirebaseAvailable) {
      try {
        final snap = await firestore
            .collection('account_managers')
            .doc(currentUid)
            .collection('proposals')
            .orderBy('createdAt', descending: true)
            .get();

        return snap.docs
            .map((doc) => ProposalModel.fromJson(doc.id, doc.data()))
            .toList();
      } catch (e) {
        debugPrint('Firestore getProposals error: $e');
      }
    }
    return [];
  }

  /// Fetch a single Proposal by ID
  Future<ProposalModel?> getProposal(String amId, String proposalId) async {
    final currentUid = _getCurrentUid(amId);
    if (_isFirebaseAvailable) {
      try {
        final doc = await firestore
            .collection('account_managers')
            .doc(currentUid)
            .collection('proposals')
            .doc(proposalId)
            .get();

        if (doc.exists && doc.data() != null) {
          return ProposalModel.fromJson(doc.id, doc.data()!);
        }
      } catch (e) {
        debugPrint('Firestore getProposal error: $e');
      }
    }
    return null;
  }

  /// Save or Update Proposal in Firestore
  Future<void> saveProposal(String amId, ProposalModel proposal) async {
    final currentUid = _getCurrentUid(amId);
    if (_isFirebaseAvailable) {
      try {
        await firestore
            .collection('account_managers')
            .doc(currentUid)
            .collection('proposals')
            .doc(proposal.id)
            .set(proposal.toJson(), SetOptions(merge: true));

        // Also update root proposals collection for centralized reporting
        await firestore
            .collection('proposals')
            .doc(proposal.id)
            .set({...proposal.toJson(), 'ownerUid': currentUid}, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Firestore saveProposal error: $e');
      }
    }
  }

  /// Delete a Proposal from Firestore
  Future<void> deleteProposal(String amId, String proposalId) async {
    final currentUid = _getCurrentUid(amId);
    if (_isFirebaseAvailable) {
      try {
        await firestore
            .collection('account_managers')
            .doc(currentUid)
            .collection('proposals')
            .doc(proposalId)
            .delete();

        await firestore.collection('proposals').doc(proposalId).delete();
      } catch (e) {
        debugPrint('Firestore deleteProposal error: $e');
      }
    }
  }

  /// Convert a winning Proposal into a Client Workspace in Firestore
  Future<ClientModel> convertProposalToClient({
    required String amId,
    required ProposalModel proposal,
  }) async {
    final currentUid = _getCurrentUid(amId);

    // 1. Create client in Firestore
    var newClient = await createClient(
      currentUid,
      proposal.leadCompanyName,
      proposal.industry,
      websiteUrl: proposal.websiteUrl,
    );

    if (proposal.extractedPitchDeckText != null && proposal.extractedPitchDeckText!.isNotEmpty) {
      newClient = newClient.copyWith(
        extractedPdfContent: proposal.extractedPitchDeckText,
        pitchDeckStoragePath: proposal.pitchDeckStorageUrl,
      );
      await updateClient(currentUid, newClient);
    }

    // 2. Save proposal deliverable in client's deliverables folder
    await saveDeliverable(currentUid, newClient.id, 'proposal', proposal.toJson());

    // 3. Mark proposal as converted in Firestore
    final updatedProposal = proposal.copyWith(
      status: ProposalStatus.converted,
      convertedAt: DateTime.now(),
      convertedClientId: newClient.id,
      updatedAt: DateTime.now(),
    );
    await saveProposal(currentUid, updatedProposal);

    return newClient;
  }
}
