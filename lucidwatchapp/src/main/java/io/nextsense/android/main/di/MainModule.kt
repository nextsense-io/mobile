/*
 * Copyright 2022 The Android Open Source Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      https://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package io.nextsense.android.main.di

import android.content.Context
import android.util.Log
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import io.nextsense.android.main.TAG
import io.nextsense.android.main.data.HealthServicesRepository
import io.nextsense.android.main.data.LocalDatabaseManager
import io.nextsense.android.main.utils.Logger
import io.nextsense.android.main.utils.SleepStagePredictionHelper
import org.tensorflow.lite.Interpreter
import org.tensorflow.lite.support.common.FileUtil
import javax.inject.Singleton

/**
 * Hilt module that provides singleton (application-scoped) objects.
 */
@Module
@InstallIn(SingletonComponent::class)
class MainModule {

    @Singleton
    @Provides
    fun provideHealthServicesRepository(@ApplicationContext context: Context): HealthServicesRepository =
        HealthServicesRepository(context)

    @Singleton
    @Provides
    fun provideLocalDatabaseManager(@ApplicationContext context: Context): LocalDatabaseManager =
        LocalDatabaseManager(context)

    @Singleton
    @Provides
    fun provideSleepStagePredictionHelper(@ApplicationContext context: Context): SleepStagePredictionHelper =
        SleepStagePredictionHelper(context, providePredictionMLModel(context))

    @Singleton
    @Provides
    fun providePredictionMLModel(@ApplicationContext context: Context): Interpreter? = try {
        Interpreter(
            FileUtil.loadMappedFile(
                context, SleepStagePredictionHelper.MODEL_FILE
            )
        )
    } catch (e: Exception) {
        Log.i(TAG, "Failed to load core ml model: $e")
        null
    }

    @Singleton
    @Provides
    fun provideLogger(): Logger = Logger()

}
