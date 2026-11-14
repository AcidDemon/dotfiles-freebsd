.pragma library

function syncKey(hints) {
    return hints.synchronous || hints["private-synchronous"] || hints["x-canonical-private-synchronous"] || "";
}

// newest first in, newest group first out
function groupByApp(notifications) {
    const groups = [];
    for (const n of notifications) {
        const key = n.desktopEntry || n.appName;
        const group = groups.find(g => g.key === key);
        if (group) group.items.push(n);
        else groups.push({ key, name: n.appName, items: [n] });
    }
    return groups;
}

function ageLabel(milliseconds) {
    const minutes = Math.floor(milliseconds / 60000);
    if (minutes < 1) return "Now";
    if (minutes < 60) return `${minutes} min${minutes === 1 ? "" : "s"} ago`;
    const hours = Math.floor(minutes / 60);
    if (hours < 24) return `${hours} hour${hours === 1 ? "" : "s"} ago`;
    const days = Math.floor(hours / 24);
    return `${days} day${days === 1 ? "" : "s"} ago`;
}

function decodeEntity(entity) {
    const named = { amp: "&", lt: "<", gt: ">", quot: '"', apos: "'" };
    const name = entity.slice(1, -1);
    if (name in named) return named[name];
    const code = name[1] === "x" ? parseInt(name.slice(2), 16) : parseInt(name.slice(1), 10);
    return code >= 0 && code <= 0x10ffff ? String.fromCodePoint(code) : "";
}

function escapeText(text) {
    return text
        .replace(/&(?:amp|lt|gt|quot|apos|#\d+|#x[0-9a-fA-F]+);/g, decodeEntity)
        .replace(/&/g, "&amp;")
        .replace(/</g, "&lt;")
        .replace(/>/g, "&gt;")
        .replace(/"/g, "&quot;")
        .replace(/\n/g, "<br>");
}

// Senders are untrusted and StyledText can load <img>: only plain emphasis survives.
function sanitizeBody(body) {
    const source = body || "";
    const tags = /<[^<>]*>/g;
    let output = "";
    let at = 0;
    let match;
    while ((match = tags.exec(source)) !== null) {
        output += escapeText(source.slice(at, match.index));
        at = match.index + match[0].length;
        const tag = match[0].toLowerCase().replace(/\s+/g, "");
        if (/^<\/?[biu]>$/.test(tag)) output += tag;
        else if (tag === "<br>" || tag === "<br/>") output += "<br>";
        else if (!/^<\/?a\b|^<img\b/.test(match[0].toLowerCase())) output += escapeText(match[0]);
    }
    return output + escapeText(source.slice(at));
}

// app_icon may be a file path or URL; images need a real URL, a bare path resolves against the config dir
function iconUrl(name) {
    if (!name) return "";
    if (name.startsWith("file://")) return name;
    if (name.startsWith("/")) return "file://" + name;
    return "";
}
