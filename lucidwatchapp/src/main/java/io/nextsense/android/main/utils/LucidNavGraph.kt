package io.nextsense.android.main.utils

import com.ramcosta.composedestinations.annotation.NavGraph
import com.ramcosta.composedestinations.annotation.RootNavGraph

@RootNavGraph(start = true)
@NavGraph
annotation class LucidNavGraph(val start: Boolean = false)
