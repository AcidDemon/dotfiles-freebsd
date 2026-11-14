.pragma library

function iconFor(percent, icons) {
    const step = Math.floor(100 / icons.length);
    return icons[Math.max(0, Math.min(icons.length - 1, Math.floor(percent / step)))];
}

function cpuSamples(stat) {
    return stat.split("\n").filter(line => /^cpu\d*\s/.test(line)).map(line => {
        const fields = line.trim().split(/\s+/);
        const times = fields.slice(1).map(Number);
        return {
            name: fields[0],
            total: times.reduce((sum, value) => sum + value, 0),
            idle: times[3] + (times[4] || 0)
        };
    });
}

function cpuUsage(previous, current) {
    return current.map(sample => {
        const before = previous.find(p => p.name === sample.name);
        const total = before ? sample.total - before.total : 0;
        const busy = total - (before ? sample.idle - before.idle : 0);
        return { name: sample.name, percent: total > 0 ? Math.round(100 * busy / total) : 0 };
    });
}

function cpuTooltip(usage, load) {
    return usage.map(u => u.name === "cpu"
        ? `Total: ${u.percent}%   ·   load ${load.toFixed(2)}`
        : `Core${u.name.slice(3)}: ${u.percent}%`).join("\n");
}

function memInfo(text, arcstats) {
    const kb = key => Number((text.match(new RegExp(`^${key}:\\s+(\\d+)`, "m")) || [])[1] || 0);
    const gib = value => value / 1048576;
    const total = kb("MemTotal");
    // waybar counts ZFS ARC as available
    const arc = Number(((arcstats || "").match(/^size\s+\d+\s+(\d+)/m) || [])[1] || 0) / 1024;
    const avail = kb("MemAvailable") + arc;
    const swapTotal = kb("SwapTotal");
    const swapUsed = swapTotal - kb("SwapFree");
    return {
        totalG: gib(total),
        availG: gib(avail),
        usedG: gib(total - avail),
        pct: total ? Math.floor(100 * (total - avail) / total) : 0,
        swapUsedG: gib(swapUsed),
        swapPct: swapTotal ? Math.floor(100 * swapUsed / swapTotal) : 0
    };
}

function battery(uevent) {
    const value = key => {
        const match = uevent.match(new RegExp(`^POWER_SUPPLY_${key}=(.*)$`, "m"));
        return match ? match[1] : null;
    };
    const status = value("STATUS");
    if (status === null) return null;

    const now = Number(value("ENERGY_NOW") ?? value("CHARGE_NOW") ?? 0);
    const full = Number(value("ENERGY_FULL") ?? value("CHARGE_FULL") ?? 0);
    const rate = Math.abs(Number(value("POWER_NOW") ?? value("CURRENT_NOW") ?? 0));
    const raw = Number(value("CAPACITY") ?? (full ? 100 * now / full : 0));
    // freebsd: no charge limit on this laptop, so no waybar full-at = 95 scaling
    const capacity = Math.min(100, Math.round(raw));

    // waybar shows a battery held at its charge limit as Plugged
    let timeTo = status === "Not charging" ? "Plugged" : status;
    if (rate > 0 && (status === "Charging" || status === "Discharging")) {
        const hours = (status === "Charging" ? full - now : now) / rate;
        const whole = Math.floor(hours);
        const label = status === "Charging" ? "Full in" : "Empty in";
        timeTo = `${label} ${whole} h ${Math.floor((hours - whole) * 60)} min`;
    }
    return { status, capacity, timeTo };
}

function backlight(line) {
    const fields = line.trim().split(",");
    if (fields.length < 4) return null;
    return { device: fields[0], percent: parseInt(fields[3]) };
}

function ipv4(line) {
    const match = line.match(/inet (\S+)/);
    return match ? match[1] : "";
}

// ponytail: parses the waybar scripts' Pango JSON, give them plain output when the waybar module goes
function plainText(markup) {
    return markup.replace(/<[^>]*>/g, "").replace(/^\S+\s*/, "").trim();
}

function temperature(output) {
    if (!output.trim()) return null;
    const data = JSON.parse(output);
    return { cls: data.class, tip: data.tooltip, value: parseInt(plainText(data.text)) };
}

// first active WireGuard or VPN connection in "nmcli -t -f NAME,TYPE connection show --active"
function nmTunnel(output) {
    for (const line of output.split("\n")) {
        const cut = line.lastIndexOf(":");
        if (cut < 0) continue;
        const type = line.slice(cut + 1);
        if (type === "wireguard" || type === "vpn") return line.slice(0, cut).replace(/\\:/g, ":");
    }
    return "";
}

function vpn(output) {
    if (!output.trim()) return null;
    const data = JSON.parse(output);
    const kind = data.class !== "up" ? "down"
        : data.tooltip.startsWith("WireGuard") ? "wireguard"
        : "tailscale";
    return { kind, tip: data.tooltip, label: plainText(data.text) };
}

// freebsd: qs-net's key=value lines stand in for Quickshell.Networking; kind is "" when there is no uplink
function net(output) {
    const value = key => (output.match(new RegExp(`^${key}=(.*)$`, "m")) || [])[1] ?? "";
    return {
        kind: value("kind"),
        name: value("iface"),
        address: value("address"),
        wifiOn: value("wifi") === "up",
        ssid: value("ssid"),
        strength: parseInt(value("strength")) || 0
    };
}

// freebsd: pulseaudio stands in for pipewire. One JSON document per line from pactl -f json
// info, list sinks, list sources and list sink-inputs. Nodes keep the shape the
// Quickshell.Services.Pipewire readers use, plus kind and id for the pactl setters in Sys
function pulse(output) {
    const [info, sinks, sources, inputs] = output.split("\n").map(line => {
        try {
            return JSON.parse(line);
        } catch (e) {
            return null;
        }
    });
    const node = (kind, data) => {
        const channels = Object.values(data.volume ?? {});
        const props = data.properties ?? {};
        return {
            kind,
            // sinks and sources go by name, streams by index
            id: kind === "sink-input" ? String(data.index) : data.name,
            name: data.name ?? props["media.name"] ?? "",
            description: data.description ?? props["application.name"] ?? "",
            properties: props,
            audio: {
                volume: channels.length ? channels.reduce((sum, c) => sum + parseInt(c.value_percent), 0) / channels.length / 100 : 0,
                muted: data.mute === true
            }
        };
    };
    const pick = (list, kind, name) => {
        const data = (list ?? []).find(d => d.name === name);
        return data ? node(kind, data) : null;
    };
    return {
        sink: pick(sinks, "sink", info?.default_sink_name),
        source: pick(sources, "source", info?.default_source_name),
        streams: (inputs ?? []).map(d => node("sink-input", d))
    };
}
