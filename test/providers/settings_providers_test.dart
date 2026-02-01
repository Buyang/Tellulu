
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tellulu/providers/settings_providers.dart';

void main() {
  group('SettingsProviders Entitlements', () {
    late ProviderContainer container;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      container = ProviderContainer(
        overrides: [
          // Override if necessary, but setMockInitialValues should handle the underlying prefs
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('UserSubscription defaults to Free and toggles', () async {
      // 1. Check default
      final sub = await container.read(userSubscriptionProvider.future);
      expect(sub, UserSubscription.free);

      // 2. Toggle
      await container.read(userSubscriptionProvider.notifier).toggleSubscription();
      final sub2 = await container.read(userSubscriptionProvider.future);
      expect(sub2, UserSubscription.pro);
    });

    test('GeminiModelNotifier enforces entitlements', () async {
      final notifier = container.read(geminiModelProvider.notifier);
      final subNotifier = container.read(userSubscriptionProvider.notifier);

      // 1. Upgrade to Pro
      await subNotifier.toggleSubscription();
      await container.read(userSubscriptionProvider.future);
      // Wait for Gemini notifier to rebuild
      await container.read(geminiModelProvider.future);

      // 2. Select a Pro model
      expect(notifier.state.value, 'gemini-2.0-flash');
      expect(await container.read(geminiModelProvider.future), 'gemini-2.0-flash');
      await notifier.setModel('gemini-2.0-flash-exp');
      expect(await container.read(geminiModelProvider.future), 'gemini-2.0-flash-exp');

      // 3. Downgrade to Free
      await subNotifier.toggleSubscription();
      await container.read(userSubscriptionProvider.future);
      // Wait for rebuild (this triggers the entitlement check in build())
      await container.read(geminiModelProvider.future);

      // 4. Verify Model Reset
      // We need to wait for the provider to rebuild/react.
      // Accessing the future should trigger re-evaluation.
      final model = await container.read(geminiModelProvider.future);
      
      // Should strictly reset to 1.5-flash (deprecated) -> 2.0-flash-exp (forced migration)
      expect(model, 'gemini-2.0-flash');
    });
    
    test('StabilityModelNotifier enforces entitlements', () async {
      final notifier = container.read(stabilityModelProvider.notifier);
      final subNotifier = container.read(userSubscriptionProvider.notifier);

      // 1. Upgrade to Pro
      await subNotifier.toggleSubscription();
      // Wait for rebuild
      await container.read(stabilityModelProvider.future);
      
      // 2. Select a Pro model
      await notifier.setModel('stable-diffusion-3-sd3-medium');
      expect(await container.read(stabilityModelProvider.future), 'stable-diffusion-3-sd3-medium');

      // 3. Downgrade
      await subNotifier.toggleSubscription();
      // Wait for rebuild (this triggers the entitlement check in build())
      await container.read(stabilityModelProvider.future);

      // 4. Verify Reset
      final model = await container.read(stabilityModelProvider.future);
      expect(model, 'stable-diffusion-xl-1024-v1-0');
    });
  });
}
