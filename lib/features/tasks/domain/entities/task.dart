/// Estado de una tarea alineado con el backend (PENDING / COMPLETED).
enum TaskStatus {
  pendiente('PENDING'),
  completada('COMPLETED');

  const TaskStatus(this.apiValue);

  final String apiValue;

  static TaskStatus fromApi(String? value) {
    switch (value?.toUpperCase()) {
      case 'COMPLETED':
        return TaskStatus.completada;
      case 'PENDING':
      default:
        return TaskStatus.pendiente;
    }
  }
}

/// Entidad de dominio que representa una tarea.
class Task {
  const Task({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.fechaCreacion,
    required this.fechaVencimiento,
    required this.estado,
    required this.usuarioId,
  });

  final int id;
  final String titulo;
  final String descripcion;
  final DateTime fechaCreacion;
  final DateTime? fechaVencimiento;
  final TaskStatus estado;
  final int usuarioId;

  bool get isCompletada => estado == TaskStatus.completada;

  Task copyWith({
    int? id,
    String? titulo,
    String? descripcion,
    DateTime? fechaCreacion,
    DateTime? fechaVencimiento,
    TaskStatus? estado,
    int? usuarioId,
  }) {
    return Task(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      descripcion: descripcion ?? this.descripcion,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaVencimiento: fechaVencimiento ?? this.fechaVencimiento,
      estado: estado ?? this.estado,
      usuarioId: usuarioId ?? this.usuarioId,
    );
  }
}
