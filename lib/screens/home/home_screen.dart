import 'package:flutter/material.dart';
import 'package:edtech_app/services/auth_service.dart';
import 'package:edtech_app/services/firestore_service.dart';
import 'package:edtech_app/models/user_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _authService = AuthService();
  final _firestoreService = FirestoreService();

  bool _isLoading = true;
  UserModel? _userModel;

  @override
  void initState() {
    super.initState();
    _checkInterests();
  }

  Future<void> _checkInterests() async {
    try {
      final uid = _authService.currentUid;
      if (uid == null) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
        return;
      }

      final user = await _firestoreService.getUser(uid);
      if (mounted) {
        if (user.interests.isEmpty) {
          // Redirect to onboarding
          Navigator.of(context).pushReplacementNamed('/onboarding');
        } else {
          setState(() {
            _userModel = user;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error checking interests: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handleLogout() async {
    await _authService.signOut();
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final user = _authService.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Home'), elevation: 0),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Text(
                'Welcome, ${_userModel?.name ?? 'Learner'}!',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              if (user != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Email: ${user.email}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'User ID: ${user.uid}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Interests: ${_userModel?.interests.join(', ') ?? ''}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _handleLogout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 24,
                  ),
                ),
                child: const Text(
                  'Sign Out',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
