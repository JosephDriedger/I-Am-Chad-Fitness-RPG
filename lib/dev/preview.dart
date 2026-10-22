import 'package:flame/game.dart';
import '../domain/combat.dart';
import '../domain/expedition.dart';
import '../domain/items.dart';
import '../game/battle_scene.dart';
import '../game/look.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../domain/activity.dart';
import '../domain/hero.dart';
import '../features/adventure/expedition_screen.dart';
import '../features/home/home_shell.dart';
import 'cast_scene.dart';

/// Developer shortcuts, enabled with `--dart-define=PREVIEW=<mode>`.
///
/// Modes: `cast` (art sheet), `duel` (practice duel), `expedition`, `hub`,
/// and the still scene states `boss`, `event`, `chest`.
/// The hero is created on demand so a scene can be opened in one step.
Widget? previewHome(String mode) {
  switch (mode) {
    case 'cast':
      return Scaffold(body: GameWidget(game: CastScene()));
    case 'duel':
      return const _Seeded(child: ExpeditionScreen(seed: 7, practice: true));
    case 'expedition':
      return const _Seeded(child: ExpeditionScreen(seed: 11, practice: false));
    case 'boss':
    case 'event':
    case 'chest':
      return _ScenePreview(mode);
    case 'hub':
      return const _Seeded(child: HomeShell());
  }
  return null;
}

class _Seeded extends ConsumerStatefulWidget {
  const _Seeded({required this.child});

  final Widget child;

  @override
  ConsumerState<_Seeded> createState() => _SeededState();
}

class _SeededState extends ConsumerState<_Seeded> {
  @override
  void initState() {
    super.initState();
    _seed();
  }

  Future<void> _seed() async {
    final repo = ref.read(repositoryProvider);
    if (await repo.watchHero().first == null) {
      await repo.createHero(const HeroProfile(
        name: 'Ada',
        appearanceStyle: 2,
        appearanceColor: 1,
        appearanceSkin: 2,
        experience: ExperienceLevel.returning,
        preferredCategories: {ActivityCategory.cardio},
        hasDumbbells: true,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final player = ref.watch(playerProvider);
    if (player == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return widget.child;
  }
}

/// A single battle-scene state on its own, for checking the art.
class _ScenePreview extends StatefulWidget {
  const _ScenePreview(this.mode);

  final String mode;

  @override
  State<_ScenePreview> createState() => _ScenePreviewState();
}

class _ScenePreviewState extends State<_ScenePreview> {
  late final BattleScene _scene = BattleScene(
    look: const HeroLook(
      style: 2,
      color: 1,
      skin: 2,
      equipped: {'iron_blade', 'wayfarer_cap', 'trail_vest'},
    ),
    heroName: 'Ada',
    reducedMotion: true,
  );

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    await _scene.sceneReady;
    final boss = widget.mode == 'boss';
    final template = boss ? EnemyPool.bosses[0] : EnemyPool.regular[0];
    final hero = Combatant.fresh(name: 'Ada', maxHp: 66, attack: 15, defense: 8);
    await _scene.beginBattle(
      template: template,
      foe: template.build(5),
      heroNow: hero.withHp(48),
      intent: boss ? EnemyMove.windUp : EnemyMove.strike,
      biome: boss ? Biome.arena : Biome.meadow,
    );
    _scene.setFocus(3);
    if (widget.mode == 'event') {
      await _scene.showEvent(EventKind.rest);
    } else if (widget.mode == 'chest') {
      await _scene.showFinale(
        victory: true,
        item: ItemCatalog.byId('iron_blade'),
      );
    }
  }

  @override
  Widget build(BuildContext context) =>
      Scaffold(body: GameWidget(game: _scene));
}
