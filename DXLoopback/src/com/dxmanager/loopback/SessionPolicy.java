// SPDX-License-Identifier: Apache-2.0
package com.dxmanager.loopback;

import java.util.List;
import java.util.Set;

/** Pure session policy, exercised on the build host without Android. */
final class SessionPolicy {
    static final long HEARTBEAT_NS = 15_000_000_000L;
    static final String KEEP_ACTIVE_ARGUMENT = "keep-active";
    static final long KEEP_ACTIVE_NS = 4_000_000_000L;
    private final String token;
    private volatile long heartbeat;
    private volatile boolean stopped;
    SessionPolicy(String token, long now) {
        if (token == null || !token.matches("[0-9a-f]{32}")) throw new IllegalArgumentException("invalid token");
        this.token = token;
        this.heartbeat = now;
    }
    void receive(String line, long now) {
        if (("PING " + token).equals(line)) heartbeat = now;
        else stopped = true; // STOP, EOF, or malformed control loses the lease; no command execution.
    }
    void stop() { stopped = true; }
    boolean expired(long now) { return stopped || now - heartbeat >= HEARTBEAT_NS; }
    static boolean validArguments(String[] args) {
        return args != null && (args.length == 1 || args.length == 2)
                && args[0] != null && args[0].matches("[0-9a-f]{32}")
                && (args.length == 1 || KEEP_ACTIVE_ARGUMENT.equals(args[1]));
    }
    static boolean keepActiveDue(long dueNanos, long nowNanos) {
        return nowNanos - dueNanos >= 0;
    }
    static boolean owns(String expectedName, String expectedAddress, String name, String address) {
        return expectedName.equals(name) && expectedAddress.equalsIgnoreCase(address);
    }
    static final class Display {
        final int id;
        final int type;
        Display(int id, int type) { this.id = id; this.type = type; }
    }
    static boolean hasExternal(List<Display> displays) {
        for (Display display : displays) {
            if (display.id != 0 && (display.type == 2 || display.type == 3 || display.type == 4)) return true;
        }
        return false;
    }
    static int newWifiDisplay(Set<Integer> before, List<Display> after) {
        int found = -1;
        for (Display display : after) {
            if (!before.contains(display.id) && display.type == 3) {
                if (found >= 0) return -1; // Never guess the largest ID.
                found = display.id;
            }
        }
        return found;
    }
}
