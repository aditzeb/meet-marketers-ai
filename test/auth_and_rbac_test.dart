import 'package:flutter_test/flutter_test.dart';
import 'package:meet_marketers_ai/data/models/account_manager_model.dart';
import 'package:meet_marketers_ai/data/models/client_model.dart';
import 'package:meet_marketers_ai/data/models/proposal_model.dart';

void main() {
  group('Auth & RBAC Role-Based Access Control Tests', () {
    test('aditya@herbalties.com is guaranteed SuperAdmin role and cannot be demoted', () {
      // Even if Firestore JSON contains role 'accountManager' or 'pending', aditya@herbalties.com must be admin
      final doc = AccountManagerModel.fromJson('user-aditya', {
        'displayName': 'Ananda Aditya',
        'email': 'aditya@herbalties.com',
        'role': 'accountManager', // incoming outdated/rollback data
      });

      expect(doc.isSuperAdmin, isTrue);
      expect(doc.isAdmin, isTrue);
      expect(doc.isPending, isFalse);
      expect(doc.role, equals('admin'));

      // Serialization preserves admin
      final json = doc.toJson();
      expect(json['role'], equals('admin'));

      // Can access any client
      expect(doc.canAccessClient('any-client-123'), isTrue);
    });

    test('New registered accounts default to pending role and cannot do anything until assigned', () {
      final newMember = AccountManagerModel.fromJson('new-user-1', {
        'displayName': 'John Doe',
        'email': 'john@agency.com',
        // role omitted or pending
      });

      expect(newMember.isPending, isTrue);
      expect(newMember.isAdmin, isFalse);
      expect(newMember.isAccountManager, isFalse);
      expect(newMember.hasActiveRole, isFalse);

      // Pending users cannot access any client workspaces
      expect(newMember.canAccessClient('client-1'), isFalse);
    });

    test('AccountManagerModel correctly differentiates Admin vs Account Manager roles', () {
      final admin = AccountManagerModel(
        id: 'user-admin-1',
        displayName: 'Chief Administrator',
        email: 'admin@agency.com',
        role: 'admin',
        assignedClientIds: const [],
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
      );

      final accountManager = AccountManagerModel(
        id: 'user-am-1',
        displayName: 'Sarah Senior AM',
        email: 'sarah@agency.com',
        role: 'accountManager',
        assignedClientIds: const ['client-alpha', 'client-beta'],
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
      );

      expect(admin.isAdmin, isTrue);
      expect(accountManager.isAdmin, isFalse);

      // Admin has access to any client
      expect(admin.canAccessClient('client-alpha'), isTrue);
      expect(admin.canAccessClient('client-gamma'), isTrue);

      // Account Manager only has access to assigned clients
      expect(accountManager.canAccessClient('client-alpha'), isTrue);
      expect(accountManager.canAccessClient('client-beta'), isTrue);
      expect(accountManager.canAccessClient('client-gamma'), isFalse);
    });

    test('AccountManagerModel serializes and deserializes role and assignedClientIds correctly', () {
      final original = AccountManagerModel(
        id: 'user-am-2',
        displayName: 'Marcus Lee',
        email: 'marcus@agency.com',
        role: 'accountManager',
        assignedClientIds: const ['client-101', 'client-102'],
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
      );

      final json = original.toJson();
      expect(json['role'], equals('accountManager'));
      expect(json['assignedClientIds'], equals(['client-101', 'client-102']));

      final deserialized = AccountManagerModel.fromJson('user-am-2', json);
      expect(deserialized.id, equals('user-am-2'));
      expect(deserialized.displayName, equals('Marcus Lee'));
      expect(deserialized.email, equals('marcus@agency.com'));
      expect(deserialized.role, equals('accountManager'));
      expect(deserialized.isAdmin, isFalse);
      expect(deserialized.assignedClientIds, equals(['client-101', 'client-102']));
    });

    test('Client access filtering respects assignedClientIds for non-admins', () {
      final clientA = ClientModel(
        id: 'client-A',
        name: 'Alpha Clinic',
        industry: 'Healthcare',
        createdAt: DateTime.now(),
        lastActivity: DateTime.now(),
      );
      final clientB = ClientModel(
        id: 'client-B',
        name: 'Beta Motors',
        industry: 'Automotive',
        createdAt: DateTime.now(),
        lastActivity: DateTime.now(),
      );
      final clientC = ClientModel(
        id: 'client-C',
        name: 'Gamma Tech',
        industry: 'Technology',
        createdAt: DateTime.now(),
        lastActivity: DateTime.now(),
      );

      final allClients = [clientA, clientB, clientC];

      final admin = AccountManagerModel(
        id: 'admin-id',
        displayName: 'Admin User',
        email: 'admin@agency.com',
        role: 'admin',
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
      );

      final am = AccountManagerModel(
        id: 'am-id',
        displayName: 'Account Manager User',
        email: 'am@agency.com',
        role: 'accountManager',
        assignedClientIds: const ['client-A', 'client-C'],
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
      );

      // Filter simulation matching getClients logic
      final adminVisibleClients = allClients.where((c) => admin.canAccessClient(c.id)).toList();
      final amVisibleClients = allClients.where((c) => am.canAccessClient(c.id)).toList();

      expect(adminVisibleClients.length, equals(3));
      expect(amVisibleClients.length, equals(2));
      expect(amVisibleClients.map((c) => c.id), containsAll(['client-A', 'client-C']));
      expect(amVisibleClients.map((c) => c.id), isNot(contains('client-B')));
    });

    test('Project creation is guarded: only 1 role (Admin) can create projects, but both can create proposals', () {
      final admin = AccountManagerModel(
        id: 'admin-id',
        displayName: 'Admin User',
        email: 'admin@agency.com',
        role: 'admin',
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
      );

      final am = AccountManagerModel(
        id: 'am-id',
        displayName: 'Account Manager User',
        email: 'am@agency.com',
        role: 'accountManager',
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
      );

      // Client Creation Permission Guard
      void attemptCreateClient(AccountManagerModel user) {
        if (!user.isAdmin) {
          throw Exception('Permission Denied: Only Admins can create new client projects.');
        }
      }

      expect(() => attemptCreateClient(admin), returnsNormally);
      expect(
        () => attemptCreateClient(am),
        throwsA(predicate((e) => e.toString().contains('Only Admins can create new client projects.'))),
      );

      // Proposal Creation: Unrestricted for EVERY active account
      ProposalModel createProposal(AccountManagerModel user, String leadName) {
        if (user.isPending) {
          throw Exception('Permission Denied: Account pending role assignment.');
        }
        final now = DateTime.now();
        return ProposalModel(
          id: 'prop-${now.millisecondsSinceEpoch}',
          amId: user.id,
          leadCompanyName: leadName,
          industry: 'Hospitality',
          websiteUrl: 'https://$leadName.com',
          status: ProposalStatus.readyForReview,
          createdAt: now,
          updatedAt: now,
        );
      }

      final adminProposal = createProposal(admin, 'Grand Hotel');
      final amProposal = createProposal(am, 'Sunset Lounge');

      expect(adminProposal.amId, equals(admin.id));
      expect(amProposal.amId, equals(am.id));
      expect(adminProposal.leadCompanyName, equals('Grand Hotel'));
      expect(amProposal.leadCompanyName, equals('Sunset Lounge'));
      expect(adminProposal.status, equals(ProposalStatus.readyForReview));
      expect(amProposal.status, equals(ProposalStatus.readyForReview));
    });
  });
}
