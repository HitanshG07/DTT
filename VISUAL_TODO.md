# Visual Polish TODO (deferred)

Three cosmetic/layout issues found during the 2026-06-20 emulator verification.
They are **not** bugs in game logic — the 7 logic fixes are done and verified. These
are visual-only and were intentionally deferred. Each item below has the root cause,
the exact change to make, and the file/line to touch.

> Note: `kHudHeight` is already `72.0` (raised from 56 as part of the HUD-overflow fix).
> Keep it at 72 — the items below assume that.

---

## 1. Forbidden-intro triangle looks like it sits too low

**Where:** intro circle (S-05), HUD AVOID thumbnail, and falling triangles all use the
same painter.

**Root cause:** `lib/game/shapes/triangle_shape.dart` draws the apex at `y = 0` and the
base at `y = size.height` (fills the box top-to-bottom). A triangle's centroid (visual
centre of mass) is ~2/3 of the way down, so inside a centred container (the intro circle)
it reads as offset/low.

**Fix (how):** raise the base so the centroid lands on the cell centre.
In `paintShape`, change the two base vertices' Y from `size.height` to `size.height * 0.75`:
```dart
final double baseY = size.height * 0.75; // centroid = (0 + .75 + .75)/3 = 0.5h
final path = Path()
  ..moveTo(size.width / 2, 0)
  ..lineTo(size.width, baseY)
  ..lineTo(0, baseY)
  ..close();
```
**Watch for:** this also affects in-game falling triangles and the HUD thumbnail (they get
a small bottom margin). Eyeball all three after changing. If the in-game triangle looks too
small, apply the 0.75 factor only in the intro/HUD painters instead of the shared one.

---

## 2. Milestone banner ("Nice Start!", etc.) is overlapped by falling shapes

**Where:** `lib/game/effects/milestone_overlay_effect.dart` — the banner is a Flame
`PositionComponent` rendered in the play field (~y=80).

**Root cause:** it has default priority, so `FallingObject`s draw **on top of** it.

**Fix (how):** give the banner a high priority so it renders above objects:
```dart
MilestoneOverlayEffect({required this.message}) : super(priority: 1000);
```
Optional: bump the hold/slide Y from `80.0` → `88.0` (3 occurrences in `update()`) so it
clears the now-72px HUD bar with a little gap, and update the stale "below the 56px HUD"
comment.

---

## 3. Score and combo badge are crowded in the HUD

**Where:** `lib/overlays/hud_overlay.dart` centre column (score `Text` stacked over
`ComboDecayBadge`), sizes in `lib/constants/app_sizes.dart`.

**Root cause:** a 28px score sits directly over a 40px badge with only 2px gap, so they
touch/crowd, especially at higher multipliers.

**Fix (how):** two small changes —
- `app_sizes.dart`: `kComboBadgeSize` `40.0` → `34.0` (slightly smaller badge).
- `hud_overlay.dart`: the badge `Padding(top: 2.0)` → `top: 5.0` (a bit more gap).

These keep the HUD at 72px with no overflow (the `hud_overlay_test` regression test still
passes). If you'd rather keep the 40px badge, instead raise `kHudHeight` to ~80 and update
that test's expectation.

---

### How to verify after applying
1. `flutter analyze` (clean) and `flutter test` (green — esp. `test/widget/hud_overlay_test.dart`).
2. `flutter run -d emulator-5554`, then:
   - Intro: forbidden = triangle → triangle looks centred in the blue circle.
   - Play to score 50 → "Nice Start!" banner renders above shapes (nothing overlaps it).
   - Build combo to x3–x5 → score and badge have clear separation, no overflow banner.
