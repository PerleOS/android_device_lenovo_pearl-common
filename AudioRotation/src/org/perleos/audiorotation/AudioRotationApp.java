/*
 * SPDX-FileCopyrightText: The PerleOS Project
 * SPDX-License-Identifier: Apache-2.0
 */

package org.perleos.audiorotation;

import android.app.Application;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.hardware.display.DisplayManager;
import android.media.AudioManager;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;
import android.view.Display;
import android.view.Surface;

/**
 * Tells the stock audio HAL how the display is rotated, so that it assigns
 * the left and right channels to the four speakers for that orientation.
 *
 * The stock HAL takes the orientation from the "gsensor_rotation" parameter,
 * which the stock framework sends from AudioService on every rotation and
 * after an audioserver restart. AOSP sends only "rotation", which this HAL
 * uses for the Qualcomm L/R swap, not for the speaker layout.
 *
 * The HAL resets the layout on every set_parameters call that lacks the key,
 * and AudioService sends "screen_state" right after each rotation and on each
 * screen on, so the value is sent again once those calls are done.
 */
public class AudioRotationApp extends Application implements DisplayManager.DisplayListener {
    private static final String TAG = "PearlAudioRotation";
    private static final long RESEND_DELAY_MS = 500;

    private AudioManager mAudioManager;
    private DisplayManager mDisplayManager;
    private Handler mHandler;
    private int mLastRotation = -1;
    private final Runnable mResend = this::send;

    @Override
    public void onCreate() {
        super.onCreate();
        mAudioManager = getSystemService(AudioManager.class);
        mDisplayManager = getSystemService(DisplayManager.class);

        Handler handler = new Handler(Looper.getMainLooper());
        mHandler = handler;
        mDisplayManager.registerDisplayListener(this, handler);
        registerReceiver(new BroadcastReceiver() {
            @Override
            public void onReceive(Context context, Intent intent) {
                scheduleResend();
            }
        }, new IntentFilter(Intent.ACTION_SCREEN_ON), null, handler);
        try {
            // The HAL forgets the rotation when audioserver restarts.
            mAudioManager.setAudioServerStateCallback(handler::post,
                    new AudioManager.AudioServerStateCallback() {
                        @Override
                        public void onAudioServerUp() {
                            mLastRotation = -1;
                            update();
                        }
                    });
        } catch (SecurityException e) {
            Log.e(TAG, "Cannot monitor audioserver restarts", e);
        }
        update();
    }

    @Override
    public void onDisplayAdded(int displayId) {
    }

    @Override
    public void onDisplayRemoved(int displayId) {
    }

    @Override
    public void onDisplayChanged(int displayId) {
        if (displayId == Display.DEFAULT_DISPLAY) {
            update();
        }
    }

    private void update() {
        Display display = mDisplayManager.getDisplay(Display.DEFAULT_DISPLAY);
        if (display == null) {
            return;
        }
        int rotation = display.getRotation();
        if (rotation == mLastRotation) {
            return;
        }
        mLastRotation = rotation;
        send();
        scheduleResend();
    }

    private void scheduleResend() {
        mHandler.removeCallbacks(mResend);
        mHandler.postDelayed(mResend, RESEND_DELAY_MS);
    }

    private void send() {
        if (mLastRotation < 0) {
            return;
        }
        String parameter = "gsensor_rotation=" + toHalRotation(mLastRotation);
        Log.d(TAG, parameter);
        mAudioManager.setParameters(parameter);
    }

    /**
     * The HAL value is the display rotation in degrees. With mode 0 the left
     * channel plays on the left edge of the natural (landscape) orientation,
     * and each further 90 degrees moves it a quarter turn with the display.
     * The stock framework used another mapping because it counted rotations
     * from a portrait natural orientation.
     */
    private static int toHalRotation(int surfaceRotation) {
        switch (surfaceRotation) {
            case Surface.ROTATION_90:
                return 90;
            case Surface.ROTATION_180:
                return 180;
            case Surface.ROTATION_270:
                return 270;
            case Surface.ROTATION_0:
            default:
                return 0;
        }
    }
}
