import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../domain/workspace.dart';

class TaskDetailsValue {
  const TaskDetailsValue({
    this.contextIds = const [],
    this.minutes,
    this.energy,
  });
  final List<String> contextIds;
  final int? minutes;
  final EnergyLevel? energy;
}

Future<List<String>?> pickTaskContexts(
  BuildContext context,
  List<TaskContext> definitions,
  List<String> selected, {
  bool filtering = false,
}) {
  final chosen = selected.toSet();
  return showDialog<List<String>>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Kontexte auswählen'),
        content: SizedBox(
          width: 440,
          child: SingleChildScrollView(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final item in definitions.where(
                  (e) => filtering || e.active || selected.contains(e.id),
                ))
                  FilterChip(
                    key: ValueKey('context-choice-${item.id}'),
                    avatar: Icon(
                      Icons.circle,
                      size: 9,
                      color: Color(item.color),
                    ),
                    label: Text(
                      '${item.name}${item.active ? '' : ' (inaktiv)'}',
                    ),
                    selected: chosen.contains(item.id),
                    onSelected: (value) => setState(() {
                      if (value) {
                        chosen.add(item.id);
                      } else {
                        chosen.remove(item.id);
                      }
                    }),
                  ),
                if (definitions.isEmpty)
                  const Text('Kontexte lassen sich in Einstellungen anlegen.'),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => setState(chosen.clear),
            child: const Text('Keine auswählen'),
          ),
          FilledButton(
            key: const ValueKey('apply-contexts'),
            onPressed: () => Navigator.pop(context, chosen.toList()),
            child: const Text('Übernehmen'),
          ),
        ],
      ),
    ),
  );
}

Future<int?> _customMinutes(BuildContext context, int? initial) async {
  final controller = TextEditingController(text: initial?.toString() ?? '');
  final form = GlobalKey<FormState>();
  try {
    return await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eigene Dauer'),
        content: Form(
          key: form,
          child: TextFormField(
            key: const ValueKey('custom-minutes'),
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Minuten'),
            validator: (value) => (int.tryParse(value ?? '') ?? 0) <= 0
                ? 'Bitte positive Minuten eingeben.'
                : null,
            onFieldSubmitted: (_) {
              if (form.currentState!.validate()) {
                Navigator.pop(context, int.parse(controller.text));
              }
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () {
              if (form.currentState!.validate()) {
                Navigator.pop(context, int.parse(controller.text));
              }
            },
            child: const Text('Übernehmen'),
          ),
        ],
      ),
    );
  } finally {
    controller.dispose();
  }
}

class TaskDetailsFields extends StatelessWidget {
  const TaskDetailsFields({
    super.key,
    required this.definitions,
    required this.value,
    required this.onChanged,
    this.readOnly = false,
    this.filtering = false,
  });
  final List<TaskContext> definitions;
  final TaskDetailsValue value;
  final ValueChanged<TaskDetailsValue> onChanged;
  final bool readOnly;
  final bool filtering;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        filtering ? 'Kontexte' : 'Kontexte (optional)',
        style: Theme.of(context).textTheme.labelMedium,
      ),
      const SizedBox(height: 6),
      Wrap(
        spacing: 6,
        runSpacing: 5,
        children: [
          for (final item in definitions.where(
            (e) => value.contextIds.contains(e.id),
          ))
            TaskValueChip(label: item.name, color: Color(item.color)),
          if (!readOnly)
            OutlinedButton.icon(
              key: const ValueKey('task-contexts'),
              onPressed: () async {
                final ids = await pickTaskContexts(
                  context,
                  definitions,
                  value.contextIds,
                  filtering: filtering,
                );
                if (ids != null) {
                  onChanged(
                    TaskDetailsValue(
                      contextIds: ids,
                      minutes: value.minutes,
                      energy: value.energy,
                    ),
                  );
                }
              },
              icon: const Icon(LucideIcons.tags, size: 14),
              label: const Text('Auswählen …'),
            ),
          if (readOnly && value.contextIds.isEmpty)
            const Text('Keine Kontexte'),
        ],
      ),
      const SizedBox(height: 14),
      Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          SizedBox(
            width: 205,
            child: DropdownButtonFormField<int>(
              key: ValueKey('duration-${value.minutes}'),
              initialValue: value.minutes ?? 0,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: filtering
                    ? 'Maximaler Zeitbedarf'
                    : 'Zeitbedarf (optional)',
              ),
              items: [
                DropdownMenuItem(
                  value: 0,
                  child: Text(filtering ? 'Beliebig' : 'Keine Angabe'),
                ),
                for (final minutes in taskDurationPresets)
                  DropdownMenuItem(value: minutes, child: Text('$minutes Min')),
                if (value.minutes != null &&
                    !taskDurationPresets.contains(value.minutes))
                  DropdownMenuItem(
                    value: value.minutes,
                    child: Text('${value.minutes} Min'),
                  ),
                const DropdownMenuItem(
                  value: -1,
                  child: Text('Eigene Dauer …'),
                ),
              ],
              onChanged: readOnly
                  ? null
                  : (minutes) async {
                      if (minutes == -1) {
                        minutes = await _customMinutes(context, value.minutes);
                        if (minutes == null) return;
                      }
                      onChanged(
                        TaskDetailsValue(
                          contextIds: value.contextIds,
                          minutes: minutes == 0 ? null : minutes,
                          energy: value.energy,
                        ),
                      );
                    },
            ),
          ),
          SizedBox(
            width: 205,
            child: DropdownButtonFormField<int>(
              key: ValueKey('energy-${value.energy?.name}'),
              initialValue: value.energy == null ? -1 : value.energy!.index,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: filtering
                    ? 'Maximaler Energiebedarf'
                    : 'Energiebedarf (optional)',
              ),
              items: [
                DropdownMenuItem(
                  value: -1,
                  child: Text(filtering ? 'Beliebig' : 'Keine Angabe'),
                ),
                for (final energy in EnergyLevel.values)
                  DropdownMenuItem(
                    value: energy.index,
                    child: Text(energy.label),
                  ),
              ],
              onChanged: readOnly
                  ? null
                  : (energy) => onChanged(
                      TaskDetailsValue(
                        contextIds: value.contextIds,
                        minutes: value.minutes,
                        energy: energy == null || energy < 0
                            ? null
                            : EnergyLevel.values[energy],
                      ),
                    ),
            ),
          ),
        ],
      ),
    ],
  );
}

class TaskValueChip extends StatelessWidget {
  const TaskValueChip({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.tooltip,
  });
  final String label;
  final Color color;
  final IconData? icon;
  final String? tooltip;
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark
        ? Color.lerp(color, Colors.white, .45)!
        : Color.lerp(color, Colors.black, .2)!;
    return Tooltip(
      message: tooltip ?? label,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color.withValues(alpha: dark ? .16 : .07),
          border: Border.all(color: color.withValues(alpha: .65)),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 12, color: ink),
                const SizedBox(width: 4),
              ],
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 11, height: 1.2, color: ink),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TaskMetadataChips extends StatelessWidget {
  const TaskMetadataChips({
    super.key,
    required this.entry,
    required this.contexts,
  });
  final Entry entry;
  final List<TaskContext> contexts;
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 6,
    runSpacing: 5,
    children: [
      for (final item in contexts.where((e) => entry.contextIds.contains(e.id)))
        TaskValueChip(
          label: item.name,
          color: Color(item.color),
          tooltip: 'Kontext: ${item.name}${item.active ? '' : ' (inaktiv)'}',
        ),
      if (entry.contextIds.isEmpty && entry.context.isNotEmpty)
        TaskValueChip(label: entry.context, color: const Color(0xff4b799e)),
      if (entry.estimatedMinutes != null)
        TaskValueChip(
          label: '${entry.estimatedMinutes} Min',
          color: const Color(0xff8c6c9c),
          icon: LucideIcons.clock3,
          tooltip: 'Geschätzte Bearbeitungszeit',
        ),
      if (entry.energy != null)
        TaskValueChip(
          label: entry.energy!.label,
          color: const Color(0xff9a7b3e),
          icon: LucideIcons.zap,
          tooltip: 'Energiebedarf: ${entry.energy!.label}',
        ),
    ],
  );
}

Future<TaskFilter?> showTaskFilterDialog(
  BuildContext context,
  List<TaskContext> definitions,
  TaskFilter current,
) {
  var details = TaskDetailsValue(
    contextIds: current.contextIds,
    minutes: current.maxMinutes,
    energy: current.maxEnergy,
  );
  var all = current.allContexts, unspecified = current.includeUnspecified;
  return showDialog<TaskFilter>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Aufgaben filtern'),
        content: SizedBox(
          width: 460,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TaskDetailsFields(
                  definitions: definitions,
                  value: details,
                  filtering: true,
                  onChanged: (value) => setState(() => details = value),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Alle gewählten Kontexte erforderlich'),
                  subtitle: const Text('Aus: mindestens einer passt'),
                  value: all,
                  onChanged: (value) => setState(() => all = value),
                ),
                SwitchListTile(
                  title: const Text('Ohne Angaben einbeziehen'),
                  value: unspecified,
                  onChanged: (value) => setState(() => unspecified = value),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, const TaskFilter()),
            child: const Text('Zurücksetzen'),
          ),
          FilledButton(
            key: const ValueKey('apply-task-filter'),
            onPressed: () => Navigator.pop(
              context,
              TaskFilter(
                contextIds: details.contextIds,
                maxMinutes: details.minutes,
                maxEnergy: details.energy,
                allContexts: all,
                includeUnspecified: unspecified,
              ),
            ),
            child: const Text('Anwenden'),
          ),
        ],
      ),
    ),
  );
}
