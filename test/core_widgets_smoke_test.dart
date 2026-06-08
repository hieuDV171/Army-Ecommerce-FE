import 'package:army_ecommerce/ui/util/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AppButton renders label and handles tap', (tester) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppButton(
            label: 'Kiểm tra',
            onPressed: () {
              tapped = true;
            },
          ),
        ),
      ),
    );

    expect(find.text('Kiểm tra'), findsOneWidget);
    await tester.tap(find.text('Kiểm tra'));
    expect(tapped, isTrue);
  });
}
