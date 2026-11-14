// node private_dot_config/private_quickshell/.tests/parse-check.js
const assert = require("assert");
const fs = require("fs");
const path = require("path");
const vm = require("vm");

const source = fs.readFileSync(path.join(__dirname, "../private_desktop/private_bar/private_Parse.js"), "utf8");
vm.runInThisContext(source.replace(/^\.pragma.*$/m, ""));
const matchSource = fs.readFileSync(path.join(__dirname, "../private_desktop/private_launcher/private_Match.js"), "utf8");
vm.runInThisContext(matchSource.replace(/^\.pragma.*$/m, ""));

const icons = ["a", "b", "c"];
assert.strictEqual(iconFor(0, icons), "a");
assert.strictEqual(iconFor(33, icons), "b");
assert.strictEqual(iconFor(100, icons), "c");

const before = cpuSamples("cpu  100 0 100 800 0 0 0 0 0 0\ncpu0 50 0 50 400 0\ncpu1 50 0 50 400 0\nintr 1 2\nctxt 3");
const after = cpuSamples("cpu  150 0 150 850 50 0 0 0 0 0\ncpu0 100 0 100 400 0\ncpu1 50 0 50 450 50\nintr 1 2\nctxt 3");
assert.deepStrictEqual(cpuUsage(before, after), [
    { name: "cpu", percent: 50 },
    { name: "cpu0", percent: 100 },
    { name: "cpu1", percent: 0 },
]);
assert.strictEqual(cpuUsage(after, after)[0].percent, 0);
assert.strictEqual(
    cpuTooltip(cpuUsage(before, after), 2.5),
    "Total: 50%   ·   load 2.50\nCore0: 100%\nCore1: 0%",
);

const mem = memInfo("MemTotal: 2097152 kB\nMemFree: 1 kB\nMemAvailable: 1048576 kB\nSwapTotal: 1048576 kB\nSwapFree: 524288 kB\n");
assert.deepStrictEqual([mem.totalG, mem.usedG, mem.pct, mem.swapUsedG, mem.swapPct], [2, 1, 50, 0.5, 50]);
assert.strictEqual(memInfo("").usedG, 0);
const withArc = memInfo("MemTotal: 2097152 kB\nMemAvailable: 524288 kB\n", "name type data\nc_min 4 1\nsize 4 536870912\n");
assert.strictEqual(withArc.usedG, 1);

const discharging = battery("POWER_SUPPLY_STATUS=Discharging\nPOWER_SUPPLY_CAPACITY=49\nPOWER_SUPPLY_ENERGY_NOW=30000000\nPOWER_SUPPLY_ENERGY_FULL=60000000\nPOWER_SUPPLY_POWER_NOW=20000000\n");
assert.deepStrictEqual(discharging, { status: "Discharging", capacity: 49, timeTo: "Empty in 1 h 30 min" });
const charging = battery("POWER_SUPPLY_STATUS=Charging\nPOWER_SUPPLY_CAPACITY=50\nPOWER_SUPPLY_CHARGE_NOW=1000\nPOWER_SUPPLY_CHARGE_FULL=2000\nPOWER_SUPPLY_CURRENT_NOW=2000\n");
assert.strictEqual(charging.timeTo, "Full in 0 h 30 min");
assert.strictEqual(battery("POWER_SUPPLY_STATUS=Full\nPOWER_SUPPLY_CAPACITY=99\n").capacity, 99);
assert.strictEqual(battery(""), null);
const atLimit = battery("POWER_SUPPLY_STATUS=Not charging\nPOWER_SUPPLY_POWER_NOW=0\nPOWER_SUPPLY_ENERGY_NOW=33080000\nPOWER_SUPPLY_ENERGY_FULL=67200000\nPOWER_SUPPLY_CAPACITY=49\n");
assert.deepStrictEqual(atLimit, { status: "Not charging", capacity: 49, timeTo: "Plugged" });

assert.deepStrictEqual(backlight("intel_backlight,backlight,30720,41%,75000\n"), { device: "intel_backlight", percent: 41 });
assert.strictEqual(backlight(""), null);
assert.strictEqual(ipv4("2: eth1    inet 192.168.1.5/24 brd 192.168.1.255 scope global"), "192.168.1.5/24");

const temp = temperature(`{"text":"<span size='130%' color='#fab387'>X</span> 57°","class":"good","tooltip":"t"}\n`);
assert.deepStrictEqual(temp, { cls: "good", tip: "t", value: 57 });
assert.strictEqual(temperature(""), null);

const ts = vpn(`{"text":"<span color='#a6e3a1'>X</span> TS","class":"up","tooltip":"Tailscale: 100.64.0.4"}\n`);
assert.deepStrictEqual(ts, { kind: "tailscale", tip: "Tailscale: 100.64.0.4", label: "TS" });
assert.strictEqual(vpn(`{"text":"<span>X</span>","class":"down","tooltip":"no tunnel"}\n`).label, "");

// freebsd: the shims' real output on vinokur
assert.deepStrictEqual(
    battery("POWER_SUPPLY_STATUS=Full\nPOWER_SUPPLY_CAPACITY=100\nPOWER_SUPPLY_CHARGE_FULL=3672\nPOWER_SUPPLY_CHARGE_NOW=3672\nPOWER_SUPPLY_CURRENT_NOW=0\n"),
    { status: "Full", capacity: 100, timeTo: "Full" },
);
assert.strictEqual(
    battery("POWER_SUPPLY_STATUS=Discharging\nPOWER_SUPPLY_CAPACITY=50\nPOWER_SUPPLY_CHARGE_FULL=3672\nPOWER_SUPPLY_CHARGE_NOW=1836\nPOWER_SUPPLY_CURRENT_NOW=918\n").timeTo,
    "Empty in 2 h 0 min",
);
assert.strictEqual(battery("POWER_SUPPLY_STATUS=Not charging\nPOWER_SUPPLY_CAPACITY=80\nPOWER_SUPPLY_CHARGE_FULL=0\nPOWER_SUPPLY_CHARGE_NOW=0\nPOWER_SUPPLY_CURRENT_NOW=0\n").timeTo, "Plugged");
const bsdMem = memInfo("MemTotal:  16006148 kB\nSwapTotal: 41943040 kB\nSwapFree:  41939736 kB\nMemAvailable: 10883782 kB\n", "");
assert.deepStrictEqual([bsdMem.pct, bsdMem.swapPct, Math.round(bsdMem.availG * 10)], [32, 0, 104]);
assert.deepStrictEqual(backlight("amdgpu_bl0,backlight,100,100%,100\n"), { device: "amdgpu_bl0", percent: 100 });
const bsdTemp = temperature(`{"text":"<span size='130%' color='#fab387'>󰔏</span> 78°","class":"good","tooltip":"CPU die (Tctl)   78°C\\ndev.cpu.*        78.5°C"}\n`);
assert.deepStrictEqual([bsdTemp.cls, bsdTemp.value, bsdTemp.tip.split("\n").length], ["good", 78, 2]);
assert.deepStrictEqual(
    vpn(`{"text":"<span size='130%' color='#a6e3a1'>󰖂</span> TS","class":"up","tooltip":"Tailscale: 100.64.0.14"}\n`),
    { kind: "tailscale", tip: "Tailscale: 100.64.0.14", label: "TS" },
);

assert.deepStrictEqual(
    net("kind=wifi\niface=wlan0\naddress=192.168.0.174/24\nwifi=up\nssid=AN-VA\nstrength=91\n"),
    { kind: "wifi", name: "wlan0", address: "192.168.0.174/24", wifiOn: true, ssid: "AN-VA", strength: 91 },
);
assert.deepStrictEqual(
    net("kind=wired\niface=ue0\naddress=10.0.0.2/24\nwifi=up\nssid=Cafe = free\nstrength=40\n"),
    { kind: "wired", name: "ue0", address: "10.0.0.2/24", wifiOn: true, ssid: "Cafe = free", strength: 40 },
);
assert.deepStrictEqual(net("wifi=down\n"), { kind: "", name: "", address: "", wifiOn: false, ssid: "", strength: 0 });
assert.strictEqual(net("").kind, "");

// pactl 17 -f json, one document per line as Sys.qml's reader prints them; field names as pactl prints them
const vol = percent => ({ "front-left": { value: 0, value_percent: `${percent[0]}%`, db: "" }, "front-right": { value: 0, value_percent: `${percent[1]}%`, db: "" } });
const pulseText = [
    { server_name: "pulseaudio", default_sink_name: "oss_output.dsp4", default_source_name: "oss_input.dsp4" },
    [
        { index: 0, name: "oss_output.dsp0", description: "0 - ATI R6xx (HDMI)", mute: false, volume: vol([100, 100]), properties: { "device.icon_name": "audio-card" } },
        { index: 4, name: "oss_output.dsp4", description: "4 - Realtek ALC285 (Internal Analog)", mute: false, volume: vol([50, 40]), properties: { "device.icon_name": "audio-card" } },
    ],
    [
        { index: 5, name: "oss_output.dsp4.monitor", description: "Monitor of 4 - Realtek ALC285 (Internal Analog)", mute: false, volume: vol([100, 100]), properties: { "device.class": "monitor" } },
        { index: 4, name: "oss_input.dsp4", description: "4 - Realtek ALC285 (Internal Analog)", mute: true, volume: vol([32, 32]), properties: {} },
    ],
    [
        { index: 7, driver: "protocol-native.c", sink: 4, mute: false, volume: vol([100, 100]), properties: { "application.name": "qs-probe", "media.name": "/dev/zero" } },
    ],
].map(doc => JSON.stringify(doc)).join("\n") + "\n";
const audio = pulse(pulseText);
assert.deepStrictEqual(
    [audio.sink.kind, audio.sink.id, audio.sink.description, audio.sink.audio, audio.sink.properties["device.icon_name"]],
    ["sink", "oss_output.dsp4", "4 - Realtek ALC285 (Internal Analog)", { volume: 0.45, muted: false }, "audio-card"],
);
assert.deepStrictEqual([audio.source.kind, audio.source.id, audio.source.audio], ["source", "oss_input.dsp4", { volume: 0.32, muted: true }]);
assert.deepStrictEqual(audio.streams.map(s => [s.kind, s.id, s.name, s.description, s.audio.volume]), [["sink-input", "7", "/dev/zero", "qs-probe", 1]]);
// no server: pactl prints nothing, so every line is empty
assert.deepStrictEqual(pulse("\n\n\n\n"), { sink: null, source: null, streams: [] });
assert.deepStrictEqual(pulse(""), { sink: null, source: null, streams: [] });
// a default the lists do not have (a sink being torn down)
assert.strictEqual(pulse(pulseText.replace('"default_sink_name":"oss_output.dsp4"', '"default_sink_name":"gone"')).sink, null);

const apps = [
    { title: "Blender", usage: 0, fields: ["Blender", "3D modeling", ""] },
    { title: "Firefox", usage: 1, fields: ["Firefox", "Web Browser", "browse the web"] },
    { title: "Fire Tool", usage: 9, fields: ["Fire Tool", "", ""] },
    { title: "Web Fire", usage: 0, fields: ["Web Fire", "", ""] },
    { title: "Zen", usage: 5, fields: ["Zen", "Web Browser", ""] },
];
const titles = (query, limit = 10) => rank(apps, query, limit).map(a => a.title);
assert.deepStrictEqual(titles(""), ["Fire Tool", "Zen", "Firefox", "Blender", "Web Fire"]);
assert.deepStrictEqual(titles("fire"), ["Fire Tool", "Firefox", "Web Fire"]);
assert.deepStrictEqual(titles("web browser"), ["Zen", "Firefox"]);
assert.deepStrictEqual(titles("nothing"), []);
assert.deepStrictEqual(titles("", 2), ["Fire Tool", "Zen"]);
assert.strictEqual(titles("c++").length, 0);

assert.deepStrictEqual(
    clipboardItems("12\tfirst\twith tab\n\nbroken line\n3\tsecond\n").map(i => [i.key, i.title]),
    [["12", "first\twith tab"], ["3", "second"]],
);

const emoji = emojiItems("🦰 red hair <small>(ginger, redhead)</small>\n😀 grinning face\n\n");
assert.deepStrictEqual(emoji.map(e => [e.glyph, e.title, e.detail]), [["🦰", "red hair", "ginger, redhead"], ["😀", "grinning face", ""]]);

const notifySource = fs.readFileSync(path.join(__dirname, "../private_desktop/private_notifications/private_Notify.js"), "utf8");
vm.runInThisContext(notifySource.replace(/^\.pragma.*$/m, ""));

assert.strictEqual(sanitizeBody("plain"), "plain");
assert.strictEqual(sanitizeBody("<b>bold</b> and <I>it</I>"), "<b>bold</b> and <i>it</i>");
assert.strictEqual(sanitizeBody('<img src="file:///etc/passwd" alt="x"/>after'), "after");
assert.strictEqual(sanitizeBody('<a href="http://evil">link</a>'), "link");
assert.strictEqual(sanitizeBody("<script>x</script>"), "&lt;script&gt;x&lt;/script&gt;");
assert.strictEqual(sanitizeBody('<b onclick="x">y</b>'), "&lt;b onclick=&quot;x&quot;&gt;y</b>");
assert.strictEqual(sanitizeBody("1 < 2 & 3 > 2"), "1 &lt; 2 &amp; 3 &gt; 2");
assert.strictEqual(sanitizeBody("a &amp; b &lt;img&gt; &#65; &apos;"), "a &amp; b &lt;img&gt; A '");
assert.strictEqual(sanitizeBody("&#60;img src=x&#62;"), "&lt;img src=x&gt;");
assert.strictEqual(sanitizeBody("one\ntwo<br/>three"), "one<br>two<br>three");
assert.strictEqual(sanitizeBody(""), "");
assert.strictEqual(sanitizeBody(undefined), "");

assert.strictEqual(syncKey({ "x-canonical-private-synchronous": "volume" }), "volume");
assert.strictEqual(syncKey({}), "");

const groups = groupByApp([
    { appName: "Mail", desktopEntry: "", id: 3 },
    { appName: "Chat", desktopEntry: "chat.desktop", id: 2 },
    { appName: "Mail", desktopEntry: "", id: 1 },
]);
assert.deepStrictEqual(groups.map(g => [g.key, g.name, g.items.map(i => i.id)]), [["Mail", "Mail", [3, 1]], ["chat.desktop", "Chat", [2]]]);

assert.strictEqual(ageLabel(30000), "Now");
assert.strictEqual(ageLabel(60000), "1 min ago");
assert.strictEqual(ageLabel(5 * 60000), "5 mins ago");
assert.strictEqual(ageLabel(2 * 3600000), "2 hours ago");
assert.strictEqual(ageLabel(24 * 3600000), "1 day ago");

const durationSource = fs.readFileSync(path.join(__dirname, "../private_desktop/private_notifications/private_Duration.js"), "utf8");
vm.runInThisContext(durationSource.replace(/^\.pragma.*$/m, ""));

assert.strictEqual(parseDuration("5"), 300000);
assert.strictEqual(parseDuration("90"), 5400000);
assert.strictEqual(parseDuration("1:30"), 90000);
assert.strictEqual(parseDuration("0:03"), 3000);
assert.strictEqual(parseDuration("1:00:00"), 3600000);
assert.strictEqual(parseDuration(" 2 "), 120000);
assert.strictEqual(parseDuration(""), 0);
assert.strictEqual(parseDuration("1:75"), 0);
assert.strictEqual(parseDuration("1:2:3:4"), 0);
assert.strictEqual(parseDuration(":"), 0);
assert.strictEqual(parseDuration("abc"), 0);

assert.strictEqual(formatClock(0), "00:00");
assert.strictEqual(formatClock(1), "00:01");
assert.strictEqual(formatClock(90000), "01:30");
assert.strictEqual(formatClock(3661000), "1:01:01");
assert.strictEqual(formatClock(-5), "00:00");

assert.strictEqual(label(300000), "5 min");
assert.strictEqual(label(90000), "1 min 30 s");
assert.strictEqual(label(3600000), "1 h");
assert.strictEqual(label(3000), "3 s");

// November 2026 starts on a Sunday, February 2027 fills exactly four weeks
const november = monthCells(2026, 10);
assert.strictEqual(november.indexOf(1), 6);
assert.strictEqual(november.length, 42);
assert.strictEqual(november[november.indexOf(6) % 7 + 0] !== undefined, true);
assert.strictEqual(november.indexOf(6) % 7, 4);
assert.strictEqual(monthCells(2027, 1).length, 28);

assert.strictEqual(weekNumber(2026, 10, 1), 44);
assert.strictEqual(weekNumber(2026, 10, 2), 45);
assert.strictEqual(weekNumber(2026, 11, 31), 53);
assert.strictEqual(weekNumber(2027, 0, 4), 1);

const todoSource = fs.readFileSync(path.join(__dirname, "../private_desktop/private_notifications/private_Todo.js"), "utf8");
vm.runInThisContext(todoSource.replace(/^\.pragma.*$/m, "").replace(/function pad\(/, "function todoPad("));
vm.runInThisContext(`pad = pad`);

const today = "2026-11-06";
assert.strictEqual(parseDue("", today), "");
assert.strictEqual(parseDue("  ", today), "");
assert.strictEqual(parseDue("24.12", today), "2026-12-24");
assert.strictEqual(parseDue("24.12.", today), "2026-12-24");
assert.strictEqual(parseDue("6.11", today), "2026-11-06");
assert.strictEqual(parseDue("5.11", today), "2027-11-05");
assert.strictEqual(parseDue("1.2.27", today), "2027-02-01");
assert.strictEqual(parseDue("01.02.2028", today), "2028-02-01");
assert.strictEqual(parseDue("2026-12-24", today), "2026-12-24");
assert.strictEqual(parseDue("29.02", today), "2028-02-29");
assert.strictEqual(parseDue("31.04", today), null);
assert.strictEqual(parseDue("29.02.2027", today), null);
assert.strictEqual(parseDue("2026-13-01", today), null);
assert.strictEqual(parseDue("soon", today), null);
assert.strictEqual(parseDue("24", today), null);

assert.strictEqual(addDays("2026-12-31", 1), "2027-01-01");
assert.strictEqual(dueLabel("", today), "");
assert.strictEqual(dueLabel(today, today), "Today");
assert.strictEqual(dueLabel("2026-11-07", today), "Tomorrow");
assert.strictEqual(dueLabel("2026-12-24", today), "24.12");
assert.strictEqual(dueLabel("2027-01-02", today), "02.01.2027");

const todos = [
    { id: 1, text: "undated", due: "", done: false },
    { id: 2, text: "finished", due: "2026-01-01", done: true },
    { id: 3, text: "later", due: "2026-12-24", done: false },
    { id: 4, text: "overdue", due: "2026-11-01", done: false },
    { id: 5, text: "soon", due: "2026-12-24", done: false },
];
assert.deepStrictEqual(sortTodos(todos).map(t => t.id), [4, 3, 5, 1, 2]);
assert.strictEqual(todos[0].id, 1);
assert.deepStrictEqual(dueMarks(todos, today), { "2026-12-24": "open", "2026-11-01": "overdue" });
assert.strictEqual(nextId(todos), 6);
assert.strictEqual(nextId([]), 1);
assert.deepStrictEqual(dueToday(todos, today).map(t => t.id), [4]);
assert.deepStrictEqual(dueToday(todos, "2026-12-24").map(t => t.id), [4, 3, 5]);
assert.strictEqual(reminderBody(dueToday(todos, today), today), "overdue (overdue 01.11)");

const nb = "\u00a0";
const mark = text => `<font color="R">${text}</font>`;
assert.strictEqual(highlight("Zen Browser", "zen", "R"), `${mark("Zen")}${nb}Browser`);
assert.strictEqual(highlight("Zen Browser", "BROW", "R"), `Zen${nb}${mark("Brow")}ser`);
assert.strictEqual(highlight("Zen Browser", "zen brow", "R"), `${mark("Zen")}${nb}${mark("Brow")}ser`);
assert.strictEqual(highlight("banana", "an", "R"), `b${mark("anan")}a`);
assert.strictEqual(highlight("Firefox", "x y", "R"), `Firefo${mark("x")}`);
assert.strictEqual(highlight("Zen", "", "R"), "Zen");
assert.strictEqual(highlight("", "zen", "R"), "");
assert.strictEqual(highlight(undefined, "zen", "R"), "");
// clipboard previews are untrusted: no markup may survive
assert.strictEqual(highlight('<img src="x">&', "", "R"), `&lt;img${nb}src=&quot;x&quot;&gt;&amp;`);
assert.strictEqual(highlight("<b>", "b", "R"), `&lt;${mark("b")}&gt;`);
assert.strictEqual(highlight("a  b\tc", "", "R"), `a${nb}${nb}b${nb}c`);

assert.strictEqual(iconUrl("/tmp/signal/icon.png"), "file:///tmp/signal/icon.png");
assert.strictEqual(iconUrl("file:///tmp/a.png"), "file:///tmp/a.png");
assert.strictEqual(iconUrl("signal-desktop"), "");
assert.strictEqual(iconUrl(""), "");

assert.strictEqual(nmTunnel("Wired connection 3:802-3-ethernet\nvdi-test:wireguard\ntailscale0:tun\n"), "vdi-test");
assert.strictEqual(nmTunnel("office\\:vpn:vpn\n"), "office:vpn");
assert.strictEqual(nmTunnel("tailscale0:tun\nlo:loopback\n"), "");
assert.strictEqual(nmTunnel(""), "");

console.log("parse-check ok");
