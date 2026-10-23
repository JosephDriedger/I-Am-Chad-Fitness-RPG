import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/game_ui.dart';
import '../../app/providers.dart';
import '../../app/widgets.dart';
import '../../domain/chad.dart';
import '../../domain/expedition.dart';
import '../../domain/shop.dart';
import '../shop/shop_screen.dart';
import 'expedition_screen.dart';

/// The expedition gate: a level-select map, a way back into an unfinished
/// expedition, and the always-free Practice Yard.
class AdventureScreen extends ConsumerWidget {
  const AdventureScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(playerProvider);
    final active = ref.watch(activeExpeditionProvider).value;
    if (player == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final canGo = player.energy >= Expedition.energyCost;
    final expedition = (active?.expedition) ??
        Expedition.generate(seed: 1, heroLevel: player.level);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
      children: [
        Row(
          children: [
            Expanded(child: Text('Adventure', style: gameTitle(30))),
            GameChip(text: '${player.energy} Energy', icon: Icons.bolt_rounded, color: GameColors.teal),
          ],
        ),
        const SizedBox(height: 10),
        ChadBubble(
          text: active != null
              ? ChadDialogue.line(ChadContext.resume, seed: active.seed)
              : canGo
                  ? ChadDialogue.line(ChadContext.adventureStart, seed: player.hero.victories)
                  : ChadDialogue.line(ChadContext.lowEnergy),
        ),
        const SizedBox(height: 16),
        if (active != null)
          _ResumeCard(progress: active, hpMax: player.maxHp)
        else
          GamePanel(
            title: 'Expedition',
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _MapArt(steps: expedition.steps, current: -1),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Three short battles with a camp on the way. Earn XP, coins and a piece of equipment.',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 10),
                      const Wrap(spacing: 8, runSpacing: 8, children: [
                        GameChip(text: 'Costs ${Expedition.energyCost} Energy', icon: Icons.bolt_rounded, color: GameColors.teal),
                        GameChip(text: 'About 3 Min', icon: Icons.timer_outlined, color: GameColors.cream),
                      ]),
                      const SizedBox(height: 14),
                      GameButton(
                        label: canGo ? 'Set Out' : 'Need ${Expedition.energyCost} Energy',
                        icon: canGo ? Icons.explore : Icons.lock_outline,
                        onPressed: canGo ? () => _start(context, ref, player.level, player.maxHp) : null,
                      ),
                      if (!canGo) ...[
                        const SizedBox(height: 8),
                        const Text(
                          'Energy comes from the workouts you log. A short walk or some stretching is plenty.',
                          style: TextStyle(color: GameColors.inkSoft, fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        GamePanel(
          title: 'Guild Shop',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Spend your coins on gear and healing potions. Potions in your pouch come along on expeditions.',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 8, children: [
                GameChip(text: '${player.hero.coins} Coins', icon: Icons.monetization_on, color: GameColors.gold),
                GameChip(
                  text: 'Potion Pouch ${player.hero.potionStock}/${Shop.potionPouchMax}',
                  icon: Icons.local_drink,
                  color: GameColors.green,
                ),
              ]),
              const SizedBox(height: 12),
              GameButton(
                label: 'Visit the Shop',
                icon: Icons.storefront_rounded,
                kind: GameButtonKind.secondary,
                onPressed: () => Navigator.of(context).push(gameRoute<void>(const ShopScreen())),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GamePanel(
          title: 'Practice Yard',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'A relaxed duel that is always free. No XP, just a few coins. Perfect for rest days.',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              GameButton(
                label: 'Practice Duel',
                icon: Icons.sports_martial_arts,
                kind: GameButtonKind.secondary,
                onPressed: () => _practice(context, ref),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: GameChip(
            text: 'Expeditions Won: ${player.hero.victories}',
            icon: Icons.emoji_events_rounded,
          ),
        ),
      ],
    );
  }

  Future<void> _start(BuildContext context, WidgetRef ref, int level, int maxHp) async {
    final seed = ref.read(clockProvider)().millisecondsSinceEpoch & 0x7FFFFFFF;
    // Potions from the pouch come along, up to a limit, on top of the free ones.
    final bring = Shop.potionsToBring(ref.read(heroProvider).value?.potionStock ?? 0);
    final progress = ExpeditionProgress.fresh(
      seed: seed,
      heroLevel: level,
      heroMaxHp: maxHp,
      potions: Shop.basePotions + bring,
    );
    // Energy, the pouch potions and the saved starting point are written together.
    await ref.read(repositoryProvider).startExpedition(
          progress,
          energyCost: Expedition.energyCost,
          broughtPotions: bring,
        );
    if (!context.mounted) return;
    await Navigator.of(context).push(
      gameRoute<void>(ExpeditionScreen(seed: seed, practice: false, progress: progress)),
    );
  }

  Future<void> _practice(BuildContext context, WidgetRef ref) async {
    final seed = ref.read(clockProvider)().millisecondsSinceEpoch & 0x7FFFFFFF;
    await Navigator.of(context).push(
      gameRoute<void>(ExpeditionScreen(seed: seed, practice: true)),
    );
  }
}

/// An unfinished expedition: where you are, and a button to carry on.
class _ResumeCard extends ConsumerWidget {
  const _ResumeCard({required this.progress, required this.hpMax});

  final ExpeditionProgress progress;
  final int hpMax;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exp = progress.expedition;
    final step = progress.stepIndex.clamp(0, exp.steps.length - 1);
    final s = exp.steps[step];
    final where = s.kind == StepKind.event
        ? 'at a camp'
        : s.enemy!.boss
            ? 'facing a boss'
            : 'in a battle';
    return GamePanel(
      title: 'Expedition in Progress',
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _MapArt(steps: exp.steps, current: step),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'You are $where, step ${step + 1} of ${exp.steps.length}. '
                  'Nothing is lost when you close the app.',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  GameChip(text: 'HP ${progress.heroHp}/$hpMax', icon: Icons.favorite, color: GameColors.red),
                  GameChip(text: '${progress.potions} Potions', icon: Icons.local_drink, color: GameColors.green),
                  GameChip(text: '+${progress.xp} XP', icon: Icons.star_rounded),
                  GameChip(text: '+${progress.coins} Coins', icon: Icons.monetization_on, color: GameColors.gold),
                ]),
                const SizedBox(height: 14),
                GameButton(
                  label: 'Resume Expedition',
                  icon: Icons.play_arrow_rounded,
                  kind: GameButtonKind.positive,
                  onPressed: () => Navigator.of(context).push(
                    gameRoute<void>(ExpeditionScreen(seed: progress.seed, practice: false, progress: progress)),
                  ),
                ),
                const SizedBox(height: 8),
                GameButton(
                  label: 'Abandon and Keep Rewards',
                  icon: Icons.flag,
                  kind: GameButtonKind.secondary,
                  small: true,
                  onPressed: () => _confirmAbandon(context, ref),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmAbandon(BuildContext context, WidgetRef ref) async {
    final ok = await showGameDialog<bool>(
      context: context,
      title: 'Abandon the Expedition?',
      content: const Text(
        'You keep the XP and coins from battles already won. There is no penalty, '
        'but the energy you spent is not refunded and there is no loot.',
      ),
      actions: [
        Builder(
          builder: (ctx) => GameButton(
            label: 'Abandon',
            kind: GameButtonKind.danger,
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ),
        Builder(
          builder: (ctx) => GameButton(
            label: 'Keep Going',
            kind: GameButtonKind.positive,
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
        ),
      ],
    );
    if (ok == true) {
      await ref.read(repositoryProvider).recordExpedition(
            seed: progress.seed,
            victory: false,
            battlesWon: progress.battlesWon,
            xp: progress.xp,
            coins: progress.coins,
            lootItemId: '',
            potionsLeft: progress.potions,
          );
    }
  }
}

/// A little overworld map: a winding road through the expedition's steps.
class _MapArt extends StatelessWidget {
  const _MapArt({required this.steps, required this.current});

  final List<ExpeditionStep> steps;

  /// The step the hero is on, or -1 for a map that hasn't been started.
  final int current;

  static const _xs = [0.12, 0.37, 0.63, 0.88];
  static const _ys = [0.66, 0.34, 0.66, 0.34];

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Expedition map with ${steps.length} stops',
      child: ExcludeSemantics(
        child: AspectRatio(
          aspectRatio: 2.4,
          child: LayoutBuilder(builder: (context, box) {
            final w = box.maxWidth, h = box.maxHeight;
            Offset at(int i) => Offset(_xs[i] * w, _ys[i] * h);
            return Stack(
              children: [
                Positioned.fill(child: CustomPaint(painter: _MapPainter([for (var i = 0; i < steps.length; i++) at(i)], current))),
                for (var i = 0; i < steps.length; i++)
                  Positioned(
                    left: at(i).dx - 22,
                    top: at(i).dy - 22,
                    child: _Node(step: steps[i], done: current > i, here: current == i),
                  ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

class _Node extends StatelessWidget {
  const _Node({required this.step, required this.done, required this.here});

  final ExpeditionStep step;
  final bool done;
  final bool here;

  @override
  Widget build(BuildContext context) {
    final boss = step.enemy?.boss ?? false;
    final icon = done
        ? Icons.check
        : step.kind == StepKind.event
            ? Icons.local_fire_department
            : boss
                ? Icons.whatshot
                : Icons.shield;
    final color = done ? GameColors.green : boss ? GameColors.red : GameColors.wood;
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(color: here ? GameColors.gold : GameColors.woodDark, width: here ? 4 : 2.5),
        boxShadow: [
          const BoxShadow(color: Color(0x66000000), offset: Offset(0, 3)),
          if (here) const BoxShadow(color: Color(0x88F2C94C), blurRadius: 12, spreadRadius: 2),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 24),
    );
  }
}

class _MapPainter extends CustomPainter {
  _MapPainter(this.points, this.current);

  final List<Offset> points;
  final int current;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFBFE3F5), Color(0xFFE9F6FB)],
        ).createShader(rect),
    );
    // Rolling hills.
    canvas.drawOval(Rect.fromCenter(center: Offset(size.width * 0.2, size.height * 1.0), width: size.width * 0.9, height: size.height * 0.9), Paint()..color = const Color(0xFF8FC47A));
    canvas.drawOval(Rect.fromCenter(center: Offset(size.width * 0.85, size.height * 1.05), width: size.width * 0.9, height: size.height * 0.95), Paint()..color = const Color(0xFF7FB86A));
    canvas.drawRect(Rect.fromLTWH(0, size.height * 0.86, size.width, size.height * 0.14), Paint()..color = const Color(0xFF6AA84F));
    canvas.drawCircle(Offset(size.width * 0.92, size.height * 0.16), 14, Paint()..color = const Color(0xFFFFF2A8));

    // The road.
    final road = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final a = points[i - 1], b = points[i];
      final mid = Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2);
      road.quadraticBezierTo(a.dx + (b.dx - a.dx) * 0.2, mid.dy + (i.isOdd ? 16 : -16), mid.dx, mid.dy);
      road.quadraticBezierTo(b.dx - (b.dx - a.dx) * 0.2, mid.dy + (i.isOdd ? -16 : 16), b.dx, b.dy);
    }
    canvas.drawPath(
      road,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFFD7B98E),
    );
    canvas.drawPath(
      road,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFFF3E4C2),
    );
  }

  @override
  bool shouldRepaint(_MapPainter old) => old.current != current || old.points != points;
}
