package com.gratovo.dhikr_reminder

import android.app.job.JobInfo
import android.app.job.JobParameters
import android.app.job.JobScheduler
import android.app.job.JobService
import android.content.ComponentName
import android.content.Context

/**
 * A once-in-twelve-hours safety net for the alarms. Some phones clear alarms
 * without telling the app (a "cleaner", a force-stop, a restore from backup); a
 * job the system keeps itself (and keeps across a reboot) arms the stored plan
 * again, so a reminder that went missing comes back without the app being
 * opened. It does nothing between runs, and does nothing at all while no plan
 * is stored.
 */
class HealthJob : JobService() {
    override fun onStartJob(params: JobParameters): Boolean {
        try {
            ReminderAlarms.topUp(this)
            ReminderStore.log(this, "rearmed", "job")
        } catch (e: Exception) {
            ReminderStore.log(this, "error", "job " + e.javaClass.simpleName)
        }
        return false
    }

    override fun onStopJob(params: JobParameters): Boolean = true

    companion object {
        private const val JOB_ID = 4711
        private const val EVERY_MILLIS = 12L * 60 * 60 * 1000

        /** Makes sure the job is scheduled, once; does nothing if it already is. */
        fun ensureScheduled(context: Context) {
            try {
                val scheduler = context.getSystemService(Context.JOB_SCHEDULER_SERVICE) as JobScheduler
                if (scheduler.getPendingJob(JOB_ID) != null) return
                val job = JobInfo.Builder(JOB_ID, ComponentName(context, HealthJob::class.java))
                    .setPeriodic(EVERY_MILLIS)
                    .setPersisted(true)
                    .build()
                scheduler.schedule(job)
            } catch (e: Exception) {
                // A phone that refuses the job loses only the safety net.
            }
        }
    }
}
