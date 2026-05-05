package com.afaqalspl.moshaf

import android.content.ContentValues
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream

class MyAudioServiceActivity : AudioServiceActivity() {

    private val CHANNEL = "com.afaqalspl.moshaf/audio"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->

                when (call.method) {

                    "insertNotificationSound" -> {
                        val filePath = call.argument<String>("filePath")
                        val displayName = call.argument<String>("displayName")

                        if (filePath == null || displayName == null) {
                            result.error("INVALID_ARGS", "Missing args", null)
                            return@setMethodCallHandler
                        }

                        try {
                            val uri = insertSoundIntoMediaStore(filePath, displayName)
                            result.success(uri?.toString())
                        } catch (e: Exception) {
                            result.error("ERROR", e.message, null)
                        }
                    }

                    "removeNotificationSound" -> {
                        val uriStr = call.argument<String>("contentUri")
                        if (uriStr == null) {
                            result.error("INVALID_ARGS", "Missing URI", null)
                            return@setMethodCallHandler
                        }

                        try {
                            val deleted = contentResolver.delete(Uri.parse(uriStr), null, null)
                            result.success(deleted > 0)
                        } catch (e: Exception) {
                            result.error("DELETE_FAILED", e.message, null)
                        }
                    }

                    else -> result.notImplemented()
                }
            }
    }

    private fun insertSoundIntoMediaStore(filePath: String, displayName: String): Uri? {
        val file = File(filePath)
        if (!file.exists()) return null

        val ext = file.extension.lowercase()
        val mimeType = when (ext) {
            "mp3" -> "audio/mpeg"
            "ogg" -> "audio/ogg"
            "wav" -> "audio/wav"
            else -> "audio/mpeg"
        }

        val values = ContentValues().apply {
            put(MediaStore.Audio.Media.DISPLAY_NAME, "$displayName.$ext")
            put(MediaStore.Audio.Media.MIME_TYPE, mimeType)
            put(MediaStore.Audio.Media.IS_NOTIFICATION, 1)

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                put(MediaStore.Audio.Media.RELATIVE_PATH, "Notifications/Mostakeem")
                put(MediaStore.Audio.Media.IS_PENDING, 1)
            }
        }

        val collection =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q)
                MediaStore.Audio.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
            else
                MediaStore.Audio.Media.EXTERNAL_CONTENT_URI

        val uri = contentResolver.insert(collection, values) ?: return null

        contentResolver.openOutputStream(uri)?.use { out ->
            FileInputStream(file).use { input -> input.copyTo(out) }
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val update = ContentValues().apply {
                put(MediaStore.Audio.Media.IS_PENDING, 0)
            }
            contentResolver.update(uri, update, null, null)
        }

        return uri
    }
}