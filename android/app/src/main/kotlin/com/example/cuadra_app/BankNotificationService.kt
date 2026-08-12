package com.example.cuadra_app

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log
import io.flutter.plugin.common.EventChannel
import org.json.JSONObject
import java.util.regex.Pattern

class BankNotificationService : NotificationListenerService() {

    companion object {
        private const val TAG = "CuadraHub"
        private const val PREFS_NAME = "cuadra_hub_prefs"
        private const val KEY_ALLOWED_PACKAGES = "allowed_notification_packages"

        var eventSink: EventChannel.EventSink? = null

        private val AMOUNT_REGEX = Pattern.compile(
            "Bs\\.?\\s*([0-9]+(?:[.,][0-9]{1,2})?)",
            Pattern.CASE_INSENSITIVE
        )

        private val PAYMENT_KEYWORDS = listOf(
            "recibiste", "pago recibido", "transferencia recibida", "deposito recibido",
            "cobro exitoso", "pago qr"
        )

        private val PACKAGE_TO_BANK = mapOf(
            // Fuente principal: la app de billetera QRWallet.
            "com.qr_cuadra_app"                 to "QRWallet",
            "com.mooveit.bcpb"                  to "BCP Bolivia",
            "com.bcp.bo.wallet"                 to "BCP Bolivia",
            "com.bg.ganamovil"                  to "Banco Ganadero",
            "com.baneco.application"            to "Banco Económico",
            "bo.com.bmsc.bancamovil"            to "Banco Mercantil",
            "com.juvomobileinc.tigoshop.bo"     to "Tigo Money",
            "com.bancosol.app"                  to "BancoSol",
            "bo.com.bisa.movil"                 to "Banco BISA",
            "com.fassil.app"                    to "Banco Fassil",
            "bo.com.bnb.movil"                  to "BNB"
        )

        @JvmStatic
        fun getAllowedPackages(context: Context): Set<String> {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            return prefs.getStringSet(KEY_ALLOWED_PACKAGES, emptySet())?.toSet() ?: emptySet()
        }

        @JvmStatic
        fun setAllowedPackages(context: Context, packages: Set<String>) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            prefs.edit().putStringSet(KEY_ALLOWED_PACKAGES, packages).apply()
        }
    }

    override fun onListenerConnected() {
        super.onListenerConnected()
        Log.d(TAG, "NotificationListenerService connected")
    }

    override fun onNotificationPosted(sbn: StatusBarNotification) {
        // Ignorar nuestras propias notificaciones (los push FCM "Pago recibido"),
        // si no se crea un loop: push → notif → se captura → POST → push → ...
        if (sbn.packageName == packageName) {
            Log.d(TAG, "Skipped: notificación propia (evita loop con FCM)")
            return
        }

        val allowedPackages = getAllowedPackages(this)
        if (allowedPackages.isNotEmpty() && !allowedPackages.contains(sbn.packageName)) {
            Log.d(TAG, "Skipped: package '${sbn.packageName}' not in configured allow-list")
            return
        }

        val extras = sbn.notification.extras
        val title = extras.getString("android.title") ?: ""
        val text = extras.getString("android.text") ?: ""
        val bigText = extras.getString("android.bigText") ?: ""
        // Prefer bigText (expanded) over text (truncated summary)
        val body = when {
            bigText.isNotEmpty() -> bigText
            else -> text
        }
        val fullText = "$title $body"
        val lower = fullText.lowercase()

        Log.d(TAG, "Notification received: pkg=${sbn.packageName} | text='$fullText'")

        if (PAYMENT_KEYWORDS.none { lower.contains(it) }) {
            Log.d(TAG, "Skipped: no payment keyword in '$lower'")
            return
        }

        val matcher = AMOUNT_REGEX.matcher(fullText)
        if (!matcher.find()) {
            Log.d(TAG, "Skipped: no amount found in '$fullText'")
            return
        }

        val amount = matcher.group(1)
            ?.replace(",", ".")
            ?.toDoubleOrNull() ?: return

        Log.d(TAG, "Payment detected: Bs $amount | sink=${eventSink != null}")

        val payload = JSONObject().apply {
            put("monto", amount)
            put("banco", PACKAGE_TO_BANK[sbn.packageName] ?: title.ifEmpty { "Banco" })
            put("texto_crudo", fullText.trim())
        }.toString()

        Handler(Looper.getMainLooper()).post {
            if (eventSink != null) {
                eventSink?.success(payload)
                Log.d(TAG, "Event sent to Flutter")
            } else {
                Log.e(TAG, "eventSink is null — Flutter not listening")
            }
        }
    }
}
