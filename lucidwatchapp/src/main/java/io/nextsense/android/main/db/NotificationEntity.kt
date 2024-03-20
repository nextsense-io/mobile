package io.nextsense.android.main.db

import androidx.room.ColumnInfo
import androidx.room.Dao
import androidx.room.Delete
import androidx.room.Entity
import androidx.room.Insert
import androidx.room.PrimaryKey

@Entity
data class NotificationEntity(
    @PrimaryKey(autoGenerate = true) val uid: Int? = null,
    @ColumnInfo val createAt: Long,
    @ColumnInfo val date: String
)

@Dao
interface NotificationDao {
    @Insert
    fun insert(notificationEntity: NotificationEntity)

    @Delete
    fun delete(notificationEntity: NotificationEntity)
}