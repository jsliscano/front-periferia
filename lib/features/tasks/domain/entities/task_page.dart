import '../entities/task.dart';

/// Página de resultados alineada con PageResponse del backend.
class TaskPage {
  const TaskPage({
    required this.content,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
    required this.last,
  });

  final List<Task> content;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;
  final bool last;

  bool get isFirst => page <= 0;
  bool get hasNext => !last && page + 1 < totalPages;
  bool get hasPrevious => page > 0;
}
