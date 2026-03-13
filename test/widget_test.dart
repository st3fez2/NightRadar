import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nightradar/core/widgets/common_widgets.dart';
import 'package:nightradar/features/auth/auth_screen.dart';

void main() {
  testWidgets('auth screen exposes demo accounts', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: AuthScreen(),
        ),
      ),
    );

    expect(find.text('NightRadar MVP'), findsOneWidget);
    expect(find.textContaining('user@nightradar.app'), findsOneWidget);
    expect(find.textContaining('promoter@nightradar.app'), findsOneWidget);
    expect(find.textContaining('venue@nightradar.app'), findsNothing);
    expect(find.textContaining('staff@nightradar.app'), findsNothing);
  });

  testWidgets('radar chip formats label for UI', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: RadarChip(label: 'near_full'),
        ),
      ),
    );

    expect(find.text('NEAR FULL'), findsOneWidget);
  });
}
