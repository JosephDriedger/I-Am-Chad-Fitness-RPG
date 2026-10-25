import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/feedback.dart';
import '../../app/game_ui.dart';
import '../../app/providers.dart';
import '../../app/widgets.dart';
import '../../domain/combat.dart' show FightingStyle;
import '../../domain/cosmetics.dart';
import '../../domain/hero.dart';
import '../../domain/items.dart';
import '../../domain/player_state.dart';
import '../../game/art/painters.dart';
import '../../game/battle_scene.dart' show paintItemIcon;
import '../../game/core.dart' show Haptic, Sfx;
import '../../game/look.dart';
import '../patron/wardrobe.dart';
import '../shop/shop_screen.dart';

/// The character sheet: your hero on a lit stage with equipment slots, stat
/// bars and a collection book of every piece of gear in the game.
class CharacterScreen extends ConsumerWidget {
  const CharacterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(playerProvider);
    final owned = ref.watch(itemsProvider).value ?? const <OwnedItem>[];
    if (player == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final h = player.hero;
    final ownedIds = {for (final o in owned) o.itemId: o};
    final look = ref.watch(heroLookProvider) ??
        HeroLook(
          style: h.appearanceStyle,
          color: h.appearanceColor,
          skin: h.appearanceSkin,
          equipped: {for (final i in player.equipped) i.id},
        );
    EquipmentItem? worn(EquipmentSlot s) {
      for (final i in player.equipped) {
        if (i.slot == s) return i;
      }
      return null;
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
      children: [
        _Stage(
          look: look,
          left: [
            _Slot(slot: EquipmentSlot.head, item: worn(EquipmentSlot.head), owned: ownedIds),
            _Slot(slot: EquipmentSlot.body, item: worn(EquipmentSlot.body), owned: ownedIds),
          ],
          right: [
            _Slot(slot: EquipmentSlot.weapon, item: worn(EquipmentSlot.weapon), owned: ownedIds),
            _Slot(slot: EquipmentSlot.trinket, item: worn(EquipmentSlot.trinket), owned: ownedIds),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: Text(h.name, style: gameTitle(32), maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(width: 8),
            // Flexible, so the badge shrinks rather than overflowing when the
            // player has set a very large text size.
            Flexible(flex: 2, child: _LevelBadge(level: player.level)),
          ],
        ),
        const SizedBox(height: 8),
        _BigBar(
          label: 'XP to Level ${player.level + 1}',
          value: player.totalXp - player.levelStartXp,
          max: player.levelSizeXp,
          color: GameColors.gold,
          icon: Icons.star_rounded,
        ),
        const SizedBox(height: 14),
        GamePanel(
          title: 'Stats',
          child: Column(
            children: [
              _StatLine(icon: Icons.favorite, label: 'Health', value: player.maxHp, cap: Progression.maxHp(Progression.maxLevel) + 20, color: GameColors.red),
              const SizedBox(height: 10),
              _StatLine(icon: Icons.flash_on, label: 'Attack', value: player.attack, cap: Progression.attack(Progression.maxLevel) + 6, color: GameColors.gold),
              const SizedBox(height: 10),
              _StatLine(icon: Icons.shield, label: 'Defense', value: player.defense, cap: Progression.defense(Progression.maxLevel) + 6, color: GameColors.blue),
              const SizedBox(height: 12),
              const Text(
                'Stat growth slows as you level, so there is no runaway power. Tactics matter more than level.',
                style: TextStyle(color: GameColors.inkSoft, fontSize: 12.5, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        GamePanel(
          title: 'Records',
          child: Column(
            children: [
              _Record('Total XP', '${player.totalXp}'),
              _Record('  From Workouts', '${player.activityXp}'),
              _Record('  From Adventures', '${h.adventureXp}'),
              _Record('  From Streaks', '${h.streakXp}'),
              _Record('Coins', '${h.coins}'),
              _Record('Expeditions Won', '${h.victories}'),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _StylePanel(current: h.style),
        const SizedBox(height: 14),
        GameButton(
          label: 'Visit the Guild Shop',
          icon: Icons.storefront_rounded,
          kind: GameButtonKind.secondary,
          onPressed: () => Navigator.of(context).push(gameRoute<void>(const ShopScreen())),
        ),
        const SizedBox(height: 14),
        GamePanel(
          title: 'Collection  ${ownedIds.length}/${ItemCatalog.all.length}',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Win expeditions or visit the Guild Shop to fill the collection. Tap one you own to wear it.',
                style: TextStyle(color: GameColors.inkSoft, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              LayoutBuilder(builder: (context, box) {
                final w = (box.maxWidth - 3 * 10) / 4;
                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final item in ItemCatalog.all)
                      SizedBox(
                        width: w,
                        child: _CollectionTile(
                          item: item,
                          owned: ownedIds[item.id],
                        ),
                      ),
                  ],
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GameButton(
          label: 'Customise',
          icon: Icons.brush,
          kind: GameButtonKind.secondary,
          onPressed: () => _customise(context, ref, player),
        ),
      ],
    );
  }

  /// The dye the preview should show: the pick, if the player has it.
  HairDye? _pickedDye(WidgetRef ref, String id) {
    final ctx = ref.read(cosmeticContextProvider);
    return ctx == null ? null : Cosmetics.wornDye(id, ctx);
  }

  Future<void> _customise(BuildContext context, WidgetRef ref, PlayerStatus player) async {
    final name = TextEditingController(text: player.hero.name);
    var pickStyle = player.hero.appearanceStyle;
    var pickColor = player.hero.appearanceColor;
    var pickSkin = player.hero.appearanceSkin;
    var pickCape = player.hero.cape;
    var pickDye = player.hero.hairDye;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: GameColors.parchment,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        side: BorderSide(color: GameColors.wood, width: 3),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.of(ctx).viewInsets.bottom + 16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: HeroAvatar(
                    style: pickStyle,
                    color: pickColor,
                    skin: pickSkin,
                    dye: _pickedDye(ref, pickDye),
                    size: 80,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: name,
                  maxLength: 20,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                const SizedBox(height: 8),
                AppearancePicker(
                  style: pickStyle,
                  color: pickColor,
                  skin: pickSkin,
                  onChanged: ({int? style, int? color, int? skin}) => setState(() {
                    pickStyle = style ?? pickStyle;
                    pickColor = color ?? pickColor;
                    pickSkin = skin ?? pickSkin;
                  }),
                ),
                const SizedBox(height: 12),
                Wardrobe(
                  cape: pickCape,
                  dye: pickDye,
                  onChanged: ({String? cape, String? dye}) => setState(() {
                    pickCape = cape ?? pickCape;
                    pickDye = dye ?? pickDye;
                  }),
                ),
                const SizedBox(height: 16),
                GameButton(
                  label: 'Save',
                  icon: Icons.check_circle,
                  kind: GameButtonKind.positive,
                  onPressed: () async {
                    final n = name.text.trim();
                    await ref.read(repositoryProvider).updateHeroDetails(
                          name: n.isEmpty ? null : n,
                          appearanceStyle: pickStyle,
                          appearanceColor: pickColor,
                          appearanceSkin: pickSkin,
                          cape: pickCape,
                          hairDye: pickDye,
                        );
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
    name.dispose();
  }
}

// ---------------------------------------------------------------------------
// Stage and figure
// ---------------------------------------------------------------------------

class _Stage extends StatelessWidget {
  const _Stage({required this.look, required this.left, required this.right});

  final HeroLook look;
  final List<Widget> left;
  final List<Widget> right;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 270,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: GameColors.wood, width: 3),
        gradient: const RadialGradient(
          center: Alignment(0, 0.15),
          radius: 0.9,
          colors: [Color(0xFF8A5A33), Color(0xFF4A2F1A), Color(0xFF2B1A0E)],
        ),
        boxShadow: const [BoxShadow(color: Color(0x66000000), offset: Offset(0, 4))],
      ),
      child: Row(
        children: [
          const SizedBox(width: 10),
          Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: left),
          Expanded(child: _HeroFigure(look: look)),
          Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: right),
          const SizedBox(width: 10),
        ],
      ),
    );
  }
}

/// The hero, idling, drawn with the same art as the game scenes.
class _HeroFigure extends StatefulWidget {
  const _HeroFigure({required this.look});

  final HeroLook look;

  @override
  State<_HeroFigure> createState() => _HeroFigureState();
}

class _HeroFigureState extends State<_HeroFigure> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  double _hop = 0;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 120))..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _jump() async {
    for (var i = 0; i < 12; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 18));
      if (!mounted) return;
      setState(() => _hop = 22 * (i < 6 ? i / 6 : (12 - i) / 6));
    }
    if (mounted) setState(() => _hop = 0);
  }

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.of(context).disableAnimations;
    return Semantics(
      label: 'Your adventurer, shown wearing your equipped gear',
      image: true,
      child: GestureDetector(
        onTap: still ? null : _jump,
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) => CustomPaint(
            painter: _FigurePainter(widget.look, still ? 0 : _c.value * 120, _hop),
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
  }
}

class _FigurePainter extends CustomPainter {
  _FigurePainter(this.look, this.time, this.hop);

  final HeroLook look;
  final double time;
  final double hop;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.height / 92;
    canvas.save();
    canvas.translate(size.width / 2, size.height - 18);
    canvas.scale(scale, scale);
    // Ground glow.
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 2), width: 64, height: 12),
      Paint()..color = const Color(0x66000000),
    );
    canvas.translate(0, -hop);
    paintHero(canvas, look, ActorState()..time = time);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_FigurePainter old) => true;
}

// ---------------------------------------------------------------------------
// Slots and collection
// ---------------------------------------------------------------------------

class _Slot extends ConsumerWidget {
  const _Slot({required this.slot, required this.item, required this.owned});

  final EquipmentSlot slot;
  final EquipmentItem? item;
  final Map<String, OwnedItem> owned;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final have = ItemCatalog.all.where((i) => i.slot == slot && owned.containsKey(i.id)).toList();
    return Semantics(
      button: true,
      label: item == null ? '${slot.label} slot, empty' : '${slot.label} slot, wearing ${item!.name}',
      child: ExcludeSemantics(
        child: GestureDetector(
          onTap: () {
            final fx = ref.read(feedbackProvider);
            fx.sfx(Sfx.tap);
            fx.haptic(Haptic.light);
            _openPicker(context, ref, have);
          },
          child: SizedBox(
            width: 74,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 66,
                  height: 66,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2B1A0E),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: item == null ? GameColors.woodLight : GameColors.gold, width: 2.5),
                  ),
                  child: CustomPaint(painter: _ItemIconPainter(slot, filled: item != null)),
                ),
                const SizedBox(height: 4),
                Text(
                  item?.name ?? slot.label,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: item == null ? const Color(0xFFBFA680) : GameColors.cream,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    height: 1.05,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openPicker(BuildContext context, WidgetRef ref, List<EquipmentItem> have) {
    showGameDialog<void>(
      context: context,
      title: '${slot.label} Slot',
      content: have.isEmpty
          ? const Text('Nothing to wear here yet. Win expeditions or visit the Guild Shop to get gear.')
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final i in have)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2B1A0E),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: CustomPaint(painter: _ItemIconPainter(i.slot, filled: true)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(i.name, style: gameTitle(17)),
                              Text(i.bonusLabel, style: const TextStyle(fontWeight: FontWeight.w700, color: GameColors.goldDark)),
                              Text(i.description, style: const TextStyle(fontSize: 12.5, color: GameColors.inkSoft)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        GameButton(
                          label: owned[i.id]!.equipped ? 'Remove' : 'Wear',
                          kind: owned[i.id]!.equipped ? GameButtonKind.secondary : GameButtonKind.positive,
                          expanded: false,
                          small: true,
                          onPressed: () {
                            ref.read(repositoryProvider).setEquipped(i.id, !owned[i.id]!.equipped);
                            Navigator.of(context, rootNavigator: true).pop();
                          },
                        ),
                      ],
                    ),
                  ),
              ],
            ),
      actions: [
        Builder(
          builder: (ctx) => GameButton(label: 'Close', kind: GameButtonKind.secondary, onPressed: () => Navigator.of(ctx).pop()),
        ),
      ],
    );
  }
}

class _ItemIconPainter extends CustomPainter {
  _ItemIconPainter(this.slot, {required this.filled});

  final EquipmentSlot slot;
  final bool filled;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    final s = size.shortestSide / 30;
    canvas.scale(s, s);
    if (filled) {
      paintItemIcon(canvas, slot, 0);
    } else {
      // Silhouette: the same icon, shadowed.
      canvas.saveLayer(const Rect.fromLTWH(-30, -30, 60, 60), Paint());
      paintItemIcon(canvas, slot, 0);
      canvas.drawRect(
        const Rect.fromLTWH(-30, -30, 60, 60),
        Paint()
          ..blendMode = BlendMode.srcATop
          ..color = const Color(0xCC1A0F06),
      );
      canvas.restore();
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ItemIconPainter old) => old.slot != slot || old.filled != filled;
}

class _CollectionTile extends ConsumerWidget {
  const _CollectionTile({required this.item, required this.owned});

  final EquipmentItem item;
  final OwnedItem? owned;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final have = owned != null;
    final worn = owned?.equipped ?? false;
    return Semantics(
      button: have,
      label: have ? '${item.name}, ${item.bonusLabel}${worn ? ', worn' : ''}' : 'Undiscovered ${item.slot.label} item',
      child: ExcludeSemantics(
        child: GestureDetector(
          onTap: have
              ? () {
                  final fx = ref.read(feedbackProvider);
                  fx.sfx(Sfx.tap);
                  fx.haptic(Haptic.light);
                  ref.read(repositoryProvider).setEquipped(item.id, !worn);
                }
              : null,
          child: Column(
            children: [
              Container(
                height: 60,
                decoration: BoxDecoration(
                  color: have ? const Color(0xFF2B1A0E) : const Color(0xFF4A3A2C),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: worn ? GameColors.gold : GameColors.woodLight, width: worn ? 3 : 1.5),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(child: CustomPaint(painter: _ItemIconPainter(item.slot, filled: have))),
                    if (!have)
                      const Center(child: Text('?', style: TextStyle(color: Color(0xFFBFA680), fontSize: 24, fontWeight: FontWeight.w900))),
                    if (worn)
                      const Positioned(top: 2, right: 2, child: Icon(Icons.check_circle, color: GameColors.gold, size: 16)),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                have ? item.name : 'Unknown',
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  height: 1.05,
                  fontWeight: FontWeight.w800,
                  color: have ? GameColors.ink : GameColors.inkSoft,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bars and rows
// ---------------------------------------------------------------------------

/// The three ways to fight. A free choice, changed any time, that never adds power:
/// it only shifts how focus is built and spent.
class _StylePanel extends ConsumerWidget {
  const _StylePanel({required this.current});

  final FightingStyle current;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GamePanel(
      title: 'Fighting Style',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'A free choice you can change any time. No style is stronger than another; each just plays a little differently.',
            style: TextStyle(color: GameColors.inkSoft, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          for (final s in FightingStyle.values)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Semantics(
                button: true,
                selected: s == current,
                label: '${s.label}. ${s.blurb}${s == current ? ' Chosen.' : ''}',
                child: ExcludeSemantics(
                  child: InkWell(
                    key: Key('style_${s.id}'),
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      ref.read(feedbackProvider).haptic(Haptic.select);
                      ref.read(repositoryProvider).setFightingStyle(s.id);
                    },
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 56),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: s == current ? GameColors.cream : GameColors.parchment,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: s == current ? GameColors.gold : GameColors.parchmentDark, width: 3),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            s == current ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
                            color: s == current ? GameColors.goldDark : GameColors.inkSoft,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(s.label, style: gameTitle(18)),
                                const SizedBox(height: 2),
                                Text(s.blurb, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LevelBadge extends StatelessWidget {
  const _LevelBadge({required this.level});

  final int level;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Level $level',
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: GameColors.woodDark,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: GameColors.gold, width: 3),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text('Level $level', style: gameTitle(20, color: GameColors.gold)),
          ),
        ),
      ),
    );
  }
}

class _BigBar extends StatelessWidget {
  const _BigBar({required this.label, required this.value, required this.max, required this.color, required this.icon});

  final String label;
  final int value;
  final int max;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final frac = max <= 0 ? 0.0 : (value / max).clamp(0.0, 1.0);
    return Semantics(
      label: '$label: $value of $max',
      child: ExcludeSemantics(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              height: 26,
              decoration: BoxDecoration(
                color: GameColors.woodDark,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: GameColors.wood, width: 2.5),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: frac,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color.lerp(color, Colors.white, 0.35)!, color],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Text(
              '$label   $value / $max',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w900,
                shadows: [Shadow(color: Colors.black87, blurRadius: 2)],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatLine extends StatelessWidget {
  const _StatLine({required this.icon, required this.label, required this.value, required this.cap, required this.color});

  final IconData icon;
  final String label;
  final int value;
  final int cap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final frac = (value / cap).clamp(0.0, 1.0);
    return Semantics(
      label: '$label $value',
      child: ExcludeSemantics(
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 8),
            SizedBox(width: 70, child: Text(label, style: gameTitle(16))),
            Expanded(
              child: Container(
                height: 14,
                decoration: BoxDecoration(
                  color: GameColors.woodDark,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: frac,
                    child: Container(decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(7))),
                  ),
                ),
              ),
            ),
            SizedBox(width: 44, child: Text('$value', textAlign: TextAlign.right, style: gameTitle(20))),
          ],
        ),
      ),
    );
  }
}

class _Record extends StatelessWidget {
  const _Record(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      // Both sides may wrap, so a long label or a large text size cannot push
      // the value off the edge of the screen.
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700))),
          const SizedBox(width: 12),
          Expanded(child: Text(value, textAlign: TextAlign.end, style: gameTitle(18))),
        ],
      ),
    );
  }
}
