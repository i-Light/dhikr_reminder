package com.gratovo.dhikr_reminder

import android.content.Intent
import android.net.Uri
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Hosts Flutter, and answers the one channel the reminder overlay uses:
 * Dart plans the reminders and hands them over; the native side arms alarms and
 * shows the card (see ReminderAlarms and OverlayService), even with the app
 * closed.
 */
class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result -> handle(call, result) }
    }

    private fun handle(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "canDrawOverlays" -> result.success(Settings.canDrawOverlays(this))

            "requestOverlayPermission" -> {
                startActivity(
                    Intent(
                        Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                        Uri.parse("package:$packageName"),
                    ),
                )
                result.success(null)
            }

            "schedule" -> {
                val items = call.argument<List<Map<String, Any>>>("plan") ?: emptyList()
                val plan = items.map {
                    ReminderStore.Planned(
                        id = (it["id"] as Number).toInt(),
                        atMillis = (it["at"] as Number).toLong(),
                        dhikrId = (it["dhikrId"] as Number).toInt(),
                        text = it["text"] as String,
                        amount = (it["amount"] as Number).toInt(),
                    )
                }
                ReminderStore.savePlan(
                    this,
                    plan,
                    call.argument<String>("title") ?: "",
                    call.argument<String>("closeLabel") ?: "",
                    call.argument<String>("tip") ?: "",
                )
                ReminderAlarms.reschedule(this)
                result.success(null)
            }

            "showNow" -> {
                if (!Settings.canDrawOverlays(this)) {
                    result.success(false)
                } else {
                    ReminderStore.saveLabels(
                        this,
                        call.argument<String>("title") ?: "",
                        call.argument<String>("closeLabel") ?: "",
                        call.argument<String>("tip") ?: "",
                    )
                    startForegroundService(
                        OverlayService.intentNow(
                            this,
                            call.argument<Int>("dhikrId") ?: 0,
                            call.argument<String>("text") ?: "",
                            call.argument<Int>("amount") ?: 1,
                        ),
                    )
                    result.success(true)
                }
            }

            "cancel" -> {
                ReminderAlarms.cancelAll(this)
                result.success(null)
            }

            "drainTaps" -> {
                val taps = ReminderStore.drainTaps(this)
                result.success(taps.mapKeys { it.key.toString() })
            }

            else -> result.notImplemented()
        }
    }

    companion object {
        private const val CHANNEL = "dhikr_reminder/overlay"
    }
}
