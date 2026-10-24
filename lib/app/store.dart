/// The only code that talks to the app store, plus the controller that turns a
/// finished purchase into saved cosmetics. The rules about what may be sold
/// live in `domain/patronage.dart`; this file just moves money through the
/// platform's own checkout. The app never sees a card, an address or a name.
///
/// Prices are never stored in the app: the store reports them in the player's
/// own currency and the screen shows exactly that.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../domain/patronage.dart';
import 'providers.dart';

// ---------------------------------------------------------------------------
// Gateway: the platform store behind a small interface
// ---------------------------------------------------------------------------

sealed class StoreEvent {
  const StoreEvent();
}

/// A purchase the store says is complete (or restored).
class StorePurchased extends StoreEvent {
  const StorePurchased({
    required this.productId,
    required this.transactionId,
    required this.restored,
    required this.confirm,
  });

  final String productId;

  /// Unique per purchase, so a delivery the store repeats is not counted twice.
  final String transactionId;
  final bool restored;

  /// Tells the store the purchase was delivered. Call it only after the
  /// purchase is saved: until then the store keeps it and will deliver it
  /// again, and an unconfirmed purchase is refunded automatically.
  final Future<void> Function() confirm;
}

/// The store is still working on it (for example a parent has to approve).
class StorePending extends StoreEvent {
  const StorePending(this.productId);
  final String productId;
}

class StoreCancelled extends StoreEvent {
  const StoreCancelled(this.productId);
  final String? productId;
}

class StoreProblem extends StoreEvent {
  const StoreProblem(this.message, {this.productId});
  final String message;
  final String? productId;
}

abstract class StoreGateway {
  /// Purchase updates. Listening starts the platform store, so the app listens
  /// from launch to receive any purchase that finished while it was closed.
  Stream<StoreEvent> get events;

  /// Localised price strings by product id, or null if the store cannot be
  /// reached (no network, no Play or App Store, a desktop build).
  Future<Map<String, String>?> loadPrices(Set<String> ids);

  /// Opens the platform's own checkout for [product]. The result arrives on
  /// [events].
  Future<void> buy(StoreProduct product);

  /// Asks the store to re-deliver one-time purchases made on this account.
  Future<void> restore();

  /// How long to wait for restored purchases before saying there were none.
  Duration get restoreWait;

  /// True for the pretend store used in tests and the browser preview, so the
  /// screen can say plainly that no real money is involved.
  bool get isTestStore;

  void dispose();
}

/// The real store: Google Play Billing on Android, StoreKit on iOS.
class InAppPurchaseGateway implements StoreGateway {
  InAppPurchaseGateway() {
    _events = StreamController<StoreEvent>.broadcast(onListen: _start);
  }

  late final StreamController<StoreEvent> _events;
  StreamSubscription<List<PurchaseDetails>>? _sub;
  InAppPurchase? _iap;
  final Map<String, ProductDetails> _details = {};

  @override
  Stream<StoreEvent> get events => _events.stream;

  @override
  Duration get restoreWait => const Duration(seconds: 4);

  @override
  bool get isTestStore => false;

  void _start() {
    if (_sub != null) return;
    try {
      final iap = InAppPurchase.instance;
      _iap = iap;
      _sub = iap.purchaseStream.listen(
        _onUpdates,
        onError: (Object e) => _events.add(StoreProblem('$e')),
      );
    } catch (_) {
      _iap = null; // No store on this platform; prices will report unavailable.
    }
  }

  Future<void> _onUpdates(List<PurchaseDetails> updates) async {
    final iap = _iap;
    for (final d in updates) {
      Future<void> finish() async {
        if (d.pendingCompletePurchase && iap != null) await iap.completePurchase(d);
      }

      switch (d.status) {
        case PurchaseStatus.pending:
          _events.add(StorePending(d.productID));
        case PurchaseStatus.canceled:
          _events.add(StoreCancelled(d.productID));
          await finish();
        case PurchaseStatus.error:
          _events.add(StoreProblem(d.error?.message ?? 'The store could not finish that.', productId: d.productID));
          await finish();
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          _events.add(StorePurchased(
            productId: d.productID,
            transactionId: d.purchaseID ?? '${d.productID}@${d.transactionDate}',
            restored: d.status == PurchaseStatus.restored,
            confirm: finish,
          ));
      }
    }
  }

  @override
  Future<Map<String, String>?> loadPrices(Set<String> ids) async {
    _start();
    final iap = _iap;
    if (iap == null) return null;
    try {
      if (!await iap.isAvailable()) return null;
      final response = await iap.queryProductDetails(ids);
      if (response.error != null && response.productDetails.isEmpty) return null;
      _details
        ..clear()
        ..addEntries(response.productDetails.map((d) => MapEntry(d.id, d)));
      return {for (final d in response.productDetails) d.id: d.price};
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> buy(StoreProduct product) async {
    final iap = _iap;
    final details = _details[product.id];
    if (iap == null || details == null) {
      throw StateError('The store is not ready.');
    }
    final param = PurchaseParam(productDetails: details);
    if (product.isTip) {
      await iap.buyConsumable(purchaseParam: param);
    } else {
      await iap.buyNonConsumable(purchaseParam: param);
    }
  }

  @override
  Future<void> restore() async {
    _start();
    await _iap?.restorePurchases();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _events.close();
  }
}

/// A pretend store with made-up prices. It is used in tests and in the browser
/// preview (web is a development convenience, not a shipped platform), never
/// on a phone, and it says so on screen.
class TestStoreGateway implements StoreGateway {
  TestStoreGateway({this.available = true, this.owned = const {}});

  /// Whether the pretend store can be reached.
  bool available;

  /// One-time packs "already bought" on the pretend account, for restore.
  final Set<String> owned;

  /// What the next [buy] does: complete, cancel, fail, or stay pending.
  TestOutcome nextOutcome = TestOutcome.complete;

  /// Every product the screen asked to buy, for tests.
  final List<String> bought = [];

  final _events = StreamController<StoreEvent>.broadcast();
  var _serial = 0;

  /// Set when the last confirm() was called, so tests can check ordering.
  int confirmed = 0;

  @override
  Stream<StoreEvent> get events => _events.stream;

  @override
  Duration get restoreWait => Duration.zero;

  @override
  bool get isTestStore => true;

  @override
  Future<Map<String, String>?> loadPrices(Set<String> ids) async {
    if (!available) return null;
    const prices = {
      Patronage.patronPackId: r'$3.99',
      'tip_shake': r'$1.99',
      'tip_lunch': r'$4.99',
      'tip_banquet': r'$9.99',
    };
    return {for (final id in ids) if (prices.containsKey(id)) id: prices[id]!};
  }

  /// Delivers a purchase as the store would, for tests.
  void deliver(String productId, {bool restored = false, String? transactionId}) {
    _events.add(StorePurchased(
      productId: productId,
      transactionId: transactionId ?? 'test-${++_serial}',
      restored: restored,
      confirm: () async => confirmed++,
    ));
  }

  @override
  Future<void> buy(StoreProduct product) async {
    bought.add(product.id);
    switch (nextOutcome) {
      case TestOutcome.complete:
        deliver(product.id);
      case TestOutcome.cancel:
        _events.add(StoreCancelled(product.id));
      case TestOutcome.fail:
        _events.add(StoreProblem('The pretend store said no.', productId: product.id));
      case TestOutcome.pending:
        _events.add(StorePending(product.id));
    }
    nextOutcome = TestOutcome.complete;
  }

  @override
  Future<void> restore() async {
    for (final id in owned) {
      deliver(id, restored: true, transactionId: 'restored-$id');
    }
  }

  @override
  void dispose() => _events.close();
}

enum TestOutcome { complete, cancel, fail, pending }

/// The gateway the app uses. Tests override it with a [TestStoreGateway].
final storeGatewayProvider = Provider<StoreGateway>((ref) {
  final gateway = kIsWeb ? TestStoreGateway() : InAppPurchaseGateway();
  ref.onDispose(gateway.dispose);
  return gateway;
});

// ---------------------------------------------------------------------------
// Controller
// ---------------------------------------------------------------------------

enum StoreStatus { idle, loading, ready, unavailable }

/// What the Patron's Hall should tell the player right now.
enum StoreNotice {
  none,
  thanksPack,
  thanksTip,
  restored,
  nothingToRestore,
  cancelled,
  pending,
  failed,
}

class StoreState {
  const StoreState({
    this.status = StoreStatus.idle,
    this.prices = const {},
    this.busyProductId,
    this.restoring = false,
    this.notice = StoreNotice.none,
    this.noticeSerial = 0,
  });

  final StoreStatus status;

  /// Localised price text by product id, as the store reports it.
  final Map<String, String> prices;

  /// The product whose checkout is open, if any.
  final String? busyProductId;
  final bool restoring;
  final StoreNotice notice;

  /// Changes with every notice so the screen can react to a repeat.
  final int noticeSerial;

  bool get busy => busyProductId != null || restoring;

  StoreState copyWith({
    StoreStatus? status,
    Map<String, String>? prices,
    Object? busyProductId = _keep,
    bool? restoring,
    StoreNotice? notice,
  }) =>
      StoreState(
        status: status ?? this.status,
        prices: prices ?? this.prices,
        busyProductId: identical(busyProductId, _keep) ? this.busyProductId : busyProductId as String?,
        restoring: restoring ?? this.restoring,
        notice: notice ?? this.notice,
        noticeSerial: notice == null ? noticeSerial : noticeSerial + 1,
      );
}

const Object _keep = Object();

class StoreController extends Notifier<StoreState> {
  var _restoredDuringRestore = 0;

  @override
  StoreState build() {
    final gateway = ref.watch(storeGatewayProvider);
    final sub = gateway.events.listen(_onEvent);
    ref.onDispose(sub.cancel);
    return const StoreState();
  }

  StoreGateway get _gateway => ref.read(storeGatewayProvider);

  /// Looks up prices. Called when the Patron's Hall opens, never at launch.
  Future<void> refresh() async {
    if (state.status == StoreStatus.loading) return;
    state = state.copyWith(status: StoreStatus.loading);
    final prices = await _gateway.loadPrices({for (final p in Patronage.all) p.id});
    if (!ref.mounted) return;
    state = prices == null || prices.isEmpty
        ? state.copyWith(status: StoreStatus.unavailable, prices: const {})
        : state.copyWith(status: StoreStatus.ready, prices: prices);
  }

  /// Opens the platform checkout. The player sees and confirms the price there.
  Future<void> buy(StoreProduct product) async {
    if (state.busy || state.status != StoreStatus.ready || !state.prices.containsKey(product.id)) return;
    state = state.copyWith(busyProductId: product.id);
    try {
      await _gateway.buy(product);
    } catch (_) {
      if (!ref.mounted) return;
      state = state.copyWith(busyProductId: null, notice: StoreNotice.failed);
    }
  }

  Future<void> restore() async {
    if (state.busy) return;
    _restoredDuringRestore = 0;
    state = state.copyWith(restoring: true);
    try {
      await _gateway.restore();
      await Future<void>.delayed(_gateway.restoreWait);
    } catch (_) {
      if (!ref.mounted) return;
      state = state.copyWith(restoring: false, notice: StoreNotice.failed);
      return;
    }
    if (!ref.mounted) return;
    state = state.copyWith(
      restoring: false,
      notice: _restoredDuringRestore > 0 ? StoreNotice.restored : StoreNotice.nothingToRestore,
    );
  }

  Future<void> _onEvent(StoreEvent e) async {
    switch (e) {
      case StorePending():
        state = state.copyWith(notice: StoreNotice.pending);
      case StoreCancelled():
        state = state.copyWith(busyProductId: null, notice: StoreNotice.cancelled);
      case StoreProblem():
        state = state.copyWith(busyProductId: null, notice: StoreNotice.failed);
      case StorePurchased():
        final product = Patronage.byId(e.productId);
        if (product == null) {
          await e.confirm(); // Not ours; let the store move on.
          return;
        }
        try {
          // Save first, confirm second: a purchase is never lost to a crash.
          await ref.read(repositoryProvider).recordPurchase(
                product,
                e.transactionId,
                at: ref.read(clockProvider)(),
              );
          await e.confirm();
        } catch (_) {
          if (ref.mounted) state = state.copyWith(busyProductId: null, notice: StoreNotice.failed);
          return;
        }
        if (!ref.mounted) return;
        if (e.restored) {
          _restoredDuringRestore++;
          state = state.copyWith(busyProductId: null, notice: StoreNotice.restored);
        } else {
          state = state.copyWith(
            busyProductId: null,
            notice: product.isTip ? StoreNotice.thanksTip : StoreNotice.thanksPack,
          );
        }
    }
  }
}

final storeProvider = NotifierProvider<StoreController, StoreState>(StoreController.new);
