import 'package:flutter/material.dart';
import 'package:medichain/patient/input_field.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:medichain/patient/login_page.dart';

class PatientRegistrationScreen extends StatefulWidget {
  const PatientRegistrationScreen({super.key});

  @override
  State<PatientRegistrationScreen> createState() => _PatientRegistrationScreenState();
}

class _PatientRegistrationScreenState extends State<PatientRegistrationScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  TextEditingController _firstNameController = TextEditingController();
  TextEditingController _lastNameController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _phoneController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  TextEditingController _confirmPasswordController = TextEditingController();

  bool _isLoading = false;

  Future<void> _registerPatient() async {
    print("DEBUG: Email is '${_emailController.text}'");
    print("DEBUG: Password is '${_passwordController.text}'");
    print("DEBUG: First Name is '${_firstNameController.text}'");
  
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match!'), backgroundColor: Colors.red),
      );
      return;
    }

    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields.'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final AuthResponse response = await _supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        data: {
          'first_name': _firstNameController.text.trim(),
          'last_name': _lastNameController.text.trim(),
          'role': 'patient', 
        },
      );

      String generatePatientId() {
        final random = DateTime.now().millisecondsSinceEpoch
            .toString()
            .substring(7);
        return 'PAT$random';
      }
      
      final user = response.user;

      if (user != null) {
        await _supabase.from('patients').insert({
  'id': user.id,

  'patient_id': generatePatientId(),

  'full_name':
      '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}',

  'email': _emailController.text.trim(),

  'phone': _phoneController.text.trim(),

  // 'date_of_birth': null,
});
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration successful! Check your email for confirmation.')),
        );
        _firstNameController.clear();
        _lastNameController.clear();
        _emailController.clear();
        _passwordController.clear();
        _confirmPasswordController.clear();
        _phoneController.clear();
      }
    } on AuthException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message), backgroundColor: Colors.red),
        );
      }
    } catch (error) {

  print("FULL ERROR: $error");

  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error.toString()),
        backgroundColor: Colors.red,
      ),
    );
  }
}
    finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Patient Registration')),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 420,
            padding: const EdgeInsets.all(24),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(30),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.person_add_alt_1,
                      size: 70,
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      'Patient Registration',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Create your account',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                    const SizedBox(height: 30),
                    InputField(
                      label: 'First Name',
                      controller: _firstNameController,
                      hint: 'Enter your first name',
                    ),
                    const SizedBox(height: 18),
                    InputField(
                      label: 'Last Name',
                      controller: _lastNameController,
                      hint: 'Enter your last name',
                    ),
                    const SizedBox(height: 18),
                    InputField(
                      label: 'Email',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      hint: 'Enter your email',
                    ),
                    const SizedBox(height: 18),
                    InputField(
                      label: 'Phone Number',
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      hint: 'Enter your phone number',
                    ),
                    const SizedBox(height: 18),
                    InputField(
                      label: 'Password',
                      controller: _passwordController,
                      keyboardType: TextInputType.visiblePassword,
                      obscureText: true,
                      hint: 'Enter your password',
                    ),
                    const SizedBox(height: 18),
                    InputField(
                      label: 'Confirm Password',
                      controller: _confirmPasswordController,
                      keyboardType: TextInputType.visiblePassword,
                      obscureText: true,
                      hint: 'Confirm your password',
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _registerPatient,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Register', style: TextStyle(fontSize: 18)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // The text link component to route back to Login screen
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Already have an account? ",
                          style: TextStyle(color: Colors.grey),
                        ),
                        TextButton(
                          
                          onPressed: () {
                            // Navigates to the signup page safely
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const PatientLoginScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            'Login here',
                            style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}