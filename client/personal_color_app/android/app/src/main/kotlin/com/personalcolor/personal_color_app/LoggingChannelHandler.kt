package com.personalcolor.personal_color_app

import android.app.ActivityManager
import android.content.Context
import android.os.Debug
import android.util.Log
import androidx.annotation.NonNull
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.ConcurrentHashMap

class LoggingChannelHandler(private val flutterEngine: FlutterEngine) {
    private val channelName = "android/logging"
    private var methodChannel: MethodChannel? = null
    private var minLogLevel = 1 // INFO level
    private val performanceTraces = ConcurrentHashMap<String, Long>()

    companion object {
        private const val TAG_PREFIX = "PersonalColorApp"
        
        // ログレベル定数
        private const val LEVEL_DEBUG = 0
        private const val LEVEL_INFO = 1
        private const val LEVEL_WARNING = 2
        private const val LEVEL_ERROR = 3
        private const val LEVEL_CRITICAL = 4
    }

    fun setupMethodChannel() {
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
        methodChannel?.setMethodCallHandler { call, result ->
            handleMethodCall(call, result)
        }
    }

    private fun handleMethodCall(@NonNull call: MethodCall, @NonNull result: MethodChannel.Result) {
        when (call.method) {
            "initialize" -> initialize(call, result)
            "log" -> log(call, result)
            "startTrace" -> startTrace(call, result)
            "stopTrace" -> stopTrace(call, result)
            "getMemoryInfo" -> getMemoryInfo(result)
            "sendErrorReport" -> sendErrorReport(call, result)
            "dispose" -> dispose(result)
            else -> result.notImplemented()
        }
    }

    private fun initialize(call: MethodCall, result: MethodChannel.Result) {
        try {
            minLogLevel = call.argument<Int>("minLogLevel") ?: LEVEL_INFO
            Log.i("$TAG_PREFIX-Logger", "AndroidLogger initialized with min level: $minLogLevel")
            result.success(true)
        } catch (e: Exception) {
            result.error("INITIALIZATION_ERROR", "Failed to initialize logger: ${e.message}", e)
        }
    }

    private fun log(call: MethodCall, result: MethodChannel.Result) {
        try {
            val level = call.argument<Int>("level") ?: LEVEL_INFO
            val tag = call.argument<String>("tag") ?: "Unknown"
            val message = call.argument<String>("message") ?: ""
            val extras = call.argument<Map<String, Any>>("extras")
            val stackTrace = call.argument<String>("stackTrace")
            val error = call.argument<String>("error")

            if (level < minLogLevel) {
                result.success(true)
                return
            }

            val logTag = "$TAG_PREFIX-$tag"
            val fullMessage = buildLogMessage(message, extras, stackTrace, error)

            when (level) {
                LEVEL_DEBUG -> Log.d(logTag, fullMessage)
                LEVEL_INFO -> Log.i(logTag, fullMessage)
                LEVEL_WARNING -> Log.w(logTag, fullMessage)
                LEVEL_ERROR -> Log.e(logTag, fullMessage)
                LEVEL_CRITICAL -> Log.wtf(logTag, fullMessage)
                else -> Log.v(logTag, fullMessage)
            }

            result.success(true)
        } catch (e: Exception) {
            result.error("LOG_ERROR", "Failed to log message: ${e.message}", e)
        }
    }

    private fun buildLogMessage(
        message: String,
        extras: Map<String, Any>?,
        stackTrace: String?,
        error: String?
    ): String {
        val builder = StringBuilder(message)

        if (extras != null && extras.isNotEmpty()) {
            builder.append(" | Extras: ").append(extras.toString())
        }

        if (error != null) {
            builder.append(" | Error: ").append(error)
        }

        if (stackTrace != null) {
            builder.append(" | StackTrace: ").append(stackTrace)
        }

        return builder.toString()
    }

    private fun startTrace(call: MethodCall, result: MethodChannel.Result) {
        try {
            val traceName = call.argument<String>("name")
            if (traceName == null) {
                result.error("INVALID_ARGUMENT", "Trace name is required", null)
                return
            }

            val startTime = System.currentTimeMillis()
            performanceTraces[traceName] = startTime

            Log.d("$TAG_PREFIX-Performance", "Started trace: $traceName at $startTime")
            result.success(true)
        } catch (e: Exception) {
            result.error("TRACE_START_ERROR", "Failed to start trace: ${e.message}", e)
        }
    }

    private fun stopTrace(call: MethodCall, result: MethodChannel.Result) {
        try {
            val traceName = call.argument<String>("name")
            if (traceName == null) {
                result.error("INVALID_ARGUMENT", "Trace name is required", null)
                return
            }

            val startTime = performanceTraces.remove(traceName)
            if (startTime != null) {
                val endTime = System.currentTimeMillis()
                val duration = endTime - startTime
                Log.i("$TAG_PREFIX-Performance", "Trace '$traceName' completed in ${duration}ms")
            } else {
                Log.w("$TAG_PREFIX-Performance", "No start time found for trace: $traceName")
            }

            result.success(true)
        } catch (e: Exception) {
            result.error("TRACE_STOP_ERROR", "Failed to stop trace: ${e.message}", e)
        }
    }

    private fun getMemoryInfo(result: MethodChannel.Result) {
        try {
            val context = flutterEngine.activityControlSurface.activity?.applicationContext
                ?: run {
                    result.error("NO_CONTEXT", "Context not available", null)
                    return
                }

            val activityManager = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
            val memInfo = ActivityManager.MemoryInfo()
            activityManager.getMemoryInfo(memInfo)

            // アプリ固有のメモリ情報
            val runtime = Runtime.getRuntime()
            val maxMemory = runtime.maxMemory()
            val totalMemory = runtime.totalMemory()
            val freeMemory = runtime.freeMemory()
            val usedMemory = totalMemory - freeMemory

            // ネイティブヒープ情報
            val nativeHeapSize = Debug.getNativeHeapSize()
            val nativeHeapUsed = Debug.getNativeHeapAllocatedSize()
            val nativeHeapFree = Debug.getNativeHeapFreeSize()

            val memoryData = mapOf(
                "systemTotalMB" to (memInfo.totalMem / 1024 / 1024),
                "systemAvailableMB" to (memInfo.availMem / 1024 / 1024),
                "appMaxMB" to (maxMemory / 1024 / 1024),
                "appTotalMB" to (totalMemory / 1024 / 1024),
                "appUsedMB" to (usedMemory / 1024 / 1024),
                "appFreeMB" to (freeMemory / 1024 / 1024),
                "nativeHeapSizeMB" to (nativeHeapSize / 1024 / 1024),
                "nativeHeapUsedMB" to (nativeHeapUsed / 1024 / 1024),
                "nativeHeapFreeMB" to (nativeHeapFree / 1024 / 1024),
                "isLowMemory" to memInfo.lowMemory,
                "memoryUsagePercent" to ((usedMemory.toDouble() / maxMemory.toDouble()) * 100)
            )

            result.success(memoryData)
        } catch (e: Exception) {
            result.error("MEMORY_INFO_ERROR", "Failed to get memory info: ${e.message}", e)
        }
    }

    private fun sendErrorReport(call: MethodCall, result: MethodChannel.Result) {
        try {
            val error = call.argument<String>("error") ?: ""
            val stackTrace = call.argument<String>("stackTrace")
            val context = call.argument<Map<String, Any>>("context")
            val userId = call.argument<String>("userId")
            val timestamp = call.argument<String>("timestamp") ?: ""
            val platform = call.argument<String>("platform") ?: "Android"
            val appVersion = call.argument<String>("appVersion") ?: "unknown"

            // エラーレポートをLogcatに出力（本来はCrashlyticsなどに送信）
            val reportBuilder = StringBuilder()
            reportBuilder.append("=== ERROR REPORT ===\n")
            reportBuilder.append("Error: $error\n")
            reportBuilder.append("Timestamp: $timestamp\n")
            reportBuilder.append("Platform: $platform\n")
            reportBuilder.append("App Version: $appVersion\n")
            if (userId != null) {
                reportBuilder.append("User ID: $userId\n")
            }
            if (context != null) {
                reportBuilder.append("Context: $context\n")
            }
            if (stackTrace != null) {
                reportBuilder.append("Stack Trace:\n$stackTrace\n")
            }
            reportBuilder.append("=== END REPORT ===")

            Log.e("$TAG_PREFIX-ErrorReport", reportBuilder.toString())

            // TODO: 実際のエラーレポートサービス（Firebase Crashlytics等）への送信
            
            result.success(true)
        } catch (e: Exception) {
            result.error("ERROR_REPORT_ERROR", "Failed to send error report: ${e.message}", e)
        }
    }

    private fun dispose(result: MethodChannel.Result) {
        try {
            performanceTraces.clear()
            Log.i("$TAG_PREFIX-Logger", "AndroidLogger disposed")
            result.success(true)
        } catch (e: Exception) {
            result.error("DISPOSE_ERROR", "Failed to dispose logger: ${e.message}", e)
        }
    }

    fun dispose() {
        methodChannel?.setMethodCallHandler(null)
        methodChannel = null
        performanceTraces.clear()
    }
}