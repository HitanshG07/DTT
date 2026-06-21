/// Score cutoffs for the 3-star mastery tiers of a level (2.0 Phase 4, §7).
///
/// Pure data. The 1-star cutoff is intentionally **forgiving** — it is the
/// unlock gate, and a brain-training module must never hard-wall a player. We
/// do NOT secretly ease physics (data-integrity guardrail); instead we keep
/// [one] reachable. The 2/3-star cutoffs are the mastery stretch.
class StarThresholds {
  final int one;
  final int two;
  final int three;

  const StarThresholds({
    required this.one,
    required this.two,
    required this.three,
  });

  /// Stars earned for [score] (0–3).
  int starsFor(int score) {
    if (score >= three) return 3;
    if (score >= two) return 2;
    if (score >= one) return 1;
    return 0;
  }
}
