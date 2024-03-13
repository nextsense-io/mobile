package io.nextsense.android.main.utils

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.content.pm.PackageManager
import androidx.core.app.ActivityCompat
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat.getString
import io.nextsense.android.main.lucid.R

const val CHANNEL_ID = "realityCheckingBedTimeChannel"
const val NOTIFICATION_ID = 102

class NotificationManager(private val context: Context) {

    init {
        createNotificationChannel()
    }

    fun showNotification(title: String, message: String) {
        val builder =
            NotificationCompat.Builder(context, CHANNEL_ID)
                .setSmallIcon(R.drawable.ic_stat_onesignal_default)
                .setContentTitle(title).setContentText(message)
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .extend(NotificationCompat.WearableExtender())
        with(NotificationManagerCompat.from(context)) {
            if (ActivityCompat.checkSelfPermission(
                    context, Manifest.permission.POST_NOTIFICATIONS
                ) != PackageManager.PERMISSION_GRANTED
            ) {
                return@with
            }
            // notificationId is a unique int for each notification that you must define.
            notify(NOTIFICATION_ID, builder.build())
        }
    }

    private fun createNotificationChannel() {
        // Create the NotificationChannel, but only on API 26+ because
        // the NotificationChannel class is not in the Support Library.
        val name = getString(context, R.string.channel_name)
        val descriptionText = getString(context, R.string.channel_description)
        val importance = NotificationManager.IMPORTANCE_DEFAULT
        val channel = NotificationChannel(CHANNEL_ID, name, importance).apply {
            description = descriptionText
        }
        // Register the channel with the system.
        val notificationManager: NotificationManager =
            context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.createNotificationChannel(channel)
    }
}