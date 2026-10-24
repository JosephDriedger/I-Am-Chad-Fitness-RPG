import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/feedback.dart';
import '../../app/game_ui.dart';
import '../../app/providers.dart';
import '../../app/store.dart';
import '../../app/widgets.dart';
import '../../domain/cosmetics.dart';
import '../../domain/patronage.dart';
import '../../game/art/painters.dart';
import '../../game/core.dart' show Haptic, Sfx;
import '../../game/look.dart';

/// The Patron's Hall: the one calm place where the optional, cosmetic-only
/// purchases live. It is reached from Settings. Nothing in the game points
/// here, interrupts the player with it, or counts down. See
/// docs/MONETIZATION.md.
class PatronScreen extends ConsumerStatefulWidget {
  const PatronScreen({super.key});

  @override
  ConsumerState<PatronScreen> createState() => _PatronScreenState();
}

class _PatronScreenState extends ConsumerState<PatronScreen> {
  String _line = PatronDialogue.welcome;
  late int _seenSerial;

  @override
  void initState() {
    super.initState();
    // A notice from before this screen opened is old news.
    _seenSerial = ref.read(storeProvider).noticeSerial;
    Future.microtask(() {
      if (mounted) ref.read(storeProvider.notifier).refresh();
    });
  }

  void _onNotice(StoreState s) {
    if (s.noticeSerial == _seenSerial) return;
    _seenSerial = s.noticeSerial;
    final line = switch (s.notice) {
      StoreNotice.thanksPack => PatronDialogue.thanksPack,
      StoreNotice.thanksTip => PatronDialogue.thanksTip,
      StoreNotice.restored => PatronDialogue.restored,
      StoreNotice.nothingToRestore => PatronDialogue.nothingToRestore,
      StoreNotice.cancelled => PatronDialogue.cancelled,
      StoreNotice.pending => PatronDialogue.pending,
      StoreNotice.failed => PatronDialogue.failed,
      StoreNotice.none => null,
    };
    if (line == null) return;
    setState(() => _line = line);
    if (s.notice == StoreNotice.thanksPack || s.notice == StoreNotice.thanksTip || s.notice == StoreNotice.restored) {
      final fx = ref.read(feedbackProvider);
      fx.sfx(Sfx.levelUp);
      fx.haptic(Haptic.medium);
    }
  }

  Future<void> _confirmAndBuy(StoreProduct product, String price) async {
    final owned = product.isTip ? false : ref.read(entitlementsProvider).value?.hasPatronPack ?? false;
    if (owned) {
      setState(() => _line = PatronDialogue.alreadyOwned);
      return;
    }
    final test = ref.read(storeGatewayProvider).isTestStore;
    final ok = await showGameDialog<bool>(
      context: context,
      title: product.isTip ? 'Say Thanks?' : 'Get the Patron Pack?',
      content: Text(
        '${product.name} · $price\n\n'
        '${product.isTip ? PatronAdvice.tipTerms : PatronAdvice.packTerms}'
        '${test ? '\n\nThis is a test store, so no real money is used.' : ''}',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      actions: [
        Builder(
          builder: (ctx) => GameButton(
            label: 'Continue',
            icon: Icons.favorite_rounded,
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
    await ref.read(storeProvider.notifier).buy(product);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(storeProvider, (_, next) => _onNotice(next));
    final store = ref.watch(storeProvider);
    final entitlements = ref.watch(entitlementsProvider).value ?? const Entitlements.none();
    final test = ref.watch(storeGatewayProvider).isTestStore;
    final unavailable = store.status == StoreStatus.unavailable;
    final loading = store.status == StoreStatus.idle || store.status == StoreStatus.loading;

    return GameScaffold(
      title: "Patron's Hall",
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
        children: [
          ChadBubble(text: unavailable ? PatronDialogue.unavailable : _line),
          if (test) ...[
            const SizedBox(height: 10),
            const GamePanel(
              color: Color(0xFFFFE9B0),
              child: Text(
                'Test store: prices are made up and no real money is used.',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
          const SizedBox(height: 16),
          const _Promise(),
          const SizedBox(height: 16),
          GamePanel(
            title: Patronage.patronPack.name,
            child: _PackCard(
              owned: entitlements.hasPatronPack,
              price: store.prices[Patronage.patronPackId],
              busy: store.busyProductId == Patronage.patronPackId,
              loading: loading,
              onBuy: store.busy || unavailable
                  ? null
                  : (price) => _confirmAndBuy(Patronage.patronPack, price),
            ),
          ),
          const SizedBox(height: 16),
          GamePanel(
            title: 'Say Thanks',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'A tip is only a thank-you. It never unlocks, unblocks or improves anything, '
                  'and not leaving one costs you nothing at all.',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                for (final tip in Patronage.tips)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _TipRow(
                      product: tip,
                      price: store.prices[tip.id],
                      busy: store.busyProductId == tip.id,
                      loading: loading,
                      onBuy: store.busy || unavailable ? null : (price) => _confirmAndBuy(tip, price),
                    ),
                  ),
                if (entitlements.tipCount > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      entitlements.tipCount == 1
                          ? 'You have said thanks once. Chad has not stopped smiling.'
                          : 'You have said thanks ${entitlements.tipCount} times. Chad has not stopped smiling.',
                      style: const TextStyle(color: GameColors.inkSoft, fontWeight: FontWeight.w700),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GameButton(
            label: store.restoring ? 'Looking...' : 'Restore Purchases',
            icon: Icons.restore_rounded,
            kind: GameButtonKind.secondary,
            onPressed: store.busy || unavailable
                ? null
                : () => ref.read(storeProvider.notifier).restore(),
          ),
          const SizedBox(height: 14),
          const Text(
            '${PatronDialogue.privacyNote}\n\n${PatronDialogue.parentNote}',
            style: TextStyle(color: GameColors.inkSoft, fontWeight: FontWeight.w600, height: 1.35),
          ),
        ],
      ),
    );
  }
}

/// Extra words for the confirmation dialogs.
class PatronAdvice {
  const PatronAdvice._();

  static const packTerms = 'One payment, yours for good. It adds looks only: three mantles, four hair dyes and '
      'some hall decorations. You will confirm the price again in the store.';
  static const tipTerms = 'A one-off thank-you that unlocks nothing. You will confirm the price again in the store.';
}

/// The promise, always first, so nobody has to wonder what money does.
class _Promise extends StatelessWidget {
  const _Promise();

  @override
  Widget build(BuildContext context) {
    return GamePanel(
      title: 'Our Promise',
      child: Semantics(
        container: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Everything in the game is free and always will be, with no ads and no tracking. '
              'Money here buys looks and thanks, never power. It will never buy:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            for (final item in Patronage.neverSold)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.block_rounded, size: 18, color: GameColors.redDark),
                    const SizedBox(width: 8),
                    Expanded(child: Text(item, style: const TextStyle(fontWeight: FontWeight.w700))),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PackCard extends ConsumerWidget {
  const _PackCard({
    required this.owned,
    required this.price,
    required this.busy,
    required this.loading,
    required this.onBuy,
  });

  final bool owned;
  final String? price;
  final bool busy;
  final bool loading;
  final void Function(String price)? onBuy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final base = ref.watch(heroLookProvider);
    final String label;
    if (owned) {
      label = 'Owned. Thank You!';
    } else if (busy) {
      label = 'Waiting for the Store...';
    } else if (price != null) {
      label = 'Get It · $price';
    } else {
      label = loading ? 'Asking the Store...' : 'Not Available Right Now';
    }
    final enabled = !owned && !busy && price != null && onBuy != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PackPreview(base: base ?? const HeroLook()),
        const SizedBox(height: 12),
        Text(Patronage.patronPack.blurb, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        for (final item in Cosmetics.patronPackContents)
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Row(
              children: [
                const Icon(Icons.check_rounded, size: 18, color: GameColors.greenDark),
                const SizedBox(width: 8),
                Expanded(child: Text(item, style: const TextStyle(fontWeight: FontWeight.w700))),
              ],
            ),
          ),
        const SizedBox(height: 12),
        GameButton(
          label: label,
          icon: owned ? Icons.favorite_rounded : Icons.shopping_bag_rounded,
          kind: owned ? GameButtonKind.secondary : GameButtonKind.positive,
          onPressed: enabled ? () => onBuy!(price!) : null,
        ),
      ],
    );
  }
}

class _TipRow extends StatelessWidget {
  const _TipRow({
    required this.product,
    required this.price,
    required this.busy,
    required this.loading,
    required this.onBuy,
  });

  final StoreProduct product;
  final String? price;
  final bool busy;
  final bool loading;
  final void Function(String price)? onBuy;

  @override
  Widget build(BuildContext context) {
    final enabled = !busy && price != null && onBuy != null;
    return Row(
      children: [
        const Icon(Icons.local_cafe_rounded, color: GameColors.goldDark),
        const SizedBox(width: 10),
        Expanded(child: Text(product.name, style: const TextStyle(fontWeight: FontWeight.w800))),
        const SizedBox(width: 8),
        GameButton(
          label: busy ? '...' : price ?? (loading ? '...' : 'N/A'),
          kind: GameButtonKind.primary,
          expanded: false,
          small: true,
          onPressed: enabled ? () => onBuy!(price!) : null,
        ),
      ],
    );
  }
}

/// The player's own hero wearing each of the pack's mantles and a hair dye, so
/// the pack can be judged before anything is bought.
class _PackPreview extends StatelessWidget {
  const _PackPreview({required this.base});

  final HeroLook base;

  @override
  Widget build(BuildContext context) {
    final patronCapes = [for (final c in Cosmetics.capes) if (c.unlock.isPatron) c];
    final patronDyes = [for (final d in Cosmetics.dyes) if (d.unlock.isPatron) d];
    return Semantics(
      label: 'Preview of your hero wearing the ${patronCapes.map((c) => c.name).join(', ')}.',
      image: true,
      child: ExcludeSemantics(
        child: Container(
          height: 130,
          decoration: BoxDecoration(
            color: GameColors.woodDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: GameColors.gold, width: 2),
          ),
          child: Row(
            children: [
              for (var i = 0; i < patronCapes.length; i++)
                Expanded(
                  child: CustomPaint(
                    painter: _HeroPreviewPainter(
                      HeroLook(
                        style: base.style,
                        color: base.color,
                        skin: base.skin,
                        cape: patronCapes[i],
                        dye: patronDyes[i % patronDyes.length],
                      ),
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroPreviewPainter extends CustomPainter {
  _HeroPreviewPainter(this.look);

  final HeroLook look;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.height / 84;
    canvas.save();
    canvas.translate(size.width / 2, size.height - 12);
    canvas.scale(scale, scale);
    paintHero(canvas, look, ActorState()..time = 0.4);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_HeroPreviewPainter old) => !old.look.sameAs(look);
}
