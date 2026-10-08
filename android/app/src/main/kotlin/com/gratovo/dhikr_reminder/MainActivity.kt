package com.gratovo.dhikr_reminder

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Bundle
import android.os.PowerManager
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Hosts Flutter, and answers the one channel the reminders use:
 * Dart plans the reminders and hands them over; the native side arms alarms and
 * shows the card (see ReminderAlarms and OverlayService), even with the app
 * closed. The same channel also asks for the two permissions the reminders
 * depend on: drawing over other apps, and running in the background.
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

            "requestOverlayPermission" -> result.success(openOverlaySettings())

            "isBackgroundUnrestricted" -> result.success(isBackgroundUnrestricted())

            "requestBackgroundUnrestricted" -> result.success(openBatterySettings())

            "schedule" -> {
                val items = call.argument<List<Map<String, Any>>>("plan") ?: emptyList()
                val plan = items.map {
                    ReminderStore.Planned(
                        id = (it["id"] as Number).toInt(),
                        atMillis = (it["at"] as Number).toLong(),
                        dhikrId = (it["dhikrId"] as Number).toInt(),
                        text = it["text"] as String,
                        amount = (it["amount"] as Number).toInt(),
                        goal = (it["goal"] as? Number)?.toInt() ?: 0,
                    )
                }
                ReminderStore.savePlan(
                    this,
                    plan,
                    (call.argument<Number>("intervalMillis") ?: 0).toLong(),
                    call.argument<String>("title") ?: "",
                    call.argument<String>("closeLabel") ?: "",
                    call.argument<String>("tip") ?: "",
                    call.argument<String>("dayLabel") ?: "",
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
                        call.argument<String>("dayLabel") ?: "",
                    )
                    startForegroundService(
                        OverlayService.intentNow(
                            this,
                            call.argument<Int>("dhikrId") ?: 0,
                            call.argument<String>("text") ?: "",
                            call.argument<Int>("amount") ?: 1,
                            call.argument<Int>("goal") ?: 0,
                        ),
                    )
                    result.success(true)
                }
            }

            "cancel" -> {
                ReminderAlarms.cancelAll(this)
                result.success(null)
            }

            "setToday" -> {
                val counts = HashMap<Int, Int>()
                call.argument<Map<String, Any>>("counts")?.forEach { (key, value) ->
                    key.toIntOrNull()?.let { id -> counts[id] = (value as? Number)?.toInt() ?: 0 }
                }
                ReminderStore.setToday(this, call.argument<String>("day") ?: "", counts)
                result.success(null)
            }

            "drainTaps" -> {
                val taps = ReminderStore.drainTaps(this)
                result.success(taps.mapKeys { it.key.toString() })
            }

            else -> result.notImplemented()
        }
    }

    /**
     * Opens the system screen where "Display over other apps" is granted,
     * straight on this app's own switch where the phone supports it.
     *
     * Phones differ a lot here, so nothing in it is allowed to fail loudly: the
     * most specific screen is tried first, then the plain list of apps with the
     * extras some Settings apps use to scroll to (and highlight) this one, and
     * if no screen can be opened at all, nothing happens and false comes back.
     */
    private fun openOverlaySettings(): Boolean {
        val own = Uri.parse("package:$packageName")
        val direct = Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION, own)
            .putExtra(FRAGMENT_ARG_KEY, packageName)
            .putExtra(
                SHOW_FRAGMENT_ARGS,
                Bundle().apply { putString(FRAGMENT_ARG_KEY, packageName) },
            )
        if (tryStart(direct)) return true
        return tryStart(Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION))
    }

    private fun isBackgroundUnrestricted(): Boolean {
        val power = getSystemService(Context.POWER_SERVICE) as PowerManager
        return power.isIgnoringBatteryOptimizations(packageName)
    }

    /**
     * Asks to let this app run in the background: the one-tap system dialog
     * first, then the list of battery-optimised apps, then this app's own
     * settings page. Silent if none of them can be opened.
     */
    private fun openBatterySettings(): Boolean {
        val own = Uri.parse("package:$packageName")
        // The one-tap dialog only works if the manifest asks for the
        // permission; without it the system closes the dialog at once and
        // reports nothing. So a build that leaves the permission out (for a
        // store that does not allow it) goes straight to the list.
        val mayAskDirectly = checkSelfPermission(
            Manifest.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS,
        ) == PackageManager.PERMISSION_GRANTED
        return (mayAskDirectly &&
            tryStart(Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS, own))) ||
            tryStart(Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)) ||
            tryStart(Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, own))
    }

    private fun tryStart(intent: Intent): Boolean =
        try {
            startActivity(intent)
            true
        } catch (e: Exception) {
            false
        }

    companion object {
        private const val CHANNEL = "dhikr_reminder/overlay"

        // The extras the Settings app reads to scroll to one row of a list.
        private const val FRAGMENT_ARG_KEY = ":settings:fragment_args_key"
        private const val SHOW_FRAGMENT_ARGS = ":settings:show_fragment_args"
    }
}
