package io.nextsense.android.main.db

import androidx.room.ColumnInfo
import androidx.room.Dao
import androidx.room.Delete
import androidx.room.Entity
import androidx.room.Insert
import androidx.room.PrimaryKey
import androidx.room.Query


@Entity
data class PredictionEntity(
    @PrimaryKey(autoGenerate = true) val uid: Int? = null,
    @ColumnInfo val createAt: Long,
    @ColumnInfo val date: String,
    @ColumnInfo val prediction: Int,
    @ColumnInfo val startDate: Long,
    @ColumnInfo val endDate: Long
)

@Dao
interface PredictionDao {
    @Query("SELECT * FROM PredictionEntity")
    fun getAll(): List<PredictionEntity>

    @Query("SELECT * FROM PredictionEntity WHERE uid IN (:uid)")
    fun loadAllByIds(uid: IntArray): List<PredictionEntity>

    @Query("SELECT * FROM PredictionEntity WHERE createAt >= (:startTime) AND createAt <= (:endTime)")
    fun findByDateRange(startTime: Long, endTime: Long): List<PredictionEntity>

    @Insert
    fun insertAll(vararg prediction: PredictionEntity)

    @Delete
    fun delete(prediction: PredictionEntity)

    @Query(
        "SELECT CASE WHEN (SELECT COUNT(*) FROM PredictionEntity WHERE uid >= (SELECT MAX(uid) - :numberOfRecords + 1 FROM PredictionEntity) AND prediction = 1) = :numberOfRecords THEN 1 ELSE 0 END AS result;"
    )
    fun isREMInRecentRecords(numberOfRecords: Int = 5): Boolean
}
