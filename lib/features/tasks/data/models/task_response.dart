import '../../domain/entities/task.dart';

class TaskResponse {
  const TaskResponse({
    required this.id,
    required this.title,
    required this.description,
    required this.createdAt,
    required this.dueDate,
    required this.status,
    required this.userId,
  });

  final int id;
  final String title;
  final String description;
  final DateTime createdAt;
  final DateTime? dueDate;
  final TaskStatus status;
  final int userId;

  factory TaskResponse.fromJson(Map<String, dynamic> json) {
    return TaskResponse(
      id: (json['id'] as num).toInt(),
      title: (json['title'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      createdAt: _parseDateTime(json['createdAt']) ?? DateTime.now(),
      dueDate: _parseCalendarDate(json['dueDate']),
      status: TaskStatus.fromApi(json['status'] as String?),
      userId: (json['userId'] as num).toInt(),
    );
  }

  Task toEntity() {
    return Task(
      id: id,
      titulo: title,
      descripcion: description,
      fechaCreacion: createdAt,
      fechaVencimiento: dueDate,
      estado: status,
      usuarioId: userId,
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is String && value.isNotEmpty) {
      final parsed = DateTime.tryParse(value);
      return parsed?.toLocal();
    }
    if (value is List && value.isNotEmpty) {
      final year = (value[0] as num).toInt();
      final month = value.length > 1 ? (value[1] as num).toInt() : 1;
      final day = value.length > 2 ? (value[2] as num).toInt() : 1;
      final hour = value.length > 3 ? (value[3] as num).toInt() : 0;
      final minute = value.length > 4 ? (value[4] as num).toInt() : 0;
      final second = value.length > 5 ? (value[5] as num).toInt() : 0;
      return DateTime(year, month, day, hour, minute, second);
    }
    return null;
  }

  static DateTime? _parseCalendarDate(dynamic value) {
    if (value is String && value.isNotEmpty) {
      final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(value);
      if (match != null) {
        return DateTime(
          int.parse(match.group(1)!),
          int.parse(match.group(2)!),
          int.parse(match.group(3)!),
        );
      }
    }
    final parsed = _parseDateTime(value);
    if (parsed == null) return null;
    return DateTime(parsed.year, parsed.month, parsed.day);
  }
}
