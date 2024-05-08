package io.nextsense.android.budz.ui.activities

import androidx.lifecycle.ViewModel
import dagger.hilt.android.lifecycle.HiltViewModel
import io.nextsense.android.budz.manager.GoogleAuth
import javax.inject.Inject

@HiltViewModel
class HomeViewModel @Inject constructor(): ViewModel() {

    @Inject lateinit var googleAuth: GoogleAuth

    fun signOut() {
        googleAuth.signOut()
    }
}