import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nle_editor/presentation/widgets/editor/resizable_panel_divider.dart';

void main() {
  testWidgets('ResizablePanelDivider Renders and Triggers Drag Events', (WidgetTester tester) async {
    double currentHeight = 190.0;
    int heightChangedCount = 0;
    int doubleTapCount = 0;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  children: [
                    const Expanded(child: SizedBox()),
                    ResizablePanelDivider(
                      currentHeight: currentHeight,
                      minHeight: 100.0,
                      maxHeight: 300.0,
                      onHeightChanged: (newHeight) {
                        setState(() {
                          currentHeight = newHeight;
                          heightChangedCount++;
                        });
                      },
                      onDoubleTap: () {
                        setState(() {
                          currentHeight = 190.0;
                          doubleTapCount++;
                        });
                      },
                    ),
                    SizedBox(height: currentHeight),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );

    // Verify it renders the gesture detector and center handle
    expect(find.byType(ResizablePanelDivider), findsOneWidget);

    // Drag the divider up (should increase the height since dy is negative)
    // GestureDetector is located at ResizablePanelDivider
    final gestureFinder = find.byType(ResizablePanelDivider);
    
    // Simulate vertical drag up
    await tester.drag(gestureFinder, const Offset(0.0, -80.0));
    await tester.pumpAndSettle();

    // Height should have increased
    expect(currentHeight, greaterThan(190.0));
    expect(heightChangedCount, greaterThan(0));

    // Simulate drag up further by a massive offset to hit clamp
    await tester.drag(gestureFinder, const Offset(0.0, -300.0));
    await tester.pumpAndSettle();
    
    // Height should be clamped to 300.0
    expect(currentHeight, equals(300.0));

    // Drag down to shrink height
    await tester.drag(gestureFinder, const Offset(0.0, 80.0));
    await tester.pumpAndSettle();
    
    // Height should decrease
    expect(currentHeight, lessThan(300.0));

    // Drag down past min limit (100) by a massive offset
    await tester.drag(gestureFinder, const Offset(0.0, 400.0));
    await tester.pumpAndSettle();
    
    // Height should clamp to 100.0
    expect(currentHeight, equals(100.0));

    // Double tap the divider to trigger reset
    await tester.tap(gestureFinder);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(gestureFinder);
    await tester.pumpAndSettle();

    // Height should reset back to 190.0
    expect(currentHeight, equals(190.0));
    expect(doubleTapCount, equals(1));
  });
}
