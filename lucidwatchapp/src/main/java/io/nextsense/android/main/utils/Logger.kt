package io.nextsense.android.main.utils

import android.util.Log
import io.nextsense.android.main.TAG

class Logger {
    fun log(msg: Any?) {
        Log.i(TAG, "$msg")
    }
}