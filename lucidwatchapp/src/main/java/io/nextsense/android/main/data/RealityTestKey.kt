package io.nextsense.android.main.data

import com.google.gson.Gson

data class RealityTest(
    val name: String, val description: String, val totemSound: String, val type: String
) {
    companion object {
        fun fromJson(jsonString: String?): RealityTest {
            val realityTest: RealityTest? = try {
                val gson = Gson()
                gson.fromJson(jsonString, RealityTest::class.java)
            } catch (e: Exception) {
                null
            }
            return realityTest ?: RealityTest(
                name = "BREATHE",
                description = "Can you hold your nose and mouth shut and breathe?",
                totemSound = "AIR",
                type = "m4r"
            )
        }
    }
}
