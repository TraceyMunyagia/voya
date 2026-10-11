import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voya/core/constants/enums.dart';
import 'package:voya/data/models/item_link.dart';
import 'package:voya/features/trips/presentation/widgets/cost_field.dart';
import 'package:voya/features/trips/presentation/widgets/links_editor.dart';
import 'package:voya/features/trips/presentation/widgets/rating_field.dart';

Widget _wrap(Widget child) => MaterialApp(
      theme: ThemeData(useMaterial3: true),
      home: Scaffold(body: SingleChildScrollView(child: Form(child: child))),
    );

void main() {
  testWidgets('CostField shows the total and per person, and hides them when free', (tester) async {
    final amount = TextEditingController(text: '1500');
    var basis = CostBasis.perPerson;

    Widget field() => _wrap(CostField(
          amount: amount,
          basis: basis,
          allowedBases: const [CostBasis.perPerson, CostBasis.free],
          currency: 'KES',
          total: 6000,
          perPerson: 1500,
          onBasisChanged: (_) {},
        ));

    await tester.pumpWidget(field());
    expect(find.text('Total KSh 6,000 · KSh 1,500 per person'), findsOneWidget);

    basis = CostBasis.free;
    await tester.pumpWidget(field());
    expect(find.text('Free'), findsWidgets);
    expect(find.textContaining('Total KSh'), findsNothing);
  });

  testWidgets('LinksEditor adds a normalised link with the preset label', (tester) async {
    var links = <ItemLink>[];
    await tester.pumpWidget(_wrap(LinksEditor(links: links, onChanged: (l) => links = l)));

    await tester.tap(find.text('Add link'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'Web address'), 'diani.com/book');
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    expect(links.length, 1);
    expect(links.first.label, 'Booking');
    expect(links.first.url, 'https://diani.com/book');
  });

  testWidgets('LinksEditor rejects a bad address', (tester) async {
    var links = <ItemLink>[];
    await tester.pumpWidget(_wrap(LinksEditor(links: links, onChanged: (l) => links = l)));

    await tester.tap(find.text('Add link'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Web address'), 'hello');
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a valid web address'), findsOneWidget);
    expect(links, isEmpty);
  });

  testWidgets('RatingField sets a rating and clears it on a second tap', (tester) async {
    int? value;
    await tester.pumpWidget(StatefulBuilder(
      builder: (context, setState) => _wrap(
        RatingField(value: value, onChanged: (v) => setState(() => value = v)),
      ),
    ));

    await tester.tap(find.byTooltip('4 stars'));
    await tester.pump();
    expect(value, 4);

    await tester.tap(find.byTooltip('4 stars'));
    await tester.pump();
    expect(value, isNull);
  });
}