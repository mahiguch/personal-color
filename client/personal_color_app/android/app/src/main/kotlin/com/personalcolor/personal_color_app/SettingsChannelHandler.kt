package com.personalcolor.personal_color_app

import android.content.Intent
import android.net.Uri
import android.provider.Settings
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class SettingsChannelHandler(private val flutterEngine: FlutterEngine, private val activity: FlutterActivity) {
    private val channelName = "android/settings"
    private var methodChannel: MethodChannel? = null

    fun setupMethodChannel() {
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
        methodChannel?.setMethodCallHandler { call, result ->
            handleMethodCall(call, result)
        }
    }

    private fun handleMethodCall(@NonNull call: MethodCall, @NonNull result: MethodChannel.Result) {
        when (call.method) {
            "openAppSettings" -> {
                openAppSettings(result)
            }
            "openPermissionSettings" -> {
                openPermissionSettings(result)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun openAppSettings(result: MethodChannel.Result) {
        try {
            val intent = Intent().apply {
                action = Settings.ACTION_APPLICATION_DETAILS_SETTINGS
                data = Uri.fromParts("package", activity.packageName, null)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }

            activity.startActivity(intent)
            result.success(true)
        } catch (e: Exception) {
            result.error("SETTINGS_ERROR", "Failed to open app settings: ${e.message}", e)
        }
    }

    private fun openPermissionSettings(result: MethodChannel.Result) {
        try {
            val intent = Intent().apply {
                action = Settings.ACTION_APPLICATION_DETAILS_SETTINGS
                data = Uri.fromParts("package", activity.packageName, null)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }

            activity.startActivity(intent)
            result.success(true)
        } catch (e: Exception) {
            result.error("PERMISSION_SETTINGS_ERROR", "Failed to open permission settings: ${e.message}", e)
        }
    }

    fun dispose() {
        methodChannel?.setMethodCallHandler(null)
        methodChannel = null
    }
}