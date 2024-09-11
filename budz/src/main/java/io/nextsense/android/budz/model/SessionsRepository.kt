package io.nextsense.android.budz.model

import com.google.firebase.firestore.DocumentReference
import io.nextsense.android.budz.State
import io.nextsense.android.budz.manager.FirestoreClient
import kotlinx.coroutines.tasks.await
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class SessionsRepository @Inject constructor() {

    @Inject
    lateinit var firestoreClient: FirestoreClient

    /**
     * Adds session [session] into the cloud firestore collection.
     * @return The [Session] which will store state of current action.
     */
    suspend fun addSession(session: Session): State<DocumentReference> {
        try {
            val sessionRef = firestoreClient.sessionsRef.document()
            sessionRef.set(session).await()
            return State.success(sessionRef)
        } catch (exception: Exception) {
            return State.failed(exception.message.toString())
        }
    }

    suspend fun addDataSession(dataSession: DataSession, sessionId: String):
            State<DocumentReference> {
        try {
            val dataSessionRef = firestoreClient.dataSessionsRef(sessionId).document()
            dataSessionRef.set(dataSession).await()
            return State.success(dataSessionRef)
        } catch (exception: Exception) {
            return State.failed(exception.message.toString())
        }
    }

    /**
     * Fetches session from the cloud firestore collection.
     * @return The [State] which will store state of current action.
     */
    suspend fun getSession(id: String): State<Session?> {
        val sessionSnapshot = firestoreClient.sessionsRef.document(id).get().await()
        if (sessionSnapshot.exists()) {
            val session = sessionSnapshot.toObject(Session::class.java)
            return State.success(session)
        }
        return State.success(null)
    }

    /**
     * Fetches session from the cloud firestore collection.
     * @return The [State] which will store state of current action.
     */
    suspend fun getDataSession(sessionId: String, dataSessionId: String):
            State<DataSession?> {
        val dataSessionSnapshot = firestoreClient.dataSessionsRef(sessionId).document(
            dataSessionId).get().await()
        if (dataSessionSnapshot.exists()) {
            val dataSession = dataSessionSnapshot.toObject(DataSession::class.java)
            return State.success(dataSession)
        }
        return State.success(null)
    }

    /**
     * Updates session [session] into the cloud firestore collection.
     * @return The [State] which will store state of current action.
     */
    suspend fun updateSession(session: Session, sessionId: String): State<DocumentReference> {
        try {
            val sessionRef = firestoreClient.sessionsRef.document(sessionId)
            sessionRef.set(session).await()
            return State.success(sessionRef)
        } catch (exception: Exception) {
            return State.failed(exception.message.toString())
        }
    }

    /**
     * Updates data session [dataSession] into the cloud firestore collection.
     * @return The [State] which will store state of current action.
     */
    suspend fun updateDataSession(dataSession: DataSession, sessionId: String,
                                  dataSessionId: String): State<DocumentReference> {
        try {
            val dataSessionRef = firestoreClient.dataSessionsRef(sessionId).document(
                dataSessionId
            )
            dataSessionRef.set(dataSession).await()
            return State.success(dataSessionRef)
        } catch (exception: Exception) {
            return State.failed(exception.message.toString())
        }
    }

    suspend fun deleteSession(sessionId: String): State<Unit> {
        try {
            firestoreClient.sessionsRef.document(sessionId).delete().await()
            return State.success(Unit)
        } catch (exception: Exception) {
            return State.failed(exception.message.toString())
        }
    }
}