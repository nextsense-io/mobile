package io.nextsense.android.budz.model

import android.annotation.SuppressLint
import com.google.firebase.Timestamp
import com.google.firebase.firestore.DocumentSnapshot
import com.google.firebase.firestore.Exclude
import com.google.firebase.firestore.PropertyName
import com.google.firebase.firestore.ServerTimestamp
import com.google.firebase.firestore.util.CustomClassMapper
import io.nextsense.android.base.utils.RotatingFileLogger

enum class UserType {
    consumer, engineer
}

enum class UserKeys {
    EMAIL, NAME, TYPE, IS_ONBOARDING_COMPLETED, FALL_ASLEEP_SOUND, FALL_ASLEEP_TIMED_SOUND,
    STAY_ASLEEP_SOUND, STAY_ASLEEP_TIMED_SOUND, TIMED_SLEEP_DURATION, FOCUS_SOUND, CREATED_AT;

    fun key() = name.lowercase()
}

data class User (
    var email: String?,
    var name: String?,
    var type: UserType?,
    @get:PropertyName("is_onboarding_completed")
    @set:PropertyName("is_onboarding_completed")
    var isOnboardingCompleted: Boolean? = false,
    @get:PropertyName("fall_asleep_sound")
    @set:PropertyName("fall_asleep_sound")
    var fallAsleepSound: String? = null,
    @get:PropertyName("fall_asleep_timed_sound")
    @set:PropertyName("fall_asleep_timed_sound")
    var fallAsleepTimedSound: String? = null,
    @get:PropertyName("stay_asleep_sound")
    @set:PropertyName("stay_asleep_sound")
    var stayAsleepSound: String? = null,
    @get:PropertyName("stay_asleep_timed_sound")
    @set:PropertyName("stay_asleep_timed_sound")
    var stayAsleepTimedSound: String? = null,
    @get:PropertyName("focus_sound")
    @set:PropertyName("focus_sound")
    var focusSound: String? = null,
    @get:PropertyName("timed_sleep_duration_minutes")
    @set:PropertyName("timed_sleep_duration_minutes")
    var timedSleepDurationMinutes: Int? = null,
    @get:PropertyName("focus_duration_minutes")
    @set:PropertyName("focus_duration_minutes")
    var focusDurationMinutes: Int? = null,
    @ServerTimestamp
    @get:PropertyName("created_at")
    @set:PropertyName("created_at")
    var createdAt: Timestamp? = null
) {

    @SuppressWarnings("unused")  // Needed for Firestore.
    constructor() : this(null, null, null)
    constructor(email: String, name: String) : this(email, name, null)

    @Exclude
    fun isConsumer() = type == UserType.consumer
    @Exclude
    fun isEngineer() = type == UserType.engineer

    companion object {
        @SuppressLint("RestrictedApi")
        fun toObject(snapshot: DocumentSnapshot): User? {
            val data = snapshot.data!!

            // Fix consumer type if needed.
            val userType = snapshot[UserKeys.TYPE.key()] as String?
            if (userType == UserType.consumer.name.uppercase()) {
                data[UserKeys.TYPE.key()] = UserType.consumer.name
                // runtime patch
                // sadly snapshot data cannot be modified directly, so we call an update
                snapshot.reference.update(
                    mapOf(
                        UserKeys.TYPE.key() to data[UserKeys.TYPE.key()]
                    )
                )
            }

            // https://github.com/firebase/firebase-android-sdk/blob/master/firebase-firestore/src/main/java/com/google/firebase/firestore/DocumentSnapshot.java
            return try {
                CustomClassMapper.convertToCustomClass(data, User::class.java, snapshot.reference)
            }
            catch (e: RuntimeException) {
                RotatingFileLogger.get().loge("User", e.message)
                null
            }
        }
    }
}
