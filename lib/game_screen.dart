import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'ads.dart';
import 'round.dart';
import 'sfx.dart';
import 'storage.dart';
import 'strings.dart';
import 'widgets.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with TickerProviderStateMixin {
  final _rng = Random();
  late final AnimationController _timer;
  late final AnimationController _shake;
  late Round _round;

  int _score = 0;
  int _best = Storage.best;
  bool _over = false;
  bool _locked = false; // blocks game-over buttons for a moment (no accidental taps)
  bool _continueUsed = false;
  bool _newBest = false;
  String _reason = '';

  @override
  void initState() {
    super.initState();
    _timer = AnimationController(vsync: this)..addStatusListener(_onStatus);
    _shake = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 420));
    _startRound();
  }

  @override
  void dispose() {
    _timer.dispose();
    _shake.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------- logic

  void _startRound() {
    _round = RoundFactory.next(_score, _rng);
    _timer.duration = _round.limit;
    _timer.forward(from: 0);
  }

  void _onStatus(AnimationStatus s) {
    if (s != AnimationStatus.completed || _over) return;
    if (_round.kind == RoundKind.doNothing) {
      _succeed(); // waiting it out is the correct move
    } else {
      _fail(S.timeUp);
    }
  }

  void _succeed() {
    if (_over) return;
    HapticFeedback.lightImpact();
    Sfx.play('win');
    setState(() {
      _score++;
      _startRound();
    });
  }

  void _fail(String reason) {
    if (_over) return;
    _timer.stop();
    HapticFeedback.heavyImpact();
    Sfx.play('fail');
    _shake.forward(from: 0);
    var nb = false;
    if (_score > _best) {
      _best = _score;
      nb = true;
      Storage.setBest(_best);
      Future.delayed(
          const Duration(milliseconds: 450), () => Sfx.play('record'));
    }
    setState(() {
      _over = true;
      _locked = true;
      _reason = reason;
      _newBest = nb;
    });
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _locked = false);
    });
  }

  void _tapTarget(Target t) {
    if (_over || t.tapped) return;
    if (!t.mustTap) {
      _fail(S.wrongTap);
      return;
    }
    HapticFeedback.selectionClick();
    Sfx.play('tap');
    setState(() => t.tapped = true);
    if (_round.allDone) _succeed();
  }

  void _tapOption(int i) {
    if (_over) return;
    if (i == _round.correctIndex) {
      _fail(S.rightAnswer);
    } else {
      _succeed();
    }
  }

  void _tapSide(bool left) {
    if (_over) return;
    if (left == _round.arrowLeft) {
      _fail(S.sameSide);
    } else {
      _succeed();
    }
  }

  void _tapAnywhere() {
    if (!_over && _round.kind == RoundKind.doNothing) _fail(S.shouldWait);
  }

  void _playAgain() {
    if (_locked) return;
    Ads.maybeShowInterstitial(() {
      if (!mounted) return;
      setState(() {
        _score = 0;
        _over = false;
        _continueUsed = false;
        _newBest = false;
        _startRound();
      });
    });
  }

  void _continue() {
    if (_locked) return;
    Ads.showRewarded(onReward: () {
      if (!mounted) return;
      setState(() {
        _over = false;
        _continueUsed = true;
        _startRound();
      });
    });
  }

  void _home() {
    if (_locked) return;
    Navigator.of(context).pop();
  }

  // ------------------------------------------------------------------- UI

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Stack(
            children: [
              Listener(
                behavior: HitTestBehavior.opaque,
                onPointerDown: (_) => _tapAnywhere(),
                child: AnimatedBuilder(
                  animation: _shake,
                  builder: (context, child) {
                    final dx = sin(_shake.value * pi * 7) * 14 * (1 - _shake.value);
                    return Transform.translate(offset: Offset(dx, 0), child: child);
                  },
                  child: Column(
                    children: [
                      _header(),
                      Expanded(child: _board()),
                    ],
                  ),
                ),
              ),
              if (_over) _gameOver(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Column(
        children: [
          Row(
            children: [
              TweenAnimationBuilder<double>(
                key: ValueKey(_score),
                tween: Tween(begin: 1.45, end: 1.0),
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutBack,
                builder: (context, v, child) =>
                    Transform.scale(scale: v, child: child),
                child: Text(
                  '$_score',
                  style: const TextStyle(
                      fontSize: 44, fontWeight: FontWeight.w900, height: 1),
                ),
              ),
              const Spacer(),
              const Icon(Icons.emoji_events_rounded,
                  color: Color(0xFFFFD166), size: 22),
              const SizedBox(width: 6),
              Text(
                '$_best',
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedBuilder(
            animation: _timer,
            builder: (context, _) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: 1 - _timer.value,
                  minHeight: 10,
                  backgroundColor: const Color(0x22FFFFFF),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Color.lerp(const Color(0xFF5EEAA0), const Color(0xFFFF4D6D),
                        _timer.value)!,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _board() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 12),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(
              _round.prompt,
              key: ValueKey(_round.id),
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 28, fontWeight: FontWeight.w800, height: 1.3),
            ),
          ),
        ),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 160),
            transitionBuilder: (child, anim) => ScaleTransition(
              scale: Tween<double>(begin: 0.85, end: 1.0).animate(anim),
              child: FadeTransition(opacity: anim, child: child),
            ),
            child: KeyedSubtree(
              key: ValueKey(_round.id),
              child: _roundBody(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _roundBody() {
    switch (_round.kind) {
      case RoundKind.avoidColor:
      case RoundKind.avoidBig:
        return _targets();
      case RoundKind.doNothing:
        return const Center(
          child: Icon(Icons.bolt_rounded, size: 130, color: Color(0xFFFFD166)),
        );
      case RoundKind.wrongAnswer:
        return _answers();
      case RoundKind.oppositeArrow:
        return _arrow();
    }
  }

  Widget _targets() {
    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 18,
        runSpacing: 18,
        children: [for (final t in _round.targets) _circle(t)],
      ),
    );
  }

  Widget _circle(Target t) {
    final size = 78.0 * t.scale;
    final c = t.gc.color;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _tapTarget(t),
      child: AnimatedScale(
        scale: t.tapped ? 0 : 1,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeIn,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              center: const Alignment(-0.3, -0.4),
              colors: [Color.lerp(c, Colors.white, 0.35)!, c],
            ),
            boxShadow: [BoxShadow(color: c.withAlpha(120), blurRadius: 22)],
          ),
        ),
      ),
    );
  }

  Widget _answers() {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _round.question,
            style: const TextStyle(fontSize: 56, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 36),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < _round.options.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 7),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapDown: (_) => _tapOption(i),
                    child: Container(
                      width: 92,
                      height: 92,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0x1AFFFFFF),
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(
                            color: const Color(0x44FFFFFF), width: 2),
                      ),
                      child: Text(
                        '${_round.options[i]}',
                        style: const TextStyle(
                            fontSize: 34, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _arrow() {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: Icon(
                _round.arrowLeft
                    ? Icons.arrow_back_rounded
                    : Icons.arrow_forward_rounded,
                size: 130,
                color: const Color(0xFF4CC9F0),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Row(
              children: [
                Expanded(child: _sideButton(true)),
                const SizedBox(width: 16),
                Expanded(child: _sideButton(false)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sideButton(bool left) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _tapSide(left),
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          color: const Color(0x1AFFFFFF),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: const Color(0x33FFFFFF), width: 2),
        ),
        child: Icon(
          left ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
          size: 72,
          color: Colors.white54,
        ),
      ),
    );
  }

  Widget _gameOver() {
    return Positioned.fill(
      child: Container(
        color: const Color(0xCC0B0A1F),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(24),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.85, end: 1.0),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutBack,
          builder: (context, v, child) =>
              Transform.scale(scale: v, child: child),
          child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF211F4A),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: const Color(0x33FFFFFF)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                S.gameOver,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFFF4D6D),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _reason,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.white70),
              ),
              const SizedBox(height: 18),
              Text(
                '$_score',
                style: const TextStyle(
                    fontSize: 72, fontWeight: FontWeight.w900, height: 1),
              ),
              const SizedBox(height: 6),
              if (_newBest)
                Text(
                  S.newBest,
                  style: const TextStyle(
                    color: Color(0xFFFFD166),
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                )
              else
                Text(
                  '${S.best}: $_best',
                  style: const TextStyle(color: Colors.white54, fontSize: 16),
                ),
              const SizedBox(height: 22),
              if (!_continueUsed && Ads.rewardedReady) ...[
                BigButton(
                  label: S.cont,
                  onTap: _locked ? null : _continue,
                  color: const Color(0xFF5EEAA0),
                  textColor: const Color(0xFF10221A),
                ),
                const SizedBox(height: 12),
              ],
              BigButton(
                label: S.playAgain,
                onTap: _locked ? null : _playAgain,
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _locked ? null : _home,
                child: Text(
                  S.home,
                  style: const TextStyle(color: Colors.white60, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}
