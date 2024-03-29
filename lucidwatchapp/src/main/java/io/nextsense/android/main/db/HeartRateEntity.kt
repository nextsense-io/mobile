package io.nextsense.android.main.db

import androidx.room.ColumnInfo
import androidx.room.Dao
import androidx.room.Delete
import androidx.room.Entity
import androidx.room.Insert
import androidx.room.PrimaryKey
import androidx.room.Query

@Entity
data class HeartRateEntity(
    @PrimaryKey(autoGenerate = true) val uid: Int? = null,
    @ColumnInfo val heartRate: Double?,
    @ColumnInfo val createdAt: Long?,
    @ColumnInfo val date: String? = null
)

@Dao
interface HeartRateDao {
    @Query("SELECT * FROM HeartRateEntity")
    fun getAll(): List<HeartRateEntity>

    @Query("SELECT * FROM HeartRateEntity WHERE uid IN (:uid)")
    fun loadAllByIds(uid: IntArray): List<HeartRateEntity>

    @Query("SELECT * FROM HeartRateEntity WHERE createdAt >= (:startTime) AND createdAt <= (:endTime)")
    fun findByDateRange(startTime: Long, endTime: Long): List<HeartRateEntity>

    @Insert
    fun insertAll(vararg heartRateEntity: HeartRateEntity)

    @Delete
    fun delete(heartRateEntity: HeartRateEntity)
}