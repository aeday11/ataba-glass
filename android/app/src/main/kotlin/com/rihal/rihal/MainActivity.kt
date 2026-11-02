package com.rihal.rihal

import android.content.pm.PackageManager
import android.os.Build
import android.os.Debug
import android.provider.Settings
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.security.MessageDigest

/// قناة حماية التطبيق: كشف الجذر/التنقيب، وضع المطوّر، وبصمة توقيع التطبيق
/// الرقمية (تُستخدم للتحقق من أن النسخة أصلية ولم يُعاد توقيعها بتوقيع مزيف).
class MainActivity : FlutterActivity() {

    private val channelName = "rihal/security"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "securityInfo" -> result.success(securityInfo())
                    "deviceId" -> result.success(deviceId())
                    else -> result.notImplemented()
                }
            }
    }

    private fun deviceId(): String {
        return try {
            Settings.Secure.getString(contentResolver, Settings.Secure.ANDROID_ID) ?: ""
        } catch (e: Exception) {
            ""
        }
    }

    private fun securityInfo(): Map<String, Any?> {
        return mapOf(
            "rooted" to isDeviceRooted(),
            "debugger" to (Debug.isDebuggerConnected() || Debug.waitingForDebugger()),
            "emulator" to isEmulator(),
            "signatureSha256" to appSignatureSha256(),
            "installer" to installerName()
        )
    }

    /// كشف بسيط وآمن (دون ادعاءات قاطعة): مسارات su معروفة + بصمة test-keys.
    private fun isDeviceRooted(): Boolean {
        val paths = arrayOf(
            "/system/bin/su", "/system/xbin/su", "/sbin/su",
            "/system/sd/xbin/su", "/system/bin/failsafe/su",
            "/data/local/su", "/data/local/bin/su", "/data/local/xbin/su",
            "/su/bin/su"
        )
        for (p in paths) {
            try { if (File(p).exists()) return true } catch (_: Exception) {}
        }
        return Build.TAGS != null && Build.TAGS!!.contains("test-keys")
    }

    private fun isEmulator(): Boolean {
        return (Build.FINGERPRINT.startsWith("generic")
                || Build.FINGERPRINT.contains("emulator")
                || Build.FINGERPRINT.contains("Android SDK")
                || Build.MODEL.contains("Emulator")
                || Build.MODEL.contains("Android SDK built for")
                || Build.MANUFACTURER.contains("Genymotion")
                || Build.PRODUCT == "sdk"
                || Build.HARDWARE.contains("goldfish")
                || Build.HARDWARE.contains("ranchu"))
    }

    /// بصمة SHA-256 لشهادة توقيع التطبيق الحالية.
    private fun appSignatureSha256(): String {
        return try {
            val sigs = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                val info = packageManager.getPackageInfo(
                    packageName, PackageManager.GET_SIGNING_CERTIFICATES
                )
                val signingInfo = info.signingInfo ?: return ""
                if (signingInfo.hasMultipleSigners()) signingInfo.apkContentsSigners
                else signingInfo.signingCertificateHistory
            } else {
                @Suppress("DEPRECATION")
                val info = packageManager.getPackageInfo(
                    packageName, PackageManager.GET_SIGNATURES
                )
                @Suppress("DEPRECATION")
                info.signatures
            }
            val sig = sigs?.firstOrNull() ?: return ""
            val digest = MessageDigest.getInstance("SHA-256").digest(sig.toByteArray())
            digest.joinToString(":") { "%02X".format(it) }
        } catch (e: Exception) {
            Log.w("KhademSecurity", "signature read failed", e)
            ""
        }
    }

    private fun installerName(): String {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                packageManager.getInstallSourceInfo(packageName).installingPackageName ?: ""
            } else {
                @Suppress("DEPRECATION")
                packageManager.getInstallerPackageName(packageName) ?: ""
            }
        } catch (e: Exception) {
            ""
        }
    }
}
