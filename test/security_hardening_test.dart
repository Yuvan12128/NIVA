import 'package:flutter_test/flutter_test.dart';
import 'package:niva/features/chat/data/chat_repository.dart';
import 'package:niva/features/reviews/data/review_repository.dart';
import 'package:niva/features/safety/data/safety_repository.dart';
import 'package:niva/features/safety/presentation/widgets/report_sheet.dart';
import 'package:flutter/material.dart';

void main() {
  group('Security Hardening & Production Fixes Unit Tests', () {
    test('1. SafetyRepository generates deterministic report document IDs', () {
      final docIdWithRef = SafetyRepository.generateReportDocId(
        'user_reporter_1',
        'user_reported_2',
        'ref_need_99',
      );
      expect(docIdWithRef, 'user_reporter_1_user_reported_2_ref_need_99');

      // Safe fallback when referenceId is null, empty, or whitespace
      final docIdNullRef = SafetyRepository.generateReportDocId(
        'user_reporter_1',
        'user_reported_2',
        null,
      );
      expect(docIdNullRef, 'user_reporter_1_user_reported_2_general');

      final docIdEmptyRef = SafetyRepository.generateReportDocId(
        'user_reporter_1',
        'user_reported_2',
        '   ',
      );
      expect(docIdEmptyRef, 'user_reporter_1_user_reported_2_general');
    });

    test(
      '2. SafetyRepository.reportUser creates report without pre-read query',
      () async {
        final safety = SafetyRepository();

        // Should succeed and return the deterministic ID without throwing permission-denied
        final reportId = await safety.reportUser(
          reporterId: 'usr_alpha',
          reportedUserId: 'usr_beta',
          reason: 'spam',
          description: 'Repeated unwanted spam messages.',
          referenceId: 'chat_123',
        );

        expect(reportId, 'usr_alpha_usr_beta_chat_123');
      },
    );

    test('3. ReviewRepository submits review without client-side trustScore mutation', () async {
      final reviewRepo = ReviewRepository();

      // Submit review returns review document ID
      final reviewId = await reviewRepo.submitReview(
        connectionRequestId: 'req_conn_1',
        needId: 'need_abc',
        reviewerId: 'reviewer_1',
        revieweeId: 'reviewee_2',
        rating: 5,
        reviewText: 'Great collaboration!',
      );

      expect(reviewId, isNotEmpty);
      // Trust score calculation remains accessible purely for display/metrics
      final calculated = ReviewRepository.calculateTrustScore([5, 4, 5]);
      expect(calculated, 93);
    });

    test(
      '4. ChatRepository rejects message exceeding 2000 characters',
      () async {
        final chatRepo = ChatRepository();

        // Empty text is rejected
        expect(
          () => chatRepo.sendMessage(
            chatId: 'userA_userB',
            senderId: 'userA',
            receiverId: 'userB',
            text: '   ',
          ),
          throwsA(isA<ArgumentError>()),
        );

        // Oversized text (>2000 chars) is rejected
        final oversizedText = 'A' * 2001;
        expect(
          () => chatRepo.sendMessage(
            chatId: 'userA_userB',
            senderId: 'userA',
            receiverId: 'userB',
            text: oversizedText,
          ),
          throwsA(isA<ArgumentError>()),
        );

        // 2000 characters is allowed
        final maxAllowedText = 'B' * 2000;
        final msgId = await chatRepo.sendMessage(
          chatId: 'userA_userB',
          senderId: 'userA',
          receiverId: 'userB',
          text: maxAllowedText,
        );
        expect(msgId, isNotEmpty);
      },
    );

    testWidgets(
      '5. ReportSheet successfully submits report via deterministic ID',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ReportSheet(
                currentUserId: 'reporter_user_123',
                reportedUserId: 'target_user_456',
                reportedUserName: 'Ananya Sharma',
                referenceId: 'need_999',
              ),
            ),
          ),
        );
        await tester.pump();

        // Select 'Spam or Advertising' radio option
        final spamOption = find.text('Spam or Advertising');
        expect(spamOption, findsOneWidget);
        await tester.tap(spamOption);
        await tester.pump();

        // Tap 'Submit Report' button
        final submitButton = find.text('Submit Report');
        expect(submitButton, findsOneWidget);
        await tester.ensureVisible(submitButton);
        await tester.tap(submitButton);
        await tester.pumpAndSettle();

        // Confirmation success message appears
        expect(find.text('Report Submitted'), findsOneWidget);
        expect(
          find.textContaining('Thank you for helping keep NIVA a safe'),
          findsOneWidget,
        );
        expect(find.text('Done'), findsOneWidget);
      },
    );
  });
}
