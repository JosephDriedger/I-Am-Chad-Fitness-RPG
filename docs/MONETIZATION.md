# Monetization

How the game earns money, and the promises that come with it. The short version: **the game is free and complete, every story chapter is free, the only ad is one at the start of each story chapter, and money buys only quiet (Premium removes that ad), looks and a thank-you.** Everything here is enforced by code and tests, not only by intention.

The rules and the product list live in [`lib/domain/patronage.dart`](../lib/domain/patronage.dart); the checkout code is in [`lib/app/store.dart`](../lib/app/store.dart); the screen is [`lib/features/patron`](../lib/features/patron). The ad code is [`lib/app/ads.dart`](../lib/app/ads.dart). The reasoning is [Decision 32](DECISIONS.md#32-optional-cosmetic-patronage-and-nothing-else) and, for the ad and Premium, [Decision 33](DECISIONS.md#33-one-ad-at-the-start-of-a-story-chapter-and-premium-removes-it).

## The promises

1. **The whole game is free, forever, and stories are never sold.** Every exercise, quest, expedition, story chapter and season, reward, streak and piece of gear is available to everyone. Nothing is gated, trialled or "unlocked later", and no story is behind a payment, because a paywall in front of the story would put people off using the app and working out.
2. **One ad, in one place.** The only ad in the game is a single full-screen ad at the very start of a story chapter, before its first line, the first time that chapter is read. Never during or between sets, workouts, rewards, battles, the shop, the hall or onboarding, never in the middle of a story, never when a chapter is read again. If no ad is ready, the story simply begins. **Premium removes it for good.** `test/ads_promise_test.dart` fails if ad code appears anywhere else.
3. **Little data, and an honest account of it.** No account, no analytics SDK and no server of ours (later story seasons are static files on a web host that the app only downloads from, see [Content packs](CONTENT_PACKS.md)). Workouts, progress and story choices never leave the device. The network is used by the platform store, and by Google AdMob for the chapter ad. Ads are requested **non-personalized** and limited to **family-friendly (G)** content, only after the player's choices have been collected where the law requires it (Google's consent form), and those choices can be reopened from Settings. Premium owners never contact AdMob at all.
4. **Money never buys power.** Not XP, energy, coins, potions, gear, damage, health, loot, streak protection, story or any shortcut. Real exercise is the only source of adventure energy ([Decision 16](DECISIONS.md#16-real-exercise-is-the-only-source-of-adventure-energy)), and that stays true.
5. **No pressure.** No countdowns, limited-time offers, "best value" badges, strike-through prices, daily deals, red notification dots, or purchase prompts after a workout, a win, a loss or a level-up. The store is never shown unless the player goes to Settings and opens it. Not owning anything costs nothing.
6. **No gambling mechanics.** No loot boxes, gacha, random cosmetics, or currencies that hide what something costs. Every product is a fixed, named item.
7. **No subscriptions.** Every purchase is a single payment.
8. **Honest prices.** Prices are never written in the app. The store reports the price in the player's own currency, and that is exactly what the screen and the store sheet show.
9. **Restorable.** One-time purchases belong to the player's store account and come back with **Restore Purchases**, on a new phone or after **Delete All My Data**.
10. **Offline-first.** A purchase is saved on the device, so what was bought works with no connection. Only buying and restoring need one.
11. **Modest by design.** There is exactly one cosmetic pack, one Premium and three tips, nothing in the catalog costs more than the largest tip (about US$9.99), and nothing can be bought in bulk.

## What is for sale

| Product | Store id | Type | What it is |
| --- | --- | --- | --- |
| Premium | `premium_no_ads` | One-time, non-consumable | Removes the ad at the start of each story chapter, for good. Gives nothing else: every chapter is free either way. |
| Patron Pack | `patron_pack` | One-time, non-consumable | Three mantles (Crimson, Starlit, Aurora), four hair dyes (Mint, Sky, Rose, Lavender) and guild-hall decorations (string lights, a potted lantern tree, a patron rosette on the banner). Looks only. |
| A Protein Shake for Chad | `tip_shake` | Consumable tip | A thank-you. Unlocks nothing. |
| A Hearty Lunch for Chad | `tip_lunch` | Consumable tip | A bigger thank-you. Unlocks nothing. |
| A Banquet for the Guild | `tip_banquet` | Consumable tip | The biggest thank-you. Unlocks nothing. |

**Suggested prices**, set in the store consoles and never in code: Premium about US$2.99, Patron Pack about US$3.99, tips about US$1.99, US$4.99 and US$9.99. Treat US$9.99 as a ceiling for anything ever added to this catalog. Use each store's regional price templates so prices stay fair in every country rather than a straight currency conversion.

Tips unlock nothing at all. They are thanks, shown as a count Chad can smile about, never as a rank, badge, title or perk.

## Free looks sit beside the paid ones

Cosmetics have three sources, and the game has plenty to look at without paying:

| Source | Examples |
| --- | --- |
| **Free** | The classic cape, six hair styles, six outfit colours, six skin tones, and every piece of gear. |
| **Earned by playing** | Six mantles, one for finishing each season (Dawn, Lantern, Chime, Table, Hearth and Comet), seven hair dyes (Sunrise, Moonlit, Ember, Glacier, Sunstone, Comet and Cinder, at levels 5, 10, 20, 30, 40, 50 and 66), and ten hall **pennants** that hang on bunting across the guild hall: first workout, first expedition, a heroic week, levels 5, 10, 20 and 30, ten expeditions, a month's streak and the finished season. They appear as milestones are reached, are never taken down, and are never for sale. Five **keepsakes** stand on the hall floor, one for each of Seasons Two to Six (a harbour lamp, a little chime, a laid table, a banked hearth and a comet glass). Ten **trophies** on the Journal bookshelf (room for twelve, in two rows) work the same way, for the long haul: the Season Two to Six finales, levels 40, 50 and 100, 25 expeditions and a 90-day streak. |
| **Patron Pack** | The extra mantles, dyes and decorations listed above. |

So paying does not make a hero look "more accomplished": the pennants, trophies, season mantles and the earned dyes can only be earned. The pack is extra choice, not better standing.

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
- **The ad** is behind `AdGateway` (`lib/app/ads.dart`), like the store is behind `StoreGateway`. `AdPolicy` decides when one may show: never before the app knows whether the player has Premium (it waits at most two seconds, then shows nothing), never for Premium, never when a chapter is read again. The story screen shows "One moment..." while it waits and will not begin underneath the ad. Any failure (offline, no consent, no ad within six seconds) means no ad and the story begins. Nothing at launch contacts AdMob: it starts the first time a non-Premium player opens a chapter they have not read.
- The platform store is behind `StoreGateway`. Tests and the browser preview use `TestStoreGateway`, a pretend store with made-up prices that says so on screen. It is only selected on web (`kIsWeb`), which is a development convenience and not a shipped target.

## Privacy and the player's data

- The only data involved is what the platform store handles itself. The app stores, per purchase, the **product id and the date**, and nothing identifying the buyer. The store's transaction id is used only as a de-duplication key for tips and is not exported.
- **Copy My Data** includes the `purchases` list. **Delete All My Data** removes the receipts; the pack comes back with Restore Purchases because it belongs to the store account. The confirmation dialog says so.
- **Declare the ad SDK honestly.** Google AdMob collects device and advertising identifiers and usage data to serve ads, so Play's *Data safety* form and Apple's *App Privacy* label must declare data collected and shared **by the ad SDK** (and Android's advertising-ID permission), alongside purchase history handled by the store. Publish a privacy policy that says the same, and keep it, the in-app wording (Settings, the Patron's Hall) and the store listing in step. Premium owners never load the ad SDK's network code.
- The player's choices: Google's consent form (UMP) is shown where required (the EEA, UK and some other regions) before the first ad, and **Ad Privacy Choices** in Settings reopens it. Ads are requested non-personalized regardless.

## Children and families

Onboarding collects no age, so the app cannot know who is playing, and the answer is to make the store the guard rather than to guess:

- All checkout is the platform's own sheet, so **Google Family Link and Apple Ask to Buy** work as usual. A purchase waiting for approval shows as pending and is delivered later.
- The Patron's Hall says plainly: if you are under 18, ask a grown-up first.
- Nothing is sold through pressure, rewards or characters begging, which is the part of "kid-friendly monetization" that matters most. There is no currency to confuse, no random result, and no gameplay benefit that could make a young player feel they have to buy.
- **The audience is teens and adults (13 and over), and the game is not for younger children.** Choose the matching answers in each store: on Google Play, set the *target audience* to 13 and over only (so the game is not in the Families programme); in App Store Connect, choose an age rating of 12+ or 13+ as the questionnaire gives it. Nothing is aimed at younger children, and the app says so in its store listing. Onboarding still collects no age (the privacy pillar), so the app does not check; the stores' ratings, parental controls and Google's own consent handling for under-16s in the EEA are what apply. If the game ever learns that a player is under 13, it should show no ads to them, so a neutral "13 or older?" question at onboarding is the natural addition if the stores or the law ask for one.
- **No adult-themed ads.** The app requests only the most restrictive content rating (G), non-personalized, and sends no child age-treatment signal (the game is not for younger children). Those settings cannot block everything by themselves, so the AdMob account must also be locked down (see the set-up steps): block the sensitive categories, and the ones that clash with this game's tone.

## Setting it up in the stores

Do this once, with the real application id (the generated id `com.iamchad.i_am_chad` is a placeholder; change it first, see [Development](DEVELOPMENT.md)).

1. **Google Play Console:** *Monetize > Products > In-app products.* Create `patron_pack` (non-consumable in practice: Play treats it as one-time; the app never consumes it), and `tip_shake`, `tip_lunch`, `tip_banquet`. Set status to *Active* and use regional price templates. Add yourself and testers under *License testing* so test purchases are free, then test with an internal-testing track build.
2. **App Store Connect:** *Monetization > In-App Purchases.* Create the same four ids as `patron_pack` (Non-Consumable) and the three tips (Consumable). Give each a reference name, a price tier, a localized display name and a screenshot of the Patron's Hall. Test with a Sandbox tester account.
3. **Product ids must match exactly** the table above. They are persisted in the receipts table and in the stores, so they are never renamed.
4. **Android:** the plugin adds the billing permission and library automatically; nothing to add to the manifest.
5. **iOS:** enable the *In-App Purchase* capability in Xcode. (iOS has not been built at all yet; see the [Roadmap](ROADMAP.md).)
6. Create `premium_no_ads` the same way in both stores (one-time, non-consumable).
7. **AdMob:** create an AdMob account and an app for each platform, and an **interstitial** ad unit for each. Replace Google's public **test** ids with the real ones: the two ad unit ids in `lib/app/ads.dart`, `com.google.android.gms.ads.APPLICATION_ID` in `android/app/src/main/AndroidManifest.xml`, and `GADApplicationIdentifier` in `ios/Runner/Info.plist`. Until you do, only test ads can ever appear. In AdMob's *Privacy & messaging*, set up the consent (GDPR) message and the privacy options entry. Test on a real device with your device id registered as a test device before going live.
   **Then lock the ads down** in AdMob under *Blocking controls*: set the maximum ad content rating to **General audiences** for both apps, and **block every sensitive category**: Dating, Gambling and betting, Alcohol, Politics and elections, Religion, Sexual and reproductive health, Get-rich-quick offers, Drugs and supplements, and above all **Weight loss and diet** (it would contradict a game that never talks about bodies). Also turn off *Sensitive categories* generally if the console offers it, and review the *Ad review center* now and then. The code asks for G-rated ads, but the account settings are what actually stop an unwanted advertiser from ever being matched.
8. Fill in the Play *Data safety* form and the App Privacy label as described above, and say it plainly in the store description: "Free to play. Every story is free. One ad at the start of each chapter, removed by Premium. Optional cosmetic pack and tip jar."

## Changing this later

Allowed without a new decision: new cosmetics for the pack or as free or earned looks, new pennants or trophies, a new tip tier at or below the ceiling.

Needs a new entry in the [decision log](DECISIONS.md) first, because it changes a promise: anything that touches gameplay, **any ad anywhere other than the start of a story chapter**, any other ad or tracking SDK, a subscription, a random reward, a currency bought with money, a limited-time offer, or a purchase prompt outside the Patron's Hall.

**Settled:** story seasons are free for everyone. A story is never sold, never locked behind a payment and never gated by Premium. Season Two, [The Lantern Coast](STORY.md), is free like Season One, and Premium only silences the one ad before each chapter.
