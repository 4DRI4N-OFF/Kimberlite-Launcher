// Física de muelle para la interfaz de Kimberlite.
// Nada de curvas de CSS ni Curves.*: cada movimiento es un muelle amortiguado
// integrado fotograma a fotograma, así que rebota, se pasa de su sitio y se
// asienta como un objeto de verdad.
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Muelle amortiguado de una dimensión (Euler semi-implícito a subpasos fijos).
class Spring1 {
  double x;
  double v = 0;
  double target;
  Spring1([this.x = 0, this.target = 0]);

  void step(double dt, {required double k, required double zeta}) {
    final c = 2 * zeta * math.sqrt(k);
    var left = dt;
    const h = 1 / 240;
    while (left > 0) {
      final s = left < h ? left : h;
      v += (-k * (x - target) - c * v) * s;
      x += v * s;
      left -= s;
    }
  }

  bool get settled => (x - target).abs() < 0.0005 && v.abs() < 0.01;
  void snap() {
    x = target;
    v = 0;
  }
}

/// Reparte el "golpe" del cambio de modo y sabe si hay que calmar todo.
class SpringHub extends ChangeNotifier {
  bool calm = false;
  int tick = 0;
  void kick() {
    tick++;
    notifyListeners();
  }
}

class SpringScope extends InheritedWidget {
  const SpringScope({super.key, required this.hub, required super.child});
  final SpringHub hub;
  static SpringHub? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<SpringScope>()?.hub;
  @override
  bool updateShouldNotify(SpringScope old) => old.hub != hub;
}

/// Envuelve cualquier widget: se aplasta al pulsar (squash), rebota al soltar
/// pasándose de su sitio (stretch) y recibe el golpe en cascada del cambio de modo.
class SpringBox extends StatefulWidget {
  const SpringBox({
    super.key,
    required this.child,
    this.press = 0,
    this.impactOrder = -1,
    this.impactStrength = 1,
    this.wobble = true,
    this.alignment = Alignment.center,
  });
  final Widget child;

  /// Profundidad del aplastamiento al pulsar (0 = no reacciona al toque).
  final double press;

  /// Orden en la cascada del golpe (-1 = no participa). Retraso = orden * 45 ms.
  final int impactOrder;
  final double impactStrength;
  final bool wobble;
  final Alignment alignment;

  @override
  State<SpringBox> createState() => _SpringBoxState();
}

class _SpringBoxState extends State<SpringBox> with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_tick);
  final Spring1 d = Spring1(); // deformación: + aplasta, - estira
  final Spring1 r = Spring1(); // giro en radianes
  double _k = 420, _z = 0.3;
  Duration _last = Duration.zero;
  SpringHub? _hub;
  int _seen = 0;
  Timer? _delay;
  bool _down = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final hub = SpringScope.maybeOf(context);
    if (hub != _hub) {
      _hub?.removeListener(_onHub);
      _hub = hub;
      _seen = hub?.tick ?? 0;
      hub?.addListener(_onHub);
    }
  }

  @override
  void dispose() {
    _hub?.removeListener(_onHub);
    _delay?.cancel();
    _ticker.dispose();
    super.dispose();
  }

  bool get _calm => _hub?.calm ?? false;

  void _wake() {
    if (!_ticker.isActive) {
      _last = Duration.zero;
      _ticker.start();
    }
  }

  void _tick(Duration elapsed) {
    final dt = ((elapsed - _last).inMicroseconds / 1e6).clamp(0.0, 1 / 30);
    _last = elapsed;
    d.step(dt, k: _k, zeta: _z);
    r.step(dt, k: _k, zeta: math.min(_z + 0.1, 0.9));
    if (d.settled && r.settled && !_down) {
      d.snap();
      r.snap();
      _ticker.stop();
    }
    if (mounted) setState(() {});
  }

  void _onHub() {
    final hub = _hub;
    if (hub == null || hub.tick == _seen) return;
    _seen = hub.tick;
    if (widget.impactOrder < 0 || hub.calm) return;
    _delay?.cancel();
    _delay = Timer(Duration(milliseconds: 45 * widget.impactOrder), () {
      if (!mounted) return;
      _k = 300;
      _z = 0.2;
      d.v += 1.7 * widget.impactStrength;
      if (widget.wobble) {
        r.v += 0.30 * widget.impactStrength * (widget.impactOrder.isEven ? 1 : -1);
      }
      _wake();
    });
  }

  void _pointerDown() {
    if (widget.press <= 0 || _calm) return;
    _down = true;
    _k = 900;
    _z = 0.75;
    d.target = widget.press;
    _wake();
  }

  void _pointerUp() {
    if (!_down) return;
    _down = false;
    _k = 360;
    _z = 0.27;
    d.target = 0;
    d.v -= widget.press * 11; // patada hacia arriba: rebota pasándose de su sitio
    _wake();
  }

  @override
  Widget build(BuildContext context) {
    final dx = d.x.clamp(-0.4, 0.4);
    final m = Matrix4.identity()
      ..rotateZ(r.x)
      ..scale(1 + 0.7 * dx, 1 - dx, 1.0);
    Widget child = Transform(transform: m, alignment: widget.alignment, child: widget.child);
    if (widget.press > 0) {
      child = Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) => _pointerDown(),
        onPointerUp: (_) => _pointerUp(),
        onPointerCancel: (_) => _pointerUp(),
        child: child,
      );
    }
    return child;
  }
}

/// Pastilla del control segmentado: se desliza con muelle y se estira con la
/// velocidad, como gelatina.
class SpringPill extends StatefulWidget {
  const SpringPill({
    super.key,
    required this.index,
    required this.count,
    required this.color,
    required this.height,
    required this.radius,
    required this.calm,
  });
  final int index;
  final int count;
  final Color color;
  final double height;
  final double radius;
  final bool calm;

  @override
  State<SpringPill> createState() => _SpringPillState();
}

class _SpringPillState extends State<SpringPill> with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_tick);
  late final Spring1 pos = Spring1(widget.index.toDouble(), widget.index.toDouble());
  Duration _last = Duration.zero;

  @override
  void didUpdateWidget(SpringPill old) {
    super.didUpdateWidget(old);
    pos.target = widget.index.toDouble();
    if (widget.calm) {
      pos.snap();
    } else if (!_ticker.isActive) {
      _last = Duration.zero;
      _ticker.start();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _tick(Duration elapsed) {
    final dt = ((elapsed - _last).inMicroseconds / 1e6).clamp(0.0, 1 / 30);
    _last = elapsed;
    pos.step(dt, k: 330, zeta: 0.46);
    if (pos.settled) {
      pos.snap();
      _ticker.stop();
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: LayoutBuilder(builder: (context, c) {
        final tabW = c.maxWidth / widget.count;
        final stretch = (pos.v.abs() * 0.05).clamp(0.0, 0.8) * tabW;
        final w = tabW + stretch;
        final h = widget.height * (1 - 0.22 * stretch / tabW);
        // el borde delantero se estira hacia donde va
        final left = pos.x * tabW - (pos.v < 0 ? stretch : 0);
        return Stack(children: [
          Positioned(
            left: left,
            top: (c.maxHeight - h) / 2,
            width: w,
            height: h,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: BorderRadius.circular(widget.radius),
              ),
            ),
          ),
        ]);
      }),
    );
  }
}

/// Interruptor sol/luna: la bolita viaja con muelle y se estira como gelatina.
class ThemeToggle extends StatefulWidget {
  const ThemeToggle({
    super.key,
    required this.dark,
    required this.onChanged,
    required this.calm,
    required this.trackColor,
    required this.borderColor,
    required this.knobColor,
    required this.iconColor,
  });
  final bool dark;
  final ValueChanged<bool> onChanged;
  final bool calm;
  final Color trackColor;
  final Color borderColor;
  final Color knobColor;
  final Color iconColor;

  @override
  State<ThemeToggle> createState() => _ThemeToggleState();
}

class _ThemeToggleState extends State<ThemeToggle> with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_tick);
  late final Spring1 pos = Spring1(widget.dark ? 1 : 0, widget.dark ? 1 : 0);
  final Spring1 press = Spring1();
  Duration _last = Duration.zero;

  void _wake() {
    if (!_ticker.isActive) {
      _last = Duration.zero;
      _ticker.start();
    }
  }

  @override
  void didUpdateWidget(ThemeToggle old) {
    super.didUpdateWidget(old);
    pos.target = widget.dark ? 1 : 0;
    if (widget.calm) {
      pos.snap();
    } else {
      _wake();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _tick(Duration elapsed) {
    final dt = ((elapsed - _last).inMicroseconds / 1e6).clamp(0.0, 1 / 30);
    _last = elapsed;
    pos.step(dt, k: 300, zeta: 0.34);
    press.step(dt, k: 700, zeta: 0.5);
    if (pos.settled && press.settled) {
      pos.snap();
      press.snap();
      _ticker.stop();
    }
    if (mounted) setState(() {});
  }

  void _setPress(bool v) {
    if (widget.calm) return;
    press.target = v ? 1 : 0;
    _wake();
  }

  @override
  Widget build(BuildContext context) {
    const trackW = 78.0, trackH = 40.0, pad = 4.0, knob = 32.0;
    final travel = trackW - pad * 2 - knob;
    final stretch = (pos.v.abs() * 3.4).clamp(0.0, 30.0);
    final w = knob + stretch + 7 * press.x;
    final h = (knob - stretch * 0.28 - 3 * press.x).clamp(18.0, 40.0);
    var left = pad + pos.x * travel - (pos.v < 0 ? stretch : 0);
    left = left.clamp(2.0, trackW - 2 - w);
    final isDark = pos.x > 0.5;
    return Semantics(
      button: true,
      label: widget.dark ? 'Cambiar a modo claro' : 'Cambiar a modo oscuro',
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (_) => _setPress(true),
        onPointerUp: (_) => _setPress(false),
        onPointerCancel: (_) => _setPress(false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => widget.onChanged(!widget.dark),
          child: Container(
            width: trackW,
            height: trackH,
            decoration: BoxDecoration(
              color: widget.trackColor,
              borderRadius: BorderRadius.circular(trackH / 2),
              border: Border.all(color: widget.borderColor),
            ),
            child: Stack(children: [
              Positioned(
                left: left,
                top: (trackH - h) / 2 - 1,
                width: w,
                height: h,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: widget.knobColor,
                    borderRadius: BorderRadius.circular(h / 2),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.22),
                          blurRadius: 8,
                          offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Center(
                    child: Transform.rotate(
                      angle: (1 - pos.x) * -0.9,
                      child: Icon(
                        isDark ? Icons.nightlight_round : Icons.wb_sunny_rounded,
                        size: 18,
                        color: isDark ? widget.iconColor : const Color(0xFFD98A12),
                      ),
                    ),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
