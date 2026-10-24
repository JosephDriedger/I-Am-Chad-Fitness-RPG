# Monetization

How the game earns money, and the promises that come with it. The short version: **the game is free and complete, there are no ads, and the only things money buys are looks and a thank-you.** Everything here is enforced by code and tests, not only by intention.

The rules and the product list live in [`lib/domain/patronage.dart`](../lib/domain/patronage.dart); the checkout code is in [`lib/app/store.dart`](../lib/app/store.dart); the screen is [`lib/features/patron`](../lib/features/patron). The reasoning is [Decision 32](DECISIONS.md#32-optional-cosmetic-patronage-and-nothing-else).

## The promises

1. **The whole game is free, forever.** Every exercise, quest, expedition, story chapter, reward, streak and piece of gear is available to everyone. Nothing is gated, trialled or "unlocked later".
2. **No ads.** No banners, no interstitials, no rewarded videos, no ad SDK, no ad ids. A fitness game that asks people to look at a screen between sets, or that sells their attention, does not fit the pillars.
3. **No tracking and no account.** There is no analytics SDK and no server. The only network contact is the platform store, when the player opens the Patron's Hall or buys something. The app never sees a card, name or address.
4. **Money never buys power.** Not XP, energy, coins, potions, gear, damage, health, loot, streak protection, story or any shortcut. Real exercise is the only source of adventure energy ([Decision 16](DECISIONS.md#16-real-exercise-is-the-only-source-of-adventure-energy)), and that stays true.
5. **No pressure.** No countdowns, limited-time offers, "best value" badges, strike-through prices, daily deals, red notification dots, or purchase prompts after a workout, a win, a loss or a level-up. The store is never shown unless the player goes to Settings and opens it. Not owning anything costs nothing.
6. **No gambling mechanics.** No loot boxes, gacha, random cosmetics, or currencies that hide what something costs. Every product is a fixed, named item.
7. **No subscriptions.** Every purchase is a single payment.
8. **Honest prices.** Prices are never written in the app. The store reports the price in the player's own currency, and that is exactly what the screen and the store sheet show.
9. **Restorable.** One-time purchases belong to the player's store account and come back with **Restore Purchases**, on a new phone or after **Delete All My Data**.
10. **Offline-first.** A purchase is saved on the device, so what was bought works with no connection. Only buying and restoring need one.
11. **Modest by design.** There is exactly one cosmetic pack and three tips, nothing in the catalog costs more than the largest tip (about US$9.99), and nothing can be bought in bulk.

## What is for sale

| Product | Store id | Type | What it is |
| --- | --- | --- | --- |
| Patron Pack | `patron_pack` | One-time, non-consumable | Three mantles (Crimson, Starlit, Aurora), four hair dyes (Mint, Sky, Rose, Lavender) and guild-hall decorations (string lights, a potted lantern tree, a patron rosette on the banner). Looks only. |
| A Protein Shake for Chad | `tip_shake` | Consumable tip | A thank-you. Unlocks nothing. |
| A Hearty Lunch for Chad | `tip_lunch` | Consumable tip | A bigger thank-you. Unlocks nothing. |
| A Banquet for the Guild | `tip_banquet` | Consumable tip | The biggest thank-you. Unlocks nothing. |

**Suggested prices**, set in the store consoles and never in code: Patron Pack about US$3.99, tips about US$1.99, US$4.99 and US$9.99. Treat US$9.99 as a ceiling for anything ever added to this catalog. Use each store's regional price templates so prices stay fair in every country rather than a straight currency conversion.

Tips unlock nothing at all. They are thanks, shown as a count Chad can smile about, never as a rank, badge, title or perk.

## Free looks sit beside the paid ones

Cosmetics have three sources, and the game has plenty to look at without paying:

| Source | Examples |
| --- | --- |
| **Free** | The classic cape, six hair styles, six outfit colours, six skin tones, and every piece of gear. |
| **Earned by playing** | The Dawn Mantle (finish Season One), the Sunrise and Moonlit hair dyes (levels 5 and 10), and ten hall **pennants** that hang on bunting across the guild hall: first workout, first expedition, a heroic week, levels 5, 10, 20 and 30, ten expeditions, a month's streak and the finished season. They appear as milestones are reached, are never taken down, and are never for sale. |
| **Patron Pack** | The extra mantles, dyes and decorations listed above. |

So paying does not make a hero look "more accomplished": the pennants and the Dawn Mantle can only be earned. The pack is extra choice, not better standing.

## How it works in the code

```
Settings ──▶ Patron's Hall (PatronScreen)
                │  asks StoreController for prices      (app/store.dart)
                ▼
          StoreGateway ──────────▶ Google Play Billing / StoreKit  (in_app_purchase)
                │  purchase events
                ▼
          StoreController: save the receipt, THEN confirm to the store
                │
                ▼
          purchase_receipts table ──▶ Entitlements ──▶ CosmeticContext ──▶ heroLookProvider, hall decor
```

- `domain/patronage.dart` is the single list of products and the wording of the promise. `test/domain/patronage_test.dart` fails if a product's text sounds like power or pressure, and lints Chad's lines in the hall.
- `domain/cosmetics.dart` describes capes, dyes, pennants and hall decorations. **None of those types has a stat, bonus or reward field.** A look the player does not have is drawn as the default, so a lost save cannot show a broken hero.
- **Receipts are idempotent.** A pack is stored once under its product id, however often the store re-delivers or restores it. A tip is stored once per store transaction id. `test/data/purchase_test.dart` proves a purchase changes no coins, XP, energy, potions, items or progress.
- **Save first, confirm second.** The store is told a purchase was delivered only after it is written to the database, so a crash can never lose something the player paid for. Until confirmed, the store keeps the purchase and delivers it again (and refunds it automatically after three days on Google Play).
- The store is listened to **from app launch**, so a purchase that finished while the app was closed, such as one a parent approved, is delivered and saved. Prices are only requested when the Patron's Hall is opened, never at launch.
- The platform store is behind `StoreGateway`. Tests and the browser preview use `TestStoreGateway`, a pretend store with made-up prices that says so on screen. It is only selected on web (`kIsWeb`), which is a development convenience and not a shipped target.

## Privacy and the player's data

- The only data involved is what the platform store handles itself. The app stores, per purchase, the **product id and the date**, and nothing identifying the buyer. The store's transaction id is used only as a de-duplication key for tips and is not exported.
- **Copy My Data** includes the `purchases` list. **Delete All My Data** removes the receipts; the pack comes back with Restore Purchases because it belongs to the store account. The confirmation dialog says so.
- Play's Data safety form and Apple's privacy label should declare **purchase history handled by the store** only, with no data collected by the developer and no data shared. If an analytics or ads SDK is ever added, this document, the store disclosures and the in-app wording must all change first, and [Decision 32](DECISIONS.md#32-optional-cosmetic-patronage-and-nothing-else) must be revisited.

## Children and families

Onboarding collects no age, so the app cannot know who is playing, and the answer is to make the store the guard rather than to guess:

- All checkout is the platform's own sheet, so **Google Family Link and Apple Ask to Buy** work as usual. A purchase waiting for approval shows as pending and is delivered later.
- The Patron's Hall says plainly: if you are under 18, ask a grown-up first.
- Nothing is sold through pressure, rewards or characters begging, which is the part of "kid-friendly monetization" that matters most. There is no currency to confuse, no random result, and no gameplay benefit that could make a young player feel they have to buy.
- Before submitting, decide the age rating together with the rest of the release work ([Roadmap](ROADMAP.md)). The in-app purchases and the absence of ads and user-generated content are the facts the questionnaires will ask about.

## Setting it up in the stores

Do this once, with the real application id (the generated id `com.iamchad.i_am_chad` is a placeholder; change it first, see [Development](DEVELOPMENT.md)).

1. **Google Play Console:** *Monetize > Products > In-app products.* Create `patron_pack` (non-consumable in practice: Play treats it as one-time; the app never consumes it), and `tip_shake`, `tip_lunch`, `tip_banquet`. Set status to *Active* and use regional price templates. Add yourself and testers under *License testing* so test purchases are free, then test with an internal-testing track build.
2. **App Store Connect:** *Monetization > In-App Purchases.* Create the same four ids as `patron_pack` (Non-Consumable) and the three tips (Consumable). Give each a reference name, a price tier, a localized display name and a screenshot of the Patron's Hall. Test with a Sandbox tester account.
3. **Product ids must match exactly** the table above. They are persisted in the receipts table and in the stores, so they are never renamed.
4. **Android:** the plugin adds the billing permission and library automatically; nothing to add to the manifest.
5. **iOS:** enable the *In-App Purchase* capability in Xcode. (iOS has not been built at all yet; see the [Roadmap](ROADMAP.md).)
6. Fill in the Play *Data safety* form and the App Privacy label as described above, and mention the optional purchases in the store description in plain words: "Free to play. No ads. Optional cosmetic pack and tip jar."

## Changing this later

Allowed without a new decision: new cosmetics for the pack or as free or earned looks, new pennants, a new tip tier at or below the ceiling.

Needs a new entry in the [decision log](DECISIONS.md) first, because it changes a promise: anything that touches gameplay, any ad or tracking SDK, a subscription, a random reward, a currency bought with money, a limited-time offer, or a purchase prompt outside the Patron's Hall.

**Planned and consistent with all of this:** future story seasons (for example Season Two) may be sold as honest one-time expansions, with Season One staying free forever. That would be new content for people who loved the first season, never a paywall in front of progress, exercise or rewards, and it would go through the same Patron's Hall, receipts and restore path.
