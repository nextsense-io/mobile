package io.nextsense.android.main.utils

import android.content.Context
import android.content.SharedPreferences
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.buffer
import kotlinx.coroutines.flow.callbackFlow

class SharedPreferencesHelper(context: Context) {
    private val sharedPreferences: SharedPreferences = context.getSharedPreferences(
        "lucid_watch_app_preferences", Context.MODE_PRIVATE
    )

    fun getString(key: String, defaultValue: String? = null): String? {
        return sharedPreferences.getString(key, defaultValue)
    }

    fun putString(key: String, value: String) {
        sharedPreferences.edit().putString(key, value).apply()
    }

    fun getInt(key: String, defaultValue: Int = 0): Int {
        return sharedPreferences.getInt(key, defaultValue)
    }

    fun putInt(key: String, value: Int) {
        sharedPreferences.edit().putInt(key, value).apply()
    }

    fun getBoolean(key: String, defaultValue: Boolean = false): Boolean {
        return sharedPreferences.getBoolean(key, defaultValue)
    }

    fun putBoolean(key: String, value: Boolean) {
        sharedPreferences.edit().putBoolean(key, value).apply()
    }

    fun clear() {
        sharedPreferences.edit().clear().apply()
    }

    fun <T> getValueForKey(
        sharedPreferencesData: SharedPreferencesData, type: PreferenceType, defaultValue: T
    ) = callbackFlow {
        val listener = SharedPreferences.OnSharedPreferenceChangeListener { _, key ->
            if (sharedPreferencesData.name == key) {
                when (type) {
                    PreferenceType.StringType -> {
                        val value = getString(key, defaultValue as String) as T
                        trySend(value)
                    }

                    PreferenceType.IntType -> {
                        val value = getInt(key, defaultValue as Int) as T
                        trySend(value)
                    }

                    PreferenceType.BoolType -> {
                        val value = getBoolean(key, defaultValue as Boolean) as T
                        trySend(value)
                    }
                }
            }
        }
        sharedPreferences.registerOnSharedPreferenceChangeListener(listener)
        if (sharedPreferences.contains(sharedPreferencesData.name)) {
            val key = sharedPreferencesData.name
            when (type) {
                PreferenceType.StringType -> {
                    val value = getString(key, defaultValue as String) as T
                    trySend(value)
                }

                PreferenceType.IntType -> {
                    val value = getInt(key, defaultValue as Int) as T
                    trySend(value)
                }

                PreferenceType.BoolType -> {
                    val value = getBoolean(key, defaultValue as Boolean) as T
                    trySend(value)
                }
            }
        }
        awaitClose { sharedPreferences.unregisterOnSharedPreferenceChangeListener(listener) }
    }.buffer(Channel.UNLIMITED) //  so trySend never fails
}

sealed class PreferenceType {
    object StringType : PreferenceType()
    object IntType : PreferenceType()
    object BoolType : PreferenceType()
}


enum class SharedPreferencesData {
    LucidSettings, isUserLogin;

    fun getKey() = "/${name}"
}