# Content packs: downloading the later story seasons

Season One is part of the app. Seasons Two to Seven (and any later season) are **downloaded the first time the player reads them**, and kept on the phone after that. This keeps a first install small and follows the pattern of games like Shadow Fight 2: when you reach new story content, the game offers a download with its size, shows progress, and then carries on. The reasoning is in [decision 39](DECISIONS.md#39-later-story-seasons-are-downloaded-once-from-static-files).

## What the player sees

1. They tap **Read** on a chapter of a season that is not on the phone yet (from the hall's "A New Chapter!" offer, the Quests card or the Chronicle). The hall offer and the Chronicle already say "downloads once, the first time you read it".
2. A card, **Download Season Two?**, names the season, states the size (for example "about 31 KB") and says plainly that it is a one-time download and that nothing about the player is sent. **Download** or **Not Now**.
3. A progress bar, with **Stop**. When it finishes, the chapter opens straight away.
4. If something goes wrong (no connection, a damaged file, a pack for a newer game, a season not on the shelf yet), a kind message says so, nothing is lost, and **Try Again** is offered where it could help. **Not Now** always leaves the chapter unread, exactly as before.

Nothing downloads at launch, in the background, or without a tap. A season that has been downloaded is never fetched again. The hall's offer is only an offer: being offered, or saying **Later**, fetches nothing, and the one look at the manifest (to say how big the download is) happens only after **Read Now**. If the player says **Not Now** to a download, the hall leaves that whole season alone for the rest of the session instead of offering its next chapter. A returning player with a chapter waiting is offered it when the hall appears, including right after the title screen, which moves on by itself after a few seconds.

Tested on an Android emulator against the live GitHub Pages address: the offer at launch, the size card, a real download whose file matches the published checksum, the same after a restart (nothing fetched), the offline message with airplane mode on, **Try Again** after reconnecting, and **Not Now** leaving nothing stored.

## What is in the app and what is downloaded

| In the app | Downloaded |
| --- | --- |
| Every season's title and blurb, and every chapter's number, season, title, unlock level and summary (`Story.chapters` in `lib/domain/story.dart`) | Each chapter's **script**: scenes, lines and choices |
| All the art: every speaker and backdrop the game can draw | Nothing visual. A script may only use speakers and backdrops the app already knows |
| The rules for when chapters open | Nothing that changes when anything opens |

So a download can never change when a chapter opens, what it is called in the Chronicle, or what a season finale unlocks. A pack that names a speaker or backdrop the app does not know is refused as a whole. **New art, such as a new character or place, needs an app update.** Only new words and choices can arrive by download.

## The files

Everything lives in one folder of static files: a `manifest.json` and one `season_N.json` per downloaded season.

```json
// manifest.json
{"format":1,"packs":[{"season":2,"version":1,"file":"season_2.json","bytes":30896,"sha256":"6ba6..."}]}
```

The app checks, before keeping anything: the size, the SHA-256, that the file is a pack of a format it can read, that it covers exactly the chapters the app lists for that season with the same titles, and that every speaker and backdrop is known and every speaker is in the scene. A file name in the manifest can only be a plain lower-case name ending in `.json`, so a manifest can never point anywhere else. Files are written to a temporary name and renamed, so a half-finished download is never mistaken for a pack. Total size of a pack is capped at 2 MB (a season is about 30 KB).

A pack made for a newer game (`format` above what the app reads) gives a polite "needs a newer version of the game" instead of an error.

## Privacy

The download is one plain HTTPS GET for `manifest.json` and one for the season file. It carries no account, id, cookie or custom header, and the app removes the user-agent. The server therefore learns only what any web request reveals (an address and the time), which is why the settings text, the guide, the data model and the content guidelines all say the download "sends nothing about you". `test/content_packs_test.dart` keeps the pack code from importing anything that knows the player, and from sending bodies, cookies or headers. Release builds accept `https` only; debug builds also accept `http` so a local server can be used.

## Writing a season

1. Write the script in `tool/story_content/season_N.dart` (the same way Seasons Two to Four are written, see [Story](STORY.md#writing-more)). Scripts live in `tool/`, not `lib/`, so they are not compiled into the app.
2. Add the chapters' place, title, unlock level and summary to the catalog in `lib/domain/story.dart` (`Story.seasonTwo` and so on, with no scenes) and a `StorySeason`. `test/domain/story_packs_test.dart` fails if the catalog and the script disagree.
3. Add the season to `tool/story_content/content.dart` (`chapters` and `versions`).
4. Run `dart run tool/build_packs.dart`. It writes `docs/packs/`. Commit the result: the same test fails if `docs/packs` is out of date.
5. Publish the folder (below).

If published wording is corrected later, raise that season's number in `StoryContent.versions` and rebuild. (Phones that already have the season keep their copy until a future update checks for newer versions; today corrections reach new downloads, and everyone else gets them with an app update.)

## Publishing

`docs/packs/` is plain files, so any static host works. The app's default address is the repository's GitHub Pages site, `https://josephdriedger.github.io/I-Am-Chad-Fitness-RPG/packs/`. To use it: in the repository's **Settings > Pages**, choose **Deploy from a branch**, the `main` branch and the `/docs` folder. Nothing else is needed, and publishing a corrected season is just pushing the rebuilt files. Another host (a bucket, a CDN, Releases) works by building the app with `--dart-define=CONTENT_URL=https://example.com/packs/`.

Until the files are published, the download card says the chapters are "not on the shelf yet". That is safe, and nothing is lost.

`.gitattributes` marks `docs/packs/*` as binary so line endings are never rewritten: that would change the bytes and break the checksums.

## Trying it without publishing

```bash
dart run tool/serve_packs.dart
```

serves `docs/packs` on port 8080. For an Android emulator, run `adb reverse tcp:8080 tcp:8080`, then build with `--dart-define=CONTENT_URL=http://localhost:8080/` (debug builds allow plain http). Open a chapter of a later season and the download card appears. Widget tests never touch the network: `bootApp` installs a pretend source and, by default, every season already on the pretend phone. Pass `packStore: MemoryPackStore()` to start with none downloaded (see `test/pack_download_flow_test.dart`).

## Where it lives

| What | Where |
| --- | --- |
| Pack format, manifest, validation (pure Dart) | `lib/domain/story_pack.dart` |
| Source (HTTP and pretend), store (files and memory), installed packs | `lib/app/content_packs.dart` |
| The download card and the "make sure it is on the phone" step | `lib/features/story/pack_download.dart`, used by `openChapter` |
| Scripts, and the files built from them | `tool/story_content/`, `tool/build_packs.dart`, `docs/packs/` |
| Local server for trying it | `tool/serve_packs.dart` |
| Tests | `test/domain/story_packs_test.dart`, `test/content_packs_test.dart`, `test/pack_download_flow_test.dart` |
