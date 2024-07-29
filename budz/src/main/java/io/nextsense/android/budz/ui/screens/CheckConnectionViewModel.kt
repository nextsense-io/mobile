package io.nextsense.android.budz.ui.screens

import dagger.hilt.android.lifecycle.HiltViewModel
import io.nextsense.android.budz.manager.AirohaDeviceManager
import javax.inject.Inject

data class CheckConnectionState(
    val connected: Boolean = false
)

@HiltViewModel
class CheckConnectionViewModel @Inject constructor(val airohaDeviceManager: AirohaDeviceManager):
        SignalVisualizationViewModel(airohaDeviceManager)