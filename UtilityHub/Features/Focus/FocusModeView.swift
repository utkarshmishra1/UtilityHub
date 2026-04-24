//
//  FocusModeView.swift
//  UtilityHub
//
//  Hosts the focus-mode HTML design in a WKWebView so every visual —
//  conic-gradient orb, hue-rotate background cycle, backdrop blur,
//  bokeh/star particle canvas — renders exactly as designed. A tiny
//  JS↔Swift bridge handles close + focus-completion side effects.
//

import SwiftUI
import SwiftData
import WebKit

struct FocusModeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: ProductivityViewModel

    var body: some View {
        ZStack {
            Color(red: 0.024, green: 0.031, blue: 0.094)
                .ignoresSafeArea()

            FocusWebView(
                html: Self.focusHTML,
                onClose: { dismiss() },
                onFocusComplete: { seconds in
                    viewModel.recordFocusCompletion(durationSeconds: seconds, context: modelContext)
                }
            )
            .ignoresSafeArea()
        }
        .preferredColorScheme(.dark)
        .statusBarHidden()
        .persistentSystemOverlays(.hidden)
    }

    // MARK: - Embedded HTML (verbatim copy of the design mock, with a JS
    // bridge added for close + focus-completion messages)

    private static let focusHTML: String = #"""
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8" />
<meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no, viewport-fit=cover" />
<meta name="theme-color" content="#0a0e27" />
<title>Focus Mode</title>
<style>
  :root{
    --bg-deep:#060818;
    --bg-mid:#12143a;
    --bg-upper:#2a1055;
    --orb-a:#a78bfa;
    --orb-b:#f0abfc;
    --orb-c:#60a5fa;
    --accent:#fbcfe8;
    --text:#f5f3ff;
    --muted:#a5a3c4;
    --glow:rgba(167,139,250,0.55);
  }
  *{box-sizing:border-box;margin:0;padding:0;-webkit-tap-highlight-color:transparent;user-select:none;-webkit-user-select:none;}
  html,body{height:100%;width:100%;overflow:hidden;background:var(--bg-deep);color:var(--text);font-family:-apple-system,BlinkMacSystemFont,"SF Pro Display","Inter",system-ui,sans-serif;}
  body{display:flex;align-items:center;justify-content:center;touch-action:manipulation;}

  /* ================ BACKGROUND ================ */
  #app{
    position:relative;
    width:min(100vw, 480px);
    height:100vh;max-height:100dvh;
    overflow:hidden;
    background:
      radial-gradient(ellipse 120% 80% at 50% 120%, var(--bg-upper) 0%, transparent 60%),
      radial-gradient(ellipse 100% 60% at 50% -10%, var(--bg-mid) 0%, transparent 55%),
      linear-gradient(180deg, #070924 0%, #060818 100%);
    animation:hueShift 90s linear infinite;
    filter:saturate(1.1);
  }
  @keyframes hueShift{
    0%{filter:hue-rotate(0deg) saturate(1.1);}
    100%{filter:hue-rotate(360deg) saturate(1.1);}
  }

  /* Moving aurora blobs */
  .aurora{
    position:absolute;border-radius:50%;
    filter:blur(80px);opacity:.5;pointer-events:none;
    mix-blend-mode:screen;
  }
  .aurora.a1{width:360px;height:360px;background:#5b21b6;top:-100px;left:-80px;animation:drift1 22s ease-in-out infinite;}
  .aurora.a2{width:320px;height:320px;background:#9333ea;bottom:-80px;right:-60px;animation:drift2 28s ease-in-out infinite;}
  .aurora.a3{width:260px;height:260px;background:#2563eb;top:40%;left:-60px;animation:drift3 26s ease-in-out infinite;}
  @keyframes drift1{0%,100%{transform:translate(0,0) scale(1);}50%{transform:translate(60px,80px) scale(1.15);}}
  @keyframes drift2{0%,100%{transform:translate(0,0) scale(1);}50%{transform:translate(-80px,-40px) scale(1.1);}}
  @keyframes drift3{0%,100%{transform:translate(0,0) scale(1);}50%{transform:translate(80px,-60px) scale(1.2);}}

  canvas#particles{
    position:absolute;inset:0;width:100%;height:100%;z-index:1;pointer-events:none;
  }

  /* Subtle grain overlay */
  #grain{
    position:absolute;inset:0;pointer-events:none;z-index:10;opacity:.04;
    background-image:url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='200' height='200'%3E%3Cfilter id='n'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.9' numOctaves='2'/%3E%3Crect width='100%25' height='100%25' filter='url(%23n)'/%3E%3C/svg%3E");
  }

  /* ================ TOP BAR ================ */
  .top{
    position:absolute;top:0;left:0;right:0;z-index:5;
    padding:env(safe-area-inset-top,16px) 20px 0;
    padding-top:max(env(safe-area-inset-top,16px), 20px);
    display:flex;align-items:center;justify-content:space-between;
  }
  .close-btn{
    width:40px;height:40px;border-radius:50%;
    border:1px solid rgba(255,255,255,0.12);
    background:rgba(255,255,255,0.04);
    backdrop-filter:blur(20px);-webkit-backdrop-filter:blur(20px);
    color:var(--text);display:flex;align-items:center;justify-content:center;
    cursor:pointer;font-size:16px;transition:all .2s;
  }
  .close-btn:active{transform:scale(0.93);background:rgba(255,255,255,0.1);}
  .mode-label{
    font-size:11px;letter-spacing:3px;text-transform:uppercase;
    color:var(--muted);font-weight:500;
  }
  .session-dots{display:flex;gap:6px;align-items:center;}
  .dot{width:6px;height:6px;border-radius:50%;background:rgba(255,255,255,0.15);transition:all .3s;}
  .dot.done{background:var(--orb-b);box-shadow:0 0 8px var(--orb-b);}
  .dot.active{background:var(--orb-a);box-shadow:0 0 12px var(--orb-a);width:18px;border-radius:3px;}

  /* ================ CENTER STAGE ================ */
  .stage{
    position:absolute;inset:0;z-index:3;
    display:flex;flex-direction:column;align-items:center;justify-content:center;
    gap:0;
  }
  .orb-wrap{
    position:relative;
    width:320px;height:320px;
    display:flex;align-items:center;justify-content:center;
  }
  @media (max-width:380px){.orb-wrap{width:280px;height:280px;}}

  /* Breathing orb - the hero element */
  .orb{
    position:absolute;inset:40px;
    border-radius:50%;
    background:
      radial-gradient(circle at 35% 35%, rgba(255,255,255,0.9) 0%, rgba(240,171,252,0.4) 20%, transparent 50%),
      conic-gradient(from 0deg, var(--orb-a), var(--orb-b), var(--orb-c), var(--orb-a));
    box-shadow:
      0 0 60px var(--glow),
      0 0 120px rgba(240,171,252,0.3),
      inset 0 0 80px rgba(255,255,255,0.12);
    animation:breathe 10s ease-in-out infinite, spin 30s linear infinite;
    will-change:transform,opacity;
  }
  .orb::before{
    content:"";position:absolute;inset:-2px;border-radius:50%;
    background:conic-gradient(from 180deg, transparent, rgba(255,255,255,0.6), transparent 40%);
    filter:blur(6px);opacity:.6;
    animation:spin 12s linear infinite reverse;
  }
  .orb::after{
    content:"";position:absolute;inset:14%;border-radius:50%;
    background:radial-gradient(circle at 30% 30%, rgba(255,255,255,0.25), transparent 60%);
    mix-blend-mode:overlay;
  }
  @keyframes breathe{
    0%,100%{transform:scale(0.88);filter:blur(0px);}
    50%{transform:scale(1.02);filter:blur(0.5px);}
  }
  @keyframes spin{to{transform:rotate(360deg);}}

  /* Pulse halo rings */
  .halo{
    position:absolute;inset:0;border-radius:50%;
    border:1px solid rgba(240,171,252,0.25);
    animation:pulse 4s ease-out infinite;
    pointer-events:none;
  }
  .halo.h2{animation-delay:1.3s;}
  .halo.h3{animation-delay:2.6s;}
  @keyframes pulse{
    0%{transform:scale(0.7);opacity:0.9;}
    100%{transform:scale(1.25);opacity:0;}
  }

  /* Progress ring SVG */
  .progress-ring{
    position:absolute;inset:0;transform:rotate(-90deg);
    width:100%;height:100%;
    filter:drop-shadow(0 0 8px var(--glow));
  }
  .progress-track{
    fill:none;stroke:rgba(255,255,255,0.08);stroke-width:2;
  }
  .progress-bar{
    fill:none;stroke:url(#progressGrad);stroke-width:3;
    stroke-linecap:round;
    transition:stroke-dashoffset 1s linear;
  }

  /* Timer display */
  .timer-display{
    position:absolute;inset:0;display:flex;flex-direction:column;
    align-items:center;justify-content:center;pointer-events:none;
    z-index:2;
  }
  .time-text{
    font-size:64px;font-weight:200;letter-spacing:-2px;
    color:var(--text);
    text-shadow:0 2px 30px rgba(240,171,252,0.5);
    font-variant-numeric:tabular-nums;
    font-feature-settings:"tnum";
    animation:timePulse 1s ease-in-out infinite;
    transition:opacity .3s;
  }
  @media (max-width:380px){.time-text{font-size:54px;}}
  @keyframes timePulse{
    0%,100%{opacity:1;}
    50%{opacity:0.92;}
  }
  .breath-hint{
    margin-top:6px;font-size:11px;letter-spacing:4px;text-transform:uppercase;
    color:var(--muted);font-weight:500;
    opacity:0.85;transition:opacity .4s;min-height:14px;
  }

  /* ================ BOTTOM CONTROLS ================ */
  .bottom{
    position:absolute;bottom:0;left:0;right:0;z-index:5;
    padding:0 20px max(env(safe-area-inset-bottom,20px), 30px);
    display:flex;flex-direction:column;align-items:center;gap:28px;
  }

  .mode-tabs{
    display:flex;gap:6px;padding:4px;
    background:rgba(255,255,255,0.05);
    border:1px solid rgba(255,255,255,0.08);
    border-radius:14px;backdrop-filter:blur(20px);-webkit-backdrop-filter:blur(20px);
  }
  .mode-tab{
    padding:9px 14px;border-radius:10px;
    font-size:12px;font-weight:500;letter-spacing:0.5px;
    color:var(--muted);cursor:pointer;border:none;background:transparent;
    transition:all .25s;
    font-family:inherit;
  }
  .mode-tab.active{
    background:rgba(255,255,255,0.1);color:var(--text);
    box-shadow:0 2px 20px rgba(167,139,250,0.2);
  }

  .controls{display:flex;gap:20px;align-items:center;}
  .ctrl-btn{
    width:54px;height:54px;border-radius:50%;
    background:rgba(255,255,255,0.06);
    border:1px solid rgba(255,255,255,0.1);
    backdrop-filter:blur(20px);-webkit-backdrop-filter:blur(20px);
    color:var(--text);cursor:pointer;font-size:18px;
    display:flex;align-items:center;justify-content:center;
    transition:all .2s;
  }
  .ctrl-btn:active{transform:scale(0.93);}
  .ctrl-btn svg{width:22px;height:22px;fill:currentColor;}

  .ctrl-btn.primary{
    width:76px;height:76px;font-size:24px;
    background:linear-gradient(135deg, var(--orb-a), var(--orb-b));
    border:none;
    color:#1a0b3d;
    box-shadow:
      0 8px 32px rgba(167,139,250,0.5),
      0 0 60px rgba(240,171,252,0.3),
      inset 0 1px 0 rgba(255,255,255,0.4);
  }
  .ctrl-btn.primary svg{width:30px;height:30px;fill:currentColor;}
  .ctrl-btn.primary:active{transform:scale(0.95);}

  /* ================ COMPLETION OVERLAY ================ */
  .complete-overlay{
    position:absolute;inset:0;z-index:20;
    display:flex;flex-direction:column;align-items:center;justify-content:center;
    background:radial-gradient(ellipse at center, rgba(18,20,58,0.75), rgba(6,8,24,0.95));
    backdrop-filter:blur(12px);-webkit-backdrop-filter:blur(12px);
    opacity:0;pointer-events:none;transition:opacity .6s;
  }
  .complete-overlay.show{opacity:1;pointer-events:auto;}
  .check-burst{
    width:120px;height:120px;border-radius:50%;
    background:linear-gradient(135deg, var(--orb-a), var(--orb-b));
    display:flex;align-items:center;justify-content:center;
    box-shadow:0 0 80px var(--glow);
    margin-bottom:24px;
    animation:checkBurst 1.2s cubic-bezier(0.34,1.56,0.64,1) both;
  }
  @keyframes checkBurst{
    0%{transform:scale(0) rotate(-30deg);opacity:0;}
    60%{transform:scale(1.1);}
    100%{transform:scale(1) rotate(0);opacity:1;}
  }
  .check-burst svg{width:54px;height:54px;fill:#1a0b3d;}
  .complete-title{
    font-size:28px;font-weight:300;letter-spacing:-0.5px;
    margin-bottom:6px;
    animation:fadeUp .8s .3s both;
  }
  .complete-sub{
    font-size:13px;color:var(--muted);letter-spacing:1px;
    margin-bottom:36px;
    animation:fadeUp .8s .5s both;
  }
  .complete-actions{display:flex;gap:12px;animation:fadeUp .8s .7s both;}
  @keyframes fadeUp{
    from{opacity:0;transform:translateY(12px);}
    to{opacity:1;transform:translateY(0);}
  }
  .action-btn{
    padding:14px 24px;border-radius:14px;
    background:rgba(255,255,255,0.08);
    border:1px solid rgba(255,255,255,0.1);
    color:var(--text);cursor:pointer;font-size:13px;letter-spacing:1px;
    font-family:inherit;font-weight:500;
    transition:all .2s;
  }
  .action-btn.primary{
    background:linear-gradient(135deg, var(--orb-a), var(--orb-b));
    color:#1a0b3d;border:none;font-weight:600;
  }
  .action-btn:active{transform:scale(0.96);}

  /* Paused state - dim the orb slightly */
  .stage.paused .orb{animation-play-state:paused;opacity:0.75;}
  .stage.paused .halo{animation-play-state:paused;}
  .stage.paused .breath-hint{opacity:0.4;}

  /* Entry animation when screen opens */
  .stage,.top,.bottom{animation:enter .7s ease-out both;}
  .top{animation-delay:.1s;}
  .bottom{animation-delay:.25s;}
  @keyframes enter{
    from{opacity:0;transform:translateY(10px);}
    to{opacity:1;transform:translateY(0);}
  }
</style>
</head>
<body>
<div id="app">
  <div class="aurora a1"></div>
  <div class="aurora a2"></div>
  <div class="aurora a3"></div>
  <canvas id="particles"></canvas>

  <div class="top">
    <button class="close-btn" id="closeBtn" aria-label="exit focus mode">
      <svg viewBox="0 0 24 24" width="16" height="16" fill="currentColor">
        <path d="M19 6.4L17.6 5 12 10.6 6.4 5 5 6.4 10.6 12 5 17.6 6.4 19 12 13.4 17.6 19 19 17.6 13.4 12z"/>
      </svg>
    </button>
    <div class="mode-label" id="modeLabel">FOCUS</div>
    <div class="session-dots" id="dots">
      <div class="dot active"></div>
      <div class="dot"></div>
      <div class="dot"></div>
      <div class="dot"></div>
    </div>
  </div>

  <div class="stage" id="stage">
    <div class="orb-wrap">
      <div class="halo"></div>
      <div class="halo h2"></div>
      <div class="halo h3"></div>
      <div class="orb"></div>
      <svg class="progress-ring" viewBox="0 0 320 320">
        <defs>
          <linearGradient id="progressGrad" x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" stop-color="#f0abfc"/>
            <stop offset="50%" stop-color="#a78bfa"/>
            <stop offset="100%" stop-color="#60a5fa"/>
          </linearGradient>
        </defs>
        <circle class="progress-track" cx="160" cy="160" r="152"/>
        <circle class="progress-bar" id="progressBar" cx="160" cy="160" r="152"
                stroke-dasharray="954.56" stroke-dashoffset="0"/>
      </svg>
      <div class="timer-display">
        <div class="time-text" id="timeText">25:00</div>
        <div class="breath-hint" id="breathHint">breathe in</div>
      </div>
    </div>
  </div>

  <div class="bottom">
    <div class="mode-tabs">
      <button class="mode-tab active" data-mode="focus" data-min="25">Focus · 25</button>
      <button class="mode-tab" data-mode="short" data-min="5">Short · 5</button>
      <button class="mode-tab" data-mode="long" data-min="15">Long · 15</button>
    </div>
    <div class="controls">
      <button class="ctrl-btn" id="resetBtn" aria-label="reset">
        <svg viewBox="0 0 24 24"><path d="M12 5V2L8 6l4 4V7c3.31 0 6 2.69 6 6s-2.69 6-6 6-6-2.69-6-6H4c0 4.42 3.58 8 8 8s8-3.58 8-8-3.58-8-8-8z"/></svg>
      </button>
      <button class="ctrl-btn primary" id="playBtn" aria-label="play pause">
        <svg id="playIcon" viewBox="0 0 24 24"><path d="M8 5v14l11-7z"/></svg>
      </button>
      <button class="ctrl-btn" id="skipBtn" aria-label="skip">
        <svg viewBox="0 0 24 24"><path d="M6 18l8.5-6L6 6v12zM16 6v12h2V6h-2z"/></svg>
      </button>
    </div>
  </div>

  <div class="complete-overlay" id="completeOverlay">
    <div class="check-burst">
      <svg viewBox="0 0 24 24"><path d="M9 16.17L4.83 12l-1.42 1.41L9 19 21 7l-1.41-1.41z"/></svg>
    </div>
    <div class="complete-title" id="completeTitle">Session Complete</div>
    <div class="complete-sub" id="completeSub">You focused for 25 minutes</div>
    <div class="complete-actions">
      <button class="action-btn" id="dismissBtn">Done</button>
      <button class="action-btn primary" id="nextBtn">Start Break</button>
    </div>
  </div>

  <div id="grain"></div>
</div>

<script>
(() => {
  // ============= NATIVE BRIDGE =============
  function sendToApp(type, data){
    try {
      if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.focusBridge) {
        var payload = Object.assign({type: type}, data || {});
        window.webkit.messageHandlers.focusBridge.postMessage(payload);
      }
    } catch(e){ /* no-op */ }
  }

  // ============= PARTICLES (ambient floating motes) =============
  const canvas = document.getElementById('particles');
  const ctx = canvas.getContext('2d');
  const app = document.getElementById('app');
  let W=0,H=0, DPR = Math.min(window.devicePixelRatio||1, 2);

  function resize(){
    const r = app.getBoundingClientRect();
    W = r.width; H = r.height;
    canvas.width = W*DPR; canvas.height = H*DPR;
    canvas.style.width = W+'px'; canvas.style.height = H+'px';
    ctx.setTransform(DPR,0,0,DPR,0,0);
  }
  resize(); window.addEventListener('resize', resize);

  // Tiered particles: soft bokeh + bright stars
  const particles = [];
  function initParticles(){
    particles.length = 0;
    for (let i=0;i<40;i++){
      particles.push({
        x: Math.random()*W,
        y: Math.random()*H,
        r: Math.random()*2.5 + 0.5,
        vy: -(Math.random()*0.3 + 0.1),
        vx: (Math.random()-0.5)*0.15,
        tw: Math.random()*Math.PI*2,
        twSpeed: Math.random()*0.02 + 0.01,
        hue: Math.random()<0.5 ? 280 : 320,
        baseA: Math.random()*0.4 + 0.15,
      });
    }
    // a few bright stars
    for (let i=0;i<18;i++){
      particles.push({
        x: Math.random()*W,
        y: Math.random()*H,
        r: Math.random()*1 + 0.3,
        vy: -(Math.random()*0.08 + 0.02),
        vx: 0,
        tw: Math.random()*Math.PI*2,
        twSpeed: Math.random()*0.04 + 0.02,
        hue: 220,
        baseA: Math.random()*0.6 + 0.3,
        star: true,
      });
    }
  }
  initParticles();

  function drawParticles(){
    ctx.clearRect(0,0,W,H);
    for (const p of particles){
      p.x += p.vx;
      p.y += p.vy;
      p.tw += p.twSpeed;
      if (p.y < -10){ p.y = H+10; p.x = Math.random()*W; }
      if (p.x < -10) p.x = W+10;
      if (p.x > W+10) p.x = -10;

      const a = p.baseA * (0.6 + Math.sin(p.tw)*0.4);
      if (p.star){
        ctx.fillStyle = `hsla(${p.hue}, 100%, 90%, ${a})`;
        ctx.fillRect(p.x, p.y, p.r, p.r);
      } else {
        const g = ctx.createRadialGradient(p.x,p.y,0, p.x,p.y, p.r*6);
        g.addColorStop(0, `hsla(${p.hue}, 80%, 75%, ${a})`);
        g.addColorStop(1, `hsla(${p.hue}, 80%, 75%, 0)`);
        ctx.fillStyle = g;
        ctx.beginPath(); ctx.arc(p.x, p.y, p.r*6, 0, Math.PI*2); ctx.fill();
      }
    }
    requestAnimationFrame(drawParticles);
  }
  drawParticles();

  // ============= TIMER LOGIC =============
  const MODES = {
    focus:   { min: 25, label: 'FOCUS',        next: 'short' },
    short:   { min: 5,  label: 'SHORT BREAK',  next: 'focus' },
    long:    { min: 15, label: 'LONG BREAK',   next: 'focus' },
  };

  let currentMode = 'focus';
  let totalSeconds = MODES.focus.min * 60;
  let remaining = totalSeconds;
  let running = false;
  let tickHandle = null;
  let completedFocusSessions = 0; // 0..4 rotating
  const CYCLE_LENGTH = 4;

  const timeText = document.getElementById('timeText');
  const modeLabel = document.getElementById('modeLabel');
  const progressBar = document.getElementById('progressBar');
  const playBtn = document.getElementById('playBtn');
  const playIcon = document.getElementById('playIcon');
  const stage = document.getElementById('stage');
  const breathHint = document.getElementById('breathHint');
  const dots = document.getElementById('dots');
  const tabs = document.querySelectorAll('.mode-tab');
  const completeOverlay = document.getElementById('completeOverlay');
  const completeTitle = document.getElementById('completeTitle');
  const completeSub = document.getElementById('completeSub');
  const nextBtn = document.getElementById('nextBtn');
  const dismissBtn = document.getElementById('dismissBtn');

  const PATH_LEN = 2 * Math.PI * 152; // r=152
  progressBar.setAttribute('stroke-dasharray', PATH_LEN.toFixed(2));

  const PLAY_SVG = '<path d="M8 5v14l11-7z"/>';
  const PAUSE_SVG = '<path d="M6 5h4v14H6zM14 5h4v14h-4z"/>';

  function fmt(s){
    const m = Math.floor(s/60);
    const r = s%60;
    return `${String(m).padStart(2,'0')}:${String(r).padStart(2,'0')}`;
  }

  function updateDisplay(){
    timeText.textContent = fmt(remaining);
    const progress = 1 - (remaining / totalSeconds);
    progressBar.style.strokeDashoffset = (PATH_LEN * (1 - progress)).toFixed(2);
  }

  function setMode(mode, {autoStart=false}={}){
    currentMode = mode;
    totalSeconds = MODES[mode].min * 60;
    remaining = totalSeconds;
    modeLabel.textContent = MODES[mode].label;
    tabs.forEach(t => t.classList.toggle('active', t.dataset.mode === mode));
    progressBar.style.transition = 'none';
    progressBar.style.strokeDashoffset = '0';
    requestAnimationFrame(()=> progressBar.style.transition = '');
    updateDisplay();
    stopTimer();
    if (autoStart) startTimer();
  }

  function startTimer(){
    if (running) return;
    running = true;
    stage.classList.remove('paused');
    playIcon.innerHTML = PAUSE_SVG;
    tickHandle = setInterval(() => {
      remaining = Math.max(0, remaining - 1);
      updateDisplay();
      updateBreathHint();
      if (remaining === 0) onComplete();
    }, 1000);
  }
  function stopTimer(){
    running = false;
    stage.classList.add('paused');
    playIcon.innerHTML = PLAY_SVG;
    if (tickHandle){ clearInterval(tickHandle); tickHandle = null; }
  }
  function togglePlay(){ running ? stopTimer() : startTimer(); }

  function resetTimer(){
    stopTimer();
    remaining = totalSeconds;
    progressBar.style.transition = 'none';
    updateDisplay();
    requestAnimationFrame(()=> progressBar.style.transition = '');
    breathHint.textContent = 'breathe in';
  }

  function skip(){
    remaining = 0;
    onComplete();
  }

  function updateDots(){
    const els = dots.querySelectorAll('.dot');
    els.forEach((el, i) => {
      el.classList.remove('active','done');
      if (i < completedFocusSessions) el.classList.add('done');
      else if (i === completedFocusSessions && currentMode === 'focus') el.classList.add('active');
    });
  }

  function onComplete(){
    stopTimer();
    const wasFocus = currentMode === 'focus';
    if (wasFocus){
      completedFocusSessions = Math.min(CYCLE_LENGTH, completedFocusSessions + 1);
      sendToApp('focusComplete', { seconds: MODES.focus.min * 60 });
    }
    updateDots();

    completeTitle.textContent = wasFocus ? 'Session Complete' : 'Break Over';
    completeSub.textContent = wasFocus
      ? `You focused for ${MODES[currentMode].min} minutes`
      : 'Ready to focus again?';

    // pick next mode
    let nextMode;
    if (wasFocus){
      nextMode = (completedFocusSessions % CYCLE_LENGTH === 0) ? 'long' : 'short';
    } else {
      nextMode = 'focus';
    }
    nextBtn.textContent = nextMode === 'focus' ? 'Start Focus' : (nextMode === 'long' ? 'Long Break' : 'Start Break');
    nextBtn.dataset.next = nextMode;
    completeOverlay.classList.add('show');
  }

  // Breath hint: syncs with 10s breathe animation (4in / 2hold / 4out)
  const BREATH_CYCLE = 10; // seconds (matches CSS)
  let breathAnchor = performance.now();
  function updateBreathHint(){
    const t = ((performance.now() - breathAnchor) / 1000) % BREATH_CYCLE;
    let label = '';
    if (t < 4) label = 'breathe in';
    else if (t < 6) label = 'hold';
    else label = 'breathe out';
    if (breathHint.textContent !== label){
      breathHint.style.opacity = 0;
      setTimeout(() => { breathHint.textContent = label; breathHint.style.opacity = 0.85; }, 180);
    }
  }

  // ============= EVENTS =============
  playBtn.addEventListener('click', togglePlay);
  document.getElementById('resetBtn').addEventListener('click', resetTimer);
  document.getElementById('skipBtn').addEventListener('click', skip);
  document.getElementById('closeBtn').addEventListener('click', () => {
    stopTimer();
    sendToApp('close');
  });

  tabs.forEach(t => t.addEventListener('click', () => setMode(t.dataset.mode)));

  dismissBtn.addEventListener('click', () => {
    completeOverlay.classList.remove('show');
    resetTimer();
    sendToApp('close');
  });
  nextBtn.addEventListener('click', () => {
    const next = nextBtn.dataset.next || 'focus';
    completeOverlay.classList.remove('show');
    setMode(next, {autoStart:true});
  });

  // Keyboard shortcuts for desktop
  window.addEventListener('keydown', (e) => {
    if (e.code === 'Space'){ e.preventDefault(); togglePlay(); }
    if (e.code === 'KeyR') resetTimer();
    if (e.code === 'KeyS') skip();
  });

  // init
  updateDisplay();
  updateDots();
})();
</script>
</body>
</html>
"""#
}

// MARK: - WebView host

private struct FocusWebView: UIViewRepresentable {
    let html: String
    let onClose: () -> Void
    let onFocusComplete: (Int) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onClose: onClose, onFocusComplete: onFocusComplete)
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        let userContent = WKUserContentController()
        userContent.add(context.coordinator, name: "focusBridge")
        configuration.userContentController = userContent
        configuration.allowsInlineMediaPlayback = true

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.loadHTMLString(html, baseURL: nil)
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {}

    final class Coordinator: NSObject, WKScriptMessageHandler {
        let onClose: () -> Void
        let onFocusComplete: (Int) -> Void

        init(onClose: @escaping () -> Void, onFocusComplete: @escaping (Int) -> Void) {
            self.onClose = onClose
            self.onFocusComplete = onFocusComplete
        }

        func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
            guard message.name == "focusBridge",
                  let body = message.body as? [String: Any],
                  let type = body["type"] as? String else { return }
            switch type {
            case "close":
                onClose()
            case "focusComplete":
                let seconds = (body["seconds"] as? Int) ?? 1500
                onFocusComplete(seconds)
            default:
                break
            }
        }
    }
}
