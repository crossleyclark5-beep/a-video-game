(() => {
  const canvas = document.getElementById("game");
  const ctx = canvas.getContext("2d");
  const scoreEl = document.getElementById("score");
  const bestEl = document.getElementById("best");
  const overlay = document.getElementById("overlay");
  const overlayTitle = document.getElementById("overlay-title");
  const overlayMsg = document.getElementById("overlay-msg");
  const startBtn = document.getElementById("start-btn");

  const W = canvas.width;
  const H = canvas.height;
  const BEST_KEY = "a-video-game-best";

  let best = Number(localStorage.getItem(BEST_KEY) || 0);
  bestEl.textContent = String(best);

  const state = {
    running: false,
    score: 0,
    time: 0,
    player: { x: W / 2, y: H - 90, r: 16, vx: 0 },
    meteors: [],
    stars: [],
    sparks: [],
    keys: { left: false, right: false },
    pointerX: null,
  };

  function reset() {
    state.score = 0;
    state.time = 0;
    state.player.x = W / 2;
    state.player.vx = 0;
    state.meteors = [];
    state.stars = [];
    state.sparks = [];
    scoreEl.textContent = "0";
  }

  function spawnMeteor() {
    const r = 10 + Math.random() * 16;
    state.meteors.push({
      x: r + Math.random() * (W - r * 2),
      y: -r - 10,
      r,
      vy: 2.2 + Math.random() * 2.4 + state.time * 0.00035,
      spin: Math.random() * Math.PI * 2,
      spinSpeed: (Math.random() - 0.5) * 0.08,
    });
  }

  function spawnStar() {
    state.stars.push({
      x: 18 + Math.random() * (W - 36),
      y: -20,
      r: 8,
      vy: 1.6 + Math.random() * 1.2,
      pulse: Math.random() * Math.PI * 2,
    });
  }

  function burst(x, y, color) {
    for (let i = 0; i < 10; i++) {
      const a = Math.random() * Math.PI * 2;
      const s = 1 + Math.random() * 3;
      state.sparks.push({
        x,
        y,
        vx: Math.cos(a) * s,
        vy: Math.sin(a) * s,
        life: 20 + Math.random() * 18,
        color,
      });
    }
  }

  function hit(a, b) {
    const dx = a.x - b.x;
    const dy = a.y - b.y;
    return dx * dx + dy * dy < (a.r + b.r) * (a.r + b.r);
  }

  function endGame() {
    state.running = false;
    if (state.score > best) {
      best = state.score;
      localStorage.setItem(BEST_KEY, String(best));
      bestEl.textContent = String(best);
      overlayTitle.textContent = "New best!";
      overlayMsg.textContent = `You scored ${state.score}. Share this page with friends.`;
    } else {
      overlayTitle.textContent = "Crash!";
      overlayMsg.textContent = `Score ${state.score}. Best ${best}. Try again.`;
    }
    startBtn.textContent = "Play again";
    overlay.classList.remove("hidden");
  }

  function startGame() {
    reset();
    overlay.classList.add("hidden");
    state.running = true;
  }

  function update(dt) {
    state.time += dt;
    const p = state.player;

    if (state.pointerX != null) {
      const target = state.pointerX;
      p.vx += (target - p.x) * 0.02;
    } else {
      if (state.keys.left) p.vx -= 0.45;
      if (state.keys.right) p.vx += 0.45;
    }

    p.vx *= 0.86;
    p.x += p.vx;
    p.x = Math.max(p.r + 4, Math.min(W - p.r - 4, p.x));

    if (Math.random() < 0.028 + Math.min(0.04, state.time * 0.00002)) spawnMeteor();
    if (Math.random() < 0.012) spawnStar();

    for (const m of state.meteors) {
      m.y += m.vy;
      m.spin += m.spinSpeed;
      if (hit(p, m)) {
        burst(p.x, p.y, "#ff6b6b");
        endGame();
        return;
      }
    }
    state.meteors = state.meteors.filter((m) => m.y < H + 40);

    for (const s of state.stars) {
      s.y += s.vy;
      s.pulse += 0.12;
      if (hit(p, s)) {
        state.score += 5;
        scoreEl.textContent = String(state.score);
        burst(s.x, s.y, "#ffd166");
        s.y = H + 100;
      }
    }
    state.stars = state.stars.filter((s) => s.y < H + 30);

    state.score += dt * 0.01;
    scoreEl.textContent = String(Math.floor(state.score));

    for (const sp of state.sparks) {
      sp.x += sp.vx;
      sp.y += sp.vy;
      sp.life -= 1;
    }
    state.sparks = state.sparks.filter((sp) => sp.life > 0);
  }

  function drawShip(x, y) {
    ctx.save();
    ctx.translate(x, y);
    ctx.fillStyle = "#3dd6c6";
    ctx.beginPath();
    ctx.moveTo(0, -18);
    ctx.lineTo(14, 14);
    ctx.lineTo(0, 8);
    ctx.lineTo(-14, 14);
    ctx.closePath();
    ctx.fill();
    ctx.fillStyle = "#9af0e6";
    ctx.beginPath();
    ctx.arc(0, 0, 4, 0, Math.PI * 2);
    ctx.fill();
    ctx.restore();
  }

  function drawMeteor(m) {
    ctx.save();
    ctx.translate(m.x, m.y);
    ctx.rotate(m.spin);
    ctx.fillStyle = "#7a8499";
    ctx.beginPath();
    ctx.moveTo(m.r, 0);
    for (let i = 1; i < 7; i++) {
      const a = (i / 7) * Math.PI * 2;
      const rr = m.r * (0.75 + ((i % 2) * 0.25));
      ctx.lineTo(Math.cos(a) * rr, Math.sin(a) * rr);
    }
    ctx.closePath();
    ctx.fill();
    ctx.fillStyle = "#5c6578";
    ctx.beginPath();
    ctx.arc(-m.r * 0.2, -m.r * 0.15, m.r * 0.25, 0, Math.PI * 2);
    ctx.fill();
    ctx.restore();
  }

  function drawStar(s) {
    const pulse = 1 + Math.sin(s.pulse) * 0.15;
    ctx.save();
    ctx.translate(s.x, s.y);
    ctx.scale(pulse, pulse);
    ctx.fillStyle = "#ffd166";
    ctx.beginPath();
    for (let i = 0; i < 5; i++) {
      const a = -Math.PI / 2 + (i * Math.PI * 2) / 5;
      const b = a + Math.PI / 5;
      ctx.lineTo(Math.cos(a) * s.r, Math.sin(a) * s.r);
      ctx.lineTo(Math.cos(b) * s.r * 0.45, Math.sin(b) * s.r * 0.45);
    }
    ctx.closePath();
    ctx.fill();
    ctx.restore();
  }

  function drawBg() {
    ctx.clearRect(0, 0, W, H);
    ctx.fillStyle = "rgba(255,255,255,0.35)";
    for (let i = 0; i < 40; i++) {
      const x = (i * 97) % W;
      const y = (i * 53 + state.time * (0.02 + (i % 5) * 0.01)) % H;
      ctx.fillRect(x, y, i % 7 === 0 ? 2 : 1, i % 7 === 0 ? 2 : 1);
    }
  }

  function draw() {
    drawBg();
    for (const s of state.stars) drawStar(s);
    for (const m of state.meteors) drawMeteor(m);
    for (const sp of state.sparks) {
      ctx.globalAlpha = Math.max(0, sp.life / 30);
      ctx.fillStyle = sp.color;
      ctx.beginPath();
      ctx.arc(sp.x, sp.y, 2.2, 0, Math.PI * 2);
      ctx.fill();
      ctx.globalAlpha = 1;
    }
    drawShip(state.player.x, state.player.y);
  }

  let last = performance.now();
  function loop(now) {
    const dt = Math.min(32, now - last);
    last = now;
    if (state.running) update(dt);
    else if (state.sparks.length) {
      for (const sp of state.sparks) {
        sp.x += sp.vx;
        sp.y += sp.vy;
        sp.life -= 1;
      }
      state.sparks = state.sparks.filter((sp) => sp.life > 0);
    }
    draw();
    requestAnimationFrame(loop);
  }
  requestAnimationFrame(loop);

  function setPointerFromEvent(e) {
    const rect = canvas.getBoundingClientRect();
    const clientX = e.touches ? e.touches[0].clientX : e.clientX;
    state.pointerX = ((clientX - rect.left) / rect.width) * W;
  }

  canvas.addEventListener("pointerdown", (e) => {
    canvas.setPointerCapture(e.pointerId);
    setPointerFromEvent(e);
  });
  canvas.addEventListener("pointermove", (e) => {
    if (state.pointerX != null) setPointerFromEvent(e);
  });
  canvas.addEventListener("pointerup", () => {
    state.pointerX = null;
  });
  canvas.addEventListener("pointercancel", () => {
    state.pointerX = null;
  });

  window.addEventListener("keydown", (e) => {
    if (e.key === "ArrowLeft" || e.key === "a") state.keys.left = true;
    if (e.key === "ArrowRight" || e.key === "d") state.keys.right = true;
    if ((e.key === " " || e.key === "Enter") && !state.running) startGame();
  });
  window.addEventListener("keyup", (e) => {
    if (e.key === "ArrowLeft" || e.key === "a") state.keys.left = false;
    if (e.key === "ArrowRight" || e.key === "d") state.keys.right = false;
  });

  startBtn.addEventListener("click", startGame);
  overlay.addEventListener("click", (e) => {
    if (e.target === overlay) startGame();
  });
})();
