package com.logria.logria

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.app.Activity
import android.content.Intent
import java.io.ByteArrayOutputStream

class MainActivity : FlutterActivity() {
    private var pending: MethodChannel.Result? = null
    private var output: String? = null
    private val limit = 32 * 1024 * 1024
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.logria.logria/documents").setMethodCallHandler { call, result ->
            if (call.method != "save" && call.method != "open") { result.notImplemented(); return@setMethodCallHandler }
            if (pending != null) { result.error("busy", "A document picker is already open", null); return@setMethodCallHandler }
            output = if (call.method == "save") call.argument<String>("content") else null
            if (call.method == "save" && output == null) { result.error("invalid", "Missing content", null); return@setMethodCallHandler }
            pending = result
            try {
                val intent = Intent(if (call.method == "save") Intent.ACTION_CREATE_DOCUMENT else Intent.ACTION_OPEN_DOCUMENT).apply {
                    addCategory(Intent.CATEGORY_OPENABLE)
                    type = if (call.method == "save") "application/json" else "*/*"
                    if (call.method == "save") putExtra(Intent.EXTRA_TITLE, call.argument<String>("name"))
                }
                startActivityForResult(intent, if (call.method == "save") 7101 else 7102)
            } catch (e: Exception) { pending = null; output = null; result.error("picker", e.message, null) }
        }
    }
    @Deprecated("Activity result bridge for the local document channel")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != 7101 && requestCode != 7102) return
        val result = pending ?: return
        val content = output
        val uri = data?.data
        // Keep the operation busy until stream I/O completes off the UI thread.
        if (resultCode != Activity.RESULT_OK || uri == null) { pending = null; output = null; result.success(null); return }
        Thread {
            try {
                val value: Any = if (requestCode == 7101) {
                    val bytes = (content ?: throw IllegalArgumentException("Missing content")).toByteArray(Charsets.UTF_8)
                    require(bytes.size <= limit) { "File exceeds 32 MiB" }
                    (contentResolver.openOutputStream(uri, "wt") ?: throw IllegalStateException("Cannot write document")).use { it.write(bytes) }
                    true
                } else {
                    (contentResolver.openInputStream(uri) ?: throw IllegalStateException("Cannot read document")).use { input ->
                        val buffer = ByteArray(8192)
                        val bytes = ByteArrayOutputStream()
                        while (true) {
                            val count = input.read(buffer)
                            if (count < 0) break
                            require(bytes.size() + count <= limit) { "File exceeds 32 MiB" }
                            bytes.write(buffer, 0, count)
                        }
                        bytes.toString("UTF-8")
                    }
                }
                runOnUiThread { pending = null; output = null; result.success(value) }
            } catch (e: Exception) { runOnUiThread { pending = null; output = null; result.error("document_io", e.message, null) } }
        }.start()
    }
}
