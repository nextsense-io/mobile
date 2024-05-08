package io.nextsense.android.budz.model

import com.google.firebase.firestore.DocumentReference
import com.google.firebase.firestore.SetOptions
import io.nextsense.android.budz.State
import io.nextsense.android.budz.manager.FirestoreClient
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.flow.flowOn
import kotlinx.coroutines.tasks.await
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class UsersRepository @Inject constructor() {

    @Inject lateinit var firestoreClient: FirestoreClient

    /**
     * Adds user [user] into the cloud firestore collection.
     * @return The Flow of [State] which will store state of current action.
     */
    fun addUser(user: User, userId: String) = flow<State<DocumentReference>> {
        emit(State.loading())
        val userRef = firestoreClient.usersRef.document(userId)
        userRef.set(user).await()
        emit(State.success(userRef))
    }.catch {
        // If exception is thrown, emit failed state along with message.
        emit(State.failed(it.message.toString()))
    }.flowOn(Dispatchers.IO)

    /**
     * Updates user [user] into the cloud firestore collection.
     * @return The Flow of [State] which will store state of current action.
     */
    fun updateUser(user: User, userId: String) = flow<State<DocumentReference>> {
        emit(State.loading())
        val userRef = firestoreClient.usersRef.document(userId)
        userRef.set(user, SetOptions.merge()).await()
        emit(State.success(userRef))
    }.catch {
        // If exception is thrown, emit failed state along with message.
        emit(State.failed(it.message.toString()))
    }.flowOn(Dispatchers.IO)

    /**
     * Fetches user from the cloud firestore collection.
     * @return The Flow of [State] which will store state of current action.
     */
    fun getUser(id: String) = flow<State<User?>> {
        emit(State.loading())
        val userSnapshot =
            firestoreClient.usersRef.document(id).get().await()
        if (userSnapshot.exists()) {
            val user = userSnapshot.toObject(User::class.java)
            emit(State.success(user))
        } else {
            emit(State.success(null))
        }
    }.flowOn(Dispatchers.IO)

    /**
     * Fetches user from the cloud firestore collection by email.
     * @return The Flow of [State] which will store state of current action.
     */
    fun getUserByEmail(email: String) = flow<State<User?>> {
        emit(State.loading())
        val userSnapshot =
            firestoreClient.usersRef.whereEqualTo(UserKeys.EMAIL.key(), email).get().await()
        if (userSnapshot.isEmpty) {
            emit(State.success(null))
        } else {
            val user = userSnapshot.documents[0].toObject(User::class.java)
            emit(State.success(user))
        }
    }.flowOn(Dispatchers.IO)
}