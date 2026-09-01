import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mountain_club_photo/main.dart';

void main() {
  testWidgets('App launches and shows camera screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MountainClubPhotoApp());
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
