package io.nextsense.android.budz.manager

import io.nextsense.android.algo.signal.BandPowerAnalysis
import org.junit.Assert.assertEquals
import org.junit.Test

class GemTest {

    @Test
    fun testFromLabel() {
        val diamond = Gem.fromLabel("Diamond")
        assertEquals(Gem.DIAMOND, diamond)

        val ruby = Gem.fromLabel("Ruby")
        assertEquals(Gem.RUBY, ruby)

        val opal = Gem.fromLabel("Opal")
        assertEquals(Gem.OPAL, opal)
    }

    @Test(expected = NoSuchElementException::class)
    fun testFromLabel_invalidLabel() {
        Gem.fromLabel("Invalid")
    }

    @Test
    fun testGetRatios() {
        val diamondRatios = Gem.DIAMOND.getRatios()
        assertEquals(listOf(20f, 40f, 40f), diamondRatios)

        val rubyRatios = Gem.RUBY.getRatios()
        assertEquals(arrayListOf(41, 33, 25), rubyRatios.map { it.toInt() })

        val quartzRatios = Gem.QUARTZ.getRatios()
        assertEquals(listOf(9, 18, 72), quartzRatios.map { it.toInt() })
    }
}

class AchievementManagerTest {

    @Test
    fun testGetClosestGem() {
        val bandPowers = mapOf(
            BandPowerAnalysis.Band.THETA to 20f,
            BandPowerAnalysis.Band.ALPHA to 40f,
            BandPowerAnalysis.Band.BETA to 40f
        )

        val closestGem = AchievementManager.getClosestGem(bandPowers)
        assertEquals(Gem.DIAMOND, closestGem)

        val bandPowersRuby = mapOf(
            BandPowerAnalysis.Band.THETA to 41f,
            BandPowerAnalysis.Band.ALPHA to 33f,
            BandPowerAnalysis.Band.BETA to 25f
        )

        val closestGemRuby = AchievementManager.getClosestGem(bandPowersRuby)
        assertEquals(Gem.RUBY, closestGemRuby)
    }
}
