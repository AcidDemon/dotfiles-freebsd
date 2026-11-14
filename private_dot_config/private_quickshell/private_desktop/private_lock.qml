//@ pragma UseQApplication
import QtQuick
import Quickshell
import Quickshell.Services.Pam
import Quickshell.Wayland
import qs.lock

// Runs as its own process (qs-lock), so a restart of the bar can never touch an active lock.
ShellRoot {
    id: root

    property string password: ""
    property string status: ""
    property bool failed: false
    property int attempts: 0
    property bool unlocking: false
    property bool capsLock: false

    function submit() {
        if (pam.active || password === "") return;
        failed = false;
        status = "";
        pam.start();
    }

    // freebsd: no caps-lock led in sysfs, so it is read off the typed letter (shift inverts caps)
    function checkCapsLock(event) {
        if (event.key === Qt.Key_CapsLock) capsLock = !capsLock;
        else if (event.text.toUpperCase() !== event.text.toLowerCase()) capsLock = (event.text === event.text.toUpperCase()) !== !!(event.modifiers & Qt.ShiftModifier);
    }

    PamContext {
        id: pam

        // freebsd: no quickshell-lock service, reuse the unix-selfauth stack (setuid helper, as hyprlock).
        // 0.3.1 wants <configDirectory>/<config> to exist, then calls pam_start(config), which searches /usr/local/etc/pam.d
        configDirectory: "/usr/local/etc/pam.d"
        config: "unix-selfauth"

        onResponseRequiredChanged: {
            if (responseRequired) respond(root.password);
        }
        onMessageChanged: {
            if (message && !responseRequired) root.status = message;
        }
        onCompleted: result => {
            if (result === PamResult.Success) {
                root.unlocking = true;
                unlockTimer.start();
                return;
            }
            root.attempts += 1;
            root.failed = true;
            root.status = `Authentication failed (${root.attempts})`;
            root.password = "";
        }
        onError: error => {
            root.failed = true;
            root.status = `Authentication error: ${PamError.toString(error)}`;
            root.password = "";
        }
    }

    // the fade-out plays before the compositor reveals the desktop
    Timer {
        id: unlockTimer

        interval: 280
        onTriggered: {
            lock.locked = false;
            quitTimer.start();
        }
    }

    Timer {
        id: quitTimer

        interval: 100
        onTriggered: Qt.quit()
    }

    WlSessionLock {
        id: lock

        locked: true

        WlSessionLockSurface {
            id: surface

            color: "black"

            LockSurface {
                anchors.fill: parent
                ctx: root
            }
        }
    }
}
