package io.nextsense.android.budz.manager

import com.google.android.gms.auth.api.signin.GoogleSignInOptions
import com.google.firebase.Timestamp

import com.google.firebase.auth.AuthResult
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.auth.GoogleAuthProvider
import io.nextsense.android.budz.BudzApplication
import io.nextsense.android.budz.R
import io.nextsense.android.budz.State
import io.nextsense.android.budz.model.User
import io.nextsense.android.budz.model.UserType
import io.nextsense.android.budz.model.UsersRepository
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.flow.flowOn

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

    lateinit var currentUserId: String
    val isSignedIn: Boolean
        get() = firebaseAuth.currentUser != null

    private val firebaseAuth = FirebaseAuth.getInstance()

    suspend fun signInFirebase(token: String) = flow<State<User>> {
        val credential = GoogleAuthProvider.getCredential(token, null)
        val authResult: AuthResult = firebaseAuth.signInWithCredential(credential).await()
        if (authResult.user != null) {
            currentUserId = authResult.user!!.uid
            val email = firebaseAuth.currentUser?.email
            val name = firebaseAuth.currentUser?.displayName
            val userGetState = usersRepository.getUser(currentUserId).let { userGetState ->
                if (userGetState is State.Success) {
                    if (userGetState.data == null) {
                        val newUser = User(email = email!!, name = name, type = UserType.consumer,
                            createdAt = Timestamp.now())
                        usersRepository.addUser(newUser, currentUserId).let {userAddState ->
                            if (userAddState is State.Success) {
                                emit(State.Success(newUser))
                            } else {
                                emit(State.failed(userAddState.toString()))
                            }
                        }
                    } else {
                        emit(State.Success(userGetState.data))
                    }
                } else {
                    emit(State.failed(userGetState.toString()))
                }
            }
        } else {
            emit(State.failed("Failed to sign in with Firebase."))
        }
    }.flowOn(Dispatchers.IO)

    fun signOut() {
        firebaseAuth.signOut()
    }
}