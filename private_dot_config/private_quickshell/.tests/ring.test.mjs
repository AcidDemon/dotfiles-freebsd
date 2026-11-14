import assert from "node:assert";
import { readFileSync } from "node:fs";

const src = readFileSync(new URL("../private_desktop/private_switcher/private_Ring.js", import.meta.url), "utf8").replace(/^\.pragma library\n/, "");
const R = new Function(src + "; return { focal, frontArc, angles, project, bounds };")();

const W = 5120, H = 1440, f = R.focal(W, 57), a = R.frontArc(0.42, 57, 0.2);

// middle card spans 42 % of the width
const l = R.project(a / 2, 0, 1, 0.2, f, W / 2, H * 0.47), r = R.project(-a / 2, 0, 1, 0.2, f, W / 2, H * 0.47);
assert.ok(Math.abs((r.x - l.x) - 0.42 * W) < 0.5);

// straight ahead lands on the principal point
assert.deepEqual(R.project(0, 0, 1, 0.2, f, W / 2, H * 0.47), { x: W / 2, y: H * 0.47 });

// today's wallX ratios survive as angles
const t = R.angles(a, [1, 0.5, 0.36, 0.3], 0.05);
[0, 0.8, 1.28, 1.66].forEach((k, i) => assert.ok(Math.abs(t[i] - k * a) < 1e-9));

// the card's outer edge is taller than its middle (edges come towards the viewer)
const h = a / (W / H);
const mid = R.project(0, h / 2, 1, 0.2, f, W / 2, H * 0.47).y, edge = R.project(a / 2, h / 2, 1, 0.2, f, W / 2, H * 0.47).y;
assert.ok(edge < mid);

// bounds of the middle card: centred, 42 % wide
const b = R.bounds(0, a, h, 0, 0.2, f, W / 2, H * 0.47);
assert.ok(Math.abs(b.x + b.width / 2 - W / 2) < 0.5 && Math.abs(b.width - 0.42 * W) < 0.5);
