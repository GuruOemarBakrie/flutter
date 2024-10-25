package com.example.test_flutter

import android.app.ActivityManager
import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.os.UserManager
import android.view.KeyEvent
import android.view.View
import android.view.WindowManager
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val KIOSK_CHANNEL = "com.example.test_flutter/kiosk"
    private lateinit var devicePolicyManager: DevicePolicyManager
    private lateinit var componentName: ComponentName
    private lateinit var activityManager: ActivityManager

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        initializeServices()
    }

    private fun initializeServices() {
        devicePolicyManager = getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
        componentName = ComponentName(this, DeviceAdminReceiver::class.java)
        activityManager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, KIOSK_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startKioskMode" -> {
                    try {
                        val success = startKioskMode()
                        result.success(success)
                    } catch (e: Exception) {
                        result.error("KIOSK_ERROR", "Error enabling kiosk mode: ${e.message}", null)
                    }
                }
                "stopKioskMode" -> {
                    try {
                        stopKioskMode()
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("KIOSK_ERROR", "Error disabling kiosk mode: ${e.message}", null)
                    }
                }
                "isKioskModeEnabled" -> {
                    result.success(isInKioskMode())
                }
                "isDeviceAdminActive" -> {
                    result.success(devicePolicyManager.isAdminActive(componentName))
                }
                "requestDeviceAdmin" -> {
                    requestDeviceAdmin()
                    result.success(true)
                }
                "startLockTask" -> {
                    if (devicePolicyManager.isLockTaskPermitted(packageName)) {
                        startLockTask()
                        result.success(true)
                    } else {
                        result.success(false)
                    }
                }
                "stopLockTask" -> {
                    stopLockTask()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun startKioskMode(): Boolean {
        try {
            if (!devicePolicyManager.isAdminActive(componentName)) {
                requestDeviceAdmin()
                return false
            }

            // Check if app is device owner
            if (!devicePolicyManager.isDeviceOwnerApp(packageName)) {
                throw Exception("App is not device owner. Please set device owner using ADB command.")
            }

            // Set kiosk policies
            devicePolicyManager.apply {
                setLockTaskPackages(componentName, arrayOf(packageName))
                
                // Disable keyguard and status bar
                setKeyguardDisabled(componentName, true)
                setStatusBarDisabled(componentName, true)

                // Prevent system dialogs
                addUserRestriction(componentName, UserManager.DISALLOW_SAFE_BOOT)
                addUserRestriction(componentName, UserManager.DISALLOW_FACTORY_RESET)
                addUserRestriction(componentName, UserManager.DISALLOW_ADD_USER)
                addUserRestriction(componentName, UserManager.DISALLOW_MOUNT_PHYSICAL_MEDIA)
                addUserRestriction(componentName, UserManager.DISALLOW_ADJUST_VOLUME)
            }

            // Start lock task mode
            startLockTask()

            // Hide system UI
            window.decorView.systemUiVisibility = (View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                    or View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                    or View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                    or View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                    or View.SYSTEM_UI_FLAG_FULLSCREEN
                    or View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY)

            // Add window flags
            window.addFlags(WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD)
            window.addFlags(WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED)
            window.addFlags(WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON)

            return true
        } catch (e: Exception) {
            e.printStackTrace()
            return false
        }
    }

    private fun stopKioskMode() {
        try {
            stopLockTask()
            
            devicePolicyManager.apply {
                setKeyguardDisabled(componentName, false)
                setStatusBarDisabled(componentName, false)
                
                clearUserRestriction(componentName, UserManager.DISALLOW_SAFE_BOOT)
                clearUserRestriction(componentName, UserManager.DISALLOW_FACTORY_RESET)
                clearUserRestriction(componentName, UserManager.DISALLOW_ADD_USER)
                clearUserRestriction(componentName, UserManager.DISALLOW_MOUNT_PHYSICAL_MEDIA)
                clearUserRestriction(componentName, UserManager.DISALLOW_ADJUST_VOLUME)
            }

            // Clear window flags
            window.clearFlags(WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD)
            window.clearFlags(WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED)
            window.clearFlags(WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun isInKioskMode(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            activityManager.lockTaskModeState == ActivityManager.LOCK_TASK_MODE_LOCKED
        } else {
            activityManager.isInLockTaskMode
        }
    }

    private fun requestDeviceAdmin() {
        val intent = Intent(DevicePolicyManager.ACTION_ADD_DEVICE_ADMIN).apply {
            putExtra(DevicePolicyManager.EXTRA_DEVICE_ADMIN, componentName)
            putExtra(DevicePolicyManager.EXTRA_ADD_EXPLANATION, "Application requires device admin access for exam mode")
        }
        startActivity(intent)
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (hasFocus && isInKioskMode()) {
            window.decorView.systemUiVisibility = (View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                    or View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                    or View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                    or View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                    or View.SYSTEM_UI_FLAG_FULLSCREEN
                    or View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY)
        }
    }

    override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        return when (keyCode) {
            KeyEvent.KEYCODE_VOLUME_DOWN,
            KeyEvent.KEYCODE_VOLUME_UP,
            KeyEvent.KEYCODE_BACK,
            KeyEvent.KEYCODE_HOME -> true
            else -> super.onKeyDown(keyCode, event)
        }
    }
}