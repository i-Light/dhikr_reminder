package com.gratovo.dhikr_reminder

import android.Manifest
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
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
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        rememberOpenRequest(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        rememberOpenRequest(intent)
    }

    /** A tapped reminder notification names the dhikr to open; Dart asks for it. */
    private fun rememberOpenRequest(intent: Intent?) {
        if (intent?.hasExtra(EXTRA_OPEN_DHIKR) != true) return
        ReminderStore.setOpenDhikr(this, intent.getIntExtra(EXTRA_OPEN_DHIKR, -1))
        // Once taken it must not come back when the activity is recreated.
        intent.removeExtra(EXTRA_OPEN_DHIKR)
    }

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

            "requestNotificationPermission" -> result.success(requestNotificationPermission())

            "health" -> result.success(health())

            "setChime" -> {
                Chime.setEnabled(
                    this,
                    call.argument<Boolean>("enabled") ?: false,
                    call.argument<ByteArray>("wav"),
                )
                result.success(null)
            }

            "playChime" -> {
                Chime.playIfEnabled(this)
                result.success(null)
            }

            "openAppLaunchSettings" -> result.success(openAppLaunchSettings())

            "openNotificationSettings" -> result.success(openNotificationSettings())

            "takeOpenDhikr" -> result.success(ReminderStore.takeOpenDhikr(this))

            "nextReminderAt" -> result.success(ReminderAlarms.nextDue(this))

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
                        translit = it["translit"] as? String ?: "",
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
                    (call.argument<Number>("pausedUntil") ?: 0).toLong(),
                    (call.argument<Number>("quietStart") ?: QuietWindow.OFF).toInt(),
                    (call.argument<Number>("quietEnd") ?: QuietWindow.OFF).toInt(),
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
                            call.argument<String>("translit") ?: "",
                        ),
                    )
                    result.success(true)
                }
            }

            "cancel" -> {
                ReminderAlarms.cancelAndForget(this)
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

            "setArabicHidden" -> {
                ReminderStore.setArabicHidden(this, call.argument<Boolean>("hidden") ?: false)
                result.success(null)
            }

            "takeArabicHidden" -> result.success(ReminderStore.takeArabicChange(this))

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

    /**
     * Whether notifications are allowed, asking the system first where the
     * phone requires it (Android 13 and later). The system shows its own
     * dialog at most twice; after that this only reports the answer. The
     * answer returned is the one at the moment of asking.
     */
    private fun requestNotificationPermission(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) return true
        val granted = checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) ==
            PackageManager.PERMISSION_GRANTED
        if (!granted) {
            requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), REQUEST_NOTIFICATIONS)
        }
        return granted
    }

    /**
     * What a person (or a bug report) needs to know about whether reminders are
     * getting through: the permissions that matter, the alarms armed, when the
     * last reminder arrived, whether that looks stopped, and the last events.
     */
    private fun health(): Map<String, Any> {
        val now = System.currentTimeMillis()
        val interval = ReminderStore.intervalMillis(this)
        val paused = ReminderStore.pausedUntilMillis(this)
        val armed = ReminderStore.armed(this).size
        val lastDelivered = ReminderStore.lastDeliveredMillis(this)
        val since = maxOf(lastDelivered, ReminderStore.activeSinceMillis(this), paused)
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val channel = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            manager.getNotificationChannel("dhikr_reminders")
        } else {
            null
        }
        return mapOf(
            "stopped" to HealthRules.isStopped(now, interval, since, paused, armed),
            "armed" to armed,
            "nextDue" to ReminderAlarms.nextDue(this),
            "intervalMillis" to interval,
            "lastDelivered" to lastDelivered,
            "notificationsEnabled" to manager.areNotificationsEnabled(),
            "channelBlocked" to (channel?.importance == NotificationManager.IMPORTANCE_NONE),
            "canDrawOverlays" to Settings.canDrawOverlays(this),
            "ignoringBattery" to isBackgroundUnrestricted(),
            "manufacturer" to Build.MANUFACTURER,
            "sdk" to Build.VERSION.SDK_INT,
            "events" to ReminderStore.events(this).takeLast(12).map {
                "${it.atMillis}|${it.kind}|${it.detail}"
            },
        )
    }

    /**
     * Opens the screen where this phone's maker hides "start in the background"
     * (Xiaomi, Oppo, Vivo, Huawei), which is what kills reminders on those phones,
     * and falls back to this app's own settings page. Silent if nothing opens.
     */
    private fun openAppLaunchSettings(): Boolean {
        val candidates = when (Build.MANUFACTURER.lowercase()) {
            "xiaomi", "redmi", "poco" -> listOf(
                "com.miui.securitycenter" to "com.miui.permcenter.autostart.AutoStartManagementActivity",
            )
            "oppo", "realme", "oneplus" -> listOf(
                "com.coloros.safecenter" to "com.coloros.safecenter.startupapp.StartupAppListActivity",
                "com.oplus.battery" to "com.oplus.powermanager.fuelgaue.PowerUsageModelActivity",
                "com.coloros.oppoguardelf" to "com.coloros.powermanager.fuelgaue.PowerUsageModelActivity",
            )
            "vivo", "iqoo" -> listOf(
                "com.vivo.permissionmanager" to "com.vivo.permissionmanager.activity.BgStartUpManagerActivity",
                "com.iqoo.secure" to "com.iqoo.secure.ui.phoneoptimize.AddWhiteListActivity",
            )
            "huawei", "honor" -> listOf(
                "com.huawei.systemmanager" to "com.huawei.systemmanager.startupmgr.ui.StartupNormalAppListActivity",
            )
            else -> emptyList()
        }
        for ((pkg, cls) in candidates) {
            if (tryStart(Intent().setClassName(pkg, cls))) return true
        }
        return tryStart(
            Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:$packageName")),
        )
    }

    private fun openNotificationSettings(): Boolean =
        tryStart(
            Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                .putExtra(Settings.EXTRA_APP_PACKAGE, packageName),
        ) || tryStart(
            Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:$packageName")),
        )

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
        private const val REQUEST_NOTIFICATIONS = 1001

        /** The dhikr id a reminder notification carries for the app to open. */
        const val EXTRA_OPEN_DHIKR = "open_dhikr"

        // The extras the Settings app reads to scroll to one row of a list.
        private const val FRAGMENT_ARG_KEY = ":settings:fragment_args_key"
        private const val SHOW_FRAGMENT_ARGS = ":settings:show_fragment_args"
    }
}
