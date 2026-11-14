pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string socketPath: Quickshell.env("NIRI_SOCKET") ?? ""
    readonly property bool active: socketPath !== ""
    property var workspaces: []
    property var windows: []

    function activeWindow(output) {
        const ws = workspaces.find(w => w.output === output && w.is_active);
        if (!ws || ws.active_window_id === null) return null;
        return windows.find(w => w.id === ws.active_window_id) ?? null;
    }

    function isEmpty(output, name) {
        const ws = workspaces.find(w => w.output === output && (w.name ?? String(w.idx)) === name);
        return ws ? ws.active_window_id === null : false;
    }

    function handle(event) {
        if (event.WorkspacesChanged) {
            workspaces = event.WorkspacesChanged.workspaces;
        } else if (event.WorkspaceActivated) {
            const output = workspaces.find(w => w.id === event.WorkspaceActivated.id)?.output;
            workspaces = workspaces.map(w => w.output === output
                ? Object.assign({}, w, { is_active: w.id === event.WorkspaceActivated.id })
                : w);
        } else if (event.WindowsChanged) {
            windows = event.WindowsChanged.windows;
        } else if (event.WindowOpenedOrChanged) {
            const window = event.WindowOpenedOrChanged.window;
            windows = windows.filter(w => w.id !== window.id).concat(window);
        } else if (event.WindowClosed) {
            windows = windows.filter(w => w.id !== event.WindowClosed.id);
        } else if (event.WorkspaceActiveWindowChanged) {
            const change = event.WorkspaceActiveWindowChanged;
            workspaces = workspaces.map(w => w.id === change.workspace_id
                ? Object.assign({}, w, { active_window_id: change.active_window_id })
                : w);
        }
    }

    Socket {
        path: root.socketPath
        connected: root.active

        parser: SplitParser {
            onRead: line => root.handle(JSON.parse(line))
        }

        onConnectedChanged: if (connected) {
            write('"EventStream"\n');
            flush();
        }
    }
}
