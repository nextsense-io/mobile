package io.nextsense.android.main;

import android.os.Bundle;
import android.webkit.WebView;

import androidx.appcompat.app.AppCompatActivity;

public class LucidPermissionsRationaleActivity extends AppCompatActivity {

  @Override
  protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    setContentView(R.layout.activity_webview);
    WebView webView = findViewById(R.id.webView);
    webView.loadUrl("https://www.getlucid.ai/about-1");
  }
}
