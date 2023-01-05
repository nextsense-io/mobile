package io.nextsense.android.main;

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
import java.util.concurrent.ExecutionException;
import java.util.concurrent.Executors;
import com.google.common.util.concurrent.ListenableFuture;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.engine.FlutterEngineCache;
import io.nextsense.android.base.Device;
import io.nextsense.android.base.DeviceManager;
import io.nextsense.android.base.DeviceScanner;
import io.nextsense.android.base.DeviceState;
import io.nextsense.android.base.SampleRateCalculator;
import io.nextsense.android.service.ForegroundService;

/**
 * Test Activity for the Base Library.
 * Can test the Bluetooth connectivity.
 */
public class TestActivity extends AppCompatActivity {

  private static final String TAG = TestActivity.class.getSimpleName();
  private static final int LOCATION_REQUEST_CODE = 100;
  private static final boolean AUTOSTART_FLUTTER = true;

  private Intent foregroundServiceIntent;
  private Button startScanningButton;
  private Button stopScanningButton;
  private Button connectButton;
  private Button disconnectButton;
  private Button startStreamingButton;
  private Button stopStreamingButton;
  private Button startFlutterButton;
  private TextView resultsTextView;
  private TextView sampleRateTextView;
  private DeviceManager deviceManager;
  private Device lastDevice;
  private ForegroundService nextSenseService;
  private boolean nextSenseServiceBound = false;

  private final Device.DeviceStateChangeListener stateChangeListener = deviceState ->
      Toast.makeText(TestActivity.this, "Device status: " + deviceState.toString(),
          Toast.LENGTH_SHORT).show();

  @Override
  protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    setContentView(R.layout.activity_test);
    foregroundServiceIntent = new Intent(getApplicationContext(), ForegroundService.class);
    foregroundServiceIntent.putExtra("ui_class", TestActivity.class);

    startScanningButton = findViewById(R.id.start_scanning_button);
    stopScanningButton = findViewById(R.id.stop_scanning_button);
    connectButton = findViewById(R.id.connect_button);
    disconnectButton = findViewById(R.id.disconnect_button);
    startStreamingButton = findViewById(R.id.start_streaming_button);
    stopStreamingButton = findViewById(R.id.stop_streaming_button);
    resultsTextView = findViewById(R.id.results_view);
    sampleRateTextView = findViewById(R.id.sample_rate_textview);
    startFlutterButton = findViewById(R.id.start_flutter_button);

    startScanningButton.setOnClickListener(view -> {
      resultsTextView.setText("");
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
                  () -> Toast.makeText(TestActivity.this, "Connect: Device status: " + state.toString(),
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
                  () -> Toast.makeText(TestActivity.this, "Disconnect: Device status: " +
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
      ListenableFuture<Boolean> deviceModeFuture = lastDevice.startStreaming(
          /*uploadToCloud=*/false, /*userBigTableKey=*/null,
          /*dataSessionId=*/null, /*earbudsConfig=*/null);
      deviceModeFuture.addListener(() -> {
        try {
          Boolean streaming = deviceModeFuture.get();
          runOnUiThread(
              () -> Toast.makeText(TestActivity.this, "Start Streaming: " + streaming.toString(),
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
      ListenableFuture<Boolean> deviceModeFuture = lastDevice.stopStreaming();
      deviceModeFuture.addListener(() -> {
        try {
          Boolean stopped = deviceModeFuture.get();
          runOnUiThread(
              () -> Toast.makeText(TestActivity.this, "Stop Streaming: " + stopped.toString(),
                  Toast.LENGTH_SHORT).show());
        } catch (ExecutionException e) {
          e.printStackTrace();
        } catch (InterruptedException e) {
          Thread.currentThread().interrupt();
          e.printStackTrace();
        }
      }, Executors.newSingleThreadExecutor());
    });

    startFlutterButton.setOnClickListener(view -> startFlutter());

    checkPermission(Manifest.permission.ACCESS_COARSE_LOCATION, LOCATION_REQUEST_CODE);

    // Need to start the service explicitly so that 'onStartCommand' gets called in the service.
    getApplicationContext().startService(foregroundServiceIntent);

    Log.d(TAG, "started");
  }

  @Override
  protected void onStart() {
    super.onStart();
    if (!nextSenseServiceBound) {
      bindService(foregroundServiceIntent, nextSenseConnection, Context.BIND_IMPORTANT);
    } else {
      Log.i(TAG, "service bound. Flutter active: " +
          nextSenseService.isFlutterActivityActive());
      if (AUTOSTART_FLUTTER) {
        if (nextSenseService.isFlutterActivityActive()) {
          startFlutter();
        } else {
          stopService();
          finish();
        }
      }
    }
  }

  @Override
  protected void onStop() {
    if (nextSenseServiceBound) {
      nextSenseService.getSampleRateCalculator().removeRateUpdateListener(rateUpdateListener);
      unbindService(nextSenseConnection);
      nextSenseServiceBound = false;
    }
    super.onStop();
  }

  @Override
  public void onBackPressed() {
    // Should add a confirmation prompt here in a non-test app.
    stopService();
    super.onBackPressed();
  }

  // Function to check and request permission
  public void checkPermission(String permission, int requestCode) {
    if (ContextCompat.checkSelfPermission(TestActivity.this, permission) ==
        PackageManager.PERMISSION_DENIED) {
      ActivityCompat.requestPermissions(TestActivity.this, new String[] { permission }, requestCode);
    } else {
      Toast.makeText(TestActivity.this, "Permission already granted", Toast.LENGTH_SHORT).show();
    }
  }

  @Override
  public void onDestroy() {
    super.onDestroy();
    // The flutter engine would survive the application.
    FlutterEngine flutterEngine = FlutterEngineCache.getInstance().get(NextSenseApplication.FLUTTER_ENGINE_NAME);
    if (flutterEngine != null) {
      Log.i(TAG, "Detaching flutter engine.");
      flutterEngine.getPlatformViewsController().detachFromView();
      flutterEngine.getLifecycleChannel().appIsDetached();
      FlutterEngineCache.getInstance().remove(NextSenseApplication.FLUTTER_ENGINE_NAME);
    }
  }

  private void stopService() {
    if (lastDevice != null) {
      try {
        lastDevice.disconnect().get();
      } catch (ExecutionException executionException) {
        executionException.printStackTrace();
      } catch (InterruptedException e) {
        e.printStackTrace();
      }
    }
    stopService(foregroundServiceIntent);
  }

  private void startFlutter() {
    if (FlutterEngineCache.getInstance().get(NextSenseApplication.FLUTTER_ENGINE_NAME) == null) {
      ((NextSenseApplication) getApplicationContext()).initFlutterEngineCache();
    }
    startActivity(FlutterActivity.withCachedEngine(NextSenseApplication.FLUTTER_ENGINE_NAME)
        .build(this));
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
        Toast.makeText(TestActivity.this, "Location Permission Granted", Toast.LENGTH_SHORT).show();
      } else {
        Toast.makeText(TestActivity.this, "Location Permission Denied", Toast.LENGTH_SHORT).show();
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
      nextSenseService.getSampleRateCalculator().addRateUpdateListener(rateUpdateListener);
      nextSenseServiceBound = true;
      Log.i(TAG, "service bound. Flutter active: " +
          nextSenseService.isFlutterActivityActive());
      if (AUTOSTART_FLUTTER) {
        if (nextSenseService.isFlutterActivityActive()) {
          startFlutter();
        } else {
          stopService();
          finish();
        }
      }
    }

    @Override
    public void onServiceDisconnected(ComponentName componentName) {
      nextSenseServiceBound = false;
      nextSenseService = null;
    }
  };

  private final DeviceManager.DeviceScanListener deviceScanListener =
      new DeviceManager.DeviceScanListener() {
        @Override
        public void onNewDevice(Device device) {
          if (lastDevice != null) {
            lastDevice.removeOnDeviceStateChangeListener(stateChangeListener);
          }
          lastDevice = device;
          runOnUiThread(() -> resultsTextView.setText(resultsTextView.getText() + " \n" + device.getName()));
        }

        @Override
        public void onScanError(DeviceScanner.DeviceScanListener.ScanError scanError) {
          Log.w(TAG, scanError.toString());
        }
      };

  private final SampleRateCalculator.RateUpdateListener rateUpdateListener =
      (formattedSampleRate, skippedSamples) ->
          runOnUiThread(() -> sampleRateTextView.setText("Sample Rate " + formattedSampleRate +
              ", Skipped samples: " + skippedSamples));
}