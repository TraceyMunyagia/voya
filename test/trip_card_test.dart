import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voya/core/constants/enums.dart';
import 'package:voya/data/models/app_user.dart';
import 'package:voya/data/models/trip.dart';
import 'package:voya/data/models/trip_member.dart';
import 'package:voya/features/trips/presentation/widgets/trip_card.dart';

Trip _trip({int creators = 4}) {
  const people = ['Tracey', 'Mary', 'Ann', 'Joy'];
  return Trip(
    id: 't1',
    ownerId: 'u0',
    title: 'Diani Girls Trip',
    destinations: const ['Diani Beach', 'Wasini Island'],
    startDate: DateTime(2026, 12, 1),
    endDate: DateTime(2026, 12, 4),
    travellers: 4,
    type: TripType.friends,
    status: TripStatus.published,
    costPerPerson: 21125,
    likeCount: 12,
    members: [
      for (var i = 0; i < creators; i++)
        TripMember(
          tripId: 't1',
          userId: 'u$i',
          role: i == 0 ? MemberRole.owner : MemberRole.coCreator,
          profile: AppUser(id: 'u$i', displayName: people[i]),
        ),
    ],
  );
}

Widget _wrap(Widget child) => MaterialApp(
  theme: ThemeData(useMaterial3: true),
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

void main() {
  testWidgets(
    'shows title, destinations, days, travellers, cost and creators',
    (tester) async {
      await tester.pumpWidget(_wrap(TripCard(trip: _trip())));

      expect(find.text('Diani Girls Trip'), findsOneWidget);
      expect(find.text('Diani Beach · Wasini Island'), findsOneWidget);
      expect(find.text('4 days'), findsOneWidget);
      expect(find.text('4 travellers'), findsOneWidget);
      expect(find.textContaining('KSh 21,125'), findsOneWidget);
      expect(find.text('Tracey, Mary +2'), findsOneWidget);
      expect(find.text('Friends'), findsOneWidget);
    },
  );

  testWidgets('Follow only appears for a single creator', (tester) async {
    await tester.pumpWidget(
      _wrap(TripCard(trip: _trip(creators: 4), onFollow: () {})),
    );
    expect(find.text('Follow'), findsNothing);

    await tester.pumpWidget(
      _wrap(TripCard(trip: _trip(creators: 1), onFollow: () {})),
    );
    expect(find.text('Follow'), findsOneWidget);
    expect(find.text('Tracey'), findsOneWidget);
  });

  testWidgets('action callbacks fire', (tester) async {
    var liked = 0, saved = 0, shared = 0;
    await tester.pumpWidget(
      _wrap(
        TripCard(
          trip: _trip(),
          onLike: () => liked++,
          onSave: () => saved++,
          onShare: () => shared++,
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('like')));
    await tester.tap(find.byKey(const ValueKey('save')));
    await tester.tap(find.byKey(const ValueKey('share')));

    expect([liked, saved, shared], [1, 1, 1]);
  });
}
