package io.nextsense.android.base.utils;

import android.content.Context;
import android.content.ContextWrapper;

import java.io.BufferedWriter;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.io.OutputStreamWriter;

public class SleepWakeCsvWriter {

  private static final String TAG = SleepWakeCsvWriter.class.getSimpleName();
  private static final String HEADER_PREFIX = "#";
  private static final String KEY_VALUE_SEPARATOR = ": ";

  private final File appDirectory;
  private OutputStream csvOutputStream;
  private BufferedWriter writer;
  private int sampleNumber = 1;
  private boolean warnedNoWriter = false;

  public SleepWakeCsvWriter(Context context) {
    ContextWrapper contextWrapper = new ContextWrapper(context);
    appDirectory = contextWrapper.getDir(context.getFilesDir().getName(), Context.MODE_PRIVATE);
  }

  public synchronized void initCsvFile(String fileName) {
    try {
      if (writer != null) {
        RotatingFileLogger.get().logw(TAG, "sleep wake csv file already initialized");
        return;
      }
      String fullFileName = fileName + ".csv";
      File csvFile = new File(appDirectory, fullFileName);
      RotatingFileLogger.get().logi(TAG, "Creating csv file: " + csvFile.getAbsolutePath());
      csvOutputStream = new FileOutputStream(csvFile);
      writer = new BufferedWriter(new OutputStreamWriter(csvOutputStream));
      warnedNoWriter = false;
    } catch (FileNotFoundException e) {
      RotatingFileLogger.get().logw(TAG, "Failed to create: " + e.getMessage());
      return;
    }
    sampleNumber = 1;
    String headerLine = "SAMPLE_NUMBER,TIMESTAMP,LEFT_SLEEPING,RIGHT_SLEEPING";
    appendHeaderLine(headerLine);
  }

  public synchronized void closeCsvFile() {
    try {
      if (writer != null) {
        writer.close();
      }
      if (csvOutputStream != null) {
        csvOutputStream.close();
      }
    } catch (IOException e) {
      RotatingFileLogger.get().logw(TAG, "failed to close sleep wake csv file: " + e.getMessage());
    }
    writer = null;
    csvOutputStream = null;
  }

  public synchronized void appendData(Boolean leftEarSleeping, Boolean rightEarSleeping) {
    StringBuilder line = new StringBuilder(sampleNumber + "," + System.currentTimeMillis() + "," +
        leftEarSleeping + "," + rightEarSleeping);
    appendLine(line.toString());
    sampleNumber++;
  }

  private void appendLine(String line) {
    if (writer == null) {
      if (!warnedNoWriter) {
        warnedNoWriter = true;
        RotatingFileLogger.get().logw(TAG, "sleep wake csv file not initialized");
      }
      return;
    }
    try {
      writer.write(line);
      writer.newLine();
    } catch (IOException e) {
      RotatingFileLogger.get().logw(TAG, "failed to append sleep wake data: " + e.getMessage());
    }
  }

  private void appendHeaderLine(String header) {
    appendHeaderLine(header, null);
  }

  private void appendHeaderLine(String header, String value) {
    if (value == null) {
      appendLine(HEADER_PREFIX + header);
    } else {
      appendLine(HEADER_PREFIX + header + KEY_VALUE_SEPARATOR + value);
    }
  }
}