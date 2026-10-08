import 'package:flutter/material.dart';
import '../models/job.dart';
import '../models/notification.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/session_storage_service.dart';

enum AuthRole { none, user }

class AppState extends ChangeNotifier {
  User? _currentUser;
  AuthRole _currentRole = AuthRole.none;

  List<Job> _jobs = const [
    Job(
      id: 'kpsc_151_2026',
      title: 'Draftsman Grade II (Cat. No. 151/2026)',
      organization: 'Kerala Public Service Commission',
      department: 'Kerala Ports service (Hydrographic Survey Wing)',
      jobType: 'State Govt',
      location: 'Kerala (Statewide)',
      vacancies: '2 (Two)',
      qualification: 'Diploma in Civil / Mechanical Engineering',
      courseRequirements: 'Diploma in Civil or Mechanical Engineering from Kerala Govt. or Pass in SSLC & NTC Draftsman',
      ageMin: 18,
      ageMax: 40,
      category: 'General / OBC / SC-ST',
      experience: 'Fresher eligible',
      applicationStartDate: '30-09-2026',
      lastDate: '04-11-2026',
      applicationFee: 'Free (Kerala PSC One Time Registration)',
      selectionProcess: 'Direct Recruitment, OMR / Online Exam, Verification',
      salary: '₹ 31,100 – 66,800/-',
      description: 'Applications are invited online through One Time Registration from qualified candidates for appointment to Draftsman Grade II in Kerala Ports service (Hydrographic Survey Wing).',
      officialNotificationUrl: 'https://www.keralapsc.gov.in/sites/default/files/2026-09/noti-151-26.pdf',
      applyUrl: 'https://thulasi.psc.kerala.gov.in/thulasi/',
    ),
    Job(
      id: 'kpsc_152_2026',
      title: 'Peon / Watchman (Cat. No. 152/2026)',
      organization: 'Kerala Public Service Commission',
      department: 'Kerala State Financial Enterprises (KSFE Ltd.)',
      jobType: 'State Govt',
      location: 'Kerala (Statewide)',
      vacancies: 'Anticipated Vacancies',
      qualification: 'Pass in Standard VI (6th) or equivalent',
      courseRequirements: 'Pass in Standard VI (New) or equivalent from recognized school',
      ageMin: 18,
      ageMax: 40,
      category: 'General / OBC / SC-ST',
      experience: 'Part-Time Employees in KSFE Ltd.',
      applicationStartDate: '30-09-2026',
      lastDate: '04-11-2026',
      applicationFee: 'Free (Kerala PSC One Time Registration)',
      selectionProcess: 'Direct Recruitment, Written Examination, Verification',
      salary: '₹ 24,500 – 42,900/-',
      description: 'Direct Recruitment from among eligible candidates for Peon/Watchman in Kerala State Financial Enterprises Ltd.',
      officialNotificationUrl: 'https://www.keralapsc.gov.in/sites/default/files/2026-09/noti-152-26.pdf',
      applyUrl: 'https://thulasi.psc.kerala.gov.in/thulasi/',
    ),
    Job(
      id: 'kpsc_153_2026',
      title: 'Forest Boat Driver (Cat. No. 153/2026)',
      organization: 'Kerala Public Service Commission',
      department: 'Forest & Wildlife Department',
      jobType: 'State Govt',
      location: 'Kerala (Statewide)',
      vacancies: 'Anticipated Vacancies',
      qualification: 'SSLC / 10th Standard + Boat Driver Licence',
      courseRequirements: 'Pass in SSLC & possession of valid Boat Driver Certificate issued by competent authority',
      ageMin: 19,
      ageMax: 36,
      category: 'General / OBC / SC-ST',
      experience: 'Valid Boat Driving experience',
      applicationStartDate: '30-09-2026',
      lastDate: '04-11-2026',
      applicationFee: 'Free (Kerala PSC One Time Registration)',
      selectionProcess: 'Practical Test (Boat Driving), OMR Exam, Medical Standard',
      salary: '₹ 26,500 – 60,700/-',
      description: 'Kerala Public Service Commission invites applications for Forest Boat Driver in Forest and Wildlife department.',
      officialNotificationUrl: 'https://www.keralapsc.gov.in/sites/default/files/2026-09/noti-153-26.pdf',
      applyUrl: 'https://thulasi.psc.kerala.gov.in/thulasi/',
    ),
    Job(
      id: 'kpsc_154_2026',
      title: 'Forest Boat Driver (By Transfer) (Cat. No. 154/2026)',
      organization: 'Kerala Public Service Commission',
      department: 'Forest & Wildlife Department',
      jobType: 'State Govt',
      location: 'Kerala (Statewide)',
      vacancies: 'By Transfer Vacancies',
      qualification: 'SSLC / 10th Standard + Boat Driver Certificate',
      courseRequirements: 'Must be an approved probationer or full member in Last Grade Service with Boat Driving Certificate',
      ageMin: 19,
      ageMax: 45,
      category: 'Departmental (By Transfer)',
      experience: 'Last Grade Service in Forest Dept',
      applicationStartDate: '30-09-2026',
      lastDate: '04-11-2026',
      applicationFee: 'Free (Kerala PSC One Time Registration)',
      selectionProcess: 'Practical Test, Verification',
      salary: '₹ 26,500 – 60,700/-',
      description: 'Recruitment By Transfer from qualified Last Grade employees in Forest & Wildlife Department.',
      officialNotificationUrl: 'https://www.keralapsc.gov.in/sites/default/files/2026-09/noti-154-26.pdf',
      applyUrl: 'https://thulasi.psc.kerala.gov.in/thulasi/',
    ),
    Job(
      id: 'kpsc_155_2026',
      title: 'Higher Secondary School Teacher - Statistics (Cat. No. 155/2026)',
      organization: 'Kerala Public Service Commission',
      department: 'Kerala Higher Secondary Education (SR for ST)',
      jobType: 'State Govt',
      location: 'Kerala (Statewide)',
      vacancies: 'Special Recruitment (ST Only)',
      qualification: "Master's Degree in Statistics + B.Ed + SET",
      courseRequirements: "Master's Degree in Statistics with minimum 50% marks, B.Ed and State Eligibility Test (SET)",
      ageMin: 20,
      ageMax: 45,
      category: 'Scheduled Tribe (ST) Only',
      experience: 'Fresher eligible',
      applicationStartDate: '30-09-2026',
      lastDate: '04-11-2026',
      applicationFee: 'Free (Kerala PSC One Time Registration)',
      selectionProcess: 'Online / OMR Examination, Document Verification',
      salary: '₹ 55,200 – 1,15,300/-',
      description: 'Special Recruitment for Scheduled Tribe candidates for Higher Secondary School Teacher (HSST Statistics).',
      officialNotificationUrl: 'https://www.keralapsc.gov.in/sites/default/files/2026-09/noti-155-26.pdf',
      applyUrl: 'https://thulasi.psc.kerala.gov.in/thulasi/',
    ),
    Job(
      id: 'kpsc_156_2026',
      title: 'Draftsman Grade II / Town Planning Surveyor (Cat. No. 156/2026)',
      organization: 'Kerala Public Service Commission',
      department: 'Local Self Government Department (LSGD)',
      jobType: 'State Govt',
      location: 'Kerala (Statewide)',
      vacancies: 'Special Recruitment for SC/ST',
      qualification: 'Diploma in Civil / Architectural Engineering',
      courseRequirements: 'Diploma in Civil Engineering / Town Planning or NTC Certificate in Draftsman Civil',
      ageMin: 18,
      ageMax: 41,
      category: 'Special Recruitment for SC/ST',
      experience: 'Fresher eligible',
      applicationStartDate: '30-09-2026',
      lastDate: '04-11-2026',
      applicationFee: 'Free (Kerala PSC One Time Registration)',
      selectionProcess: 'Written / OMR Exam, Verification',
      salary: '₹ 31,100 – 66,800/-',
      description: 'Recruitment to Draftsman Grade II / Town Planning Surveyor Grade II in LSGD Planning Wing.',
      officialNotificationUrl: 'https://www.keralapsc.gov.in/sites/default/files/2026-09/noti-156-26.pdf',
      applyUrl: 'https://thulasi.psc.kerala.gov.in/thulasi/',
    ),
    Job(
      id: 'kpsc_157_2026',
      title: 'Higher Secondary School Teacher (Junior) Arabic (Cat. No. 157/2026)',
      organization: 'Kerala Public Service Commission',
      department: 'Kerala Higher Secondary Education',
      jobType: 'State Govt',
      location: 'Kerala (Statewide)',
      vacancies: 'Anticipated Vacancies',
      qualification: "Master's Degree in Arabic + B.Ed + SET",
      courseRequirements: "Master's Degree in Arabic with min 50% marks, B.Ed and State Eligibility Test (SET)",
      ageMin: 20,
      ageMax: 40,
      category: 'General / OBC / SC-ST',
      experience: 'Fresher eligible',
      applicationStartDate: '30-09-2026',
      lastDate: '04-11-2026',
      applicationFee: 'Free (Kerala PSC One Time Registration)',
      selectionProcess: 'OMR Examination, Interview, Document Verification',
      salary: '₹ 45,600 – 95,600/-',
      description: 'Direct Recruitment for Higher Secondary School Teacher (Junior) Arabic under Higher Secondary Education.',
      officialNotificationUrl: 'https://www.keralapsc.gov.in/sites/default/files/2026-09/noti-157-158-26.pdf',
      applyUrl: 'https://thulasi.psc.kerala.gov.in/thulasi/',
    ),
    Job(
      id: 'kpsc_159_2026',
      title: 'Police Constable Driver (Cat. No. 159/2026)',
      organization: 'Kerala Public Service Commission',
      department: 'Kerala Police Department (NCA LC/AI)',
      jobType: 'State Govt',
      location: 'Kerala (Statewide)',
      vacancies: 'NCA Vacancies (LC/AI)',
      qualification: 'Pass in SSLC / 10th + HVD Licence + Badge',
      courseRequirements: 'Pass in SSLC and valid Heavy Vehicle Driving Licence with Badge',
      ageMin: 18,
      ageMax: 39,
      category: 'Latin Catholic / Anglo Indian (LC/AI)',
      experience: 'Driving Experience with Heavy Vehicles',
      applicationStartDate: '30-09-2026',
      lastDate: '04-11-2026',
      applicationFee: 'Free (Kerala PSC One Time Registration)',
      selectionProcess: 'Physical Efficiency Test, Practical Driving Test, OMR Exam',
      salary: '₹ 31,100 – 66,800/-',
      description: 'NCA Recruitment for Police Constable Driver / Woman Police Constable Driver in Kerala Police.',
      officialNotificationUrl: 'https://www.keralapsc.gov.in/sites/default/files/2026-09/noti-159-26.pdf',
      applyUrl: 'https://thulasi.psc.kerala.gov.in/thulasi/',
    ),
    Job(
      id: 'kpsc_160_2026',
      title: 'Peon / Watchman (PT Employees) (Cat. No. 160/2026)',
      organization: 'Kerala Public Service Commission',
      department: 'KSFE Ltd. (IV NCA-ST)',
      jobType: 'State Govt',
      location: 'Kerala (Statewide)',
      vacancies: '1 (NCA-ST)',
      qualification: 'Pass in Standard VI (6th) or equivalent',
      courseRequirements: 'Pass in Standard VI (New) or equivalent from recognized school',
      ageMin: 18,
      ageMax: 50,
      category: 'Scheduled Tribe (ST) Only',
      experience: 'Part-Time Employees in KSFE Ltd.',
      applicationStartDate: '30-09-2026',
      lastDate: '04-11-2026',
      applicationFee: 'Free (Kerala PSC One Time Registration)',
      selectionProcess: 'Written / OMR Examination, Verification',
      salary: '₹ 24,500 – 42,900/-',
      description: 'IV NCA Recruitment from among Part-Time Employees in KSFE Ltd belonging to ST category.',
      officialNotificationUrl: 'https://www.keralapsc.gov.in/sites/default/files/2026-09/noti-160-26.pdf',
      applyUrl: 'https://thulasi.psc.kerala.gov.in/thulasi/',
    ),
    Job(
      id: 'kpsc_161_2026',
      title: 'Peon / Watchman (PT Employees) (Cat. No. 161/2026)',
      organization: 'Kerala Public Service Commission',
      department: 'KSFE Ltd. (VIII NCA-ST)',
      jobType: 'State Govt',
      location: 'Kerala (Statewide)',
      vacancies: '1 (NCA-ST)',
      qualification: 'Pass in Standard VI (6th) or equivalent',
      courseRequirements: 'Pass in Standard VI (New) or equivalent from recognized school',
      ageMin: 18,
      ageMax: 50,
      category: 'Scheduled Tribe (ST) Only',
      experience: 'Part-Time Employees in KSFE Ltd.',
      applicationStartDate: '30-09-2026',
      lastDate: '04-11-2026',
      applicationFee: 'Free (Kerala PSC One Time Registration)',
      selectionProcess: 'Written / OMR Examination, Verification',
      salary: '₹ 24,500 – 42,900/-',
      description: 'VIII NCA Recruitment from among Part-Time Employees in KSFE Ltd belonging to ST category.',
      officialNotificationUrl: 'https://www.keralapsc.gov.in/sites/default/files/2026-09/noti-161-26.pdf',
      applyUrl: 'https://thulasi.psc.kerala.gov.in/thulasi/',
    ),
    Job(
      id: 'ssc_cgle_2026',
      title: 'Combined Graduate Level Exam 2026',
      organization: 'Staff Selection Commission',
      department: 'Central Region (SSCCR)',
      jobType: 'Central Govt',
      location: 'All India',
      vacancies: 'As per official notification',
      qualification: 'Any Degree / Graduation',
      courseRequirements: 'Bachelor Degree in any discipline from a recognized University',
      ageMin: 18,
      ageMax: 32,
      category: 'General / OBC / SC / ST / EWS',
      experience: 'Fresher eligible',
      applicationStartDate: '25-09-2026',
      lastDate: '25-10-2026',
      applicationFee: '₹ 100 (Women / SC / ST / PwD / ESM Exempted)',
      selectionProcess: 'Tier-I (CBE) & Tier-II (CBE) Examinations',
      salary: 'Level-4 to Level-8 (₹ 25,500 – 1,51,100/-)',
      description: 'Staff Selection Commission notice for Combined Graduate Level Examination (CGLE) 2026 for recruitment to Group B and Group C posts in various Ministries and Departments.',
      officialNotificationUrl: 'https://ssccr.gov.in/api/media/file/Important%20Notice-%20CGLE%202026-1.pdf',
      applyUrl: 'https://ssc.gov.in',
    ),
    Job(
      id: 'ssc_cr13324_je',
      title: 'Post Code CR13324 - Junior Engineer (Quality Assurance) Radar & System',
      organization: 'Staff Selection Commission',
      department: 'Central Region (SSCCR)',
      jobType: 'Central Govt',
      location: 'All India',
      vacancies: 'As per notification',
      qualification: 'Diploma / Degree in Engineering',
      courseRequirements: 'Degree / Diploma in Electronics / Radar / Systems Engineering',
      ageMin: 18,
      ageMax: 30,
      category: 'General / OBC / SC / ST',
      experience: 'Fresher / Experienced',
      applicationStartDate: '25-09-2026',
      lastDate: '25-10-2026',
      applicationFee: '₹ 100 (Exempted for Women/SC/ST)',
      selectionProcess: 'Computer Based Examination (CBE), Skill Test, Document Verification',
      salary: 'Level-6 (₹ 35,400 – 1,12,400/-)',
      description: 'Recruitment for Junior Engineer (QA) Radar & System under Staff Selection Commission Central Region.',
      officialNotificationUrl: 'https://ssccr.gov.in/api/media/file/CR13324%20(1)-1.pdf',
      applyUrl: 'https://ssc.gov.in',
    ),
    Job(
      id: 'ssc_cr12624_je',
      title: 'Post Code CR12624 - Junior Engineer (Quality Assurance) Armament - Small Arms',
      organization: 'Staff Selection Commission',
      department: 'Central Region (SSCCR)',
      jobType: 'Central Govt',
      location: 'All India',
      vacancies: 'As per notification',
      qualification: 'Diploma / Degree in Mechanical / Production Engg',
      courseRequirements: 'Diploma or Degree in Mechanical / Production / Armament Engineering',
      ageMin: 18,
      ageMax: 30,
      category: 'General / OBC / SC / ST',
      experience: 'Fresher / Experienced',
      applicationStartDate: '25-09-2026',
      lastDate: '25-10-2026',
      applicationFee: '₹ 100 (Exempted for Women/SC/ST)',
      selectionProcess: 'Computer Based Examination (CBE), Verification',
      salary: 'Level-6 (₹ 35,400 – 1,12,400/-)',
      description: 'Junior Engineer (QA) Armament Small Arms recruitment by Staff Selection Commission Central Region.',
      officialNotificationUrl: 'https://ssccr.gov.in/api/media/file/CR12624%20(1)-1.pdf',
      applyUrl: 'https://ssc.gov.in',
    ),
    Job(
      id: 'ssc_cr11524_pharm',
      title: 'Post Code CR11524 - Pharmacist (Allopathic)',
      organization: 'Staff Selection Commission',
      department: 'Central Region (SSCCR)',
      jobType: 'Central Govt',
      location: 'All India',
      vacancies: 'As per notification',
      qualification: 'Diploma / Degree in Pharmacy (D.Pharm / B.Pharm)',
      courseRequirements: 'Pass in 12th with Science and Diploma in Pharmacy from recognized institution',
      ageMin: 18,
      ageMax: 30,
      category: 'General / OBC / SC / ST',
      experience: 'Registered Pharmacist with Pharmacy Council',
      applicationStartDate: '25-09-2026',
      lastDate: '25-10-2026',
      applicationFee: '₹ 100 (Exempted for Women/SC/ST)',
      selectionProcess: 'Computer Based Examination (CBE), Document Verification',
      salary: 'Level-5 (₹ 29,200 – 92,300/-)',
      description: 'Pharmacist (Allopathic) vacancy notification under Staff Selection Commission Central Region.',
      officialNotificationUrl: 'https://ssccr.gov.in/api/media/file/CR11524%20(2)-2.pdf',
      applyUrl: 'https://ssc.gov.in',
    ),
    Job(
      id: 'ssc_cr10224_mts',
      title: 'Post Code CR10224 - Multi Tasking Staff (MTS)',
      organization: 'Staff Selection Commission',
      department: 'Central Region (SSCCR)',
      jobType: 'Central Govt',
      location: 'All India',
      vacancies: 'As per notification',
      qualification: 'Matriculation / 10th Standard Pass',
      courseRequirements: 'Pass in 10th / Matriculation from recognized Board',
      ageMin: 18,
      ageMax: 27,
      category: 'General / OBC / SC / ST / EWS',
      experience: 'Fresher eligible',
      applicationStartDate: '25-09-2026',
      lastDate: '25-10-2026',
      applicationFee: '₹ 100 (Exempted for Women/SC/ST/PwD)',
      selectionProcess: 'Computer Based Examination (CBE)',
      salary: 'Level-1 (₹ 18,000 – 56,900/-)',
      description: 'Multi Tasking Staff (Non-Technical) recruitment by Staff Selection Commission Central Region.',
      officialNotificationUrl: 'https://ssccr.gov.in/api/media/file/CR10224%20(1)-3.pdf',
      applyUrl: 'https://ssc.gov.in',
    ),
  ];
  final Set<String> _savedJobIds = {};
  List<JobNotification> _notifications = [];

  bool _isDarkMode = false;
  bool _isLoading = false;

  // Settings preferences
  bool _pushNotificationsEnabled = true;
  bool _eligibleAlertsOnly = true;
  bool _deadlineReminders = true;
  String _selectedLanguage = 'English';

  AppState() {
    // Initial async sync with backend and restore session
    initSession();
    syncWithBackend();
  }

  /// Restore saved session, theme, and saved jobs on app boot
  Future<void> initSession() async {
    try {
      final savedDark = await SessionStorageService.instance.getThemeMode();
      if (savedDark != null) {
        _isDarkMode = savedDark;
      }

      final savedBookmarks = await SessionStorageService.instance.getBookmarkedJobIds();
      if (savedBookmarks.isNotEmpty) {
        _savedJobIds.clear();
        _savedJobIds.addAll(savedBookmarks);
      }

      final session = await SessionStorageService.instance.getSession();
      if (session != null) {
        final token = session['token'] as String?;
        final userData = session['userData'] as Map<String, dynamic>?;

        if (token != null && token.isNotEmpty) {
          ApiService.instance.authToken = token;

          if (userData != null) {
            _currentUser = User.fromJson(userData);
            _currentRole = AuthRole.user;
          }
        }
      }
    } catch (e) {
      debugPrint('initSession error: $e');
    } finally {
      notifyListeners();
    }
  }

  // Getters
  User? get currentUser => _currentUser;
  AuthRole get currentRole => _currentRole;
  bool get isLoading => _isLoading;

  List<Job> get jobs => List.unmodifiable(_jobs);
  Set<String> get savedJobIds => Set.unmodifiable(_savedJobIds);
  List<JobNotification> get notifications => List.unmodifiable(_notifications);

  bool get isDarkMode => _isDarkMode;
  bool get pushNotificationsEnabled => _pushNotificationsEnabled;
  bool get eligibleAlertsOnly => _eligibleAlertsOnly;
  bool get deadlineReminders => _deadlineReminders;
  String get selectedLanguage => _selectedLanguage;

  int get unreadNotificationCount =>
      _notifications.where((n) => !n.isRead).length;

  List<Job> get savedJobs =>
      _jobs.where((j) => _savedJobIds.contains(j.id)).toList();

  List<Job> get eligibleJobs {
    if (_currentUser == null) return _jobs;
    return _jobs.where((j) => j.checkEligibility(_currentUser).isEligible).toList();
  }

  Job? getJobById(String id) {
    try {
      return _jobs.firstWhere((j) => j.id == id);
    } catch (_) {
      return null;
    }
  }

  bool isJobSaved(String jobId) => _savedJobIds.contains(jobId);

  /// Synchronize jobs and notifications with backend MongoDB APIs
  Future<void> syncWithBackend() async {
    _isLoading = true;
    notifyListeners();

    try {
      final fetchedJobs = await ApiService.instance.fetchJobs();
      if (fetchedJobs.isNotEmpty) {
        _jobs = fetchedJobs;
      }

      try {
        final notifs = await ApiService.instance.fetchNotifications();
        if (notifs.isNotEmpty) _notifications = notifs;
      } catch (_) {}
    } catch (e) {
      debugPrint('SyncWithBackend fallback: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Authentication Actions

  /// Send system auto-generated 6-digit OTP code to candidate email
  Future<Map<String, dynamic>?> sendEmailOtp(String email) async {
    return await ApiService.instance.sendEmailOtp(email.trim().toLowerCase());
  }

  /// Verify system auto-generated OTP code against backend
  Future<Map<String, dynamic>?> verifyEmailOtp(String email, String otp) async {
    final res = await ApiService.instance.verifyEmailOtp(email.trim().toLowerCase(), otp.trim());
    if (res != null && res['success'] == true) {
      final token = res['token'] ?? ApiService.instance.authToken ?? '';
      if (res['user'] != null) {
        _currentUser = User.fromJson(res['user']);
        _currentRole = AuthRole.user;
        await SessionStorageService.instance.saveSession(
          token: token,
          userData: res['user'],
        );
        await SessionStorageService.instance.saveLastIdentifier(email);
        notifyListeners();
      }
      return res;
    }
    return null;
  }

  /// Email / Username + Password login with backend REST API integration
  Future<AuthRole> loginWithCredentialsAsync(String identifier, String password) async {
    final result = await loginDetailedAsync(identifier, password);
    return result['role'] as AuthRole? ?? AuthRole.none;
  }

  /// Detailed login method returning explicit notRegistered status and message
  Future<Map<String, dynamic>> loginDetailedAsync(String identifier, String password) async {
    final id = identifier.trim().toLowerCase();
    final p = password.trim();

    // 1. Attempt login via REST API
    final res = await ApiService.instance.login(identifier: id, password: p);
    if (res != null) {
      if (res['success'] == true && res['user'] != null) {
        final token = res['token'] ?? ApiService.instance.authToken ?? '';
        _currentRole = AuthRole.user;
        _currentUser = User.fromJson(res['user']);
        await SessionStorageService.instance.saveSession(
          token: token,
          userData: res['user'],
        );
        await SessionStorageService.instance.saveLastIdentifier(id);
        notifyListeners();
        return {'success': true, 'role': AuthRole.user, 'message': 'Login successful'};
      }

      // Check if server indicated notRegistered
      if (res['notRegistered'] == true) {
        return {
          'success': false,
          'role': AuthRole.none,
          'notRegistered': true,
          'message': res['message'] ?? 'This email is not registered. Please register first.',
        };
      }

      return {
        'success': false,
        'role': AuthRole.none,
        'notRegistered': false,
        'message': res['message'] ?? 'Invalid credentials.',
      };
    }

    return {
      'success': false,
      'role': AuthRole.none,
      'notRegistered': true,
      'message': 'No account found with this email address. Please register first.',
    };
  }

  /// Send Password Reset OTP Code to email
  Future<Map<String, dynamic>?> forgotPasswordAsync(String email) async {
    return await ApiService.instance.forgotPassword(email);
  }

  /// Verify OTP and reset password
  Future<Map<String, dynamic>?> resetPasswordAsync({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    return await ApiService.instance.resetPassword(
      email: email,
      otp: otp,
      newPassword: newPassword,
    );
  }

  Future<void> registerUserAsync(Map<String, dynamic> data) async {
    final res = await ApiService.instance.registerUser(data);
    if (res != null && res['user'] != null) {
      _currentUser = res['user'] as User;
      _currentRole = AuthRole.user;
      final token = res['token'] ?? ApiService.instance.authToken ?? '';
      await SessionStorageService.instance.saveSession(
        token: token,
        userData: _currentUser!.toJson(),
      );
      if (data['email'] != null) {
        await SessionStorageService.instance.saveLastIdentifier(data['email'].toString());
      }
      notifyListeners();
    }
  }

  void registerUser(User user) {
    _currentUser = user;
    _currentRole = AuthRole.user;
    notifyListeners();
  }

  Future<void> updateProfileAsync(User user) async {
    _currentUser = user;
    notifyListeners();
    await SessionStorageService.instance.saveUserData(user.toJson());
    await ApiService.instance.updateUserProfile(user.id, user.toJson());
  }

  void updateProfile(User user) {
    _currentUser = user;
    SessionStorageService.instance.saveUserData(user.toJson());
    notifyListeners();
  }

  void logout() {
    _currentUser = null;
    _currentRole = AuthRole.none;
    ApiService.instance.authToken = null;
    SessionStorageService.instance.clearSession();
    notifyListeners();
  }

  // Bookmarking / Saved Jobs
  void toggleSaveJob(String jobId) {
    if (_savedJobIds.contains(jobId)) {
      _savedJobIds.remove(jobId);
    } else {
      _savedJobIds.add(jobId);
    }
    SessionStorageService.instance.saveBookmarkedJobIds(_savedJobIds.toList());
    notifyListeners();
  }

  // Notifications
  void markNotificationAsRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      notifyListeners();
    }
  }

  void markAllNotificationsAsRead() {
    for (int i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(isRead: true);
    }
    ApiService.instance.markAllNotificationsRead();
    notifyListeners();
  }

  void deleteNotification(String id) {
    _notifications.removeWhere((n) => n.id == id);
    notifyListeners();
  }

  // Settings
  void toggleTheme(bool isDark) {
    _isDarkMode = isDark;
    SessionStorageService.instance.saveThemeMode(isDark);
    notifyListeners();
  }

  void setPushNotifications(bool val) {
    _pushNotificationsEnabled = val;
    notifyListeners();
  }

  void setEligibleAlertsOnly(bool val) {
    _eligibleAlertsOnly = val;
    notifyListeners();
  }

  void setDeadlineReminders(bool val) {
    _deadlineReminders = val;
    notifyListeners();
  }

  void setLanguage(String lang) {
    _selectedLanguage = lang;
    notifyListeners();
  }
}

// Global shared instance for the app
final AppState appState = AppState();
