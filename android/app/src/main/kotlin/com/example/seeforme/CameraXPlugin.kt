package com.example.seeforme

import android.Manifest
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
import io.flutter.plugin.common.PluginRegistry
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import android.content.pm.PackageManager
import android.app.Activity
import java.io.File

class CameraXPlugin: FlutterPlugin, MethodCallHandler, ActivityAware, PluginRegistry.RequestPermissionsResultListener {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private var cameraHelper: CameraXHelper? = null
    private var lifecycleOwner: LifecycleOwner? = null
    private var activityBinding: ActivityPluginBinding? = null
    private var pendingResult: Result? = null
    private var pendingStart: Boolean = false
    private var activity: Activity? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "com.example.seeforme/camera")
        channel.setMethodCallHandler(this)
        context = binding.applicationContext
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "startCamera" -> {
                if (lifecycleOwner == null || activity == null) {
                    result.error("UNAVAILABLE", "Activity not available", null)
                    return
                }

                if (!hasCameraPermission()) {
                    pendingResult = result
                    pendingStart = true
                    requestCameraPermission()
                    return
                }

                startCameraCapture(result)
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
        lifecycleOwner = binding.activity as? LifecycleOwner ?: CustomLifecycleOwner()
        activityBinding = binding
        activity = binding.activity
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        lifecycleOwner = null
        activityBinding?.removeRequestPermissionsResultListener(this)
        activityBinding = null
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        lifecycleOwner = CustomLifecycleOwner()
        activityBinding = binding
        activity = binding.activity
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onDetachedFromActivity() {
        lifecycleOwner = null
        activityBinding?.removeRequestPermissionsResultListener(this)
        activityBinding = null
        activity = null
    }

    private fun hasCameraPermission(): Boolean {
        val currentActivity = activity ?: return false
        return ContextCompat.checkSelfPermission(currentActivity, Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED
    }

    private fun requestCameraPermission() {
        val currentActivity = activity ?: return
        ActivityCompat.requestPermissions(currentActivity, arrayOf(Manifest.permission.CAMERA), REQUEST_CAMERA_PERMISSION)
    }

    private fun startCameraCapture(result: Result) {
        if (lifecycleOwner == null) {
            result.error("UNAVAILABLE", "Lifecycle not available", null)
            return
        }

        cameraHelper = CameraXHelper(context)
        cameraHelper?.startCamera(lifecycleOwner!!) { file ->
            channel.invokeMethod("onImageCaptured", file.absolutePath)
        }
        result.success(null)
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<String>, grantResults: IntArray): Boolean {
        if (requestCode != REQUEST_CAMERA_PERMISSION) return false

        val granted = grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
        val result = pendingResult
        pendingResult = null

        if (granted) {
            if (pendingStart && result != null) {
                pendingStart = false
                startCameraCapture(result)
            }
        } else {
            result?.error("PERMISSION_DENIED", "Camera permission denied", null)
        }

        return true
    }

    companion object {
        private const val REQUEST_CAMERA_PERMISSION = 1001
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