import 'package:flutter/material.dart';
import '../models/player_profile.dart';
import '../theme/app_theme.dart';

class PlayerProgressCard extends StatelessWidget {
  final PlayerProfile profile;
  final int completedQuestsCount;

  const PlayerProgressCard({
    super.key,
    required this.profile,
    required this.completedQuestsCount,
  });

  @override
  Widget build(BuildContext context) {
    final bool isMonarch = profile.currentRank == 'Monarch';
    final Color rankColor = isMonarch ? AppTheme.goldColor : AppTheme.primaryColor;

    return Container(
      width: 400,
      height: 480,
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F13), // dark template
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: rankColor, width: 3),
        boxShadow: [
          BoxShadow(
            color: rankColor.withOpacity(0.5),
            blurRadius: 40,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background subtle glow
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(21),
                gradient: RadialGradient(
                  colors: [
                    rankColor.withOpacity(0.15),
                    Colors.transparent,
                  ],
                  radius: 0.8,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(Icons.military_tech, size: 64, color: rankColor),
                const SizedBox(height: 16),
                Text(
                  profile.username.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: rankColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: rankColor, width: 1.5),
                  ),
                  child: Text(
                    'RANK ${profile.currentRank}',
                    style: TextStyle(
                      color: rankColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                const Spacer(),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatColumn('TOTAL XP', profile.totalXp.toString(), rankColor),
                    Container(height: 50, width: 1, color: Colors.white24),
                    _buildStatColumn('STREAK', '${profile.streakCount} Days', Colors.orange),
                    Container(height: 50, width: 1, color: Colors.white24),
                    _buildStatColumn('QUESTS', completedQuestsCount.toString(), Colors.green),
                  ],
                ),
                const Spacer(),
                
                const Text(
                  'ASCEND: LEVEL UP YOUR LIFE',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 3.0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }
}
