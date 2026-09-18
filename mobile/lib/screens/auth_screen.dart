import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import '../widgets/google_button.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with TickerProviderStateMixin {
  // Video player controller for handwritten "On My Way"
  late VideoPlayerController _videoController;
  bool _isVideoInitialized = false;

  // Animation controllers
  late AnimationController _introController;
  late AnimationController _transitionController;
  late Animation<double> _logoScaleAnimation;
  late Animation<Offset> _logoPositionAnimation;
  late Animation<double> _formFadeAnimation;
  late Animation<Offset> _formSlideAnimation;
  late Animation<double> _handwrittenFadeAnimation;

  // Form controllers
  final TextEditingController _emailController = TextEditingController();
  bool _isIntroPlaying = true;
  bool _isLoading = false;
  String? _errorMessage;

  final String _apiBaseUrl = 'https://omw-jout.onrender.com/api';

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    hostedDomain: 'vitstudent.ac.in',
  );

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _setupVideo();
  }

  void _setupAnimations() {
    // 1. Intro sequence controller (2.8 seconds)
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );

    // 2. Morph transition controller (800ms easeInOutCubic)
    _transitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    // Mascot logo morphs from center intro to top header
    _logoPositionAnimation = Tween<Offset>(
      begin: const Offset(0, 0),
      end: const Offset(0, -0.42),
    ).animate(
      CurvedAnimation(
        parent: _transitionController,
        curve: Curves.easeInOutCubic,
      ),
    );

    _logoScaleAnimation = Tween<double>(
      begin: 1.15,
      end: 0.85,
    ).animate(
      CurvedAnimation(
        parent: _transitionController,
        curve: Curves.easeInOutCubic,
      ),
    );

    // Handwritten video fades out smoothly
    _handwrittenFadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(
      CurvedAnimation(
        parent: _transitionController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    // Form slides and fades up into position
    _formFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _transitionController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    _formSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _transitionController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _introController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _isIntroPlaying = false;
        });
        _transitionController.forward();
      }
    });
  }

  void _setupVideo() {
    _videoController = VideoPlayerController.asset(
      'assets/videos/handwritten_onmyway.mp4',
    )..initialize().then((_) {
        setState(() {
          _isVideoInitialized = true;
        });
        _videoController.setVolume(0.0);
        _videoController.play();
        _introController.forward();
      }).catchError((err) {
        // Fallback if video asset fails on desktop/web simulators
        setState(() {
          _isVideoInitialized = true;
        });
        _introController.forward();
      });
  }

  @override
  void dispose() {
    _videoController.dispose();
    _introController.dispose();
    _transitionController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // Handle Google Sign-In with VIT domain check
  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Check domain
      if (!googleUser.email.endsWith('@vitstudent.ac.in')) {
        await _googleSignIn.signOut();
        throw Exception('Only @vitstudent.ac.in VIT student emails are permitted.');
      }

      final GoogleSignInAuthentication auth = await googleUser.authentication;

      final res = await http.post(
        Uri.parse('$_apiBaseUrl/auth/google'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'idToken': auth.idToken ?? 'mock_google_id_token',
          'email': googleUser.email,
          'name': googleUser.displayName,
        }),
      );

      final data = jsonDecode(res.body);
      if (!data['success']) throw Exception(data['error']);

      _showSuccessDialog(
        title: data['isNewUser'] ? 'Welcome Airdrop Claimed!' : 'Welcome Back!',
        message: data['message'] ?? 'Logged in successfully.',
        userName: data['user']['name'],
        standing: data['user']['academicStanding'],
        tokens: data['wallet']['availableTokens'],
        bonusTokens: data['wallet']['bonusTokens'] ?? 0,
      );
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception:', '').trim();
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Handle email continue with domain verification
  Future<void> _handleEmailContinue() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _errorMessage = 'Please enter your VIT student email');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await http.post(
        Uri.parse('$_apiBaseUrl/auth/vit-verify'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      final data = jsonDecode(res.body);
      if (!data['success']) {
        throw Exception(data['error'] ?? 'Invalid VIT student email');
      }

      // Validated! Proceed with registration / login
      final authRes = await http.post(
        Uri.parse('$_apiBaseUrl/auth/google'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'idToken': 'mock_token_${DateTime.now().millisecondsSinceEpoch}',
          'email': data['email'],
          'name': data['fullName'],
        }),
      );

      final authData = jsonDecode(authRes.body);
      _showSuccessDialog(
        title: authData['isNewUser'] ? '20 Tokens Airdropped!' : 'Authenticated!',
        message: authData['message'],
        userName: authData['user']['name'],
        standing: authData['user']['academicStanding'],
        tokens: authData['wallet']['availableTokens'],
        bonusTokens: authData['wallet']['bonusTokens'] ?? 0,
      );
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception:', '').trim();
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog({
    required String title,
    required String message,
    required String userName,
    required String standing,
    required dynamic tokens,
    required dynamic bonusTokens,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Text('🎉 ', style: TextStyle(fontSize: 22)),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message, style: const TextStyle(color: Color(0xFF4B5563), fontSize: 14)),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('👤 Student: $userName', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text('🎓 Academic Standing: $standing', style: const TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.w600, fontSize: 13)),
                  const Divider(height: 16),
                  Text('💰 Total Wallet: $tokens Tokens', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  Text('🎁 Non-Cashable Airdrop: $bonusTokens Tokens', style: const TextStyle(color: Color(0xFF4338CA), fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Enter Campus Marketplace'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // ----------------------------------------------------
            // 1. INTRO VIDEO OVERLAY (Handwritten "On My Way" text)
            // ----------------------------------------------------
            if (_isIntroPlaying || _transitionController.value < 0.5)
              Positioned(
                top: size.height * 0.55,
                child: FadeTransition(
                  opacity: _handwrittenFadeAnimation,
                  child: _isVideoInitialized && _videoController.value.isInitialized
                      ? SizedBox(
                          width: size.width * 0.75,
                          height: 90,
                          child: FittedBox(
                            fit: BoxFit.contain,
                            child: SizedBox(
                              width: _videoController.value.size.width,
                              height: _videoController.value.size.height,
                              child: VideoPlayer(_videoController),
                            ),
                          ),
                        )
                      : const Text(
                          'On My Way',
                          style: TextStyle(
                            fontFamily: 'serif',
                            fontStyle: FontStyle.italic,
                            fontSize: 32,
                            color: Color(0xFF16302E),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),

            // ----------------------------------------------------
            // 2. MASCOT CIRCULAR LOGO (Animates from center to top)
            // ----------------------------------------------------
            SlideTransition(
              position: _logoPositionAnimation,
              child: ScaleTransition(
                scale: _logoScaleAnimation,
                child: Hero(
                  tag: 'app_logo',
                  child: Image.asset(
                    'assets/images/logo_transparent.png',
                    width: 190,
                    height: 190,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),

            // ----------------------------------------------------
            // 3. LOGIN PAGE CONTENT (Exact match to target design)
            // ----------------------------------------------------
            Positioned(
              top: size.height * 0.32,
              left: 28,
              right: 28,
              bottom: 12,
              child: SlideTransition(
                position: _formSlideAnimation,
                child: FadeTransition(
                  opacity: _formFadeAnimation,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Title
                        const Text(
                          'Create an account',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                            color: Color(0xFF000000),
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Subtitle
                        const Text(
                          'Enter your email to sign up for this app',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Error message banner (if any)
                        if (_errorMessage != null)
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFFCA5A5)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(color: Color(0xFFB91C1C), fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Email Input Field
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(fontSize: 15, color: Colors.black87),
                          decoration: InputDecoration(
                            hintText: 'email@domain.com',
                            hintStyle: const TextStyle(
                              color: Color(0xFF9CA3AF),
                              fontSize: 15,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: Color(0xFFE5E7EB),
                                width: 1.2,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: Colors.black,
                                width: 1.4,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Primary Solid Black "Continue" Button
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleEmailContinue,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Continue',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.1,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 22),

                        // "or" Divider Line
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 1,
                                color: const Color(0xFFE5E7EB),
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 14),
                              child: Text(
                                'or',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF9CA3AF),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                height: 1,
                                color: const Color(0xFFE5E7EB),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // "Continue with Google" Button
                        GoogleSignInButton(
                          onPressed: _handleGoogleSignIn,
                          isLoading: _isLoading,
                        ),
                        const SizedBox(height: 12),

                        // "Continue with Email" Button
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: TextButton(
                            onPressed: () {
                              _emailController.text = 'vismay.shrouty2025@vitstudent.ac.in';
                            },
                            style: TextButton.styleFrom(
                              backgroundColor: const Color(0xFFF3F4F6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Continue with Email',
                              style: TextStyle(
                                color: Color(0xFF1F2937),
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Footer Terms & Privacy Policy
                        RichText(
                          textAlign: TextAlign.center,
                          text: const TextSpan(
                            text: 'By clicking continue, you agree to our ',
                            style: TextStyle(
                              color: Color(0xFF9CA3AF),
                              fontSize: 12,
                              height: 1.4,
                            ),
                            children: [
                              TextSpan(
                                text: 'Terms of Service',
                                style: TextStyle(
                                  color: Color(0xFF1F2937),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              TextSpan(text: '\nand '),
                              TextSpan(
                                text: 'Privacy Policy',
                                style: TextStyle(
                                  color: Color(0xFF1F2937),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ----------------------------------------------------
            // 4. BOTTOM HOME INDICATOR BAR (iOS / Modern Android)
            // ----------------------------------------------------
            Positioned(
              bottom: 8,
              child: Container(
                width: 134,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
