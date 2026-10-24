import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/feedback.dart';
import '../../app/game_ui.dart';
import '../../app/providers.dart';
import '../../app/widgets.dart';
import '../../domain/items.dart';
import '../../domain/player_state.dart';
import '../../domain/shop.dart';
import '../../game/battle_scene.dart' show paintItemIcon;
import '../../game/core.dart' show Haptic, Sfx;

/// The Guild Shop: gear and healing potions, paid for with coins.
class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key});

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> {
  String _line = 'Welcome to the guild shop! Everything is priced in coins you earned. '
      'Nothing here is random, and nothing costs real money.';

  void _say(String text) => setState(() => _line = text);

  Future<void> _buyItem(EquipmentItem item) async {
    final price = Shop.priceOf(item.id)!;
    final ok = await showGameDialog<bool>(
      context: context,
      title: 'Buy ${item.name}?',
      content: Text(
        '$price coins. It goes into your collection, and you can wear it from the Hero screen.',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      actions: [
        Builder(
          builder: (ctx) => GameButton(
            label: 'Buy',
            icon: Icons.shopping_bag_rounded,
            kind: GameButtonKind.positive,
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ),
        Builder(
          builder: (ctx) => GameButton(
            label: 'Not Now',
            kind: GameButtonKind.secondary,
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
        ),
      ],
    );
    if (ok != true || !mounted) return;
    final result = await ref.read(repositoryProvider).buyItem(item.id);
    if (!mounted) return;
    _report(result, boughtLine: 'A fine choice! The ${item.name} is yours. Wear it from the Hero screen.');
  }

  Future<void> _buyPotion() async {
    final result = await ref.read(repositoryProvider).buyPotion();
    if (!mounted) return;
    _report(result, boughtLine: 'One healing potion, bottled this morning. It goes in your pouch.');
  }

  void _report(PurchaseResult result, {required String boughtLine}) {
    final fx = ref.read(feedbackProvider);
    switch (result) {
      case PurchaseResult.bought:
        fx.sfx(Sfx.coin);
        fx.haptic(Haptic.medium);
        _say(boughtLine);
      case PurchaseResult.notEnoughCoins:
        _say('A little short on coins. Expeditions and streak rewards will top you up.');
      case PurchaseResult.alreadyOwned:
        _say('You already have that one. Hero, you are well stocked.');
      case PurchaseResult.pouchFull:
        _say('Your pouch is full. Take some on an expedition first.');
      case PurchaseResult.unavailable:
        _say('Hmm, I cannot sell that right now.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final player = ref.watch(playerProvider);
    final owned = {for (final o in ref.watch(itemsProvider).value ?? const <OwnedItem>[]) o.itemId};
    if (player == null) {
      return const GameScaffold(title: 'Guild Shop', child: Center(child: CircularProgressIndicator()));
    }
    final coins = player.hero.coins;
    final stock = player.hero.potionStock;

    return GameScaffold(
      title: 'Guild Shop',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
        children: [
          Row(
            children: [
              Expanded(child: Text('Your Coins', style: gameTitle(24))),
              GameChip(text: '$coins Coins', icon: Icons.monetization_on, color: GameColors.gold),
            ],
          ),
          const SizedBox(height: 10),
          ChadBubble(text: _line),
          const SizedBox(height: 16),
          GamePanel(
            title: 'Supplies',
            child: _Offer(
              icon: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFDDF3E1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: GameColors.green, width: 2.5),
                ),
                child: const Icon(Icons.local_drink, color: GameColors.green, size: 30),
              ),
              name: 'Healing Potion',
              detail: 'Heals you in battle. Your pouch holds $stock of ${Shop.potionPouchMax}. '
                  'Up to ${Shop.maxPotionsBrought} come along on each expedition, '
                  'and any you do not use come home again.',
              price: Shop.potionPrice,
              coins: coins,
              disabledLabel: stock >= Shop.potionPouchMax ? 'Pouch Full' : null,
              onBuy: _buyPotion,
            ),
          ),
          const SizedBox(height: 16),
          GamePanel(
            title: 'Outfitter',
            child: Column(
              children: [
                for (final item in Shop.gear)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _Offer(
                      icon: SizedBox(
                        width: 52,
                        height: 52,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: GameColors.woodDark,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: GameColors.gold, width: 2),
                          ),
                          child: CustomPaint(painter: _GearIconPainter(item.slot)),
                        ),
                      ),
                      name: item.name,
                      detail: '${item.slot.label}  ·  ${item.bonusLabel}\n${item.description}',
                      price: Shop.priceOf(item.id)!,
                      coins: coins,
                      disabledLabel: owned.contains(item.id) ? 'Owned' : null,
                      onBuy: () => _buyItem(item),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Coins come from expeditions and streak rewards. Gear also drops from expeditions, '
            'and a duplicate drop pays coins back.',
            style: TextStyle(color: GameColors.inkSoft, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/// One thing for sale: an icon, what it is, and a button to buy it.
class _Offer extends StatelessWidget {
  const _Offer({
    required this.icon,
    required this.name,
    required this.detail,
    required this.price,
    required this.coins,
    required this.onBuy,
    this.disabledLabel,
  });

  final Widget icon;
  final String name;
  final String detail;
  final int price;
  final int coins;
  final VoidCallback onBuy;

  /// Why it cannot be bought ("Owned", "Pouch Full"), or null if it can.
  final String? disabledLabel;

  @override
  Widget build(BuildContext context) {
    final short = coins < price;
    final canBuy = disabledLabel == null && !short;
    final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    final words = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(name, style: gameTitle(18)),
        const SizedBox(height: 2),
        Text(detail, style: const TextStyle(color: GameColors.inkSoft, fontWeight: FontWeight.w600, fontSize: 13)),
        if (disabledLabel == null && short)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text('Need ${price - coins} more coins',
                style: const TextStyle(color: GameColors.goldDark, fontWeight: FontWeight.w800, fontSize: 13)),
          ),
      ],
    );
    GameButton buttonFor(bool stacked) => GameButton(
          label: disabledLabel ?? '$price Coins',
          icon: disabledLabel == null ? Icons.monetization_on : null,
          kind: GameButtonKind.primary,
          expanded: stacked,
          small: true,
          onPressed: canBuy ? onBuy : null,
        );
    return Semantics(
      container: true,
      label: '$name. $detail. ${disabledLabel ?? '$price coins${short ? ', you need ${price - coins} more' : ''}'}.',
      child: ExcludeSemantics(
        // With large text, or on a narrow screen, the button no longer fits
        // beside the words, so it moves underneath them instead of pushing off
        // the edge of the screen.
        child: LayoutBuilder(
          builder: (context, box) {
            final stacked = largeText || box.maxWidth < 290;
            final button = buttonFor(stacked);
            return stacked
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [icon, const SizedBox(width: 12), Expanded(child: words)],
                      ),
                      const SizedBox(height: 8),
                      button,
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [icon, const SizedBox(width: 12), Expanded(child: words), const SizedBox(width: 8), button],
                  );
          },
        ),
      ),
    );
  }
}

class _GearIconPainter extends CustomPainter {
  _GearIconPainter(this.slot);

  final EquipmentSlot slot;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    final s = size.shortestSide / 30;
    canvas.scale(s, s);
    paintItemIcon(canvas, slot, 0);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_GearIconPainter old) => old.slot != slot;
}
