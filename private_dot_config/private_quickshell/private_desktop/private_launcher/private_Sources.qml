import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import qs.bar
import "Match.js" as Match

Scope {
    id: root

    required property string mode
    required property string query
    readonly property int limit: 100

    readonly property var appItems: DesktopEntries.applications.values
        .map(entry => ({
            kind: "app",
            key: entry.id,
            title: entry.name,
            detail: entry.genericName || entry.comment,
            icon: entry.icon,
            entry: entry,
            usage: usage.counts[entry.id] ?? 0,
            fields: [entry.name, entry.genericName, entry.comment, entry.keywords.join(" "), entry.categories.join(" "), entry.execString]
        }))
        .sort((a, b) => a.title.localeCompare(b.title))
    property string windowFilter: ""
    property string clipFilter: "all"
    readonly property var windowItems: windowList().filter(t => !windowFilter || t.appId === windowFilter).map((toplevel, index) => {
        const appId = toplevel.appId;
        return {
            kind: "window",
            key: `${index}-${appId}`,
            title: toplevel.title,
            detail: appId,
            icon: DesktopEntries.heuristicLookup(appId)?.icon ?? appId,
            toplevel: toplevel,
            fields: [toplevel.title, appId]
        };
    })
    property var clipboardItems: []
    readonly property var clipFilters: [
        { key: "all", title: "All" },
        { key: "text", title: "Text" },
        { key: "images", title: "Images" },
        { key: "links", title: "Links" }
    ]
    property var emojiList: []
    readonly property var emojiItems: emojiList.map(item => Object.assign({}, item, { usage: usage.counts[`emoji:${item.key}`] ?? 0 }))
    // what the shelf across the launcher's base offers in each mode
    readonly property var shelfItems: {
        const used = list => list.filter(item => item.usage > 0).sort((a, b) => b.usage - a.usage).slice(0, 12);
        switch (mode) {
        case "apps": return used(appItems);
        case "emoji": return used(emojiItems);
        case "windows":
        case "windows-here": return windowApps();
        case "clipboard": return clipFilters.map(filter => ({
            kind: "filter",
            key: filter.key,
            title: `${filter.title} ${clipboardItems.filter(item => filter.key === "all" || Match.clipKind(item) === filter.key).length}`,
            active: clipFilter === filter.key
        }));
        case "calc": return usage.calcHistory.map((entry, index) => ({ kind: "calc", key: `${index}`, title: `${entry.expression} = ${entry.result}`, expression: entry.expression }));
        }
        return [];
    }
    property string calcResult: ""

    readonly property var items: {
        switch (mode) {
        case "apps": return Match.rank(appItems, query, limit);
        case "windows":
        case "windows-here": return Match.rank(windowItems, query, limit);
        case "clipboard": return Match.rank(clipboardItems.filter(item => clipFilter === "all" || Match.clipKind(item) === clipFilter), query, limit);
        case "emoji": return Match.rank(emojiItems, query, limit);
        case "calc": return calcResult ? [{ kind: "calc", key: "result", title: calcResult, detail: "Enter copies", glyph: "\u{F00EC}" }] : [];
        }
        return [];
    }
    readonly property string emptyText: mode === "calc" ? "Type an expression" : "Nothing found"

    function windowList() {
        const hidden = Tools.hiddenWindows.split(" ");
        const all = mode === "windows-here" && Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE")
            ? (Hyprland.focusedWorkspace?.toplevels.values ?? []).map(t => t.wayland).filter(Boolean)
            : ToplevelManager.toplevels.values;
        return all.filter(toplevel => !hidden.includes(toplevel.appId));
    }

    // one entry per app with its window count, the busiest first
    function windowApps() {
        const all = mode === "windows-here" || mode === "windows" ? windowList() : [];
        const groups = {};
        for (const toplevel of all) groups[toplevel.appId] = (groups[toplevel.appId] ?? 0) + 1;
        return Object.keys(groups).map(appId => {
            const entry = DesktopEntries.heuristicLookup(appId);
            return { kind: "appfilter", key: appId, title: entry?.name ?? appId, icon: entry?.icon ?? appId, count: groups[appId], active: windowFilter === appId };
        }).sort((a, b) => b.count - a.count || a.title.localeCompare(b.title)).slice(0, 12);
    }

    function launch(entry) {
        const directory = entry.workingDirectory ? [`--working-directory=${entry.workingDirectory}`] : [];
        Sys.launch([...directory, "--", ...(entry.runInTerminal ? [Tools.terminal, "-e", ...entry.command] : entry.command)]);
        count(entry.id);
    }

    function count(key) {
        usage.counts = Object.assign({}, usage.counts, { [key]: (usage.counts[key] ?? 0) + 1 });
        save();
    }

    // never write before the file has loaded, that would replace it with the defaults
    function save() {
        if (usageFile.ready) usageFile.writeAdapter();
    }

    function activate(item) {
        switch (item.kind) {
        case "app": launch(item.entry); break;
        case "window": item.toplevel.activate(); break;
        case "clip": Quickshell.execDetached([Tools.clipCopy, item.key]); break;
        case "emoji":
            Quickshell.execDetached([Tools.copy, item.glyph, "Emoji"]);
            count(`emoji:${item.key}`);
            break;
        case "calc":
            Quickshell.execDetached([Tools.copy, item.title]);
            usage.calcHistory = [{ expression: query.trim(), result: item.title }]
                .concat(usage.calcHistory.filter(entry => entry.expression !== query.trim())).slice(0, 5);
            save();
            break;
        }
    }

    onModeChanged: {
        windowFilter = "";
        clipFilter = "all";
        refresh();
    }
    onQueryChanged: if (mode === "calc") calcDebounce.restart()
    Component.onCompleted: refresh()

    function refresh() {
        if (mode === "clipboard") clipboardProc.running = true;
        if (mode === "calc") calcDebounce.restart();
    }

    FileView {
        id: usageFile

        property bool ready: false

        path: Quickshell.statePath("launcher-usage.json")
        blockWrites: true
        printErrors: false
        onLoaded: ready = true
        onLoadFailed: ready = true

        JsonAdapter {
            id: usage

            property var counts: ({})
            property var calcHistory: []
        }
    }

    Process {
        id: clipboardProc

        command: [Tools.cliphist, "list"]
        stdout: StdioCollector {
            onStreamFinished: root.clipboardItems = Match.clipboardItems(text)
        }
    }

    FileView {
        path: root.mode === "emoji" ? Tools.emojiData : ""
        onLoaded: root.emojiList = Match.emojiItems(text())
    }

    Timer {
        id: calcDebounce

        interval: 120
        onTriggered: {
            if (!root.query.trim()) {
                root.calcResult = "";
                return;
            }
            calcProc.exec([Tools.qalc, "-t", "-nocurrencies", "--", root.query]);
        }
    }

    Process {
        id: calcProc

        stdout: StdioCollector {
            onStreamFinished: root.calcResult = text.trim()
        }
    }
}
