// Smoke test : l'application demarre et affiche la barre de navigation.
import 'package:flutter_test/flutter_test.dart';

import 'package:parismap_video_guide/app.dart';

void main() {
  testWidgets('App boots and shows bottom navigation', (tester) async {
    await tester.pumpWidget(const ParisMapApp());
    await tester.pump();

    expect(find.text('Carte'), findsOneWidget);
    expect(find.text('Lieux'), findsOneWidget);
    expect(find.text('Collections'), findsOneWidget);
  });
}
