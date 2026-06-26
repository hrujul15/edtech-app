import 'package:flutter/material.dart';
import 'package:edtech_app/services/auth_service.dart';
import 'package:edtech_app/services/firestore_service.dart';
import 'package:edtech_app/services/cache_service.dart';

class InterestPickerScreen extends StatefulWidget {
  const InterestPickerScreen({super.key});

  @override
  State<InterestPickerScreen> createState() => _InterestPickerScreenState();
}

class _InterestPickerScreenState extends State<InterestPickerScreen> {
  final _authService = AuthService();
  final _firestoreService = FirestoreService();
  final _cacheService = CacheService();
  final List<String> _topics = [
    'Programming',
    'Math',
    'Science',
    'Design',
    'Business',
    'Language',
    'History',
    'AI/ML',
  ];

  final Set<String> _selectedTopics = {};
  bool _isLoading = false;
  String? _errorMessage;

  void _toggleTopic(String topic) {
    setState(() {
      if (_selectedTopics.contains(topic)) {
        _selectedTopics.remove(topic);
      } else {
        _selectedTopics.add(topic);
      }
    });
  }

  void _handleContinue() async {
    if (_selectedTopics.length < 3) {
      setState(() {
        _errorMessage = 'Please select at least 3 topics to continue.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final uid = _authService.currentUid;
      if (uid == null) {
        throw Exception('User is not logged in.');
      }
      await _cacheService
          .clearAll(); // wipe cache so home refreshes with new interests
      await _firestoreService.saveInterests(uid, _selectedTopics.toList());

      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to save interests: ${e.toString()}';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isButtonEnabled = _selectedTopics.length >= 3;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              Text(
                'Personalize Your Feed',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[900],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Select at least 3 topics you are interested in to customize your learning recommendation engine.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Center(
                child: Chip(
                  label: Text(
                    '${_selectedTopics.length} selected (min 3)',
                    style: TextStyle(
                      color: isButtonEnabled
                          ? Colors.green[800]
                          : Colors.blueGrey[800],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  backgroundColor: isButtonEnabled
                      ? Colors.green[50]
                      : Colors.blueGrey[50],
                ),
              ),
              const SizedBox(height: 24),
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    border: Border.all(color: Colors.red[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red[700]),
                    textAlign: TextAlign.center,
                  ),
                ),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 2.0,
                  ),
                  itemCount: _topics.length,
                  itemBuilder: (context, index) {
                    final topic = _topics[index];
                    final isSelected = _selectedTopics.contains(topic);
                    return InkWell(
                      onTap: () => _toggleTopic(topic),
                      borderRadius: BorderRadius.circular(16),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.blue[600] : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? Colors.blue[600]!
                                : Colors.grey[300]!,
                            width: 2,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: Colors.blue.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : [],
                        ),
                        child: Center(
                          child: Text(
                            topic,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? Colors.white
                                  : Colors.blueGrey[800],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: (isButtonEnabled && !_isLoading)
                    ? _handleContinue
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  disabledBackgroundColor: Colors.grey[300],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: isButtonEnabled ? 4 : 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text(
                        'Continue to Home',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
