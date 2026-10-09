package com.gratovo.dhikr_reminder

import android.os.Build
import android.service.quicksettings.Tile
import android.service.quicksettings.TileService

/**
 * Quick-settings tile "Count one": a tap adds one to the dhikr being counted
 * without opening anything, and the tile shows today's total. Greyed out until
 * a first reminder has told it which dhikr that is.
 */
class CountTile : TileService() {
    override fun onStartListening() = render()

    override fun onClick() {
        Surfaces.countOne(this)
        render()
    }

    private fun render() {
        val tile = qsTile ?: return
        val focus = ReminderStore.focus(this)
        tile.label = Surfaces.label(this, "countOne", R.string.tile_count)
        tile.state = if (focus == null) Tile.STATE_UNAVAILABLE else Tile.STATE_INACTIVE
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            tile.subtitle = if (focus == null) null else ReminderStore.todayTotal(this).toString()
        }
        tile.updateTile()
    }
}

/**
 * Quick-settings tile "Pause for 1 hour". Lit while a pause is on; a tap then
 * lifts it. The app learns of the change the next time it opens.
 */
class PauseTile : TileService() {
    override fun onStartListening() = render()

    override fun onClick() {
        Surfaces.togglePause(this)
        render()
    }

    private fun render() {
        val tile = qsTile ?: return
        val until = ReminderStore.pausedUntilMillis(this)
        val paused = PendingRules.isPaused(System.currentTimeMillis(), until)
        tile.label = if (paused) {
            Surfaces.label(this, "resume", R.string.tile_resume)
        } else {
            Surfaces.label(this, "pause", R.string.tile_pause)
        }
        tile.state = if (paused) Tile.STATE_ACTIVE else Tile.STATE_INACTIVE
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            tile.subtitle = if (paused) Surfaces.pausedText(this, until) else null
        }
        tile.updateTile()
    }
}
