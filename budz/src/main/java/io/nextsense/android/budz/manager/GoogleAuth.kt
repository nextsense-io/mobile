package io.nextsense.android.budz.manager

import com.google.android.gms.auth.api.signin.GoogleSignInOptions
import com.google.android.gms.tasks.Task
import com.google.firebase.auth.AuthResult
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.auth.GoogleAuthProvider
import io.nextsense.android.budz.BudzApplication
import io.nextsense.android.budz.R
import io.nextsense.android.budz.State
import io.nextsense.android.budz.model.User
import io.nextsense.android.budz.model.UsersRepository
import kotlinx.coroutines.flow.last
import kotlinx.coroutines.flow.single
import kotlinx.coroutines.tasks.await
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class GoogleAuth @Inject constructor() {

    @Inject lateinit var usersRepository: UsersRepository

    val gso = GoogleSignInOptions.Builder(GoogleSignInOptions.DEFAULT_SIGN_IN)
        .requestIdToken(BudzApplication.instance.getString(R.string.web_client_id))
        .requestEmail()
        .build()

    var email: String? = null
    var user: User? = null
    val isSignedIn: Boolean
        get() = firebaseAuth.currentUser != null

    private val firebaseAuth = FirebaseAuth.getInstance()

    suspend fun signInFirebase(token: String) : Boolean {
        val credential = GoogleAuthProvider.getCredential(token, null)
        val authResult: AuthResult = firebaseAuth.signInWithCredential(credential).await()
        return authResult.user != null
//        if (authResult.user != null) {
//            email = firebaseAuth.currentUser?.email
//            user = usersRepository.getUser(email!!).last() { state ->
//                {
//                    when
//                }
//            }
//        }
    }
}