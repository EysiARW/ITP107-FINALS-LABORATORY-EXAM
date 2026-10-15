import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:main/main.dart';
import 'package:main/models/post.dart';
import 'package:main/screens/details_screen.dart';
import 'package:main/screens/favorites_screen.dart';

class MockHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return FakeHttpClient();
  }
}

class FakeHttpClient extends Fake implements HttpClient {
  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async {
    return FakeHttpClientRequest();
  }

  @override
  void close({bool force = false}) {}
}

class FakeHttpClientRequest extends Fake implements HttpClientRequest {
  @override
  final HttpHeaders headers = FakeHttpHeaders();

  @override
  bool followRedirects = true;

  @override
  int maxRedirects = 5;

  @override
  int contentLength = -1;

  @override
  bool persistentConnection = false;

  @override
  bool bufferOutput = true;

  @override
  void add(List<int> data) {}

  @override
  Future addStream(Stream<List<int>> stream) async {
    await stream.drain();
  }

  @override
  Future<HttpClientResponse> close() async {
    return FakeHttpClientResponse();
  }
}

class FakeHttpHeaders extends Fake implements HttpHeaders {
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}

  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {}

  @override
  void forEach(void Function(String name, List<String> values) action) {
    action('content-type', ['application/json; charset=utf-8']);
  }
}

class FakeHttpClientResponse extends Stream<List<int>>
    with Fake
    implements HttpClientResponse {
  @override
  int get statusCode => 200;

  @override
  int get contentLength => utf8.encode(body).length;

  @override
  String get reasonPhrase => 'OK';

  @override
  bool get isRedirect => false;

  @override
  bool get persistentConnection => false;

  @override
  List<RedirectInfo> get redirects => const [];

  @override
  final HttpHeaders headers = FakeHttpHeaders();

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  static const String body =
      '[{"id": 1, "title": "Test Post 1", "body": "Body 1"}]';

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.value(utf8.encode(body)).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = MockHttpOverrides();

  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_test_');
    Hive.init(tempDir.path);
    await Hive.openBox('favoritesBox');
  });

  tearDownAll(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  testWidgets('Renders PostsScreen and displays fetched post',
      (WidgetTester tester) async {
    await tester.pumpWidget(const PostReaderApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Post Reader & Favorites'), findsOneWidget);
    expect(find.byIcon(Icons.favorite), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.text('Test Post 1'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('PostsScreen FAB opens create dialog and validates empty fields',
      (WidgetTester tester) async {
    await tester.pumpWidget(const PostReaderApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text('Create New Post'), findsOneWidget);
    expect(find.text('Create'), findsOneWidget);

    // Attempting to submit empty form
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    expect(find.text('Title cannot be empty'), findsOneWidget);
    expect(find.text('Body cannot be empty'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Hive CRUD operations work for favoritesBox',
      (WidgetTester tester) async {
    final box = Hive.box('favoritesBox');

    await tester.runAsync(() async {
      // Create
      const testPost = {
        'id': 101,
        'title': 'Test Post',
        'body': 'Test Body',
        'note': 'Initial note',
      };
      await box.put(101, testPost);
      expect(box.containsKey(101), isTrue);

      // Read
      final saved = Map<String, dynamic>.from(box.get(101) as Map);
      expect(saved['title'], 'Test Post');
      expect(saved['note'], 'Initial note');

      // Update
      saved['note'] = 'Updated note';
      await box.put(101, saved);
      final updated = Map<String, dynamic>.from(box.get(101) as Map);
      expect(updated['note'], 'Updated note');

      // Delete
      await box.delete(101);
      expect(box.containsKey(101), isFalse);
    });
  });

  testWidgets('Details screen can save post to favorites',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        routes: {
          '/details': (context) => const DetailsScreen(),
        },
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/details',
                arguments: {
                  'id': 42,
                  'title': 'Argument Post',
                  'body': 'Argument Body',
                },
              );
            },
            child: const Text('Go to details'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Go to details'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Post Details'), findsOneWidget);
    expect(find.text('Argument Post'), findsOneWidget);
    expect(find.text('Argument Body'), findsOneWidget);
    expect(find.text('Save to Favorites'), findsOneWidget);

    await tester.runAsync(() async {
      await tester.tap(find.text('Save to Favorites'));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final box = Hive.box('favoritesBox');
    expect(box.containsKey(42), isTrue);
    expect(find.text('Saved to Favorites'), findsOneWidget);

    ScaffoldMessenger.of(tester.element(find.byType(Scaffold)))
        .clearSnackBars();
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Favorites screen lists saved items, updates note, and deletes',
      (WidgetTester tester) async {
    final box = Hive.box('favoritesBox');
    await tester.runAsync(() async {
      await box.put(55, {
        'id': 55,
        'title': 'Favorite #55',
        'body': 'Body #55',
        'note': 'Old Note',
      });
    });
    await tester.pumpWidget(
      const MaterialApp(
        home: FavoritesScreen(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Favorites'), findsOneWidget);
    expect(find.text('Favorite #55'), findsOneWidget);
    expect(find.text('Note: Old Note'), findsOneWidget);

    // Edit note
    await tester.tap(find.byTooltip('Edit Note').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Edit Personal Note'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'New Personal Note');
    await tester.runAsync(() async {
      await tester.tap(find.text('Save Note'));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    final updated = Map<String, dynamic>.from(box.get(55) as Map);
    expect(updated['note'], 'New Personal Note');
    expect(find.text('Note: New Personal Note'), findsOneWidget);

    ScaffoldMessenger.of(tester.element(find.byType(Scaffold)))
        .clearSnackBars();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Delete item
    await tester.runAsync(() async {
      await tester.tap(find.byTooltip('Remove').last);
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(box.containsKey(55), isFalse);
    expect(find.text('Favorite #55'), findsNothing);

    ScaffoldMessenger.of(tester.element(find.byType(Scaffold)))
        .clearSnackBars();
    await tester.pumpWidget(const SizedBox());
  });

  test('Post model adheres to OOP encapsulation and serialization', () {
    final json = {
      'id': 1,
      'title': 'OOP Title',
      'body': 'OOP Body',
      'note': 'OOP Note',
    };
    final post = Post.fromJson(json);
    expect(post.id, 1);
    expect(post.title, 'OOP Title');
    expect(post.body, 'OOP Body');
    expect(post.note, 'OOP Note');
    expect(post.hasNote, isTrue);

    final map = post.toMap();
    expect(map['id'], 1);
    expect(map['title'], 'OOP Title');

    final copied = post.copyWith(note: 'Modified Note');
    expect(copied.note, 'Modified Note');
    expect(copied.id, post.id);

    final fromMap = Post.fromMap(map);
    expect(fromMap, equals(post));
  });

  testWidgets('Screens apply responsive maxWidth constraints for tablet/desktop',
      (WidgetTester tester) async {
    await tester.pumpWidget(const PostReaderApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    final constrainedBoxes =
        tester.widgetList<ConstrainedBox>(find.byType(ConstrainedBox));
    final hasResponsiveConstraint = constrainedBoxes.any(
      (box) => box.constraints.maxWidth == 800.0,
    );
    expect(hasResponsiveConstraint, isTrue);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Favorites screen supports swipe-to-dismiss deletion',
      (WidgetTester tester) async {
    final box = Hive.box('favoritesBox');
    await tester.runAsync(() async {
      await box.put(77, {
        'id': 77,
        'title': 'Swipe Item #77',
        'body': 'Swipe Body #77',
        'note': 'Swipe Note',
      });
    });
    await tester.pumpWidget(
      const MaterialApp(
        home: FavoritesScreen(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Swipe Item #77'), findsOneWidget);

    // Perform swipe from right to left
    await tester.drag(find.text('Swipe Item #77'), const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(box.containsKey(77), isFalse);
    expect(find.text('Swipe Item #77'), findsNothing);

    ScaffoldMessenger.of(tester.element(find.byType(Scaffold)))
        .clearSnackBars();
    await tester.pumpWidget(const SizedBox());
  });

  test('Favorites persist across box close and reopen', () async {
    final box = await Hive.openBox('persistenceTestBox');
    await box.put(99, {
      'id': 99,
      'title': 'Persistent Title',
      'body': 'Persistent Body',
      'note': 'Persisted Note',
    });

    await box.close();

    final reopenedBox = await Hive.openBox('persistenceTestBox');
    expect(reopenedBox.containsKey(99), isTrue);
    final item = Map<String, dynamic>.from(reopenedBox.get(99) as Map);
    expect(item['title'], 'Persistent Title');
    expect(item['note'], 'Persisted Note');

    await reopenedBox.close();
  });
}
