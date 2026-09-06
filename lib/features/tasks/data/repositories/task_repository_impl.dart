import '../../domain/entities/task.dart';
import '../../domain/entities/task_page.dart';
import '../../domain/repositories/task_repository.dart';
import '../datasources/task_remote_datasource.dart';

class TaskRepositoryImpl implements TaskRepository {
  TaskRepositoryImpl({TaskRemoteDataSource? remoteDataSource})
      : _remoteDataSource = remoteDataSource ?? TaskRemoteDataSource();

  final TaskRemoteDataSource _remoteDataSource;

  @override
  Future<TaskPage> getTasks({
    required int userId,
    TaskStatus? status,
    int page = 0,
    int size = 7,
  }) {
    return _remoteDataSource.findByUserId(
      userId: userId,
      status: status,
      page: page,
      size: size,
    );
  }

  @override
  Future<Task> createTask({
    required String title,
    required String description,
    required DateTime? dueDate,
    required int userId,
  }) {
    return _remoteDataSource.create(
      title: title,
      description: description,
      dueDate: dueDate,
      userId: userId,
    );
  }

  @override
  Future<Task> updateTask({
    required int id,
    required String title,
    required String description,
    required DateTime? dueDate,
    required TaskStatus status,
  }) {
    return _remoteDataSource.update(
      id: id,
      title: title,
      description: description,
      dueDate: dueDate,
      status: status,
    );
  }

  @override
  Future<void> deleteTask(int id) {
    return _remoteDataSource.delete(id);
  }
}
