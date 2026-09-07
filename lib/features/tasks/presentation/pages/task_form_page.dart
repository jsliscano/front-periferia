import 'package:flutter/material.dart';

import '../../../../core/widgets/app_dialog.dart';
import '../../../auth/data/session_store.dart';
import '../../domain/entities/task.dart';

class TaskFormResult {
  const TaskFormResult({
    required this.titulo,
    required this.descripcion,
    required this.fechaVencimiento,
    required this.estado,
  });

  final String titulo;
  final String descripcion;
  final DateTime fechaVencimiento;
  final TaskStatus estado;
}

class TaskFormPage extends StatefulWidget {
  const TaskFormPage({super.key, this.task});

  final Task? task;

  bool get isEditing => task != null;

  @override
  State<TaskFormPage> createState() => _TaskFormPageState();
}

class _TaskFormPageState extends State<TaskFormPage> {
  late final TextEditingController _tituloController;
  late final TextEditingController _descripcionController;
  late DateTime _fechaVencimiento;
  late TaskStatus _estado;

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    _tituloController = TextEditingController(text: task?.titulo ?? '');
    _descripcionController =
        TextEditingController(text: task?.descripcion ?? '');
    _fechaVencimiento = task?.fechaVencimiento ??
        DateTime.now().add(const Duration(days: 7));
    _estado = task?.estado ?? TaskStatus.pendiente;
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  Future<void> _pickDueDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _fechaVencimiento,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (selected != null) {
      setState(() => _fechaVencimiento = selected);
    }
  }

  Future<void> _save() async {
    final titulo = _tituloController.text.trim();
    final descripcion = _descripcionController.text.trim();

    if (titulo.isEmpty) {
      await AppDialog.info(
        context,
        title: 'Campo requerido',
        message: 'El título de la tarea es obligatorio.',
      );
      return;
    }

    if (SessionStore.current == null) {
      await AppDialog.error(
        context,
        title: 'Sesión expirada',
        message: 'Inicia sesión nuevamente para continuar.',
      );
      return;
    }

    Navigator.of(context).pop(
      TaskFormResult(
        titulo: titulo,
        descripcion: descripcion,
        fechaVencimiento: _fechaVencimiento,
        estado: _estado,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Editar tarea' : 'Nueva tarea'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        widget.isEditing
                            ? 'Actualiza los datos de la tarea'
                            : 'Completa los datos de la nueva tarea',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _tituloController,
                        decoration: const InputDecoration(
                          labelText: 'Título',
                          prefixIcon: Icon(Icons.title),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _descripcionController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Descripción',
                          prefixIcon: Icon(Icons.notes_outlined),
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: _pickDueDate,
                        borderRadius: BorderRadius.circular(12),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Fecha de vencimiento',
                            prefixIcon: Icon(Icons.calendar_today_outlined),
                          ),
                          child: Text(_formatDate(_fechaVencimiento)),
                        ),
                      ),
                      if (widget.isEditing) ...[
                        const SizedBox(height: 16),
                        DropdownButtonFormField<TaskStatus>(
                          key: ValueKey(_estado),
                          initialValue: _estado,
                          decoration: const InputDecoration(
                            labelText: 'Estado',
                            prefixIcon: Icon(Icons.flag_outlined),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: TaskStatus.pendiente,
                              child: Text('Pendiente'),
                            ),
                            DropdownMenuItem(
                              value: TaskStatus.completada,
                              child: Text('Completada'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _estado = value);
                            }
                          },
                        ),
                      ],
                      const SizedBox(height: 28),
                      SizedBox(
                        height: 48,
                        child: FilledButton.icon(
                          onPressed: _save,
                          icon: Icon(
                            widget.isEditing ? Icons.save_outlined : Icons.add,
                          ),
                          label: Text(
                            widget.isEditing
                                ? 'Guardar cambios'
                                : 'Crear tarea',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
