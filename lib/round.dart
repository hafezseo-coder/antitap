import 'dart:math';
import 'package:flutter/material.dart';
import 'strings.dart';

enum RoundKind { avoidColor, avoidBig, doNothing, wrongAnswer, oppositeArrow }

class GameColor {
  final Color color;
  final String ar;
  final String en;
  const GameColor(this.color, this.ar, this.en);
  String get name => S.ar ? ar : en;
}

const palette = <GameColor>[
  GameColor(Color(0xFFFF4D6D), 'الأحمر', 'red'),
  GameColor(Color(0xFF4CC9F0), 'الأزرق', 'blue'),
  GameColor(Color(0xFF5EEAA0), 'الأخضر', 'green'),
  GameColor(Color(0xFFFFD166), 'الأصفر', 'yellow'),
  GameColor(Color(0xFFB388FF), 'البنفسجي', 'purple'),
];

class Target {
  final GameColor gc;
  final double scale;
  final bool mustTap;
  bool tapped = false;
  Target(this.gc, this.scale, this.mustTap);
}

class Round {
  final int id;
  final RoundKind kind;
  final Duration limit;
  final String prompt;
  final List<Target> targets;
  final String question;
  final List<int> options;
  final int correctIndex;
  final bool arrowLeft;

  Round({
    required this.id,
    required this.kind,
    required this.limit,
    required this.prompt,
    this.targets = const [],
    this.question = '',
    this.options = const [],
    this.correctIndex = 0,
    this.arrowLeft = true,
  });

  bool get allDone => targets.where((t) => t.mustTap).every((t) => t.tapped);
}

class RoundFactory {
  static int _id = 0;
  static RoundKind? _prev;

  static Duration _ms(double seconds) =>
      Duration(milliseconds: (seconds * 1000).round());

  /// [score] = rounds cleared so far. Higher score = shorter time, more targets.
  static Round next(int score, Random r) {
    final kinds = <RoundKind>[
      RoundKind.avoidColor,
      RoundKind.avoidBig,
      RoundKind.oppositeArrow,
    ];
    if (score >= 2) kinds.add(RoundKind.wrongAnswer);
    if (score >= 3) kinds.add(RoundKind.doNothing);
    if (_prev != null && kinds.length > 1) kinds.remove(_prev);
    final kind = kinds[r.nextInt(kinds.length)];
    _prev = kind;

    // Base time shrinks with score, never below 1.1 s.
    final base = max(1.1, 3.2 - score * 0.07);

    switch (kind) {
      case RoundKind.avoidColor:
        final bad = palette[r.nextInt(palette.length)];
        final others = palette.where((p) => p != bad).toList();
        final int n = min<int>(6, 3 + score ~/ 6);
        final badCount = n >= 5 ? 2 : 1;
        final ts = <Target>[];
        for (var i = 0; i < n; i++) {
          if (i < badCount) {
            ts.add(Target(bad, 1, false));
          } else {
            ts.add(Target(others[r.nextInt(others.length)], 1, true));
          }
        }
        ts.shuffle(r);
        final taps = n - badCount;
        return Round(
          id: ++_id,
          kind: kind,
          limit: _ms(base * 0.6 + 0.45 * taps),
          prompt: S.avoidColor(bad.name),
          targets: ts,
        );

      case RoundKind.avoidBig:
        final n = 3 + r.nextInt(3);
        final bigIndex = r.nextInt(n);
        final bigScale = score >= 15 ? 1.0 : 1.25;
        final ts = <Target>[];
        for (var i = 0; i < n; i++) {
          final c = palette[r.nextInt(palette.length)];
          ts.add(i == bigIndex
              ? Target(c, bigScale, false)
              : Target(c, 0.75, true));
        }
        return Round(
          id: ++_id,
          kind: kind,
          limit: _ms(base * 0.6 + 0.45 * (n - 1)),
          prompt: S.avoidBig,
          targets: ts,
        );

      case RoundKind.doNothing:
        final prompts = S.doNothing;
        return Round(
          id: ++_id,
          kind: kind,
          limit: _ms(1.0 + base * 0.35),
          prompt: prompts[r.nextInt(prompts.length)],
        );

      case RoundKind.wrongAnswer:
        final int range = 8 + min<int>(score, 12);
        final a = 2 + r.nextInt(range);
        final b = 2 + r.nextInt(range);
        final correct = a + b;
        final opts = <int>{correct};
        while (opts.length < 3) {
          final d = 1 + r.nextInt(4);
          opts.add(r.nextBool() ? correct + d : correct - d);
        }
        final list = opts.toList()..shuffle(r);
        return Round(
          id: ++_id,
          kind: kind,
          limit: _ms(base),
          prompt: S.wrongAnswer,
          question: '$a + $b',
          options: list,
          correctIndex: list.indexOf(correct),
        );

      case RoundKind.oppositeArrow:
        return Round(
          id: ++_id,
          kind: kind,
          limit: _ms(base * 0.75),
          prompt: S.opposite,
          arrowLeft: r.nextBool(),
        );
    }
  }
}
