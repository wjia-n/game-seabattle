import 'package:flutter/material.dart';
import 'package:wajiha_game_core/wajiha_game_core.dart';
import 'game_screen.dart';

void main() => runApp(const SeaBattleApp());

class SeaBattleApp extends StatelessWidget {
  const SeaBattleApp({super.key});
  @override
  Widget build(BuildContext context) {
    return GameShell(
      variant: ShellVariant.neonArcade,
      title: 'Sea Battle',
      tagline: 'Sink the hidden fleet before yours goes down!',
      emoji: '🚢',
      slug: 'seabattle',
      howToPlay: '• Shuffle your fleet until you love it, then start\n• Tap the enemy waters to fire a salvo\n• 💥 = hit, 🌊 = miss — sink all 5 ships to win\n• Watch out: the enemy admiral hunts smart',
      playerOptions: const [1, 2],
      supportsBots: true,
      gameBuilder: (ctx, players, cb) => SeaBattleScreen(players: players, callbacks: cb),
    );
  }
}
