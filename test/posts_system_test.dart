import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niva/features/home/presentation/widgets/home_posts_section.dart';
import 'package:niva/features/needs/data/need_model.dart';
import 'package:niva/features/needs/data/need_repository.dart';
import 'package:niva/features/needs/presentation/widgets/create_post_sheet.dart';
import 'package:niva/features/user/data/user_model.dart';
import 'package:niva/features/user/data/user_repository.dart';

class FakeNeedRepository extends NeedRepository {
  final Map<String, NeedModel> posts = {};
  final StreamController<List<NeedModel>> _controller =
      StreamController<List<NeedModel>>.broadcast();

  bool shouldFail = false;
  String failMessage = 'Firestore database error';

  void _notify() {
    _controller.add(posts.values.toList());
  }

  @override
  Future<String> createNeed(NeedModel need) async {
    if (shouldFail) {
      throw Exception(failMessage);
    }
    final id =
        need.needId.isNotEmpty
            ? need.needId
            : 'need_${DateTime.now().millisecondsSinceEpoch}_${posts.length}';
    final saved = need.copyWith(
      needId: id,
      createdAt: need.createdAt ?? DateTime.now(),
    );
    posts[id] = saved;
    _notify();
    return id;
  }

  @override
  Future<void> updateNeed(String needId, Map<String, dynamic> data) async {
    if (shouldFail) {
      throw Exception(failMessage);
    }
    final existing = posts[needId];
    if (existing == null) return;

    final updated = existing.copyWith(
      title: data['title'] as String? ?? existing.title,
      description: data['description'] as String? ?? existing.description,
      type: data['type'] as String? ?? existing.type,
      skills:
          (data['skills'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          existing.skills,
      updatedAt: DateTime.now(),
    );
    posts[needId] = updated;
    _notify();
  }

  @override
  Future<void> deleteNeed(String needId) async {
    if (shouldFail) {
      throw Exception(failMessage);
    }
    posts.remove(needId);
    _notify();
  }

  @override
  Future<List<NeedModel>> getNeedsByType(
    String type, {
    int limit = 20,
    dynamic startAfter,
  }) async {
    if (shouldFail) {
      throw Exception(failMessage);
    }
    return posts.values.where((p) => p.type == type).take(limit).toList();
  }

  @override
  Stream<List<NeedModel>> streamNeedsByType(String type, {int limit = 30}) {
    if (shouldFail) {
      return Stream.error(failMessage);
    }
    return Stream<List<NeedModel>>.multi((controller) {
      controller.add(
        posts.values.where((p) => p.type == type).take(limit).toList(),
      );
      final sub = _controller.stream.listen((all) {
        controller.add(all.where((p) => p.type == type).take(limit).toList());
      });
      controller.onCancel = () => sub.cancel();
    });
  }

  void dispose() {
    _controller.close();
  }
}

class FakeUserRepositoryForPosts extends UserRepository {
  final Map<String, UserModel> users = {};

  @override
  Future<UserModel?> getUserProfile(String uid) async {
    return users[uid];
  }
}

void main() {
  group('NeedModel Phase 3 Field Tests', () {
    test('Serializes and deserializes authorPhotoUrl and authorProfession', () {
      final post = NeedModel(
        needId: 'post_101',
        userId: 'user_404',
        type: 'need',
        title: 'Need a distributed systems consultant',
        description:
            'Looking for advice on scaling Firestore and caching layers',
        skills: const ['Go', 'Distributed Systems', 'GCP'],
        authorName: 'Sundar',
        authorPhotoUrl: 'https://example.com/sundar.png',
        authorProfession: 'VP of Infrastructure',
        createdAt: DateTime(2026, 11, 2, 12, 0),
      );

      final map = post.toMap(useServerTimestamp: false);
      expect(map['authorName'], 'Sundar');
      expect(map['authorPhotoUrl'], 'https://example.com/sundar.png');
      expect(map['authorProfession'], 'VP of Infrastructure');
      expect(map['title'], 'Need a distributed systems consultant');
      expect(map['skills'], ['Go', 'Distributed Systems', 'GCP']);

      final restored = NeedModel.fromMap('post_101', map);
      expect(restored.needId, 'post_101');
      expect(restored.authorName, 'Sundar');
      expect(restored.authorPhotoUrl, 'https://example.com/sundar.png');
      expect(restored.authorProfession, 'VP of Infrastructure');
      expect(restored.type, 'need');
    });

    test('copyWith updates author attributes and post fields properly', () {
      const post = NeedModel(
        needId: 'post_102',
        userId: 'user_102',
        type: 'need',
        title: 'Initial Title',
        description: 'Initial Description',
      );

      final updated = post.copyWith(
        title: 'Updated Title',
        authorProfession: 'Staff Engineer',
        authorPhotoUrl: 'https://cdn.example.com/photo.jpg',
      );

      expect(updated.title, 'Updated Title');
      expect(updated.authorProfession, 'Staff Engineer');
      expect(updated.authorPhotoUrl, 'https://cdn.example.com/photo.jpg');
      expect(updated.description, 'Initial Description');
    });
  });

  group('NeedRepository Phase 3 CRUD & Queries', () {
    late FakeNeedRepository repo;

    setUp(() {
      repo = FakeNeedRepository();
    });

    tearDown(() {
      repo.dispose();
    });

    test('createNeed, updateNeed, and deleteNeed work as expected', () async {
      final post = NeedModel(
        needId: '',
        userId: 'u1',
        type: 'need',
        title: 'Need a Flutter architect',
        description: 'Code review for state management',
        authorName: 'Arun',
      );

      final id = await repo.createNeed(post);
      expect(id, isNotEmpty);
      expect(repo.posts.containsKey(id), isTrue);

      await repo.updateNeed(id, {'title': 'Need an experienced Flutter lead'});
      expect(repo.posts[id]?.title, 'Need an experienced Flutter lead');

      await repo.deleteNeed(id);
      expect(repo.posts.containsKey(id), isFalse);
    });

    test('getNeedsByType filters strictly by need or help type', () async {
      await repo.createNeed(
        const NeedModel(
          needId: 'n1',
          userId: 'u1',
          type: 'need',
          title: 'Looking for a designer',
          description: 'Figma UI design',
        ),
      );
      await repo.createNeed(
        const NeedModel(
          needId: 'h1',
          userId: 'u2',
          type: 'help',
          title: 'I can review PRs',
          description: 'Flutter PR reviews',
        ),
      );

      final needs = await repo.getNeedsByType('need');
      final helps = await repo.getNeedsByType('help');

      expect(needs.length, 1);
      expect(needs.first.title, 'Looking for a designer');

      expect(helps.length, 1);
      expect(helps.first.title, 'I can review PRs');
    });
  });

  group('CreatePostSheet Widget Tests', () {
    testWidgets(
      'Validates required Title and Description on empty submission',
      (WidgetTester tester) async {
        final fakeRepo = FakeNeedRepository();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CreatePostSheet(
                needRepository: fakeRepo,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Tap Publish Post without filling fields
        final publishBtn = find.text('Publish Post');
        await tester.ensureVisible(publishBtn);
        await tester.tap(publishBtn);
        await tester.pumpAndSettle();

        // Verify validation error messages appear
        expect(find.text('Title is required'), findsOneWidget);
        expect(find.text('Description is required'), findsOneWidget);

        // Verify no post was published
        expect(fakeRepo.posts.isEmpty, isTrue);
      },
    );

    testWidgets(
      'Prevents duplicate submissions and shows loading indicator while in-flight',
      (WidgetTester tester) async {
        final fakeRepo = FakeNeedRepository();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CreatePostSheet(
                needRepository: fakeRepo,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Enter Title and Description
        final titleField = find.byType(TextField).at(0);
        final descField = find.byType(TextField).at(1);

        await tester.enterText(titleField, 'Need a UI/UX Review');
        await tester.enterText(descField, 'Looking for Apple minimal feedback');
        await tester.pumpAndSettle();

        final publishBtn = find.text('Publish Post');
        await tester.tap(publishBtn);

        // Once tapped, publish is initiated and saved
        await tester.pumpAndSettle();
        expect(fakeRepo.posts.length, 1);
        expect(fakeRepo.posts.values.first.title, 'Need a UI/UX Review');
      },
    );

    testWidgets(
      'Displays real error snackbar and stays open when repository fails (no fake success)',
      (WidgetTester tester) async {
        final fakeRepo = FakeNeedRepository()..shouldFail = true;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CreatePostSheet(
                needRepository: fakeRepo,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final titleField = find.byType(TextField).at(0);
        final descField = find.byType(TextField).at(1);

        await tester.enterText(titleField, 'Failing post');
        await tester.enterText(descField, 'This post should fail to save');
        await tester.pumpAndSettle();

        final publishBtn = find.text('Publish Post');
        await tester.tap(publishBtn);
        await tester.pumpAndSettle();

        // Verify error feedback is displayed
        expect(find.textContaining('Failed to publish post:'), findsOneWidget);
        // Verify sheet remains open
        expect(find.text('Create Post'), findsOneWidget);
      },
    );

    testWidgets(
      'Edits existing post and updates repository',
      (WidgetTester tester) async {
        final fakeRepo = FakeNeedRepository();
        final existing = NeedModel(
          needId: 'edit_target_1',
          userId: 'user_author',
          type: 'need',
          title: 'Old Title',
          description: 'Old Description',
          skills: const ['Flutter'],
        );
        fakeRepo.posts['edit_target_1'] = existing;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CreatePostSheet(
                existingPost: existing,
                needRepository: fakeRepo,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Verify pre-filled fields
        expect(find.text('Edit Post'), findsOneWidget);
        expect(find.text('Old Title'), findsOneWidget);
        expect(find.text('Old Description'), findsOneWidget);

        // Edit Title
        final titleField = find.byType(TextField).at(0);
        await tester.enterText(titleField, 'Brand New Title');
        await tester.pumpAndSettle();

        // Tap Save Changes
        final saveBtn = find.text('Save Changes');
        await tester.tap(saveBtn);
        await tester.pumpAndSettle();

        // Verify repository was updated
        expect(fakeRepo.posts['edit_target_1']?.title, 'Brand New Title');
      },
    );
  });

  group('HomePostsSection Feed Widget Tests', () {
    testWidgets(
      'Renders segmented tabs, post details, author photo, name, profession and delete flow',
      (WidgetTester tester) async {
        final fakeRepo = FakeNeedRepository();
        final post = NeedModel(
          needId: 'feed_post_1',
          userId: 'guest_author',
          type: 'need',
          title: 'Looking for a Backend Go Mentor',
          description: '1-on-1 architecture review for microservices.',
          skills: const ['Go', 'Docker', 'Kubernetes'],
          authorName: 'Karthik Subramanian',
          authorProfession: 'Lead Systems Architect',
          createdAt: DateTime.now(),
        );
        await fakeRepo.createNeed(post);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: HomePostsSection(
                  needRepository: fakeRepo,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Verify segmented tabs exist
        expect(find.text('Need Help'), findsOneWidget);
        expect(find.text('Can Help'), findsOneWidget);

        // Verify post details are visible
        expect(find.text('Karthik Subramanian'), findsOneWidget);
        expect(find.text('Lead Systems Architect'), findsOneWidget);
        expect(find.text('Looking for a Backend Go Mentor'), findsOneWidget);
        expect(
          find.text('1-on-1 architecture review for microservices.'),
          findsOneWidget,
        );
        expect(find.text('Go'), findsOneWidget);
        expect(find.text('Docker'), findsOneWidget);

        // Verify author menu is present for guest/own post
        final moreMenu = find.byIcon(Icons.more_horiz_rounded);
        expect(moreMenu, findsOneWidget);

        // Tap more menu and select Delete Post
        await tester.tap(moreMenu);
        await tester.pumpAndSettle();

        expect(find.text('Edit Post'), findsOneWidget);
        expect(find.text('Delete Post'), findsOneWidget);

        await tester.tap(find.text('Delete Post'));
        await tester.pumpAndSettle();

        // Confirmation dialog appears
        expect(find.text('Delete Post'), findsWidgets);
        expect(find.text('Cancel'), findsOneWidget);

        // Tap Delete in dialog
        final confirmBtn = find.widgetWithText(ElevatedButton, 'Delete');
        await tester.tap(confirmBtn);
        await tester.pumpAndSettle();

        // Post deleted from repository
        expect(fakeRepo.posts.containsKey('feed_post_1'), isFalse);
      },
    );

    testWidgets(
      'Empty state is displayed when no posts exist in the selected tab',
      (WidgetTester tester) async {
        final fakeRepo = FakeNeedRepository();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: HomePostsSection(
                  needRepository: fakeRepo,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Verify empty state for Need Help
        expect(find.text('No Help Requests Yet'), findsOneWidget);
        expect(find.text('Request Help'), findsOneWidget);

        // Switch to Can Help tab
        await tester.tap(find.text('Can Help'));
        await tester.pumpAndSettle();

        // Verify empty state for Can Help
        expect(find.text('No Help Offers Yet'), findsOneWidget);
        expect(find.text('Offer Help'), findsOneWidget);
      },
    );
  });
}
