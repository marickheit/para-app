import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:para_workspace/domain/workspace.dart';
import 'package:para_workspace/ui/entry_actions.dart';
import 'package:para_workspace/ui/file_drop.dart';

void main() {
  testWidgets('nested drop regions choose one precise destination', (
    tester,
  ) async {
    final controller = WorkspaceDropController();
    Widget region(String id, int priority, Widget child) => WorkspaceDropRegion(
      id: id,
      controller: controller,
      destination: DropDestination(ParaSection.inbox, id, 'Ziel $id'),
      priority: priority,
      canMove: (_, _) => true,
      onMove: (_, _) async {},
      child: child,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: region(
              'project',
              0,
              SizedBox(
                width: 500,
                height: 400,
                child: Stack(
                  children: [
                    Positioned(
                      left: 25,
                      top: 30,
                      width: 150,
                      height: 70,
                      child: region(
                        'folder',
                        40,
                        const ColoredBox(
                          key: ValueKey('folder-target'),
                          color: Colors.transparent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    final point = tester.getCenter(find.byKey(const ValueKey('folder-target')));
    expect(controller.at(point)!.parentId, 'folder');
    expect(controller.at(const Offset(350, 200))!.parentId, 'project');
    controller.hover(point);
    await tester.pump();
    expect(find.text('Ziel folder'), findsOneWidget);
    expect(find.text('Ziel project'), findsNothing);
    controller.clear();
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });

  testWidgets('offscreen rows cannot receive drops through a scroll clip', (
    tester,
  ) async {
    final controller = WorkspaceDropController();
    final scroll = ScrollController(initialScrollOffset: 40);
    Widget region(String id, int priority, Widget child) => WorkspaceDropRegion(
      id: id,
      controller: controller,
      destination: DropDestination(ParaSection.inbox, id, id),
      priority: priority,
      canMove: (_, _) => true,
      onMove: (_, _) async {},
      child: child,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: region(
              'background',
              0,
              SizedBox(
                width: 400,
                height: 300,
                child: Column(
                  children: [
                    const SizedBox(height: 100),
                    SizedBox(
                      height: 80,
                      child: ListView(
                        controller: scroll,
                        padding: EdgeInsets.zero,
                        children: [
                          region(
                            'clipped',
                            40,
                            const SizedBox(height: 160, child: Text('Eintrag')),
                          ),
                          const SizedBox(height: 160),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    expect(controller.at(const Offset(20, 90))!.parentId, 'background');
    expect(controller.at(const Offset(20, 120))!.parentId, 'clipped');
    await tester.pumpWidget(const SizedBox.shrink());
    scroll.dispose();
    controller.dispose();
  });

  testWidgets('secondary click and overflow menu present identical actions', (
    tester,
  ) async {
    const actions = [
      EntryAction('copy', 'Link kopieren'),
      EntryAction('archive', 'Archivieren'),
    ];
    String? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: EntryContextMenu(
              actions: actions,
              onSelected: (value) async => selected = value,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Datei'),
                  PopupMenuButton<String>(
                    key: const ValueKey('overflow'),
                    itemBuilder: (_) => actionMenuItems(actions),
                    onSelected: (value) => selected = value,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tapAt(
      tester.getCenter(find.text('Datei')),
      buttons: kSecondaryMouseButton,
      kind: PointerDeviceKind.mouse,
    );
    await tester.pumpAndSettle();
    final contextActions = tester
        .widgetList<PopupMenuItem<String>>(find.byType(PopupMenuItem<String>))
        .map((e) => e.value)
        .toList();
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('overflow')));
    await tester.pumpAndSettle();
    final overflowActions = tester
        .widgetList<PopupMenuItem<String>>(find.byType(PopupMenuItem<String>))
        .map((e) => e.value)
        .toList();
    expect(contextActions, ['copy', 'archive']);
    expect(overflowActions, contextActions);
    await tester.tap(find.text('Archivieren'));
    await tester.pumpAndSettle();
    expect(selected, 'archive');
  });
}
