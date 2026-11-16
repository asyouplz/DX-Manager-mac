// SPDX-License-Identifier: Apache-2.0
package com.dxmanager.loopback;

import java.lang.reflect.Method;

/** Optional default-display user activity; no persistent device state is changed. */
final class PhonePower {
    static final int DEFAULT_DISPLAY = 0;
    static final int EVENT_OTHER = 0;
    // USER_ACTIVITY_FLAG_NO_CHANGE_LIGHTS; device testing may switch this to 0.
    static final int FLAGS = 1;
    private Object manager;
    private Method userActivity;
    private Method uptimeMillis;

    boolean poke() {
        try {
            if (userActivity == null) {
                Class<?> binderClass = Class.forName("android.os.IBinder");
                Class<?> serviceClass = Class.forName("android.os.ServiceManager");
                Object binder = serviceClass.getMethod("getService", String.class).invoke(null, "power");
                Class<?> stub = Class.forName("android.os.IPowerManager$Stub");
                Object power = stub.getMethod("asInterface", binderClass).invoke(null, binder);
                if (power == null) return false;
                Class<?> api = Class.forName("android.os.IPowerManager");
                Method activity;
                try {
                    activity = api.getMethod("userActivity", int.class, long.class, int.class, int.class);
                } catch (NoSuchMethodException unavailable) {
                    activity = api.getMethod("userActivity", long.class, int.class, int.class);
                }
                uptimeMillis = Class.forName("android.os.SystemClock").getMethod("uptimeMillis");
                manager = power;
                userActivity = activity;
            }
            Long time = (Long) uptimeMillis.invoke(null);
            if (userActivity.getParameterTypes().length == 4) {
                userActivity.invoke(manager, Integer.valueOf(DEFAULT_DISPLAY), time,
                        Integer.valueOf(EVENT_OTHER), Integer.valueOf(FLAGS));
            } else {
                userActivity.invoke(manager, time, Integer.valueOf(EVENT_OTHER), Integer.valueOf(FLAGS));
            }
            return true;
        } catch (Throwable unavailable) {
            return false;
        }
    }
}
