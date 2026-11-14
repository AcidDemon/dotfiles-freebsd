pragma Singleton

import QtQuick
import Quickshell
import "../notifications/Duration.js" as Duration

// Lives outside the panel, so a countdown keeps running after it closes.
Singleton {
    id: root

    property string phase: "idle"
    property int durationMs: 0
    property int remainingMs: 0
    // wall clock, so a suspend cannot stretch the countdown
    property real endsAt: 0

    function select(milliseconds) {
        if (phase !== "idle") return;
        durationMs = milliseconds;
        remainingMs = milliseconds;
    }

    function start() {
        if (phase === "running" || remainingMs <= 0) return;
        endsAt = Date.now() + remainingMs;
        phase = "running";
    }

    function pause() {
        if (phase !== "running") return;
        remainingMs = Math.max(0, endsAt - Date.now());
        phase = "paused";
    }

    function stop() {
        phase = "idle";
        remainingMs = durationMs;
    }

    function tick() {
        remainingMs = Math.max(0, endsAt - Date.now());
        if (remainingMs > 0) return;
        const finished = Duration.label(durationMs);
        stop();
        Quickshell.execDetached([Tools.notifySend, "-a", "Timer", "-u", "critical", "Timer finished", finished]);
    }

    Timer {
        interval: 200
        repeat: true
        running: root.phase === "running"
        onTriggered: root.tick()
    }
}
