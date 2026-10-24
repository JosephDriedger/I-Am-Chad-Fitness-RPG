// Synthesizes the game's two music loops as small 16-bit mono WAV files.
// Original, license-free output, like the sound effects. Run: node tool/gen_music.mjs
//
//   hall_loop.wav    calm and warm, for the guild hall (76 BPM, 8 bars)
//   battle_loop.wav  livelier, for battles and practice duels (138 BPM, 16 bars)
//
// Every note is mixed in "circularly": whatever rings past the end wraps to the
// start, so the file loops with no click and no gap.
import { writeFileSync, mkdirSync } from 'node:fs';

const SR = 16000;
const out = 'assets/audio';
mkdirSync(out, { recursive: true });

let seed = 20261023;
const rnd = () => ((seed = (seed * 1664525 + 1013904223) >>> 0) / 4294967296) * 2 - 1;
const note = (n) => 440 * Math.pow(2, (n - 69) / 12);

/** Adds [from] into [into] starting [at] seconds, wrapping around the end. */
function mix(into, from, at, gain = 1) {
  const n = into.length;
  const start = Math.round(at * SR);
  for (let i = 0; i < from.length; i++) into[(start + i) % n] += from[i] * gain;
}

/** A note with a soft attack and release; [wave] is sine, tri, saw or square. */
function voice(freq, sec, { wave = 'sine', attack = 0.01, release = 0.2, curve = 0 } = {}) {
  const n = Math.floor(sec * SR);
  const b = new Float32Array(n);
  let ph = 0;
  for (let i = 0; i < n; i++) {
    ph += (2 * Math.PI * freq) / SR;
    let s = Math.sin(ph);
    if (wave === 'tri') s = (2 / Math.PI) * Math.asin(Math.sin(ph));
    if (wave === 'saw') s = ((ph / Math.PI) % 2) - 1;
    if (wave === 'square') s = Math.sign(s) * 0.6;
    const t = i / SR;
    const atk = Math.min(1, t / attack);
    const rel = Math.min(1, (sec - t) / release);
    const decay = curve > 0 ? Math.pow(1 - i / n, curve) : 1;
    b[i] = s * atk * rel * decay;
  }
  return b;
}

function kick() {
  const n = Math.floor(0.2 * SR);
  const b = new Float32Array(n);
  let ph = 0;
  for (let i = 0; i < n; i++) {
    const t = i / n;
    ph += (2 * Math.PI * (45 + 110 * Math.pow(1 - t, 3))) / SR;
    b[i] = Math.sin(ph) * Math.pow(1 - t, 2.2);
  }
  return b;
}

function snare() {
  const n = Math.floor(0.16 * SR);
  const b = new Float32Array(n);
  let y = 0;
  for (let i = 0; i < n; i++) {
    y += 0.55 * (rnd() - y);
    b[i] = (y * 1.6 + Math.sin((2 * Math.PI * 190 * i) / SR) * 0.4) * Math.pow(1 - i / n, 2.6);
  }
  return b;
}

function hat(open = false) {
  const n = Math.floor((open ? 0.09 : 0.035) * SR);
  const b = new Float32Array(n);
  let prev = 0;
  for (let i = 0; i < n; i++) {
    const r = rnd();
    b[i] = (r - prev) * 0.7 * Math.pow(1 - i / n, 2.5); // differencing keeps the highs
    prev = r;
  }
  return b;
}

/** A simple echo that also wraps around, so it loops cleanly. */
function echo(buf, sec, feedback, wet) {
  const d = Math.round(sec * SR);
  const n = buf.length;
  const dry = Float32Array.from(buf);
  for (let pass = 0; pass < 4; pass++) {
    const g = wet * Math.pow(feedback, pass);
    for (let i = 0; i < n; i++) buf[(i + d * (pass + 1)) % n] += dry[i] * g;
  }
}

function lowpass(buf, amount) {
  let y = 0;
  for (let i = 0; i < buf.length; i++) {
    y += amount * (buf[i] - y);
    buf[i] = y;
  }
}

function save(name, data, peakTarget = 0.6) {
  let peak = 0;
  for (const v of data) peak = Math.max(peak, Math.abs(v));
  const k = peak > 0 ? peakTarget / peak : 1;
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
  console.log(`${name}.wav  ${(data.length / SR).toFixed(1)} s  ${(pcm.length / 1024).toFixed(0)} KB`);
}

// ---- Guild hall: calm ------------------------------------------------------
{
  const bpm = 76;
  const beat = 60 / bpm;
  const bar = beat * 4;
  const bars = 8;
  const total = bar * bars;
  const buf = new Float32Array(Math.round(total * SR));

  // Cmaj7, Am7, Fmaj7, G6: two bars each.
  const chords = [
    { root: 48, tones: [60, 64, 67, 71] },
    { root: 45, tones: [57, 60, 64, 67] },
    { root: 41, tones: [53, 57, 60, 64] },
    { root: 43, tones: [55, 59, 62, 64] },
  ];
  const pentatonic = [72, 74, 76, 79, 81, 84]; // C D E G A C

  chords.forEach((c, ci) => {
    const at = ci * bar * 2;
    // Pad: slow, soft, overlapping the next chord a little.
    for (const t of c.tones) {
      mix(buf, voice(note(t), bar * 2 + 0.6, { wave: 'tri', attack: 0.7, release: 1.1 }), at, 0.16);
      mix(buf, voice(note(t) * 1.003, bar * 2 + 0.6, { wave: 'sine', attack: 0.9, release: 1.1 }), at, 0.1);
    }
    // Bass: a root on each bar and the fifth on the third beat.
    for (let b = 0; b < 2; b++) {
      mix(buf, voice(note(c.root), beat * 2.2, { attack: 0.02, release: 0.5, curve: 1.2 }), at + b * bar, 0.5);
      mix(buf, voice(note(c.root + 7), beat * 1.6, { attack: 0.02, release: 0.4, curve: 1.2 }), at + b * bar + beat * 2, 0.28);
    }
  });

  // A slow, wandering melody on soft plucks: a note every half beat or so, with rests.
  let pos = 2;
  for (let s = 0; s < bars * 8; s++) {
    const r = rnd();
    if (r > 0.1 && r < 0.55) {
      pos = Math.max(0, Math.min(pentatonic.length - 1, pos + (r > 0.35 ? 1 : -1) * (Math.abs(r) > 0.3 ? 1 : 2)));
      const hold = beat * (r > 0.45 ? 1.4 : 0.8);
      mix(buf, voice(note(pentatonic[pos]), hold, { attack: 0.008, release: 0.15, curve: 2.4 }), s * beat * 0.5, 0.2);
    }
  }
  echo(buf, beat * 0.75, 0.5, 0.35);
  lowpass(buf, 0.55);
  save('hall_loop', buf, 0.55);
}

// ---- Battle: livelier ------------------------------------------------------
{
  const bpm = 138;
  const beat = 60 / bpm;
  const bar = beat * 4;
  const bars = 16;
  const total = bar * bars;
  const buf = new Float32Array(Math.round(total * SR));

  // Am, F, C, G, repeated four times.
  const chords = [
    { root: 45, tones: [57, 60, 64] },
    { root: 41, tones: [53, 57, 60] },
    { root: 48, tones: [55, 60, 64] },
    { root: 43, tones: [55, 59, 62] },
  ];

  for (let b = 0; b < bars; b++) {
    const c = chords[b % 4];
    const at = b * bar;
    // Drums: kick on 1 and 3, snare on 2 and 4, hats on the eighths.
    mix(buf, kick(), at, 0.9);
    mix(buf, kick(), at + beat * 2, 0.8);
    if (b % 4 === 3) mix(buf, kick(), at + beat * 3.5, 0.6);
    mix(buf, snare(), at + beat, 0.55);
    mix(buf, snare(), at + beat * 3, 0.55);
    for (let h = 0; h < 8; h++) mix(buf, hat(h === 7), at + h * beat * 0.5, h % 2 ? 0.28 : 0.18);

    // Driving eighth-note bass.
    for (let h = 0; h < 8; h++) {
      const n = h % 4 === 3 ? c.root + 12 : c.root;
      mix(buf, voice(note(n), beat * 0.48, { wave: 'saw', attack: 0.004, release: 0.05, curve: 0.8 }), at + h * beat * 0.5, 0.3);
    }
    // Chord stabs on the off-beats.
    for (const t of c.tones) {
      mix(buf, voice(note(t + 12), beat * 0.4, { wave: 'square', attack: 0.004, release: 0.08, curve: 1.5 }), at + beat * 1.5, 0.07);
      mix(buf, voice(note(t + 12), beat * 0.4, { wave: 'square', attack: 0.004, release: 0.08, curve: 1.5 }), at + beat * 3.5, 0.07);
    }
    // A bright sixteenth-note arpeggio, busier in the second half of each 4 bars.
    const lead = [...c.tones, c.tones[1] + 12];
    for (let s = 0; s < 16; s++) {
      if (b % 4 < 2 && s % 2) continue;
      const n = lead[(s * (b % 2 ? 3 : 1)) % lead.length] + 12;
      mix(buf, voice(note(n), beat * 0.24, { wave: 'tri', attack: 0.003, release: 0.04, curve: 1.6 }), at + s * beat * 0.25, 0.13);
    }
  }
  echo(buf, beat * 0.75, 0.4, 0.18);
  lowpass(buf, 0.7);
  save('battle_loop', buf, 0.55);
}
