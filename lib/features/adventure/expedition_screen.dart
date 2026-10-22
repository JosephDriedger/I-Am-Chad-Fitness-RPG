import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/feedback.dart';
import '../../app/providers.dart';
import '../../domain/chad.dart';
import '../../domain/combat.dart';
import '../../domain/expedition.dart';
import '../../domain/items.dart';
import '../../domain/rng.dart';
import '../../game/battle_scene.dart';
import '../../game/core.dart' show Sfx;
import '../../game/look.dart';

enum _View { battle, battleOver, event, result }

/// Plays one expedition (or practice duel) from start to finish.
class ExpeditionScreen extends ConsumerStatefulWidget {
  const ExpeditionScreen({super.key, required this.seed, required this.practice});

  final int seed;
  final bool practice;

  @override
  ConsumerState<ExpeditionScreen> createState() => _ExpeditionScreenState();
}

class _ExpeditionScreenState extends ConsumerState<ExpeditionScreen> {
  late final ExpeditionRun _run;
  late final BattleScene _scene;
  BattleState? _battle;
  _View _view = _View.battle;

  bool _busy = true;
  bool _saved = false;
  bool _lootWasNew = false;
  bool _showChad = true;
  List<String> _log = const [];
  late final String _chadStart;
  int _battlesStarted = 0;

  @override
  void initState() {
    super.initState();
    final player = ref.read(playerProvider)!;
    final prefs = ref.read(prefsProvider);
    final fx = ref.read(feedbackProvider);
    final expedition = widget.practice
        ? Expedition.practice(seed: widget.seed, heroLevel: player.level)
        : Expedition.generate(seed: widget.seed, heroLevel: player.level);
    _run = ExpeditionRun(
      expedition: expedition,
      hero: Combatant.fresh(
        name: player.hero.name,
        maxHp: player.maxHp,
        attack: player.attack,
        defense: player.defense,
      ),
      rng: GameRng(widget.seed ^ 0x5bd1e995),
    );
    _chadStart = ChadDialogue.line(ChadContext.adventureStart, seed: widget.seed);

    _scene = BattleScene(
      look: HeroLook(
        style: player.hero.appearanceStyle,
        color: player.hero.appearanceColor,
        skin: player.hero.appearanceSkin,
        equipped: {for (final i in player.equipped) i.id},
      ),
      heroName: player.hero.name,
      reducedMotion: prefs.reducedMotion,
      onSfx: fx.sfx,
      onHaptic: fx.haptic,
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
    return _battlesStarted <= 1 ? Biome.meadow : Biome.forest;
  }

  /// Starts whatever comes next in the run.
  Future<void> _beginStep() async {
    if (_run.finished) {
      await _finish();
      return;
    }
    final step = _run.current!;
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
    _battlesStarted++;
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
    if (widget.practice) {
      if (_run.victory) await repo.addCoins(Expedition.practiceCoins);
    } else {
      _lootWasNew = await repo.recordExpedition(
        seed: widget.seed,
        victory: _run.victory,
        battlesWon: _run.battlesWon,
        xp: _run.xp,
        coins: _run.coins,
        lootItemId: _run.expedition.lootItemId,
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
    _run.finishBattle(_battle!);
    await _beginStep();
  }

  Future<void> _onward() async {
    if (_busy) return;
    final kind = _run.current!.event!.kind;
    setState(() => _busy = true);
    _run.resolveEvent();
    await _scene.applyEvent(kind, heroHp: _run.hero.hp);
    if (mounted) await _beginStep();
  }

  Future<bool> _confirmLeave() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Retreat from the expedition?'),
        content: const Text(
            'You keep everything earned so far. There is no penalty for '
            'regrouping.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep going')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Retreat')),
        ],
      ),
    );
    return ok == true;
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
          _run.defeated = true; // retreat: keeps winnings, no loot
          await _save();
          if (mounted) nav.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.practice ? 'Practice duel' : 'Expedition'),
        ),
        body: SafeArea(
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
      ),
    );
  }

  Widget _panel(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
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

  String _intentLine(BattleState b, bool heavy) => heavy
      ? '${b.enemy.name} is winding up a heavy blow. Guarding will soften it.'
      : '${b.enemy.name} is about to strike.';

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
            ? 'Rewards from this battle: +${Expedition.xpForBattle(_run.current!.enemy!)} XP, '
                '+${Expedition.coinsForBattle(_run.current!.enemy!)} coins.'
            : 'Rewards from battles already won are kept.'),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: _busy ? null : _continueAfterBattle,
          child: Text(won ? 'Continue' : 'See results'),
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
            EventKind.restock => '+1 potion',
            EventKind.rest => 'Recover 40% of your max HP',
            EventKind.treasure => '+8 coins',
          },
          style: t.labelLarge,
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _busy ? null : _onward,
            child: const Text('Onward'),
          ),
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
              ? (victory ? 'Duel won!' : 'Good practice!')
              : (victory ? 'Expedition complete!' : 'Regrouping for next time'),
          style: t.titleLarge,
        ),
        const SizedBox(height: 4),
        Text(ChadDialogue.line(
          victory ? ChadContext.victory : ChadContext.defeat,
          seed: widget.seed,
        )),
        const SizedBox(height: 8),
        if (widget.practice)
          Text(victory
              ? '+${Expedition.practiceCoins} coins'
              : 'No coins this time. Practice is free, so try again whenever you like.')
        else ...[
          Text('Battles won: ${_run.battlesWon}   +${_run.xp} XP   +${_run.coins} coins'),
          if (victory && loot != null)
            Text(
              _lootWasNew
                  ? 'New equipment: ${loot.name} (${loot.bonusLabel})'
                  : 'You already own ${loot.name}, so it became 10 coins.',
              style: t.titleSmall,
            ),
        ],
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _saved ? () => Navigator.of(context).pop() : null,
            child: const Text('Back to the Guild'),
          ),
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
    BattleAction.guard: Icons.shield_outlined,
    BattleAction.skill: Icons.auto_awesome,
    BattleAction.item: Icons.local_drink_outlined,
  };

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: enabled,
      label: '${action.label}. ${action.help}${badge != null ? ' ($badge)' : ''}',
      child: ExcludeSemantics(
        child: FilledButton.tonal(
          onPressed: enabled ? onTap : null,
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
            minimumSize: const Size(48, 56),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_icons[action], size: 22),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(action.label, style: const TextStyle(fontSize: 12)),
              ),
              if (badge != null)
                Text(badge!, style: const TextStyle(fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }
}
