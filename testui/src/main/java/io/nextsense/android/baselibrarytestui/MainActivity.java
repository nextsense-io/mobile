package io.nextsense.android.baselibrarytestui;

import androidx.annotation.NonNull;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;

import android.Manifest;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.ServiceConnection;
import android.content.pm.PackageManager;
import android.os.Bundle;
import android.os.IBinder;
import android.util.Log;
import android.widget.Button;
import android.widget.TextView;
import android.widget.Toast;

import com.google.common.util.concurrent.ListenableFuture;

import java.util.concurrent.ExecutionException;
import java.util.concurrent.Executors;

import io.nextsense.android.base.Device;
import io.nextsense.android.base.DeviceManager;
import io.nextsense.android.base.DeviceMode;
import io.nextsense.android.base.DeviceScanner;
import io.nextsense.android.base.DeviceState;
import io.nextsense.android.service.ForegroundService;

/**
 * Test Activity for the Base Library.
 * Can test the Bluetooth connectivity.
 */
public class MainActivity extends AppCompatActivity {

  private static final int LOCATION_REQUEST_CODE = 100;

  private Intent foregroundServiceIntent;
  private Button startScanningButton;
  private Button stopScanningButton;
  private Button connectButton;
  private Button disconnectButton;
  private Button startStreamingButton;
  private Button stopStreamingButton;
  private TextView resultsView;
  private DeviceManager deviceManager;
  private Device lastDevice;
  private ForegroundService nextSenseService;
  private boolean nextSenseServiceBound = false;

  private Device.DeviceStateChangeListener stateChangeListener = deviceState ->
      Toast.makeText(MainActivity.this, "Device status: " + deviceState.toString(),
          Toast.LENGTH_SHORT).show();

  @Override
  protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    setContentView(R.layout.activity_main);
    foregroundServiceIntent = new Intent(getApplicationContext(), ForegroundService.class);
    foregroundServiceIntent.putExtra("ui_class", MainActivity.class);

    startScanningButton = findViewById(R.id.start_scanning_button);
    stopScanningButton = findViewById(R.id.stop_scanning_button);
    connectButton = findViewById(R.id.connect_button);
    disconnectButton = findViewById(R.id.disconnect_button);
    startStreamingButton = findViewById(R.id.start_streaming_button);
    stopStreamingButton = findViewById(R.id.stop_streaming_button);
    resultsView = findViewById(R.id.results_view);

    startScanningButton.setOnClickListener(view -> {
      resultsView.setText("");
      if (!nextSenseServiceBound) {
        return;
      }
      deviceManager.findDevices(deviceScanListener);
    });

    stopScanningButton.setOnClickListener(view -> {
      if (!nextSenseServiceBound) {
        return;
      }
      deviceManager.stopFindingDevices(deviceScanListener);
    });

    connectButton.setOnClickListener(view -> {
      if (!nextSenseServiceBound || lastDevice == null) {
        return;
      }
      lastDevice.addOnDeviceStateChangeListener(stateChangeListener);
      ListenableFuture<DeviceState> connectionFuture = lastDevice.connect(false);
      connectionFuture.addListener(() -> {
        try {
          DeviceState state = connectionFuture.get();
          runOnUiThread(
              () -> Toast.makeText(MainActivity.this, "Connect: Device status: " + state.toString(),
                  Toast.LENGTH_SHORT).show());
        } catch (ExecutionException e) {
          e.printStackTrace();
        } catch (InterruptedException e) {
          Thread.currentThread().interrupt();
          e.printStackTrace();
        }
      }, Executors.newSingleThreadExecutor());
    }
    );

    disconnectButton.setOnClickListener(view -> {
      if (!nextSenseServiceBound || lastDevice == null) {
        return;
      }
      ListenableFuture<DeviceState> disconnectionFuture = lastDevice.disconnect();
      disconnectionFuture.addListener(() -> {
        try {
          DeviceState state = disconnectionFuture.get();
          runOnUiThread(
              () -> Toast.makeText(MainActivity.this, "Disconnect: Device status: " +
                      state.toString(), Toast.LENGTH_SHORT).show());
        } catch (ExecutionException e) {
          e.printStackTrace();
        } catch (InterruptedException e) {
          Thread.currentThread().interrupt();
          e.printStackTrace();
        }
      }, Executors.newSingleThreadExecutor());
    }
    );

    startStreamingButton.setOnClickListener(view -> {
      if (!nextSenseServiceBound || lastDevice == null) {
        return;
      }
      ListenableFuture<DeviceMode> deviceModeFuture = lastDevice.setMode(DeviceMode.STREAMING);
      deviceModeFuture.addListener(() -> {
        try {
          DeviceMode mode = deviceModeFuture.get();
          runOnUiThread(
              () -> Toast.makeText(MainActivity.this, "Start Streaming: Mode " + mode.toString(),
                  Toast.LENGTH_SHORT).show());
        } catch (ExecutionException e) {
          e.printStackTrace();
        } catch (InterruptedException e) {
          Thread.currentThread().interrupt();
          e.printStackTrace();
        }
      }, Executors.newSingleThreadExecutor());
    });

    stopStreamingButton.setOnClickListener(view -> {
      if (!nextSenseServiceBound || lastDevice == null) {
        return;
      }
      ListenableFuture<DeviceMode> deviceModeFuture = lastDevice.setMode(DeviceMode.IDLE);
      deviceModeFuture.addListener(() -> {
        try {
          DeviceMode mode = deviceModeFuture.get();
          runOnUiThread(
              () -> Toast.makeText(MainActivity.this, "Stop Streaming: Mode " + mode.toString(),
                  Toast.LENGTH_SHORT).show());
        } catch (ExecutionException e) {
          e.printStackTrace();
        } catch (InterruptedException e) {
          Thread.currentThread().interrupt();
          e.printStackTrace();
        }
      }, Executors.newSingleThreadExecutor());
    });

    checkPermission(Manifest.permission.ACCESS_FINE_LOCATION, LOCATION_REQUEST_CODE);

    // Need to start the service explicitly so that 'onStartCommand' gets called in the service.
    getApplicationContext().startService(foregroundServiceIntent);

    Log.d("MainActivity", "started");
  }

  @Override
  protected void onStart() {
    super.onStart();
    bindService(foregroundServiceIntent, nextSenseConnection, Context.BIND_IMPORTANT);
  }

  @Override
  protected void onStop() {
    super.onStop();
    unbindService(nextSenseConnection);
    nextSenseServiceBound = false;
  }

  @Override
  public void onBackPressed() {
    // Should add a confirmation prompt here in a non-test app.
    // Disconnect is done on the main thread handler so can't do it synchronously, it would hang.
    if (lastDevice != null) {
      lastDevice.disconnect();
    }
    stopService(foregroundServiceIntent);
    super.onBackPressed();
  }

  // Function to check and request permission
  public void checkPermission(String permission, int requestCode) {
    if (ContextCompat.checkSelfPermission(MainActivity.this, permission) ==
        PackageManager.PERMISSION_DENIED) {
      ActivityCompat.requestPermissions(MainActivity.this, new String[] { permission }, requestCode);
    } else {
      Toast.makeText(MainActivity.this, "Permission already granted", Toast.LENGTH_SHORT).show();
    }
  }

  @Override
  @Deprecated
  public void onRequestPermissionsResult(int requestCode,
                                         @NonNull String[] permissions,
                                         @NonNull int[] grantResults) {
    super.onRequestPermissionsResult(requestCode, permissions, grantResults);

    if (requestCode == LOCATION_REQUEST_CODE) {
      // Checking whether user granted the permission or not.
      if (grantResults.length > 0 && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
        Toast.makeText(MainActivity.this, "Location Permission Granted", Toast.LENGTH_SHORT).show();
      } else {
        Toast.makeText(MainActivity.this, "Location Permission Denied", Toast.LENGTH_SHORT).show();
      }
    }
  }

  private final ServiceConnection nextSenseConnection = new ServiceConnection() {

    @Override
    public void onServiceConnected(ComponentName className,
                                   IBinder service) {
      // We've bound to LocalService, cast the IBinder and get LocalService instance
      ForegroundService.LocalBinder binder = (ForegroundService.LocalBinder) service;
      nextSenseService = binder.getService();
      deviceManager = nextSenseService.getDeviceManager();
      nextSenseServiceBound = true;
    }

    @Override
    public void onServiceDisconnected(ComponentName componentName) {
      nextSenseServiceBound = false;
    }
  };

  private final DeviceScanner.DeviceScanListener deviceScanListener =
      new DeviceScanner.DeviceScanListener() {
    @Override
    public void onNewDevice(Device device) {
      if (lastDevice != null) {
        lastDevice.removeOnDeviceStateChangeListener(stateChangeListener);
      }
      lastDevice = device;
      runOnUiThread(() -> resultsView.setText(resultsView.getText() + " \n" + device.getName()));
    }

    @Override
    public void onScanError(ScanError scanError) {
      Log.w("MainActivity", scanError.toString());
    }
  };
}