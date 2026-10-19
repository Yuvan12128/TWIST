import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twist/core/localization/app_language.dart';
import 'package:twist/core/localization/app_localizations.dart';
import 'package:twist/core/localization/language_provider.dart';
import 'package:twist/core/services/analytics_service.dart';
import 'package:twist/core/services/storage_service.dart';
import 'package:twist/models/user_model.dart';
import 'package:twist/providers/auth_provider.dart';
import 'package:twist/providers/chat_provider.dart';
import 'package:twist/providers/profile_provider.dart';
import 'package:twist/providers/story_feed_provider.dart';
import 'package:twist/repositories/auth_repository.dart';
import 'package:twist/repositories/chat_repository.dart';
import 'package:twist/repositories/social_repository.dart';
import 'package:twist/repositories/story_repository.dart';
import 'package:twist/views/chat/chat_screen.dart';
import 'package:twist/views/chat/chats_screen.dart';
import 'package:twist/views/profile/profile_screen.dart';
import 'package:twist/core/utils/formatters.dart';
import 'package:twist/widgets/twist_button.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StorageService storageService;
  late AuthRepository authRepository;
  late AuthProvider authProvider;
  late StoryRepository storyRepository;
  late SocialRepository socialRepository;
  late ProfileProvider profileProvider;
  late ChatRepository chatRepository;
  late ChatProvider chatProvider;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    storageService = StorageService(prefs);
    authRepository = AuthRepository(storageService);
    authProvider = AuthProvider(authRepository);
    storyRepository = StoryRepository(storageService, enableSampleFallback: false);
    socialRepository = SocialRepository(storageService);
    profileProvider = ProfileProvider(storyRepository, storageService, socialRepository: socialRepository);
    chatRepository = ChatRepository();
    chatProvider = ChatProvider(chatRepository);

    await authProvider.signUpWithEmail('alice@twist.app', 'password123', 'Alice User');
  });

  group('1. ChatRepository & Deterministic ID Unit Tests', () {
    test('Deterministic conversation ID is identical regardless of user order', () {
      const userA = 'uid_alice_123';
      const userB = 'uid_bob_456';

      final id1 = ChatRepository.getConversationId(userA, userB);
      final id2 = ChatRepository.getConversationId(userB, userA);

      expect(id1, equals(id2));
      expect(id1, equals('conv_uid_alice_123_uid_bob_456'));
    });

    test('Self-chat is strictly prevented by throwing ArgumentError', () {
      const userA = 'uid_alice_123';
      expect(
        () => ChatRepository.getConversationId(userA, userA),
        throwsArgumentError,
      );
    });

    test('getOrCreateConversation returns same deterministic conversation without duplicates', () async {
      final userAlice = UserModel(
        uid: 'uid_alice',
        email: 'alice@twist.app',
        displayName: 'Alice',
        createdAt: DateTime.now(),
      );
      final userBob = UserModel(
        uid: 'uid_bob',
        email: 'bob@twist.app',
        displayName: 'Bob',
        createdAt: DateTime.now(),
      );

      final conv1 = await chatRepository.getOrCreateConversation(
        currentUser: userAlice,
        otherUser: userBob,
      );

      final conv2 = await chatRepository.getOrCreateConversation(
        currentUser: userBob,
        otherUser: userAlice,
      );

      expect(conv1.id, equals(conv2.id));
      expect(conv1.participantIds, containsAll(['uid_alice', 'uid_bob']));
    });

    test('sendMessage validates text, stores message and updates conversation lastMessage', () async {
      final userAlice = UserModel(
        uid: 'uid_alice',
        email: 'alice@twist.app',
        displayName: 'Alice',
        createdAt: DateTime.now(),
      );
      final userBob = UserModel(
        uid: 'uid_bob',
        email: 'bob@twist.app',
        displayName: 'Bob',
        createdAt: DateTime.now(),
      );

      final conv = await chatRepository.getOrCreateConversation(
        currentUser: userAlice,
        otherUser: userBob,
      );

      // Empty text is rejected
      final failedSend = await chatRepository.sendMessage(
        conversationId: conv.id,
        sender: userAlice,
        recipient: userBob,
        text: '   ',
      );
      expect(failedSend, isFalse);

      // Valid text succeeds
      final success = await chatRepository.sendMessage(
        conversationId: conv.id,
        sender: userAlice,
        recipient: userBob,
        text: 'Hey Bob, loved your sci-fi story!',
      );
      expect(success, isTrue);

      // Check messages stream
      final messages = await chatRepository.streamMessages(conv.id).first;
      expect(messages.length, equals(1));
      expect(messages.first.text, equals('Hey Bob, loved your sci-fi story!'));
      expect(messages.first.senderId, equals('uid_alice'));

      // Check conversation updated
      final convList = await chatRepository.streamConversations('uid_alice').first;
      expect(convList.first.lastMessage, equals('Hey Bob, loved your sci-fi story!'));
    });
  });

  group('2. ProfileScreen Message Button Widget Tests', () {
    testWidgets('Other user profile displays both Follow and Message buttons', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final otherUser = UserModel(
        uid: 'creator_karthik_99',
        email: 'karthik@twist.app',
        displayName: 'Karthik Master',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
            ChangeNotifierProvider<ProfileProvider>.value(value: profileProvider),
            ChangeNotifierProvider<ChatProvider>.value(value: chatProvider),
            ChangeNotifierProvider<StoryFeedProvider>(
              create: (_) => StoryFeedProvider(storyRepository, AnalyticsService()),
            ),
            ChangeNotifierProvider<LanguageProvider>(
              create: (_) => LanguageProvider(storageService),
            ),
          ],
          child: MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: [
              const AppLocalizationsDelegate(AppLanguage.en),
            ],
            home: ProfileScreen(
              userId: 'creator_karthik_99',
              initialUser: otherUser,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check other user details
      expect(find.text('Karthik Master'), findsAtLeastNWidgets(1));
      // Follow button is present
      expect(find.widgetWithText(TwistButton, '+ Follow'), findsOneWidget);
      // Message button is present
      expect(find.widgetWithText(TwistButton, 'Message'), findsOneWidget);
    });
  });

  group('3. ChatScreen Real-Time Messages Widget Tests', () {
    testWidgets('ChatScreen renders user header, empty state, and sends a new message', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final currentUser = authProvider.user!;
      final otherUser = UserModel(
        uid: 'user_priya_55',
        email: 'priya@twist.app',
        displayName: 'Priya Raman',
        createdAt: DateTime.now(),
      );

      final conv = await chatRepository.getOrCreateConversation(
        currentUser: currentUser,
        otherUser: otherUser,
      );

      // Open conversation in provider
      await chatProvider.openConversation(currentUser: currentUser, otherUser: otherUser);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
            ChangeNotifierProvider<ChatProvider>.value(value: chatProvider),
          ],
          child: MaterialApp(
            home: ChatScreen(
              conversation: conv,
              otherUser: otherUser,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check Header
      expect(find.text('Priya Raman'), findsOneWidget);
      expect(find.text('@priya'), findsOneWidget);

      // Check Empty State
      expect(find.text('Private 1-to-1 Chat'), findsOneWidget);

      // Type and send a message
      await tester.enterText(find.byType(TextField), 'Hello Priya! What is your next story?');
      await tester.pumpAndSettle();

      // Tap Send Button (circle icon button with arrow)
      final sendFinder = find.byIcon(Icons.arrow_upward_rounded);
      expect(sendFinder, findsOneWidget);
      await tester.tap(sendFinder);
      await tester.pumpAndSettle();

      // Message bubble appears
      expect(find.text('Hello Priya! What is your next story?'), findsOneWidget);

      // TextField is cleared
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text.isEmpty, isTrue);
    });
  });

  group('4. ChatsScreen Conversations List Widget Tests', () {
    testWidgets('ChatsScreen displays empty state when there are no conversations', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
            ChangeNotifierProvider<ChatProvider>.value(value: chatProvider),
          ],
          child: const MaterialApp(
            home: ChatsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Chats'), findsOneWidget);
      expect(find.text('No Conversations Yet'), findsOneWidget);
    });

    testWidgets('ChatsScreen displays conversation card when conversation exists', (tester) async {
      final currentUser = authProvider.user!;
      final otherUser = UserModel(
        uid: 'user_deepak_88',
        email: 'deepak@twist.app',
        displayName: 'Deepak V',
        createdAt: DateTime.now(),
      );

      final conv = await chatRepository.getOrCreateConversation(
        currentUser: currentUser,
        otherUser: otherUser,
      );

      await chatRepository.sendMessage(
        conversationId: conv.id,
        sender: otherUser,
        recipient: currentUser,
        text: 'The new horror ending is unlocked!',
      );

      chatProvider.initConversations(currentUser.uid);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
            ChangeNotifierProvider<ChatProvider>.value(value: chatProvider),
          ],
          child: const MaterialApp(
            home: ChatsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check conversation item
      expect(find.text('Deepak V'), findsOneWidget);
      expect(find.text('The new horror ending is unlocked!'), findsOneWidget);
    });
  });

  group('5. Chat Up-to-Date Timestamp Formatting Unit Tests', () {
    test('chatMessageTime formats exact time with AM/PM', () {
      final testDate = DateTime(2026, 10, 19, 14, 30);
      final formatted = Formatters.chatMessageTime(testDate);
      expect(formatted, contains('2:30'));
      expect(formatted, contains('PM'));
    });

    test('chatDateSeparator returns Today for current date and Yesterday for yesterday', () {
      final now = DateTime.now();
      expect(Formatters.chatDateSeparator(now), equals('Today'));

      final yesterday = now.subtract(const Duration(days: 1));
      expect(Formatters.chatDateSeparator(yesterday), equals('Yesterday'));
    });

    test('chatListTime returns time for today and Yesterday for yesterday', () {
      final now = DateTime.now();
      final formattedToday = Formatters.chatListTime(now);
      expect(formattedToday, matches(RegExp(r'\d+:\d+\s+[AP]M')));

      final yesterday = now.subtract(const Duration(days: 1));
      expect(Formatters.chatListTime(yesterday), equals('Yesterday'));
    });
  });

  group('6. Instagram Style Profile Widget Tests', () {
    testWidgets('Self profile renders Instagram-style stats, edit profile, and story grid', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
            ChangeNotifierProvider<ProfileProvider>.value(value: profileProvider),
            ChangeNotifierProvider<ChatProvider>.value(value: chatProvider),
            ChangeNotifierProvider<StoryFeedProvider>(
              create: (_) => StoryFeedProvider(storyRepository, AnalyticsService()),
            ),
            ChangeNotifierProvider<LanguageProvider>(
              create: (_) => LanguageProvider(storageService),
            ),
          ],
          child: const MaterialApp(
            home: ProfileScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check Instagram-style components
      expect(find.text('Stories'), findsOneWidget);
      expect(find.text('Followers'), findsOneWidget);
      expect(find.text('Following'), findsOneWidget);
      expect(find.text('Edit profile'), findsOneWidget);
      expect(find.text('Share profile'), findsOneWidget);
      expect(find.text('Top Plots'), findsOneWidget);
      expect(find.byIcon(Icons.grid_on_sharp), findsOneWidget);
    });
  });

  group('7. Blue Tick Read Receipts Unit & Widget Tests', () {
    test('Message is unread initially and markMessagesAsRead marks it read', () async {
      final userAlice = authProvider.user!;
      final userBob = UserModel(
        uid: 'user_bob_blue',
        email: 'bob@twist.app',
        displayName: 'Bob Blue',
        createdAt: DateTime.now(),
      );

      final conv = await chatRepository.getOrCreateConversation(
        currentUser: userAlice,
        otherUser: userBob,
      );

      await chatRepository.sendMessage(
        conversationId: conv.id,
        sender: userBob,
        recipient: userAlice,
        text: 'Testing blue tick seen status',
      );

      // Verify message is unread initially
      final msgsBefore = await chatRepository.streamMessages(conv.id).first;
      expect(msgsBefore.first.isRead, isFalse);

      // Alice opens chat and marks Bob's messages as read
      await chatRepository.markMessagesAsRead(
        conversationId: conv.id,
        currentUserId: userAlice.uid,
      );

      final msgsAfter = await chatRepository.streamMessages(conv.id).first;
      expect(msgsAfter.first.isRead, isTrue);
      expect(msgsAfter.first.readAt, isNotNull);
    });

    testWidgets('ChatScreen renders electric blue double tick when isRead is true', (tester) async {
      final currentUser = authProvider.user!;
      final otherUser = UserModel(
        uid: 'user_priya_read',
        email: 'priya_read@twist.app',
        displayName: 'Priya Reader',
        createdAt: DateTime.now(),
      );

      final conv = await chatRepository.getOrCreateConversation(
        currentUser: currentUser,
        otherUser: otherUser,
      );

      // Send a message from current user
      await chatRepository.sendMessage(
        conversationId: conv.id,
        sender: currentUser,
        recipient: otherUser,
        text: 'Did you see this ending?',
      );

      // Other user reads it
      await chatRepository.markMessagesAsRead(
        conversationId: conv.id,
        currentUserId: otherUser.uid,
      );

      await chatProvider.openConversation(
        currentUser: currentUser,
        otherUser: otherUser,
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
            ChangeNotifierProvider<ChatProvider>.value(value: chatProvider),
          ],
          child: MaterialApp(
            home: ChatScreen(
              conversation: conv,
              otherUser: otherUser,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Look for the blue double tick
      final iconFinder = find.byWidgetPredicate((widget) {
        return widget is Icon &&
            widget.icon == Icons.done_all_rounded &&
            widget.color == const Color(0xFF007AFF);
      });

      expect(iconFinder, findsOneWidget);
    });
  });
}
