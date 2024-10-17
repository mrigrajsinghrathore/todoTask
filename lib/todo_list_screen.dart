import 'package:flutter/material.dart';
import 'task_model.dart';
import 'task_storage.dart';

class TodoListScreen extends StatefulWidget {
  @override
  TodoListScreenState createState() => TodoListScreenState();
}

class TodoListScreenState extends State<TodoListScreen> with TickerProviderStateMixin {
  final TaskStorage taskStorage = TaskStorage();
  List<Task> tasks = [];
  List<bool> isTaskExpanded = [];

  @override
  void initState() {
    super.initState();
    loadTasks();
  }

  Future<void> loadTasks() async {
    List<Task> loadedTasks = await taskStorage.loadTasks();
    setState(() {
      tasks = loadedTasks;
      isTaskExpanded = List.generate(tasks.length, (_) => false);
    });
  }

  Future<void> saveTasks() async {
    await taskStorage.saveTasks(tasks);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'To-Do List',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue.shade500,
        centerTitle: true,
        actions: tasks.isNotEmpty
            ? [
          IconButton(
            icon: Icon(
              Icons.delete,
              color: Colors.white,
            ),
            onPressed: () async {
              if (tasks.where((task) => task.isCompleted).isEmpty) {
                await showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Icon(Icons.info_outline, color: Colors.blue, size: 50),
                    content: Text('Please select a completed task to delete.'),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text('OK', style: TextStyle(color: Colors.black)),
                      ),
                    ],
                  ),
                );
              } else {
                bool? confirmDelete = await showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Icon(Icons.delete_forever, color: Colors.red, size: 50),
                    content: Text('Are you sure you want to delete all completed tasks?'),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context, false);
                        },
                        child: Text('No', style: TextStyle(color: Colors.black)),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context, true);
                        },
                        child: Text('Yes', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
                if (confirmDelete == true) {
                  deleteCompletedTasks();
                }
              }
            },
          )
        ] : [],
      ),

      body: tasks.isEmpty
          ? Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue[300]!, Colors.blue[50]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),child: Center(child: Text('No tasks !')))
          : Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue[300]!, Colors.blue[50]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Pending Tasks',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,color: Colors.white),
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: tasks.where((task) => !task.isCompleted).length,
              itemBuilder: (context, index) {
                final pendingTasks = tasks.where((task) => !task.isCompleted).toList();
                return buildTaskItem(pendingTasks[index]);
              },
            ),

            if (tasks.where((task) => task.isCompleted).isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Completed Tasks',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,color: Colors.white),
                ),
              ),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: tasks.where((task) => task.isCompleted).length,
              itemBuilder: (context, index) {
                final completedTasks = tasks.where((task) => task.isCompleted).toList();
                return buildTaskItem(completedTasks[index]);
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue.shade500,
        onPressed: () => showAddOrEditTaskDialog(),
        child: Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget buildTaskItem(Task task) {
    int index = tasks.indexOf(task);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Container(
            decoration: BoxDecoration(
              color: task.isCompleted ? Colors.green[50] : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: ListTile(
              leading: Icon(
                task.isCompleted ? Icons.check_circle : Icons.circle,
                color: task.isCompleted ? Colors.green : Colors.grey,
              ),
              title: Text(
                task.title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  decoration: task.isCompleted
                      ? TextDecoration.lineThrough
                      : TextDecoration.none,
                  color: task.isCompleted ? Colors.grey : Colors.black,
                ),
              ),
              subtitle: task.dueDate != null
                  ? Text(
                'Due: ${task.dueDate!.toLocal().toString().split(' ')[0]}',
                style: TextStyle(color: Colors.grey[600]),
              )
                  : null,
              trailing: Checkbox(
                value: task.isCompleted,
                onChanged: (value) {
                  toggleTaskCompletion(index);
                },
                activeColor: Colors.green,
              ),
              onTap: () {
                setState(() {
                  // Collapse all other tasks
                  for (int i = 0; i < isTaskExpanded.length; i++) {
                    if (i != index) {
                      isTaskExpanded[i] = false;
                    }
                  }
                  isTaskExpanded[index] = !isTaskExpanded[index];
                });
              },
            ),
          ),
        ),
        AnimatedSize(
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: isTaskExpanded[index]
              ? Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!, width: 1),
              ),
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (task.description != null && task.description!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        'Description: ${task.description}',
                        style: TextStyle(color: Colors.black87),
                      ),
                    ),
                  if (task.dueDate != null)
                    Text(
                      'Due Date: ${task.dueDate!.toLocal().toString().split(' ')[0]}',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        showAddOrEditTaskDialog(taskToEdit: task, taskIndex: index);
                      },
                      child: Text(
                        'Edit',
                        style: TextStyle(color: Colors.blue),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
              : SizedBox.shrink(),
        ),
      ],
    );
  }

  void addTask(String title, String? description, DateTime? dueDate) {
    setState(() {
      tasks.add(Task(
        title: title,
        description: description,
        dueDate: dueDate,
      ));
      isTaskExpanded.add(false);
    });
    saveTasks();
  }

  void editTask(int index, String title, String? description, DateTime? dueDate) {
    setState(() {
      tasks[index].title = title;
      tasks[index].description = description;
      tasks[index].dueDate = dueDate;
    });
    saveTasks();
  }

  void toggleTaskCompletion(int index) {
    setState(() {
      tasks[index].isCompleted = !tasks[index].isCompleted;
      for (int i = 0; i < isTaskExpanded.length; i++) {
        isTaskExpanded[i] = false;
      }
    });
    saveTasks();
  }

  void deleteCompletedTasks() {
    setState(() {
      for (int i = tasks.length - 1; i >= 0; i--) {
        if (tasks[i].isCompleted) {
          tasks.removeAt(i);
          isTaskExpanded.removeAt(i);
        }
      }
    });
    saveTasks();
  }

  void showAddOrEditTaskDialog({Task? taskToEdit, int? taskIndex}) {
    String title = taskToEdit?.title ?? '';
    String? description = taskToEdit?.description;
    DateTime? dueDate = taskToEdit?.dueDate;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(taskToEdit == null ? 'Add Task' : 'Edit Task'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: InputDecoration(labelText: 'Title'),
                    controller: TextEditingController(text: title),
                    onChanged: (value) => title = value,
                  ),
                  TextField(
                    decoration: const InputDecoration(labelText: 'Description'),
                    controller: TextEditingController(text: description),
                    onChanged: (value) => description = value,
                  ),
                  TextButton(
                    child: Text(dueDate == null
                        ? 'Select Due Date'
                        : 'Due Date: ${dueDate?.toLocal().toString().split(' ')[0]}',style: TextStyle(color: Colors.red,fontWeight: FontWeight.bold),),
                    onPressed: () async {
                      final selectedDate = await showDatePicker(
                        context: context,
                        initialDate: dueDate ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );
                      if (selectedDate != null) {
                        setState(() {
                          dueDate = selectedDate;
                        });
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: Text('Cancel',style: TextStyle(color: Colors.black),),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                TextButton(
                  child: Text(taskToEdit == null ? 'Add' : 'Save',style: TextStyle(color: Colors.black)),
                  onPressed: () {
                    if (title.isNotEmpty) {
                      if (taskToEdit == null) {
                        addTask(title, description, dueDate);
                      } else if (taskIndex != null) {
                        editTask(taskIndex, title, description, dueDate);
                      }
                      Navigator.pop(context);
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}
