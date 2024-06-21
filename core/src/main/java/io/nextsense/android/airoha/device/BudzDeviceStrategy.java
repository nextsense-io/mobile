package io.nextsense.android.airoha.device;

import com.airoha.sdk.api.device.ApiStrategy;

public class BudzDeviceStrategy extends ApiStrategy {

  public BudzDeviceStrategy(){
    setNextScanWindow(0);
    setNextScanInterval(0);
    setConnectTimeout(1000);
    setMaxRetryOnFail(0);
    setOfflineTimeout(0);
  }

  private void readObject(java.io.ObjectInputStream in) throws java.io.IOException, ClassNotFoundException {
    throw new java.io.NotSerializableException("io.nextsense.android.budz.manager.BudzDeviceStrategy");
  }

  private void writeObject(java.io.ObjectOutputStream out) throws java.io.IOException {
    throw new java.io.NotSerializableException("io.nextsense.android.budz.manager.BudzDeviceStrategy");
  }
}