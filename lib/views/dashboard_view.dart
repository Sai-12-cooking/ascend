import 'dart:ui';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import '../models/player_profile.dart';
import '../models/task_model.dart';
import '../providers/player_profile_provider.dart';
import '../providers/task_provider.dart';
import '../providers/daily_popup_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/penalty_engine_provider.dart';
import '../widgets/premium_gate.dart';
import '../theme/app_theme.dart';
import '../utils/export_utility.dart';
import '../widgets/cinematic_rank_up_overlay.dart';
import 'monk_mode_view.dart';
import 'custom_web_view.dart';

class DashboardView extends ConsumerStatefulWidget {
  const DashboardView({super.key});

  @override
  ConsumerState<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends ConsumerState<DashboardView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Load today's tasks on load for the current user
      final uid = ref.read(authRepositoryProvider).currentUser?.uid ?? 'unknown_uid';
      await _evaluateDeadlinesAndRefresh(uid);
      
      // Trigger landing popup if it's the first open
      _triggerPopupIfNeeded();
    });
  }

  Future<void> _evaluateDeadlinesAndRefresh(String uid) async {
    final profile = ref.read(playerProfileProvider);
    final penaltyEngine = ref.read(penaltyEngineProvider);
    
    final newProfile = await penaltyEngine.evaluatePassedDeadlines(uid, profile);
    if (newProfile != profile) {
      ref.read(playerProfileProvider.notifier).setProfile(newProfile);
    }
    
    await ref.read(tasksNotifierProvider.notifier).fetchTodayTasks(uid);
  }

  void _triggerPopupIfNeeded() {
    final shouldShow = ref.read(dailyPopupProvider);
    if (shouldShow) {
      _showSystemActivatedDialog();
    }
  }

  Future<Map<String, String>> _fetchZenQuote() async {
    try {
      final dio = Dio();
      final response = await dio.get('https://zenquotes.io/api/random');
      if (response.data is List && response.data.isNotEmpty) {
        final quoteData = response.data[0];
        return {
          'q': quoteData['q']?.toString() ?? 'Rise to the challenge.',
          'a': quoteData['a']?.toString() ?? 'System',
        };
      }
    } catch (e) {
      // Fallback
    }
    return {
      'q': 'Rise to the challenge, gain experience, and build your legacy.',
      'a': 'Ascend AI',
    };
  }

  /// Displays the gaming-inspired "SYSTEM ACTIVATED" popup with background blur.
  void _showSystemActivatedDialog() {
    final quoteFuture = _fetchZenQuote();
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'System Activated Dialog',
      barrierColor: Colors.black.withOpacity(0.7),
      transitionDuration: const Duration(milliseconds: 600),
      pageBuilder: (context, anim1, anim2) {
        return const SizedBox.shrink(); // Unused in custom transition builder
      },
      transitionBuilder: (context, anim1, anim2, child) {
        final scale = CurvedAnimation(parent: anim1, curve: Curves.elasticOut).value;
        final opacity = CurvedAnimation(parent: anim1, curve: Curves.easeIn).value;
        
        return BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 10 * anim1.value,
            sigmaY: 10 * anim1.value,
          ),
          child: Opacity(
            opacity: opacity,
            child: Transform.scale(
              scale: scale,
              child: AlertDialog(
                backgroundColor: const Color(0xFF0F0F13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(color: AppTheme.primaryColor, width: 2),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.security,
                      size: 64,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(height: 16),
                    // High-impact neon title
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [AppTheme.primaryColor, AppTheme.accentColor],
                      ).createShader(bounds),
                      child: const Text(
                        'SYSTEM ACTIVATED',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.0,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FutureBuilder<Map<String, String>>(
                      future: quoteFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.all(24.0),
                            child: CircularProgressIndicator(color: AppTheme.primaryColor),
                          );
                        }
                        
                        final quote = snapshot.data?['q'] ?? '';
                        final author = snapshot.data?['a'] ?? '';
                        
                        return Column(
                          children: [
                            Text(
                              '"$quote"',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontStyle: FontStyle.italic,
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '- $author',
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppTheme.goldColor,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 16,
                        ),
                      ),
                      onPressed: () {
                        // Dismiss popup state
                        ref.read(dailyPopupProvider.notifier).dismissPopup();
                        Navigator.of(context).pop();

                        // Check if we need to dynamically generate quests for the new day
                        final tasks = ref.read(tasksNotifierProvider);
                        if (tasks.isEmpty) {
                          final uid = ref.read(authRepositoryProvider).currentUser?.uid ?? 'unknown_uid';
                          final profile = ref.read(playerProfileProvider);
                          ref.read(tasksNotifierProvider.notifier).generateAndSaveDailyQuests(uid, profile);
                        }
                      },
                      child: const Text(
                        'BEGIN ASCENT',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Displays a dialog to add a new task custom to the Dashboard.
  void _showAddTaskDialog() {
    final titleController = TextEditingController();
    String selectedCategory = 'Workout';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF18181B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFF27272A)),
              ),
              title: const Text('New Quest'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      hintText: 'Enter quest title...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    dropdownColor: const Color(0xFF18181B),
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                    items: ['Workout', 'Focus Work', 'Learning']
                        .map((cat) => DropdownMenuItem(
                              value: cat,
                              child: Text(cat),
                            ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          selectedCategory = val;
                        });
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final title = titleController.text.trim();
                    if (title.isNotEmpty) {
                      final uid = ref.read(authRepositoryProvider).currentUser?.uid ?? 'unknown_uid';
                      final task = TaskModel(
                        id: const Uuid().v4(),
                        userId: uid,
                        title: title,
                        category: selectedCategory,
                        xpReward: selectedCategory == 'Workout' ? 20 : 15,
                      );
                      ref.read(tasksNotifierProvider.notifier).addTask(task);
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Calculates the XP progress percentage for the progress bar based on the current rank.
  double _getXpProgress(String rank, int xp) {
    if (rank == 'E') return (xp / 150.0).clamp(0.0, 1.0);
    if (rank == 'D') return ((xp - 150.0) / (500.0 - 150.0)).clamp(0.0, 1.0);
    if (rank == 'C') return ((xp - 500.0) / (1200.0 - 500.0)).clamp(0.0, 1.0);
    if (rank == 'B') return ((xp - 1200.0) / (2500.0 - 1200.0)).clamp(0.0, 1.0);
    if (rank == 'A') return ((xp - 2500.0) / (5000.0 - 2500.0)).clamp(0.0, 1.0);
    if (rank == 'S') return ((xp - 500.0) / (10000.0 - 5000.0)).clamp(0.0, 1.0);
    return 1.0; // Monarch
  }

  /// Returns the next Rank target XP cap.
  int _getNextRankCap(String rank) {
    if (rank == 'E') return 150;
    if (rank == 'D') return 500;
    if (rank == 'C') return 1200;
    if (rank == 'B') return 2500;
    if (rank == 'A') return 5000;
    if (rank == 'S') return 10000;
    return 10000;
  }

  @override
  Widget build(BuildContext context) {
    final PlayerProfile profile = ref.watch(playerProfileProvider);
    final tasks = ref.watch(tasksNotifierProvider);

    final progress = _getXpProgress(profile.currentRank, profile.totalXp);
    final nextCap = _getNextRankCap(profile.currentRank);

    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: RefreshIndicator(
              onRefresh: () async {
                HapticFeedback.lightImpact();
                final uid = ref.read(authRepositoryProvider).currentUser?.uid ?? 'unknown_uid';
                await _evaluateDeadlinesAndRefresh(uid);
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'ASCEND',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.0,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.self_improvement, color: AppTheme.goldColor),
                        onPressed: () {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => const PremiumGate(child: MonkModeView()),
                          ));
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.info_outline),
                        onPressed: _showSystemActivatedDialog,
                      ),
                      IconButton(
                        icon: const Icon(Icons.public, color: AppTheme.primaryColor),
                        onPressed: () {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => const CustomWebView(
                              url: 'https://flutter.dev',
                              title: 'WEB VIEW',
                            ),
                          ));
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // PLAYER CARD
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  width: 48,
                                  height: 48,
                                  color: Colors.white10,
                                  child: Platform.environment.containsKey('FLUTTER_TEST')
                                      ? const Icon(Icons.person, size: 32, color: Colors.white54)
                                      : SvgPicture.network(
                                          'https://api.dicebear.com/7.x/pixel-art/svg?seed=${Uri.encodeComponent(profile.username)}',
                                          placeholderBuilder: (BuildContext context) => const Padding(
                                            padding: EdgeInsets.all(12.0),
                                            child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryColor),
                                          ),
                                          errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) => const Icon(
                                            Icons.person,
                                            size: 32,
                                            color: Colors.white54,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    profile.username,
                                    style: Theme.of(context).textTheme.titleLarge,
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.local_fire_department,
                                        color: Colors.orange,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${profile.streakCount} Day Streak',
                                        style: const TextStyle(
                                          color: Colors.orange,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                          // Premium badge for Rank
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: profile.currentRank == 'Monarch'
                                  ? AppTheme.goldColor.withOpacity(0.15)
                                  : AppTheme.primaryColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: profile.currentRank == 'Monarch'
                                    ? AppTheme.goldColor
                                    : AppTheme.primaryColor,
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              'RANK ${profile.currentRank}',
                              style: TextStyle(
                                color: profile.currentRank == 'Monarch'
                                    ? AppTheme.goldColor
                                    : AppTheme.primaryColor,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // XP Progress Bar Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'XP: ${profile.totalXp} / $nextCap',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          Text(
                            '${(progress * 100).toInt()}%',
                            style: const TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Styled Progress Bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 12,
                          backgroundColor: const Color(0xFF27272A),
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            final completedQuests = tasks.where((t) => t.isCompleted).length;
                            ExportUtility.exportProgressCard(context, profile, completedQuests);
                          },
                          icon: const Icon(Icons.ios_share, size: 18),
                          label: const Text('SHARE ASCENSION'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.primaryColor,
                            side: const BorderSide(color: AppTheme.primaryColor),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // STATS GRID HEADER
              Text(
                'CORE ATTRIBUTES',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
              ),
              const SizedBox(height: 12),

              // STATS GRID
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.6,
                children: [
                  _buildStatCard('Strength', profile.coreStats['Strength'] ?? 10, Icons.fitness_center),
                  _buildStatCard('Intelligence', profile.coreStats['Intelligence'] ?? 10, Icons.psychology),
                  _buildStatCard('Discipline', profile.coreStats['Discipline'] ?? 10, Icons.shield),
                  _buildStatCard('Wealth', profile.coreStats['Wealth'] ?? 10, Icons.monetization_on),
                  _buildStatCard(
                    'Charisma',
                    profile.coreStats['Charisma'] ?? 10,
                    Icons.auto_awesome,
                    isGold: true,
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // QUESTS HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'DAILY QUESTS',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, color: AppTheme.primaryColor),
                    onPressed: _showAddTaskDialog,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // QUESTS LIST
              if (tasks.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32.0),
                    child: Column(
                      children: [
                        const Icon(Icons.assignment_add, size: 48, color: Colors.white24),
                        const SizedBox(height: 16),
                        const Text(
                          'No active quests detected.',
                          style: TextStyle(color: Colors.white54, fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: _showAddTaskDialog,
                          icon: const Icon(Icons.add),
                          label: const Text('Initialize First Quest'),
                        )
                      ],
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: tasks.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: task.isCompleted
                              ? Colors.green.withOpacity(0.1)
                              : AppTheme.primaryColor.withOpacity(0.1),
                          child: Icon(
                            task.category == 'Workout'
                                ? Icons.fitness_center
                                : task.category == 'Focus Work'
                                    ? Icons.laptop
                                    : Icons.menu_book,
                            color: task.isCompleted ? Colors.green : AppTheme.primaryColor,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          task.title,
                          style: TextStyle(
                            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                            color: task.isCompleted ? Colors.white38 : Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          '${task.category} • +${task.xpReward} XP',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: Checkbox(
                          value: task.isCompleted,
                          activeColor: Colors.green,
                          onChanged: (val) {
                            ref.read(tasksNotifierProvider.notifier).toggleTaskCompletion(task.id);
                            // If completing, dynamically award XP, else remove XP
                            if (val == true) {
                              ref.read(playerProfileProvider.notifier).addXP(task.xpReward);
                            } else {
                              ref.read(playerProfileProvider.notifier).removeXP(task.xpReward);
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      const CinematicRankUpOverlay(),
      ],
      ),
    );
  }

  /// Builds a card representing a single player core attribute.
  Widget _buildStatCard(String title, int value, IconData icon, {bool isGold = false}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            Icon(
              icon,
              size: 28,
              color: isGold ? AppTheme.goldColor : AppTheme.primaryColor,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 13, color: Colors.white54, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Lvl $value',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
