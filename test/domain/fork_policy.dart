import 'package:i_am_chad/domain/expedition.dart';

/// How the scripted players in the balance tests take a fork in the road: a
/// sensible player heals when hurt and otherwise takes the bonus.
int wayAtFork(ExpeditionRun run) {
  final ev = run.current!.event!;
  if (!ev.hasChoice) return 0;
  final hurt = run.hero.hp < run.hero.maxHp * 0.65;
  bool heals(EventKind k) => k == EventKind.rest || k == EventKind.spring;
  for (var i = 0; i < ev.choices.length; i++) {
    if (heals(ev.choices[i].kind) == hurt) return i;
  }
  return 0;
}
