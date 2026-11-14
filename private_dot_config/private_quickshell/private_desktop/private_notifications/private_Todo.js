.pragma library

function pad(number) {
    return String(number).padStart(2, "0");
}

// month is zero-based, like Date
function isoDate(year, month, day) {
    return `${year}-${pad(month + 1)}-${pad(day)}`;
}

function toIso(date) {
    return isoDate(date.getFullYear(), date.getMonth(), date.getDate());
}

function addDays(iso, days) {
    const parts = iso.split("-").map(Number);
    return toIso(new Date(parts[0], parts[1] - 1, parts[2] + days));
}

function validDate(year, month, day) {
    const date = new Date(year, month - 1, day);
    return date.getFullYear() === year && date.getMonth() === month - 1 && date.getDate() === day;
}

// "" means no due date, null means unreadable. 24.12 picks the next 24.12 from today on.
function parseDue(text, today) {
    const value = (text || "").trim();
    if (value === "") return "";
    const iso = value.match(/^(\d{4})-(\d{1,2})-(\d{1,2})$/);
    if (iso) {
        const parts = [Number(iso[1]), Number(iso[2]), Number(iso[3])];
        return validDate(parts[0], parts[1], parts[2]) ? isoDate(parts[0], parts[1] - 1, parts[2]) : null;
    }
    const german = value.match(/^(\d{1,2})\.(\d{1,2})\.?(\d{2}|\d{4})?$/);
    if (!german) return null;
    const day = Number(german[1]);
    const month = Number(german[2]);
    if (german[3]) {
        const year = german[3].length === 2 ? 2000 + Number(german[3]) : Number(german[3]);
        return validDate(year, month, day) ? isoDate(year, month - 1, day) : null;
    }
    const thisYear = Number(today.slice(0, 4));
    // 29.02 stays readable in years without one: the next real one is chosen
    for (let year = thisYear; year <= thisYear + 8; year++) {
        if (validDate(year, month, day) && isoDate(year, month - 1, day) >= today) return isoDate(year, month - 1, day);
    }
    return null;
}

function shortDate(iso) {
    const parts = iso.split("-");
    return `${parts[2]}.${parts[1]}`;
}

function dueLabel(iso, today) {
    if (!iso) return "";
    if (iso === today) return "Today";
    if (iso === addDays(today, 1)) return "Tomorrow";
    return iso.slice(0, 4) === today.slice(0, 4) ? shortDate(iso) : `${shortDate(iso)}.${iso.slice(0, 4)}`;
}

// open before done, then by due date with undated last, then oldest first
function sortTodos(items) {
    const order = item => [item.done ? 1 : 0, item.due || "9999-99-99", item.id];
    return items.slice().sort((a, b) => {
        const left = order(a);
        const right = order(b);
        if (left[0] !== right[0]) return left[0] - right[0];
        if (left[1] !== right[1]) return left[1] < right[1] ? -1 : 1;
        return left[2] - right[2];
    });
}

// days with open items; "overdue" wins over "open"
function dueMarks(items, today) {
    const marks = {};
    for (const item of items) {
        if (!item.done && item.due) marks[item.due] = item.due < today ? "overdue" : "open";
    }
    return marks;
}

// open items due today or earlier, overdue first
function dueToday(items, today) {
    return sortTodos(items.filter(item => !item.done && item.due && item.due <= today));
}

function reminderBody(items, today) {
    return items.map(item => item.due < today ? `${item.text} (overdue ${shortDate(item.due)})` : item.text).join("\n");
}

function nextId(items) {
    return items.reduce((highest, item) => Math.max(highest, item.id), 0) + 1;
}
