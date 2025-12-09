# Prelude Flutter SDK

Flutter plugin that provides applications easy access to the native Android and iOS Prelude SDKs.

## Getting Started

The Flutter SDK enables your application to capture device signals that are sent to Prelude to enhance the fraud detection process.
It also provides the functionality to allow your application to use the [silent‑verification feature](https://docs.prelude.so/verify/v2/documentation/silent-verification).

Add the SDK to your Flutter application project by declaring it as a dependency in **pubspec.yaml**:

```yaml
dependencies:
  prelude_flutter_sdk: ^[VERSION]   # replace with the latest version
```


> **Important:** You will need the SDK key generated in the [Prelude dashboard](https://app.prelude.so/). The key is shown only once when it is created, so store it securely for later use.

### Capturing Signals

To collect device signals simply create an instance of `PreludeFlutterSdk` and call `dispatchSignals`.
The call returns a `Future<String>` that resolves to a **dispatch ID** which you should forward to your back‑end.

The SDK functions return `Futures` so the snippets listed here wrap them in async functions. Adjust to your code base accordingly.

The most basic usage is as simple as:

```dart
import 'package:prelude_flutter_sdk/prelude_flutter_sdk.dart';

Future<void> collectSignals() async {
  final prelude = PreludeFlutterSdk();

  try {
    final dispatchId = await prelude.dispatchSignals(
      sdkKey: 'sdk_XXXXXXXXXXXXXXXX', // ← your SDK key
    );

    // Send the `dispatchId` to your server so it can
    // be used in verification calls.
    print('Dispatch ID: $dispatchId');
  } catch (e) {
    // Handle errors (e.g., network failure, timeout)
    print('Failed to dispatch signals: $e');
  }
}
```
The SDK allows you to fine-tune some extra arguments depending on your requirements:

```dart
import 'package:prelude_flutter_sdk/prelude_flutter_sdk.dart';

Future<void> collectSignals() async {
  final prelude = PreludeFlutterSdk();

  try {
    final dispatchId = await prelude.dispatchSignals(
      sdkKey: 'sdk_XXXXXXXXXXXXXXXX',    // ← your SDK key
      requestTimeoutMilliseconds: 10000, // optional, defaults to 10 000 ms
      automaticRetryCount: 3,            // optional, defaults to 3 retries with exponential backoff
      implementedFeatures: [],           // required for the silent verification feature
      signalsScope: SignalsScope.full,   // optional, default is `full`, set to `silentVerification`
                                         // when using the silent verification feature
    );

    // Send the `dispatchId` to your server
    // so it can be used in verification calls.
    print('Dispatch ID: $dispatchId');
  } catch (e) {
    print('Failed to dispatch signals: $e');
  }
}
```


> **Tip:** There is no need to keep an instance of the `PreludeFlutterSdk()`object. Instantiate it when needed and call the dispatchSignals function during your onboarding process.

### Silent Verification

If you want to perform silent verification of a phone number, use the `verifySilent` method.

You must first have sent the signals and obtained a `dispatchId`.

When initiating the verification process with your backend, you send the dispatchId with the user's phone number. If silent verification is available for that number, you will get back in the verification response a url that you need to pass to the SDK so that it can proceed with the verification.

```dart
import 'package:prelude_flutter_sdk/prelude_flutter_sdk.dart';

Future<void> performSilentVerification() async {
  final prelude = PreludeFlutterSdk();

  try {
    final dispatchId = await prelude.dispatchSignals(
      sdkKey: 'sdk_XXXXXXXXXXXXXXXX', // ← your SDK key
      implementedFeatures: [Features.silentVerification], // ← required
      signalsScope: SignalsScope.silentVerification       // ← required
    );

    // Start the verification process with your backend
    //  sending the dispatch id and the user's phone number.
    //  You get back a method: silent and a request_url in
    //  the response if silent is available.

    final code = await prelude.verifySilent(
      sdkKey: 'sdk_XXXXXXXXXXXXXXXX', // ← your SDK key
      requestUrl: '[request_url]',    // ← the request_url retrieved
                                      // from your backend
    );

    // If the silent verification is successful you will get back
    //  a code that you need to send to your backend to check and
    //  complete the authentication flow

  } catch (e) {
    // Handle verification errors
    print('Silent verification failed: $e');
  }
}
```


> **Note:** Silent verification requires a server‑side component that forwards the request to Prelude, using the `dispatchId` you collected earlier. See the [Silent Verification documentation](https://docs.prelude.so/verify/silent/overview) for full details.
