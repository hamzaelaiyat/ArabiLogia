package com.arabilogia.arabilogia

import android.app.DownloadManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.Settings
import android.util.Log
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.arabilogia.app/download"
    private var downloadManager: DownloadManager? = null
    private var methodChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        downloadManager = getSystemService(Context.DOWNLOAD_SERVICE) as DownloadManager
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "startDownload" -> {
                    val url = call.argument<String>("url")
                    val fileName = call.argument<String>("fileName")
                    if (url != null && fileName != null) {
                        val downloadId = startDownload(url, fileName)
                        result.success(mapOf("downloadId" to downloadId))
                    } else {
                        result.error("INVALID_ARGS", "Missing url or fileName", null)
                    }
                }
                "getProgress" -> {
                    val downloadId = call.argument<Int>("downloadId")
                    if (downloadId != null) {
                        val progress = getProgress(downloadId)
                        result.success(progress)
                    } else {
                        result.error("INVALID_ARGS", "Missing downloadId", null)
                    }
                }
                "installApk" -> {
                    val downloadId = call.argument<Int>("downloadId")
                    val fileName = call.argument<String>("fileName")
                    if (downloadId != null && fileName != null) {
                        val success = installApk(downloadId, fileName)
                        result.success(success)
                    } else {
                        result.error("INVALID_ARGS", "Missing downloadId or fileName", null)
                    }
                }
                "canRequestPackageInstalls" -> {
                    result.success(canRequestPackageInstalls())
                }
                "requestPackageInstallPermission" -> {
                    requestPackageInstallPermission()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun startDownload(url: String, fileName: String): Long {
        val request = DownloadManager.Request(Uri.parse(url)).apply {
            setTitle("تحميل تحديث عربيلوجيا")
            setDescription("جاري تحميل الإصدار الجديد...")
            setNotificationVisibility(DownloadManager.Request.VISIBILITY_VISIBLE_NOTIFY_COMPLETED)
            setDestinationInExternalPublicDir(Environment.DIRECTORY_DOWNLOADS, fileName)
            setAllowedOverMetered(true)
            setAllowedOverRoaming(false)
        }

        return downloadManager?.enqueue(request) ?: -1
    }

    private fun getProgress(downloadId: Int): Map<String, Any?> {
        val query = DownloadManager.Query().setFilterById(downloadId.toLong())
        val cursor = downloadManager?.query(query)
        
        cursor?.use {
            if (it.moveToFirst()) {
                val statusIndex = it.getColumnIndex(DownloadManager.COLUMN_STATUS)
                val bytesDownloadedIndex = it.getColumnIndex(DownloadManager.COLUMN_BYTES_DOWNLOADED_SO_FAR)
                val totalBytesIndex = it.getColumnIndex(DownloadManager.COLUMN_TOTAL_SIZE_BYTES)
                
                val status = if (statusIndex >= 0) it.getInt(statusIndex) else 0
                val bytesDownloaded = if (bytesDownloadedIndex >= 0) it.getLong(bytesDownloadedIndex) else 0
                val totalBytes = if (totalBytesIndex >= 0) it.getLong(totalBytesIndex) else 0
                
                return mapOf(
                    "status" to status,
                    "bytesDownloaded" to bytesDownloaded,
                    "totalBytes" to totalBytes
                )
            }
        }
        
        return mapOf("status" to -1, "bytesDownloaded" to 0, "totalBytes" to 0)
    }

    private fun installApk(downloadId: Int, fileName: String): Boolean {
        try {
            val uri = downloadManager?.getUriForDownloadedFile(downloadId.toLong())
            if (uri == null) {
                Log.e("Download", "Could not get URI for download $downloadId")
                return false
            }

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                if (!canRequestPackageInstalls()) {
                    requestPackageInstallPermission()
                    return false
                }
            }

            val installIntent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(uri, "application/vnd.android.package-archive")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }

            if (installIntent.resolveActivity(packageManager) != null) {
                startActivity(installIntent)
                return true
            } else {
                return tryInstallWithFileProvider(downloadId, fileName)
            }
        } catch (e: Exception) {
            Log.e("Install", "Error installing APK", e)
            return false
        }
    }

private fun tryInstallWithFileProvider(downloadId: Int, fileName: String): Boolean {
        try {
            val file = File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS), fileName)
            
            if (!file.exists()) {
                // Try to find it differently
                val uri = downloadManager?.getUriForDownloadedFile(downloadId.toLong())
                if (uri != null) {
                    // Use the URI directly - it might be a content:// URI
                    val installIntent = Intent(Intent.ACTION_VIEW).apply {
                        setDataAndType(uri, "application/vnd.android.package-archive")
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                    }
                    startActivity(installIntent)
                    return true
                }
            }
            
            // Try to grant permission and install
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val uri = FileProvider.getUriForFile(this, "$packageName.fileprovider", file)
                val installIntent = Intent(Intent.ACTION_VIEW).apply {
                    setDataAndType(uri, "application/vnd.android.package-archive")
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                }
                startActivity(installIntent)
                return true
            }
        } catch (e: Exception) {
            Log.e("FileProvider", "Error with FileProvider", e)
        }
        return false
    }

    private fun canRequestPackageInstalls(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            packageManager.canRequestPackageInstalls()
        } else {
            true
        }
    }

    private fun requestPackageInstallPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val intent = Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES).apply {
                data = Uri.parse("package:$packageName")
            }
            startActivity(intent)
        }
    }
}