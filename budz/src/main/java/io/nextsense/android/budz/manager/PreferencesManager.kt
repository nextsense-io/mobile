package io.nextsense.android.budz.manager

import android.content.Context
import android.content.SharedPreferences
import dagger.hilt.android.qualifiers.ApplicationContext
import javax.inject.Inject
import javax.inject.Singleton

enum class PreferenceKeys(private val defaultValue: Any) {
    SLEEP_MODE(false),
    TOUCH_CONTROLS_DISABLED(true),
    VOICE_PROMPTS_DISABLED(true);

    fun <T> getDefaultValue(): T {
        return defaultValue as T
    }
}

@Singleton
class PreferencesManager @Inject constructor(
    @ApplicationContext private val context: Context
) {
    private val _preferences = context.getSharedPreferences("io.nextsense.android.budz",
        Context.MODE_PRIVATE)

    val prefs: SharedPreferences
        get() = _preferences
}