package io.nextsense.android.base.utils;

import android.annotation.SuppressLint;
import android.content.Context;
import android.util.Log;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.Arrays;
import java.util.Collections;
import java.util.Comparator;
import java.util.Date;
import java.util.Locale;

import io.nextsense.android.base.BuildConfig;

/**
 * A logger that writes to a file in the app's private directory. The files are named daily_log.txt
 * and daily_log_old.txt. If the daily_log.txt is at least 24h old, it is renamed to
 * daily_log_old.txt and a new daily_log.txt is created. The content of the old file is deleted.
 */
public class RotatingFileLogger {
  private static final String TAG = RotatingFileLogger.class.getSimpleName();
  private static final String LOG_DIR_NAME = "logs";
  private static final String LOG_DATE_TIME_FORMAT = "yyyy-MM-dd hh:mm:ss.SSS";
  private static final String LOG_FILE_NAME_PREFIX = "daily_log_";
  private static final String LOG_FILE_NAME_SUFFIX = ".txt";
  private static final int DAY_IN_MILLIS = 24 * 60 * 60 * 1000; // Milliseconds in a day

  private static RotatingFileLogger sInstance;
  private final SimpleDateFormat logFileNameFormat =
      new SimpleDateFormat("'daily_log_'yyyy-MM-dd'.txt'", Locale.getDefault());

  @SuppressLint("ConstantLocale")
  private final SimpleDateFormat dateTimeFormat = new SimpleDateFormat(
      LOG_DATE_TIME_FORMAT, Locale.getDefault());
  private final File logDir;

  public static synchronized void initialize(Context context) {
    if (sInstance == null) {
      sInstance = new RotatingFileLogger(context);
    }
  }

  public static synchronized RotatingFileLogger get() {
    if (sInstance == null) {
      throw new IllegalStateException("DailyFileLogger not initialized");
    }
    return sInstance;
  }

  private RotatingFileLogger(Context context) {
    logDir = new File(context.getFilesDir(), LOG_DIR_NAME);
    if (!logDir.exists()) {
      boolean created = logDir.mkdirs();
      if (!created) {
        RotatingFileLogger.get().loge(TAG, "Error creating log directory: " + logDir.getAbsolutePath());
      }
    }
    Log.i(TAG, "DailyFileLogger initialized");
    cleanOldLogFiles();
  }

  public void logv(String tag, String message) {
    if (BuildConfig.DEBUG && BuildConfig.BUILD_TYPE.equals("debug")) {
      Log.v(tag, message);
      logToFile(tag, "VERBOSE", message);
    }
  }

  public void logd(String tag, String message) {
    if (BuildConfig.DEBUG && BuildConfig.BUILD_TYPE.equals("debug")) {
      Log.d(tag, message);
      logToFile(tag, "DEBUG", message);
    }
  }

  public void logi(String tag, String message) {
    Log.i(tag, message);
    logToFile(tag, "INFO", message);
  }

  public void logw(String tag, String message) {
    Log.w(tag, message);
    logToFile(tag, "WARNING", message);
  }

  public void loge(String tag, String message) {
    Log.e(tag, message);
    logToFile(tag, "ERROR", message);
  }

  // Returns the concatenation of the previous and current log files. This will ensure that there is
  // at least 24h of data if the app has been running for that long, and up to 48 hours at most.
  public String getAtLeast24HoursLogs() {
    StringBuilder logTextBuilder = new StringBuilder();
    File[] logFiles = listLogFiles();
    if (logFiles == null || logFiles.length == 0) {
      return logTextBuilder.toString();
    }
    Arrays.sort(logFiles, Collections.reverseOrder());
    int numFiles = Math.min(logFiles.length, 2);
    for (int i = 0; i < numFiles; i++) {
      File logFile = logFiles[i];
      logTextBuilder.append(readLogFile(logFile));
    }
    return logTextBuilder.toString();
  }

  private File[] listLogFiles() {
    if (!logDir.exists()) {
      return new File[0];
    }
    File[] logFiles = logDir.listFiles(
        (dir, name) -> name.startsWith(LOG_FILE_NAME_PREFIX) &&
            name.endsWith(LOG_FILE_NAME_SUFFIX));
    if (logFiles == null || logFiles.length == 0) {
      return new File[0];
    }
    Arrays.sort(logFiles, Collections.reverseOrder(Comparator.comparingLong(File::lastModified)));
    return logFiles;
  }

  private String readLogFile(File logFile) {
    StringBuilder sb = new StringBuilder();
    try (BufferedReader reader = new BufferedReader(new FileReader(logFile))) {
      String line;
      while ((line = reader.readLine()) != null) {
        sb.append(line).append("\n");
      }
    } catch (IOException e) {
      Log.e(TAG, "Error reading log file " + logFile.getAbsolutePath(), e);
    }
    return sb.toString();
  }

  private void logToFile(String tag, String severity, String message) {
    File logFile = getLogFile();
    try (FileWriter writer = new FileWriter(logFile, true)) {
      writer.write(getCurrentTimestamp() + ": " + tag + ": " + severity + ": " + message + "\n");
    } catch (IOException e) {
      Log.e(TAG, "Error writing to log file", e);
    }
  }

  private void cleanOldLogFiles() {
    File[] logFiles = listLogFiles();
    if (logFiles.length <= 2) {
      return;
    }
    Arrays.sort(logFiles, Collections.reverseOrder());
    long currentTime = System.currentTimeMillis();
    for (int i = 2; i < logFiles.length; i++) {
      File logFile = logFiles[i];
      String logFileName = logFile.getName();
      try {
        Date logFileDate = logFileNameFormat.parse(logFileName);
        long logFileTime = logFileDate.getTime();
        if (currentTime - logFileTime >= 2 * DAY_IN_MILLIS) {
          if (logFile.delete()) {
            Log.d(TAG, "Deleted old log file: " + logFile.getName());
          } else {
            Log.w(TAG, "Failed to delete old log file: " + logFile.getName());
          }
        }
      } catch (ParseException e) {
        Log.w(TAG, "Failed to parse log file name: " + logFileName, e);
      }
    }
  }

  private File getLogFile() {
    String logFileName = logFileNameFormat.format(new Date());
    return new File(logDir, logFileName);
  }

  private String getCurrentTimestamp() {
    return dateTimeFormat.format(new Date());
  }
}
