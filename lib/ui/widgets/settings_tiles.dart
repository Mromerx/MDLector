import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/app_settings.dart';

/// Header that groups several settings rows under one title.
class SettingsSection extends StatelessWidget {
  const SettingsSection({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 6),
          child: Text(
            title.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        ...children,
        const SizedBox(height: 6),
      ],
    );
  }
}

/// Base row of a setting: icon, label and control on the right.
class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.icon,
    required this.title,
    required this.trailing,
    this.subtitle,
    this.onTap,
    this.stackWhenNarrow = false,
    this.expandedTrailing,
  });

  static const double _minHorizontalWidth = 420;

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget trailing;
  final VoidCallback? onTap;
  final bool stackWhenNarrow;
  final Widget? expandedTrailing;

  @override
  Widget build(BuildContext context) {
    if (!stackWhenNarrow) return _horizontal(context, trailing);
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= _minHorizontalWidth) {
          return _horizontal(context, trailing);
        }
        return _vertical(context);
      },
    );
  }

  Widget _horizontal(BuildContext context, Widget control) {
    final theme = Theme.of(context);
    return ListTile(
      hoverColor: Colors.transparent,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Icon(icon, size: 20),
      title: Text(title),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
      trailing: control,
      onTap: onTap,
    );
  }

  Widget _vertical(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: 16),
                Expanded(child: Text(title)),
              ],
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Padding(
                padding: const EdgeInsets.only(left: 36),
                child: Text(
                  subtitle!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: expandedTrailing ?? trailing,
            ),
          ],
        ),
      ),
    );
  }
}

/// Boolean setting: a `Switch`.
class SwitchSettingTile extends ConsumerWidget {
  const SwitchSettingTile({
    super.key,
    required this.def,
    required this.icon,
    required this.title,
    this.subtitle,
  });

  final SettingDef<bool> def;
  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(appSettingsProvider.select((s) => s.get(def)));
    return _SettingTile(
      icon: icon,
      title: title,
      subtitle: subtitle,
      trailing: Switch(
        value: value,
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        thumbColor: _staticThumbColor(context),
        onChanged: (next) =>
            ref.read(appSettingsProvider.notifier).set(def, next),
      ),
      onTap: () => ref.read(appSettingsProvider.notifier).set(def, !value),
    );
  }
}

/// Single-choice setting between [options].
class DropdownSettingTile<T> extends ConsumerWidget {
  const DropdownSettingTile({
    super.key,
    required this.def,
    required this.icon,
    required this.title,
    required this.options,
    required this.labelOf,
    this.subtitle,
  });

  final SettingDef<T> def;
  final IconData icon;
  final String title;
  final String? subtitle;
  final List<T> options;
  final String Function(T value) labelOf;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(appSettingsProvider.select((s) => s.get(def)));
    return _SettingTile(
      icon: icon,
      title: title,
      subtitle: subtitle,
      stackWhenNarrow: true,
      trailing: SizedBox(width: 190, child: _dropdown(context, ref, value)),
      expandedTrailing: _dropdown(context, ref, value),
    );
  }

  Widget _dropdown(BuildContext context, WidgetRef ref, T value) {
    return DropdownButton<T>(
      value: value,
      isExpanded: true,
      underline: const SizedBox.shrink(),
      focusColor: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      items: [
        for (final option in options)
          DropdownMenuItem<T>(
            value: option,
            child: Text(labelOf(option), overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: (next) {
        if (next == null) return;
        ref.read(appSettingsProvider.notifier).set(def, next);
      },
    );
  }
}

/// Numeric setting with − / + buttons inside [min]–[max].
class StepperSettingTile extends ConsumerWidget {
  const StepperSettingTile({
    super.key,
    required this.def,
    required this.icon,
    required this.title,
    required this.step,
    required this.min,
    required this.max,
    required this.format,
    this.subtitle,
  });

  final SettingDef<double> def;
  final IconData icon;
  final String title;
  final String? subtitle;
  final double step;
  final double min;
  final double max;
  final String Function(double value) format;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(appSettingsProvider.select((s) => s.get(def)));
    final notifier = ref.read(appSettingsProvider.notifier);
    return _SettingTile(
      icon: icon,
      title: title,
      subtitle: subtitle,
      trailing: _stepper(context, value, notifier),
    );
  }

  Widget _stepper(
    BuildContext context,
    double value,
    AppSettingsNotifier notifier,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _stepperButton(
          icon: Icons.remove,
          tooltip: 'Decrease',
          onPressed:
              value <= min ? null : () => notifier.set(def, value - step),
        ),
        SizedBox(
          width: 46,
          child: Text(
            format(value),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),
        _stepperButton(
          icon: Icons.add,
          tooltip: 'Increase',
          onPressed:
              value >= max ? null : () => notifier.set(def, value + step),
        ),
      ],
    );
  }

  Widget _stepperButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
  }) {
    return IconButton(
      tooltip: tooltip,
      icon: Icon(icon, size: 20),
      onPressed: onPressed,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 36, height: 36),
    );
  }
}

/// Thumb colour for the switch that ignores hover/focus tinting.
WidgetStateProperty<Color> _staticThumbColor(BuildContext context) {
  final scheme = Theme.of(context).colorScheme;
  return WidgetStateProperty.resolveWith((states) {
    if (states.contains(WidgetState.disabled)) {
      return states.contains(WidgetState.selected)
          ? scheme.surface
          : scheme.onSurface.withValues(alpha: 0.38);
    }
    return states.contains(WidgetState.selected)
        ? scheme.onPrimary
        : scheme.outline;
  });
}
