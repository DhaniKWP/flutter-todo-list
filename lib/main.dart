import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const NabilaToDoApp());
}

class Category {
  String id;
  String name;
  Color color;

  Category({required this.id, required this.name, required this.color});

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'color': color.value,
      };

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: json['id'],
        name: json['name'],
        color: Color(json['color']),
      );
}

class Task {
  String id;
  String title;
  String categoryId;
  String date; // Format: yyyy-MM-dd
  bool isDone;

  Task({required this.id, required this.title, required this.categoryId, required this.date, this.isDone = false});

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'categoryId': categoryId,
        'date': date,
        'isDone': isDone,
      };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
        id: json['id'],
        title: json['title'],
        categoryId: json['categoryId'],
        date: json['date'],
        isDone: json['isDone'],
      );
}

class NabilaToDoApp extends StatelessWidget {
  const NabilaToDoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'To-Do Nabila',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'ComicNeue',
        scaffoldBackgroundColor: const Color(0xFFFFF0F5),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.pink,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
        ),
        cardTheme: CardThemeData(
          elevation: 8,
          shadowColor: Colors.pink.withOpacity(0.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: const BorderSide(color: Colors.pink, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  DateTime selectedDate = DateTime.now();
  List<Category> categories = [];
  List<Task> allTasks = [];
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    loadData();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    
    final categoriesData = prefs.getString('categories');
    if (categoriesData != null) {
      final jsonList = jsonDecode(categoriesData) as List;
      categories = jsonList.map((e) => Category.fromJson(e)).toList();
    }

    final tasksData = prefs.getString('tasks');
    if (tasksData != null) {
      final jsonList = jsonDecode(tasksData) as List;
      allTasks = jsonList.map((e) => Task.fromJson(e)).toList();
    }

    setState(() {});
  }

  void onDateChanged(DateTime date) {
    setState(() {
      selectedDate = date;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: IndexedStack(
          index: _currentIndex,
          children: [
            CalendarScreen(
              selectedDate: selectedDate,
              categories: categories,
              allTasks: allTasks,
              onDateChanged: onDateChanged,
              onDataChanged: loadData,
            ),
            CategoryListScreen(
              categories: categories,
              allTasks: allTasks,
              onDataChanged: loadData,
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.pink.shade400, Colors.pink.shade600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.pink.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedItemColor: Colors.white,
            unselectedItemColor: Colors.pink.shade100,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.calendar_today_rounded),
                activeIcon: Icon(Icons.calendar_today_rounded, size: 28),
                label: 'Kalender',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.folder_rounded),
                activeIcon: Icon(Icons.folder_rounded, size: 28),
                label: 'Kategori',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CalendarScreen extends StatefulWidget {
  final DateTime selectedDate;
  final List<Category> categories;
  final List<Task> allTasks;
  final Function(DateTime) onDateChanged;
  final VoidCallback onDataChanged;

  const CalendarScreen({
    super.key,
    required this.selectedDate,
    required this.categories,
    required this.allTasks,
    required this.onDateChanged,
    required this.onDataChanged,
  });

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> with TickerProviderStateMixin {
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _bounceAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  List<Task> getTasksForDate(DateTime date) {
    final dateStr = "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    return widget.allTasks.where((task) => task.date == dateStr).toList();
  }

  bool hasTasksOnDate(DateTime date) {
    return getTasksForDate(date).isNotEmpty;
  }

  String getFormattedDay(DateTime date) {
    const days = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
    return days[date.weekday % 7];
  }

  String getFormattedDate(DateTime date) {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Widget _buildCalendarGrid() {
    final currentDate = DateTime.now();
    final displayMonth = DateTime(widget.selectedDate.year, widget.selectedDate.month, 1);
    final firstDay = DateTime(displayMonth.year, displayMonth.month, 1);
    final lastDay = DateTime(displayMonth.year, displayMonth.month + 1, 0);
    
    // Calculate start date (first Monday of the calendar grid)
    int firstWeekday = firstDay.weekday;
    if (firstWeekday == 7) firstWeekday = 0; // Convert Sunday from 7 to 0
    final startDate = firstDay.subtract(Duration(days: firstWeekday));
    
    // Calculate how many weeks we need to show
    final endDate = startDate.add(const Duration(days: 41)); // 6 weeks = 42 days
    final totalWeeks = ((endDate.difference(startDate).inDays + 1) / 7).ceil();
    
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header bulan dengan navigasi
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () {
                      final prevMonth = DateTime(displayMonth.year, displayMonth.month - 1, 1);
                      widget.onDateChanged(prevMonth);
                    },
                    icon: const Icon(Icons.chevron_left, color: Colors.pink),
                  ),
                  Text(
                    getFormattedMonthYear(displayMonth),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.pink,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      final nextMonth = DateTime(displayMonth.year, displayMonth.month + 1, 1);
                      widget.onDateChanged(nextMonth);
                    },
                    icon: const Icon(Icons.chevron_right, color: Colors.pink),
                  ),
                ],
              ),
            ),
            // Days header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min']
                    .map((day) => Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              day,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                                color: Colors.pink.shade400,
                              ),
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ),
            // Calendar grid
            ...List.generate(totalWeeks.clamp(4, 6), (weekIndex) {
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: List.generate(7, (dayIndex) {
                    final date = startDate.add(Duration(days: weekIndex * 7 + dayIndex));
                    final isCurrentMonth = date.month == displayMonth.month && date.year == displayMonth.year;
                    final isSelected = date.day == widget.selectedDate.day &&
                        date.month == widget.selectedDate.month &&
                        date.year == widget.selectedDate.year;
                    final isToday = date.day == currentDate.day &&
                        date.month == currentDate.month &&
                        date.year == currentDate.year;
                    final hasTasks = hasTasksOnDate(date);

                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          widget.onDateChanged(date);
                          _bounceController.forward().then((_) {
                            _bounceController.reverse();
                          });
                        },
                        child: AnimatedBuilder(
                          animation: _bounceAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: isSelected ? _bounceAnimation.value : 1.0,
                              child: Container(
                                height: 40,
                                margin: const EdgeInsets.all(1),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.pink
                                      : isToday
                                          ? Colors.pink.shade100
                                          : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  border: hasTasks && !isSelected && isCurrentMonth
                                      ? Border.all(color: Colors.pink.shade300, width: 1.5)
                                      : null,
                                ),
                                child: Stack(
                                  children: [
                                    Center(
                                      child: Text(
                                        date.day.toString(),
                                        style: TextStyle(
                                          color: isSelected
                                              ? Colors.white
                                              : isCurrentMonth
                                                  ? isToday
                                                      ? Colors.pink.shade700
                                                      : Colors.black87
                                                  : Colors.grey.shade400,
                                          fontWeight: isSelected || isToday
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    if (hasTasks && !isSelected && isCurrentMonth)
                                      Positioned(
                                        top: 2,
                                        right: 2,
                                        child: Container(
                                          width: 6,
                                          height: 6,
                                          decoration: BoxDecoration(
                                            color: Colors.pink.shade500,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  }),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  String getFormattedMonthYear(DateTime date) {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final selectedTasks = getTasksForDate(widget.selectedDate);
    final groupedTasks = <String, List<Task>>{};
    
    for (final task in selectedTasks) {
      final category = widget.categories.firstWhere(
        (cat) => cat.id == task.categoryId,
        orElse: () => Category(id: '', name: 'Unknown', color: Colors.grey),
      );
      if (!groupedTasks.containsKey(category.name)) {
        groupedTasks[category.name] = [];
      }
      groupedTasks[category.name]!.add(task);
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.pink.shade50,
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.pink.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.calendar_today_rounded,
                        color: Colors.pink,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        '🦄 Kalender Nabila',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.pink,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Calendar - Made more compact
              Expanded(
                flex: 3,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: Card(
                    child: _buildCalendarGrid(),
                  ),
                ),
              ),
              // Selected date info - Made more compact
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.pink.shade400, Colors.pink.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.pink.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.event_note_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${getFormattedDay(widget.selectedDate)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            getFormattedDate(widget.selectedDate),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${selectedTasks.length} tugas',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Tasks for selected date
              Expanded(
                flex: 2,
                child: selectedTasks.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.event_available_rounded,
                              size: 48,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Tidak ada tugas\ndi tanggal ini',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: groupedTasks.length,
                        itemBuilder: (context, index) {
                          final categoryName = groupedTasks.keys.elementAt(index);
                          final categoryTasks = groupedTasks[categoryName]!;
                          final category = widget.categories.firstWhere(
                            (cat) => cat.name == categoryName,
                            orElse: () => Category(id: '', name: categoryName, color: Colors.grey),
                          );

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ExpansionTile(
                              leading: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: category.color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              title: Text(
                                categoryName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.pink,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Text(
                                '${categoryTasks.length} tugas',
                                style: const TextStyle(fontSize: 12),
                              ),
                              childrenPadding: EdgeInsets.zero,
                              children: categoryTasks.map((task) {
                                return ListTile(
                                  dense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                                  leading: Transform.scale(
                                    scale: 0.8,
                                    child: Checkbox(
                                      value: task.isDone,
                                      activeColor: category.color,
                                      onChanged: (value) async {
                                        setState(() {
                                          task.isDone = value ?? false;
                                        });
                                        
                                        // Save to SharedPreferences
                                        final prefs = await SharedPreferences.getInstance();
                                        final updatedData = jsonEncode(widget.allTasks.map((t) => t.toJson()).toList());
                                        await prefs.setString('tasks', updatedData);
                                        widget.onDataChanged();
                                      },
                                    ),
                                  ),
                                  title: Text(
                                    task.title,
                                    style: TextStyle(
                                      decoration: task.isDone ? TextDecoration.lineThrough : null,
                                      color: task.isDone ? Colors.grey : Colors.black87,
                                      fontSize: 13,
                                    ),
                                  ),
                                  trailing: IconButton(
                                    iconSize: 20,
                                    icon: Icon(Icons.open_in_new, color: category.color),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => TaskListScreen(
                                            category: category,
                                            selectedDate: widget.selectedDate,
                                            onTasksChanged: widget.onDataChanged,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              }).toList(),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CategoryListScreen extends StatefulWidget {
  final List<Category> categories;
  final List<Task> allTasks;
  final VoidCallback onDataChanged;

  const CategoryListScreen({
    super.key,
    required this.categories,
    required this.allTasks,
    required this.onDataChanged,
  });

  @override
  State<CategoryListScreen> createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends State<CategoryListScreen> with TickerProviderStateMixin {
  final categoryController = TextEditingController();
  late AnimationController _staggerController;

  final List<Color> categoryColors = [
    Colors.pink,
    Colors.purple,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.red,
    Colors.teal,
    Colors.indigo,
  ];

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _staggerController.forward();
  }

  @override
  void dispose() {
    _staggerController.dispose();
    super.dispose();
  }

  Future<void> saveData() async {
    final prefs = await SharedPreferences.getInstance();
    final categoriesData = jsonEncode(widget.categories.map((c) => c.toJson()).toList());
    final tasksData = jsonEncode(widget.allTasks.map((t) => t.toJson()).toList());
    await prefs.setString('categories', categoriesData);
    await prefs.setString('tasks', tasksData);
  }

  void addCategory() {
    if (categoryController.text.isNotEmpty) {
      final category = Category(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: categoryController.text,
        color: categoryColors[widget.categories.length % categoryColors.length],
      );
      setState(() {
        widget.categories.add(category);
      });
      categoryController.clear();
      saveData();
      widget.onDataChanged();
    }
  }

  void editCategory(Category category) {
    categoryController.text = category.name;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Edit Kategori'),
        content: TextField(
          controller: categoryController,
          decoration: const InputDecoration(hintText: 'Nama kategori'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              categoryController.clear();
              Navigator.pop(context);
            },
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (categoryController.text.isNotEmpty) {
                setState(() {
                  category.name = categoryController.text;
                });
                categoryController.clear();
                saveData();
                widget.onDataChanged();
                Navigator.pop(context);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void deleteCategory(Category category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Kategori'),
        content: Text('Yakin ingin menghapus kategori "${category.name}"?\nSemua tugas dalam kategori ini juga akan terhapus.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              setState(() {
                widget.categories.remove(category);
                widget.allTasks.removeWhere((task) => task.categoryId == category.id);
              });
              saveData();
              widget.onDataChanged();
              Navigator.pop(context);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  int getTaskCount(String categoryId) {
    return widget.allTasks.where((task) => task.categoryId == categoryId).length;
  }

  int getCompletedTaskCount(String categoryId) {
    return widget.allTasks.where((task) => task.categoryId == categoryId && task.isDone).length;
  }

  double getProgress(String categoryId) {
    final total = getTaskCount(categoryId);
    if (total == 0) return 0.0;
    final completed = getCompletedTaskCount(categoryId);
    return completed / total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.pink.shade50,
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.pink.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(
                        Icons.folder_rounded,
                        color: Colors.pink,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        '🗂️ Kategori To-Do',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.pink,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Add category input
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.pink.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: categoryController,
                    decoration: InputDecoration(
                      hintText: 'Tambahkan kategori baru 💖',
                      suffixIcon: Container(
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.pink,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.add, color: Colors.white),
                          onPressed: addCategory,
                        ),
                      ),
                    ),
                    onSubmitted: (_) => addCategory(),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Categories list
              Expanded(
                child: widget.categories.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.folder_open_rounded,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Belum ada kategori\nTambahkan kategori pertama Anda!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: widget.categories.length,
                        itemBuilder: (context, index) {
                          final category = widget.categories[index];
                          final taskCount = getTaskCount(category.id);
                          final completedCount = getCompletedTaskCount(category.id);
                          final progress = getProgress(category.id);

                          return AnimatedBuilder(
                            animation: _staggerController,
                            builder: (context, child) {
                              final animationValue = Tween<double>(
                                begin: 0.0,
                                end: 1.0,
                              ).animate(CurvedAnimation(
                                parent: _staggerController,
                                curve: Interval(
                                  index * 0.1,
                                  1.0,
                                  curve: Curves.easeOutBack,
                                ),
                              ));

                              return Transform.translate(
                                offset: Offset(0, 50 * (1 - animationValue.value)),
                                child: Opacity(
                                  opacity: animationValue.value,
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    child: Card(
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(20),
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => TaskListScreen(
                                                category: category,
                                                selectedDate: DateTime.now(),
                                                onTasksChanged: widget.onDataChanged,
                                              ),
                                            ),
                                          );
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(20),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                category.color.withOpacity(0.1),
                                                category.color.withOpacity(0.05),
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Container(
                                                    width: 32,
                                                    height: 32,
                                                    decoration: BoxDecoration(
                                                      color: category.color,
                                                      shape: BoxShape.circle,
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: category.color.withOpacity(0.3),
                                                          blurRadius: 8,
                                                          offset: const Offset(0, 2),
                                                        ),
                                                      ],
                                                    ),
                                                    child: const Icon(
                                                      Icons.folder_rounded,
                                                      color: Colors.white,
                                                      size: 18,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 16),
                                                  Expanded(
                                                    child: Text(
                                                      category.name,
                                                      style: const TextStyle(
                                                        fontSize: 20,
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.pink,
                                                      ),
                                                    ),
                                                  ),
                                                  PopupMenuButton(
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(15),
                                                    ),
                                                    onSelected: (value) {
                                                      if (value == 'edit') {
                                                        editCategory(category);
                                                      } else if (value == 'delete') {
                                                        deleteCategory(category);
                                                      }
                                                    },
                                                    itemBuilder: (context) => [
                                                      const PopupMenuItem(
                                                        value: 'edit',
                                                        child: Row(
                                                          children: [
                                                            Icon(Icons.edit_rounded, color: Colors.blue),
                                                            SizedBox(width: 12),
                                                            Text('Edit'),
                                                          ],
                                                        ),
                                                      ),
                                                      const PopupMenuItem(
                                                        value: 'delete',
                                                        child: Row(
                                                          children: [
                                                            Icon(Icons.delete_rounded, color: Colors.red),
                                                            SizedBox(width: 12),
                                                            Text('Hapus'),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 16),
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.task_alt_rounded,
                                                    color: Colors.grey[600],
                                                    size: 20,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    '$completedCount dari $taskCount tugas selesai',
                                                    style: TextStyle(
                                                      color: Colors.grey[600],
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 12),
                                              ClipRRect(
                                                borderRadius: BorderRadius.circular(10),
                                                child: TweenAnimationBuilder<double>(
                                                  duration: const Duration(milliseconds: 1000),
                                                  curve: Curves.easeOutCubic,
                                                  tween: Tween<double>(begin: 0, end: progress),
                                                  builder: (context, value, _) => LinearProgressIndicator(
                                                    value: value,
                                                    backgroundColor: Colors.grey[300],
                                                    valueColor: AlwaysStoppedAnimation<Color>(category.color),
                                                    minHeight: 12,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    '${(progress * 100).toInt()}% selesai',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey[600],
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: category.color.withOpacity(0.1),
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    child: Text(
                                                      '$taskCount tugas',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: category.color,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TaskListScreen extends StatefulWidget {
  final Category category;
  final DateTime selectedDate;
  final VoidCallback onTasksChanged;

  const TaskListScreen({
    super.key,
    required this.category,
    required this.selectedDate,
    required this.onTasksChanged,
  });

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> with TickerProviderStateMixin {
  List<Task> tasks = [];
  final taskController = TextEditingController();
  late AnimationController _animationController;
  late AnimationController _addTaskController;
  late Animation<double> _addTaskAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _addTaskController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _addTaskAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _addTaskController, curve: Curves.elasticOut),
    );
    loadTasks();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _addTaskController.dispose();
    super.dispose();
  }

  Future<void> loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final tasksData = prefs.getString('tasks');
    if (tasksData != null) {
      final jsonList = jsonDecode(tasksData) as List;
      final allTasks = jsonList.map((e) => Task.fromJson(e)).toList();
      setState(() {
        tasks = allTasks.where((task) => task.categoryId == widget.category.id).toList();
      });
    }
  }

  Future<void> saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final tasksData = prefs.getString('tasks');
    List<Task> allTasks = [];
    
    if (tasksData != null) {
      final jsonList = jsonDecode(tasksData) as List;
      allTasks = jsonList.map((e) => Task.fromJson(e)).toList();
    }

    // Update all tasks
    allTasks.removeWhere((task) => task.categoryId == widget.category.id);
    allTasks.addAll(tasks);

    final updatedData = jsonEncode(allTasks.map((t) => t.toJson()).toList());
    await prefs.setString('tasks', updatedData);
    widget.onTasksChanged();
  }

  void addTask() {
    if (taskController.text.isNotEmpty) {
      final dateStr = "${widget.selectedDate.year.toString().padLeft(4, '0')}-${widget.selectedDate.month.toString().padLeft(2, '0')}-${widget.selectedDate.day.toString().padLeft(2, '0')}";
      final task = Task(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: taskController.text,
        categoryId: widget.category.id,
        date: dateStr,
      );
      setState(() {
        tasks.add(task);
      });
      taskController.clear();
      saveTasks();
      
      _addTaskController.forward().then((_) {
        _addTaskController.reverse();
      });
    }
  }

  void toggleTask(int index) {
    setState(() {
      tasks[index].isDone = !tasks[index].isDone;
    });
    saveTasks();
    
    _animationController.forward().then((_) {
      _animationController.reverse();
    });
  }

  void editTask(int index) {
    taskController.text = tasks[index].title;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Edit Tugas'),
        content: TextField(
          controller: taskController,
          decoration: const InputDecoration(hintText: 'Nama tugas'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              taskController.clear();
              Navigator.pop(context);
            },
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (taskController.text.isNotEmpty) {
                setState(() {
                  tasks[index].title = taskController.text;
                });
                taskController.clear();
                saveTasks();
                Navigator.pop(context);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void deleteTask(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Tugas'),
        content: Text('Yakin ingin menghapus tugas "${tasks[index].title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              setState(() {
                tasks.removeAt(index);
              });
              saveTasks();
              Navigator.pop(context);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String getFormattedDay(DateTime date) {
    const days = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
    return days[date.weekday % 7];
  }

  String getFormattedDate(DateTime date) {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  int get completedTasks => tasks.where((task) => task.isDone).length;
  double get progress => tasks.isEmpty ? 0.0 : completedTasks / tasks.length;

  @override
  Widget build(BuildContext context) {
    final tasksForSelectedDate = tasks.where((task) => task.date == "${widget.selectedDate.year.toString().padLeft(4, '0')}-${widget.selectedDate.month.toString().padLeft(2, '0')}-${widget.selectedDate.day.toString().padLeft(2, '0')}").toList();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              widget.category.color.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(Icons.arrow_back_rounded, color: widget.category.color),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '📝 ${widget.category.name}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.pink,
                            ),
                          ),
                          Text(
                            '${getFormattedDay(widget.selectedDate)}, ${getFormattedDate(widget.selectedDate)}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Progress card
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [widget.category.color, widget.category.color.withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: widget.category.color.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.trending_up_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Progress Hari Ini',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '$completedTasks dari ${tasksForSelectedDate.length} tugas selesai',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${tasksForSelectedDate.isEmpty ? 0 : (tasksForSelectedDate.where((t) => t.isDone).length / tasksForSelectedDate.length * 100).toInt()}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 1000),
                        curve: Curves.easeOutCubic,
                        tween: Tween<double>(
                          begin: 0,
                          end: tasksForSelectedDate.isEmpty ? 0 : tasksForSelectedDate.where((t) => t.isDone).length / tasksForSelectedDate.length,
                        ),
                        builder: (context, value, _) => LinearProgressIndicator(
                          value: value,
                          backgroundColor: Colors.white.withOpacity(0.3),
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                          minHeight: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Add task input
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: AnimatedBuilder(
                  animation: _addTaskAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _addTaskAnimation.value,
                      child: Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: widget.category.color.withOpacity(0.2),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: taskController,
                          decoration: InputDecoration(
                            hintText: 'Tambahkan tugas baru 💖',
                            suffixIcon: Container(
                              margin: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: widget.category.color,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.add_rounded, color: Colors.white),
                                onPressed: addTask,
                              ),
                            ),
                          ),
                          onSubmitted: (_) => addTask(),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              // Tasks list
              Expanded(
                child: tasksForSelectedDate.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.task_alt_rounded,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Belum ada tugas\nTambahkan tugas pertama Anda!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: tasksForSelectedDate.length,
                        itemBuilder: (context, index) {
                          final task = tasksForSelectedDate[index];
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Card(
                              elevation: task.isDone ? 2 : 8,
                              shadowColor: widget.category.color.withOpacity(0.2),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  gradient: task.isDone
                                      ? LinearGradient(
                                          colors: [
                                            Colors.grey.shade100,
                                            Colors.grey.shade50,
                                          ],
                                        )
                                      : LinearGradient(
                                          colors: [
                                            Colors.white,
                                            widget.category.color.withOpacity(0.05),
                                          ],
                                        ),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 8,
                                  ),
                                  leading: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    child: Transform.scale(
                                      scale: 1.2,
                                      child: Checkbox(
                                        value: task.isDone,
                                        activeColor: widget.category.color,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        onChanged: (_) => toggleTask(index),
                                      ),
                                    ),
                                  ),
                                  title: AnimatedDefaultTextStyle(
                                    duration: const Duration(milliseconds: 300),
                                    style: TextStyle(
                                      decoration: task.isDone ? TextDecoration.lineThrough : null,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: task.isDone ? Colors.grey : Colors.black87,
                                    ),
                                    child: Text(task.title),
                                  ),
                                  trailing: PopupMenuButton(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    onSelected: (value) {
                                      if (value == 'edit') {
                                        editTask(index);
                                      } else if (value == 'delete') {
                                        deleteTask(index);
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'edit',
                                        child: Row(
                                          children: [
                                            Icon(Icons.edit_rounded, color: Colors.blue),
                                            SizedBox(width: 12),
                                            Text('Edit'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(Icons.delete_rounded, color: Colors.red),
                                            SizedBox(width: 12),
                                            Text('Hapus'),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}