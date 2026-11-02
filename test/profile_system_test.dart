import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niva/core/utils/url_validator.dart';
import 'package:niva/features/profile/presentation/profile_screen.dart';
import 'package:niva/features/profile/presentation/widgets/edit_profile_sheet.dart';
import 'package:niva/features/user/data/user_model.dart';
import 'package:niva/features/user/data/user_repository.dart';

class FakeProfileUserRepository extends UserRepository {
  final Map<String, UserModel> users = {};
  final Map<String, String> privateEmails = {};

  @override
  Future<void> createUserProfile(UserModel user) async {
    users[user.uid] = user;
    if (user.email.isNotEmpty) {
      privateEmails[user.uid] = user.email;
    }
  }

  @override
  Future<UserModel?> getUserProfile(String uid) async {
    final user = users[uid];
    if (user == null) return null;
    return user.copyWith(email: privateEmails[uid] ?? user.email);
  }

  @override
  Future<String?> getUserPrivateEmail(String uid) async {
    return privateEmails[uid];
  }

  @override
  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    final existing = users[uid];
    if (existing == null) return;

    final email = data['email'] as String?;
    if (email != null && email.isNotEmpty) {
      privateEmails[uid] = email;
    }

    users[uid] = existing.copyWith(
      name: data['name'] as String? ?? existing.name,
      bio: data['bio'] as String? ?? existing.bio,
      profession: data['profession'] as String? ?? existing.profession,
      education: data['education'] as String? ?? existing.education,
      experience: data['experience'] as String? ?? existing.experience,
      city: data['city'] as String? ?? existing.city,
      language: data['language'] as String? ?? existing.language,
      skills:
          (data['skills'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          existing.skills,
      canHelpWith:
          (data['canHelpWith'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          existing.canHelpWith,
      lookingFor:
          (data['lookingFor'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          existing.lookingFor,
      linkedInUrl: data['linkedInUrl'] as String? ?? existing.linkedInUrl,
      githubUrl: data['githubUrl'] as String? ?? existing.githubUrl,
      portfolioUrl: data['portfolioUrl'] as String? ?? existing.portfolioUrl,
      otherSocialUrl:
          data['otherSocialUrl'] as String? ?? existing.otherSocialUrl,
      availability: data['availability'] as String? ?? existing.availability,
    );
  }
}

void main() {
  group('UrlValidator Utility Tests', () {
    test('Normalizes URLs without scheme by prepending https://', () {
      expect(
        UrlValidator.normalize('linkedin.com/in/arun'),
        'https://linkedin.com/in/arun',
      );
      expect(
        UrlValidator.normalize('https://github.com/torvalds'),
        'https://github.com/torvalds',
      );
      expect(UrlValidator.normalize(''), '');
      expect(UrlValidator.normalize('   '), '');
    });

    test('Validates LinkedIn URLs accurately', () {
      expect(
        UrlValidator.validateUrl(
          'https://linkedin.com/in/arunkumar',
          platform: 'LinkedIn',
        ),
        isNull,
      );
      expect(
        UrlValidator.validateUrl(
          'linkedin.com/in/arunkumar',
          platform: 'LinkedIn',
        ),
        isNull,
      );
      expect(
        UrlValidator.validateUrl(
          'https://twitter.com/arunkumar',
          platform: 'LinkedIn',
        ),
        'Must be a valid LinkedIn URL (e.g. https://linkedin.com/in/username)',
      );
    });

    test('Validates GitHub URLs accurately', () {
      expect(
        UrlValidator.validateUrl(
          'https://github.com/flutter',
          platform: 'GitHub',
        ),
        isNull,
      );
      expect(
        UrlValidator.validateUrl('github.com/flutter', platform: 'GitHub'),
        isNull,
      );
      expect(
        UrlValidator.validateUrl(
          'https://gitlab.com/flutter',
          platform: 'GitHub',
        ),
        'Must be a valid GitHub URL (e.g. https://github.com/username)',
      );
    });

    test('Validates generic website/portfolio URLs', () {
      expect(UrlValidator.validateUrl('https://myportfolio.dev'), isNull);
      expect(UrlValidator.validateUrl('portfolio.com/projects'), isNull);
      expect(UrlValidator.validateUrl('not-a-valid-url'), isNotNull);
    });

    test('Optional empty URLs pass validation with null', () {
      expect(UrlValidator.validateUrl(''), isNull);
      expect(UrlValidator.validateUrl('   '), isNull);
      expect(UrlValidator.validateUrl(null), isNull);
    });
  });

  group('UserModel Serialization & Phase 2 Fields Tests', () {
    test('Serializes all Phase 2 profile fields correctly', () {
      const user = UserModel(
        uid: 'user_123',
        name: 'Sundar Pitchai',
        email: 'sundar@gmail.com',
        photoUrl: 'https://lh3.googleusercontent.com/photo.jpg',
        bio: 'Product leader building technology for everyone.',
        profession: 'Chief Executive Officer',
        education: 'Stanford University, Wharton School',
        experience: '20+ years leading product and engineering',
        skills: ['Leadership', 'Cloud Infrastructure', 'Product Strategy'],
        canHelpWith: ['Mentorship', 'Scaling Startups'],
        lookingFor: ['AI Research Collaborators'],
        linkedInUrl: 'https://linkedin.com/in/sundarpichai',
        githubUrl: 'https://github.com/google',
        portfolioUrl: 'https://about.google',
        otherSocialUrl: 'https://x.com/sundarpichai',
      );

      final map = user.toMap(includeEmail: false);

      // Verify privacy by default
      expect(map.containsKey('email'), isFalse);
      expect(map['name'], 'Sundar Pitchai');
      expect(map['profession'], 'Chief Executive Officer');
      expect(map['education'], 'Stanford University, Wharton School');
      expect(
        map['experience'],
        '20+ years leading product and engineering',
      );
      expect(map['skills'], [
        'Leadership',
        'Cloud Infrastructure',
        'Product Strategy',
      ]);
      expect(map['linkedInUrl'], 'https://linkedin.com/in/sundarpichai');
      expect(map['githubUrl'], 'https://github.com/google');
      expect(map['portfolioUrl'], 'https://about.google');
      expect(map['otherSocialUrl'], 'https://x.com/sundarpichai');
    });

    test('Deserializes all Phase 2 profile fields from Firestore map', () {
      final rawMap = {
        'name': 'Radha Ravi',
        'photoUrl': 'https://example.com/radha.png',
        'bio': 'Passionate Flutter & backend developer in Chennai.',
        'profession': 'Senior Software Architect',
        'education': 'Anna University, B.E. Computer Science',
        'experience': '8+ years in distributed systems',
        'skills': ['Dart', 'Flutter', 'Go', 'GCP'],
        'canHelpWith': ['Flutter Code Review', 'Clean Architecture'],
        'lookingFor': ['Mobile UI/UX Designer'],
        'linkedInUrl': 'https://linkedin.com/in/radharavi',
        'githubUrl': 'https://github.com/radharavi',
        'portfolioUrl': 'https://radharavi.dev',
        'otherSocialUrl': 'https://blog.radharavi.dev',
        'city': 'Chennai',
        'language': 'Tamil, English',
        'availability': 'Available',
      };

      final user = UserModel.fromMap(
        'user_456',
        rawMap,
        email: 'radha@gmail.com',
      );

      expect(user.uid, 'user_456');
      expect(user.name, 'Radha Ravi');
      expect(user.email, 'radha@gmail.com');
      expect(user.profession, 'Senior Software Architect');
      expect(user.education, 'Anna University, B.E. Computer Science');
      expect(user.experience, '8+ years in distributed systems');
      expect(user.skills, ['Dart', 'Flutter', 'Go', 'GCP']);
      expect(user.linkedInUrl, 'https://linkedin.com/in/radharavi');
      expect(user.githubUrl, 'https://github.com/radharavi');
      expect(user.portfolioUrl, 'https://radharavi.dev');
      expect(user.otherSocialUrl, 'https://blog.radharavi.dev');
    });

    test('copyWith updates specified fields while preserving others', () {
      const user = UserModel(
        uid: 'user_789',
        name: 'Priya Raman',
        profession: 'UI Designer',
        education: 'NIFT Chennai',
      );

      final updated = user.copyWith(
        profession: 'Lead Product Designer',
        experience: '6 years at high-growth startups',
      );

      expect(updated.name, 'Priya Raman');
      expect(updated.education, 'NIFT Chennai');
      expect(updated.profession, 'Lead Product Designer');
      expect(updated.experience, '6 years at high-growth startups');
    });
  });

  group('EditProfileSheet & ProfileScreen Widget Tests', () {
    testWidgets(
      'EditProfileSheet populates initial fields and validates invalid URLs',
      (WidgetTester tester) async {
        final fakeRepo = FakeProfileUserRepository();
        const testUser = UserModel(
          uid: 'user_edit_test',
          name: 'Anand Kumar',
          email: 'anand@gmail.com',
          profession: 'Full Stack Engineer',
          linkedInUrl: 'https://linkedin.com/in/anand',
        );
        await fakeRepo.createUserProfile(testUser);

        UserModel? updatedProfile;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EditProfileSheet(
                user: testUser,
                userRepository: fakeRepo,
                onProfileUpdated: (u) => updatedProfile = u,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Verify initial field values are populated
        expect(find.text('Anand Kumar'), findsOneWidget);
        expect(find.text('Full Stack Engineer'), findsOneWidget);

        // Enter an invalid LinkedIn URL
        final linkedInFinder = find.byWidgetPredicate(
          (w) =>
              w is TextField &&
              w.decoration?.hintText == 'https://linkedin.com/in/username',
        );
        await tester.ensureVisible(linkedInFinder);
        await tester.enterText(linkedInFinder, 'https://facebook.com/anand');
        await tester.pumpAndSettle();

        // Tap Save Changes button
        final saveBtn = find.text('Save Changes');
        await tester.ensureVisible(saveBtn);
        await tester.tap(saveBtn);
        await tester.pumpAndSettle();

        // Verify inline error message
        expect(
          find.text(
            'Must be a valid LinkedIn URL (e.g. https://linkedin.com/in/username)',
          ),
          findsOneWidget,
        );
        expect(updatedProfile, isNull);

        // Fix the URL to a valid LinkedIn URL
        await tester.enterText(
          linkedInFinder,
          'https://linkedin.com/in/anandkumar',
        );
        await tester.pumpAndSettle();

        // Tap Save Changes again
        await tester.tap(saveBtn);
        await tester.pumpAndSettle();

        // Verify profile updated in repository
        final saved = await fakeRepo.getUserProfile('user_edit_test');
        expect(saved?.linkedInUrl, 'https://linkedin.com/in/anandkumar');
      },
    );

    testWidgets(
      'ProfileScreen renders complete professional profile with Apple minimal styling',
      (WidgetTester tester) async {
        final fakeRepo = FakeProfileUserRepository();
        const testUser = UserModel(
          uid: 'user_profile_view',
          name: 'Kavitha Swaminathan',
          email: 'kavitha@niva.community',
          profession: 'Design Systems Lead',
          bio: 'Crafting minimalist, intuitive digital experiences.',
          education: 'IIT Madras, M.Des',
          experience: '7 years building accessible mobile apps',
          skills: ['Figma', 'Flutter UI', 'Design Tokens'],
          canHelpWith: ['UX Audits', 'Typography'],
          lookingFor: ['Mobile Architect'],
          linkedInUrl: 'https://linkedin.com/in/kavitha',
          githubUrl: 'https://github.com/kavitha',
          portfolioUrl: 'https://kavitha.design',
          otherSocialUrl: 'https://kavitha.substack.com',
        );
        await fakeRepo.createUserProfile(testUser);

        await tester.pumpWidget(
          MaterialApp(
            home: ProfileScreen(
              targetUserId: 'user_profile_view',
              initialProfile: testUser,
              isOwnProfileOverride: true,
              userRepository: fakeRepo,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Verify Name and Profession
        expect(find.text('Kavitha Swaminathan'), findsOneWidget);
        expect(find.text('Design Systems Lead'), findsOneWidget);

        // Verify Bio
        expect(
          find.text('Crafting minimalist, intuitive digital experiences.'),
          findsOneWidget,
        );

        // Verify Private Gmail indicator
        expect(find.text('kavitha@niva.community'), findsOneWidget);
        expect(find.text('Private'), findsOneWidget);

        // Verify Social pills
        expect(find.text('LinkedIn'), findsOneWidget);
        expect(find.text('GitHub'), findsOneWidget);
        expect(find.text('Portfolio'), findsOneWidget);
        expect(find.text('Website'), findsOneWidget);

        // Verify Professional Background
        expect(find.text('Professional Background'), findsOneWidget);
        expect(
          find.text('7 years building accessible mobile apps'),
          findsOneWidget,
        );
        expect(find.text('IIT Madras, M.Des'), findsOneWidget);

        // Verify Skills
        expect(find.text('Skills & Expertise'), findsOneWidget);
        expect(find.text('Figma'), findsOneWidget);
        expect(find.text('Flutter UI'), findsOneWidget);

        // Verify Preserved sections
        expect(find.text('Trust & Verification'), findsOneWidget);
        expect(find.text('I Need'), findsOneWidget);
        expect(find.text('I Can Help With'), findsOneWidget);
        expect(find.text('Edit Profile'), findsOneWidget);
      },
    );

    testWidgets(
      'ProfileScreen peer profile hides private email and displays action buttons',
      (WidgetTester tester) async {
        final fakeRepo = FakeProfileUserRepository();
        const peerUser = UserModel(
          uid: 'user_peer_view',
          name: 'Arunmozhi Varman',
          email: 'arunmozhi@private.domain',
          profession: 'Cloud Architect',
          bio: 'Building resilient cloud systems.',
        );
        await fakeRepo.createUserProfile(peerUser);

        await tester.pumpWidget(
          MaterialApp(
            home: ProfileScreen(
              targetUserId: 'user_peer_view',
              initialProfile: peerUser,
              isOwnProfileOverride: false,
              userRepository: fakeRepo,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Verify name and profession
        expect(find.text('Arunmozhi Varman'), findsOneWidget);
        expect(find.text('Cloud Architect'), findsOneWidget);

        // Verify private email is strictly hidden from peer view
        expect(find.text('arunmozhi@private.domain'), findsNothing);
        expect(find.text('Edit Profile'), findsNothing);

        // Verify peer interaction buttons are visible
        expect(find.text('Send Connection Request'), findsOneWidget);
        expect(find.text('Direct Message'), findsOneWidget);
        expect(find.text('Report Profile'), findsOneWidget);
      },
    );
  });
}
