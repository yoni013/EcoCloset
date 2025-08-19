import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:eco_closet/generated/l10n.dart';

class PhoneAuthScreen extends StatefulWidget {
  final VoidCallback onSignedIn;

  const PhoneAuthScreen({Key? key, required this.onSignedIn}) : super(key: key);

  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  // Phone auth fields
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  
  // Email auth fields
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  
  final _formKey = GlobalKey<FormState>();
  
  bool _isLoading = false;
  bool _codeSent = false;
  bool _isEmailMode = false; // Toggle between phone and email auth
  bool _isRegistering = false; // Toggle between signin and signup for email
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  
  String? _verificationId;
  final String _countryCode = '+972'; // Fixed to Israel only
  
  // For web reCAPTCHA
  ConfirmationResult? _confirmationResult;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _sendOTP() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    String phoneInput = _phoneController.text.trim();
    
    // Handle Israeli phone numbers - remove leading 0 if present
    if (phoneInput.startsWith('0')) {
      phoneInput = phoneInput.substring(1);
      debugPrint('Israeli number: Removed leading 0, formatted as: +972$phoneInput');
    }
    
    final phoneNumber = '$_countryCode$phoneInput';
    debugPrint('Final phone number for Firebase: $phoneNumber');

    try {
      if (kIsWeb) {
        // For web, use signInWithPhoneNumber
        _confirmationResult = await FirebaseAuth.instance.signInWithPhoneNumber(phoneNumber);
        setState(() {
          _codeSent = true;
          _isLoading = false;
        });
      } else {
        // For mobile platforms
        await FirebaseAuth.instance.verifyPhoneNumber(
          phoneNumber: phoneNumber,
          verificationCompleted: (PhoneAuthCredential credential) async {
            await FirebaseAuth.instance.signInWithCredential(credential);
            widget.onSignedIn();
          },
          verificationFailed: (FirebaseAuthException e) {
            setState(() => _isLoading = false);
            _showError(e.message ?? 'Verification failed');
          },
          codeSent: (String verificationId, int? resendToken) {
            setState(() {
              _verificationId = verificationId;
              _codeSent = true;
              _isLoading = false;
            });
          },
          codeAutoRetrievalTimeout: (String verificationId) {
            _verificationId = verificationId;
          },
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Failed to send OTP: ${e.toString()}');
    }
  }

  Future<void> _verifyOTP() async {
    if (_codeController.text.trim().length != 6) {
      _showError('Please enter a valid 6-digit code');
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (kIsWeb) {
        // For web
        if (_confirmationResult != null) {
          await _confirmationResult!.confirm(_codeController.text.trim());
          widget.onSignedIn();
        }
      } else {
        // For mobile
        if (_verificationId != null) {
          final credential = PhoneAuthProvider.credential(
            verificationId: _verificationId!,
            smsCode: _codeController.text.trim(),
          );
          await FirebaseAuth.instance.signInWithCredential(credential);
          widget.onSignedIn();
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Invalid verification code. Please try again.');
    }
  }

  // Email Authentication Methods
  Future<void> _signInWithEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      
      if (credential.user != null && !credential.user!.emailVerified) {
        await _sendEmailVerification();
        _showEmailVerificationDialog();
      } else {
        widget.onSignedIn();
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);
      String message = 'Sign in failed';
      switch (e.code) {
        case 'user-not-found':
          message = 'No account found with this email. Please register first.';
          break;
        case 'wrong-password':
          message = 'Incorrect password. Please try again.';
          break;
        case 'invalid-email':
          message = 'Please enter a valid email address.';
          break;
        case 'user-disabled':
          message = 'This account has been disabled.';
          break;
        default:
          message = e.message ?? message;
      }
      _showError(message);
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('An unexpected error occurred. Please try again.');
    }
  }

  Future<void> _registerWithEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      
      // Update display name
      if (_nameController.text.trim().isNotEmpty) {
        await credential.user?.updateDisplayName(_nameController.text.trim());
      }
      
      await _sendEmailVerification();
      _showEmailVerificationDialog();
      
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);
      String message = 'Registration failed';
      switch (e.code) {
        case 'weak-password':
          message = 'Password is too weak. Please choose a stronger password.';
          break;
        case 'email-already-in-use':
          message = 'An account already exists with this email.';
          break;
        case 'invalid-email':
          message = 'Please enter a valid email address.';
          break;
        default:
          message = e.message ?? message;
      }
      _showError(message);
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('An unexpected error occurred. Please try again.');
    }
  }

  Future<void> _sendEmailVerification() async {
    try {
      await FirebaseAuth.instance.currentUser?.sendEmailVerification();
    } catch (e) {
      debugPrint('Error sending email verification: $e');
    }
  }

  void _showEmailVerificationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).verifyEmailTitle),
        content: Text(AppLocalizations.of(context).verifyEmailMessage),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseAuth.instance.signOut();
              setState(() => _isLoading = false);
            },
            child: const Text('OK'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseAuth.instance.currentUser?.reload();
              final user = FirebaseAuth.instance.currentUser;
              if (user != null && user.emailVerified) {
                widget.onSignedIn();
              } else {
                _showError('Email not verified yet. Please check your inbox.');
              }
            },
            child: const Text('I\'ve verified'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _goBack() {
    setState(() {
      _codeSent = false;
      _verificationId = null;
      _confirmationResult = null;
      _codeController.clear();
    });
  }

  String _getFormattedPhoneNumber() {
    String phoneInput = _phoneController.text.trim();
    
    // Handle Israeli phone numbers - remove leading 0 if present for display
    if (phoneInput.startsWith('0')) {
      phoneInput = phoneInput.substring(1);
    }
    
    return '$_countryCode$phoneInput';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getAppBarTitle()),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                Text(
                  'Welcome to Eco Closet',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _getSubtitle(),
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                
                if (!_codeSent) ...[
                  
                  if (_isEmailMode) ...[
                    // Email authentication form
                    if (_isRegistering) ...[
                      // Name field for registration
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (value) {
                          if (_isRegistering && (value == null || value.trim().isEmpty)) {
                            return 'Please enter your name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    // Email field
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                          return 'Please enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Password field
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your password';
                        }
                        if (_isRegistering && value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Confirm password field for registration
                    if (_isRegistering) ...[
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        decoration: InputDecoration(
                          labelText: 'Confirm Password',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off),
                            onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                          ),
                        ),
                        validator: (value) {
                          if (_isRegistering) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please confirm your password';
                            }
                            if (value != _passwordController.text) {
                              return 'Passwords do not match';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                  ] else ...[
                    // Phone authentication form
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your phone number';
                        }
                        
                        String phoneValue = value.trim();
                        
                        // Israeli phone number validation
                        if (phoneValue.startsWith('0')) {
                          phoneValue = phoneValue.substring(1); // Remove leading 0 for validation
                        }
                        
                        if (phoneValue.length != 9) {
                          return 'Phone number should be 9 digits (e.g., 0501234567)';
                        }
                        
                        if (!phoneValue.startsWith(RegExp(r'[5][0-9]'))) {
                          return 'Mobile numbers start with 05X';
                        }
                        
                        return null;
                      },
                    ),
                  ],
                  
                  const SizedBox(height: 24),
                  
                  // Primary action button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _getPrimaryAction(),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(_getPrimaryActionText()),
                  ),
                  
                  // Secondary action for email mode
                  if (_isEmailMode) ...[
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => setState(() => _isRegistering = !_isRegistering),
                      child: Text(_isRegistering 
                        ? 'Already have an account? Sign In'
                        : 'Don\'t have an account? Sign Up'),
                    ),
                  ],
                  
                  // Alternative auth option
                  const SizedBox(height: 16),
                  Text(
                    'or',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => setState(() {
                      _isEmailMode = !_isEmailMode;
                      _isRegistering = false;
                    }),
                    child: Text(_isEmailMode 
                      ? 'Continue with Phone Number'
                      : 'Continue with Email & Password'),
                  ),
                ] else ...[
                  // SMS verification screen
                  Icon(
                    Icons.sms,
                    size: 64,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Enter verification code',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Code sent to ${_getFormattedPhoneNumber()}',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  
                  TextFormField(
                    controller: _codeController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Verification Code',
                      hintText: '123456',
                      border: OutlineInputBorder(),
                    ),
                    style: const TextStyle(fontSize: 24, letterSpacing: 8),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  
                  ElevatedButton(
                    onPressed: _isLoading ? null : _verifyOTP,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : const Text('Verify'),
                  ),
                  const SizedBox(height: 16),
                  
                  TextButton(
                    onPressed: _goBack,
                    child: const Text('Change Phone Number'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getAppBarTitle() {
    if (_codeSent) return 'Enter SMS Code';
    if (_isEmailMode && _isRegistering) return 'Create Account';
    if (_isEmailMode) return 'Sign In';
    return 'Phone Authentication';
  }

  String _getSubtitle() {
    if (_codeSent) return 'We sent you a verification code';
    if (_isEmailMode && _isRegistering) return 'Create your account to get started';
    if (_isEmailMode) return 'Sign in to your account';
    return 'We\'ll send you a verification code via SMS';
  }

  VoidCallback _getPrimaryAction() {
    if (_isEmailMode && _isRegistering) return _registerWithEmail;
    if (_isEmailMode) return _signInWithEmail;
    return _sendOTP;
  }

  String _getPrimaryActionText() {
    if (_isEmailMode && _isRegistering) return 'Create Account';
    if (_isEmailMode) return 'Sign In';
    return 'Send Code';
  }
}
