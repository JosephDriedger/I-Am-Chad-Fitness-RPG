import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/widgets.dart';
import '../../domain/activity.dart';
import '../../domain/chad.dart';
import '../../domain/hero.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _step = 0;
  final _name = TextEditingController();
  int _style = 0;
  int _color = 0;
  int _skin = 0;
  ExperienceLevel _level = ExperienceLevel.starting;
  final Set<ActivityCategory> _prefs = {};
  bool _dumbbells = false;
  bool _saving = false;

  static const _steps = 3;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  bool get _canContinue => _step != 1 || _name.text.trim().isNotEmpty;

  Future<void> _finish() async {
    setState(() => _saving = true);
    await ref.read(repositoryProvider).createHero(HeroProfile(
          name: _name.text.trim(),
          appearanceStyle: _style,
          appearanceColor: _color,
          appearanceSkin: _skin,
          experience: _level,
          preferredCategories: _prefs,
          hasDumbbells: _dumbbells,
        ));
    // The gate switches to the main app by itself once the hero is saved.
  }

  @override
  Widget build(BuildContext context) {
    final body = switch (_step) {
      0 => _welcome(context),
      1 => _create(context),
      _ => _preferences(context),
    };
    return Scaffold(
      appBar: AppBar(
        title: Text('Step ${_step + 1} of $_steps'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [body],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  if (_step > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _saving ? null : () => setState(() => _step--),
                        child: const Text('Back'),
                      ),
                    ),
                  if (_step > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: !_canContinue || _saving
                          ? null
                          : () {
                              if (_step < _steps - 1) {
                                setState(() => _step++);
                              } else {
                                _finish();
                              }
                            },
                      child: Text(_step == _steps - 1
                          ? 'Enter the Guild'
                          : _step == 0
                              ? 'Let\'s Go'
                              : 'Next'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _welcome(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('I Am Chad', style: t.displaySmall),
        Text('Fitness RPG', style: t.titleLarge),
        const SizedBox(height: 16),
        ChadBubble(text: ChadDialogue.line(ChadContext.welcome)),
        const SizedBox(height: 16),
        Text('How It Works', style: t.titleMedium),
        const SizedBox(height: 8),
        const _Bullet(Icons.edit_note,
            'Log real workouts at your own level. Smaller or easier versions '
            'earn the same rewards.'),
        const _Bullet(Icons.bolt,
            'Workouts give XP and adventure energy, with a gentle daily limit.'),
        const _Bullet(Icons.explore,
            'Spend energy on short turn-based expeditions with loot.'),
        const _Bullet(Icons.hotel,
            'Rest days are training. Missed days never cost you progress.'),
        const _Bullet(Icons.lock_outline,
            'Everything is saved on your device. No account needed.'),
        const SizedBox(height: 8),
        const SafetyNote(),
      ],
    );
  }

  Widget _create(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Create Your Adventurer', style: t.headlineSmall),
        const SizedBox(height: 16),
        Center(
          child: HeroAvatar(style: _style, color: _color, skin: _skin, size: 96),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _name,
          maxLength: 20,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Name',
            helperText: 'Any name you like. You can change it later.',
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 8),
        AppearancePicker(
          style: _style,
          color: _color,
          skin: _skin,
          onChanged: ({int? style, int? color, int? skin}) => setState(() {
            _style = style ?? _style;
            _color = color ?? _color;
            _skin = skin ?? _skin;
          }),
        ),
      ],
    );
  }

  Widget _preferences(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Where Are You Starting From?', style: t.headlineSmall),
        const SizedBox(height: 4),
        Text(
          'This only shapes the suggestions you see. You can change anything '
          'later.',
          style: t.bodyMedium,
        ),
        const SizedBox(height: 12),
        for (final l in ExperienceLevel.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Card(
              color: _level == l ? scheme.primaryContainer : null,
              child: ListTile(
                selected: _level == l,
                leading: Icon(_level == l
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked),
                title: Text(l.label),
                subtitle: Text(l.blurb),
                onTap: () => setState(() => _level = l),
              ),
            ),
          ),
        const SizedBox(height: 8),
        Text('What Do You Enjoy? (Optional)', style: t.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final c in ActivityCategory.values)
              FilterChip(
                label: Text(c.label),
                selected: _prefs.contains(c),
                onSelected: (on) => setState(() {
                  on ? _prefs.add(c) : _prefs.remove(c);
                }),
              ),
          ],
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('I Have Dumbbells'),
          subtitle: const Text('Unlocks weight-based suggestions'),
          value: _dumbbells,
          onChanged: (v) => setState(() => _dumbbells = v),
        ),
      ],
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.icon, this.text);

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
