package io.nextsense.android.main.utils

import android.util.Log
import io.nextsense.android.main.TAG

class Logger(private val tag: String? = TAG) {
    fun log(msg: Any?) {
        Log.i(tag, "$msg")
    }
}