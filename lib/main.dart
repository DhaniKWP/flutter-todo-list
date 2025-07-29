import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

void main() => runApp(const NabilaToDoApp());

class NabilaToDoApp extends StatelessWidget {
  const NabilaToDoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'To-Do Nabila',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'ComicNeue',
        primarySwatch: Colors.pink,
        scaffoldBackgroundColor: Colors.pink[50],
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      home: const ToDoPage(),
    );
  }
}

class Task {
  String title;
  String date;
  String time;
  bool isDone;

  Task({required this.title, required this.date, required this.time, this.isDone = false});

  Map<String, dynamic> toJson() => {
        'title': title,
        'date': date,
        'time': time,
        'isDone': isDone,
      };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
        title: json['title'],
        date: json['date'],
        time: json['time'],
        isDone: json['isDone'],
      );
}

class ToDoPage extends StatefulWidget {
  const ToDoPage({super.key});
  @override
  State<ToDoPage> createState() => _ToDoPageState();
}

class _ToDoPageState extends State<ToDoPage> {
  List<Task> tasks = [];
  List<Task> filteredTasks = [];
  final titleController = TextEditingController();
  String filter = "";
  String selectedDayName = "";
  String statusFilter = "Semua";

  @override
  void initState() {
    super.initState();
    loadTasks();
  }

  Future<void> saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode(tasks.map((e) => e.toJson()).toList());
    await prefs.setString('tasks', data);
  }

  Future<void> loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('tasks');
    if (data != null) {
      final jsonList = jsonDecode(data) as List;
      tasks = jsonList.map((e) => Task.fromJson(e)).toList();
      applyFilter();
    }
  }

  void addTask(String title) async {
    final now = DateTime.now();
    final selectedDate = filter.isNotEmpty
        ? DateFormat('EEEE, dd MMMM yyyy').parse(filter)
        : now;

    final date = DateFormat('EEEE, dd MMMM yyyy').format(selectedDate);
    final time = DateFormat('HH:mm').format(now);

    final task = Task(title: title, date: date, time: time);
    setState(() => tasks.add(task));
    await saveTasks();
    applyFilter();
  }

  void toggleDone(int index) async {
    setState(() => filteredTasks[index].isDone = !filteredTasks[index].isDone);
    await saveTasks();
  }

  void deleteTask(int index) async {
    final realTask = filteredTasks[index];
    tasks.removeWhere((t) => t.title == realTask.title && t.date == realTask.date && t.time == realTask.time);
    setState(() => filteredTasks.removeAt(index));
    await saveTasks();
  }

  void applyFilter() {
    setState(() {
      filteredTasks = tasks.where((task) {
        final matchDate = filter.isEmpty || task.date == filter;
        final matchStatus = statusFilter == "Semua" ||
            (statusFilter == "Selesai" && task.isDone) ||
            (statusFilter == "Belum Selesai" && !task.isDone);
        return matchDate && matchStatus;
      }).toList();

      if (filter.isNotEmpty) {
        try {
          final parsedDate = DateFormat('EEEE, dd MMMM yyyy').parse(filter);
          selectedDayName = DateFormat('EEEE').format(parsedDate);
        } catch (_) {
          selectedDayName = "";
        }
      } else {
        selectedDayName = "";
      }
    });
  }

  double calculateProgress() {
    if (filteredTasks.isEmpty) return 0;
    final completed = filteredTasks.where((t) => t.isDone).length;
    return completed / filteredTasks.length;
  }

  void markAllDone() async {
    for (var task in filteredTasks) {
      task.isDone = true;
    }
    await saveTasks();
    applyFilter();
  }

  void editTask(int index) async {
    final task = filteredTasks[index];
    final controller = TextEditingController(text: task.title);

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit Tugas"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "Judul tugas"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                task.title = controller.text;
              });
              saveTasks();
              Navigator.pop(context);
            },
            child: const Text("Simpan"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = calculateProgress();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.pinkAccent,
        title: const Text('🦄 To-Do List Nabila', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month, color: Colors.white),
            onPressed: () async {
              final selected = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2023),
                lastDate: DateTime(2030),
              );
              if (selected != null) {
                filter = DateFormat('EEEE, dd MMMM yyyy').format(selected);
                applyFilter();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.clear, color: Colors.white),
            onPressed: () {
              filter = "";
              applyFilter();
            },
          )
        ],
      ),
      body: Column(
        children: [
          if (filter.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.pink.shade100),
                ),
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Colors.pink),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Kegiatan hari $selectedDayName\n$filter",
                        style: const TextStyle(fontSize: 14, color: Colors.pink, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 500),
              tween: Tween(begin: 0, end: progress),
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                backgroundColor: Colors.pink[100],
                valueColor: AlwaysStoppedAnimation<Color>(Colors.pink),
                minHeight: 10,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              DropdownButton<String>(
                value: statusFilter,
                borderRadius: BorderRadius.circular(10),
                dropdownColor: Colors.white,
                style: const TextStyle(color: Colors.pink),
                items: const [
                  DropdownMenuItem(value: "Semua", child: Text("Semua")),
                  DropdownMenuItem(value: "Belum Selesai", child: Text("Belum Selesai")),
                  DropdownMenuItem(value: "Selesai", child: Text("Selesai")),
                ],
                onChanged: (value) {
                  if (value != null) {
                    statusFilter = value;
                    applyFilter();
                  }
                },
              ),
              TextButton.icon(
                onPressed: markAllDone,
                icon: const Icon(Icons.check, color: Colors.green),
                label: const Text("Tandai semua selesai", style: TextStyle(color: Colors.green)),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: titleController,
              decoration: InputDecoration(
                hintText: 'Masukkan tugas Nabila💖',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add_circle_outline, color: Colors.pink),
                  onPressed: () {
                    if (titleController.text.isNotEmpty) {
                      addTask(titleController.text);
                      titleController.clear();
                    }
                  },
                ),
              ),
            ),
          ),
          Expanded(
            child: filteredTasks.isEmpty
                ? const Center(child: Text("Tidak ada tugas 😴", style: TextStyle(color: Colors.pink)))
                : ListView.builder(
                    itemCount: filteredTasks.length,
                    itemBuilder: (_, index) {
                      final task = filteredTasks[index];
                      return Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        color: Colors.white,
                        elevation: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: ListTile(
                          leading: Checkbox(
                            value: task.isDone,
                            onChanged: (_) => toggleDone(index),
                            activeColor: Colors.pink,
                          ),
                          title: Text(
                            task.title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              decoration: task.isDone ? TextDecoration.lineThrough : null,
                              color: Colors.pink[700],
                            ),
                          ),
                          subtitle: Text('${task.date} • ${task.time}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.orange),
                                onPressed: () => editTask(index),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_forever, color: Colors.pink),
                                onPressed: () => deleteTask(index),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
