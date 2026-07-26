import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/settings_repository.dart';
import '../../../state/settings_provider.dart';
import '../../theme/palette.dart';
import '../../widgets/page_body.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);
    final brightness = Theme.of(context).brightness;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: PageBody(
        child: ListView(
        children: [
          ListTile(
            title: const Text('Appearance'),
            trailing: DropdownButton<AppThemeMode>(
              value: settings.themeMode,
              onChanged: (mode) {
                if (mode != null) controller.setThemeMode(mode);
              },
              items: const [
                DropdownMenuItem(value: AppThemeMode.system, child: Text('System')),
                DropdownMenuItem(value: AppThemeMode.light, child: Text('Light')),
                DropdownMenuItem(value: AppThemeMode.dark, child: Text('Dark')),
              ],
            ),
          ),
          const Divider(height: 1),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Text('Color scheme',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
          ...AppPalettes.all.map(
            (scheme) => _SchemeTile(
              scheme: scheme,
              brightness: brightness,
              selected: scheme.id == settings.paletteId,
              onTap: () => controller.setPaletteId(scheme.id),
            ),
          ),
          const Divider(height: 32),
          SwitchListTile(
            title: const Text('Sound'),
            value: settings.soundEnabled,
            onChanged: controller.setSoundEnabled,
          ),
          SwitchListTile(
            title: const Text('Haptics'),
            value: settings.hapticsEnabled,
            onChanged: controller.setHapticsEnabled,
          ),
          const SizedBox(height: 24),
        ],
        ),
      ),
    );
  }
}

class _SchemeTile extends StatelessWidget {
  final PaletteScheme scheme;
  final Brightness brightness;
  final bool selected;
  final VoidCallback onTap;

  const _SchemeTile({
    required this.scheme,
    required this.brightness,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Preview in the brightness the user is actually looking at, so the
    // swatches match what they'll get.
    final preview = scheme.forBrightness(brightness);
    final active = context.palette;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        scheme.name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                      if (selected) ...[
                        const SizedBox(width: 6),
                        Icon(Icons.check_circle,
                            size: 16, color: active.primary),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    scheme.description,
                    style: TextStyle(fontSize: 12, color: active.noteText),
                  ),
                  const SizedBox(height: 8),
                  _Swatches(preview: preview),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Swatches extends StatelessWidget {
  final Palette preview;

  const _Swatches({required this.preview});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: preview.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: preview.gridLine),
      ),
      child: Row(
        children: List.generate(6, (i) {
          final digit = i + 1;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: preview.fillFor(digit),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                '$digit',
                style: TextStyle(
                  color: preview.textOn(digit),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
