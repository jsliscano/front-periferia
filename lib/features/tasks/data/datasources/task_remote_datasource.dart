import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_config.dart';
import '../../domain/entities/task.dart';
import '../../domain/entities/task_page.dart';
import '../models/task_response.dart';

/// Acceso remoto a endpoints de tareas.
class TaskRemoteDataSource {
  TaskRemoteDataSource({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<TaskPage> findByUserId({
    required int userId,
    TaskStatus? status,
    int page = 0,
    int size = 7,
  }) async {
    final query = <String, String>{
      'userId': userId.toString(),
      'page': page.toString(),
      'size': size.toString(),
    };
    if (status != null) {
      query['status'] = status.apiValue;
    }

    final json = await _apiClient.get(
     ApiConfig.tasksPath,
     query: query,
     auth: true,
    );

    final content = json['content'];
    final tasks = content is List
        ? content
            .whereType<Map<String, dynamic>>()
            .map((item) => TaskResponse.fromJson(item).toEntity())
            .toList()
        : <Task>[];

    return TaskPage(
      content: tasks,
      page: (json['page'] as num?)?.toInt() ?? page,
      size: (json['size'] as num?)?.toInt() ?? size,
      totalElements: (json['totalElements'] as num?)?.toInt() ?? tasks.length,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 1,
      last: json['last'] as bool? ?? true,
    );
  }

  Future<Task> create({
    required String title,
    required String description,
    required DateTime? dueDate,
    required int userId,
  }) async {
    final json = await _apiClient.post(
      ApiConfig.tasksPath,
      auth: true,
      body: {
        'title': title,
        'description': description,
        'dueDate': dueDate?.toIso8601String().split('.').first,
        'userId': userId,
      },
    );
    return TaskResponse.fromJson(json).toEntity();
  }

  Future<Task> update({
    required int id,
    required String title,
    required String description,
    required DateTime? dueDate,
    required TaskStatus status,
  }) async {
    final json = await _apiClient.put(
      '${ApiConfig.tasksPath}/$id',
      body: {
        'title': title,
        'description': description,
        'dueDate': dueDate?.toIso8601String().split('.').first,
        'status': status.apiValue,
      },
    );
    return TaskResponse.fromJson(json).toEntity();
  }

  Future<void> delete(int id) async {
    await _apiClient.delete('${ApiConfig.tasksPath}/$id');
  }
}
