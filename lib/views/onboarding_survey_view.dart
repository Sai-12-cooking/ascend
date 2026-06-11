import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/player_profile_provider.dart';
import '../theme/app_theme.dart';
import 'dashboard_view.dart';

class OnboardingSurveyView extends ConsumerStatefulWidget {
  const OnboardingSurveyView({super.key});

  @override
  ConsumerState<OnboardingSurveyView> createState() => _OnboardingSurveyViewState();
}

class _OnboardingSurveyViewState extends ConsumerState<OnboardingSurveyView> {
  final PageController _pageController = PageController();
  
  String _primaryGoal = 'Muscle Gain';
  int _pushups = 0;
  int _pullups = 0;
  int _runMinutes = 0;
  int _runSeconds = 0;
  int _plankSeconds = 0;

  final _formKey = GlobalKey<FormState>();

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final mileTimeSeconds = (_runMinutes * 60) + _runSeconds;

    int totalPoints = 0;

    // Pushups logic
    if (_pushups <= 15) {
      totalPoints += 1;
    } else if (_pushups <= 40) {
      totalPoints += 2;
    } else {
      totalPoints += 3;
    }

    // Pullups logic
    if (_pullups <= 3) {
      totalPoints += 1;
    } else if (_pullups <= 12) {
      totalPoints += 2;
    } else {
      totalPoints += 3;
    }

    // Mile run logic
    if (mileTimeSeconds > 600 || mileTimeSeconds == 0) { // treat 0 as beginner or unset
      totalPoints += 1;
    } else if (mileTimeSeconds >= 420) {
      totalPoints += 2;
    } else {
      totalPoints += 3;
    }

    // Plank logic
    if (_plankSeconds < 60) {
      totalPoints += 1;
    } else if (_plankSeconds <= 180) {
      totalPoints += 2;
    } else {
      totalPoints += 3;
    }

    final average = (totalPoints / 4).round();
    String tier = 'Beginner';
    if (average == 2) tier = 'Intermediate';
    if (average == 3) tier = 'Elite';

    final profile = ref.read(playerProfileProvider);
    final updatedProfile = profile.copyWith(
      primaryFitnessGoal: _primaryGoal,
      globalFitnessTier: tier,
      physicalBaselines: {
        'pushups': _pushups,
        'pullups': _pullups,
        'mileTimeSeconds': mileTimeSeconds,
        'plankSeconds': _plankSeconds,
      },
    );

    await ref.read(playerProfileProvider.notifier).setProfile(
          updatedProfile,
          saveToFirestore: true,
        );

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const DashboardView()),
      );
    }
  }

  void _nextPage() {
    FocusScope.of(context).unfocus();
    if (_pageController.page!.toInt() < 4) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _submit();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('INITIATE SEQUENCE', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, letterSpacing: 2.0)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(), // Force using buttons
            children: [
              _buildStep1Goal(),
              _buildStep2Pushups(),
              _buildStep3Pullups(),
              _buildStep4Run(),
              _buildStep5Plank(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepContainer({required String title, required String subtitle, required Widget content}) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.2),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 16, color: Colors.white60, height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          content,
          const Spacer(),
          ElevatedButton(
            onPressed: _nextPage,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              _pageController.hasClients && _pageController.page?.toInt() == 4 ? 'COMPLETE ASSESSMENT' : 'NEXT PROTOCOL',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1Goal() {
    return _buildStepContainer(
      title: 'PRIMARY DIRECTIVE',
      subtitle: 'Identify your main objective to calibrate the AI scheduler.',
      content: DropdownButtonFormField<String>(
        value: _primaryGoal,
        dropdownColor: const Color(0xFF18181B),
        decoration: InputDecoration(
          filled: true,
          fillColor: const Color(0xFF18181B),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.primaryColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppTheme.primaryColor.withOpacity(0.5)),
          ),
        ),
        style: const TextStyle(color: Colors.white, fontSize: 18),
        items: const [
          DropdownMenuItem(value: 'Muscle Gain', child: Text('Muscle Gain')),
          DropdownMenuItem(value: 'Weight Loss', child: Text('Weight Loss')),
          DropdownMenuItem(value: 'Endurance', child: Text('Endurance')),
        ],
        onChanged: (val) {
          if (val != null) setState(() => _primaryGoal = val);
        },
      ),
    );
  }

  Widget _buildStep2Pushups() {
    return _buildStepContainer(
      title: 'UPPER BODY STRENGTH',
      subtitle: 'Enter your maximum unbroken pushup capacity.',
      content: TextFormField(
        keyboardType: TextInputType.number,
        style: const TextStyle(fontSize: 32, color: AppTheme.goldColor, fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          hintText: '0',
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
          border: InputBorder.none,
        ),
        onSaved: (val) => _pushups = int.tryParse(val ?? '0') ?? 0,
        validator: (val) => val == null || val.isEmpty ? 'Required' : null,
      ),
    );
  }

  Widget _buildStep3Pullups() {
    return _buildStepContainer(
      title: 'VERTICAL PULL',
      subtitle: 'Enter your maximum strict pullup capacity.',
      content: TextFormField(
        keyboardType: TextInputType.number,
        style: const TextStyle(fontSize: 32, color: AppTheme.goldColor, fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          hintText: '0',
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
          border: InputBorder.none,
        ),
        onSaved: (val) => _pullups = int.tryParse(val ?? '0') ?? 0,
        validator: (val) => val == null || val.isEmpty ? 'Required' : null,
      ),
    );
  }

  Widget _buildStep4Run() {
    return _buildStepContainer(
      title: 'AEROBIC ENDURANCE',
      subtitle: 'Enter your fastest 1-Mile run time.',
      content: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 100,
            child: TextFormField(
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 32, color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              decoration: const InputDecoration(hintText: 'Min', hintStyle: TextStyle(color: Colors.white24)),
              onSaved: (val) => _runMinutes = int.tryParse(val ?? '0') ?? 0,
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(':', style: TextStyle(fontSize: 32, color: Colors.white54, fontWeight: FontWeight.bold)),
          ),
          SizedBox(
            width: 100,
            child: TextFormField(
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 32, color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              decoration: const InputDecoration(hintText: 'Sec', hintStyle: TextStyle(color: Colors.white24)),
              onSaved: (val) => _runSeconds = int.tryParse(val ?? '0') ?? 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep5Plank() {
    return _buildStepContainer(
      title: 'CORE STABILITY',
      subtitle: 'Enter your maximum plank hold time in seconds.',
      content: TextFormField(
        keyboardType: TextInputType.number,
        style: const TextStyle(fontSize: 32, color: AppTheme.goldColor, fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          hintText: '0',
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
          border: InputBorder.none,
        ),
        onSaved: (val) => _plankSeconds = int.tryParse(val ?? '0') ?? 0,
        validator: (val) => val == null || val.isEmpty ? 'Required' : null,
      ),
    );
  }
}
