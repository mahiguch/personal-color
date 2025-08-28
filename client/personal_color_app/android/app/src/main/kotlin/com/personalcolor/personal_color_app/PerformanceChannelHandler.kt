package com.personalcolor.personal_color_app

import android.app.ActivityManager
import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.os.Debug
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import kotlin.math.min

class PerformanceChannelHandler(private val flutterEngine: FlutterEngine, private val activity: FlutterActivity) {
    private val channelName = "android/performance"
    private var methodChannel: MethodChannel? = null

    fun setupMethodChannel() {
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
        methodChannel?.setMethodCallHandler { call, result ->
            handleMethodCall(call, result)
        }
    }

    private fun handleMethodCall(@NonNull call: MethodCall, @NonNull result: MethodChannel.Result) {
        when (call.method) {
            "triggerGC" -> triggerGC(result)
            "optimizeBattery" -> optimizeBattery(result)
            "optimizeCPU" -> optimizeCPU(result)
            "optimizeImage" -> optimizeImage(call, result)
            "optimizeNetwork" -> optimizeNetwork(result)
            "getPerformanceMetrics" -> getPerformanceMetrics(result)
            "cleanup" -> cleanup(result)
            else -> result.notImplemented()
        }
    }

    private fun triggerGC(result: MethodChannel.Result) {
        try {
            System.gc()
            System.runFinalization()
            result.success(true)
        } catch (e: Exception) {
            result.error("GC_ERROR", "Failed to trigger GC: ${e.message}", e)
        }
    }

    private fun optimizeBattery(result: MethodChannel.Result) {
        try {
            // バッテリー使用量最適化の実装
            // 実際の最適化処理はここに実装
            result.success(true)
        } catch (e: Exception) {
            result.error("BATTERY_OPTIMIZATION_ERROR", "Failed to optimize battery: ${e.message}", e)
        }
    }

    private fun optimizeCPU(result: MethodChannel.Result) {
        try {
            // CPU使用量最適化の実装
            // 実際の最適化処理はここに実装
            result.success(true)
        } catch (e: Exception) {
            result.error("CPU_OPTIMIZATION_ERROR", "Failed to optimize CPU: ${e.message}", e)
        }
    }

    private fun optimizeImage(call: MethodCall, result: MethodChannel.Result) {
        try {
            val imageData = call.argument<ByteArray>("imageData")
            val maxWidth = call.argument<Int>("maxWidth") ?: 1024
            val maxHeight = call.argument<Int>("maxHeight") ?: 1024
            val quality = call.argument<Int>("quality") ?: 85

            if (imageData == null) {
                result.error("INVALID_ARGUMENT", "imageData is required", null)
                return
            }

            val optimizedData = processImage(imageData, maxWidth, maxHeight, quality)
            result.success(optimizedData)
        } catch (e: Exception) {
            result.error("IMAGE_OPTIMIZATION_ERROR", "Failed to optimize image: ${e.message}", e)
        }
    }

    private fun processImage(
        imageData: ByteArray,
        maxWidth: Int,
        maxHeight: Int,
        quality: Int
    ): ByteArray {
        // 元の画像をデコード
        val originalBitmap = BitmapFactory.decodeByteArray(imageData, 0, imageData.size)
            ?: throw IllegalArgumentException("Invalid image data")

        // リサイズ計算
        val originalWidth = originalBitmap.width
        val originalHeight = originalBitmap.height
        
        val scale = min(
            maxWidth.toFloat() / originalWidth,
            maxHeight.toFloat() / originalHeight
        )

        val newWidth = (originalWidth * scale).toInt()
        val newHeight = (originalHeight * scale).toInt()

        // リサイズ実行
        val resizedBitmap = if (scale < 1.0f) {
            Bitmap.createScaledBitmap(originalBitmap, newWidth, newHeight, true)
        } else {
            originalBitmap
        }

        // JPEG圧縮
        val outputStream = ByteArrayOutputStream()
        resizedBitmap.compress(Bitmap.CompressFormat.JPEG, quality, outputStream)
        
        // リソースクリーンアップ
        if (resizedBitmap != originalBitmap) {
            resizedBitmap.recycle()
        }
        originalBitmap.recycle()

        return outputStream.toByteArray()
    }

    private fun optimizeNetwork(result: MethodChannel.Result) {
        try {
            // ネットワーク最適化の実装
            // 実際の最適化処理はここに実装
            result.success(true)
        } catch (e: Exception) {
            result.error("NETWORK_OPTIMIZATION_ERROR", "Failed to optimize network: ${e.message}", e)
        }
    }

    private fun getPerformanceMetrics(result: MethodChannel.Result) {
        try {
            val context = activity.applicationContext

            val activityManager = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
            val memInfo = ActivityManager.MemoryInfo()
            activityManager.getMemoryInfo(memInfo)

            // メモリ使用量の計算
            val totalMemory = memInfo.totalMem
            val availableMemory = memInfo.availMem
            val usedMemory = totalMemory - availableMemory
            val memoryUsagePercent = usedMemory.toDouble() / totalMemory.toDouble()

            // Dalvik ヒープ情報
            val dalvikHeapSize = Debug.getNativeHeapSize()
            val dalvikHeapUsed = Debug.getNativeHeapAllocatedSize()
            val dalvikHeapFree = Debug.getNativeHeapFreeSize()

            val metrics = mapOf(
                "totalMemoryMB" to (totalMemory / 1024 / 1024),
                "availableMemoryMB" to (availableMemory / 1024 / 1024),
                "usedMemoryMB" to (usedMemory / 1024 / 1024),
                "memoryUsagePercent" to memoryUsagePercent,
                "dalvikHeapSizeMB" to (dalvikHeapSize / 1024 / 1024),
                "dalvikHeapUsedMB" to (dalvikHeapUsed / 1024 / 1024),
                "dalvikHeapFreeMB" to (dalvikHeapFree / 1024 / 1024),
                "isLowMemory" to memInfo.lowMemory
            )

            result.success(metrics)
        } catch (e: Exception) {
            result.error("PERFORMANCE_METRICS_ERROR", "Failed to get performance metrics: ${e.message}", e)
        }
    }

    private fun cleanup(result: MethodChannel.Result) {
        try {
            // クリーンアップ処理
            System.gc()
            result.success(true)
        } catch (e: Exception) {
            result.error("CLEANUP_ERROR", "Failed to cleanup: ${e.message}", e)
        }
    }

    fun dispose() {
        methodChannel?.setMethodCallHandler(null)
        methodChannel = null
    }
}