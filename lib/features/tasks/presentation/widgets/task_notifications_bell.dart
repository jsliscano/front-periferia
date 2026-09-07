import 'package:flutter/material.dart';

import '../../../../core/notifications/task_notification_service.dart';
import '../../domain/entities/task.dart';

class TaskNotificationsBell extends StatelessWidget {
  const TaskNotificationsBell({
    super.key,
    required this.upcoming,
    this.enabled = true,
    this.onTaskSelected,
  });

  final List<Task> upcoming;
  final bool enabled;
  final ValueChanged<Task>? onTaskSelected;

  static Future<void> showUpcomingPanel(
    BuildContext context, {
    required List<Task> upcoming,
    ValueChanged<Task>? onTaskSelected,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        final maxHeight = MediaQuery.sizeOf(dialogContext).height * 0.65;

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    upcoming.isEmpty
                        ? Icons.notifications_none_outlined
                        : Icons.notifications_active_outlined,
                    color: theme.colorScheme.primary,
                    size: 34,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Tareas por vencer',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    upcoming.isEmpty
                        ? 'No hay tareas vencidas ni que venzan en 1 día.'
                        : 'Tienes ${upcoming.length} tarea(s) vencida(s) '
                            'o que vencen en 1 día. Toca una para abrirla.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.black54,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (upcoming.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'Todo al día',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else
                    ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: maxHeight),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: upcoming.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final task = upcoming[index];
                          return _NotificationTile(
                            task: task,
                            onTap: onTaskSelected == null
                                ? null
                                : () {
                                    Navigator.of(dialogContext).pop();
                                    onTaskSelected(task);
                                  },
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: FilledButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Aceptar'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final count = upcoming.length;
    final theme = Theme.of(context);

    return IconButton(
      tooltip: count == 0
          ? 'Sin tareas por vencer'
          : '$count tarea(s) por vencer',
      onPressed: !enabled
          ? null
          : () => showUpcomingPanel(
                context,
                upcoming: upcoming,
                onTaskSelected: onTaskSelected,
              ),
      icon: Badge(
        isLabelVisible: count > 0,
        backgroundColor: const Color(0xFFDC2626),
        textColor: Colors.white,
        label: Text(
          count > 99 ? '99+' : '$count',
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
        ),
        child: Icon(
          count > 0 ? Icons.notifications_active : Icons.notifications_none,
          color: theme.colorScheme.onPrimary,
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.task,
    this.onTap,
  });

  final Task task;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final due = task.fechaVencimiento;
    final status = _dueStatus(due);
    final accent = status.overdue
        ? const Color(0xFFDC2626)
        : status.today
            ? const Color(0xFFD97706)
            : theme.colorScheme.primary;

    return Material(
      color: accent.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                task.titulo,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (task.descripcion.trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  task.descripcion,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.black54,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    status.overdue
                        ? Icons.warning_amber_rounded
                        : Icons.event_outlined,
                    size: 16,
                    color: accent,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      status.label,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (onTap != null) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: accent.withValues(alpha: 0.8),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static _DueStatus _dueStatus(DateTime? due) {
    if (due == null) {
      return const _DueStatus(
        label: 'Sin fecha de vencimiento',
        overdue: false,
        today: false,
      );
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(due.year, due.month, due.day);
    final diff = dueDay.difference(today).inDays;
    final formatted =
        '${due.day.toString().padLeft(2, '0')}/'
        '${due.month.toString().padLeft(2, '0')}/'
        '${due.year}';

    if (diff < 0) {
      final days = -diff;
      return _DueStatus(
        label: days == 1
            ? 'Vencida ayer · $formatted'
            : 'Vencida hace $days días · $formatted',
        overdue: true,
        today: false,
      );
    }
    if (diff == 0) {
      return _DueStatus(
        label: 'Vence hoy · $formatted',
        overdue: false,
        today: true,
      );
    }
    if (diff == 1) {
      return _DueStatus(
        label: 'Vence mañana · $formatted',
        overdue: false,
        today: false,
      );
    }
    return _DueStatus(
      label: 'Vence en $diff días · $formatted',
      overdue: false,
      today: false,
    );
  }
}

class _DueStatus {
  const _DueStatus({
    required this.label,
    required this.overdue,
    required this.today,
  });

  final String label;
  final bool overdue;
  final bool today;
}
