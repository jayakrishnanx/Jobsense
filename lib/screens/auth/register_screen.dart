import 'package:flutter/material.dart';
import '../../data/app_state.dart';
import '../../models/user.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../home/home_screen.dart';

class RegisterScreen extends StatefulWidget {
  final String email;

  const RegisterScreen({
    super.key,
    required this.email,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController dobController = TextEditingController();
  final TextEditingController otherCourseController = TextEditingController();
  final TextEditingController yearController = TextEditingController();

  String? selectedGender = 'Male';
  String? selectedQualification = 'Degree';
  String? selectedCourse = 'BCA (Bachelor of Computer Applications)';
  String? selectedCategory = 'General';
  String? selectedState = 'Kerala';
  String? selectedDistrict = 'Ernakulam';

  bool _isLoading = false;
  bool _obscurePassword = true;

  static const Map<String, List<String>> qualificationCourses = {
    'Post Graduate': [
      'MCA (Master of Computer Applications)',
      'M.Tech / M.E (Computer Science / IT)',
      'M.Tech / M.E (Civil / Mechanical / Electrical / EC)',
      'MBA (Master of Business Administration)',
      'M.Sc Computer Science / Data Science / IT',
      'M.Sc Mathematics / Statistics',
      'M.Sc Physics / Chemistry',
      'M.Sc Botany / Zoology / Life Sciences',
      'M.Com (Finance / Taxation / Banking)',
      'M.A Economics / English / History / Public Admin',
      'MSW (Master of Social Work)',
      'LL.M (Master of Laws)',
      'MD / MS (Medical Postgraduate)',
      'Other',
    ],
    'Degree': [
      'BCA (Bachelor of Computer Applications)',
      'B.Tech / B.E (Computer Science & Engineering)',
      'B.Tech / B.E (Civil Engineering)',
      'B.Tech / B.E (Mechanical Engineering)',
      'B.Tech / B.E (Electrical & Electronics)',
      'B.Tech / B.E (Electronics & Communication)',
      'B.Sc Computer Science / IT / AI',
      'B.Sc Mathematics / Statistics',
      'B.Sc Physics / Chemistry',
      'B.Sc Botany / Zoology / Agriculture',
      'B.Sc Nursing',
      'B.Com (Finance / Computer Applications / General)',
      'BBA / BBM (Business Administration)',
      'B.A Economics / Political Science / History',
      'B.A English / Literature / Languages',
      'B.Ed (Bachelor of Education)',
      'LL.B (Bachelor of Laws)',
      'MBBS / BDS / BAMS / BHMS',
      'B.Pharm (Bachelor of Pharmacy)',
      'B.Voc (Vocational Studies)',
      'Other',
    ],
    'Diploma': [
      'Diploma in Computer Engineering / IT',
      'Diploma in Civil Engineering',
      'Diploma in Mechanical Engineering',
      'Diploma in Electrical & Electronics',
      'Diploma in Electronics & Communication',
      'Diploma in Automobile Engineering',
      'Diploma in Pharmacy (D.Pharm)',
      'Diploma in General Nursing & Midwifery (GNM)',
      'Diploma in Medical Laboratory Technology (DMLT)',
      'Diploma in Commercial Practice / Secretarial',
      'Other',
    ],
    'Plus Two / 12th': [
      'Higher Secondary - Science (Bio-Maths / PCMB)',
      'Higher Secondary - Science (Computer Science)',
      'Higher Secondary - Commerce (with Computer Applications / Maths)',
      'Higher Secondary - Commerce (Cooperation)',
      'Higher Secondary - Humanities / Arts',
      'VHSE / Technical Higher Secondary',
      'Other',
    ],
    'SSLC / 10th Pass': [
      'General 10th Standard / SSLC Pass',
      'CBSE Class 10 (Secondary School)',
      'ICSE Class 10 (Secondary School)',
      'ITI / Trade Certificate (Electrician, Fitter, Welder, COPA)',
      'Other',
    ],
  };

  final Map<String, List<String>> _stateDistricts = {
    'Kerala': [
      'Ernakulam',
      'Thiruvananthapuram',
      'Kozhikode',
      'Kollam',
      'Thrissur',
      'Malappuram',
      'Palakkad',
      'Kannur',
      'Kottayam',
      'Alappuzha',
      'Idukki',
      'Pathanamthitta',
      'Kasaragod',
      'Wayanad',
    ],
    'Tamil Nadu': ['Chennai', 'Coimbatore', 'Madurai', 'Tiruchirappalli', 'Salem'],
    'Karnataka': ['Bengaluru Urban', 'Mysuru', 'Mangaluru', 'Hubballi-Dharwad', 'Belagavi'],
    'Delhi': ['New Delhi', 'Central Delhi', 'South Delhi', 'North Delhi'],
    'Maharashtra': ['Mumbai', 'Pune', 'Nagpur', 'Nashik', 'Thane'],
  };

  @override
  void initState() {
    super.initState();
    if (widget.email.isNotEmpty) {
      emailController.text = widget.email;
    }
    final initialCourses = qualificationCourses[selectedQualification] ?? [];
    if (initialCourses.isNotEmpty) {
      selectedCourse = initialCourses.first;
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    dobController.dispose();
    otherCourseController.dispose();
    yearController.dispose();
    super.dispose();
  }

  Future<void> _selectDateOfBirth() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      firstDate: DateTime(1970),
      lastDate: DateTime(2010),
      initialDate: DateTime(2001, 6, 15),
    );

    if (pickedDate != null) {
      setState(() {
        dobController.text =
            '${pickedDate.day.toString().padLeft(2, '0')}/${pickedDate.month.toString().padLeft(2, '0')}/${pickedDate.year}';
      });
    }
  }

  void _registerUser() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields properly'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final emailVal = emailController.text.trim().toLowerCase();
    final nameVal = nameController.text.trim();
    final passVal = passwordController.text.trim();
    final effectiveCourse = selectedCourse == 'Other'
        ? otherCourseController.text.trim()
        : (selectedCourse ?? 'General');

    final userMap = {
      'name': nameVal,
      'email': emailVal,
      'password': passVal.isNotEmpty ? passVal : 'Password123',
      'username': emailVal.split('@')[0],
      'dob': dobController.text.trim(),
      'gender': selectedGender ?? 'Male',
      'qualification': selectedQualification ?? 'Degree',
      'course': effectiveCourse,
      'yearOfPassing': yearController.text.trim(),
      'category': selectedCategory ?? 'General',
      'state': selectedState ?? 'Kerala',
      'district': selectedDistrict ?? 'Ernakulam',
    };

    final newUser = User(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      name: nameVal,
      email: emailVal,
      phone: '',
      dob: dobController.text.trim(),
      gender: selectedGender ?? 'Male',
      qualification: selectedQualification ?? 'Degree',
      course: effectiveCourse,
      yearOfPassing: yearController.text.trim(),
      category: selectedCategory ?? 'General',
      state: selectedState ?? 'Kerala',
      district: selectedDistrict ?? 'Ernakulam',
    );

    await appState.registerUserAsync(userMap);
    if (appState.currentUser == null) {
      appState.registerUser(newUser);
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Account created successfully! Welcome, ${newUser.name}!'),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final availableDistricts = _stateDistricts[selectedState] ?? ['General'];
    final availableCourses = qualificationCourses[selectedQualification] ?? ['General', 'Other'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Candidate Registration'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Personal & Education Profile',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'JobSense uses your profile criteria to match Kerala PSC, SSC, and UPSC job openings you are eligible for.',
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 20),

                // Full Name
                CustomTextField(
                  controller: nameController,
                  label: 'Full Name',
                  hint: 'e.g. Rahul Sharma',
                  required: true,
                  prefixIcon: const Icon(Icons.person_outline),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter your full name';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Email
                CustomTextField(
                  controller: emailController,
                  label: 'Email Address',
                  hint: 'e.g. rahul.sharma@example.com',
                  required: true,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: const Icon(Icons.email_outlined),
                  validator: (val) {
                    final trimmed = val?.trim() ?? '';
                    if (trimmed.isEmpty) {
                      return 'Please enter your email address';
                    }
                    if (!trimmed.contains('@') || !trimmed.contains('.')) {
                      return 'Enter a valid email address';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Password
                CustomTextField(
                  controller: passwordController,
                  label: 'Create Password',
                  hint: 'At least 6 characters',
                  required: true,
                  obscureText: _obscurePassword,
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                  validator: (val) {
                    if (val == null || val.trim().length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Date of Birth
                CustomTextField(
                  controller: dobController,
                  label: 'Date of Birth',
                  hint: 'DD/MM/YYYY',
                  required: true,
                  readOnly: true,
                  onTap: _selectDateOfBirth,
                  prefixIcon: const Icon(Icons.cake_outlined),
                  suffixIcon: const Icon(Icons.calendar_month),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please select your date of birth';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Gender Dropdown
                _buildDropdownLabel('Gender', required: true),
                DropdownButtonFormField<String>(
                  initialValue: selectedGender,
                  decoration: const InputDecoration(),
                  items: const [
                    DropdownMenuItem(value: 'Male', child: Text('Male')),
                    DropdownMenuItem(value: 'Female', child: Text('Female')),
                    DropdownMenuItem(value: 'Other', child: Text('Other')),
                  ],
                  onChanged: (val) => setState(() => selectedGender = val),
                  validator: (val) => val == null ? 'Select gender' : null,
                ),

                const SizedBox(height: 16),

                // Qualification Dropdown
                _buildDropdownLabel('Highest Educational Qualification', required: true),
                DropdownButtonFormField<String>(
                  initialValue: selectedQualification,
                  decoration: const InputDecoration(),
                  items: const [
                    DropdownMenuItem(value: 'Post Graduate', child: Text('Post Graduate / Master\'s')),
                    DropdownMenuItem(value: 'Degree', child: Text('Degree / Graduation')),
                    DropdownMenuItem(value: 'Diploma', child: Text('Polytechnic / Diploma')),
                    DropdownMenuItem(value: 'Plus Two / 12th', child: Text('Plus Two / 12th Pass')),
                    DropdownMenuItem(value: 'SSLC / 10th Pass', child: Text('SSLC / 10th Pass')),
                  ],
                  onChanged: (val) {
                    setState(() {
                      selectedQualification = val;
                      final courses = qualificationCourses[val] ?? ['Other'];
                      selectedCourse = courses.contains(selectedCourse) ? selectedCourse : courses.first;
                    });
                  },
                ),

                const SizedBox(height: 16),

                // Course / Degree Dynamic Dropdown
                _buildDropdownLabel('Course / Degree Discipline', required: true),
                DropdownButtonFormField<String>(
                  initialValue: availableCourses.contains(selectedCourse) ? selectedCourse : availableCourses.first,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.school_outlined),
                  ),
                  isExpanded: true,
                  items: availableCourses.map((c) {
                    return DropdownMenuItem<String>(
                      value: c,
                      child: Text(
                        c,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: c == 'Other' ? FontWeight.bold : FontWeight.normal,
                          color: c == 'Other' ? theme.colorScheme.primary : null,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      selectedCourse = val;
                    });
                  },
                ),

                // Additional Text Field if "Other" is selected
                if (selectedCourse == 'Other') ...[
                  const SizedBox(height: 14),
                  CustomTextField(
                    controller: otherCourseController,
                    label: 'Specify Your Course / Degree',
                    hint: 'e.g. B.Tech Artificial Intelligence, B.Sc Forensic Science',
                    required: true,
                    prefixIcon: const Icon(Icons.edit_note_outlined),
                    validator: (val) {
                      if (selectedCourse == 'Other' && (val == null || val.trim().isEmpty)) {
                        return 'Please enter your course/degree name';
                      }
                      return null;
                    },
                  ),
                ],

                const SizedBox(height: 16),

                // Year of Passing
                CustomTextField(
                  controller: yearController,
                  label: 'Year of Passing',
                  hint: 'e.g. 2025',
                  required: true,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  prefixIcon: const Icon(Icons.date_range_outlined),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter year of passing';
                    }
                    if (val.length != 4) {
                      return 'Enter a 4-digit year (e.g. 2025)';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Category Dropdown
                _buildDropdownLabel('Reservation Category', required: true),
                DropdownButtonFormField<String>(
                  initialValue: selectedCategory,
                  decoration: const InputDecoration(),
                  items: const [
                    DropdownMenuItem(value: 'General', child: Text('General / Unreserved (UR)')),
                    DropdownMenuItem(value: 'OBC', child: Text('OBC (Other Backward Classes)')),
                    DropdownMenuItem(value: 'SC', child: Text('SC (Scheduled Castes)')),
                    DropdownMenuItem(value: 'ST', child: Text('ST (Scheduled Tribes)')),
                    DropdownMenuItem(value: 'EWS', child: Text('EWS (Economically Weaker Section)')),
                  ],
                  onChanged: (val) => setState(() => selectedCategory = val),
                ),

                const SizedBox(height: 16),

                // State Dropdown
                _buildDropdownLabel('State of Domicile', required: true),
                DropdownButtonFormField<String>(
                  initialValue: selectedState,
                  decoration: const InputDecoration(),
                  items: _stateDistricts.keys.map((st) {
                    return DropdownMenuItem(value: st, child: Text(st));
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      selectedState = val;
                      selectedDistrict = _stateDistricts[val]?.first ?? 'General';
                    });
                  },
                ),

                const SizedBox(height: 16),

                // District Dropdown
                _buildDropdownLabel('District', required: true),
                DropdownButtonFormField<String>(
                  initialValue: availableDistricts.contains(selectedDistrict)
                      ? selectedDistrict
                      : availableDistricts.first,
                  decoration: const InputDecoration(),
                  items: availableDistricts.map((dist) {
                    return DropdownMenuItem(value: dist, child: Text(dist));
                  }).toList(),
                  onChanged: (val) => setState(() => selectedDistrict = val),
                ),

                const SizedBox(height: 32),

                // Create Account Button
                CustomButton(
                  text: 'Create Account & Continue',
                  isLoading: _isLoading,
                  onPressed: _registerUser,
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownLabel(String label, {bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          if (required)
            const Text(
              ' *',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
        ],
      ),
    );
  }
}