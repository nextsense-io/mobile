package io.nextsense.android.budz.ui.screens

import dagger.hilt.android.lifecycle.HiltViewModel
import io.nextsense.android.budz.manager.AirohaDeviceManager
import io.nextsense.android.budz.manager.SignalStateManager
import javax.inject.Inject

@HiltViewModel
class CheckConnectionViewModel @Inject constructor(
    airohaDeviceManagerParam: AirohaDeviceManager,
    signalStateManagerParam: SignalStateManager
): SignalVisualizationViewModel(airohaDeviceManagerParam, signalStateManagerParam)