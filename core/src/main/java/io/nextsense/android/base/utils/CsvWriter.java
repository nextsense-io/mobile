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
import java.util.List;

public class CsvWriter {

  private static final String TAG = CsvWriter.class.getSimpleName();
  private static final String HEADER_PREFIX = "#";
  private static final String KEY_VALUE_SEPARATOR = ": ";

  private final File appDirectory;
  private OutputStream csvOutputStream;
  private BufferedWriter writer;
  private int sampleNumber = 1;

  public CsvWriter(Context context) {
    ContextWrapper contextWrapper = new ContextWrapper(context);
    appDirectory = contextWrapper.getDir(context.getFilesDir().getName(), Context.MODE_PRIVATE);
  }

  public synchronized void initCsvFile(String fileName, String earbudsConfig, boolean haveRssi) {
    try {
      if (writer != null) {
        RotatingFileLogger.get().logw(TAG, "csv file already initialized");
        return;
      }
      String fullFileName = fileName + ".csv";
      File csvFile = new File(appDirectory, fullFileName);
      RotatingFileLogger.get().logi(TAG, "Creating csv file: " + csvFile.getAbsolutePath());
      csvOutputStream = new FileOutputStream(csvFile);
      writer = new BufferedWriter(new OutputStreamWriter(csvOutputStream));
    } catch (FileNotFoundException e) {
      RotatingFileLogger.get().logw(TAG, "Failed to create: " + e.getMessage());
      return;
    }
    sampleNumber = 1;
    appendHeaderLine("Header version 1.0");
    appendHeaderLine("Version", "0.7.0");
    appendHeaderLine("Protocol version", "1");
    appendHeaderLine("Device", "Maui");
    appendHeaderLine("MAC address", "unknown");
    appendHeaderLine("eegStreamingRate", "1000");
    appendHeaderLine("accelerationStreamingRate", "250");
    appendHeaderLine("channelConfig", earbudsConfig);
    appendHeaderLine("========== Start Data ==========");
    String headerLine = "SAMPLE_NUMBER,CH-1,CH-2,CH-3,CH-4,CH-5,CH-6,CH-7,CH-8,ACC_L_X,ACC_L_Y," +
        "ACC_L_Z,GYRO_L_X,GYRO_L_Y,GYRO_L_Z,ACC_R_X,ACC_R_Y,ACC_R_Z,GYRO_R_X,GYRO_R_Y,GYRO_R_Z," +
        "SAMPLING_TIMESTAMP,RECEPTION_TIMESTAMP,IMPEDANCE_FLAG,SYNC,TRIG_OUT,TRIG_IN,ZMOD,MARKER," +
        "TBD6,TBD7,BUTTON,SLEEP_STAGE";
    if (haveRssi) {
      headerLine += ",RSSI";
    }
    appendHeaderLine(headerLine);
  }

  public synchronized void closeCsvFile() {
    if (writer != null) {
      appendHeaderLine("========== End Data ==========");
      appendHeaderLine("========== Start Events ==========");
      appendHeaderLine("========== End Events ==========");
    }
    try {
      if (writer != null) {
        writer.close();
      }
      if (csvOutputStream != null) {
        csvOutputStream.close();
      }
    } catch (IOException e) {
      RotatingFileLogger.get().logw(TAG, "failed to close csv file: " + e.getMessage());
    }
    writer = null;
    csvOutputStream = null;
  }

  public synchronized void appendData(
      List<Float> eegData, List<Float> leftImuData, List<Float> rightImuData,
      long samplingTimestamp, long receptionTimestamp, int impedanceFlag, int sync, int trigOut,
      int trigIn, int zmod, int marker, int tbd6, int tbd7, int button, Integer rssi,
      String sleepStage) {
    StringBuilder line = new StringBuilder(sampleNumber + ",");
    for (int i = 0; i < eegData.size(); i++) {
      line.append(eegData.get(i)).append(",");
    }
    for (int i = 0; i < leftImuData.size(); i++) {
      line.append(leftImuData.get(i)).append(",");
    }
    for (int i = 0; i < rightImuData.size(); i++) {
      line.append(rightImuData.get(i)).append(",");
    }
    line.append(samplingTimestamp).append(",").append(receptionTimestamp).append(",")
        .append(impedanceFlag).append(",").append(sync).append(",").append(trigOut).append(",")
        .append(trigIn).append(",").append(zmod).append(",").append(marker).append(",")
        .append(tbd6).append(",").append(tbd7).append(",").append(button).append(",")
        .append(sleepStage);
    if (rssi != null) {
      line.append(",").append(rssi);
    }
    appendLine(line.toString());
    sampleNumber++;
  }

  private void appendLine(String line) {
    if (writer == null) {
      RotatingFileLogger.get().logw(TAG, "csv file not initialized");
      return;
    }
    try {
      writer.write(line);
      writer.newLine();
    } catch (IOException e) {
      RotatingFileLogger.get().logw(TAG, "failed to append data: " + e.getMessage());
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