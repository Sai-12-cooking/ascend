import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import '../models/player_profile.dart';
import '../widgets/player_progress_card.dart';

class ExportUtility {
  static Future<void> exportProgressCard(
    BuildContext context,
    PlayerProfile profile,
    int completedQuests,
  ) async {
    final screenshotController = ScreenshotController();

    // The widget to capture
    final cardWidget = Directionality(
      textDirection: TextDirection.ltr,
      child: Material(
        color: Colors.transparent,
        child: PlayerProgressCard(
          profile: profile,
          completedQuestsCount: completedQuests,
        ),
      ),
    );

    // Capture off-screen
    final capturedBytes = await screenshotController.captureFromWidget(
      cardWidget,
      delay: const Duration(milliseconds: 20),
    );

    // Save to temp directory
    final tempDir = await getTemporaryDirectory();
    final file = await File('${tempDir.path}/ascend_progress.png').create();
    await file.writeAsBytes(capturedBytes);

    // Share natively
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Rise to the challenge. I am Rank ${profile.currentRank} on ASCEND!',
    );
  }
}
