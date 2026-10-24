import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/game_ui.dart';
import '../../app/providers.dart';
import '../../domain/story.dart';
import 'story_screen.dart';

/// Opens a chapter. Anything already unlocked can be read again at any time.
Future<void> openChapter(BuildContext context, StoryChapter chapter) =>
    Navigator.of(context).push<bool>(gameRoute(StoryScreen(chapter: chapter)));

/// Every chapter of the season: the ones that have opened, and a hint of when
/// the next one will. Nothing in here is timed or can be missed.
class ChronicleScreen extends ConsumerWidget {
  const ChronicleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(storyStatusProvider);
    if (status == null) {
      return const GameScaffold(
        title: 'Chronicle',
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return GameScaffold(
      title: 'Chronicle',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
        children: [
          const Text(
            'Chapters open as you level up, and every one stays open to read again. '
            'No timers, nothing to miss, and every chapter is free.',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: GameColors.inkSoft,
            ),
          ),
          const SizedBox(height: 14),
          for (final season in Story.seasons) ...[
            Text(season.title, style: gameTitle(28)),
            const SizedBox(height: 2),
            Text(
              '${season.name}. ${season.blurb}',
              style: const TextStyle(fontWeight: FontWeight.w700, color: GameColors.inkSoft),
            ),
            const SizedBox(height: 12),
            for (final c in Story.inSeason(season.number)) ...[
              _ChapterCard(chapter: c, status: status),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _ChapterCard extends StatelessWidget {
  const _ChapterCard({required this.chapter, required this.status});

  final StoryChapter chapter;
  final StoryStatus status;

  @override
  Widget build(BuildContext context) {
    final open = status.isUnlocked(chapter);
    final read = status.isRead(chapter);
    final String stateText;
    if (!open) {
      stateText = 'Opens at Level ${chapter.unlockLevel}';
    } else if (read) {
      stateText = 'Read';
    } else {
      stateText = 'New';
    }
    return Semantics(
      button: open,
      label: open
          ? '${chapter.label}, ${chapter.title}. $stateText.'
          : '${chapter.label}, locked. $stateText.',
      child: ExcludeSemantics(
        child: GamePanel(
          title: chapter.label,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LayoutBuilder(
                builder: (context, box) {
                  final title = Text(
                    open ? chapter.title : 'A chapter yet to come',
                    style: gameTitle(
                      21,
                      color: open ? GameColors.ink : GameColors.inkSoft,
                    ),
                  );
                  final chip = GameChip(
                    text: stateText,
                    icon: open
                        ? (read
                              ? Icons.check_circle_rounded
                              : Icons.auto_awesome_rounded)
                        : Icons.lock_rounded,
                    color: open && !read ? GameColors.gold : GameColors.cream,
                  );
                  // Side by side when there is room, stacked on a narrow screen or at large text.
                  final roomy = box.maxWidth >= 300 && MediaQuery.textScalerOf(context).scale(16) <= 20;
                  if (roomy) {
                    return Row(children: [Expanded(child: title), chip]);
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [title, const SizedBox(height: 6), chip],
                  );
                },
              ),
              if (open) ...[
                const SizedBox(height: 6),
                Text(
                  chapter.summary,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                GameButton(
                  label: read ? 'Read Again' : 'Read',
                  icon: Icons.auto_stories_rounded,
                  kind: read
                      ? GameButtonKind.secondary
                      : GameButtonKind.positive,
                  expanded: false,
                  small: true,
                  onPressed: () => openChapter(context, chapter),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A short card for the Quests screen: where the story is, and a way in.
class ChroniclePanel extends ConsumerWidget {
  const ChroniclePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(storyStatusProvider);
    if (status == null) return const SizedBox.shrink();
    final unread = status.unread;
    final next = status.next;
    return GamePanel(
      title: 'Chronicle',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${Story.seasonOf(status.latest.season).title}, ${status.read.length} of ${Story.chapters.length} chapters read',
            style: gameTitle(17),
          ),
          const SizedBox(height: 6),
          Text(
            unread.isNotEmpty
                ? 'A new chapter is waiting: ${unread.first.title}.'
                : next == null
                ? 'You have read everything there is, and every chapter can be read again whenever you like.'
                : 'You are all caught up. The next chapter opens at Level ${next.unlockLevel}.',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          if (unread.isNotEmpty) ...[
            GameButton(
              label: 'Read ${unread.first.label}',
              icon: Icons.auto_stories_rounded,
              kind: GameButtonKind.positive,
              onPressed: () => openChapter(context, unread.first),
            ),
            const SizedBox(height: 8),
          ],
          GameButton(
            label: 'Open the Chronicle',
            icon: Icons.menu_book_rounded,
            kind: GameButtonKind.secondary,
            onPressed: () =>
                Navigator.of(context).push(gameRoute(const ChronicleScreen())),
          ),
        ],
      ),
    );
  }
}
