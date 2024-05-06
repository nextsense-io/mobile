package io.nextsense.android.budz.model

import com.google.firebase.Timestamp
import com.google.firebase.firestore.Exclude
import com.google.firebase.firestore.ServerTimestamp

enum class UserType {
    CONSUMER, ENGINEER
}

enum class UserKeys {
    EMAIL, TYPE, CREATED_AT;

    fun key() = name.lowercase()
}

data class User(
    val email: String?,
    val type: UserType?,
    @ServerTimestamp
    val createdAt: Timestamp? = null
) {
    @Exclude
    fun isConsumer() = type == UserType.CONSUMER
    @Exclude
    fun isEngineer() = type == UserType.ENGINEER
}
