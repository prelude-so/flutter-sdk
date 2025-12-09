package so.prelude.fluttersdk

import android.content.Context
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import so.prelude.android.sdk.Configuration
import so.prelude.android.sdk.Endpoint
import so.prelude.android.sdk.Features
import so.prelude.android.sdk.Prelude
import so.prelude.android.sdk.signals.SignalsScope
import java.net.URL

/** PreludeFlutterSdkPlugin */
class PreludeFlutterSdkPlugin :
    FlutterPlugin,
    MethodCallHandler {
    private lateinit var channel: MethodChannel
    private val scope: CoroutineScope = CoroutineScope(SupervisorJob() + Dispatchers.Default)

    @Volatile
    private var androidContext: Context? = null

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "prelude_so_flutter_sdk")
        channel.setMethodCallHandler(this)
        androidContext = flutterPluginBinding.applicationContext
    }

    override fun onMethodCall(
        call: MethodCall,
        result: Result,
    ) {
        androidContext?.let { context ->
            val args =
                call.arguments as? Map<*, *> ?: run {
                    result.error("1", "Initialization error", "Empty arguments list.")
                    return
                }
            when (call.method) {
                "dispatchSignals" -> dispatchSignals(context, args, result)
                "verifySilent" -> verifySilent(context, args, result)
                else -> result.notImplemented()
            }
        } ?: result.error("1", "Initialization error", "Invalid Android context.")
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        scope.cancel()
        androidContext = null
    }

    private fun dispatchSignals(
        context: Context,
        args: Map<*, *>,
        result: Result,
    ) {
        try {
            val configuration = buildDispatchSignalsConfiguration(context, args)
            val scopeArg = args["signalsScope"] as? Int ?: SignalsScope.FULL.value
            val signalsScope = SignalsScope.from(scopeArg)
            scope.launch(Dispatchers.IO) {
                Prelude(configuration)
                    .dispatchSignals(signalsScope = signalsScope)
                    .mapCatching { dispatchResult ->
                        if (isActive) {
                            result.uiSuccess(dispatchResult)
                        }
                    }.onFailure { e ->
                        if (isActive) {
                            result.uiError("2", "Dispatch signals error", e.message)
                        }
                    }
            }
        } catch (e: Exception) {
            result.error("3", "Illegal arguments", e.message)
        }
    }

    private fun buildDispatchSignalsConfiguration(
        context: Context,
        args: Map<*, *>,
    ): Configuration {
        val sdkKey = args["sdkKey"] as String
        require(sdkKey.isNotBlank()) { "SDK key cannot be blank." }
        val requestTimeoutMilliseconds = (args["requestTimeoutMilliseconds"] as Int).toLong()
        require(requestTimeoutMilliseconds > 0) { "Request timeout must be greater than zero." }
        val maxRetries = (args["automaticRetryCount"] as Int).coerceAtLeast(1)
        val implementedFeatures = Features.fromRawValue((args["implementedFeatures"] as Int).toLong())
        val endpointArg = (args["customEndpointUrl"] as String?) ?: ""
        val endpoint = if (endpointArg.isBlank()) Endpoint.Default else Endpoint.Custom(endpointArg)

        return Configuration(
            context = context,
            sdkKey = sdkKey,
            requestTimeout = requestTimeoutMilliseconds,
            maxRetries = maxRetries,
            implementedFeatures = implementedFeatures,
            endpoint = endpoint,
        )
    }

    private fun verifySilent(
        context: Context,
        args: Map<*, *>,
        result: Result,
    ) {
        try {
            val sdkKey = args["sdkKey"] as String
            require(sdkKey.isNotBlank()) { "SDK key cannot be blank." }
            val requestUrl = URL(args["requestUrl"] as String)
            scope.launch(Dispatchers.IO) {
                Prelude(context, sdkKey)
                    .verifySilent(requestUrl)
                    .mapCatching { verifyResult ->
                        if (isActive) {
                            result.uiSuccess(verifyResult)
                        }
                    }.onFailure { e ->
                        if (isActive) {
                            result.uiError("4", "Silent Verification error", e.message)
                        }
                    }
            }
        } catch (e: Exception) {
            result.error("3", "Illegal arguments", e.message)
        }
    }

    private suspend fun Result.uiSuccess(arg: Any) {
        withContext(Dispatchers.Main) {
            success(arg)
        }
    }

    private suspend fun Result.uiError(
        code: String,
        message: String,
        extra: String?,
    ) {
        withContext(Dispatchers.Main) {
            error(code, message, extra)
        }
    }
}
