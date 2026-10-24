import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/feedback.dart';
import '../../app/music.dart';
import '../../app/game_ui.dart';
import '../../app/providers.dart';
import '../../domain/chad.dart';
import '../../domain/combat.dart';
import '../../domain/difficulty.dart';
import '../../domain/expedition.dart';
import '../../domain/items.dart';
import '../../domain/rng.dart';
import '../../game/battle_scene.dart';
import '../../game/core.dart' show Sfx;
import '../../game/look.dart';

enum _View { battle, battleOver, event, result }

/// Plays one expedition (or practice duel) from start to finish.
class ExpeditionScreen extends ConsumerStatefulWidget {
  const ExpeditionScreen({
    super.key,
    required this.seed,
    required this.practice,
    this.progress,
  });

  final int seed;
  final bool practice;

  /// The saved state to start from: the very start of a new expedition, or a
  /// step reached before the app was closed. Null for practice duels.
  final ExpeditionProgress? progress;

  @override
  ConsumerState<ExpeditionScreen> createState() => _ExpeditionScreenState();
}

class _ExpeditionScreenState extends ConsumerState<ExpeditionScreen> with WantsMusic {
  late final ExpeditionRun _run;
  late final BattleScene _scene;
  BattleState? _battle;

  /// The enemy of the battle on screen. The "battle over" panel reads this and
  /// not the run, because the run moves on the moment the battle is finished.
  EnemyTemplate? _foe;
  _View _view = _View.battle;

  bool _busy = true;
  bool _saved = false;
  bool _lootWasNew = false;
  bool _showChad = true;
  List<String> _log = const [];
  late final String _chadStart;
  bool _leaveLater = false;

  @override
  void initState() {
    super.initState();
    wantMusic(MusicTrack.battle);
    final player = ref.read(playerProvider)!;
    final prefs = ref.read(prefsProvider);
    final freshHero = Combatant.fresh(
      name: player.hero.name,
      maxHp: player.maxHp,
      attack: player.attack,
      defense: player.defense,
    );
    final saved = widget.progress;
    if (!widget.practice && saved != null) {
      _run = ExpeditionRun.restore(progress: saved, hero: freshHero);
    } else {
      final expedition = widget.practice
          ? Expedition.practice(seed: widget.seed, heroLevel: player.level)
          : Expedition.generate(seed: widget.seed, heroLevel: player.level);
      _run = ExpeditionRun(
        expedition: expedition,
        hero: freshHero,
        rng: GameRng(widget.seed ^ 0x5bd1e995),
      );
    }
    final resumed = saved != null && saved.stepIndex > 0;
    _chadStart = ChadDialogue.line(
      resumed ? ChadContext.resume : ChadContext.adventureStart,
      seed: widget.seed,
    );

    _scene = BattleScene(
      look: ref.read(heroLookProvider) ??
          HeroLook(
            style: player.hero.appearanceStyle,
            color: player.hero.appearanceColor,
            skin: player.hero.appearanceSkin,
            equipped: {for (final i in player.equipped) i.id},
          ),
      heroName: player.hero.name,
      reducedMotion: prefs.reducedMotion,
      // Read the settings each time: they can change while the scene lives.
      onSfx: (s) { if (mounted) ref.read(feedbackProvider).sfx(s); },
      onHaptic: (h) { if (mounted) ref.read(feedbackProvider).haptic(h); },
    );
    _begin();
  }

  Future<void> _begin() async {
    await _scene.sceneReady;
    if (!mounted) return;
    await _beginStep();
  }

  Biome _biomeFor(EnemyTemplate e) {
    if (widget.practice) return Biome.meadow;
    if (e.boss) return Biome.arena;
    // The first battle is in the region's opening scenery, later ones in its second.
    final terrains = _run.expedition.region.terrains;
    final terrain = terrains[_run.stepIndex <= 1 ? 0 : terrains.length - 1];
    return switch (terrain) {
      Terrain.meadow => Biome.meadow,
      Terrain.forest => Biome.forest,
      Terrain.coast => Biome.coast,
      Terrain.cave => Biome.cave,
      Terrain.peak => Biome.peak,
      Terrain.storm => Biome.storm,
      Terrain.dunes => Biome.dunes,
    };
  }

  /// Starts whatever comes next in the run.
  Future<void> _beginStep() async {
    if (_run.finished) {
      await _finish();
      return;
    }
    final step = _run.current!;
    // Save the start of every step so closing the app never loses progress.
    if (!widget.practice) {
      await ref.read(repositoryProvider).saveExpeditionProgress(_run.progress);
      if (!mounted) return;
    }
    if (step.kind == StepKind.event) {
      setState(() {
        _view = _View.event;
        _busy = true;
      });
      await _scene.showEvent(step.event!.kind);
      if (mounted) setState(() => _busy = false);
      return;
    }
    final b = _run.startBattle();
    _foe = step.enemy;
    setState(() {
      _battle = b;
      _view = _View.battle;
      _busy = true;
      _log = b.log;
    });
    _scene.setFocus(b.focus);
    await _scene.beginBattle(
      template: step.enemy!,
      foe: b.enemy,
      heroNow: b.player,
      intent: b.intent,
      biome: _biomeFor(step.enemy!),
    );
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _finish() async {
    await _save();
    if (!mounted) return;
    setState(() => _view = _View.result);
    final victory = _run.victory;
    final loot = ItemCatalog.byId(_run.expedition.lootItemId);
    await _scene.showFinale(
      victory: victory,
      chest: victory && !widget.practice,
      item: victory && !widget.practice ? loot : null,
      isNew: _lootWasNew,
    );
  }

  Future<void> _save() async {
    if (_saved) return;
    _saved = true;
    final repo = ref.read(repositoryProvider);
    // Practice duels pay nothing, so there is nothing to save for them.
    if (!widget.practice) {
      _lootWasNew = await repo.recordExpedition(
        seed: widget.seed,
        victory: _run.victory,
        battlesWon: _run.battlesWon,
        xp: _run.xp,
        coins: _run.coins,
        lootItemId: _run.expedition.lootItemId,
        duplicateCoins: Expedition.duplicateCoins(_run.expedition.tier),
        potionsLeft: _run.potions,
      );
    }
    if (mounted) setState(() {});
  }

  Future<void> _act(BattleAction a) async {
    final before = _battle;
    if (_busy || before == null || !before.canAct(a)) return;
    ref.read(feedbackProvider).sfx(Sfx.tap);
    final next = BattleEngine.act(before, a, _run.rng);
    setState(() {
      _busy = true;
      _showChad = false;
      _log = next.log;
    });
    await _scene.play(
      next.events,
      heroAfter: next.player,
      enemyAfter: next.enemy,
      focusAfter: next.focus,
    );
    if (!mounted) return;
    setState(() {
      _battle = next;
      _busy = false;
      if (next.isOver) _view = _View.battleOver;
    });
    if (!next.isOver) _scene.setIntent(next.intent);
  }

  Future<void> _continueAfterBattle() async {
    if (_busy) return;
    // Lock the screen first: saving takes a moment, and a second tap in that
    // moment must not finish the same battle twice and skip a step.
    setState(() => _busy = true);
    _run.finishBattle(_battle!);
    await _beginStep();
  }

  Future<void> _onward() async {
    if (_busy) return;
    final kind = _run.current!.event!.kind;
    setState(() => _busy = true);
    _run.resolveEvent();
    await _scene.applyEvent(
      kind,
      heroHp: _run.hero.hp,
      stash: Expedition.stashCoins(_run.expedition.tier),
    );
    if (mounted) await _beginStep();
  }

  Future<bool> _confirmLeave() async {
    final choice = await showGameDialog<String>(
      context: context,
      title: widget.practice ? 'Retreat from the Duel?' : 'Retreat from the Expedition?',
      content: Text(widget.practice
          ? 'It is only practice, so nothing is lost.'
          : 'You keep everything earned so far, and you can also leave and '
              'come back: your expedition is saved at the start of each step.'),
      actions: [
        Builder(
          builder: (ctx) => GameButton(
            label: 'Keep Going',
            kind: GameButtonKind.positive,
            onPressed: () => Navigator.pop(ctx, 'keep'),
          ),
        ),
        if (!widget.practice)
          Builder(
            builder: (ctx) => GameButton(
              label: 'Leave and Come Back Later',
              kind: GameButtonKind.secondary,
              small: true,
              onPressed: () => Navigator.pop(ctx, 'later'),
            ),
          ),
        Builder(
          builder: (ctx) => GameButton(
            label: 'Retreat',
            kind: GameButtonKind.danger,
            small: true,
            onPressed: () => Navigator.pop(ctx, 'retreat'),
          ),
        ),
      ],
    );
    // Dismissing the dialog (tapping outside) means keep going.
    _leaveLater = choice == 'later';
    return choice == 'retreat' || _leaveLater;
  }

  @override
  Widget build(BuildContext context) {
    final done = _view == _View.result;
    // Keep the scene in step with the Reduce motion setting.
    _scene.reducedMotion = ref.watch(prefsProvider.select((p) => p.reducedMotion));

    return PopScope(
      canPop: done,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final nav = Navigator.of(context);
        if (await _confirmLeave()) {
          // "Leave and come back later" keeps the saved expedition; a retreat
          // ends it, keeping winnings but no loot.
          if (!_leaveLater) {
            _run.defeated = true;
            await _save();
          }
          if (mounted) nav.pop();
        }
      },
      child: GameScaffold(
        title: widget.practice ? 'Practice Duel' : 'Expedition',
        child: Column(
          children: [
            if (!widget.practice) _PathBar(run: _run, view: _view),
            Expanded(
              child: ClipRect(
                child: GameWidget(game: _scene),
              ),
            ),
            _panel(context),
          ],
        ),
      ),
    );
  }

  Widget _panel(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        color: GameColors.parchment,
        border: Border(top: BorderSide(color: GameColors.wood, width: 4)),
      ),
      child: switch (_view) {
        _View.battle => _battlePanel(context),
        _View.battleOver => _overPanel(context),
        _View.event => _eventPanel(context),
        _View.result => _resultPanel(context),
      },
    );
  }

  Widget _battlePanel(BuildContext context) {
    final b = _battle;
    if (b == null) return const SizedBox(height: 96);
    final t = Theme.of(context).textTheme;
    final heavy = b.intent == EnemyMove.windUp;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_showChad)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text('Chad: $_chadStart', style: t.bodySmall),
          )
        else
          Semantics(
            liveRegion: true,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                _busy ? _log.join(' ') : _intentLine(b, heavy),
                style: t.bodyMedium?.copyWith(
                  fontWeight: heavy && !_busy ? FontWeight.w700 : null,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 0.95,
          children: [
            for (final a in BattleAction.values)
              _ActionButton(
                action: a,
                enabled: !_busy && b.canAct(a),
                badge: switch (a) {
                  BattleAction.item => '${b.potions}',
                  BattleAction.skill => '${b.focus}/${BattleState.skillCost}',
                  _ => null,
                },
                onTap: () => _act(a),
              ),
          ],
        ),
      ],
    );
  }

  String _intentLine(BattleState b, bool heavy) => switch (b.intent) {
        EnemyMove.windUp => '${b.enemy.name} is winding up a heavy blow. Guarding will soften it.',
        EnemyMove.flurry => '${b.enemy.name} is getting ready to strike twice. Guarding halves both blows.',
        EnemyMove.brace => '${b.enemy.name} is bracing. A big hit will land softly, so build focus or guard.',
        EnemyMove.mend => '${b.enemy.name} is about to mend. Hit it now while you can.',
        EnemyMove.strike => '${b.enemy.name} is about to strike.',
      };

  Widget _overPanel(BuildContext context) {
    final b = _battle!;
    final won = b.phase == BattlePhase.victory;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(won ? '${b.enemy.name} is defeated!' : 'You are knocked out.',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(won
            ? 'Rewards from this battle: +${Expedition.xpForBattle(_foe!, tier: _run.expedition.tier)} XP, '
                '+${Expedition.coinsForBattle(_foe!, tier: _run.expedition.tier)} Coins.'
            : 'Rewards from battles already won are kept.'),
        const SizedBox(height: 12),
        GameButton(
          label: won ? 'Continue' : 'See Results',
          icon: Icons.arrow_forward_rounded,
          onPressed: _busy ? null : _continueAfterBattle,
        ),
      ],
    );
  }

  Widget _eventPanel(BuildContext context) {
    final ev = _run.current?.event;
    final t = Theme.of(context).textTheme;
    if (ev == null) return const SizedBox(height: 96);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(ev.title, style: t.titleMedium),
        const SizedBox(height: 4),
        Text(ev.text),
        const SizedBox(height: 6),
        Text(
          switch (ev.kind) {
            EventKind.restock => '+1 Potion',
            EventKind.rest => 'Recover 40% of your max HP',
            EventKind.treasure => '+${Expedition.stashCoins(_run.expedition.tier)} Coins',
            EventKind.bard => 'Start the next fight with 2 focus',
            EventKind.spring => 'Recover 25% of your max HP',
          },
          style: t.labelLarge,
        ),
        const SizedBox(height: 12),
        GameButton(
          label: 'Onward',
          icon: Icons.directions_walk_rounded,
          onPressed: _busy ? null : _onward,
        ),
      ],
    );
  }

  Widget _resultPanel(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final victory = _run.victory;
    final loot = ItemCatalog.byId(_run.expedition.lootItemId);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.practice
              ? (victory ? 'Duel Won!' : 'Good Practice!')
              : (victory ? 'Expedition Complete!' : 'Regrouping for Next Time'),
          style: t.titleLarge,
        ),
        const SizedBox(height: 4),
        Text(ChadDialogue.line(
          victory ? ChadContext.victory : ChadContext.defeat,
          seed: widget.seed,
        )),
        const SizedBox(height: 8),
        if (widget.practice)
          const Text('Practice has no rewards. Try again whenever you like.')
        else ...[
          Text('Battles Won: ${_run.battlesWon}   +${_run.xp} XP   +${_run.coins} Coins'),
          if (victory && loot != null)
            Text(
              _lootWasNew
                  ? 'New Equipment: ${loot.name} (${loot.bonusLabel})'
                  : 'You already own ${loot.name}, so it became ${Expedition.duplicateCoins(_run.expedition.tier)} coins.',
              style: t.titleSmall,
            ),
        ],
        const SizedBox(height: 12),
        GameButton(
          label: 'Back to the Guild',
          icon: Icons.home_rounded,
          kind: GameButtonKind.positive,
          onPressed: _saved ? () => Navigator.of(context).pop() : null,
        ),
      ],
    );
  }
}

class _PathBar extends StatelessWidget {
  const _PathBar({required this.run, required this.view});

  final ExpeditionRun run;
  final _View view;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final steps = run.expedition.steps;
    return Semantics(
      label: 'Expedition progress: step ${run.stepIndex.clamp(0, steps.length - 1) + 1} of ${steps.length}',
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
        color: scheme.surfaceContainerHigh,
        child: Row(
          children: [
            for (var i = 0; i < steps.length; i++) ...[
              if (i > 0)
                Expanded(
                  child: Container(
                    height: 3,
                    color: i <= run.stepIndex ? scheme.primary : scheme.outlineVariant,
                  ),
                ),
              _node(context, i, steps[i]),
            ],
          ],
        ),
      ),
    );
  }

  Widget _node(BuildContext context, int i, ExpeditionStep s) {
    final scheme = Theme.of(context).colorScheme;
    final done = i < run.stepIndex || run.victory;
    final current = i == run.stepIndex && !run.finished;
    final boss = s.enemy?.boss ?? false;
    final icon = done
        ? Icons.check
        : s.kind == StepKind.event
            ? Icons.local_fire_department
            : boss
                ? Icons.whatshot
                : Icons.shield;
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done
            ? scheme.primary
            : current
                ? scheme.primaryContainer
                : scheme.surfaceContainerHighest,
        border: Border.all(
          color: current ? scheme.primary : scheme.outlineVariant,
          width: current ? 2.5 : 1,
        ),
      ),
      child: Icon(
        icon,
        size: 18,
        color: done ? scheme.onPrimary : scheme.onSurfaceVariant,
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.action,
    required this.enabled,
    required this.onTap,
    this.badge,
  });

  final BattleAction action;
  final bool enabled;
  final VoidCallback onTap;
  final String? badge;

  static const _icons = {
    BattleAction.attack: Icons.bolt,
    BattleAction.guard: Icons.shield,
    BattleAction.skill: Icons.auto_awesome,
    BattleAction.item: Icons.local_drink,
  };

  static const _colors = {
    BattleAction.attack: GameColors.red,
    BattleAction.guard: GameColors.blue,
    BattleAction.skill: GameColors.purple,
    BattleAction.item: GameColors.green,
  };

  @override
  Widget build(BuildContext context) {
    final color = _colors[action]!;
    return Semantics(
      button: true,
      enabled: enabled,
      label: '${action.label}. ${action.help}${badge != null ? ' ($badge)' : ''}',
      child: ExcludeSemantics(
        child: FilledButton(
          onPressed: enabled ? onTap : null,
          style: FilledButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            disabledBackgroundColor: const Color(0xFFCDBFA3),
            disabledForegroundColor: const Color(0xFF8A7F6C),
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
            minimumSize: const Size(48, 64),
            elevation: enabled ? 4 : 0,
            shadowColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(
                color: enabled ? Color.lerp(color, Colors.black, 0.45)! : const Color(0xFFA89C86),
                width: 2.5,
              ),
            ),
          ),
          // Scaled down as a whole: the button is a fixed size in a grid, and large
          // text would otherwise push the badge out of the bottom.
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_icons[action], size: 24),
                const SizedBox(height: 2),
                Text(action.label, style: gameTitle(13, color: enabled ? Colors.white : const Color(0xFF8A7F6C))),
                if (badge != null)
                  Text(badge!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
