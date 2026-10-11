import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voya/features/create/presentation/create_trip_screen.dart';

Widget _app() =>
    const ProviderScope(child: MaterialApp(home: CreateTripScreen()));

void main() {
  testWidgets('a trip needs a name', (tester) async {
    await tester.pumpWidget(_app());
    await tester.ensureVisible(find.text('Create draft'));
    await tester.tap(find.text('Create draft'));
    await tester.pump();

    expect(find.text('Enter a trip name'), findsOneWidget);
  });

  testWidgets('travellers stepper stays within 1 to 50', (tester) async {
    await tester.pumpWidget(_app());
    await tester.ensureVisible(find.byTooltip('More'));

    await tester.tap(find.byTooltip('More'));
    await tester.pump();
    expect(find.text('2'), findsOneWidget);

    await tester.tap(find.byTooltip('Fewer'));
    await tester.pump();
    expect(find.text('1'), findsOneWidget);

    // already at the minimum: the button is disabled
    final fewer = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.remove),
    );
    expect(fewer.onPressed, isNull);
  });

  testWidgets('destinations become chips and can be removed', (tester) async {
    await tester.pumpWidget(_app());

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Destinations'),
      'Diani',
    );
    await tester.tap(find.byTooltip('Add destination'));
    await tester.pump();
    expect(find.widgetWithText(InputChip, 'Diani'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.cancel)); // InputChip delete icon
    await tester.pump();
    expect(find.widgetWithText(InputChip, 'Diani'), findsNothing);
  });
}
