import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/notifications/task_notification_service.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../auth/data/session_store.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../data/repositories/task_repository_impl.dart';
import '../../domain/entities/task.dart';
import '../../domain/repositories/task_repository.dart';
import '../widgets/task_list_item.dart';
import '../widgets/task_notifications_bell.dart';
import 'task_form_page.dart';

/// Pantalla con el listado de tareas conectado al backend (con paginación).
class TaskListPage extends StatefulWidget {
  const TaskListPage({super.key, this.taskRepository});

  final TaskRepository? taskRepository;

  @override
  State<TaskListPage> createState() => _TaskListPageState();
}

class _TaskListPageState extends State<TaskListPage> {
  static const int _pageSize = 7;

  late final TaskRepository _taskRepository =
      widget.taskRepository ?? TaskRepositoryImpl();

  final _searchController = TextEditingController();
  final List<Task> _tasks = [];

  TaskStatus? _selectedStatus;
  String _searchQuery = '';
  bool _isLoading = true;

  int _currentPage = 0;
  int _totalPages = 1;
  int _totalElements = 0;
  bool _isLastPage = true;
  bool _upcomingAlertShown = false;
  List<Task> _upcomingTasks = const [];

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  int? get _userId => SessionStore.current?.userId;

  List<Task> get _filteredTasks {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return _tasks;

    return _tasks.where((task) {
      return task.titulo.toLowerCase().contains(query) ||
          task.descripcion.toLowerCase().contains(query);
    }).toList();
  }

  Future<void> _loadTasks({int? page}) async {
    final userId = _userId;
    if (userId == null) {
      setState(() => _isLoading = false);
      await AppDialog.error(
        context,
        title: 'Sesión no válida',
        message: 'Inicia sesión nuevamente para ver tus tareas.',
      );
      if (!mounted) return;
      _logout(showConfirm: false);
      return;
    }

    final targetPage = page ?? _currentPage;

    setState(() => _isLoading = true);

    try {
      final result = await _taskRepository.getTasks(
        userId: userId,
        status: _selectedStatus,
        page: targetPage,
        size: _pageSize,
      );

      if (!mounted) return;

      // Si la página pedida quedó vacía (por ejemplo al borrar), retrocede.
      if (result.content.isEmpty && targetPage > 0) {
        await _loadTasks(page: targetPage - 1);
        return;
      }

      setState(() {
        _currentPage = result.page;
        _totalPages = result.totalPages == 0 ? 1 : result.totalPages;
        _totalElements = result.totalElements;
        _isLastPage = result.last || result.page >= _totalPages - 1;
        _tasks
          ..clear()
          ..addAll(result.content);
        _isLoading = false;
      });

      // Notificaciones en segundo plano: no bloquean la lista.
      unawaited(_syncUpcomingNotifications());
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      await AppDialog.error(
        context,
        title: 'Error al cargar tareas',
        message: error.message,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      await AppDialog.error(
        context,
        title: 'Error',
        message: 'No se pudieron cargar las tareas.',
      );
    }
  }

  Future<void> _syncUpcomingNotifications() async {
    final userId = _userId;
    if (userId == null || !mounted) return;

    try {
      final pendingPage = await _taskRepository.getTasks(
        userId: userId,
        status: TaskStatus.pendiente,
        page: 0,
        size: 100,
      );

      final pendingTasks = pendingPage.content;
      final upcoming =
          TaskNotificationService.instance.getUpcomingTasks(pendingTasks);

      await TaskNotificationService.instance.syncFromTasks(pendingTasks);

      if (!mounted) return;
      setState(() => _upcomingTasks = upcoming);
      await _showUpcomingDueModalIfNeeded(upcoming);
    } catch (_) {
      // No bloquea la UI si fallan las notificaciones.
    }
  }

  Future<void> _showUpcomingDueModalIfNeeded(List<Task> upcoming) async {
    if (_upcomingAlertShown || !mounted) return;
    if (upcoming.isEmpty) return;

    _upcomingAlertShown = true;
    await TaskNotificationsBell.showUpcomingPanel(
      context,
      upcoming: upcoming,
      onTaskSelected: _editTask,
    );
  }

  Future<void> _goToPreviousPage() async {
    if (_currentPage <= 0 || _isLoading) return;
    await _loadTasks(page: _currentPage - 1);
  }

  Future<void> _goToNextPage() async {
    if (_isLastPage || _isLoading) return;
    await _loadTasks(page: _currentPage + 1);
  }

  Future<void> _createTask() async {
    final userId = _userId;
    if (userId == null) {
      await AppDialog.error(
        context,
        title: 'Sesión no válida',
        message: 'Inicia sesión nuevamente.',
      );
      return;
    }

    final result = await Navigator.of(context).push<TaskFormResult>(
      MaterialPageRoute(
        builder: (_) => const TaskFormPage(),
      ),
    );

    if (result == null || !mounted) return;

    try {
      final created = await _taskRepository.createTask(
        title: result.titulo,
        description: result.descripcion,
        dueDate: result.fechaVencimiento,
        userId: userId,
      );

      if (!mounted) return;

      await AppDialog.success(
        context,
        title: 'Tarea creada',
        message: 'La tarea "${created.titulo}" se creó correctamente.',
      );

      if (!mounted) return;
      _upcomingAlertShown = false;
      await _loadTasks(page: 0);
    } on ApiException catch (error) {
      if (!mounted) return;
      await AppDialog.error(
        context,
        title: 'No se pudo crear',
        message: error.message,
      );
    } catch (_) {
      if (!mounted) return;
      await AppDialog.error(
        context,
        title: 'Error',
        message: 'Ocurrió un error al crear la tarea.',
      );
    }
  }

  Future<void> _editTask(Task task) async {
    final result = await Navigator.of(context).push<TaskFormResult>(
      MaterialPageRoute(
        builder: (_) => TaskFormPage(task: task),
      ),
    );

    if (result == null || !mounted) return;

    try {
      final updated = await _taskRepository.updateTask(
        id: task.id,
        title: result.titulo,
        description: result.descripcion,
        dueDate: result.fechaVencimiento,
        status: result.estado,
      );

      if (!mounted) return;

      await AppDialog.success(
        context,
        title: 'Tarea actualizada',
        message:
            'Los cambios de "${updated.titulo}" se guardaron correctamente.',
      );

      if (!mounted) return;
      _upcomingAlertShown = false;
      await _loadTasks(page: _currentPage);
    } on ApiException catch (error) {
      if (!mounted) return;
      await AppDialog.error(
        context,
        title: 'No se pudo actualizar',
        message: error.message,
      );
    } catch (_) {
      if (!mounted) return;
      await AppDialog.error(
        context,
        title: 'Error',
        message: 'Ocurrió un error al actualizar la tarea.',
      );
    }
  }

  Future<void> _deleteTask(Task task) async {
    final confirmed = await AppDialog.confirm(
      context,
      title: 'Eliminar tarea',
      message: '¿Seguro que quieres eliminar "${task.titulo}"?',
      confirmText: 'Eliminar',
      isDestructive: true,
      icon: Icons.warning_amber_rounded,
    );

    if (!confirmed || !mounted) return;

    try {
      await _taskRepository.deleteTask(task.id);
      if (!mounted) return;

      await AppDialog.success(
        context,
        title: 'Tarea eliminada',
        message: 'La tarea "${task.titulo}" se eliminó correctamente.',
      );

      if (!mounted) return;
      await TaskNotificationService.instance.cancelForTask(task.id);
      _upcomingAlertShown = false;
      await _loadTasks(page: _currentPage);
    } on ApiException catch (error) {
      if (!mounted) return;
      await AppDialog.error(
        context,
        title: 'No se pudo eliminar',
        message: error.message,
      );
    } catch (_) {
      if (!mounted) return;
      await AppDialog.error(
        context,
        title: 'Error',
        message: 'Ocurrió un error al eliminar la tarea.',
      );
    }
  }

  Future<void> _logout({bool showConfirm = true}) async {
    if (showConfirm) {
      final confirmed = await AppDialog.confirm(
        context,
        title: 'Cerrar sesión',
        message: '¿Deseas cerrar tu sesión actual?',
        confirmText: 'Cerrar sesión',
        icon: Icons.logout,
      );
      if (!confirmed || !mounted) return;
    }

    SessionStore.clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => const LoginPage(),
      ),
      (_) => false,
    );
  }

  Future<void> _onFilterSelected(TaskStatus? status) async {
    setState(() {
      _selectedStatus = status;
      _currentPage = 0;
    });
    await _loadTasks(page: 0);
  }

  Widget _filterButton({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return Expanded(
      child: Material(
        color: selected ? theme.colorScheme.primary : Colors.white,
        borderRadius: BorderRadius.circular(4),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(4),
          child: Container(
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: selected
                    ? theme.colorScheme.primary
                    : const Color(0xFFCBD5E1),
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : const Color(0xFF334155),
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaginationBar(ThemeData theme) {
    final canGoPrevious = _currentPage > 0 && !_isLoading;
    final canGoNext = !_isLastPage && !_isLoading;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Row(
            children: [
              OutlinedButton.icon(
                onPressed: canGoPrevious ? _goToPreviousPage : null,
                icon: const Icon(Icons.chevron_left, size: 18),
                label: const Text('Anterior'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
              Expanded(
                child: Text(
                  _totalElements == 0
                      ? 'Sin resultados'
                      : 'Página ${_currentPage + 1} de $_totalPages\n$_totalElements tareas',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.black54,
                    height: 1.3,
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: canGoNext ? _goToNextPage : null,
                icon: const Icon(Icons.chevron_right, size: 18),
                label: const Text('Siguiente'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tasks = _filteredTasks;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de tareas'),
        actions: [
          TaskNotificationsBell(
            upcoming: _upcomingTasks,
            enabled: !_isLoading,
            onTaskSelected: _editTask,
          ),
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _isLoading ? null : () => _loadTasks(),
            icon: const Icon(Icons.refresh),
          ),
          TextButton.icon(
            onPressed: _isLoading ? null : () => _logout(),
            icon: const Icon(Icons.logout, size: 18),
            label: const Text('Cerrar sesión'),
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.onPrimary,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 56),
        child: FloatingActionButton(
          onPressed: _isLoading ? null : _createTask,
          tooltip: 'Nueva tarea',
          child: const Icon(Icons.add),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      enabled: !_isLoading,
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: 'Buscar en esta página',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        prefixIconConstraints: const BoxConstraints(
                          minWidth: 40,
                          minHeight: 36,
                        ),
                        suffixIcon: _searchQuery.isEmpty
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      onChanged: (value) {
                        setState(() => _searchQuery = value);
                      },
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _filterButton(
                          label: 'Todas',
                          selected: _selectedStatus == null,
                          onTap: () => _onFilterSelected(null),
                        ),
                        const SizedBox(width: 8),
                        _filterButton(
                          label: 'Pendiente',
                          selected: _selectedStatus == TaskStatus.pendiente,
                          onTap: () => _onFilterSelected(TaskStatus.pendiente),
                        ),
                        const SizedBox(width: 8),
                        _filterButton(
                          label: 'Completada',
                          selected: _selectedStatus == TaskStatus.completada,
                          onTap: () =>
                              _onFilterSelected(TaskStatus.completada),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : tasks.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.inbox_outlined,
                              size: 44,
                              color: theme.colorScheme.primary
                                  .withValues(alpha: 0.45),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No hay tareas en esta página',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      )
                    : Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 720),
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                            itemCount: tasks.length,
                            itemBuilder: (context, index) {
                              final task = tasks[index];
                              return TaskListItem(
                                task: task,
                                onEdit: () => _editTask(task),
                                onDelete: () => _deleteTask(task),
                              );
                            },
                          ),
                        ),
                      ),
          ),
          _buildPaginationBar(theme),
        ],
      ),
    );
  }
}
