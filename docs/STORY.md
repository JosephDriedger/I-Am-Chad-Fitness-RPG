# Story

Season One, **The Dawn Bell**: a comedic, warm story told in a prologue and seven chapters. It is a reason to level up, not a reason to feel behind. For the tone rules every line has to follow, see [Content guidelines](CONTENT_GUIDELINES.md#story).

## The premise

The Guild Hall's great bell has been silent for a long time, and nobody can quite remember why. You arrive as a new hero, and Chad, who is certain he is in charge, enlists you to find out. Along the way you meet the people and creatures of the valley, learn what really happened to the bell, and ring it at dawn.

## Cast

| Name | Who they are |
| --- | --- |
| Chad | The guildmaster. Theatrical, sincere, and fond of mentioning that he started at Level 2. |
| Biscuit | Chad's dog and the hall's only fully reliable employee. Says "Woof!" and means it. |
| Maple | The quartermaster. Dry, practical, always counting something. |
| Brad | A very enthusiastic rival who turns out to be good at resting. |
| Oakhelm | A very old tree with strong opinions and a slow way of stretching. |
| Grit | A gremlin who collects shiny things and has the bell's clapper. |
| Murmur | A small, sorry creature in the fog. Fears tomorrow, learns it is fine. |
| You | Called by the hero's name wherever a line says `{hero}`. |

## Chapters

Chapters open at hero levels, which only ever go up. The spacing follows the level curve: the first few arrive quickly, and the last ones take a few months of regular movement.

| Chapter | Title | Opens at | What happens |
| --- | --- | --- | --- |
| Prologue | A Hall Waiting for a Hero | Level 1 | You meet Chad and Biscuit, and learn that the Dawn Bell has been silent for a long time. |
| 1 | The Bell That Would Not Ring | Level 2 | The bell has no clapper. A trail of pebbles leads away, and you meet Maple, the quartermaster. |
| 2 | Pebbles and Misunderstandings | Level 3 | The pebble trail ends at Grit's hollow, and the clapper comes home. |
| 3 | A Rival, Briefly | Level 5 | Brad turns up with a rope, a lot of enthusiasm, and a surprising discovery about resting. |
| 4 | Strong Opinions in the Old Oak Wood | Level 7 | A very old tree, a slow stretch, and the beam the bell needs. |
| 5 | Maybe Tomorrow | Level 10 | In the foggiest corner of the valley, a small, sorry creature, and a cracked weathervane. |
| 6 | The Night Before the Bell | Level 13 | A campfire on the hill, and the true story of Level 2. |
| 7 | The Dawn Bell | Level 16 | The bell rings, the fog lifts, and the hall fills up. |

## Choices

A few moments ask you something. The answer is saved, the character replies to it straight away, and a later chapter may remember it: your reason for coming to the hall, whether you offered to help, how you asked Grit for the clapper, what you said to Brad, Oakhelm and Murmur, what you told Chad, and how you ring the Dawn Bell. Nothing is a wrong answer and nothing changes what you earn. The last chapter's farewell changes with your first answer.

Replaying a chapter lets you answer differently. The newest answer replaces the old one.

## How it works

- **Unlocking:** a chapter is open when the hero's level reaches its unlock level. Nothing is timed, nothing can be missed, and nothing is lost if you stop exercising for a while.
- **Hall:** when you come back to the hall with an unread chapter, Chad offers it once per session ("Read Now" or "Later"), and he mentions it in his idle lines. Choosing "Later" is always fine and nothing nags afterwards.
- **Reading:** tap anywhere to read on; the first tap finishes the line that is being typed. **Skip** counts the chapter as read, and the cross leaves without marking it, so it stays new. With reduced motion on, text appears at once and the scenery holds still.
- **Chronicle:** the Quests screen has a Chronicle card, which opens a list of every chapter. Chapters that have not opened keep their titles secret and say what level opens them. Anything opened can be read again whenever you like.
- **Saved data:** two small tables (`story_progress`, `story_choices`), included in the JSON export and cleared by Delete Everything. See [Data model](DATA_MODEL.md).

## Where it lives

| What | Where |
| --- | --- |
| Script, cast, unlock rules, conditions | `lib/domain/story.dart` (pure Dart) |
| Backdrops and the new characters (Maple, Biscuit) | `lib/game/art/story_art.dart` |
| Reading screen | `lib/features/story/story_screen.dart` |
| Chronicle list and Quests card | `lib/features/story/chronicle_screen.dart` |
| Offer in the hall | `lib/features/home/hub_screen.dart` |
| Rules enforced by tests | `test/domain/story_test.dart` |
| Looking at the scenes | `STORY_SHEET=<folder> flutter test test/tool/story_sheet_test.dart` renders a contact sheet of every scene |

## Writing more

Add a `StoryChapter` to `Story.chapters` in order, with an unlock level that is higher than the last one. Every line is checked by `story_test.dart`: no shaming or pressure words, no body talk, the season must say that rest, your own pace and no deadlines are welcome, conditions must refer to choices that exist, and the numbering and levels must stay in order. Read the [content guidelines](CONTENT_GUIDELINES.md) first.

Ideas for Season Two live in the [roadmap](ROADMAP.md).
