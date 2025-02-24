package com.example.wikidex

import io.flutter.embedding.android.FlutterActivity
import android.os.Bundle
import android.Manifest
import android.os.Build
import androidx.core.app.ActivityCompat

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            ActivityCompat.requestPermissions(
                this,
                arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                0
            )
        }
    }
}
