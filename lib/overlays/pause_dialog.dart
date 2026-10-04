import 'package:flutter/material.dart';
import '../services/progress_service.dart';

class PauseDialog extends StatefulWidget {
  final VoidCallback onResume;
  final VoidCallback onRestart;
  final VoidCallback onExit;

  const PauseDialog({
    super.key,
    required this.onResume,
    required this.onRestart,
    required this.onExit,
  });

  @override
  State<PauseDialog> createState() => _PauseDialogState();
}

class _PauseDialogState extends State<PauseDialog> {
  @override
  Widget build(BuildContext context) {
    final progress = ProgressService.instance;

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        padding: const EdgeInsets.all(26),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B).withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.15),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 25,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.pause_circle_filled_rounded,
              color: Color(0xFF38BDF8),
              size: 52,
            ),
            const SizedBox(height: 10),
            const Text(
              'GAME PAUSED',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 20),

            // Sound Toggle
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              tileColor: Colors.black.withValues(alpha: 0.25),
              leading: Icon(
                progress.soundEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                color: const Color(0xFF38BDF8),
              ),
              title: const Text(
                'Sound & Haptics',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              trailing: Switch(
                value: progress.soundEnabled,
                activeThumbColor: const Color(0xFF38BDF8),
                onChanged: (val) {
                  progress.toggleSound();
                  setState(() {});
                },
              ),
            ),
            const SizedBox(height: 20),

            // Resume Button
            ElevatedButton(
              onPressed: widget.onResume,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.play_arrow_rounded, size: 22),
                  SizedBox(width: 8),
                  Text('RESUME', style: TextStyle(fontWeight: FontWeight.w900)),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Restart Button
            OutlinedButton(
              onPressed: widget.onRestart,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                minimumSize: const Size.fromHeight(44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.replay_rounded, size: 18),
                  SizedBox(width: 8),
                  Text('Restart Level', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Exit Button
            TextButton(
              onPressed: widget.onExit,
              child: const Text(
                'Exit to Menu',
                style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
