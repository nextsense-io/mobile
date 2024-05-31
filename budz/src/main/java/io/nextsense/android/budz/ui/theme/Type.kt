package io.nextsense.android.budz.ui.theme

import androidx.compose.material3.Typography
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.Font
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.sp
import io.nextsense.android.budz.R

val workSansRegularFontFamily =
    FontFamily(
        Font(
            R.font.work_sans_regular
        )
    )

val workSansMediumFontFamily =
    FontFamily(
        Font(
            R.font.work_sans_medium
        )
    )

val workSansSemiBoldFontFamily =
    FontFamily(
        Font(
            R.font.work_sans_semi_bold
        )
    )

val workSansBoldFontFamily =
    FontFamily(
        Font(
            R.font.work_sans_bold
        )
    )

val gowunBatangRegularFontFamily =
    FontFamily(
        Font(
            R.font.gowun_batang_regular
        )
    )

val Typography = Typography(
    // Used for thicker labels in cards content
    displayMedium = TextStyle(
        fontFamily = workSansMediumFontFamily,
        fontWeight = FontWeight.Medium,
        fontSize = 18.sp,
        lineHeight = 24.sp,
        letterSpacing = 0.5.sp
    ),
    // Body text in most screens
    bodyMedium = TextStyle(
        fontFamily = workSansRegularFontFamily,
        fontWeight = FontWeight.Normal,
        fontSize = 18.sp,
        lineHeight = 28.sp,
        letterSpacing = 0.5.sp
    ),
    // Different typography for sleep emphasis inside the big circle
    headlineLarge = TextStyle(
        fontFamily = gowunBatangRegularFontFamily,
        fontWeight = FontWeight.Normal,
        fontSize = 60.sp,
        lineHeight = 80.sp,
        letterSpacing = 0.sp
    ),
    // Used for the title in the top bar for secondary screens
    titleSmall = TextStyle(
        fontFamily = workSansSemiBoldFontFamily,
        fontWeight = FontWeight.SemiBold,
        fontSize = 18.sp,
        lineHeight = 22.sp,
        letterSpacing = 0.sp
    ),
    // Used for the app name title in the top bar
    titleMedium = TextStyle(
        fontFamily = workSansBoldFontFamily,
        fontWeight = FontWeight.Bold,
        fontSize = 26.sp,
        lineHeight = 30.sp,
        letterSpacing = 0.sp
    ),
    // Used for text in small buttons
    labelSmall = TextStyle(
        fontFamily = workSansSemiBoldFontFamily,
        fontWeight = FontWeight.SemiBold,
        fontSize = 14.sp,
        lineHeight = 20.sp,
        letterSpacing = 0.5.sp
    ),
    // Used for action labels and text in card titles
    labelMedium = TextStyle(
        fontFamily = workSansRegularFontFamily,
        fontWeight = FontWeight.Normal,
        fontSize = 16.sp,
        lineHeight = 20.sp,
        letterSpacing = 0.5.sp
    ),
    // Used for the text in large buttons
    labelLarge = TextStyle(
        fontFamily = workSansSemiBoldFontFamily,
        fontWeight = FontWeight.SemiBold,
        fontSize = 20.sp,
        lineHeight = 24.sp,
        letterSpacing = 0.5.sp
    ),
)