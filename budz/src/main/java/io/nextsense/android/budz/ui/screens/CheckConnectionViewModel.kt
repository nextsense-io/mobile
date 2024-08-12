package io.nextsense.android.budz.ui.screens

import android.content.Context
import dagger.hilt.android.lifecycle.HiltViewModel
import dagger.hilt.android.qualifiers.ApplicationContext
import io.nextsense.android.budz.manager.AirohaDeviceManager
import io.nextsense.android.budz.manager.SignalStateManager
import javax.inject.Inject

@HiltViewModel
class CheckConnectionViewModel @Inject constructor(
    @ApplicationContext context: Context,
    airohaDeviceManagerParam: AirohaDeviceManager,
    signalStateManagerParam: SignalStateManager
): SignalVisualizationViewModel(context, airohaDeviceManagerParam, signalStateManagerParam)