import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todo/firebase_options.dart';
import 'login_page.dart';

class TodoScreen extends StatefulWidget {
  final String userId;

  TodoScreen({required this.userId});

  @override
  _TodoScreenState createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  TextEditingController _todoController = TextEditingController();
  TextEditingController _priorityController = TextEditingController();
  TextEditingController _tagsController = TextEditingController();
  TextEditingController _recurringController = TextEditingController();
  late Stream<QuerySnapshot> _todoStream;

  @override
  void initState() {
    super.initState();
    _todoStream = _firestore
        .collection('todos')
        .doc(widget.userId) // Use the authenticated user's userId
        .collection('user_todos')
        .snapshots();
  }

  Future<void> _addTodo() async {
    final userId = _auth.currentUser!.uid;
    final todo = _todoController.text.trim();
    final priority = _priorityController.text.trim();
    final tags = _tagsController.text.trim();
    final recurring = _recurringController.text.trim();

    if (todo.isNotEmpty && priority.isNotEmpty && tags.isNotEmpty) {
      await _firestore
          .collection('todos')
          .doc(userId)
          .collection('user_todos')
          .add({
        'todo': todo,
        'priority': priority,
        'tags': tags,
        'recurring': recurring
      });
      _todoController.clear();
      _priorityController.clear();
      _tagsController.clear();
      _recurringController.clear();
    }
  }

  Future<void> _editTodo(String todoId) async {
    final userId = _auth.currentUser!.uid;
    final todo = _todoController.text.trim();
    final priority = _priorityController.text.trim();
    final tags = _tagsController.text.trim();
    final recurring = _recurringController.text.trim();

    if (todo.isNotEmpty && priority.isNotEmpty && tags.isNotEmpty) {
      await _firestore
          .collection('todos')
          .doc(userId)
          .collection('user_todos')
          .doc(todoId)
          .update({
        'todo': todo,
        'priority': priority,
        'tags': tags,
        'recurring': recurring
      });
      _todoController.clear();
      _priorityController.clear();
      _tagsController.clear();
      _recurringController.clear();
    }
  }

  Future<void> _deleteTodo(String todoId) async {
    final userId = _auth.currentUser!.uid;
    await _firestore
        .collection('todos')
        .doc(userId)
        .collection('user_todos')
        .doc(todoId)
        .delete();
  }

  Future<void> _signOut() async {
    try {
      await _auth.signOut();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      ); // Go back to the login screen
    } catch (e) {
      print('Logout error: $e');
      // Show an error message to the user
    }
  }

  Future<void> _showLogoutConfirmationDialog() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Logout'),
          content: Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: Text('Logout'),
              onPressed: _signOut,
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Todo App'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _showLogoutConfirmationDialog,
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextFormField(
              controller: _todoController,
              decoration: InputDecoration(labelText: 'Task'),
            ),
            TextFormField(
              controller: _priorityController,
              decoration: InputDecoration(labelText: 'Priority'),
            ),
            TextFormField(
              controller: _tagsController,
              decoration: InputDecoration(labelText: 'Tags'),
            ),
            TextFormField(
              controller: _recurringController,
              decoration: InputDecoration(labelText: 'Recurring'),
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _addTodo,
              child: Text('Add Task'),
            ),
            SizedBox(height: 16.0),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _todoStream,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final todos = snapshot.data!.docs;
                    return ListView.builder(
                      itemCount: todos.length,
                      itemBuilder: (context, index) {
                        final todo =
                            todos[index].data() as Map<String, dynamic>;
                        final todoId = todos[index].id;
                        return ListTile(
                          title: Text(todo['todo']),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Priority: ${todo['priority']}'),
                              Text('Tags: ${todo['tags']}'),
                              Text('Recurring: ${todo['recurring']}'),
                            ],
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () => _deleteTodo(todoId),
                          ),
                          onTap: () {
                            _todoController.text = todo['todo'];
                            _priorityController.text = todo['priority'];
                            _tagsController.text = todo['tags'];
                            _recurringController.text = todo['recurring'];

                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: Text('Edit Task'),
                                  content: SingleChildScrollView(
                                    child: Column(
                                      children: [
                                        TextFormField(
                                          controller: _todoController,
                                          decoration: InputDecoration(
                                              labelText: 'Task'),
                                        ),
                                        TextFormField(
                                          controller: _priorityController,
                                          decoration: InputDecoration(
                                              labelText: 'Priority'),
                                        ),
                                        TextFormField(
                                          controller: _tagsController,
                                          decoration: InputDecoration(
                                              labelText: 'Tags'),
                                        ),
                                        TextFormField(
                                          controller: _recurringController,
                                          decoration: InputDecoration(
                                              labelText: 'Recurring'),
                                        ),
                                      ],
                                    ),
                                  ),
                                  actions: [
                                    ElevatedButton(
                                      onPressed: () {
                                        _editTodo(todoId);
                                        Navigator.of(context).pop();
                                      },
                                      child: Text('Save Changes'),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        );
                      },
                    );
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else {
                    return Center(child: CircularProgressIndicator());
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
