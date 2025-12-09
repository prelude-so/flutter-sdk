import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:prelude_flutter_sdk/prelude_flutter_sdk.dart';

import 'prelude_flutter_sdk_platform_interface.dart';

class MethodChannelPreludeFlutterSdk extends PreludeFlutterSdkPlatform {
  @visibleForTesting
  final methodChannel = const MethodChannel('prelude_so_flutter_sdk');

  @override
  Future<String> dispatchSignals({
    required String sdkKey,
    int requestTimeoutMilliseconds = 10000,
    int automaticRetryCount = 3,
    List<Features> implementedFeatures = const [],
    String customEndpointUrl = "",
    SignalsScope signalsScope = SignalsScope.full,
  }) async {
    final args = <String, dynamic>{
      'sdkKey': sdkKey,
      'requestTimeoutMilliseconds': requestTimeoutMilliseconds,
      'automaticRetryCount': automaticRetryCount,
      'implementedFeatures': implementedFeatures.toRawValue(),
      'customEndpointUrl': customEndpointUrl,
      'signalsScope': signalsScope.value,
    };

    String? dispatchIdResult = await methodChannel.invokeMethod<String>('dispatchSignals', args);
    if (dispatchIdResult == null) {
      throw StateError("Dispatch Method Channel failed. Dispatch id is null.");
    } else {
      return dispatchIdResult;
    }
  }

  @override
  Future<String> verifySilent({
    required String sdkKey,
    required String requestUrl,
  }) async {
    final args = <String, dynamic>{
      'sdkKey': sdkKey,
      'requestUrl': requestUrl,
    };

    String? verificationCode = await methodChannel.invokeMethod<String>('verifySilent', args);
    if (verificationCode == null) {
      throw StateError("VerifySilent Method Channel failed. Verification code is null.");
    } else {
      return verificationCode;
    }
  }
}
