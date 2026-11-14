.pragma library

function fieldScore(token, field, weight) {
    const value = (field || "").toLowerCase();
    const at = value.indexOf(token);
    if (at < 0) return 0;
    if (at === 0) return weight * 4;
    return weight * (/[a-z0-9]/.test(value[at - 1]) ? 2 : 3);
}

// first field counts triple; ties go to usage, then to input order
function rank(items, query, limit) {
    const tokens = query.toLowerCase().split(/\s+/).filter(Boolean);
    const scored = [];
    items.forEach((item, index) => {
        let score = 0;
        for (const token of tokens) {
            const best = Math.max(...item.fields.map((field, i) => fieldScore(token, field, i === 0 ? 3 : 1)));
            if (best === 0) return;
            score += best;
        }
        scored.push({ item, score, index });
    });
    scored.sort((a, b) => b.score - a.score || (b.item.usage || 0) - (a.item.usage || 0) || a.index - b.index);
    return scored.slice(0, limit).map(entry => entry.item);
}

function escapeChar(char) {
    switch (char) {
    case "&": return "&amp;";
    case "<": return "&lt;";
    case ">": return "&gt;";
    case '"': return "&quot;";
    // StyledText collapses plain whitespace
    case " ":
    case "\t": return "\u00a0";
    }
    return char;
}

// StyledText for a result label, typed letters in color; everything else is escaped
function highlight(text, query, color) {
    const source = text || "";
    const lower = source.toLowerCase();
    const marked = new Array(source.length).fill(false);
    // lowercasing can change length (İ), offsets would be wrong
    if (lower.length === source.length) {
        for (const token of query.toLowerCase().split(/\s+/).filter(Boolean)) {
            for (let at = lower.indexOf(token); at >= 0; at = lower.indexOf(token, at + token.length)) {
                marked.fill(true, at, at + token.length);
            }
        }
    }
    let output = "";
    let open = false;
    for (let i = 0; i < source.length; i++) {
        if (marked[i] !== open) {
            output += marked[i] ? `<font color="${color}">` : "</font>";
            open = marked[i];
        }
        output += escapeChar(source[i]);
    }
    return open ? output + "</font>" : output;
}

function clipboardItems(list) {
    return list.split("\n").filter(line => line.includes("\t")).map(line => {
        const tab = line.indexOf("\t");
        const preview = line.slice(tab + 1);
        return { kind: "clip", key: line.slice(0, tab), title: preview, glyph: "\u{F0147}", fields: [preview] };
    });
}

// cliphist lists images as "[[ binary data … ]]"
function clipKind(item) {
    if (item.title.startsWith("[[ binary data")) return "images";
    if (/^\s*(https?:\/\/|www\.)\S+\s*$/.test(item.title)) return "links";
    return "text";
}

function emojiItems(data) {
    const items = [];
    for (const line of data.split("\n")) {
        const match = line.match(/^(\S+) (.*?)(?: <small>\((.*)\)<\/small>)?$/);
        if (match) items.push({ kind: "emoji", key: match[1], glyph: match[1], title: match[2], detail: match[3] || "", fields: [match[2], match[3] || ""] });
    }
    return items;
}
