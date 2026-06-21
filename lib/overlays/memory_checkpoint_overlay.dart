import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_fonts.dart';
import '../game/config/checkpoint_spec.dart';

/// Memory-checkpoint recall modal (2.0 Phase 3, §6).
///
/// Presented while the round timer is frozen. Shows the shuffled [prompt.options]
/// and asks the player to pick the [prompt.recallCount] tokens they saw — in
/// order when [prompt.orderMatters]. On submit, [onSubmit] receives the selected
/// tokens (in tap order) and the game grades them (+reward / -penalty).
class MemoryCheckpointOverlay extends StatefulWidget {
  final CheckpointPrompt prompt;
  final void Function(List<String> selected) onSubmit;

  const MemoryCheckpointOverlay({
    super.key,
    required this.prompt,
    required this.onSubmit,
  });

  @override
  State<MemoryCheckpointOverlay> createState() =>
      _MemoryCheckpointOverlayState();
}

class _MemoryCheckpointOverlayState extends State<MemoryCheckpointOverlay> {
  final List<String> _selected = <String>[];

  void _toggle(String token) {
    setState(() {
      if (_selected.contains(token)) {
        _selected.remove(token);
      } else if (_selected.length < widget.prompt.recallCount) {
        _selected.add(token);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final prompt = widget.prompt;
    final bool ready = _selected.length == prompt.recallCount;
    final String title =
        prompt.orderMatters ? "Recall — in order" : "What did you see?";
    final String subtitle = prompt.orderMatters
        ? "Tap the ${prompt.recallCount} tokens in the order they appeared"
        : "Tap the ${prompt.recallCount} tokens you saw";

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24.0),
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          color: AppColors.kSurface,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: AppColors.kAccent, width: 2.0),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontFamily: AppFonts.kFontDisplay,
                fontSize: 22.0,
                fontWeight: FontWeight.bold,
                color: AppColors.kPrimaryText,
              ),
            ),
            const SizedBox(height: 8.0),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: AppFonts.kFontBody,
                fontSize: 13.0,
                color: AppColors.kSecondaryText,
              ),
            ),
            const SizedBox(height: 20.0),
            Wrap(
              spacing: 12.0,
              runSpacing: 12.0,
              alignment: WrapAlignment.center,
              children: prompt.options.map(_buildChip).toList(),
            ),
            const SizedBox(height: 24.0),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: ready ? () => widget.onSubmit(List.of(_selected)) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.kAccent,
                  disabledBackgroundColor: AppColors.kBackground,
                  padding: const EdgeInsets.symmetric(vertical: 14.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                child: Text(
                  ready
                      ? "SUBMIT"
                      : "PICK ${prompt.recallCount - _selected.length} MORE",
                  style: const TextStyle(
                    fontFamily: AppFonts.kFontDisplay,
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                    color: AppColors.kPrimaryText,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String token) {
    final int index = _selected.indexOf(token);
    final bool isSelected = index >= 0;
    return GestureDetector(
      onTap: () => _toggle(token),
      child: Container(
        width: 56.0,
        height: 56.0,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.kAccent : AppColors.kBackground,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: isSelected ? AppColors.kAccent : AppColors.kSecondaryText,
            width: 2.0,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              token,
              style: const TextStyle(
                fontFamily: AppFonts.kFontDisplay,
                fontSize: 22.0,
                fontWeight: FontWeight.bold,
                color: AppColors.kPrimaryText,
              ),
            ),
            // Order badge (only meaningful when order matters, but harmless).
            if (isSelected && widget.prompt.orderMatters)
              Positioned(
                top: 2.0,
                right: 4.0,
                child: Text(
                  "${index + 1}",
                  style: const TextStyle(
                    fontFamily: AppFonts.kFontBody,
                    fontSize: 11.0,
                    fontWeight: FontWeight.bold,
                    color: AppColors.kPrimaryText,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
