package io.nextsense.android.budz.model

import com.google.firebase.firestore.DocumentReference
import com.google.firebase.firestore.SetOptions
import io.nextsense.android.budz.State
import io.nextsense.android.budz.manager.FirestoreClient
import kotlinx.coroutines.tasks.await
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class UsersRepository @Inject constructor() {

    @Inject lateinit var firestoreClient: FirestoreClient
    var cachedUser: User? = null

    /**
     * Adds user [user] into the cloud firestore collection.
     * @return The [State] which will store state of current action.
     */
    suspend fun addUser(user: User, userId: String): State<DocumentReference> {
        try {
            val userRef = firestoreClient.usersRef.document(userId)
            userRef.set(user).await()
            cachedUser = user
            return State.success(userRef)
        } catch (exception: Exception) {
            // If exception is thrown, emit failed state along with message.
            return State.failed(exception.message.toString())
        }
    }

    /**
     * Updates user [user] into the cloud firestore collection.
     * @return The [State] which will store state of current action.
     */
    suspend fun updateUser(user: User, userId: String): State<DocumentReference> {
        try {
            val userRef = firestoreClient.usersRef.document(userId)
            userRef.set(user, SetOptions.merge()).await()
            cachedUser = user
            return State.success(userRef)
        } catch (exception: Exception) {
            // If exception is thrown, emit failed state along with message.
            return State.failed(exception.message.toString())
        }
    }

    /**
     * Fetches user from the cloud firestore collection.
     * @return The [State] which will store state of current action.
     */
    suspend fun getUser(id: String): State<User?> {
        if (cachedUser != null) {
            return State.success(cachedUser)
        }
        val userSnapshot = firestoreClient.usersRef.document(id).get().await()
        if (userSnapshot.exists()) {
            val user = userSnapshot.toObject(User::class.java)
            cachedUser = user
            return State.success(user)
        } else {
            return State.success(null)
        }
    }

    /**
     * Fetches user from the cloud firestore collection by email.
     * @return The Flow of [State] which will store state of current action.
     */
    suspend fun getUserByEmail(email: String): State<User?> {
        val userSnapshot =
            firestoreClient.usersRef.whereEqualTo(UserKeys.EMAIL.key(), email).get().await()
        if (userSnapshot.isEmpty) {
            return State.success(null)
        } else {
            val user = userSnapshot.documents[0].toObject(User::class.java)
            return State.success(user)
        }
    }
}