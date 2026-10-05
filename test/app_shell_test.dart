import 'package:flutter_test/flutter_test.dart';
import 'package:voya/app.dart';

void main() {
  testWidgets('renders all five navigation tabs', (tester) async {
    await tester.pumpWidget(const VoyaApp());
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Explore'), findsOneWidget);
    expect(find.text('Create'), findsOneWidget);
    expect(find.text('Saved'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });
}
