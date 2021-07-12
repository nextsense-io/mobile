package io.nextsense.android.baselibrarytestui;

import androidx.annotation.NonNull;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;

import android.Manifest;
import android.content.pm.PackageManager;
import android.os.Bundle;
import android.util.Log;
import android.widget.Button;
import android.widget.TextView;
import android.widget.Toast;

import com.google.common.util.concurrent.ListenableFuture;

import java.util.concurrent.ExecutionException;
import java.util.concurrent.Executors;

import io.nextsense.android.base.Device;
import io.nextsense.android.base.DeviceScanner;
import io.nextsense.android.base.DeviceState;
import io.nextsense.android.base.communication.ble.BleCentralManagerProxy;
import io.nextsense.android.base.devices.NextSenseDeviceManager;

/**
 * Test Activity for the Base Library.
 * Can test the Bluetooth connectivity.
 */
public class MainActivity extends AppCompatActivity {

  private static final int LOCATION_REQUEST_CODE = 100;

  private Button startScanningButton;
  private Button stopScanningButton;
  private Button connectButton;
  private Button disconnectButton;
  private TextView resultsView;
  private BleCentralManagerProxy centralManagerProxy;
  private DeviceScanner deviceScanner;
  private Device lastDevice;

  private Device.DeviceStateChangeListener stateChangeListener = deviceState ->
      Toast.makeText(MainActivity.this, "Device status: " + deviceState.toString(),
          Toast.LENGTH_SHORT).show();

  @Override
  protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    setContentView(R.layout.activity_main);
    startScanningButton = findViewById(R.id.start_scanning_button);
    stopScanningButton = findViewById(R.id.stop_scanning_button);
    connectButton = findViewById(R.id.connect_button);
    disconnectButton = findViewById(R.id.disconnect_button);
    resultsView = findViewById(R.id.results_view);

    centralManagerProxy = new BleCentralManagerProxy(getApplicationContext());
    deviceScanner = new DeviceScanner(new NextSenseDeviceManager(), centralManagerProxy);

    startScanningButton.setOnClickListener(view -> deviceScanner.findDevices(
        new DeviceScanner.DeviceScanListener() {
      @Override
      public void onNewDevice(Device device) {
        lastDevice = device;
        runOnUiThread(() ->
            resultsView.setText(
                resultsView.getText() + " \n" + device.getInfo().getDeviceType().toString()));

      }

      @Override
      public void onScanError(ScanError scanError) {
        Log.w("MainActivity", scanError.toString());
      }
    }));

    stopScanningButton.setOnClickListener(view -> deviceScanner.stopFindingDevices());

    connectButton.setOnClickListener(view -> {
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
          e.printStackTrace();
        }
      }, Executors.newSingleThreadExecutor());
    }
    );

    disconnectButton.setOnClickListener(view -> {
          ListenableFuture<DeviceState> disconnectionFuture = lastDevice.disconnect();
          disconnectionFuture.addListener(() -> {
            try {
              DeviceState state = disconnectionFuture.get();
              runOnUiThread(
                  () -> Toast.makeText(MainActivity.this, "Disconnect: Device status: " + state.toString(),
                      Toast.LENGTH_SHORT).show());
            } catch (ExecutionException e) {
              e.printStackTrace();
            } catch (InterruptedException e) {
              e.printStackTrace();
            }
          }, Executors.newSingleThreadExecutor());
        }
    );

    checkPermission(Manifest.permission.ACCESS_FINE_LOCATION, LOCATION_REQUEST_CODE);

    Log.d("MainActivity", "started");
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
}