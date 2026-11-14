.pragma library

// The panel outline: straight walls with rounded corners that flare out into a
// screen edge. inset() offsets that outline inward by a fixed distance, so inner
// shapes run parallel to it. Coordinates: 0,0 is the left flare tip's top-left,
// the screen edge is y = g.height. side() is the same shape against the right
// edge: g.width then runs down the screen and g.height is the panel's depth.

function bezier(p, t) {
    const u = 1 - t;
    const x = u * u * u * p[0][0] + 3 * u * u * t * p[1][0] + 3 * u * t * t * p[2][0] + t * t * t * p[3][0];
    const y = u * u * u * p[0][1] + 3 * u * u * t * p[1][1] + 3 * u * t * t * p[2][1] + t * t * t * p[3][1];
    const dx = 3 * u * u * (p[1][0] - p[0][0]) + 6 * u * t * (p[2][0] - p[1][0]) + 3 * t * t * (p[3][0] - p[2][0]);
    const dy = 3 * u * u * (p[1][1] - p[0][1]) + 6 * u * t * (p[2][1] - p[1][1]) + 3 * t * t * (p[3][1] - p[2][1]);
    return [x, y, dx, dy];
}

// left half from the flare tip up to the middle of the top edge
function leftHalf(g, d, top, radius) {
    const wall = g.flare;
    const edge = g.height;
    const curve = [[0, edge], [g.flare * 0.7, edge], [wall, edge - g.flareHeight * 0.4], [wall, edge - g.flareHeight]];
    let points = [];
    for (let i = 0; i <= 64; i++) {
        const [x, y, dx, dy] = bezier(curve, i / 64);
        const n = Math.hypot(dx, dy) || 1;
        // right-hand normal points into the shape
        points.push([x - dy / n * d, y + dx / n * d]);
    }
    if (d > 0) {
        const floor = edge - d;
        for (let i = 0; i < points.length - 1; i++) {
            const [ax, ay] = points[i];
            const [bx, by] = points[i + 1];
            if (ay >= floor && floor > by) {
                const f = (ay - floor) / (ay - by);
                points = [[ax + (bx - ax) * f, floor]].concat(points.slice(i + 1));
                break;
            }
        }
    }
    const cx = wall + d + radius;
    const cy = top + radius;
    for (let i = 0; i <= 12; i++) {
        const a = Math.PI + Math.PI / 2 * i / 12;
        points.push([cx + radius * Math.cos(a), cy + radius * Math.sin(a)]);
    }
    return points;
}

function closed(g, half) {
    const width = 2 * g.flare + g.width;
    const right = half.slice().reverse().map(([x, y]) => [width - x, y]);
    return half.concat(right).concat([half[0]]).map(([x, y]) => Qt.point(x, y));
}

function inset(g, d, top, radius) {
    return closed(g, leftHalf(g, d, top, radius));
}

function side(g, d, top, radius) {
    return inset(g, d, top, radius).map(p => Qt.point(p.y, p.x));
}
