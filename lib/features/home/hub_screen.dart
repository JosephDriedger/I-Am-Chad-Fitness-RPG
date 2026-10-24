import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/feedback.dart';
import '../../app/game_ui.dart';
import '../../app/providers.dart';
import '../../app/widgets.dart';
import '../../domain/chad.dart';
import '../../domain/cosmetics.dart';
import '../../domain/expedition.dart';
import '../../domain/player_state.dart';
import '../../domain/quests.dart';
import '../../domain/workout.dart';
import '../../game/hub_scene.dart';
import '../../game/look.dart';
import '../adventure/adventure_screen.dart';
import '../character/character_screen.dart';
import '../guild/quests_screen.dart';
import '../history/history_screen.dart';
import '../settings/settings_screen.dart';
import '../story/chronicle_screen.dart';
import '../workout/workout_screen.dart';

/// The home screen: a living guild hall you tap around in, with a HUD that
/// mirrors your real-world progress.
class HubScreen extends ConsumerStatefulWidget {
  const HubScreen({super.key});

  @override
  ConsumerState<HubScreen> createState() => _HubScreenState();
}

class _HubScreenState extends ConsumerState<HubScreen> {
  late final HubScene _scene;
  int _chadNudge = 0;
  bool _navigating = false;

  /// Chapters already offered this session, so "Later" is respected.
  final _offered = <int>{};

  @override
  void initState() {
    super.initState();
    _scene = HubScene(
      initial: _stateFor(ref.read(playerProvider)!),
      reducedMotion: ref.read(prefsProvider).reducedMotion,
      // Read the settings each time: they can change while the scene lives.
      onSfx: (s) { if (mounted) ref.read(feedbackProvider).sfx(s); },
      onHaptic: (h) { if (mounted) ref.read(feedbackProvider).haptic(h); },
      onSelect: _open,
      onChadTap: () => setState(() => _chadNudge++),
    );
  }

  HubState _stateFor(PlayerStatus p) {
    final workouts = ref.read(workoutsProvider).value ?? const <WorkoutEntry>[];
    final items = ref.read(itemsProvider).value ?? const [];
    final prefs = ref.read(prefsProvider);
    final now = ref.read(clockProvider)();
    final today = workouts.where((w) => dayKey(w.performedAt) == dayKey(now)).toList();
    final goal = QuestBoard.weeklyGoal(
      level: p.hero.experience,
      now: now,
      entries: workouts,
      target: p.hero.weeklyGoalTarget,
    );
    final quests = QuestBoard.dailySuggestions(
      level: p.hero.experience,
      day: now,
      preferred: p.hero.preferredCategories,
      hasDumbbells: p.hero.hasDumbbells,
    );
    final ctx = workouts.isEmpty
        ? ChadContext.welcome
        : today.isNotEmpty
            ? ChadContext.afterWorkout
            : (ref.read(storyStatusProvider)?.unread.isNotEmpty ?? false)
                ? ChadContext.newChapter
                : goal.met
                    ? ChadContext.restDay
                : ChadContext.idle;
    final seed = now.difference(DateTime(now.year)).inDays + _chadNudge;
    final quiet = prefs.quietChad && workouts.isNotEmpty;
    final cosmetics = ref.read(cosmeticContextProvider);
    return HubState(
      look: ref.read(heroLookProvider) ??
          HeroLook(
            style: p.hero.appearanceStyle,
            color: p.hero.appearanceColor,
            skin: p.hero.appearanceSkin,
            equipped: {for (final i in p.equipped) i.id},
          ),
      // A gentle "start here" until the first workout is logged, then never again.
      highlight: workouts.isEmpty ? HubTarget.train : null,
      pennants: cosmetics == null ? const [] : [for (final x in Cosmetics.earnedPennants(cosmetics)) x.color],
      trophies: cosmetics == null ? const [] : [for (final t in Cosmetics.earnedTrophies(cosmetics)) t.shape],
      patronDecor: cosmetics == null ? const {} : Cosmetics.patronDecor(cosmetics),
      chadLine: quiet ? 'Tap me if you want a word.' : ChadDialogue.line(ctx, seed: seed),
      questPending: quests.any((q) => !q.isDoneBy(today)),
      canAdventure: p.energy >= Expedition.energyCost,
      weeklyDone: goal.daysActive,
      weeklyGoal: goal.target,
      hour: now.hour,
      itemsOwned: items.length,
    );
  }

  Future<void> _open(HubTarget target) async {
    if (_navigating) return;
    _navigating = true;
    final before = ref.read(playerProvider)!;
    final page = switch (target) {
      HubTarget.train => const GamePage(title: 'Train', child: WorkoutScreen()),
      HubTarget.quests => const QuestsScreen(),
      HubTarget.adventure => const GamePage(title: 'Adventure', child: AdventureScreen()),
      HubTarget.hero => const GamePage(title: 'Hero', child: CharacterScreen()),
      HubTarget.journal => const GamePage(title: 'Journal', child: HistoryScreen()),
    };
    await Navigator.of(context).push(gameRoute<void>(page));
    if (!mounted) return;
    _navigating = false;
    await _scene.resume();
    await _celebrate(before);
    await _maybeOfferStory();
  }

  /// Offers the next unread chapter, once per session, only while the hall is
  /// what the player is looking at. "Later" is always fine.
  Future<void> _maybeOfferStory() async {
    if (!mounted || _navigating || !ref.read(storyAutoOfferProvider)) return;
    if (ModalRoute.of(context)?.isCurrent != true) return;
    final status = ref.read(storyStatusProvider);
    if (status == null) return;
    final chapter = status.unread.where((c) => !_offered.contains(c.number)).firstOrNull;
    if (chapter == null) return;
    _offered.add(chapter.number);
    _navigating = true;
    final readNow = await showGameDialog<bool>(
      context: context,
      title: 'A New Chapter!',
      content: Text('${chapter.label}: ${chapter.title}\n\n${chapter.summary}'),
      actions: [
        Builder(
          builder: (ctx) => GameButton(
            label: 'Read Now',
            icon: Icons.auto_stories_rounded,
            kind: GameButtonKind.positive,
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ),
        Builder(
          builder: (ctx) => GameButton(
            label: 'Later',
            kind: GameButtonKind.secondary,
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
        ),
      ],
    );
    if (!mounted) return;
    if (readNow == true) {
      await openChapter(context, chapter);
    }
    if (!mounted) return;
    _navigating = false;
    await _scene.resume();
    // A read chapter can lead straight on to the next that has opened.
    if (readNow == true) await _maybeOfferStory();
  }

  /// Plays the "you earned something" moments after returning to the hall.
  Future<void> _celebrate(PlayerStatus before) async {
    // Saved data reaches the screen a beat after the page closes, so give it
    // a moment to arrive instead of reading a stale status.
    PlayerStatus? after;
    for (var i = 0; i < 15 && mounted; i++) {
      after = ref.read(playerProvider);
      if (after != null && _changed(before, after)) break;
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    if (after == null || !mounted) return;
    final xp = after.totalXp - before.totalXp;
    final energy = after.energy - before.energy;
    final coins = after.hero.coins - before.hero.coins;
    if (xp > 0 || energy > 0 || coins > 0) {
      await _scene.showGain(
        xp: xp > 0 ? xp : 0,
        energy: energy > 0 ? energy : 0,
        coins: coins > 0 ? coins : 0,
      );
    }
    if (after.level > before.level && mounted) {
      await _scene.celebrateLevelUp(after.level);
    }
  }

  static bool _changed(PlayerStatus a, PlayerStatus b) =>
      a.totalXp != b.totalXp ||
      a.energy != b.energy ||
      a.hero.coins != b.hero.coins;

  @override
  Widget build(BuildContext context) {
    final player = ref.watch(playerProvider);
    // The story status arrives a beat after launch; offer once it has.
    ref.listen(storyStatusProvider, (prev, next) {
      if (prev == null && next != null) _maybeOfferStory();
    });
    // Rebuild whenever anything the hall shows changes.
    ref.watch(workoutsProvider);
    ref.watch(itemsProvider);
    ref.watch(heroLookProvider);
    ref.watch(cosmeticContextProvider);
    final prefs = ref.watch(prefsProvider);
    _scene.reducedMotion = prefs.reducedMotion;
    if (player == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final state = _stateFor(player);
    _scene.apply(state);

    final hud = _Hud(
      player: player,
      dye: ref.watch(heroLookProvider)?.dye,
      goalDone: state.weeklyDone,
      goalTarget: state.weeklyGoal,
      streak: ref.watch(streakProvider)?.current ?? 0,
      onSettings: () => Navigator.of(context).push(gameRoute<void>(const SettingsScreen())),
    );
    Widget menu(bool vertical) => _MenuBar(
          vertical: vertical,
          canAdventure: state.canAdventure,
          questPending: state.questPending,
          onTap: _scene.activate,
        );

    return LayoutBuilder(
      builder: (context, box) {
        // Held sideways, the menu becomes a rail down the right-hand side, so the hall
        // has the whole height instead of being covered by a bar along the bottom.
        if (box.maxWidth > box.maxHeight * 1.2) {
          return Row(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(child: GameWidget(game: _scene)),
                    SafeArea(right: false, child: Column(children: [hud, const Spacer()])),
                  ],
                ),
              ),
              SafeArea(left: false, child: SizedBox(width: 104, child: menu(true))),
            ],
          );
        }
        return Stack(
          children: [
            Positioned.fill(child: GameWidget(game: _scene)),
            SafeArea(
              child: Column(
                children: [
                  hud,
                  const Spacer(),
                  menu(false),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// A plain scaffolded page around the older list-style screens.
class GamePage extends StatelessWidget {
  const GamePage({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => GameScaffold(title: title, child: child);
}

const _wood = Color(0xFF4A2F1A);
const _woodLight = Color(0xFF6B4528);
const _cream = Color(0xFFFFF3D6);

class _Hud extends StatelessWidget {
  const _Hud({
    required this.player,
    required this.dye,
    required this.goalDone,
    required this.goalTarget,
    required this.streak,
    required this.onSettings,
  });

  final PlayerStatus player;
  final HairDye? dye;
  final int goalDone;
  final int goalTarget;
  final int streak;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final h = player.hero;
    final xpNow = player.totalXp - player.levelStartXp;
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 8, 4, 8),
        decoration: BoxDecoration(
          color: _wood.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _woodLight, width: 2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(color: Color(0xFFF2C94C), shape: BoxShape.circle),
              child: HeroAvatar(
                style: h.appearanceStyle,
                color: h.appearanceColor,
                skin: h.appearanceSkin,
                equipped: {for (final i in player.equipped) i.id},
                dye: dye,
                size: 48,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(h.name,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: _cream, fontWeight: FontWeight.w800, fontSize: 15)),
                      ),
                      const SizedBox(width: 8),
                      Text('Lv ${player.level}',
                          style: const TextStyle(
                              color: Color(0xFFF2C94C), fontWeight: FontWeight.w800, fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Semantics(
                    label: 'Experience: $xpNow of ${player.levelSizeXp} to the next level',
                    child: ExcludeSemantics(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: player.levelSizeXp == 0 ? 0 : xpNow / player.levelSizeXp,
                          minHeight: 9,
                          color: const Color(0xFFF2C94C),
                          backgroundColor: const Color(0xFF2B1A0E),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 10,
                    children: [
                      _Stat(Icons.bolt, '${player.energy}', const Color(0xFF5AD1C4), 'Adventure energy: ${player.energy}'),
                      _Stat(Icons.monetization_on, '${h.coins}', const Color(0xFFF2C94C), '${h.coins} coins'),
                      _Stat(Icons.calendar_today, '$goalDone/$goalTarget', const Color(0xFFFFB067), 'Active days this week: $goalDone of $goalTarget'),
                      if (streak > 0)
                        _Stat(Icons.local_fire_department_rounded, '$streak', const Color(0xFFFF7043), 'Streak: $streak active days in a row'),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Settings',
              onPressed: onSettings,
              icon: const Icon(Icons.settings, color: _cream),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.icon, this.text, this.color, this.semantics);

  final IconData icon;
  final String text;
  final Color color;
  final String semantics;

  @override
  Widget build(BuildContext context) => Semantics(
        label: semantics,
        child: ExcludeSemantics(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 3),
              Text(text,
                  style: const TextStyle(
                      color: _cream, fontWeight: FontWeight.w700, fontSize: 13)),
            ],
          ),
        ),
      );
}

class _MenuBar extends StatelessWidget {
  const _MenuBar({
    required this.canAdventure,
    required this.questPending,
    required this.onTap,
    this.vertical = false,
  });

  /// A rail down the side (for a phone held sideways) instead of a bar along the bottom.
  final bool vertical;
  final bool canAdventure;
  final bool questPending;
  final void Function(HubTarget) onTap;

  @override
  Widget build(BuildContext context) {
    final buttons = [
      _MenuButton(Icons.fitness_center, 'Train', () => onTap(HubTarget.train)),
      _MenuButton(Icons.flag, 'Quests', () => onTap(HubTarget.quests), badge: questPending),
      _MenuButton(Icons.explore, 'Adventure', () => onTap(HubTarget.adventure), highlight: canAdventure),
      _MenuButton(Icons.person, 'Hero', () => onTap(HubTarget.hero)),
      _MenuButton(Icons.menu_book, 'Journal', () => onTap(HubTarget.journal)),
    ];
    return Padding(
      padding: vertical ? const EdgeInsets.fromLTRB(0, 8, 8, 8) : const EdgeInsets.fromLTRB(10, 0, 10, 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          color: _wood.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _woodLight, width: 2),
        ),
        child: vertical ? Column(children: buttons) : Row(children: buttons),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  const _MenuButton(this.icon, this.label, this.onTap, {this.badge = false, this.highlight = false});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool badge;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        button: true,
        label: label,
        child: ExcludeSemantics(
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Container(
              constraints: const BoxConstraints(minHeight: 56),
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: highlight ? const Color(0xFF1F7A70) : _woodLight.withValues(alpha: 0.55),
                border: highlight ? Border.all(color: const Color(0xFF5AD1C4), width: 2) : null,
              ),
              // Shrinks a little rather than overflowing, at large text or on a short rail.
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(icon, color: _cream, size: 24),
                      if (badge)
                        Positioned(
                          right: -4,
                          top: -3,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5A623),
                              shape: BoxShape.circle,
                              border: Border.all(color: _wood, width: 1.5),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(label,
                      style: const TextStyle(
                          color: _cream, fontSize: 11, fontWeight: FontWeight.w700)),
                ],
              ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
