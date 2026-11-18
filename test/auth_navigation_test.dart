import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:wild_sense/app/routes/app_routes.dart';
import 'package:wild_sense/core/services/auth_service.dart';
import 'package:wild_sense/modules/auth/views/auth_view.dart';

void main() {
  setUp(() {
    Get.testMode = true;
    Get.put<AuthService>(AuthService());
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets('registration is a separate screen with back navigation', (
    tester,
  ) async {
    await tester.pumpWidget(
      GetMaterialApp(
        initialRoute: AppRoutes.login,
        getPages: [
          GetPage(name: AppRoutes.login, page: () => const AuthView()),
          GetPage(
            name: AppRoutes.createAccount,
            page: () => const CreateAccountView(),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('New here?'), findsOneWidget);
    expect(find.text('Create account'), findsOneWidget);
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    expect(find.text('Create your account'), findsOneWidget);
    expect(find.text('Already have an account?'), findsOneWidget);
    await tester.ensureVisible(find.text('Sign in'));
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
  });

  testWidgets('tapping outside auth fields dismisses the keyboard focus', (
    tester,
  ) async {
    await tester.pumpWidget(
      GetMaterialApp(
        initialRoute: AppRoutes.login,
        getPages: [
          GetPage(name: AppRoutes.login, page: () => const AuthView()),
        ],
      ),
    );
    await tester.pumpAndSettle();

    final editableTextFinder = find.descendant(
      of: find.byType(TextFormField).first,
      matching: find.byType(EditableText),
    );
    final focusNode = tester.widget<EditableText>(editableTextFinder).focusNode;
    await tester.tap(find.byType(TextFormField).first);
    await tester.pump();
    expect(focusNode.hasFocus, isTrue);

    await tester.tap(find.text('Welcome back'));
    await tester.pump();
    expect(focusNode.hasFocus, isFalse);
  });
}
