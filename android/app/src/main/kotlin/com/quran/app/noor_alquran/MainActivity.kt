package com.quran.app.noor_alquran

import android.app.AlarmManager
import android.content.Context
import android.content.Intent
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
	private val channelName = "noor_alquran/adhan"
	private val compassChannelName = "noor_alquran/compass"

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)
		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
			.setMethodCallHandler { call, result ->
				when (call.method) {
					"schedule" -> {
						val filePath = call.argument<String>("filePath")
						val alarms = call.argument<List<Map<String, Any>>>("alarms")
						if (alarms == null) {
							result.error("invalid_arguments", "Missing alarms schedule", null)
						} else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S &&
							!getSystemService(AlarmManager::class.java).canScheduleExactAlarms()
						) {
							try {
								startActivity(
									Intent(
										Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM,
										Uri.parse("package:$packageName")
									)
								)
							} catch (_: Exception) {}
							result.error("exact_alarm_permission_required", "Exact alarm permission is required", null)
						} else {
							AdhanAlarmScheduler.schedule(this, filePath, alarms)
							result.success(null)
						}
					}
					"cancel" -> {
						AdhanAlarmScheduler.cancel(this)
						result.success(null)
					}
					"stopAdhan" -> {
						val stopIntent = Intent(this, AdhanPlaybackService::class.java).setAction("com.quran.app.noor_alquran.STOP_ADHAN")
						startService(stopIntent)
						result.success(null)
					}
					"canScheduleExactAlarms" -> {
						if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
							val canSchedule = getSystemService(AlarmManager::class.java).canScheduleExactAlarms()
							result.success(canSchedule)
						} else {
							result.success(true)
						}
					}
					"requestExactAlarmPermission" -> {
						if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
							try {
								startActivity(
									Intent(
										Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM,
										Uri.parse("package:$packageName")
									)
								)
							} catch (_: Exception) {}
						}
						result.success(null)
					}
					"startDhikrPopup" -> {
						DhikrAlarmScheduler.start(this)
						result.success(null)
					}
					"stopDhikrPopup" -> {
						DhikrAlarmScheduler.stop(this)
						result.success(null)
					}
					else -> result.notImplemented()
				}
			}

		// Compass Hardware Sensor Event Channel (100% Offline)
		EventChannel(flutterEngine.dartExecutor.binaryMessenger, compassChannelName)
			.setStreamHandler(object : EventChannel.StreamHandler {
				private var sensorManager: SensorManager? = null
				private var sensorListener: SensorEventListener? = null
				private val rotationMatrix = FloatArray(9)
				private val orientationValues = FloatArray(3)
				private val lastAccelerometer = FloatArray(3)
				private val lastMagnetometer = FloatArray(3)
				private var lastAccelerometerSet = false
				private var lastMagnetometerSet = false

				override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
					sensorManager = getSystemService(Context.SENSOR_SERVICE) as SensorManager
					val rotationVector = sensorManager?.getDefaultSensor(Sensor.TYPE_ROTATION_VECTOR)

					if (rotationVector != null) {
						sensorListener = object : SensorEventListener {
							override fun onSensorChanged(event: SensorEvent?) {
								if (event?.sensor?.type == Sensor.TYPE_ROTATION_VECTOR) {
									SensorManager.getRotationMatrixFromVector(rotationMatrix, event.values)
									SensorManager.getOrientation(rotationMatrix, orientationValues)
									var azimuth = Math.toDegrees(orientationValues[0].toDouble()).toFloat()
									if (azimuth < 0) {
										azimuth += 360f
									}
									events?.success(azimuth.toDouble())
								}
							}
							override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}
						}
						sensorManager?.registerListener(sensorListener, rotationVector, SensorManager.SENSOR_DELAY_UI)
					} else {
						val accelerometer = sensorManager?.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)
						val magnetometer = sensorManager?.getDefaultSensor(Sensor.TYPE_MAGNETIC_FIELD)
						if (accelerometer != null && magnetometer != null) {
							sensorListener = object : SensorEventListener {
								override fun onSensorChanged(event: SensorEvent?) {
									if (event == null) return
									if (event.sensor.type == Sensor.TYPE_ACCELEROMETER) {
										System.arraycopy(event.values, 0, lastAccelerometer, 0, event.values.size)
										lastAccelerometerSet = true
									} else if (event.sensor.type == Sensor.TYPE_MAGNETIC_FIELD) {
										System.arraycopy(event.values, 0, lastMagnetometer, 0, event.values.size)
										lastMagnetometerSet = true
									}
									if (lastAccelerometerSet && lastMagnetometerSet) {
										if (SensorManager.getRotationMatrix(rotationMatrix, null, lastAccelerometer, lastMagnetometer)) {
											SensorManager.getOrientation(rotationMatrix, orientationValues)
											var azimuth = Math.toDegrees(orientationValues[0].toDouble()).toFloat()
											if (azimuth < 0) {
												azimuth += 360f
											}
											events?.success(azimuth.toDouble())
										}
									}
								}
								override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}
							}
							sensorManager?.registerListener(sensorListener, accelerometer, SensorManager.SENSOR_DELAY_UI)
							sensorManager?.registerListener(sensorListener, magnetometer, SensorManager.SENSOR_DELAY_UI)
						} else {
							events?.error("SENSOR_UNAVAILABLE", "Compass sensor is not available on this device", null)
						}
					}
				}

				override fun onCancel(arguments: Any?) {
					sensorListener?.let { sensorManager?.unregisterListener(it) }
					sensorListener = null
					sensorManager = null
					lastAccelerometerSet = false
					lastMagnetometerSet = false
				}
			})
	}
}
