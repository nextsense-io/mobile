package io.nextsense.android.main.db

import androidx.room.ColumnInfo
import androidx.room.Dao
import androidx.room.Delete
import androidx.room.Entity
import androidx.room.Insert
import androidx.room.PrimaryKey
import androidx.room.Query
import kotlin.math.atan
import kotlin.math.pow
import kotlin.math.sqrt

@Entity
data class AccelerometerEntity(
    @PrimaryKey(autoGenerate = true) val uid: Int? = null,
    @ColumnInfo val x: Double?,
    @ColumnInfo val y: Double?,
    @ColumnInfo val z: Double?,
    @ColumnInfo val createAt: Long,
)

@Dao
interface AccelerometerDao {
    @Query("SELECT * FROM AccelerometerEntity")
    fun getAll(): List<AccelerometerEntity>

    @Query("SELECT * FROM AccelerometerEntity WHERE uid IN (:uid)")
    fun loadAllByIds(uid: IntArray): List<AccelerometerEntity>

    @Query("SELECT * FROM AccelerometerEntity WHERE createAt >= (:startTime) AND createAt <= (:endTime)")
    fun findByDateRange(startTime: Long, endTime: Long): List<AccelerometerEntity>

    @Insert
    fun insertAll(vararg accelerometerEntity: AccelerometerEntity)

    @Delete
    fun delete(accelerometerEntity: AccelerometerEntity)
}

fun AccelerometerEntity.getAngle() = atan(x!! / sqrt(y!!.pow(2.0) + z!!.pow(2.0)))