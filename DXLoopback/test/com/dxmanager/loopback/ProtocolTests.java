// SPDX-License-Identifier: Apache-2.0
package com.dxmanager.loopback;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.util.Arrays;
import java.util.HashSet;

public final class ProtocolTests {
    private static int count;
    private static final String TOKEN = "0123456789abcdef0123456789abcdef";
    private interface Test { void run() throws Exception; }
    private static void test(String name, Test action) throws Exception {
        action.run(); count++; System.out.println("PASS " + name);
    }
    private static void check(boolean value) { if (!value) throw new AssertionError(); }
    private static Rtsp.Message message(String text) throws IOException {
        return Rtsp.read(new ByteArrayInputStream(text.getBytes(StandardCharsets.US_ASCII)));
    }
    private static String parameter(String body) {
        return "SET_PARAMETER rtsp://127.0.0.1 RTSP/1.0\r\nCSeq: 3\r\nContent-Length: "
                + body.getBytes(StandardCharsets.US_ASCII).length + "\r\n\r\n" + body;
    }
    private static void rejects(String input) throws Exception {
        try { message(input); throw new AssertionError("accepted malformed frame"); }
        catch (IOException expected) { }
    }
    public static void main(String[] args) throws Exception {
        test("exact body framing preserves next message", new Test() { public void run() throws Exception {
            String first = parameter("abc");
            ByteArrayInputStream stream = new ByteArrayInputStream((first + "OPTIONS * RTSP/1.0\r\nCSeq: 4\r\n\r\n").getBytes(StandardCharsets.US_ASCII));
            check("abc".equals(Rtsp.read(stream).body)); check(Rtsp.read(stream).first.startsWith("OPTIONS"));
        }});
        test("negative length rejected", new Test() { public void run() throws Exception { rejects("RTSP/1.0 200 OK\r\nContent-Length: -1\r\n\r\n"); }});
        test("excessive body rejected", new Test() { public void run() throws Exception { rejects("RTSP/1.0 200 OK\r\nContent-Length: 65537\r\n\r\n"); }});
        test("truncated body rejected", new Test() { public void run() throws Exception { rejects("RTSP/1.0 200 OK\r\nContent-Length: 4\r\n\r\nx"); }});
        test("duplicate header rejected", new Test() { public void run() throws Exception { rejects("RTSP/1.0 200 OK\r\nCSeq: 1\r\ncseq: 2\r\n\r\n"); }});
        test("truncated headers rejected", new Test() { public void run() throws Exception { rejects("RTSP/1.0 200 OK\r\nCSeq: 1\r\n"); }});
        test("only matching PLAY response marks ready", new Test() { public void run() throws Exception {
            Rtsp.Handshake handshake = new Rtsp.Handshake(20000, 20001);
            ByteArrayOutputStream out = new ByteArrayOutputStream();
            handshake.accept(message("OPTIONS * RTSP/1.0\r\nCSeq: 9\r\n\r\n"), out);
            handshake.accept(message("RTSP/1.0 200 OK\r\nCSeq: 1\r\n\r\n"), out);
            handshake.accept(message(parameter("wfd_trigger_method: SETUP\r\n")), out);
            handshake.accept(message("RTSP/1.0 200 OK\r\nCSeq: 2\r\nSession: abc123;timeout=30\r\n\r\n"), out);
            check(!handshake.isReady());
            handshake.accept(message("RTSP/1.0 200 OK\r\nCSeq: 1\r\n\r\n"), out);
            check(!handshake.isReady());
            handshake.accept(message("RTSP/1.0 200 OK\r\nCSeq: 3\r\n\r\n"), out);
            check(handshake.isReady());
        }});
        test("external presentation URL refused", new Test() { public void run() throws Exception {
            try { new Rtsp.Handshake(20000, 20001).accept(message(parameter("wfd_presentation_URL: rtsp://192.0.2.1/stream none\r\n")), new ByteArrayOutputStream()); throw new AssertionError(); }
            catch (IOException expected) { }
        }});
        test("unknown response cannot activate", new Test() { public void run() throws Exception {
            try { new Rtsp.Handshake(20000, 20001).accept(message("RTSP/1.0 200 OK\r\nCSeq: 42\r\nSession: abc\r\n\r\n"), new ByteArrayOutputStream()); throw new AssertionError(); }
            catch (IOException expected) { }
        }});
        test("token-only arguments accepted", new Test() { public void run() {
            check(SessionPolicy.validArguments(new String[] { TOKEN }));
        }});
        test("optional keep-active argument accepted", new Test() { public void run() {
            check(SessionPolicy.validArguments(new String[] { TOKEN, "keep-active" }));
        }});
        test("wrong keep-active literal rejected", new Test() { public void run() {
            check(!SessionPolicy.validArguments(new String[] { TOKEN, "--keep-active" }));
            check(!SessionPolicy.validArguments(new String[] { TOKEN, "KEEP-ACTIVE" }));
            check(!SessionPolicy.validArguments(new String[] { TOKEN, null }));
        }});
        test("missing and extra arguments rejected", new Test() { public void run() {
            check(!SessionPolicy.validArguments(null));
            check(!SessionPolicy.validArguments(new String[0]));
            check(!SessionPolicy.validArguments(new String[] { TOKEN, "keep-active", "extra" }));
        }});
        test("invalid argument tokens rejected", new Test() { public void run() {
            check(!SessionPolicy.validArguments(new String[] { "bad-token" }));
            check(!SessionPolicy.validArguments(new String[] { TOKEN.toUpperCase(java.util.Locale.ROOT), "keep-active" }));
            check(!SessionPolicy.validArguments(new String[] { TOKEN.substring(1) }));
            check(!SessionPolicy.validArguments(new String[] { TOKEN + "0", "keep-active" }));
            check(!SessionPolicy.validArguments(new String[] { null }));
        }});
        test("keep-active due immediately then every four seconds", new Test() { public void run() {
            long due = 123_000_000_000L;
            check(SessionPolicy.KEEP_ACTIVE_NS == 4_000_000_000L);
            check(!SessionPolicy.keepActiveDue(due, due - 1));
            check(SessionPolicy.keepActiveDue(due, due));
            due += SessionPolicy.KEEP_ACTIVE_NS;
            check(!SessionPolicy.keepActiveDue(due, due - 250_000_000L));
            check(!SessionPolicy.keepActiveDue(due, due - 1));
            check(SessionPolicy.keepActiveDue(due, due));
            check(SessionPolicy.keepActiveDue(due, due + 250_000_000L));
            due += SessionPolicy.KEEP_ACTIVE_NS;
            check(!SessionPolicy.keepActiveDue(due, due - 1));
            check(SessionPolicy.keepActiveDue(due, due));
        }});
        test("keep-active cadence survives nanoTime wraparound", new Test() { public void run() {
            long due = Long.MAX_VALUE - SessionPolicy.KEEP_ACTIVE_NS / 2;
            long next = due + SessionPolicy.KEEP_ACTIVE_NS;
            check(next < 0);
            check(!SessionPolicy.keepActiveDue(due, due - 1));
            check(SessionPolicy.keepActiveDue(due, due));
            check(SessionPolicy.keepActiveDue(due, next));
            check(!SessionPolicy.keepActiveDue(next, due));
            check(!SessionPolicy.keepActiveDue(next, next - 1));
            check(SessionPolicy.keepActiveDue(next, next));
            check(SessionPolicy.keepActiveDue(next, next + 1));
        }});
        test("heartbeat expires at 15 seconds", new Test() { public void run() {
            SessionPolicy lease = new SessionPolicy(TOKEN, 0); check(!lease.expired(14_999_999_999L)); check(lease.expired(15_000_000_000L));
        }});
        test("authenticated heartbeat renews", new Test() { public void run() {
            SessionPolicy lease = new SessionPolicy(TOKEN, 0); lease.receive("PING " + TOKEN, 10_000_000_000L); check(!lease.expired(20_000_000_000L));
        }});
        test("renewed heartbeat expires 15 seconds after last signal", new Test() { public void run() {
            SessionPolicy lease = new SessionPolicy(TOKEN, 0);
            lease.receive("PING " + TOKEN, 3_000_000_000L);
            check(!lease.expired(17_999_999_999L)); check(lease.expired(18_000_000_000L));
        }});
        test("STOP and EOF end lease", new Test() { public void run() {
            SessionPolicy lease = new SessionPolicy(TOKEN, 0); lease.receive("STOP " + TOKEN, 1); check(lease.expired(2));
            SessionPolicy eof = new SessionPolicy(TOKEN, 0); eof.stop(); check(eof.expired(2));
        }});
        test("wrong token cannot renew lease", new Test() { public void run() {
            SessionPolicy lease = new SessionPolicy(TOKEN, 0); lease.receive("PING ffffffffffffffffffffffffffffffff", 1); check(lease.expired(2));
        }});
        test("late heartbeat cannot revive a stopped session", new Test() { public void run() {
            SessionPolicy lease = new SessionPolicy(TOKEN, 0);
            lease.receive("STOP " + TOKEN, 1); lease.receive("PING " + TOKEN, 2);
            check(lease.expired(3));
        }});
        test("cleanup ownership needs name AND address", new Test() { public void run() {
            check(SessionPolicy.owns("DXM-x", "02:ab", "DXM-x", "02:AB"));
            check(!SessionPolicy.owns("DXM-x", "02:ab", "external", "02:ab"));
            check(!SessionPolicy.owns("DXM-x", "02:ab", "DXM-x", "02:cd"));
            check(!SessionPolicy.owns("DXM-x", "02:ab", null, null));
        }});
        test("only new unique WIFI display selected", new Test() { public void run() {
            HashSet<Integer> before = new HashSet<Integer>(Arrays.asList(0, 4));
            check(SessionPolicy.newWifiDisplay(before, Arrays.asList(new SessionPolicy.Display(0, 1), new SessionPolicy.Display(4, 3), new SessionPolicy.Display(9, 3))) == 9);
            check(SessionPolicy.newWifiDisplay(before, Arrays.asList(new SessionPolicy.Display(9, 3), new SessionPolicy.Display(10, 3))) == -1);
            check(SessionPolicy.newWifiDisplay(before, Arrays.asList(new SessionPolicy.Display(99, 5))) == -1);
        }});
        test("active external and overlay rejected", new Test() { public void run() {
            check(SessionPolicy.hasExternal(Arrays.asList(new SessionPolicy.Display(4, 2))));
            check(SessionPolicy.hasExternal(Arrays.asList(new SessionPolicy.Display(4, 3))));
            check(SessionPolicy.hasExternal(Arrays.asList(new SessionPolicy.Display(4, 4))));
            check(!SessionPolicy.hasExternal(Arrays.asList(new SessionPolicy.Display(0, 1), new SessionPolicy.Display(5, 5))));
        }});
        System.out.println("DXLoopback: " + count + " host tests passed; Android firmware/device validation is separate.");
    }
}
