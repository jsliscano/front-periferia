import '../../domain/entities/task.dart';
import '../../domain/entities/task_page.dart';

abstract class TaskRepository {
  Future<TaskPage> getTasks({
    required int userId,
    TaskStatus? status,
    int page = 0,
    int size = 7,
  });

  Future<Task> createTask({
    required String title,
    required String description,
    required DateTime? dueDate,
    required int userId,
  });

  Future<Task> updateTask({
    required int id,
    required String title,
    required String description,
    required DateTime? dueDate,
    required TaskStatus status,
  });

  Future<void> deleteTask(int id);
}
