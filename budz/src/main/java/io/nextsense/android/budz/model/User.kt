package io.nextsense.android.budz.model

import java.time.Instant

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
    val createdAt: Instant?
) {
    fun isConsumer() = type == UserType.CONSUMER
    fun isEngineer() = type == UserType.ENGINEER
}
