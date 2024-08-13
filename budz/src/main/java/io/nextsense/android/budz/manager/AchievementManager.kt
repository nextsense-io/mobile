package io.nextsense.android.budz.manager

import io.nextsense.android.algo.signal.BandPowerAnalysis
import kotlin.math.abs

enum class Gem(val label: String, val description: String,val delta: Int, val theta: Int,
               val alpha: Int, val beta: Int, val gamma: Int) {
    DIAMOND("Diamond","Ultimate balance, coherence, and focused state", 0, 15, 30, 30, 0),
    RUBY("Ruby","Relaxed but focused", 0, 25, 20, 15, 0),
    QUARTZ("Quartz", "Amplifies energy and thought, for brainstorming sessions",0, 5, 10, 40, 0),
    OPAL("Opal","Energetic and enthusiastic, boosts vitality", 0, 30, 15, 10, 0),
    SAPPHIRE("Sapphire","Calm and serene, ideal for meditation", 0, 20, 25, 10, 0),
    EMERALD("Emerald","Creative and open-minded state", 0, 22, 18, 25, 0),
    AMETHYST("Amethyst", "Introspective and insightful, good for deep thinking", 0, 35, 10, 5, 0),
    TOPAZ("Topaz", "Clarity and decision-making, great for problem solving", 0, 10, 15, 35, 0),
    JADE("Jade","Peaceful and harmonious, for stress relief", 0, 25, 25, 10, 0),
    TURQUOISE("Turquoise", "Healing and recuperative, for recovery phases", 0, 15, 20, 20, 0),
    GARNET("Garnet", "Revitalizing and restoring, boosts motivation",0, 10, 12, 40, 0),
    PEARL("Pearl","Pure and clear-minded, aids in emotional balance", 0, 18, 30, 8, 0),
    ONYX("Onyx", "Strength and resilience, for overcoming challenge",0, 30, 20, 10, 0),
    CITRINE("Citrine", "Joyful and uplifting, enhances positivity", 0, 20, 15, 25, 0),
    AQUAMARINE("Aquamarine", "Soothing and calming, great for anxiety reduction",0, 10, 20, 30, 0);

    companion object {
        fun fromLabel(label: String): Gem {
            return values().first { it.label == label }
        }
    }

    fun getRatios() : List<Float> {
        val total = theta + alpha + beta
        val multiplyRatio = 100F / total
        return listOf(theta * multiplyRatio, alpha * multiplyRatio, beta * multiplyRatio)
    }
}

object AchievementManager {

    fun getClosestGem(bandPowers: Map<BandPowerAnalysis.Band, Float>) : Gem {
        val ratios = bandPowers.map { it.value }
        val closestGem = Gem.values().minByOrNull {
            val gemRatios = it.getRatios()
            abs(ratios[0] - gemRatios[0]) + abs(ratios[1] - gemRatios[1]) +
                    abs(ratios[2] - gemRatios[2])
        }
        return closestGem ?: Gem.DIAMOND
    }
}