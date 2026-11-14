pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import "Parse.js" as Parse

Singleton {
    id: root

    property bool idleInhibited: false

    property real cpu: 0
    property var cpuUsage: []
    property real load: 0
    property var cpuPrevious: null
    property var mem: Parse.memInfo("")
    property var temp: null
    property var vpn: null
    // freebsd: from qs-net, no NetworkManager here
    property var net: null
    property var battery: null
    property var backlight: null

    property int backlightTarget: 0
    readonly property var player: {
        const players = Mpris.players.values;
        const isProxy = p => p.dbusName.endsWith(".playerctld");
        const proxy = players.find(p => isProxy(p) && p.identity);
        if (proxy) return proxy;
        const real = players.filter(p => !isProxy(p));
        return real.find(p => p.isPlaying) ?? real[0] ?? null;
    }
    // freebsd: pulseaudio through pactl, there is no pipewire server here. Nodes keep the
    // Pipewire shape the readers use (see Parse.pulse), writes go through setVolume and setMuted
    property var sink: null
    property var source: null
    property var streams: []
    property var pactlPending: ({})

    // systemd-run keeps apps out of this service's cgroup and away from Quickshell's Qt wrapper env
    function launch(args) {
        Quickshell.execDetached([Tools.systemdRun, "--user", "--collect", "--quiet", "--no-block", ...args]);
    }

    function setBacklight(percent) {
        backlightTarget = percent;
        backlightThrottle.start();
    }

    function refreshVpn() {
        vpnProc.running = true;
    }

    function refreshNet() {
        netProc.running = true;
    }

    // node is Sys.sink, Sys.source or one of Sys.streams
    function setVolume(node, volume) {
        if (!node) return;
        patchAudio(node, { volume });
        pactlPending[`${node.kind} ${node.id}`] = [Tools.pactl, `set-${node.kind}-volume`, node.id, `${Math.round(Math.max(0, volume) * 100)}%`];
        pactlThrottle.start();
    }

    function setMuted(node, muted) {
        if (!node) return;
        patchAudio(node, { muted });
        Quickshell.execDetached([Tools.pactl, `set-${node.kind}-mute`, node.id, muted ? "1" : "0"]);
    }

    // shown at once rather than after the pactl round trip, so quick scroll steps add up
    function patchAudio(node, audio) {
        const patch = n => n?.kind === node.kind && n.id === node.id
            ? Object.assign({}, n, { audio: Object.assign({}, n.audio, audio) })
            : n;
        sink = patch(sink);
        source = patch(source);
        streams = streams.map(patch);
    }

    function refreshPower() {
        batteryProc.running = true;
        backlightProc.running = true;
    }

    function stepBacklight(steps) {
        Quickshell.execDetached([Tools.brightnessctl, "set", steps > 0 ? `+${steps * 5}%` : `${-steps * 5}%-`]);
        // freebsd: backlight(8) raises no devd event, so read it back ourselves
        udevDebounce.restart();
    }

    Timer {
        id: backlightThrottle

        interval: 40
        onTriggered: {
            Quickshell.execDetached([Tools.brightnessctl, "set", `${root.backlightTarget}%`]);
            // freebsd: see stepBacklight
            udevDebounce.restart();
        }
    }

    Timer {
        id: pactlThrottle

        interval: 40
        onTriggered: {
            for (const command of Object.values(root.pactlPending)) Quickshell.execDetached(command);
            root.pactlPending = {};
        }
    }

    // freebsd: pactl subscribe stands in for the pipewire node signals. The loop outlives
    // pulseaudio restarts, and its "start" line reads the state on every (re)connect.
    // LC_ALL=C: pactl gettext-translates the event lines (and the JSON "db" strings)
    Process {
        command: ["sh", "-c", "while :; do echo start; LC_ALL=C \"$0\" subscribe; sleep 2; done", Tools.pactl]
        running: true
        stdout: SplitParser {
            onRead: line => {
                if (line === "start" || / on (sink|source|server)/.test(line)) pulseDebounce.restart();
            }
        }
    }

    Timer {
        id: pulseDebounce

        interval: 50
        // a read under way may predate this change, so wait for it
        onTriggered: {
            if (pulseProc.running) pulseDebounce.restart();
            else pulseProc.running = true;
        }
    }

    // one document per line; tr because pactl prints its JSON without a newline
    Process {
        id: pulseProc

        command: ["sh", "-c", "for q in info 'list sinks' 'list sources' 'list sink-inputs'; do LC_ALL=C \"$0\" -f json $q | tr -d '\\n'; echo; done", Tools.pactl]
        stdout: StdioCollector {
            onStreamFinished: {
                const pulse = Parse.pulse(text);
                root.sink = pulse.sink;
                root.source = pulse.source;
                root.streams = pulse.streams;
            }
        }
    }

    FileView {
        id: statFile

        // freebsd: linprocfs, same format as linux /proc
        path: "/compat/linux/proc/stat"
        onLoaded: {
            const samples = Parse.cpuSamples(text());
            if (root.cpuPrevious) {
                root.cpuUsage = Parse.cpuUsage(root.cpuPrevious, samples);
                root.cpu = root.cpuUsage[0].percent;
            }
            root.cpuPrevious = samples;
        }
    }

    FileView {
        id: loadFile

        path: "/compat/linux/proc/loadavg"
        onLoaded: root.load = parseFloat(text())
    }

    // freebsd: linprocfs meminfo has no MemAvailable and there is no spl kstat; qs-meminfo adds it, arc included
    Process {
        id: memProc

        command: [Tools.meminfo]
        stdout: StdioCollector {
            onStreamFinished: root.mem = Parse.memInfo(text, "")
        }
    }

    Timer {
        interval: 3000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: {
            statFile.reload();
            loadFile.reload();
        }
    }

    Timer {
        interval: 5000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: {
            memProc.running = true;
            netProc.running = true;
            tempProc.running = true;
        }
    }

    Timer {
        interval: 10000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: vpnProc.running = true
    }

    Timer {
        interval: 30000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root.refreshPower()
    }

    Process {
        id: tempProc

        command: [Tools.temperature]
        stdout: StdioCollector {
            onStreamFinished: root.temp = Parse.temperature(text)
        }
    }

    Process {
        id: vpnProc

        command: [Tools.vpn]
        stdout: StdioCollector {
            onStreamFinished: root.vpn = Parse.vpn(text)
        }
    }

    Process {
        id: netProc

        command: [Tools.net]
        stdout: StdioCollector {
            onStreamFinished: root.net = Parse.net(text)
        }
    }

    Process {
        id: batteryProc

        command: [Tools.battery]
        stdout: StdioCollector {
            onStreamFinished: root.battery = Parse.battery(text)
        }
    }

    Process {
        id: backlightProc

        command: [Tools.brightnessctl, "-m"]
        stdout: StdioCollector {
            onStreamFinished: root.backlight = Parse.backlight(text)
        }
    }

    Timer {
        id: udevDebounce

        interval: 80
        onTriggered: root.refreshPower()
    }

    // freebsd: devd stands in for udevadm. ACAD is the charger, CMBAT the battery, Video is acpi_video
    // moving the backlight for the Fn keys ("!system=ACPI subsystem=ACAD type=... notify=0x01")
    // ponytail: no reconnect if devd restarts, the 30 s poll still covers it
    Socket {
        path: "/var/run/devd.pipe"
        connected: true
        parser: SplitParser {
            onRead: line => {
                if (/ subsystem=(ACAD|CMBAT|Video)\b/.test(line)) udevDebounce.restart();
            }
        }
    }
}
