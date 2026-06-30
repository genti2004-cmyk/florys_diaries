import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:florys_diaries/app/florys_diaries_app.dart';
import 'package:florys_diaries/core/constants/app_metadata.dart';
import 'package:florys_diaries/features/shell/presentation/main_shell_screen.dart';

void main() {
  testWidgets('FlorysDiaries starts', (tester) async {
    await tester.pumpWidget(const FlorysDiariesApp());

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(MainShellScreen), findsOneWidget);

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.title, AppMetadata.name);
  });
}
