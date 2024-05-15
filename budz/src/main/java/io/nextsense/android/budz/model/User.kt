package io.nextsense.android.budz.model

import com.google.firebase.Timestamp
import com.google.firebase.firestore.Exclude
import com.google.firebase.firestore.PropertyName
import com.google.firebase.firestore.ServerTimestamp

enum class UserType {
    CONSUMER, ENGINEER
}

enum class UserKeys {
    EMAIL, NAME, TYPE, IS_ONBOARDING_COMPLETED, FALL_ASLEEP_SOUND, STAY_ASLEEP_SOUND, FOCUS_SOUND,
    CREATED_AT;

    fun key() = name.lowercase()
}

data class User (
    var email: String?,
    var name: String?,
    var type: UserType?,
    @get:PropertyName("is_onboarding_completed")
    @set:PropertyName("is_onboarding_completed")
    var isOnboardingCompleted: Boolean = false,
    @get:PropertyName("fall_asleep_sound")
    @set:PropertyName("fall_asleep_sound")
    var fallAsleepSound: String? = null,
    @get:PropertyName("stay_asleep_sound")
    @set:PropertyName("stay_asleep_sound")
    var stayAsleepSound: String? = null,
    @get:PropertyName("focus_sound")
    @set:PropertyName("focus_sound")
    var focusSound: String? = null,
    @ServerTimestamp
    @get:PropertyName("created_at")
    @set:PropertyName("created_at")
    var createdAt: Timestamp? = null
) {
    // Needed for Firestore.
    constructor() : this(null, null, null)
    constructor(email: String, name: String) : this(email, name, null)

    @Exclude
    fun isConsumer() = type == UserType.CONSUMER
    @Exclude
    fun isEngineer() = type == UserType.ENGINEER
}
