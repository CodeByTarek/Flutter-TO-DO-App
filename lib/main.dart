import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const TodoApp());
}

// ---------------- MODELS ----------------
enum Priority { low, medium, high }

class Task {
  final String id;
  String title;
  String description;
  Priority priority;
  bool completed;
  String sectionId; // which section this task belongs to
  DateTime? reminder; // optional soft reminder

  Task({
    required this.id,
    required this.title,
    required this.description,
    this.priority = Priority.low,
    this.completed = false,
    required this.sectionId,
    this.reminder,
  });
}

class Section {
  final String id;
  String title;

  Section({required this.id, required this.title});
}

// ---------------- PROVIDERS ----------------
class SectionProvider extends ChangeNotifier {
  final List<Section> _sections = [Section(id: 'inbox', title: 'Inbox')];

  List<Section> get sections => List.unmodifiable(_sections);

  void addSection(String title) {
    _sections.add(Section(id: DateTime.now().millisecondsSinceEpoch.toString(), title: title));
    notifyListeners();
  }

  void updateSection(String id, String title) {
    final s = _sections.firstWhere((e) => e.id == id);
    s.title = title;
    notifyListeners();
  }

  void deleteSection(String id) {
    if (id == 'inbox') return; // protect default
    _sections.removeWhere((s) => s.id == id);
    notifyListeners();
  }
}

class TaskProvider extends ChangeNotifier {
  final List<Task> _tasks = [];

  List<Task> get tasks => List.unmodifiable(_tasks);

  List<Task> tasksForSection(String sectionId) => _tasks.where((t) => t.sectionId == sectionId).toList();

  void addTask(String title, String description, Priority priority, String sectionId, DateTime? reminder) {
    _tasks.insert(
      0,
      Task(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        description: description,
        priority: priority,
        sectionId: sectionId,
        reminder: reminder,
      ),
    );
    notifyListeners();
  }

  void deleteTask(String id) {
    _tasks.removeWhere((task) => task.id == id);
    notifyListeners();
  }

  void updateTask(String id, String title, String description, Priority priority, String sectionId, DateTime? reminder) {
    final t = _tasks.firstWhere((e) => e.id == id);
    t.title = title;
    t.description = description;
    t.priority = priority;
    t.sectionId = sectionId;
    t.reminder = reminder;
    notifyListeners();
  }

  void toggleComplete(String id) {
    final t = _tasks.firstWhere((e) => e.id == id);
    t.completed = !t.completed;
    notifyListeners();
  }

  Task getById(String id) => _tasks.firstWhere((t) => t.id == id);
}

// ---------------- ROOT ----------------
class TodoApp extends StatelessWidget {
  const TodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SectionProvider()),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorSchemeSeed: Colors.indigo,
          useMaterial3: true,
          textTheme: const TextTheme(bodyLarge: TextStyle(fontSize: 16)),
        ),
        home: const SectionsHome(),
      ),
    );
  }
}

// ---------------- SECTIONS HOME (Option B) ----------------
class SectionsHome extends StatefulWidget {
  const SectionsHome({super.key});

  @override
  State<SectionsHome> createState() => _SectionsHomeState();
}

class _SectionsHomeState extends State<SectionsHome> {
  String _newSectionTitle = '';

  @override
  Widget build(BuildContext context) {
    final sections = Provider.of<SectionProvider>(context).sections;

    return Scaffold(
      appBar: AppBar(title: const Text('Sections'), centerTitle: true),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Add Section'),
        onPressed: () => _showAddSectionDialog(context),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: sections.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final s = sections[index];
          return Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              title: Text(s.title, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${Provider.of<TaskProvider>(context).tasksForSection(s.id).length} tasks'),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _showEditSectionDialog(context, s),
                ),
                if (s.id != 'inbox')
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: () => _confirmDeleteSection(context, s),
                  ),
              ]),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SectionPage(section: s))),
            ),
          );
        },
      ),
    );
  }

  void _showAddSectionDialog(BuildContext context) {
    _newSectionTitle = '';
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('New Section'),
        content: TextField(
          onChanged: (v) => _newSectionTitle = v,
          decoration: const InputDecoration(hintText: 'Section name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (_newSectionTitle.trim().isEmpty) return;
              Provider.of<SectionProvider>(context, listen: false).addSection(_newSectionTitle.trim());
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditSectionDialog(BuildContext context, Section s) {
    var tmp = s.title;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Section'),
        content: TextField(
          controller: TextEditingController(text: s.title),
          onChanged: (v) => tmp = v,
          decoration: const InputDecoration(hintText: 'Section name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (tmp.trim().isEmpty) return;
              Provider.of<SectionProvider>(context, listen: false).updateSection(s.id, tmp.trim());
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteSection(BuildContext context, Section s) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Section'),
        content: Text('Delete "${s.title}"? Tasks will move to Inbox.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              // move tasks to inbox
              final tasks = Provider.of<TaskProvider>(context, listen: false).tasksForSection(s.id);
              for (var t in tasks) {
                Provider.of<TaskProvider>(context, listen: false).updateTask(t.id, t.title, t.description, t.priority, 'inbox', t.reminder);
              }

              Provider.of<SectionProvider>(context, listen: false).deleteSection(s.id);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ---------------- SECTION PAGE (list of tasks in a section) ----------------
class SectionPage extends StatefulWidget {
  final Section section;
  const SectionPage({super.key, required this.section});

  @override
  State<SectionPage> createState() => _SectionPageState();
}

class _SectionPageState extends State<SectionPage> with SingleTickerProviderStateMixin {
  String _search = '';
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TaskProvider>(context);
    final tasks = provider.tasksForSection(widget.section.id);
    final filtered = tasks.where((t) {
      final q = _search.toLowerCase();
      return t.title.toLowerCase().contains(q) || t.description.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.section.title),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        )
                      ],
                    ),
                    child: TextField(
                      onChanged: (v) => setState(() => _search = v),
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: 'Search tasks in section... ',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                FloatingActionButton(
                  mini: true,
                  heroTag: 'addTaskBtn',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AddEditTaskPage(sectionId: widget.section.id)),
                  ),
                  child: const Icon(Icons.add),
                )
              ],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFe8f0ff), Color(0xFFffffff)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: filtered.isEmpty
              ? Center(
                  key: const ValueKey('empty'),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ScaleTransition(
                        scale: Tween(begin: 0.9, end: 1.0).animate(CurvedAnimation(parent: _animController, curve: Curves.elasticOut)),
                        child: const Icon(Icons.list_alt, size: 80, color: Colors.indigo),
                      ),
                      const SizedBox(height: 12),
                      const Text('No tasks yet in this section', style: TextStyle(fontSize: 18)),
                      const SizedBox(height: 6),
                      const Text('Tap + to add tasks to this section.')
                    ],
                  ),
                )
              : ListView.builder(
                  key: const ValueKey('list'),
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final task = filtered[index];
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeOut,
                      transform: Matrix4.identity()..scale(task.completed ? 0.995 : 1.0),
                      child: Card(
                        elevation: 6,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        margin: const EdgeInsets.only(bottom: 14),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => TaskDetailsPage(taskId: task.id)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12),
                            child: Row(
                              children: [
                                GestureDetector(
                                  onTap: () => provider.toggleComplete(task.id),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: task.completed
                                          ? const LinearGradient(colors: [Colors.green, Colors.greenAccent])
                                          : const LinearGradient(colors: [Colors.white, Colors.white]),
                                      border: Border.all(color: Colors.grey.shade300),
                                    ),
                                    child: Icon(
                                      task.completed ? Icons.check : Icons.circle_outlined,
                                      color: task.completed ? Colors.white : Colors.grey,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              task.title,
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                decoration: task.completed ? TextDecoration.lineThrough : null,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: _priorityColor(task.priority).withOpacity(0.12),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(Icons.flag, size: 14, color: _priorityColor(task.priority)),
                                                const SizedBox(width: 6),
                                                Text(
                                                  task.priority.name.toUpperCase(),
                                                  style: TextStyle(fontSize: 12, color: _priorityColor(task.priority)),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        task.description,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(color: Colors.grey.shade700, decoration: task.completed ? TextDecoration.lineThrough : null),
                                      ),
                                      const SizedBox(height: 8),
                                      if (task.reminder != null)
                                        Row(
                                          children: [
                                            const Icon(Icons.alarm, size: 16),
                                            const SizedBox(width: 6),
                                            Text(_formatDateTime(task.reminder!)),
                                          ],
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      tooltip: 'Edit',
                                      onPressed: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (_) => AddEditTaskPage(editTask: task)),
                                      ),
                                      icon: const Icon(Icons.edit),
                                    ),
                                    IconButton(
                                      tooltip: 'Delete',
                                      onPressed: () => provider.deleteTask(task.id),
                                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }

  Color _priorityColor(Priority p) {
    switch (p) {
      case Priority.high:
        return Colors.redAccent;
      case Priority.medium:
        return Colors.orange;
      case Priority.low:
      default:
        return Colors.green;
    }
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}-${_two(dt.month)}-${_two(dt.day)} ${_two(dt.hour)}:${_two(dt.minute)}';
  }

  String _two(int n) => n.toString().padLeft(2, '0');
}

// ---------------- ADD / EDIT TASK PAGE (now supports section & reminder) ----------------
class AddEditTaskPage extends StatefulWidget {
  final Task? editTask;
  final String? sectionId; // optional when creating from a section
  const AddEditTaskPage({super.key, this.editTask, this.sectionId});

  @override
  State<AddEditTaskPage> createState() => _AddEditTaskPageState();
}

class _AddEditTaskPageState extends State<AddEditTaskPage> {
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  Priority _priority = Priority.low;
  String? _selectedSectionId;
  DateTime? _reminder;
  String _reminderPreset = 'None';

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.editTask?.title ?? '');
    _descController = TextEditingController(text: widget.editTask?.description ?? '');
    _priority = widget.editTask?.priority ?? Priority.low;
    _selectedSectionId = widget.editTask?.sectionId ?? widget.sectionId ?? 'inbox';
    _reminder = widget.editTask?.reminder;
    _reminderPreset = _reminder == null ? 'None' : 'Custom';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickCustomDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _reminder ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_reminder ?? DateTime.now()),
    );
    if (time == null) return;
    setState(() {
      _reminder = DateTime(date.year, date.month, date.day, time.hour, time.minute);
      _reminderPreset = 'Custom';
    });
  }

  void _applyPreset(String preset) {
    DateTime now = DateTime.now();
    if (preset == 'None') {
      setState(() {
        _reminder = null;
        _reminderPreset = 'None';
      });
    } else if (preset == 'Today (evening)') {
      setState(() {
        _reminder = DateTime(now.year, now.month, now.day, 20, 0);
        _reminderPreset = preset;
      });
    } else if (preset == 'Tomorrow') {
      final t = now.add(const Duration(days: 1));
      setState(() {
        _reminder = DateTime(t.year, t.month, t.day, 9, 0);
        _reminderPreset = preset;
      });
    } else if (preset == 'Next Week') {
      final t = now.add(const Duration(days: 7));
      setState(() {
        _reminder = DateTime(t.year, t.month, t.day, 9, 0);
        _reminderPreset = preset;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.editTask != null;
    final provider = Provider.of<TaskProvider>(context, listen: false);
    final sections = Provider.of<SectionProvider>(context).sections;

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Task' : 'Add Task')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title', filled: true),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(labelText: 'Description', filled: true),
              maxLines: 4,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Priority:'),
                const SizedBox(width: 12),
                ChoiceChip(
                  label: const Text('Low'),
                  selected: _priority == Priority.low,
                  onSelected: (_) => setState(() => _priority = Priority.low),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Medium'),
                  selected: _priority == Priority.medium,
                  onSelected: (_) => setState(() => _priority = Priority.medium),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('High'),
                  selected: _priority == Priority.high,
                  onSelected: (_) => setState(() => _priority = Priority.high),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Section:'),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedSectionId,
                    items: sections.map((s) => DropdownMenuItem(value: s.id, child: Text(s.title))).toList(),
                    onChanged: (v) => setState(() => _selectedSectionId = v),
                    decoration: const InputDecoration(filled: true, border: InputBorder.none),
                  ),
                )
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Reminder:'),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _reminderPreset,
                  items: const [
                    DropdownMenuItem(value: 'None', child: Text('None')),
                    DropdownMenuItem(value: 'Today (evening)', child: Text('Today (evening)')),
                    DropdownMenuItem(value: 'Tomorrow', child: Text('Tomorrow')),
                    DropdownMenuItem(value: 'Next Week', child: Text('Next Week')),
                    DropdownMenuItem(value: 'Custom', child: Text('Custom...')),
                  ],
                  onChanged: (v) async {
                    if (v == null) return;
                    if (v == 'Custom') {
                      await _pickCustomDateTime();
                    } else {
                      _applyPreset(v);
                    }
                  },
                ),
                const SizedBox(width: 12),
                if (_reminder != null) Text(_formatDateTime(_reminder!)),
              ],
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final title = _titleController.text.trim();
                  final desc = _descController.text.trim();
                  if (title.isEmpty) return; // quick validation

                  if (isEditing) {
                    provider.updateTask(widget.editTask!.id, title, desc, _priority, _selectedSectionId ?? 'inbox', _reminder);
                  } else {
                    provider.addTask(title, desc, _priority, _selectedSectionId ?? 'inbox', _reminder);
                  }

                  Navigator.pop(context);
                },
                child: Text(isEditing ? 'Save Changes' : 'Add Task'),
              ),
            )
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) => '${dt.year}-${_two(dt.month)}-${_two(dt.day)} ${_two(dt.hour)}:${_two(dt.minute)}';
  String _two(int n) => n.toString().padLeft(2, '0');
}

// ---------------- DETAILS PAGE ----------------
class TaskDetailsPage extends StatelessWidget {
  final String taskId;
  const TaskDetailsPage({super.key, required this.taskId});

  @override
  Widget build(BuildContext context) {
    final task = Provider.of<TaskProvider>(context).getById(taskId);
    final sections = Provider.of<SectionProvider>(context).sections;
    final sectionTitle = sections.firstWhere((s) => s.id == task.sectionId, orElse: () => Section(id: 'inbox', title: 'Inbox')).title;

    return Scaffold(
      appBar: AppBar(title: const Text('Task Details')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            task.title,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: _priorityColor(task.priority).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(task.priority.name.toUpperCase(), style: TextStyle(color: _priorityColor(task.priority))),
                        )
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.folder),
                        const SizedBox(width: 8),
                        Text(sectionTitle),
                        const SizedBox(width: 12),
                        if (task.reminder != null) ...[
                          const Icon(Icons.alarm),
                          const SizedBox(width: 8),
                          Text(_formatDateTime(task.reminder!)),
                        ]
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(task.description, style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            Provider.of<TaskProvider>(context, listen: false).toggleComplete(task.id);
                          },
                          icon: Icon(task.completed ? Icons.check_circle : Icons.check),
                          label: Text(task.completed ? 'Mark as Incomplete' : 'Mark Completed'),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => AddEditTaskPage(editTask: task)),
                          ),
                          icon: const Icon(Icons.edit),
                          label: const Text('Edit'),
                        )
                      ],
                    )
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Color _priorityColor(Priority p) {
    switch (p) {
      case Priority.high:
        return Colors.redAccent;
      case Priority.medium:
        return Colors.orange;
      case Priority.low:
      default:
        return Colors.green;
    }
  }

  String _formatDateTime(DateTime dt) => '${dt.year}-${_two(dt.month)}-${_two(dt.day)} ${_two(dt.hour)}:${_two(dt.minute)}';
  String _two(int n) => n.toString().padLeft(2, '0');
}
