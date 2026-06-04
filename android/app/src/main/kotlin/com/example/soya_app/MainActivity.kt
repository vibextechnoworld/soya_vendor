package com.example.soya_app

import android.content.Intent
import android.net.Uri
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.soya_app/share"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "shareToWhatsApp") {
                val filePath = call.argument<String>("filePath")
                val phoneNumber = call.argument<String>("phoneNumber")
                val message = call.argument<String>("message")
                
                if (filePath != null) {
                    shareFileToWhatsApp(filePath, phoneNumber, message)
                    result.success(null)
                } else {
                    result.error("INVALID_ARGUMENT", "File path is null", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun shareFileToWhatsApp(filePath: String, phoneNumber: String?, message: String?) {
        try {
            val file = File(filePath)
            val uri = FileProvider.getUriForFile(
                this,
                "${applicationContext.packageName}.fileprovider",
                file
            )

            // Determine target package (Standard or Business)
            val targetPackage = when {
                isPackageInstalled("com.whatsapp") -> "com.whatsapp"
                isPackageInstalled("com.whatsapp.w4b") -> "com.whatsapp.w4b"
                else -> null
            }

            if (targetPackage == null) {
                android.widget.Toast.makeText(this, "WhatsApp not installed", android.widget.Toast.LENGTH_LONG).show()
                // Fallback to generic chooser
                val fallbackIntent = Intent(Intent.ACTION_SEND)
                fallbackIntent.type = "application/pdf"
                fallbackIntent.putExtra(Intent.EXTRA_STREAM, uri)
                if (!message.isNullOrEmpty()) {
                    fallbackIntent.putExtra(Intent.EXTRA_TEXT, message)
                }
                fallbackIntent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                startActivity(Intent.createChooser(fallbackIntent, "Share Bill"))
                return
            }

            val intent = Intent(Intent.ACTION_SEND)
            intent.type = "application/pdf"
            intent.putExtra(Intent.EXTRA_STREAM, uri)
            if (!message.isNullOrEmpty()) {
                intent.putExtra(Intent.EXTRA_TEXT, message)
            }
            intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            // Important: Add ClipData for Android 10+ permission propagation
            intent.clipData = android.content.ClipData.newRawUri("", uri)
            intent.setPackage(targetPackage)

            if (!phoneNumber.isNullOrEmpty()) {
                try {
                    // Visual confirmation for the user that V13 is running
                    android.widget.Toast.makeText(this, "Native V13 (Unsaved Fix) Loaded", android.widget.Toast.LENGTH_SHORT).show()
                    
                    val cleanPhone = phoneNumber.replace("+", "").replace(" ", "").trim()
                    val fullJid = "$cleanPhone@s.whatsapp.net"
                    
                    // TARGETING: Successful Shotgun approach - Adding more extras for unsaved contacts
                    intent.putExtra("jid", fullJid)
                    intent.putExtra("com.whatsapp.extra.JID", fullJid)
                    intent.putExtra("contact_number", cleanPhone)
                    intent.putExtra("address", cleanPhone)
                    intent.putExtra(Intent.EXTRA_PHONE_NUMBER, cleanPhone)
                    
                    // CAPTION FIX: Bundle text and file together
                    // 1. Extra Text
                    intent.putExtra(Intent.EXTRA_TEXT, message ?: "")
                    intent.putExtra("android.intent.extra.TEXT", message ?: "")
                    
                    // 2. Caption Extra (Specifically for WhatsApp/social apps)
                    intent.putExtra("caption", message ?: "")
                    
                    // 3. ClipData: Most robust way on Android 10+ to bundle text + URI
                    try {
                        val uri = intent.getParcelableExtra<Uri>(Intent.EXTRA_STREAM)
                        if (uri != null) {
                            val clipData = android.content.ClipData.newRawUri("PDF Bill", uri)
                            clipData.addItem(android.content.ClipData.Item(message ?: ""))
                            intent.setClipData(clipData)
                            // Grant read permission for the clipdata specifically
                            intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                        }
                    } catch (e: Exception) {
                        android.util.Log.w("SoyaApp", "ClipData setup failed: ${e.message}")
                    }

                    intent.setPackage(targetPackage)
                    
                    android.util.Log.d("SoyaApp", "**************************************************")
                    android.util.Log.d("SoyaApp", "SoyaApp V13 (Unsaved Contact Fix): STARTING SHARE")
                    android.util.Log.d("SoyaApp", "Target: $fullJid, Msg: ${message?.take(20)}...")
                    android.util.Log.d("SoyaApp", "**************************************************")
                } catch (e: Exception) {
                    android.util.Log.e("SoyaApp", "Direct Share Setup Error: ${e.message}", e)
                }
            }

            try {
                // Grant temporary read permission to the uri
                this.grantUriPermission(targetPackage, uri, Intent.FLAG_GRANT_READ_URI_PERMISSION)
                startActivity(intent)
                android.util.Log.d("SoyaApp", "WhatsApp Intent started successfully")
            } catch (e: Exception) {
                android.util.Log.e("SoyaApp", "WhatsApp Intent execution failed: ${e.message}", e)
                android.widget.Toast.makeText(this, "Direct Share Failed: ${e.message}", android.widget.Toast.LENGTH_LONG).show()
                
                // Final fallback to generic chooser
                val fallbackIntent = Intent(Intent.ACTION_SEND)
                fallbackIntent.type = "application/pdf"
                fallbackIntent.putExtra(Intent.EXTRA_STREAM, uri)
                if (!message.isNullOrEmpty()) {
                    fallbackIntent.putExtra(Intent.EXTRA_TEXT, message)
                }
                fallbackIntent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                startActivity(Intent.createChooser(fallbackIntent, "Share Bill"))
            }
        } catch (e: Exception) {
            android.widget.Toast.makeText(this, "Critical Error: ${e.message}", android.widget.Toast.LENGTH_LONG).show()
        }
    }

    private fun isPackageInstalled(packageName: String): Boolean {
        return try {
            packageManager.getPackageInfo(packageName, 0)
            true
        } catch (e: Exception) {
            false
        }
    }
}
    
