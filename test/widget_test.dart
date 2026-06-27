import 'package:flutter_test/flutter_test.dart';
import 'package:florys_diaries/app/florys_diaries_app.dart';

void main() {
  testWidgets('FlorysDiaries starts', (tester) async {
    await tester.pumpWidget(const FlorysDiariesApp());
    expect(find.text('FlorysDiaries'), findsOneWidget);
  });
}
