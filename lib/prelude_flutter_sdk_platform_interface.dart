import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:prelude_flutter_sdk/prelude_flutter_sdk.dart';

import 'prelude_flutter_sdk_method_channel.dart';

abstract class PreludeFlutterSdkPlatform extends PlatformInterface {
  PreludeFlutterSdkPlatform() : super(token: _token);

  static final Object _token = Object();

  static PreludeFlutterSdkPlatform _instance = MethodChannelPreludeFlutterSdk();

  static PreludeFlutterSdkPlatform get instance => _instance;

  static set instance(PreludeFlutterSdkPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String> dispatchSignals({
    required String sdkKey,
    int requestTimeoutMilliseconds,
    int automaticRetryCount,
    List<Features> implementedFeatures,
    String customEndpointUrl,
    SignalsScope signalsScope,
  });

  Future<String> verifySilent({
    required String sdkKey,
    required String requestUrl,
  });
}
