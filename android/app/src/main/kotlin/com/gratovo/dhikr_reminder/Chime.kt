package com.gratovo.dhikr_reminder

import android.content.Context
import android.media.AudioAttributes
import android.media.MediaPlayer
import java.io.File

/**
 * The soft chime played when a dhikr is finished, if the person switched sound
 * on. The app (Dart) makes the sound and hands it over once; this keeps it in
 * the app's cache folder and plays it, so a card finished with the app closed
 * chimes too. It is played as a notification sound, so the phone's silent and
 * vibrate modes keep it quiet, and it follows the notification volume.
 *
 * Nothing is loaded until a chime is played, and nothing at all while sound is
 * off.
 */
object Chime {
    private const val FILE = "chime.wav"
    private const val PREFS = "dhikr_overlay"
    private const val KEY_ON = "chime_on"

    fun setEnabled(context: Context, enabled: Boolean, wav: ByteArray?) {
        context.applicationContext
            .getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit().putBoolean(KEY_ON, enabled && wav != null).apply()
        val file = File(context.cacheDir, FILE)
        if (enabled && wav != null) {
            file.writeBytes(wav)
        } else if (file.exists()) {
            file.delete()
        }
    }

    fun isEnabled(context: Context): Boolean =
        context.applicationContext
            .getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getBoolean(KEY_ON, false)

    /** Plays the chime once if sound is on and the file is there; never throws. */
    fun playIfEnabled(context: Context) {
        if (!isEnabled(context)) return
        val file = File(context.cacheDir, FILE)
        if (!file.exists()) return
        try {
            val player = MediaPlayer()
            player.setAudioAttributes(
                AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_NOTIFICATION)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .build(),
            )
            player.setDataSource(file.path)
            player.setOnCompletionListener { it.release() }
            player.setOnErrorListener { mp, _, _ ->
                mp.release()
                true
            }
            player.prepare()
            player.start()
        } catch (e: Exception) {
            // Silence is a fine way to fail.
        }
    }
}
