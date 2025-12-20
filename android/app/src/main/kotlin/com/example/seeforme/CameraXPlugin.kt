package com.example.seeforme

import android.content.Context
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleOwner
import androidx.lifecycle.LifecycleRegistry
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.File

class CameraXPlugin: FlutterPlugin, MethodCallHandler, ActivityAware {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private var cameraHelper: CameraXHelper? = null
    private var lifecycleOwner: CustomLifecycleOwner? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "com.example.seeforme/camera")
        channel.setMethodCallHandler(this)
        context = binding.applicationContext
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "startCamera" -> {
                if (lifecycleOwner == null) {
                    result.error("UNAVAILABLE", "Activity not available", null)
                    return
                }

                cameraHelper = CameraXHelper(context)
                cameraHelper?.startCamera(lifecycleOwner!!) { file ->
                    channel.invokeMethod("onImageCaptured", file.absolutePath)
                }
                result.success(null)
            }
            "stopCamera" -> {
                cameraHelper?.shutdown()
                cameraHelper = null
                result.success(null)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        lifecycleOwner = CustomLifecycleOwner()
    }

    override fun onDetachedFromActivityForConfigChanges() {
        lifecycleOwner = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        lifecycleOwner = CustomLifecycleOwner()
    }

    override fun onDetachedFromActivity() {
        lifecycleOwner = null
    }
}

class CustomLifecycleOwner : LifecycleOwner {
    private val lifecycleRegistry: LifecycleRegistry = LifecycleRegistry(this)

    init {
        lifecycleRegistry.currentState = Lifecycle.State.RESUMED
    }

    override val lifecycle: Lifecycle
        get() = lifecycleRegistry
} 