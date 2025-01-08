import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_provider.dart';
import 'firebase_options.dart';
import 'home_screen.dart';
import 'auth_screen.dart';
import 'interests_screen.dart';
import 'theme.dart';
import 'database_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(const MyApp());
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling a background message: \${message.messageId}");
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'socialEventApp',
            theme: socialAppTheme.lightTheme, // Light theme
            darkTheme: socialAppTheme.darkTheme, // Dark theme
            themeMode: authProvider.themeMode, // Use theme mode from AuthProvider
            home: _getInitialScreen(authProvider),
            routes: {
              '/home': (context) => HomeScreen(),
              '/auth': (context) => AuthScreen(),
            },
            onGenerateRoute: (settings) {
              if (settings.name == '/interests') {
                final args = settings.arguments as String;
                return MaterialPageRoute(
                  builder: (context) {
                    return InterestsScreen(name: args);
                  },
                );
              }
              return null;
            },
          );
        },
      ),
    );
  }

  Widget _getInitialScreen(AuthProvider authProvider) {
    if (authProvider.isAuthenticated) {
      return HomeScreen();
    } else {
      return AuthScreen();
    }
  }
}

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseDatabase _realtimeDb = FirebaseDatabase.instance;

  Future<void> syncData(Map<String, dynamic> data, String docId) async {
    try {
      // Ghi dữ liệu vào Firestore
      await _firestore.collection('collection_name').doc(docId).set(data);

      // Ghi dữ liệu vào Realtime Database
      await _realtimeDb.ref('collection_name/$docId').set(data);

      print('Data synchronized successfully!');
    } catch (e) {
      print('Error syncing data: $e');
    }
  }

  Future<void> deleteData(String docId) async {
    try {
      // Xóa dữ liệu khỏi Firestore
      await _firestore.collection('collection_name').doc(docId).delete();

      // Xóa dữ liệu khỏi Realtime Database
      await _realtimeDb.ref('collection_name/$docId').remove();

      print('Data deleted successfully!');
    } catch (e) {
      print('Error deleting data: $e');
    }
  }
}
