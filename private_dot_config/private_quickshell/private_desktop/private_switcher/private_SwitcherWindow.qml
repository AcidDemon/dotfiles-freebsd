import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.bar
import qs.theme
import "Ring.js" as Ring

// Themes up and down, the selected theme's wallpapers left and right.
PanelWindow {
    id: root

    required property var switcher

    readonly property var themes: Themes.list
    readonly property string activeTheme: (themes.find(t => t.name === Base16.scheme) ?? themes[0]).id
    // the compositor puts the window on the focused output
    readonly property string output: "focused"
    // steps count on past either end so both lists go round; positions follow them animated
    property int themeStep: Math.max(0, themes.findIndex(t => t.id === activeTheme))
    property int wallStep: 0
    readonly property int themeIndex: mod(themeStep, themes.length)
    readonly property int wallIndex: mod(wallStep, pool.length)
    property var walls: ({})
    property var chosen: ({})
    property bool touched: false
    property bool peek: false
    property bool shuffle: false
    // seconds between shuffled wallpapers
    property int interval: 0
    readonly property var intervals: [60, 120, 300, 600, 900, 1800, 3600, 7200]
    property real themePos: themeStep
    property real wallPos: wallStep

    readonly property var theme: themes[themeIndex]
    readonly property var pool: walls[theme.id] ?? []
    readonly property string current: pool[wallIndex] ?? ""

    readonly property real aspect: width / Math.max(1, height)
    readonly property real cw: Math.min(width * 0.42, height * 0.46 * aspect)
    readonly property real ch: cw / aspect
    readonly property real midY: height * 0.47
    readonly property real gap: height * 0.06
    readonly property var themeScale: [1, 0.45, 0.32]
    readonly property var themeY: [0, ch / 2 + gap + ch * 0.45 / 2, ch / 2 + gap + ch * 0.45 + gap + ch * 0.32 / 2]
    readonly property var wallScale: [1, 0.5, 0.36, 0.3]
    readonly property var wallX: {
        const s = wallScale.map(f => f * cw / 2);
        const gx = cw * 0.05;
        const x1 = s[0] + gx + s[1];
        const x2 = x1 + s[1] + gx + s[2];
        return [0, x1, x2, x2 + s[2] + gx + s[3]];
    }
    // the row is bent onto the inside of a ring: 57° across, viewer a fifth of the radius behind its centre
    readonly property real hfov: 57
    readonly property real viewBack: 0.2
    readonly property real focal: Ring.focal(width, hfov)
    readonly property real ringArc: Ring.frontArc(cw / Math.max(1, width), hfov, viewBack)
    readonly property real ringHeight: ringArc / aspect
    readonly property var wallTheta: Ring.angles(ringArc, wallScale, 0.05)
    readonly property real floorY: -(ringHeight / 2 + ringHeight * 0.06)
    readonly property real gloss: 0.45
    readonly property real edge: 0.5
    readonly property real shadow: 0.43
    readonly property real reflect: 0.21
    readonly property real floorOpacity: 0.62
    readonly property real themeShift: Math.min(1, Math.abs(themeStep - themePos))

    function at(table, x) {
        x = Math.min(Math.abs(x), table.length - 1);
        const i = Math.floor(x);
        return i + 1 < table.length ? table[i] + (table[i + 1] - table[i]) * (x - i) : table[i];
    }

    function shownFor(id) {
        const list = walls[id] ?? [];
        return list[Math.max(0, chosen[id] ?? 0)] ?? "";
    }

    function pretty(path) {
        return path.split("/").pop()
            .replace(/\.[^.]+$/, "")
            .replace(/[-_ ]?\(?\d{3,5}x\d{3,5}\)?/g, "")
            .replace(/[-_]+/g, " ")
            .trim()
            .replace(/\b\w/g, c => c.toUpperCase());
    }

    function mod(i, n) {
        return n > 0 ? ((i % n) + n) % n : 0;
    }

    // nearest way round, in -n/2..n/2
    function wrap(d, n) {
        return n > 0 ? d - n * Math.round(d / n) : d;
    }

    // back to the active theme and its remembered wallpaper, so the hidden window decodes what the next open shows
    function reset() {
        themeMotion.enabled = false;
        wallMotion.enabled = false;
        themeStep = Math.max(0, themes.findIndex(t => t.id === activeTheme));
        wallStep = Math.max(0, chosen[theme.id] ?? 0);
        themeMotion.enabled = true;
        wallMotion.enabled = true;
        touched = false;
        peek = false;
    }

    function moveTheme(delta) {
        if (delta === 0 || themes.length < 2) return;
        themeStep += delta;
        wallMotion.enabled = false;
        wallStep = Math.max(0, chosen[theme.id] ?? 0);
        wallMotion.enabled = true;
        touched = false;
    }

    function moveWall(delta) {
        if (delta === 0 || pool.length < 2) return;
        wallStep += delta;
        touched = true;
    }

    function stepInterval(delta) {
        const next = delta > 0 ? intervals.find(s => s > interval) : intervals.filter(s => s < interval).pop();
        if (next === undefined) return;
        interval = next;
        Quickshell.execDetached([Tools.wallpaper, "interval", String(next)]);
    }

    function duration(s) {
        return s >= 3600 ? `${s / 3600} h` : `${Math.round(s / 60)} min`;
    }

    function apply() {
        const id = theme.id;
        const pick = current !== "" && (touched || (!shuffle && (chosen[id] ?? -1) < 0));
        const change = id !== activeTheme;
        if (pick || change) {
            Quickshell.execDetached([Tools.systemdRun, "--user", "--collect", "--quiet", "--", "/bin/sh", "-c",
                'if [ -n "$3" ]; then WALLPAPER_THEME="$1" "$2" pick "$3" "$4"; fi; if [ -n "$5" ]; then "$5" "$1"; fi',
                "sh", id, Tools.wallpaper, pick ? current : "", output, change ? Tools.themeSwitch : ""]);
        }
        if (pick) chosen = Object.assign({}, chosen, { [id]: wallIndex });
        switcher.open = false;
    }

    visible: switcher.open
    onVisibleChanged: {
        if (visible) {
            lister.running = true;
            shuffleState.running = true;
            intervalState.running = true;
        } else {
            reset();
        }
        stage.opacity = visible ? 1 : 0;
    }
    onActiveThemeChanged: if (!visible) reset()

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qs-switcher"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    Behavior on themePos {
        id: themeMotion

        NumberAnimation { duration: 420; easing.type: Easing.OutCubic }
    }

    Behavior on wallPos {
        id: wallMotion

        NumberAnimation { duration: 380; easing.type: Easing.OutCubic }
    }

    Process {
        id: lister

        property var found: ({})
        property var picked: ({})

        running: true
        command: [Tools.wallpaper, "list", root.output, ...root.themes.map(t => t.id)]
        stdout: SplitParser {
            onRead: line => {
                const [id, mark, path] = line.split("\t");
                if (!path) return;
                const list = lister.found[id] ?? (lister.found[id] = []);
                if (mark === "1") lister.picked[id] = list.length;
                list.push(path);
            }
        }
        // runs again on every open; replacing an unchanged list would rebuild the cards and decode everything again
        onExited: {
            const same = JSON.stringify([found, picked]) === JSON.stringify([root.walls, root.chosen]);
            if (!same) {
                root.walls = found;
                root.chosen = picked;
                root.reset();
            }
            found = {};
            picked = {};
        }
    }

    Process {
        id: shuffleState

        running: true
        command: [Tools.wallpaper, "shuffle", "status"]
        stdout: StdioCollector {
            onStreamFinished: root.shuffle = text.trim() === "on"
        }
    }

    Process {
        id: intervalState

        running: true
        command: [Tools.wallpaper, "interval"]
        stdout: StdioCollector {
            onStreamFinished: root.interval = parseInt(text) || 0
        }
    }

    Item {
        id: stage

        anchors.fill: parent
        focus: true
        opacity: 0

        Behavior on opacity {
            NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
        }

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape) root.switcher.open = false;
            else if (event.key === Qt.Key_Up || event.key === Qt.Key_K) root.moveTheme(-1);
            else if (event.key === Qt.Key_Down || event.key === Qt.Key_J) root.moveTheme(1);
            else if (event.key === Qt.Key_Left || event.key === Qt.Key_H) root.moveWall(-1);
            else if (event.key === Qt.Key_Right || event.key === Qt.Key_L) root.moveWall(1);
            else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) root.apply();
            else if (event.key === Qt.Key_Space && !event.isAutoRepeat) root.peek = true;
            else if (event.key === Qt.Key_S) {
                root.shuffle = !root.shuffle;
                Quickshell.execDetached([Tools.wallpaper, "shuffle", root.shuffle ? "on" : "off"]);
            } else if (root.shuffle && (event.key === Qt.Key_Plus || event.key === Qt.Key_Equal)) root.stepInterval(1);
            else if (root.shuffle && event.key === Qt.Key_Minus) root.stepInterval(-1);
            else return;
            event.accepted = true;
        }

        Keys.onReleased: event => {
            if (event.key === Qt.Key_Space && !event.isAutoRepeat) {
                root.peek = false;
                event.accepted = true;
            }
        }

        Rectangle {
            anchors.fill: parent
            color: Theme.crust
        }

        Image {
            id: backdrop

            anchors.fill: parent
            visible: false
            source: root.current !== "" ? "file://" + root.current : ""
            sourceSize.width: 480
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            retainWhileLoading: true
        }

        MultiEffect {
            anchors.fill: parent
            source: backdrop
            blurEnabled: true
            blur: 1
            blurMax: 64
            autoPaddingEnabled: false
        }

        Rectangle {
            anchors.fill: parent
            color: Qt.alpha(Theme.crust, 0.45)
        }

        // the floor the reflections sit under
        Rectangle {
            visible: root.pool.length > 0
            y: Ring.project(0, root.floorY, 1, root.viewBack, root.focal, root.width / 2, root.midY).y
            width: parent.width
            height: Math.max(0, parent.height - y)
            color: Theme.crust
            opacity: root.floorOpacity
        }

        Item {
            id: behindRow

            anchors.fill: parent
        }

        MouseArea {
            anchors.fill: parent
            onClicked: root.switcher.open = false
        }

        // the other themes, each with its remembered wallpaper
        Repeater {
            model: root.themes

            delegate: Card {
                id: themeCard

                required property var modelData
                required property int index
                readonly property real q: root.wrap(index - root.themePos, root.themes.length)
                readonly property real size: root.at(root.themeScale, q)

                visible: index !== root.themeIndex && Math.abs(q) < 1.9
                z: 10 - Math.abs(q)
                width: root.cw * size
                height: root.ch * size
                x: root.width / 2 - width / 2
                y: root.midY + Math.sign(q) * root.at(root.themeY, q) - height / 2
                opacity: 1 - Math.max(0, Math.abs(q) - 1)
                slant: Math.min(1, Math.abs(q))
                source: Math.abs(q) < 1.9 ? root.shownFor(modelData.id) : ""

                Stripes {
                    card: themeCard
                    colors: themeCard.modelData.colors
                    name: themeCard.modelData.name
                    opacity: themeCard.slant
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.moveTheme(root.wrap(themeCard.index - root.themeIndex, root.themes.length))
                }
            }
        }

        // the selected theme's wallpapers; the middle one is the preview
        Repeater {
            model: root.pool

            delegate: CurvedCard {
                id: wallCard

                required property string modelData
                required property int index
                readonly property real p: root.wrap(index - root.wallPos, root.pool.length)
                readonly property bool middle: index === root.wallIndex
                readonly property real q: middle ? root.themeStep - root.themePos : 0
                readonly property real size: root.at(root.wallScale, p) * root.at(root.themeScale, q)

                visible: Math.abs(p) < 3
                z: 20 - Math.abs(p)
                flatWidth: root.cw * size
                flatHeight: root.ch * size
                flatX: root.width / 2 + Math.sign(p) * root.at(root.wallX, p) - flatWidth / 2
                flatY: root.midY + Math.sign(q) * root.at(root.themeY, q) - flatHeight / 2
                fade: (middle ? 1 : 1 - Math.min(1, root.themeShift * 2)) * (1 - Math.max(0, Math.abs(p) - 2))
                slant: Math.min(1, Math.abs(q))
                source: Math.abs(p) < 3 ? modelData : ""
                theta: -Math.sign(p) * root.at(root.wallTheta, p)
                arc: root.ringArc * root.at(root.wallScale, p)
                cardHeight: root.ringHeight * root.at(root.wallScale, p)
                selected: Math.abs(p) < 0.5
                colors: root.theme.colors
                focal: root.focal
                back: root.viewBack
                centreX: root.width / 2
                centreY: root.midY
                floorY: root.floorY
                gloss: root.gloss
                edge: root.edge
                shadow: root.shadow
                reflect: root.reflect
                floorOpacity: root.floorOpacity
                under: behindRow
                onClicked: wallCard.middle ? root.apply() : root.moveWall(root.wrap(wallCard.index - root.wallIndex, root.pool.length))

                MiniDesktop {
                    anchors.fill: parent
                    visible: opacity > 0
                    opacity: Math.max(0, 1 - Math.abs(wallCard.p) * 2) * Math.max(0, 1 - Math.abs(wallCard.q) * 1.5)
                    colors: root.theme.colors
                    name: root.theme.name
                    peek: root.peek
                }

                Stripes {
                    card: wallCard.picture
                    colors: root.theme.colors
                    name: root.theme.name
                    opacity: wallCard.slant
                }
            }
        }

        Rectangle {
            visible: root.current !== ""
            x: root.width / 2 - width / 2
            y: root.midY + root.ch / 2 + (root.gap - height) / 2
            z: 30
            width: wallName.implicitWidth + 28
            height: 30
            radius: height / 2
            opacity: 1 - root.themeShift
            color: Qt.alpha(Theme.crust, 0.75)
            border.width: 1
            border.color: Qt.alpha("white", 0.1)

            Txt {
                id: wallName

                anchors.centerIn: parent
                text: root.pretty(root.current) + (root.pool.length > 1 ? `  ${root.wallIndex + 1}/${root.pool.length}` : "")
                font.pixelSize: 14
            }
        }

        Txt {
            visible: root.pool.length === 0 && Object.keys(root.walls).length > 0
            anchors.centerIn: parent
            z: 30
            text: `No wallpapers in themes/${root.theme.id} for this screen`
            color: Theme.fgDim
        }

        Row {
            anchors {
                horizontalCenter: parent.horizontalCenter
                bottom: parent.bottom
                bottomMargin: 28
            }
            z: 30
            spacing: 18

            Repeater {
                model: [
                    { key: "↑↓", text: "theme" },
                    { key: "←→", text: "wallpaper" },
                    { key: "Space", text: "preview" },
                    { key: "S", text: root.shuffle ? "shuffle on" : "shuffle off" },
                    ...(root.shuffle && root.interval > 0 ? [{ key: "+−", text: `every ${root.duration(root.interval)}` }] : []),
                    { key: "⏎", text: "apply" },
                    { key: "Esc", text: "close" }
                ]

                Row {
                    required property var modelData

                    spacing: 8

                    Keycap {
                        anchors.verticalCenter: parent.verticalCenter
                        height: 30
                        label: parent.modelData.key
                        labelSize: 13
                        active: parent.modelData.key === "S" && root.shuffle
                    }

                    Txt {
                        anchors.verticalCenter: parent.verticalCenter
                        text: parent.modelData.text
                        color: Theme.subtext1
                        font.pixelSize: 13
                    }
                }
            }
        }
    }
}
