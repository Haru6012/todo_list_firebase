import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding(); //これをつけないと怒られる
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var taskList = <Task>[];

  Future<void> fetchTaskList() async {
    final snapshot = await FirebaseFirestore.instance.collection("tasks").get();
    taskList = snapshot.docs.map(Task.fromFireStore).toList();
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    fetchTaskList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("TODO"),
      ),
      body: Column(
        children: [
          ...taskList
              .map(
                (e) => ListTile(
                  title: Text(e.content),
                  trailing: IconButton(
                    onPressed: () {
                      //TODO 削除処理
                      final ref = e.ref;
                      if (ref != null) {
                        ref.delete();
                        taskList.remove(e);
                        setState(() {});
                      }
                    },
                    icon: const Icon(Icons.delete),
                  ),
                ),
              )
              .toList(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const AddTaskPage()));
          fetchTaskList();
        },
        child:const Icon(Icons.add),
      ),
    );
  }
}

class AddTaskPage extends StatefulWidget {
  const AddTaskPage({Key? key}) : super(key: key);

  @override
  _AddTaskPageState createState() => _AddTaskPageState();
}

class _AddTaskPageState extends State<AddTaskPage> {
  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController();
    return Scaffold(
      appBar: AppBar(
        title: const Text("タスク追加"),
        actions: [
          ElevatedButton(
            onPressed: () async {
              final content = controller.text;
              await FirebaseFirestore.instance.collection("tasks").add(
                    Task(
                            content: content,
                            done: false,
                            createdAt: DateTime.now(),
                            ref: null)
                        .toMap(),
                  );
              Navigator.of(context).pop();
            },
            child: const Text("追加"),
          ),
        ],
      ),
      body: TextFormField(
        controller: controller,
      ),
    );
  }
}

class Task {
  Task({
    required this.content,
    required this.done,
    required this.createdAt,
    required this.ref,
  });

  final String content;
  final bool done;
  final DateTime createdAt;
  final DocumentReference<Map<String, dynamic>>? ref;

  static Task fromFireStore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Task(
      content: data["content"],
      done: data["done"],
      createdAt: (data["createdAt"] as Timestamp).toDate(),
      ref: doc.reference,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      "content": content,
      "done": done,
      "createdAt": Timestamp.fromDate(createdAt),
    };
  }
}
