/// What real money can and cannot buy. This file is the whole list.
///
/// The game is free and complete. Every exercise, expedition, story chapter,
/// reward and piece of gear is available to everyone, forever, with no ads,
/// no account and no tracking. Players who want to support the game can buy
/// one optional cosmetic pack, or leave a tip that is only a thank-you.
///
/// The rules, which `test/domain/patronage_test.dart` enforces:
///
/// * Nothing here changes XP, energy, coins, potions, damage, health, loot,
///   streaks or story. Money never makes the game easier to win, and exercise
///   is still the only source of adventure energy.
/// * Everything is a one-time purchase. No subscriptions, no consumable
///   currencies, no random rewards, no timers or limited-time offers.
/// * Prices come from the store at the moment of purchase, so they are never
///   hard-coded here and always match what the player is charged.
/// * A purchase can always be restored from the player's store account.
///
/// See docs/MONETIZATION.md for the reasoning and the store set-up.
library;

enum ProductKind {
  /// Bought once and owned for good; restorable from the store account.
  cosmeticPack,

  /// A thank-you. Bought as often as the player likes; unlocks nothing.
  tip,
}

class StoreProduct {
  const StoreProduct({
    required this.id,
    required this.kind,
    required this.name,
    required this.blurb,
  });

  /// The product id registered in Google Play Console and App Store Connect.
  /// Never rename: the stores and saved receipts both use it.
  final String id;
  final ProductKind kind;
  final String name;
  final String blurb;

  bool get isTip => kind == ProductKind.tip;
}

class Patronage {
  const Patronage._();

  static const patronPackId = 'patron_pack';

  static const patronPack = StoreProduct(
    id: patronPackId,
    kind: ProductKind.cosmeticPack,
    name: 'Patron Pack',
    blurb: 'Three mantles, four hair dyes and a brighter guild hall: string lights, '
        'a potted lantern tree and a patron rosette on the banner. '
        'Looks only. It changes nothing about how the game plays.',
  );

  static const tipSmall = StoreProduct(
    id: 'tip_shake',
    kind: ProductKind.tip,
    name: 'A Protein Shake for Chad',
    blurb: 'A small thank-you.',
  );

  static const tipMedium = StoreProduct(
    id: 'tip_lunch',
    kind: ProductKind.tip,
    name: 'A Hearty Lunch for Chad',
    blurb: 'A bigger thank-you.',
  );

  static const tipLarge = StoreProduct(
    id: 'tip_banquet',
    kind: ProductKind.tip,
    name: 'A Banquet for the Guild',
    blurb: 'A very big thank-you.',
  );

  static const tips = <StoreProduct>[tipSmall, tipMedium, tipLarge];

  /// Everything the stores are asked about, in the order it is shown.
  static const all = <StoreProduct>[patronPack, ...tips];

  static final Map<String, StoreProduct> _byId = {for (final p in all) p.id: p};

  static StoreProduct? byId(String id) => _byId[id];

  /// What tips and the pack give back besides the thank-you. Kept as words so
  /// the screen and the tests read the same promise.
  static const tipPerk = 'Tips unlock nothing. They are only a thank-you.';

  /// Things money will never buy. Shown on the Patron's Hall screen.
  static const neverSold = <String>[
    'XP, energy, coins or potions',
    'Gear, damage, health or any advantage in battle',
    'Story chapters, exercises or any part of the core game',
    'Random rewards, loot boxes or timed offers',
  ];
}

/// Chad's words in the Patron's Hall. Warm, never pushy: no urgency, no guilt
/// for not buying, no talk of what a purchase "unlocks" beyond looks. The
/// tests lint these like the rest of Chad's dialogue.
class PatronDialogue {
  const PatronDialogue._();

  static const welcome = 'This game is free, and it stays free. No ads, no account, nothing watching you. '
      'If you want to support it, here are two optional ways. Nobody has to, and nothing here makes you stronger.';

  static const thanksPack = 'Now that is generous! Your mantles and dyes are ready, and the hall just got a lot '
      'brighter. Thank you, hero. Truly.';

  static const thanksTip = 'A thank-you from you, to me! I have a lump in my throat, and it is not the protein. '
      'It changes nothing in the game, which makes it even kinder.';

  static const restored = 'Welcome back! Everything you had is restored.';

  static const nothingToRestore = 'I looked everywhere, but there is nothing to restore on this store account. '
      'No harm done.';

  static const cancelled = 'No problem at all. Nothing was bought.';

  static const pending = 'The store is still working on it. It will show up here once it is approved.';

  static const failed = 'The store could not finish that. Nothing is lost on this end, and you can try again '
      'whenever you like.';

  static const unavailable = 'The store cannot be reached right now, maybe because you are offline. '
      'The whole game still works, and this will be here when you are back.';

  static const alreadyOwned = 'You already have the Patron Pack. Thank you again, truly.';

  static const parentNote = 'Purchases go through Google Play or the App Store, so any parental controls you have '
      'set there apply. If you are under 18, please ask a grown-up first. Refunds are handled by the store.';

  static const privacyNote = 'The store handles the payment. This game never sees your card, name or address, '
      'and sends nothing anywhere.';

  static const all = <String>[
    welcome,
    thanksPack,
    thanksTip,
    restored,
    nothingToRestore,
    cancelled,
    pending,
    failed,
    unavailable,
    alreadyOwned,
    parentNote,
    privacyNote,
  ];
}

/// What the player owns, worked out from saved purchase receipts.
class Entitlements {
  const Entitlements({this.ownedPacks = const {}, this.tipCount = 0});

  const Entitlements.none() : this();

  /// Ids of one-time packs the player owns.
  final Set<String> ownedPacks;

  /// How many tips the player has given, so Chad can say thank you. It is a
  /// count of kind gestures, never a score, rank or perk.
  final int tipCount;

  bool get hasPatronPack => ownedPacks.contains(Patronage.patronPackId);

  /// Builds entitlements from the stored receipts, ignoring unknown products.
  /// Each receipt is `(key, productId)`; a pack counts once however many
  /// times it was restored, and each tip receipt counts once.
  factory Entitlements.fromReceipts(Iterable<({String key, String productId})> receipts) {
    final packs = <String>{};
    final tipKeys = <String>{};
    for (final r in receipts) {
      final product = Patronage.byId(r.productId);
      if (product == null) continue;
      if (product.isTip) {
        tipKeys.add(r.key);
      } else {
        packs.add(product.id);
      }
    }
    return Entitlements(ownedPacks: packs, tipCount: tipKeys.length);
  }

  /// The receipt key under which a purchase is stored. Packs are keyed by
  /// product, so restoring one again can never create a second copy. Tips are
  /// keyed by the store's transaction id, so a delivery repeated by the store
  /// can never count twice.
  static String receiptKey(StoreProduct product, String transactionId) =>
      product.isTip ? 'tip:$transactionId' : product.id;
}
