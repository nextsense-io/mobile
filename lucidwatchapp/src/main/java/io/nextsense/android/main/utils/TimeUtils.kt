package io.nextsense.android.main.utils

import java.util.concurrent.TimeUnit

fun minutesToMilliseconds(minutes: Int) = minutes * 60 * 1000

fun Long.toSeconds() = TimeUnit.MILLISECONDS.toSeconds(this)
