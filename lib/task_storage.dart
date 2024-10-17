import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'task_model.dart';

class TaskStorage {
  static const String _tasksKey = 'tasks';

  Future<List<Task>> loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final tasksString = prefs.getString(_tasksKey);
    if (tasksString != null) {
      List<dynamic> jsonList = json.decode(tasksString);
      return jsonList.map((jsonTask) => Task.fromJson(jsonTask)).toList();
    }
    return [];
  }

  Future<void> saveTasks(List<Task> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    List<Map<String, dynamic>> jsonList = tasks.map((task) => task.toJson()).toList();
    prefs.setString(_tasksKey, json.encode(jsonList));
  }
}
