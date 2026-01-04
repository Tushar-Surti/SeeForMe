package com.example.seeforme

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/**
 * Placeholder Phi-3 bridge. This avoids runtime crashes until a real llama.cpp
 * integration is added. It accepts loadModel/unloadModel/generateText and
 * returns stubbed values so the Dart side can proceed.
 */
class Phi3Plugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private var isLoaded: Boolean = false

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "com.example.seeforme/phi3")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "loadModel" -> {
                // Pretend to load; just mark as loaded.
                isLoaded = true
                result.success(true)
            }
            "generateText" -> {
                if (!isLoaded) {
                    result.error("NOT_LOADED", "Model not loaded", null)
                    return
                }
                val prompt = call.argument<String>("prompt") ?: ""
                // Minimal placeholder response; replace with real inference.
                val response = if (prompt.isNotBlank()) {
                    "(Placeholder) Description generated for prompt: ${prompt.take(120)}"
                } else {
                    "(Placeholder) No prompt provided."
                }
                result.success(response)
            }
            "unloadModel" -> {
                isLoaded = false
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}
