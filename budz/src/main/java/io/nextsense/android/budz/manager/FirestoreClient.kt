package io.nextsense.android.budz.manager

import android.util.Log
import com.google.firebase.Firebase
import com.google.firebase.firestore.firestore
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class FirestoreClient @Inject constructor() {

    private enum class Table {
        USERS,
        SESSIONS,
        DATA_SESSIONS,
        EVENTS;

        fun tableName() = name.lowercase()
    }

    private val tag = FirestoreClient::class.java.simpleName
    private val db = Firebase.firestore
    private val rootRefPath = "consumer/v2/"

    val usersRef = db.collection(rootRefPath + Table.USERS.tableName())

    init {
        Log.d(tag, "FirestoreClient initialized.")
    }
}