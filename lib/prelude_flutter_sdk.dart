import 'prelude_flutter_sdk_platform_interface.dart';

class PreludeFlutterSdk {
  Future<String> dispatchSignals({
    required String sdkKey,
    int requestTimeoutMilliseconds = 10000,
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

enum Features {
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
