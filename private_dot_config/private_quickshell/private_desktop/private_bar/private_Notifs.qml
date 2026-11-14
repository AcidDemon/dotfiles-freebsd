pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import "../notifications/Notify.js" as Notify

Singleton {
    id: root

    property bool panelOpen: false
    property var popups: []
    property var arrivals: ({})
    property real now: Date.now()
    readonly property var stored: server.trackedNotifications.values.filter(n => !n.transient).reverse()
    readonly property var groups: Notify.groupByApp(stored)
    readonly property int count: stored.length
    readonly property bool dnd: saved.dnd

    function bypassesDnd(n) {
        return n.urgency === NotificationUrgency.Critical || !!n.hints.SWAYNC_BYPASS_DND;
    }

    function showPopup(n) {
        if (panelOpen || (dnd && !bypassesDnd(n)) || popups.includes(n)) return;
        popups = [n].concat(popups);
    }

    function removePopup(n) {
        popups = popups.filter(p => p !== n);
    }

    function add(n) {
        const key = Notify.syncKey(n.hints);
        if (key) {
            for (const other of server.trackedNotifications.values.filter(o => Notify.syncKey(o.hints) === key)) other.dismiss();
        }
        n.tracked = true;
        arrivals[n.id] = Date.now();
        n.closed.connect(() => root.removePopup(n));
        n.bodyChanged.connect(() => root.showPopup(n));
        n.summaryChanged.connect(() => root.showPopup(n));
        showPopup(n);
    }

    // timeout hides the popup; only transient ones are gone for good
    function popupExpired(n) {
        if (n.transient) n.expire();
        else removePopup(n);
    }

    function hideAllPopups() {
        for (const n of popups.filter(p => p.transient)) n.expire();
        popups = [];
    }

    function actionsOf(n) {
        const actions = n?.actions ?? [];
        const result = [];
        for (let i = 0; i < actions.length; i++) result.push(actions[i]);
        return result;
    }

    function activate(n, action) {
        const target = action ?? actionsOf(n).find(a => a.identifier === "default");
        if (target) {
            target.invoke();
            panelOpen = false;
        } else if (!n.resident) {
            n.dismiss();
        }
    }

    function clearAll() {
        for (const n of stored) n.dismiss();
    }

    function toggleDnd() {
        saved.dnd = !saved.dnd;
        savedFile.writeAdapter();
    }

    NotificationServer {
        id: server

        keepOnReload: true
        persistenceSupported: true
        bodyMarkupSupported: true
        actionsSupported: true
        imageSupported: true
        onNotification: n => root.add(n)
    }

    FileView {
        id: savedFile

        path: Quickshell.statePath("notifications.json")
        blockWrites: true
        printErrors: false

        JsonAdapter {
            id: saved

            property bool dnd: false
        }
    }

    Timer {
        interval: 30000
        repeat: true
        running: root.count > 0
        onTriggered: root.now = Date.now()
    }
}
