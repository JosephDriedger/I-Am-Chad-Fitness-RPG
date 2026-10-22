import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/widgets.dart';
import '../../domain/chad.dart';
import '../../domain/combat.dart';
import '../../domain/expedition.dart';
import '../../domain/items.dart';
import '../../domain/rng.dart';

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
  BattleState? _battle;
  _View _view = _View.battle;

  bool _saved = false;
  bool _lootWasNew = false;
  late final String _chadStart;

  @override
  void initState() {
    super.initState();
    final player = ref.read(playerProvider)!;
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
    _advance();
  }

  /// Moves to whatever comes next in the run.
  void _advance() {
    if (_run.finished) {
      _view = _View.result;
      _save();
    } else if (_run.current!.kind == StepKind.event) {
      _view = _View.event;
    } else {
      _battle = _run.startBattle();
      _view = _View.battle;
    }
  }

  Future<void> _save() async {
    if (_saved) return;
    _saved = true;
    final repo = ref.read(repositoryProvider);
    if (widget.practice) {
      if (_run.victory) await repo.addCoins(Expedition.practiceCoins);
    } else {
      final isNew = await repo.recordExpedition(
        seed: widget.seed,
        victory: _run.victory,
        battlesWon: _run.battlesWon,
        xp: _run.xp,
        coins: _run.coins,
        lootItemId: _run.expedition.lootItemId,
      );
      _lootWasNew = isNew;
    }
    if (mounted) setState(() {});
  }

  void _act(BattleAction a) {
    setState(() {
      _battle = BattleEngine.act(_battle!, a, _run.rng);
      if (_battle!.isOver) _view = _View.battleOver;
    });
  }

  void _continueAfterBattle() {
    setState(() {
      _run.finishBattle(_battle!);
      _advance();
    });
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
          child: switch (_view) {
            _View.battle || _View.battleOver => _battleView(context),
            _View.event => _eventView(context),
            _View.result => _resultView(context),
          },
        ),
      ),
    );
  }

  // ---- Battle -------------------------------------------------------------

  Widget _battleView(BuildContext context) {
    final b = _battle!;
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final over = b.isOver;
    final step = _run.expedition.steps
        .take(_run.stepIndex + 1)
        .where((s) => s.kind == StepKind.battle)
        .length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (!widget.practice)
          Text('Battle $step of ${_run.expedition.battleCount}',
              style: t.labelLarge),
        if (_run.stepIndex == 0 && b.turn == 1 && !over) ...[
          const SizedBox(height: 8),
          ChadBubble(text: _chadStart),
        ],
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(b.enemy.name, style: t.titleLarge),
                const SizedBox(height: 8),
                StatBar(
                  label: 'Enemy HP',
                  value: b.enemy.hp,
                  max: b.enemy.maxHp,
                  color: scheme.error,
                  icon: Icons.favorite_border,
                ),
                if (!over) ...[
                  const SizedBox(height: 12),
                  _Intent(move: b.intent),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(b.player.name, style: t.titleMedium),
                const SizedBox(height: 8),
                StatBar(
                  label: 'Your HP',
                  value: b.player.hp,
                  max: b.player.maxHp,
                  icon: Icons.favorite,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Semantics(
                      label: 'Focus ${b.focus} of ${BattleState.maxFocus}',
                      child: ExcludeSemantics(
                        child: Row(children: [
                          const Text('Focus '),
                          for (var i = 0; i < BattleState.maxFocus; i++)
                            Icon(
                              i < b.focus ? Icons.circle : Icons.circle_outlined,
                              size: 14,
                            ),
                        ]),
                      ),
                    ),
                    const Spacer(),
                    StatChip(
                      icon: Icons.local_drink_outlined,
                      text: '${b.potions}',
                      tip: '${b.potions} potions',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Semantics(
          liveRegion: true,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final line in b.log) Text(line),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (over)
          FilledButton(
            onPressed: _continueAfterBattle,
            child: Text(b.phase == BattlePhase.victory ? 'Continue' : 'See results'),
          )
        else
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.9,
            children: [
              for (final a in BattleAction.values)
                _ActionButton(
                  action: a,
                  enabled: b.canAct(a),
                  onTap: () => _act(a),
                ),
            ],
          ),
      ],
    );
  }

  // ---- Events and results ---------------------------------------------------

  Widget _eventView(BuildContext context) {
    final ev = _run.current!.event!;
    final t = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ev.title, style: t.titleLarge),
                const SizedBox(height: 8),
                Text(ev.text),
                const SizedBox(height: 8),
                Text(
                  switch (ev.kind) {
                    EventKind.restock => '+1 potion',
                    EventKind.rest => 'Recover 40% of your max HP',
                    EventKind.treasure => '+8 coins',
                  },
                  style: t.labelLarge,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () => setState(() {
            _run.resolveEvent();
            _advance();
          }),
          child: const Text('Onward'),
        ),
      ],
    );
  }

  Widget _resultView(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final victory = _run.victory;
    final loot = ItemCatalog.byId(_run.expedition.lootItemId);
    final seed = widget.seed;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Icon(victory ? Icons.emoji_events : Icons.healing,
            size: 56, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 8),
        Text(
          widget.practice
              ? (victory ? 'Duel won!' : 'Good practice!')
              : (victory ? 'Expedition complete!' : 'Regrouping for next time'),
          style: t.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        ChadBubble(
          text: ChadDialogue.line(
            victory ? ChadContext.victory : ChadContext.defeat,
            seed: seed,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Rewards', style: t.titleMedium),
                const SizedBox(height: 8),
                if (widget.practice)
                  Text(victory
                      ? '+${Expedition.practiceCoins} coins'
                      : 'No coins this time. Practice is free, so try again '
                          'whenever you like.')
                else ...[
                  Text('Battles won: ${_run.battlesWon}'),
                  Text('+${_run.xp} XP'),
                  Text('+${_run.coins} coins'),
                  if (victory && loot != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _lootWasNew
                          ? 'New equipment: ${loot.name} (${loot.bonusLabel})'
                          : 'You already own ${loot.name}, so it became '
                              '10 coins.',
                      style: t.titleSmall,
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _saved ? () => Navigator.of(context).pop() : null,
          child: const Text('Back to the Guild'),
        ),
      ],
    );
  }
}

class _Intent extends StatelessWidget {
  const _Intent({required this.move});

  final EnemyMove move;

  @override
  Widget build(BuildContext context) {
    final heavy = move == EnemyMove.windUp;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: heavy ? scheme.errorContainer : scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(heavy ? Icons.warning_amber_rounded : Icons.flash_on, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              heavy
                  ? 'Next: heavy blow! Guarding will soften it.'
                  : 'Next: a regular strike.',
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.action,
    required this.enabled,
    required this.onTap,
  });

  final BattleAction action;
  final bool enabled;
  final VoidCallback onTap;

  static const _icons = {
    BattleAction.attack: Icons.bolt,
    BattleAction.guard: Icons.shield_outlined,
    BattleAction.skill: Icons.auto_awesome,
    BattleAction.item: Icons.local_drink_outlined,
  };

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: action.help,
      child: FilledButton.tonal(
        onPressed: enabled ? onTap : null,
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_icons[action]),
            const SizedBox(height: 2),
            Text(action.label),
          ],
        ),
      ),
    );
  }
}
