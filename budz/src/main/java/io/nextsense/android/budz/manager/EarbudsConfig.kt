package io.nextsense.android.budz.manager

enum class EarEegChannel(val alias: String) {
    ERW_ELC(""), // Ear Right Whole Canal - Ear Left Cymba
    ELW_ELC("Left"), // Ear Left Whole Canal - Ear Left Cymba
    ELC_ELW(""), // Ear Left Cymba - Ear Left Whole Canal
    ELC_ERC(""), // Ear Left Cymba - Ear Right Cymba
    ELC_ERW(""), // Ear Left Cymba - Ear Right Whole Canal
    ERW_ELW(""), // Ear Right Whole Canal - Ear Left Whole Canal
    ELW_ERW(""), // Ear Left Whole Canal - Ear Right Whole Canal
    ELW_ERC(""), // Ear Left Whole Canal - Ear Right Cymba
    ERW_ERC("Right"), // Ear Right Whole Canal - Ear Right Cymba
    ERC_ERW(""), // Ear Right Cymba - Ear Right Whole Canal
    ERC_ELW("");  // Ear Right Cymba - Ear Left Whole Canal

    companion object {
        fun getChannelByAlias(alias: String): EarEegChannel {
            return values().first { it.alias == alias }
        }
    }
}

enum class ChannelOperator {
    ADDITION,
    SUBTRACTION
}

enum class EarLocationName {
    RIGHT_HELIX,
    RIGHT_CANAL,
    LEFT_HELIX,
    LEFT_CANAL
}

enum class EarbudsConfigNames {
    XENON_B_CONFIG,
    XENON_P02_CONFIG,
    KAUAI_MEDICAL_CONFIG,
    NITRO_CONFIG,
    MAUI_CONFIG;

    fun key() = name.lowercase()
}

class ImpedanceConfig private constructor(
    private val firstChannel: Int,
    private val channelOperator: ChannelOperator? = null,
    private val secondChannel: Int? = null
) {
    companion object {
        fun create(
            firstChannel: Int,
            channelOperator: ChannelOperator? = null,
            secondChannel: Int? = null
        ): ImpedanceConfig {
            if (channelOperator != null || secondChannel != null) {
                if (channelOperator == null || secondChannel == null) {
                    throw IllegalArgumentException("Both channelOperator and secondChannel need " +
                            "to be provided if one of them is provided.")
                }
                return ImpedanceConfig(firstChannel, channelOperator, secondChannel)
            }
            return ImpedanceConfig(firstChannel)
        }
    }

    override fun toString(): String {
        var text = "$firstChannel"
        if (secondChannel != null) {
            text += " ${channelOperator.toString()} $secondChannel"
        }
        return text
    }
}

class EarLocation(
    val name: EarLocationName,
    val impedanceConfig: ImpedanceConfig? = null
) {
    fun getDisplayName(): String {
        return name.name.lowercase().replace('_', ' ')
    }
}

class EarbudsConfig(
    val name: String,
    val channelsConfig: Map<Int, EarEegChannel>,
    val earLocations: Map<EarLocationName, EarLocation>,
    val bestSignalChannel: Int
)

object EarbudsConfigs {
    private val earbudsConfigs: Map<String, EarbudsConfig> = mapOf(
        EarbudsConfigNames.XENON_B_CONFIG.key() to EarbudsConfig(
            name = EarbudsConfigNames.XENON_B_CONFIG.name.lowercase(),
            channelsConfig = mapOf(
                1 to EarEegChannel.ERW_ELC,
                3 to EarEegChannel.ELW_ELC,
                6 to EarEegChannel.ELW_ERW,
                7 to EarEegChannel.ELW_ERC,
                8 to EarEegChannel.ERW_ERC
            ),
            earLocations = mapOf(
                EarLocationName.RIGHT_CANAL to EarLocation(
                    name = EarLocationName.RIGHT_CANAL,
                    impedanceConfig = ImpedanceConfig.create(firstChannel = 8)
                ),
                EarLocationName.RIGHT_HELIX to EarLocation(name = EarLocationName.RIGHT_HELIX),
                EarLocationName.LEFT_CANAL to EarLocation(
                    name = EarLocationName.LEFT_CANAL,
                    impedanceConfig = ImpedanceConfig.create(firstChannel = 7)
                ),
                EarLocationName.LEFT_HELIX to EarLocation(
                    name = EarLocationName.LEFT_HELIX,
                    impedanceConfig = ImpedanceConfig.create(
                        firstChannel = 8,
                        channelOperator = ChannelOperator.SUBTRACTION,
                        secondChannel = 1
                    )
                )
            ),
            bestSignalChannel = 6
        ),
        EarbudsConfigNames.KAUAI_MEDICAL_CONFIG.key() to EarbudsConfig(
            name = EarbudsConfigNames.KAUAI_MEDICAL_CONFIG.name.lowercase(),
            channelsConfig = mapOf(
                1 to EarEegChannel.ERW_ERC,
                2 to EarEegChannel.ELW_ERC,
                3 to EarEegChannel.ELC_ERC,
                4 to EarEegChannel.ERW_ELW,
                5 to EarEegChannel.ELW_ELC,
                6 to EarEegChannel.ELC_ERW
            ),
            earLocations = mapOf(
                EarLocationName.RIGHT_CANAL to EarLocation(
                    name = EarLocationName.RIGHT_CANAL,
                    impedanceConfig = ImpedanceConfig.create(firstChannel = 1)
                ),
                EarLocationName.RIGHT_HELIX to EarLocation(name = EarLocationName.RIGHT_HELIX),
                EarLocationName.LEFT_CANAL to EarLocation(
                    name = EarLocationName.LEFT_CANAL,
                    impedanceConfig = ImpedanceConfig.create(firstChannel = 2)
                ),
                EarLocationName.LEFT_HELIX to EarLocation(
                    name = EarLocationName.LEFT_HELIX,
                    impedanceConfig = ImpedanceConfig.create(
                        firstChannel = 1,
                        channelOperator = ChannelOperator.SUBTRACTION,
                        secondChannel = 6
                    )
                )
            ),
            bestSignalChannel = 4
        ),
        EarbudsConfigNames.XENON_P02_CONFIG.key() to EarbudsConfig(
            name = EarbudsConfigNames.XENON_P02_CONFIG.name.lowercase(),
            channelsConfig = mapOf(
                1 to EarEegChannel.ELC_ELW,
                2 to EarEegChannel.ERC_ERW,
                3 to EarEegChannel.ELC_ERW,
                4 to EarEegChannel.ERC_ELW,
                6 to EarEegChannel.ERW_ELW
            ),
            earLocations = mapOf(
                EarLocationName.RIGHT_CANAL to EarLocation(
                    name = EarLocationName.RIGHT_CANAL,
                    impedanceConfig = ImpedanceConfig.create(firstChannel = 1)
                ),
                EarLocationName.RIGHT_HELIX to EarLocation(name = EarLocationName.RIGHT_HELIX),
                EarLocationName.LEFT_CANAL to EarLocation(
                    name = EarLocationName.LEFT_CANAL,
                    impedanceConfig = ImpedanceConfig.create(firstChannel = 2)
                ),
                EarLocationName.LEFT_HELIX to EarLocation(
                    name = EarLocationName.LEFT_HELIX,
                    impedanceConfig = ImpedanceConfig.create(
                        firstChannel = 1,
                        channelOperator = ChannelOperator.SUBTRACTION,
                        secondChannel = 6
                    )
                )
            ),
            bestSignalChannel = 6
        ),
        EarbudsConfigNames.MAUI_CONFIG.key() to EarbudsConfig(
            name = EarbudsConfigNames.MAUI_CONFIG.name.lowercase(),
            channelsConfig = mapOf(
                1 to EarEegChannel.ELW_ELC,
                2 to EarEegChannel.ERW_ERC
            ),
            earLocations = mapOf(
                EarLocationName.LEFT_CANAL to EarLocation(
                    name = EarLocationName.LEFT_CANAL,
                    impedanceConfig = ImpedanceConfig.create(firstChannel = 1)
                ),
                EarLocationName.RIGHT_CANAL to EarLocation(
                    name = EarLocationName.RIGHT_CANAL,
                    impedanceConfig = ImpedanceConfig.create(firstChannel = 2)
                ),
            ),
            bestSignalChannel = 1
        )
    )

    fun getEarbudsConfig(name: String): EarbudsConfig {
        return earbudsConfigs[name.lowercase()] ?:
            throw IllegalArgumentException("Earbuds config with name $name not found.")
    }
}