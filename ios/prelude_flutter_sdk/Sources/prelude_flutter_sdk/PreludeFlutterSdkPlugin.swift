import Flutter
import UIKit
#if SWIFT_PACKAGE
import Prelude
#endif

public class PreludeFlutterSdkPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "prelude_so_flutter_sdk", binaryMessenger: registrar.messenger())
        let instance = PreludeFlutterSdkPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any] else {
            result(FlutterError(code: "1", message: "Initialization error", details: "Empty arguments list."))
            return
        }

        switch call.method {
        case "dispatchSignals":
            dispatchSignals(args: args, result: result)
        case "verifySilent":
            verifySilent(args: args, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func dispatchSignals(args: [String: Any], result: @escaping FlutterResult) {
        do {
            let configuration = try buildDispatchSignalsConfiguration(args: args)
            let signalsScope = buildSignalsScope(args: args)

            Task {
                do {
                    let dispatchId = try await Prelude(configuration).dispatchSignals(scope: signalsScope)
                    DispatchQueue.main.async {
                        result(dispatchId)
                    }
                } catch {
                    DispatchQueue.main.async {
                        result(
                            FlutterError(
                                code: "2",
                                message: "Dispatch signals error",
                                details: error.localizedDescription
                            )
                        )
                    }
                }
            }
        } catch {
            result(FlutterError(code: "3", message: "Illegal arguments", details: error.localizedDescription))
        }
    }

    private func buildDispatchSignalsConfiguration(args: [String: Any]) throws -> Configuration {
        guard let sdkKey = args["sdkKey"] as? String, !sdkKey.isEmpty else {
            throw PluginError.illegalArgument("SDK key cannot be blank.")
        }

        guard let requestTimeoutMilliseconds = args["requestTimeoutMilliseconds"] as? Int,
              requestTimeoutMilliseconds > 0 else {
            throw PluginError.illegalArgument("Request timeout must be greater than zero.")
        }

        let timeout = TimeInterval(requestTimeoutMilliseconds) / 1000.0
        let maxRetries = max((args["automaticRetryCount"] as? Int) ?? 1, 1)
        let implementedFeaturesRaw = (args["implementedFeatures"] as? Int) ?? 0
        let implementedFeatures = Features(rawValue: UInt64(implementedFeaturesRaw))

        let endpointArg = (args["customEndpointUrl"] as? String) ?? ""
        let endpoint: Endpoint = endpointArg.isEmpty ? .default : .custom(endpointArg)

        return Configuration(
            sdkKey: sdkKey,
            endpoint: endpoint,
            implementedFeatures: implementedFeatures,
            timeout: timeout,
            maxRetries: maxRetries
        )
    }

    private func buildSignalsScope(args: [String: Any]) -> SignalsScope {
        guard let scopeArg = args["signalsScope"] as? Int else {
         return .full // default when not provided
        }
        switch scopeArg {
        case 1:
            return .full
        case 2:
            return .silentVerification
        default:
            return .full // return default for invalid values to match Android behavior
        }
    }

    private func verifySilent(args: [String: Any], result: @escaping FlutterResult) {
        do {
            guard let sdkKey = args["sdkKey"] as? String, !sdkKey.isEmpty else {
                throw PluginError.illegalArgument("SDK key cannot be blank.")
            }

            guard let requestUrlString = args["requestUrl"] as? String, !requestUrlString.isEmpty else {
                throw PluginError.illegalArgument("Request URL cannot be blank.")
            }

            guard let requestUrl = URL(string: requestUrlString) else {
                throw PluginError.illegalArgument("Request URL is invalid.")
            }

            let prelude = Prelude(sdkKey: sdkKey)

            Task {
                do {
                    let verifyResult = try await prelude.verifySilent(url: requestUrl)
                    DispatchQueue.main.async {
                        result(verifyResult)
                    }
                } catch {
                    DispatchQueue.main.async {
                        result(
                            FlutterError(
                                code: "4",
                                message: "Silent Verification error",
                                details: error.localizedDescription
                            )
                        )
                    }
                }
            }
        } catch {
            result(FlutterError(code: "3", message: "Illegal arguments", details: error.localizedDescription))
        }
    }
}

private enum PluginError: LocalizedError {
    case illegalArgument(String)

    var errorDescription: String? {
        switch self {
        case .illegalArgument(let message):
            return message
        }
    }
}
