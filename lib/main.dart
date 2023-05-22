import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todo/firebase_options.dart';
import 'login_page.dart';
import 'todo_screen.dart';
import 'package:flutter/material.dart';

final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(ProviderScope(child: MyApp()));
}

final userProvider = StreamProvider<User?>((ref) {
  final auth = FirebaseAuth.instance;
  return auth.authStateChanges();
});

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Todo App',
      key: _scaffoldKey,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      debugShowCheckedModeBanner: false,
      home: Consumer(
        builder: (context, ref, _) {
          final userSnapshot = ref.watch(userProvider);
          return userSnapshot.when(
            data: (user) {
              return user != null
                  ? TodoScreen(
                      userId: user.uid,
                    )
                  : LoginPage();
            },
            loading: () => Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
            error: (error, stackTrace) {
              // Handle error state
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: $error'),
                ),
              );
              return Scaffold(
                body: Center(child: Text('Error: $error')),
              );
            },
          );
        },
      ),
    );
  }
}
