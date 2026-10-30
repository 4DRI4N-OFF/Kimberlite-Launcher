// Kimberlite website - interactive demo window + scroll reveals.
// Content is visible by default; only below-fold elements are armed for reveal.

(function () {
    'use strict';

    var instances = [
        { name: 'Supervivencia', meta: '1.21.1 · Fabric' },
        { name: 'Creativo', meta: '1.20.4 · Forge' },
        { name: 'Pruebas con mods', meta: '1.21 · NeoForge' }
    ];

    var launchScript = [
        'Comprobando el Java de la instancia…',
        'Java listo. Preparando el arranque…',
        'Lanzando Minecraft con tu perfil…',
        'Esto es una demo visual: el launcher de verdad está en el PC de Adrián.'
    ];

    // ---- wordmark intro: «<>» opens into «<KIMBERLITE>» ----
    var wm = document.getElementById('wm-letters');
    'KIMBERLITE'.split('').forEach(function (ch, i) {
        var s = document.createElement('span');
        s.className = 'kb-letter';
        s.style.animationDelay = (0.4 + i * 0.04) + 's';
        s.textContent = ch;
        wm.appendChild(s);
    });

    // ---- tabs ----
    var tabs = Array.prototype.slice.call(document.querySelectorAll('.kb-tab'));
    var panes = Array.prototype.slice.call(document.querySelectorAll('.kb-pane'));
    var win = document.getElementById('demo-window');

    function showTab(id) {
        tabs.forEach(function (t) {
            var active = t.getAttribute('data-tab') === id;
            t.classList.toggle('is-active', active);
            t.setAttribute('aria-selected', active ? 'true' : 'false');
        });
        panes.forEach(function (p) {
            p.hidden = p.getAttribute('data-pane') !== id;
        });
    }

    tabs.forEach(function (t) {
        t.addEventListener('click', function () { showTab(t.getAttribute('data-tab')); });
    });

    document.querySelector('[data-goto="instancias"]').addEventListener('click', function () {
        showTab('instancias');
    });

    // ---- instance selection ----
    var instButtons = Array.prototype.slice.call(document.querySelectorAll('#inst-list .kb-setrow'));
    var nameEl = document.querySelector('.js-inst-name');
    var metaEl = document.querySelector('.js-inst-meta');
    var hint = document.getElementById('newinst-hint');

    instButtons.forEach(function (btn) {
        btn.addEventListener('click', function () {
            var i = parseInt(btn.getAttribute('data-inst'), 10);
            instButtons.forEach(function (b) {
                var sel = b === btn;
                b.classList.toggle('is-selected', sel);
                b.querySelector('.kb-check').hidden = !sel;
            });
            nameEl.textContent = instances[i].name;
            metaEl.textContent = instances[i].meta;
            hint.hidden = true;
        });
    });

    document.getElementById('newinst-btn').addEventListener('click', function () {
        hint.hidden = false;
    });

    // ---- play sequence ----
    var playBtn = document.getElementById('play-btn');
    var playStatus = document.getElementById('play-status');
    var timers = [];
    var step = -1;

    function clearTimers() {
        timers.forEach(function (t) { window.clearTimeout(t); });
        timers = [];
    }

    playBtn.addEventListener('click', function () {
        clearTimers();
        step = 0;
        playStatus.textContent = launchScript[0];
        playBtn.textContent = 'Lanzando…';
        for (var i = 1; i < launchScript.length; i++) {
            (function (idx) {
                timers.push(window.setTimeout(function () {
                    step = idx;
                    playStatus.textContent = launchScript[idx];
                    if (idx === launchScript.length - 1) playBtn.textContent = 'Jugar';
                }, 950 * idx));
            })(i);
        }
    });

    // ---- reduce-motion switch ----
    var calmSwitch = document.getElementById('calm-switch');
    calmSwitch.addEventListener('click', function () {
        var on = !win.classList.contains('kb-calm');
        win.classList.toggle('kb-calm', on);
        calmSwitch.classList.toggle('is-on', on);
        calmSwitch.setAttribute('aria-checked', on ? 'true' : 'false');
    });

    // ---- deep link ?tab=instancias ----
    var wanted = new URLSearchParams(window.location.search).get('tab');
    if (wanted && document.querySelector('.kb-pane[data-pane="' + wanted + '"]')) showTab(wanted);

    // ---- reveals: visible by default; only below-fold armed ----
    var els = Array.prototype.slice.call(document.querySelectorAll('.kb-reveal'));
    var vh = window.innerHeight || 800;
    var belowFold = [];
    els.forEach(function (el) {
        var top = el.getBoundingClientRect().top;
        if (top > vh * 0.85) { el.classList.add('kb-armed'); belowFold.push(el); }
        else el.classList.add('is-in');
    });
    if ('IntersectionObserver' in window) {
        var io = new IntersectionObserver(function (entries) {
            entries.forEach(function (e) {
                if (e.isIntersecting) { e.target.classList.add('is-in'); io.unobserve(e.target); }
            });
        }, { threshold: 0.12 });
        belowFold.forEach(function (el) { io.observe(el); });
    } else {
        belowFold.forEach(function (el) { el.classList.add('is-in'); });
    }
    window.setTimeout(function () {
        els.forEach(function (el) { el.classList.add('is-in'); });
    }, 2500);
})();
