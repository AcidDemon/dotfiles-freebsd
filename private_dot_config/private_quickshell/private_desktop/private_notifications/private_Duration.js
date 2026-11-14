.pragma library

// "90" is minutes, "1:30" is m:ss, "1:00:00" is h:mm:ss; anything else is 0
function parseDuration(text) {
    const value = (text || "").trim();
    if (!/^\d+(:\d{1,2}){0,2}$/.test(value)) return 0;
    const parts = value.split(":").map(Number);
    if (parts.length === 1) return parts[0] * 60000;
    if (parts.slice(1).some(part => part > 59)) return 0;
    const seconds = parts.reduce((total, part) => total * 60 + part, 0);
    return seconds * 1000;
}

function pad(number) {
    return String(number).padStart(2, "0");
}

function formatClock(milliseconds) {
    const total = Math.ceil(Math.max(0, milliseconds) / 1000);
    const hours = Math.floor(total / 3600);
    const minutes = Math.floor(total / 60) % 60;
    const seconds = total % 60;
    return hours > 0 ? `${hours}:${pad(minutes)}:${pad(seconds)}` : `${pad(minutes)}:${pad(seconds)}`;
}

function label(milliseconds) {
    const total = Math.round(milliseconds / 1000);
    const parts = [];
    if (total >= 3600) parts.push(`${Math.floor(total / 3600)} h`);
    if (total % 3600 >= 60) parts.push(`${Math.floor(total / 60) % 60} min`);
    if (total % 60 > 0) parts.push(`${total % 60} s`);
    return parts.join(" ");
}

// grid of a month, Monday first, null for days outside it
function monthCells(year, month) {
    const leading = (new Date(year, month, 1).getDay() + 6) % 7;
    const days = new Date(year, month + 1, 0).getDate();
    const cells = new Array(leading).fill(null);
    for (let day = 1; day <= days; day++) cells.push(day);
    while (cells.length % 7 !== 0) cells.push(null);
    return cells;
}

// ISO 8601 week of a date
function weekNumber(year, month, day) {
    const date = new Date(Date.UTC(year, month, day));
    date.setUTCDate(date.getUTCDate() + 4 - (date.getUTCDay() || 7));
    const start = Date.UTC(date.getUTCFullYear(), 0, 1);
    return Math.ceil(((date.getTime() - start) / 86400000 + 1) / 7);
}
