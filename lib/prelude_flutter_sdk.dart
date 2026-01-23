import 'prelude_flutter_sdk_platform_interface.dart';

/// The main entry point for the Prelude Flutter SDK.
///
/// This SDK provides applications with easy access to device signal collection
/// and silent verification capabilities to enhance fraud detection.
class PreludeFlutterSdk {
  /// Collects and dispatches device signals to Prelude for fraud detection.
  ///
  /// This method captures device signals and sends them to Prelude's servers.
  /// The returned dispatch ID should be forwarded to your backend and included
  /// in verification API calls.
  ///
  /// Example:
  /// ```dart
  /// final prelude = PreludeFlutterSdk();
  /// final dispatchId = await prelude.dispatchSignals(
  ///   sdkKey: 'sdk_XXXXXXXXXXXXXXXX',
  /// );
  /// // Send dispatchId to your backend
  /// ```
  ///
  /// Parameters:
  /// - [sdkKey]: Your Prelude SDK key from the dashboard (required)
  /// - [requestTimeoutMilliseconds]: Network request timeout in milliseconds (default: 5000)
  /// - [automaticRetryCount]: Number of automatic retries in case of server error (default: 3)
  /// - [implementedFeatures]: List of features implemented in your app (e.g., [Features.silentVerification])
  ///
  /// Returns a [Future] that resolves to a dispatch ID string.
  ///
  /// Throws an exception if the request fails due to network issues, timeout, or invalid credentials.
  Future<String> dispatchSignals({
    required String sdkKey,
    int requestTimeoutMilliseconds = 5000,
    int automaticRetryCount = 3,
    List<Features> implementedFeatures = const [],
    String customEndpointUrl = "",
    SignalsScope signalsScope = SignalsScope.full,
  }) {
    return PreludeFlutterSdkPlatform.instance.dispatchSignals(
      sdkKey: sdkKey,
      requestTimeoutMilliseconds: requestTimeoutMilliseconds,
      automaticRetryCount: automaticRetryCount,
      implementedFeatures: implementedFeatures,
      customEndpointUrl: customEndpointUrl,
      signalsScope: signalsScope,
    );
  }

  /// Performs silent verification of a phone number using carrier network detection.
  ///
  /// This method should be called after [dispatchSignals] and receiving a verification
  /// response from your backend that includes a `requestUrl` for silent verification.
  ///
  /// Silent verification allows verification of phone numbers without requiring SMS codes
  /// by leveraging carrier network capabilities.
  ///
  /// Example workflow:
  /// ```dart
  /// final prelude = PreludeFlutterSdk();
  ///
  /// // 1. Dispatch signals first
  /// final dispatchId = await prelude.dispatchSignals(
  ///   sdkKey: 'sdk_XXXXXXXXXXXXXXXX',
  ///   implementedFeatures: [Features.silentVerification],
  /// );
  ///
  /// // 2. Send dispatchId to your backend to initiate verification
  /// // 3. Receive requestUrl from your backend's verification response
  ///
  /// // 4. Complete silent verification
  /// final code = await prelude.verifySilent(
  ///   sdkKey: 'sdk_XXXXXXXXXXXXXXXX',
  ///   requestUrl: requestUrl,
  /// );
  /// // Send code to your backend to complete verification
  /// ```
  ///
  /// Parameters:
  /// - [sdkKey]: Your Prelude SDK key from the dashboard (required)
  /// - [requestUrl]: The URL received from your backend's verification response (required)
  ///
  /// Returns a [Future] that resolves to a verification code string.
  ///
  /// Throws an exception if the verification fails.
  Future<String> verifySilent({
    required String sdkKey,
    required String requestUrl,
  }) {
    return PreludeFlutterSdkPlatform.instance.verifySilent(
      sdkKey: sdkKey,
      requestUrl: requestUrl,
    );
  }
}

/// Features that can be implemented in your application.
///
/// Use this enum to indicate which Prelude features your app supports
/// when calling [PreludeFlutterSdk.dispatchSignals].
enum Features {
  /// Indicates that your app implements silent verification.
  ///
  /// Include this in the [PreludeFlutterSdk.dispatchSignals] call when using
  /// the [PreludeFlutterSdk.verifySilent] method.
  silentVerification(1 << 0);

  final int value;

  const Features(this.value);

  static List<Features> fromRawValue(int rawValue) {
    return Features.values
        .where((feature) => (rawValue & feature.value) != 0)
        .toList();
  }
}

extension FeaturesListExtension on List<Features> {
  int toRawValue() {
    return fold(0, (acc, feature) => acc | feature.value);
  }
}

enum SignalsScope {
  full(1),
  silentVerification(2);

  final int value;

  const SignalsScope(this.value);
}
