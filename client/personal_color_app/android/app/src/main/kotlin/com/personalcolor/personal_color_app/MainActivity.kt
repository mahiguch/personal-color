package com.personalcolor.personal_color_app

import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private var settingsChannelHandler: SettingsChannelHandler? = null
    private var performanceChannelHandler: PerformanceChannelHandler? = null
    private var loggingChannelHandler: LoggingChannelHandler? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // SettingsChannelHandlerの初期化
        settingsChannelHandler = SettingsChannelHandler(flutterEngine)
        settingsChannelHandler?.setupMethodChannel()
        
        // PerformanceChannelHandlerの初期化
        performanceChannelHandler = PerformanceChannelHandler(flutterEngine)
        performanceChannelHandler?.setupMethodChannel()
        
        // LoggingChannelHandlerの初期化
        loggingChannelHandler = LoggingChannelHandler(flutterEngine)
        loggingChannelHandler?.setupMethodChannel()
    }

    override fun onDestroy() {
        super.onDestroy()
        settingsChannelHandler?.dispose()
        performanceChannelHandler?.dispose()
        loggingChannelHandler?.dispose()
    }
}
