// Kimberlite - prueba de Flutter: ventana de cristal iOS 26 + intro.
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

void main() => runApp(const KimberliteApp());

class KimberliteApp extends StatelessWidget {
  const KimberliteApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kimberlite',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'Roboto', useMaterial3: true),
      home: const KimberliteStage(),
    );
  }
}

// ---------- datos de muestra (los mismos que enseña la web) ----------
const instances = [
  ('Supervivencia', '1.21.1 · Fabric'),
  ('Creativo', '1.20.4 · Forge'),
  ('Pruebas con mods', '1.21 · NeoForge'),
];

class KimberliteStage extends StatefulWidget {
  const KimberliteStage({super.key});
  @override
  State<KimberliteStage> createState() => _KimberliteStageState();
}

class _KimberliteStageState extends State<KimberliteStage>
    with TickerProviderStateMixin {
  late final AnimationController intro;
  late final AnimationController drift;
  bool introDone = false;
  bool calm = false;
  // modo oscuro por defecto (pedido por Adrián): cantera de noche, tinta de piedra clara
  bool dark = true;
  Color get ink => dark ? const Color(0xFFEDE9E0) : const Color(0xFF201D18);
  Color get teal => const Color(0xFF0E6071);
  Color get tealSoft => dark ? const Color(0xFF4FA8BD) : const Color(0xFF0E6071);
  Color get glassFill => dark ? Colors.white.withValues(alpha: 0.07) : Colors.white.withValues(alpha: 0.55);
  Color get glassBorder => dark ? Colors.white.withValues(alpha: 0.16) : Colors.white.withValues(alpha: 0.7);
  Color get pillFill => dark ? Colors.white.withValues(alpha: 0.16) : Colors.white.withValues(alpha: 0.85);
  Color get hoverFill => dark ? Colors.white.withValues(alpha: 0.10) : Colors.white.withValues(alpha: 0.5);
  List<Color> get bgColors =>
      dark ? const [Color(0xFF171410), Color(0xFF201C16)] : const [Color(0xFFEDE9E0), Color(0xFFE4DFD3)];
  List<Color> get blobColors => dark
      ? const [Color(0x30C7B49A), Color(0x2A5F97A0), Color(0x24A89A80)]
      : const [Color(0x55D8CDB8), Color(0x4DC7DFE2), Color(0x40E3DCC9)];
  // interfaz viva: parpadeo del puntero y revelado en cascada de cada panel
  final ValueNotifier<Offset> pointer = ValueNotifier(Offset.zero);
  late final AnimationController paneCtrl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 520));
  bool pressing = false;
  int tab = 0;
  int selectedInstance = 0;
  bool showNewHint = false;
  String playStatus = 'Nada en marcha. Pulsa Jugar para ver la secuencia.';
  bool launching = false;
  final List<Timer> _timers = [];

  // fps de la prueba: notificador aislado para no reconstruir la ventana
  final ValueNotifier<double> fps = ValueNotifier(0);
  int frames = 0;
  DateTime windowStart = DateTime.now();

  @override
  void initState() {
    super.initState();
    final q = Uri.base.queryParameters['tab'];
    const order = ['jugar', 'instancias', 'mods', 'ajustes'];
    if (q != null && order.contains(q)) tab = order.indexOf(q);

    intro = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400));
    drift = AnimationController(vsync: this, duration: const Duration(seconds: 14))
      ..repeat(reverse: true);
    if (calm) {
      intro.value = 1;
      introDone = true;
    } else {
      intro.forward().whenComplete(() {
        if (mounted) setState(() => introDone = true);
      });
    }
    if (calm) {
      paneCtrl.value = 1;
    } else {
      paneCtrl.forward();
    }
    SchedulerBinding.instance.addTimingsCallback(_onFrame);
  }

  void _onFrame(List<FrameTiming> timings) {
    frames += timings.length;
    final now = DateTime.now();
    final elapsed = now.difference(windowStart).inMilliseconds;
    if (elapsed >= 1000) {
      fps.value = frames * 1000.0 / elapsed;
      frames = 0;
      windowStart = now;
    }
  }

  @override
  void dispose() {
    intro.dispose();
    drift.dispose();
    paneCtrl.dispose();
    pointer.dispose();
    fps.dispose();
    _cancelTimers();
    SchedulerBinding.instance.removeTimingsCallback(_onFrame);
    super.dispose();
  }

  Duration d(Duration normal) => calm ? Duration.zero : normal;

  void _cancelTimers() {
    for (final t in _timers) {
      t.cancel();
    }
    _timers.clear();
  }

  void replayIntro() {
    _cancelTimers();
    setState(() {
      introDone = false;
      playStatus = 'Nada en marcha. Pulsa Jugar para ver la secuencia.';
      launching = false;
    });
    if (calm) {
      intro.value = 1;
      setState(() => introDone = true);
    } else {
      intro.forward(from: 0).whenComplete(() {
        if (mounted) setState(() => introDone = true);
      });
    }
  }

  void play() {
    _cancelTimers();
    const script = [
      'Comprobando el Java de la instancia…',
      'Java listo. Preparando el arranque…',
      'Lanzando Minecraft con tu perfil…',
      'Esto es una demo visual: el launcher de verdad está en el PC de Adrián.',
    ];
    setState(() {
      launching = true;
      playStatus = script[0];
    });
    for (var i = 1; i < script.length; i++) {
      _timers.add(Timer(calm ? Duration(milliseconds: 120 * i) : Duration(milliseconds: 950 * i), () {
        if (!mounted) return;
        setState(() {
          playStatus = script[i];
          if (i == script.length - 1) launching = false;
        });
      }));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MouseRegion(
        onHover: (e) {
          if (calm) return;
          final s = MediaQuery.of(context).size;
          pointer.value =
              Offset((e.localPosition.dx / s.width) * 2 - 1, (e.localPosition.dy / s.height) * 2 - 1);
        },
        child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: bgColors,
              ),
            ),
          ),
          // manchas de luz mineral que respiran detrás del cristal
          if (!calm)
            RepaintBoundary(
              child: AnimatedBuilder(
                animation: drift,
                builder: (context, _) => Stack(fit: StackFit.expand, children: _blobs()),
              ),
            ),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 660),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: ValueListenableBuilder<Offset>(
                  valueListenable: pointer,
                  builder: (context, pt, child) => Transform.translate(
                      offset: calm ? Offset.zero : Offset(pt.dx * 7, pt.dy * 5), child: child),
                  child: _window(),
                ),
              ),
            ),
          ),
          Positioned(top: 14, right: 16, child: _fpsPill()),
          if (!introDone) _introOverlay(),
        ],
      ),
      ),
    );
  }

  List<Widget> _blobs() {
    final t = drift.value;
    final pt = pointer.value;
    Offset p(double phase) => Offset(
        0.5 + 0.32 * math.sin(2 * math.pi * (t + phase)) + pt.dx * 0.07,
        0.5 + 0.30 * math.cos(2 * math.pi * (t * 0.8 + phase)) + pt.dy * 0.055);
    final a = p(0.0), b = p(0.33), c = p(0.66);
    Widget blob(Offset at, Color color, double size) => Align(
          alignment: Alignment(at.dx * 2 - 1, at.dy * 2 - 1),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
            ),
          ),
        );
    return [
      blob(a, blobColors[0], 380),
      blob(b, blobColors[1], 420),
      blob(c, blobColors[2], 340),
    ];
  }

  Widget _glass({required Widget child, double radius = 26, EdgeInsets? padding}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: glassFill,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: glassBorder),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _wordmark({double size = 15, bool tappable = true}) {
    final w = Text('<KIMBERLITE>',
        style: TextStyle(
            color: ink,
            fontSize: size,
            fontWeight: FontWeight.w700,
            letterSpacing: size * 0.32));
    if (!tappable) return w;
    return Tooltip(
      message: 'Toca para repetir la intro',
      child: InkWell(borderRadius: BorderRadius.circular(8), onTap: replayIntro, child: Padding(padding: const EdgeInsets.all(4), child: w)),
    );
  }

  Widget _window() {
    return AnimatedScale(
      scale: introDone ? 1 : 0.96,
      duration: d(const Duration(milliseconds: 500)),
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: introDone ? 1 : 0,
        duration: d(const Duration(milliseconds: 450)),
        child: _glass(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(children: [
                _wordmark(),
                const Spacer(),
                Text('Launcher',
                    style: TextStyle(color: ink.withValues(alpha: 0.55), fontSize: 13)),
              ]),
              const SizedBox(height: 16),
              _tabBar(),
              const SizedBox(height: 18),
              AnimatedSize(
                duration: d(const Duration(milliseconds: 300)),
                curve: Curves.easeOutCubic,
                child: AnimatedSwitcher(
                  duration: d(const Duration(milliseconds: 260)),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: KeyedSubtree(key: ValueKey(tab), child: _pane()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tabBar() {
    const labels = ['Jugar', 'Instancias', 'Mods', 'Ajustes'];
    // sin blur anidado: ya vive dentro de la ventana de cristal
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: glassFill,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: glassBorder),
      ),
      child: Stack(
        children: [
          // pastilla que se desliza hasta la pestaña activa
          AnimatedAlign(
            alignment: Alignment(-1 + (2 / 3) * tab, 0),
            duration: d(const Duration(milliseconds: 260)),
            curve: Curves.easeOutCubic,
            child: FractionallySizedBox(
              widthFactor: 1 / labels.length,
              child: Container(
                height: 36,
                decoration: BoxDecoration(
                  color: pillFill,
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
            ),
          ),
          Row(
            children: List.generate(labels.length, (i) {
              final active = tab == i;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    setState(() => tab = i);
                    if (calm) {
                      paneCtrl.value = 1;
                    } else {
                      paneCtrl.forward(from: 0);
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    child: Text(labels[i],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: active
                                ? ink
                                : ink.withValues(alpha: 0.6),
                            fontSize: 13.5,
                            fontWeight: active ? FontWeight.w600 : FontWeight.w400)),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _stagger(Widget child, int i) {
    final start = (0.09 * i).clamp(0.0, 0.55);
    return AnimatedBuilder(
      animation: paneCtrl,
      builder: (context, _) {
        final t = Interval(start, 1.0, curve: Curves.easeOutCubic).transform(paneCtrl.value);
        return Opacity(
            opacity: t, child: Transform.translate(offset: Offset(0, (1 - t) * 16), child: child));
      },
    );
  }

  Widget _pane() {
    switch (tab) {
      case 1:
        return _instancesPane();
      case 2:
        return _modsPane();
      case 3:
        return _settingsPane();
      default:
        return _playPane();
    }
  }

  Widget _row(String label, String value, {String? meta, bool strong = false, Widget? trailing, VoidCallback? onTap}) {
    final child = Padding(
      padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 4),
      child: Row(children: [
        Text(label,
            style: TextStyle(
                color: ink.withValues(alpha: 0.72),
                fontSize: 14,
                fontWeight: strong ? FontWeight.w600 : FontWeight.w400)),
        const Spacer(),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(value, style: TextStyle(color: ink, fontSize: 14, fontWeight: FontWeight.w600)),
          if (meta != null)
            Text(meta, style: TextStyle(color: ink.withValues(alpha: 0.5), fontSize: 12)),
        ]),
        if (trailing != null) ...[const SizedBox(width: 8), trailing],
      ]),
    );
    return onTap == null
        ? child
        : InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: onTap,
            hoverColor: hoverFill,
            splashColor: teal.withValues(alpha: 0.12),
            child: child);
  }

  Widget _playPane() {
    final inst = instances[selectedInstance];
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _stagger(_row('Instancia', inst.$1, meta: inst.$2, onTap: () => setState(() => tab = 1)), 0),
      _stagger(Divider(color: ink.withValues(alpha: 0.1), height: 1), 1),
      _stagger(_row('Cuenta', 'Adrián', meta: 'Microsoft · también vale un perfil local'), 2),
      const SizedBox(height: 18),
      _stagger(
          GestureDetector(
            onTapDown: (_) => setState(() => pressing = true),
            onTapUp: (_) => setState(() => pressing = false),
            onTapCancel: () => setState(() => pressing = false),
            child: AnimatedScale(
              scale: pressing ? 0.96 : 1,
              duration: d(const Duration(milliseconds: 110)),
              curve: Curves.easeOutCubic,
              child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: teal,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
              onPressed: play,
              child: Text(launching ? 'Lanzando…' : 'Jugar',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          )),
          3),
      const SizedBox(height: 12),
      _stagger(
          AnimatedSwitcher(
            duration: d(const Duration(milliseconds: 220)),
            child: Text(playStatus,
                key: ValueKey(playStatus),
                style: TextStyle(color: ink.withValues(alpha: 0.55), fontSize: 12.5)),
          ),
          4),
    ]);
  }

  Widget _instancesPane() {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      for (var i = 0; i < instances.length; i++)
        _stagger(
            _row(instances[i].$1, '', meta: instances[i].$2, strong: true,
                trailing: Icon(selectedInstance == i ? Icons.check_circle : Icons.circle_outlined,
                    size: 18,
                    color: selectedInstance == i
                        ? tealSoft
                        : ink.withValues(alpha: 0.25)),
                onTap: () => setState(() {
                      selectedInstance = i;
                      showNewHint = false;
                    })),
            i),
      const SizedBox(height: 14),
      _stagger(OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: ink,
          side: BorderSide(color: ink.withValues(alpha: 0.25)),
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
              onPressed: () => setState(() => showNewHint = true),
              child: const Text('Nueva instancia'),
            ),
            instances.length),
      if (showNewHint)
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Text('En el launcher real, este botón abre el asistente para crear la instancia.',
              style: TextStyle(color: ink.withValues(alpha: 0.55), fontSize: 12.5)),
        ),
    ]);
  }

  Widget _modsPane() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 34),
      child: Column(children: [
        Text('Vacía, por ahora',
            style: TextStyle(color: ink.withValues(alpha: 0.85), fontSize: 15, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text('El catálogo de mods es la siguiente fase del launcher.\nLa pestaña ya está aquí, esperándolo.',
            textAlign: TextAlign.center,
            style: TextStyle(color: ink.withValues(alpha: 0.55), fontSize: 12.5, height: 1.5)),
      ]),
    );
  }

  Widget _settingsPane() {
    return Column(children: [
      _stagger(_row('Modo oscuro', '', strong: true,
          trailing: Switch(
            value: dark,
            activeTrackColor: teal,
            onChanged: (v) => setState(() => dark = v),
          )), 0),
      _stagger(Divider(color: ink.withValues(alpha: 0.1), height: 1), 1),
      _stagger(_row('Carpeta de instancias', '', meta: 'Separada de otros launchers', strong: true), 2),
      _stagger(Divider(color: ink.withValues(alpha: 0.1), height: 1), 3),
      _row('Reducir animaciones', '', strong: true,
          trailing: Switch(
            value: calm,
            activeTrackColor: teal,
            onChanged: (v) => setState(() {
              calm = v;
              if (v) {
                drift.stop();
                paneCtrl.value = 1;
              } else {
                drift.repeat(reverse: true);
                paneCtrl.forward(from: 0);
              }
            }),
          )),
      Divider(color: ink.withValues(alpha: 0.1), height: 1),
      _stagger(_row('Registros', '', meta: 'Los logs, siempre a mano', strong: true), 5),
      const SizedBox(height: 8),
      _stagger(
          Text('Los dos interruptores funcionan: oscuro por defecto, y la ventana se calma si lo pides.',
              style: TextStyle(color: ink.withValues(alpha: 0.55), fontSize: 12.5)),
          6),
    ]);
  }

  Widget _fpsPill() {
    // sin blur: va dentro de la escena, no necesita cristal propio
    return ValueListenableBuilder<double>(
      valueListenable: fps,
      builder: (context, v, _) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: glassFill,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: glassBorder),
        ),
        child: Text('${v.toStringAsFixed(0)} fps · prueba',
            style: TextStyle(color: ink.withValues(alpha: 0.6), fontSize: 11)),
      ),
    );
  }

  // ---------- intro: «<>» se abre hasta «<KIMBERLITE>» ----------
  Widget _introOverlay() {
    return AnimatedBuilder(
      animation: intro,
      builder: (context, _) {
        final t = intro.value;
        final letters = 'KIMBERLITE'.split('');
        final spread = Curves.easeOutCubic.transform(math.min(t / 0.55, 1.0));
        final fadeOut = t > 0.86 ? 1 - (t - 0.86) / 0.14 : 1.0;
        return Opacity(
          opacity: fadeOut,
          child: Container(
            color: bgColors[0],
            child: Center(
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Transform.translate(
                  offset: Offset(-spread * 116, 0),
                  child: Text('<', style: TextStyle(color: tealSoft, fontSize: 44, fontWeight: FontWeight.w700)),
                ),
                ClipRect(
                  child: SizedBox(
                    width: spread * 232,
                    child: OverflowBox(
                      minWidth: 232,
                      maxWidth: 232,
                      alignment: Alignment.center,
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        for (var i = 0; i < letters.length; i++)
                          _letter(letters[i], i),
                      ]),
                    ),
                  ),
                ),
                Transform.translate(
                  offset: Offset(spread * 116, 0),
                  child: Text('>', style: TextStyle(color: tealSoft, fontSize: 44, fontWeight: FontWeight.w700)),
                ),
              ]),
            ),
          ),
        );
      },
    );
  }

  Widget _letter(String ch, int i) {
    final start = 0.30 + i * 0.045;
    final local = ((intro.value - start) / 0.30).clamp(0.0, 1.0);
    final e = Curves.easeOutCubic.transform(local);
    return Opacity(
      opacity: e,
      child: Transform.translate(
        offset: Offset(0, 14 * (1 - e)),
        child: Text(ch,
            style: TextStyle(color: ink, fontSize: 34, fontWeight: FontWeight.w700, letterSpacing: 2)),
      ),
    );
  }
}
