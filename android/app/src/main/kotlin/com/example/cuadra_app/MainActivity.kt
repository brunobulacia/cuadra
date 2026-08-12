package com.example.cuadra_app

import android.content.Intent
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Stream de notificaciones que captura el NotificationListenerService
        // (la notif de pago de QRWallet) hacia Flutter.
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, "cuadra/notifications")
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    BankNotificationService.eventSink = events
                }
                override fun onCancel(arguments: Any?) {
                    BankNotificationService.eventSink = null
                }
            })

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "cuadra/hub")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isPermissionGranted" -> {
                        val listeners = Settings.Secure.getString(
                            contentResolver, "enabled_notification_listeners"
                        )
                        result.success(listeners?.contains(packageName) == true)
                    }
                    "openPermissionSettings" -> {
                        startActivity(Intent("android.settings.ACTION_NOTIFICATION_LISTENER_SETTINGS"))
                        result.success(null)
                    }
                    "getAllowedNotificationPackages" -> {
                        result.success(BankNotificationService.getAllowedPackages(this).toList())
                    }
                    "setAllowedNotificationPackages" -> {
                        val packages = call.argument<List<String>>("packages")
                            ?.map { it.trim() }
                            ?.filter { it.isNotEmpty() }
                            ?.toSet() ?: emptySet()
                        BankNotificationService.setAllowedPackages(this, packages)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
