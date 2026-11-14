.pragma library

// ring of radius 1; angles positive to the viewer's left

function focal(width, hfovDeg) {
    return width / 2 / Math.tan(hfovDeg * Math.PI / 360);
}

// arc that makes the middle card span `frontFrac` of the width
function frontArc(frontFrac, hfovDeg, back) {
    const target = frontFrac * Math.tan(hfovDeg * Math.PI / 360);
    let lo = 0, hi = Math.PI;
    for (let i = 0; i < 60; i++) {
        const m = (lo + hi) / 2;
        if (Math.sin(m / 2) / (Math.cos(m / 2) + back) < target)
            lo = m;
        else
            hi = m;
    }
    return (lo + hi) / 2;
}

// the flat row's half widths and gaps, laid out as angles
function angles(arc, scales, gap) {
    const t = [0];
    for (let i = 0; i + 1 < scales.length; i++)
        t.push(t[i] + arc * scales[i] / 2 + gap * arc + arc * scales[i + 1] / 2);
    return t;
}

function project(theta, y, ringScale, back, f, cx, cy) {
    const z = ringScale * Math.cos(theta) + back;
    return { x: cx - f * ringScale * Math.sin(theta) / z, y: cy - f * y / z };
}

function bounds(theta, arc, height, yCentre, back, f, cx, cy) {
    let x0 = Infinity, y0 = Infinity, x1 = -Infinity, y1 = -Infinity;
    for (const t of [theta + arc / 2, theta, theta - arc / 2]) {
        for (const y of [yCentre + height / 2, yCentre - height / 2]) {
            const p = project(t, y, 1, back, f, cx, cy);
            x0 = Math.min(x0, p.x); x1 = Math.max(x1, p.x);
            y0 = Math.min(y0, p.y); y1 = Math.max(y1, p.y);
        }
    }
    return { x: x0, y: y0, width: x1 - x0, height: y1 - y0 };
}
