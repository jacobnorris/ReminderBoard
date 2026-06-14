import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/task.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDeleteRequested;

  const TaskCard({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onDeleteRequested,
  });

  bool get _isDesktopOrWeb =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.linux ||
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.windows;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: _isDesktopOrWeb ? null : onDeleteRequested,
      onSecondaryTap: _isDesktopOrWeb ? onDeleteRequested : null,
      child: Card(
        elevation: 2.0,
        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Choose layout direction based on the card's actual aspect ratio.
            // Cards wider than 1.5× their height get a Row (side-by-side) layout.
            // Square or portrait cards get a Column (stacked) layout.
            // This naturally matches the two childAspectRatio values in the grid
            // (2.5 for ≤3 columns → wide → Row; 1.0 for >3 columns → square → Column).
            final isWide = constraints.maxWidth > constraints.maxHeight * 1.5;

            // Flutter's Material Switch natural dimensions (dp).
            const switchNaturalWidth = 60.0;
            const switchNaturalHeight = 40.0;

            // How much of the card width the switch may occupy.
            // Row layout: keep the switch to 40% so text gets the majority.
            // Column layout: switch can be wider since text is above it.
            final maxSwitchWidth = isWide
                ? constraints.maxWidth * 0.40
                : constraints.maxWidth * 0.70;

            // Scale down to fit, but never below 0.55×.
            // At 0.55× the switch is ~33×22dp — small but still intentionally
            // tappable at the high column counts the user has chosen.
            final scale = (maxSwitchWidth / switchNaturalWidth).clamp(
              0.55,
              1.0,
            );

            final scaledSwitchWidth = switchNaturalWidth * scale;
            final scaledSwitchHeight = switchNaturalHeight * scale;

            // Shrink font slightly on narrow cards so more characters fit
            // before the ellipsis kicks in.
            final fontSize = constraints.maxWidth < 80 ? 10.0 : 13.0;

            final textWidget = Text(
              task.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: fontSize,
                decoration: task.isCompleted
                    ? TextDecoration.lineThrough
                    : TextDecoration.none,
              ),
            );

            // FittedBox with BoxFit.contain scales both the rendering AND the
            // hit-test region, so the switch stays interactive at reduced size.
            final switchWidget = SizedBox(
              width: scaledSwitchWidth,
              height: scaledSwitchHeight,
              child: FittedBox(
                fit: BoxFit.contain,
                child: Switch(
                  value: task.isCompleted,
                  onChanged: onToggle,
                  activeThumbColor: Colors.teal,
                ),
              ),
            );

            if (isWide) {
              // Horizontal layout: text expands to fill remaining width.
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 4.0,
                ),
                child: Row(
                  children: [
                    Expanded(child: textWidget),
                    const SizedBox(width: 4.0),
                    switchWidget,
                  ],
                ),
              );
            } else {
              // Vertical layout: text sits above the switch, both centred.
              // Expanded on the text section lets it occupy all spare vertical
              // space while the switch stays at its fixed scaled size below.
              return Padding(
                padding: const EdgeInsets.all(6.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: textWidget,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    switchWidget,
                  ],
                ),
              );
            }
          },
        ),
      ),
    );
  }
}
