import 'package:flutter/material.dart';

import 'game_screen.dart';
import 'round.dart';
import 'storage.dart';
import 'strings.dart';
import 'widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _best = Storage.best;

  void _play() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const GameScreen()))
        .then((_) {
      if (mounted) setState(() => _best = Storage.best);
    });
  }

  Widget _logoDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final p in palette)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: p.color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: p.color.withAlpha(120), blurRadius: 16),
                    ],
                  ),
                ),
                if (p == palette.first)
                  const Icon(Icons.close_rounded, color: Colors.white, size: 26),
              ],
            ),
          ),
      ],
    );
  }

  Widget _example(String text) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0x14FFFFFF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x22FFFFFF)),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 16, color: Colors.white70),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: SoundButton(),
                  ),
                ),
                const Spacer(flex: 2),
                _logoDots(),
                const SizedBox(height: 22),
                Text(
                  S.appName,
                  style: const TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  S.tagline,
                  style: const TextStyle(fontSize: 20, color: Color(0xFFFFD166)),
                ),
                const SizedBox(height: 36),
                _example(S.ex1),
                _example(S.ex2),
                _example(S.ex3),
                const Spacer(flex: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.emoji_events_rounded,
                        color: Color(0xFFFFD166)),
                    const SizedBox(width: 8),
                    Text(
                      '${S.best}: $_best',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                BigButton(label: S.play, onTap: _play),
                const SizedBox(height: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
