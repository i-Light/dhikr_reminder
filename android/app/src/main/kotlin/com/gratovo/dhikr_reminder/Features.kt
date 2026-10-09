package com.gratovo.dhikr_reminder

/**
 * One switch per optional behaviour, so one that is not liked can be turned off
 * by changing one `true` to `false`. The Dart side has its own list in
 * lib/core/features.dart; keep the two in step.
 */
object Features {
    /**
     * Do not show the floating card during Do Not Disturb or a phone call (the
     * reminder arrives as a notification instead), and keep to quiet hours.
     */
    const val POLITE_REMINDERS = true
}
