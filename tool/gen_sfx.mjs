// Synthesizes the game's sound effects as small 16-bit mono WAV files.
// Original, license-free output. Run: node tool/gen_sfx.mjs
import { writeFileSync, mkdirSync } from 'node:fs';

const SR = 22050;
const out = 'assets/audio';
mkdirSync(out, { recursive: true });

const buf = (sec) => new Float32Array(Math.max(1, Math.floor(sec * SR)));
let seed = 12345;
const rnd = () => ((seed = (seed * 1664525 + 1013904223) >>> 0) / 4294967296) * 2 - 1;

function mix(into, from, at = 0, gain = 1) {
  const start = Math.floor(at * SR);
  for (let i = 0; i < from.length && start + i < into.length; i++) into[start + i] += from[i] * gain;
}

const env = (i, n, a = 0.005, curve = 3) => {
  const t = i / n;
  const atk = Math.min(1, i / (a * SR));
  return atk * Math.pow(1 - t, curve);
};

function tone(freq, sec, { wave = 'sine', curve = 3, vib = 0 } = {}) {
  const b = buf(sec);
  let ph = 0;
  for (let i = 0; i < b.length; i++) {
    const f = freq * (1 + vib * Math.sin((i / SR) * 40));
    ph += (2 * Math.PI * f) / SR;
    let s = Math.sin(ph);
    if (wave === 'square') s = Math.sign(s) * 0.5;
    if (wave === 'tri') s = (2 / Math.PI) * Math.asin(Math.sin(ph));
    if (wave === 'saw') s = ((ph / Math.PI) % 2) - 1;
    b[i] = s * env(i, b.length, 0.004, curve);
  }
  return b;
}

function sweep(f0, f1, sec, { wave = 'sine', curve = 2 } = {}) {
  const b = buf(sec);
  let ph = 0;
  for (let i = 0; i < b.length; i++) {
    const t = i / b.length;
    ph += (2 * Math.PI * (f0 + (f1 - f0) * t)) / SR;
    let s = Math.sin(ph);
    if (wave === 'tri') s = (2 / Math.PI) * Math.asin(Math.sin(ph));
    if (wave === 'saw') s = ((ph / Math.PI) % 2) - 1;
    b[i] = s * env(i, b.length, 0.01, curve);
  }
  return b;
}

function noise(sec, { lp = 0.25, curve = 3 } = {}) {
  const b = buf(sec);
  let y = 0;
  for (let i = 0; i < b.length; i++) {
    y += lp * (rnd() - y);
    b[i] = y * env(i, b.length, 0.002, curve) * 2.2;
  }
  return b;
}

function whooshNoise(sec) {
  const b = buf(sec);
  let y = 0;
  for (let i = 0; i < b.length; i++) {
    const t = i / b.length;
    const lp = 0.04 + 0.4 * Math.sin(Math.PI * t);
    y += lp * (rnd() - y);
    b[i] = y * Math.sin(Math.PI * t) * 2.4;
  }
  return b;
}

function save(name, data, gain = 0.8) {
  let peak = 0;
  for (const v of data) peak = Math.max(peak, Math.abs(v));
  const k = peak > 0 ? gain / peak : 1;
  const pcm = Buffer.alloc(data.length * 2);
  for (let i = 0; i < data.length; i++) {
    pcm.writeInt16LE(Math.max(-32767, Math.min(32767, Math.round(data[i] * k * 32767))), i * 2);
  }
  const h = Buffer.alloc(44);
  h.write('RIFF', 0); h.writeUInt32LE(36 + pcm.length, 4); h.write('WAVE', 8);
  h.write('fmt ', 12); h.writeUInt32LE(16, 16); h.writeUInt16LE(1, 20); h.writeUInt16LE(1, 22);
  h.writeUInt32LE(SR, 24); h.writeUInt32LE(SR * 2, 28); h.writeUInt16LE(2, 32); h.writeUInt16LE(16, 34);
  h.write('data', 36); h.writeUInt32LE(pcm.length, 40);
  writeFileSync(`${out}/${name}.wav`, Buffer.concat([h, pcm]));
}

const note = (n) => 440 * Math.pow(2, (n - 69) / 12);
const arp = (notes, step, len, wave = 'tri') => {
  const b = buf(notes.length * step + len);
  notes.forEach((n, i) => mix(b, tone(note(n), len, { wave, curve: 2.2 }), i * step));
  return b;
};

save('tap', tone(880, 0.07, { curve: 4 }), 0.5);

{ const b = buf(0.22); mix(b, noise(0.18, { lp: 0.3 }), 0, 1); mix(b, sweep(180, 70, 0.16, { curve: 3 }), 0, 1.1); save('hit', b); }
{ const b = buf(0.4); mix(b, sweep(260, 1300, 0.28, { wave: 'saw', curve: 1.5 }), 0, 0.5); mix(b, noise(0.2, { lp: 0.35 }), 0.2, 0.9); mix(b, sweep(200, 60, 0.2), 0.2, 1); save('skill', b); }
{ const b = buf(0.3); mix(b, tone(1240, 0.28, { curve: 5 }), 0, 0.6); mix(b, tone(1870, 0.2, { curve: 6 }), 0, 0.4); mix(b, noise(0.04, { lp: 0.6 }), 0, 0.6); save('guard', b); }
save('heal', arp([72, 76, 79, 84], 0.07, 0.25), 0.6);
{ const b = buf(0.3); mix(b, tone(1318, 0.09, { wave: 'square', curve: 2 }), 0, 0.5); mix(b, tone(1975, 0.2, { wave: 'square', curve: 3 }), 0.07, 0.5); save('coin', b, 0.55); }
{ const b = arp([72, 76, 79, 84, 88, 91], 0.09, 0.3); const chord = buf(0.7); [72, 76, 79, 84].forEach((n) => mix(chord, tone(note(n), 0.7, { wave: 'tri', curve: 1.6 }), 0, 0.5)); const out2 = buf(1.3); mix(out2, b, 0); mix(out2, chord, 0.55); save('levelUp', out2, 0.7); }
save('victory', arp([67, 72, 76, 79], 0.11, 0.35, 'tri'), 0.65);
{ const b = sweep(420, 140, 0.7, { wave: 'tri', curve: 1.5 }); save('defeat', b, 0.6); }
save('whoosh', whooshNoise(0.28), 0.5);
{ const b = buf(0.9); mix(b, sweep(180, 340, 0.25, { wave: 'saw', curve: 1 }), 0, 0.35); mix(b, arp([84, 88, 91, 96], 0.07, 0.3), 0.3, 0.7); save('chest', b, 0.65); }
// Workout saved: a warm two-note chime with a little shimmer on top.
{ const b = buf(0.7); mix(b, tone(note(79), 0.5, { curve: 2.4 }), 0, 0.7); mix(b, tone(note(91), 0.4, { curve: 3.5 }), 0, 0.25); mix(b, tone(note(84), 0.55, { curve: 2.2 }), 0.12, 0.8); mix(b, tone(note(96), 0.4, { curve: 3.5 }), 0.12, 0.22); save('saved', b, 0.6); }
// Fanfare for a personal best or a streak reward: a rising run, then a bright held chord.
{ const run = arp([67, 71, 74, 79, 83], 0.075, 0.22); const chord = buf(0.8); [67, 74, 79, 83].forEach((n) => mix(chord, tone(note(n), 0.8, { wave: 'tri', curve: 1.5 }), 0, 0.45)); mix(chord, tone(note(95), 0.6, { curve: 3 }), 0.05, 0.25); const b = buf(1.5); mix(b, run, 0, 0.8); mix(b, chord, 0.37); save('fanfare', b, 0.7); }
// One counted rep: a soft, low tick, quieter and rounder than a tap.
{ const b = buf(0.09); mix(b, tone(520, 0.08, { wave: 'tri', curve: 5 }), 0, 0.8); mix(b, noise(0.012, { lp: 0.5 }), 0, 0.3); save('rep', b, 0.45); }
console.log('wrote sound effects to', out);
