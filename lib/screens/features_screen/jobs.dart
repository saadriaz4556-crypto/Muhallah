import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../features/jobs/models/job_model.dart';
import '../../features/jobs/models/job_application_model.dart';
import '../../features/jobs/services/job_application_service.dart';
import 'job_applications_screen.dart';

// --- THEME COLORS ---
const Color bgDeepNavy = Color(0xFF252A34);
const Color accentTeal = Color(0xFF08D9D6);
const Color dangerCoral = Color(0xFFFF2E63);
const Color lightText = Color(0xFFEAEAEA);
const Color successGreen = Color(0xFF4CAF50);
const Color warningOrange = Color(0xFFFF9800);
const Color cardBg = Color(0xFF333947);

// ==========================================
// ENTRY POINT
// ==========================================
class JobsApp extends StatelessWidget {
  const JobsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: bgDeepNavy,
        appBarTheme: const AppBarTheme(
          backgroundColor: bgDeepNavy,
          elevation: 0,
          centerTitle: true,
        ),
        colorScheme: const ColorScheme.dark(
          primary: accentTeal,
          secondary: accentTeal,
          surface: bgDeepNavy,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: accentTeal,
        ),
      ),
      child: const JobsHomeScreen(),
    );
  }
}

// ==========================================
// HOME SCREEN
// ==========================================
class JobsHomeScreen extends StatefulWidget {
  const JobsHomeScreen({super.key});

  @override
  State<JobsHomeScreen> createState() => _JobsHomeScreenState();
}

class _JobsHomeScreenState extends State<JobsHomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jobs 💼'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: accentTeal,
          labelColor: accentTeal,
          unselectedLabelColor: lightText,
          tabs: const [
            Tab(text: "Browse Jobs"),
            Tab(text: "My Applications"),
            Tab(text: "Posted by Me"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          BrowseJobsTab(),
          MyApplicationsScreen(),
          PostedJobsScreen(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PostJobScreen()),
          );
        },
        icon: const Icon(Icons.add, color: bgDeepNavy),
        label: const Text(
          "Post a Job",
          style: TextStyle(color: bgDeepNavy, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

// ==========================================
// TAB 1: BROWSE JOBS
// ==========================================
class BrowseJobsTab extends StatefulWidget {
  const BrowseJobsTab({super.key});

  @override
  State<BrowseJobsTab> createState() => _BrowseJobsTabState();
}

class _BrowseJobsTabState extends State<BrowseJobsTab> {
  String _searchQuery = '';
  String _selectedType = 'All';

  final List<String> _filters = ['All', 'Full-time', 'Part-time', 'Freelance'];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search & Filter
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                onChanged: (val) =>
                    setState(() => _searchQuery = val.toLowerCase()),
                style: const TextStyle(color: lightText),
                decoration: InputDecoration(
                  hintText: 'Search jobs...',
                  hintStyle: const TextStyle(color: Colors.white54),
                  prefixIcon: const Icon(Icons.search, color: accentTeal),
                  filled: true,
                  fillColor: cardBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _filters.map((filter) {
                    final isSelected = _selectedType == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(filter),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) setState(() => _selectedType = filter);
                        },
                        selectedColor: accentTeal,
                        backgroundColor: cardBg,
                        labelStyle: TextStyle(
                          color: isSelected ? bgDeepNavy : lightText,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),

        // List
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('jobs')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              print('Snapshot state: ${snapshot.connectionState}');
              print('Has data: ${snapshot.hasData}');
              print('Data length: ${snapshot.data?.docs.length}');
              print('Error: ${snapshot.error}');

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF08D9D6),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.work_off, color: Color(0xFF08D9D6), size: 64),
                      SizedBox(height: 16),
                      Text(
                        'No jobs available yet',
                        style: TextStyle(color: Color(0xFFEAEAEA)),
                      ),
                      Text(
                        'Be the first to post a job!',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              final docs = snapshot.data!.docs;
              final jobs = docs
                  .map((d) =>
                      JobModel.fromMap(d.data() as Map<String, dynamic>, d.id))
                  .where((job) {
                final matchesSearch =
                    job.jobTitle.toLowerCase().contains(_searchQuery) ||
                        job.company.toLowerCase().contains(_searchQuery);
                final matchesType =
                    _selectedType == 'All' || job.jobType == _selectedType;
                return matchesSearch && matchesType;
              }).toList();

              if (jobs.isEmpty) {
                return const Center(
                    child: Text('No jobs match your criteria.'));
              }

              return ListView.builder(
                itemCount: jobs.length,
                padding: const EdgeInsets.symmetric(horizontal: 0),
                itemBuilder: (context, index) {
                  final job = jobs[index];
                  return JobCard(
                    job: job,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => JobDetailScreen(job: job),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// ==========================================
// WIDGET: JOB CARD
// ==========================================
class JobCard extends StatelessWidget {
  final JobModel job;
  final VoidCallback onTap;

  const JobCard({super.key, required this.job, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF1A1F2E),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              job.jobTitle,
              style: const TextStyle(
                color: Color(0xFFEAEAEA),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              job.company,
              style: const TextStyle(color: Color(0xFF08D9D6)),
            ),
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.location_on, color: Colors.grey, size: 16),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  job.location,
                  style: const TextStyle(color: Colors.grey),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF08D9D6).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  job.jobType,
                  style: const TextStyle(color: Color(0xFF08D9D6)),
                ),
              ),
            ]),
            const SizedBox(height: 8),
            Text(
              'Salary: ${job.salary}',
              style: const TextStyle(color: Color(0xFFEAEAEA)),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF08D9D6),
                ),
                onPressed: onTap,
                child: const Text(
                  'View Details',
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// JOB DETAIL SCREEN
// ==========================================
class JobDetailScreen extends StatelessWidget {
  final JobModel job;

  const JobDetailScreen({super.key, required this.job});

  Future<void> _deleteJob(BuildContext context, String jobId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator(color: accentTeal)),
    );

    try {
      // 1. Delete job applications
      final appsQuery = await FirebaseFirestore.instance
          .collection('job_applications')
          .where('jobId', isEqualTo: jobId)
          .get();
      
      final batch = FirebaseFirestore.instance.batch();
      for (var doc in appsQuery.docs) {
        batch.delete(doc.reference);
      }
      
      // 2. Delete the job itself
      batch.delete(FirebaseFirestore.instance.collection('jobs').doc(jobId));
      
      await batch.commit();

      if (context.mounted) {
        Navigator.pop(context); // Pop loader
        Navigator.pop(context); // Pop Detail Screen
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Job deleted successfully"),
            backgroundColor: successGreen,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Pop loader
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error deleting job: $e"),
            backgroundColor: dangerCoral,
          ),
        );
      }
    }
  }

  void _showDeleteDialog(BuildContext context, String jobId, String jobTitle) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: bgDeepNavy,
        title: const Text("Delete Job Post"),
        content: Text("Are you sure you want to delete '$jobTitle'? This will also delete all applications received for this job."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: lightText)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: dangerCoral),
            onPressed: () {
              Navigator.pop(ctx);
              _deleteJob(context, jobId);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final isPoster = currentUid == job.postedBy;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: bgDeepNavy,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Job Details',
          style: TextStyle(color: lightText),
        ),
        actions: isPoster
            ? [
                IconButton(
                  icon: const Icon(Icons.delete, color: dangerCoral),
                  tooltip: 'Delete Job',
                  onPressed: () => _showDeleteDialog(context, job.id, job.jobTitle),
                ),
              ]
            : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(job.jobTitle,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(job.company,
                style: const TextStyle(fontSize: 18, color: accentTeal)),
            const SizedBox(height: 20),
            _buildDetailRow(Icons.location_on, "Location", job.location),
            _buildDetailRow(Icons.monetization_on, "Salary", job.salary),
            _buildDetailRow(Icons.work, "Job Type", job.jobType),
            _buildDetailRow(Icons.category, "Category", job.category),
            _buildDetailRow(Icons.calendar_today, "Deadline",
                DateFormat('dd MMM, yyyy').format(job.lastDate)),
            const SizedBox(height: 24),
            const Text("Job Description",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(job.description,
                style: const TextStyle(height: 1.5, color: Colors.white70)),
            const SizedBox(height: 40),
            if (isPoster)
              Center(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('job_applications')
                      .where('jobId', isEqualTo: job.id)
                      .snapshots(),
                  builder: (context, snapshot) {
                    final count =
                        snapshot.hasData ? snapshot.data!.docs.length : 0;
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => JobApplicationsScreen(
                              jobId: job.id,
                              jobTitle: job.jobTitle,
                              jobPosterId: job.postedBy,
                            ),
                          ),
                        );
                      },
                      child: Text(
                        'You have received $count applications.',
                        style: const TextStyle(
                          color: Color(0xFF08D9D6),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    );
                  },
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentTeal,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => ApplyJobScreen(job: job)),
                    );
                  },
                  child: const Text("Apply Now",
                      style: TextStyle(
                          color: bgDeepNavy,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                ),
              )
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, color: accentTeal, size: 20),
          const SizedBox(width: 12),
          Text("$label: ", style: const TextStyle(color: Colors.white70)),
          Expanded(
              child: Text(value,
                  style: const TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }
}

// ==========================================
// APPLY JOB SCREEN
// ==========================================
class ApplyJobScreen extends StatefulWidget {
  final JobModel job;

  const ApplyJobScreen({super.key, required this.job});

  @override
  State<ApplyJobScreen> createState() => _ApplyJobScreenState();
}

class _ApplyJobScreenState extends State<ApplyJobScreen> {
  final _jobAppService = JobApplicationService();
  final _formKey = GlobalKey<FormState>();
  final _coverLetterCtrl = TextEditingController();

  PlatformFile? _cvFile;
  bool _isLoading = false;
  String _uploadStatus = 'none'; // none, uploading, success, error
  String? _cvUrl;

  @override
  void dispose() {
    _coverLetterCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );

    if (result != null && result.files.single.bytes != null ||
        result?.files.single.path != null) {
      final file = result!.files.single;

      // Check size (5MB)
      if (file.size > 5 * 1024 * 1024) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('File must be less than 5MB'),
            backgroundColor: dangerCoral));
        return;
      }

      setState(() {
        _cvFile = file;
        _uploadStatus = 'uploading';
      });

      // Start Cloudinary upload immediately
      final url = await _jobAppService.uploadCVToCloudinary(file);

      if (mounted) {
        setState(() {
          if (url != null) {
            _cvUrl = url;
            _uploadStatus = 'success';
          } else {
            _uploadStatus = 'error';
          }
        });
      }
    }
  }

  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate()) return;
    if (_cvFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please upload your CV (PDF or Image)'),
          backgroundColor: dangerCoral));
      return;
    }
    if (_uploadStatus == 'uploading') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please wait for CV to finish uploading'),
          backgroundColor: warningOrange));
      return;
    }
    if (_uploadStatus == 'error' || _cvUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('CV upload failed. Please try again.'),
          backgroundColor: dangerCoral));
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please log in to apply for a job.'),
          backgroundColor: dangerCoral));
      return;
    }

    setState(() => _isLoading = true);

    try {

      // Check if already applied
      final alreadyApplied =
          await _jobAppService.hasAlreadyApplied(widget.job.id, user.uid);
      if (alreadyApplied) {
        throw Exception("You have already applied for this job!");
      }

      // Fetch user data
      String applicantName = user.displayName ?? 'Unknown';
      String applicantPhone = 'Not provided';

      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (userDoc.exists) {
          applicantName = userDoc.data()?['fullName'] ?? applicantName;
          applicantPhone = userDoc.data()?['phone'] ?? applicantPhone;
        }
      } catch (e) {
        debugPrint("Could not fetch user details: $e");
      }

      // Save Application
      final application = JobApplicationModel(
        id: '', // Firestore will generate
        jobId: widget.job.id,
        jobTitle: widget.job.jobTitle,
        company: widget.job.company,
        applicantId: user.uid,
        applicantName: applicantName,
        applicantEmail: user.email ?? '',
        applicantPhone: applicantPhone,
        coverLetter: _coverLetterCtrl.text.trim(),
        cvFileName: _cvFile?.name ?? '',
        cvDownloadUrl: _cvUrl ?? '',
        status: 'Pending',
        appliedAt: DateTime.now(),
        jobPosterId: widget.job.postedBy,
      );

      await _jobAppService.applyForJob(application);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Application Submitted Successfully!'),
          backgroundColor: successGreen));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceAll("Exception: ", "")),
          backgroundColor: dangerCoral));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: bgDeepNavy,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          "Apply: ${widget.job.jobTitle}",
          style: const TextStyle(color: lightText),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Cover Letter (Optional)",
                        style: TextStyle(
                            color: accentTeal, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _coverLetterCtrl,
                      maxLines: 5,
                      style: const TextStyle(color: lightText),
                      decoration: InputDecoration(
                        hintText: "Write why you are a good fit...",
                        filled: true,
                        fillColor: cardBg,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text("CV / Resume (PDF or Image, Max 5MB)",
                        style: TextStyle(
                            color: accentTeal, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _pickFile,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: _uploadStatus == 'error'
                                  ? dangerCoral
                                  : (_uploadStatus == 'success'
                                      ? successGreen
                                      : accentTeal),
                              style: BorderStyle.solid),
                        ),
                        child: Column(
                          children: [
                            Icon(
                                _uploadStatus == 'success'
                                    ? Icons.check_circle
                                    : Icons.upload_file,
                                size: 40,
                                color: _uploadStatus == 'error'
                                    ? dangerCoral
                                    : (_uploadStatus == 'success'
                                        ? successGreen
                                        : accentTeal)),
                            const SizedBox(height: 8),
                            Text(
                              _cvFile == null
                                  ? "Tap to select File"
                                  : _cvFile!.name,
                              style: const TextStyle(color: Colors.white70),
                              textAlign: TextAlign.center,
                            ),
                            if (_uploadStatus == 'uploading') ...[
                              const SizedBox(height: 12),
                              const LinearProgressIndicator(
                                  color: accentTeal,
                                  backgroundColor: Colors.white12),
                              const SizedBox(height: 8),
                              const Text("Uploading CV...",
                                  style: TextStyle(
                                      color: accentTeal, fontSize: 12)),
                            ],
                            if (_uploadStatus == 'success') ...[
                              const SizedBox(height: 8),
                              const Text("CV uploaded successfully ✓",
                                  style: TextStyle(
                                      color: successGreen,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold)),
                            ],
                            if (_uploadStatus == 'error') ...[
                              const SizedBox(height: 8),
                              const Text("Upload failed. Try again.",
                                  style: TextStyle(
                                      color: dangerCoral,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentTeal,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          disabledBackgroundColor: Colors.grey,
                        ),
                        onPressed: (_isLoading || _uploadStatus == 'uploading')
                            ? null
                            : _submitApplication,
                        child: _isLoading
                            ? const CircularProgressIndicator(color: bgDeepNavy)
                            : const Text("Submit Application",
                                style: TextStyle(
                                    color: bgDeepNavy,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

// ==========================================
// TAB 2: MY APPLICATIONS
// ==========================================
class MyApplicationsScreen extends StatefulWidget {
  const MyApplicationsScreen({super.key});

  @override
  State<MyApplicationsScreen> createState() => _MyApplicationsScreenState();
}

class _MyApplicationsScreenState extends State<MyApplicationsScreen> {
  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 64, color: accentTeal),
            SizedBox(height: 16),
            Text('Please log in to view your applications',
                style: TextStyle(color: lightText, fontSize: 16)),
          ],
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('job_applications')
          .where('applicantId', isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: accentTeal));
        }
        if (snapshot.hasError) {
          return Center(
              child: Text('Error: ${snapshot.error}',
                  style: const TextStyle(color: dangerCoral)));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox, size: 64, color: Colors.white30),
                SizedBox(height: 16),
                Text("You haven't applied to any jobs yet.",
                    style: TextStyle(color: lightText, fontSize: 16)),
              ],
            ),
          );
        }

        final apps = snapshot.data!.docs
            .map((d) => JobApplicationModel.fromMap(
                d.data() as Map<String, dynamic>, d.id))
            .toList();
        // Sort in-memory by appliedAt descending
        apps.sort((a, b) => b.appliedAt.compareTo(a.appliedAt));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: apps.length,
          itemBuilder: (context, index) {
            final app = apps[index];
            return Card(
              color: cardBg,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                title: Text(app.jobTitle,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(app.company,
                        style: const TextStyle(color: accentTeal, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(
                        "Applied on: ${DateFormat('dd MMM, yyyy').format(app.appliedAt)}",
                        style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  ],
                ),
                trailing: _buildStatusBadge(app.status),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    if (status == 'Shortlisted') {
      color = successGreen;
    } else if (status == 'Rejected') {
      color = dangerCoral;
    } else {
      color = warningOrange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(status,
          style: TextStyle(
              color: color, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }
}

// ==========================================
// TAB 3: POSTED JOBS
// ==========================================
class PostedJobsScreen extends StatefulWidget {
  const PostedJobsScreen({super.key});

  @override
  State<PostedJobsScreen> createState() => _PostedJobsScreenState();
}

class _PostedJobsScreenState extends State<PostedJobsScreen> {
  Future<void> _deleteJob(BuildContext context, String jobId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator(color: accentTeal)),
    );

    try {
      // 1. Delete job applications
      final appsQuery = await FirebaseFirestore.instance
          .collection('job_applications')
          .where('jobId', isEqualTo: jobId)
          .get();
      
      final batch = FirebaseFirestore.instance.batch();
      for (var doc in appsQuery.docs) {
        batch.delete(doc.reference);
      }
      
      // 2. Delete the job itself
      batch.delete(FirebaseFirestore.instance.collection('jobs').doc(jobId));
      
      await batch.commit();

      if (context.mounted) {
        Navigator.pop(context); // Pop loader
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Job deleted successfully"),
            backgroundColor: successGreen,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Pop loader
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error deleting job: $e"),
            backgroundColor: dangerCoral,
          ),
        );
      }
    }
  }

  void _showDeleteDialog(BuildContext context, String jobId, String jobTitle) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: bgDeepNavy,
        title: const Text("Delete Job Post"),
        content: Text("Are you sure you want to delete '$jobTitle'? This will also delete all applications received for this job."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: lightText)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: dangerCoral),
            onPressed: () {
              Navigator.pop(ctx);
              _deleteJob(context, jobId);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 64, color: accentTeal),
            SizedBox(height: 16),
            Text('Please log in to view your posted jobs',
                style: TextStyle(color: lightText, fontSize: 16)),
          ],
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('jobs')
          .where('postedBy', isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: accentTeal));
        }
        if (snapshot.hasError) {
          return Center(
              child: Text('Error: ${snapshot.error}',
                  style: const TextStyle(color: dangerCoral)));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.work_off, size: 64, color: Colors.white30),
                SizedBox(height: 16),
                Text("You haven't posted any jobs yet.",
                    style: TextStyle(color: lightText, fontSize: 16)),
              ],
            ),
          );
        }

        final jobs = snapshot.data!.docs
            .map((d) => JobModel.fromMap(d.data() as Map<String, dynamic>, d.id))
            .toList();
        // Sort in-memory by createdAt descending
        jobs.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: jobs.length,
          itemBuilder: (context, index) {
            final job = jobs[index];
            return Card(
              color: cardBg,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accentTeal.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.work, color: accentTeal, size: 24),
                ),
                title: Text(job.jobTitle,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16, color: lightText)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(job.company,
                        style: const TextStyle(color: accentTeal, fontSize: 13)),
                    const SizedBox(height: 2),
                    Text(
                        "Last date: ${DateFormat('dd MMM, yyyy').format(job.lastDate)}",
                        style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.delete, color: dangerCoral),
                      onPressed: () => _showDeleteDialog(context, job.id, job.jobTitle),
                    ),
                    const Icon(Icons.arrow_forward_ios,
                        color: accentTeal, size: 16),
                  ],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => JobApplicationsScreen(
                        jobId: job.id,
                        jobTitle: job.jobTitle,
                        jobPosterId: job.postedBy,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}

// ==========================================
// APPLICATIONS LIST SCREEN (For Job Poster)
// ==========================================
class ApplicationsListScreen extends StatelessWidget {
  final JobModel job;

  const ApplicationsListScreen({super.key, required this.job});

  Future<void> _updateStatus(
      String appId, String status, BuildContext context) async {
    try {
      await FirebaseFirestore.instance
          .collection('job_applications')
          .doc(appId)
          .update({'status': status});
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Status updated to $status'),
          backgroundColor: successGreen));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: dangerCoral));
    }
  }

  Future<void> _downloadCV(String url, BuildContext context) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw "Could not launch URL";
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Could not open CV: $e'),
          backgroundColor: dangerCoral));
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    // Security check: only poster can view
    if (currentUid != job.postedBy) {
      return Scaffold(
        appBar: AppBar(title: const Text("Access Denied")),
        body: const Center(
            child: Text("Only the job poster can view applications.")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text("Applicants: ${job.jobTitle}")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('job_applications')
            .where('jobId', isEqualTo: job.id)
            .where('jobPosterId',
                isEqualTo: FirebaseAuth.instance.currentUser?.uid ?? '')
            .orderBy('appliedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No applications yet."));
          }

          final apps = snapshot.data!.docs
              .map((d) => JobApplicationModel.fromMap(
                  d.data() as Map<String, dynamic>, d.id))
              .toList();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: apps.length,
            itemBuilder: (context, index) {
              final app = apps[index];
              return Card(
                color: cardBg,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                              child: Text(app.applicantName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18))),
                          DropdownButton<String>(
                            value: app.status,
                            dropdownColor: bgDeepNavy,
                            underline: const SizedBox(),
                            icon: const Icon(Icons.arrow_drop_down,
                                color: accentTeal),
                            style: const TextStyle(
                                color: accentTeal, fontWeight: FontWeight.bold),
                            items: ['Pending', 'Shortlisted', 'Rejected']
                                .map((s) =>
                                    DropdownMenuItem(value: s, child: Text(s)))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                _updateStatus(app.id, val, context);
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(children: [
                        const Icon(Icons.email,
                            size: 16, color: Colors.white54),
                        const SizedBox(width: 8),
                        Text(app.applicantEmail,
                            style: const TextStyle(color: Colors.white70))
                      ]),
                      const SizedBox(height: 4),
                      Row(children: [
                        const Icon(Icons.phone,
                            size: 16, color: Colors.white54),
                        const SizedBox(width: 8),
                        Text(app.applicantPhone,
                            style: const TextStyle(color: Colors.white70))
                      ]),
                      if (app.coverLetter.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        const Text("Cover Letter:",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: accentTeal)),
                        const SizedBox(height: 4),
                        Text(app.coverLetter,
                            style: const TextStyle(color: Colors.white70)),
                      ],
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.download),
                          label: Text("Download CV (${app.cvFileName})"),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: accentTeal,
                            side: const BorderSide(color: accentTeal),
                          ),
                          onPressed: () =>
                              _downloadCV(app.cvDownloadUrl, context),
                        ),
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ==========================================
// POST JOB SCREEN
// ==========================================
class PostJobScreen extends StatefulWidget {
  const PostJobScreen({super.key});

  @override
  State<PostJobScreen> createState() => _PostJobScreenState();
}

class _PostJobScreenState extends State<PostJobScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _salaryCtrl = TextEditingController();

  String _jobType = 'Full-time';
  String _category = 'IT';
  DateTime? _lastDate;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _companyCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    _salaryCtrl.dispose();
    super.dispose();
  }

  final List<String> _types = ['Full-time', 'Part-time', 'Freelance'];
  final List<String> _categories = [
    'IT',
    'Construction',
    'Education',
    'Healthcare',
    'Retail',
    'Driver',
    'Other'
  ];

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
                primary: accentTeal,
                onPrimary: bgDeepNavy,
                surface: bgDeepNavy),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _lastDate = picked);
    }
  }

  Future<void> _submitJob() async {
    if (!_formKey.currentState!.validate()) return;
    if (_lastDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Please select a last date to apply."),
          backgroundColor: dangerCoral));
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please log in to post a job.'),
          backgroundColor: dangerCoral));
      return;
    }

    setState(() => _isLoading = true);

    try {
      String posterName = user.displayName ?? 'Unknown';

      // Attempt to get name from users collection
      try {
        final uDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (uDoc.exists) {
          posterName = uDoc.data()?['fullName'] ?? posterName;
        }
      } catch (_) {}

      final docRef = FirebaseFirestore.instance.collection('jobs').doc();
      await docRef.set({
        'jobTitle': _titleCtrl.text.trim(),
        'company': _companyCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'location': _locationCtrl.text.trim(),
        'salary': _salaryCtrl.text.trim(),
        'jobType': _jobType,
        'category': _category,
        'lastDate': Timestamp.fromDate(_lastDate!),
        'postedBy': user.uid,
        'postedByName': posterName,
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Job Posted Successfully!'),
          backgroundColor: successGreen));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: dangerCoral));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: bgDeepNavy,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Post a Job",
          style: TextStyle(color: lightText),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildField("Job Title", _titleCtrl),
                    _buildField("Company Name", _companyCtrl),
                    _buildField("Location", _locationCtrl),
                    _buildField(
                        "Salary Range (e.g., 30k - 50k PKR)", _salaryCtrl),
                    const Text("Job Description",
                        style: TextStyle(color: accentTeal)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descCtrl,
                      maxLines: 4,
                      style: const TextStyle(color: lightText),
                      decoration: _inputDeco(),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Job Type",
                                  style: TextStyle(color: accentTeal)),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                initialValue: _jobType,
                                dropdownColor: bgDeepNavy,
                                decoration: _inputDeco(),
                                items: _types
                                    .map((t) => DropdownMenuItem(
                                        value: t,
                                        child: Text(t,
                                            style: const TextStyle(
                                                color: lightText))))
                                    .toList(),
                                onChanged: (v) => setState(() => _jobType = v!),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Category",
                                  style: TextStyle(color: accentTeal)),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                initialValue: _category,
                                dropdownColor: bgDeepNavy,
                                decoration: _inputDeco(),
                                items: _categories
                                    .map((c) => DropdownMenuItem(
                                        value: c,
                                        child: Text(c,
                                            style: const TextStyle(
                                                color: lightText))))
                                    .toList(),
                                onChanged: (v) =>
                                    setState(() => _category = v!),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text("Last Date to Apply",
                        style: TextStyle(color: accentTeal)),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _selectDate(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                                _lastDate == null
                                    ? "Select Date"
                                    : DateFormat('dd MMM, yyyy')
                                        .format(_lastDate!),
                                style: const TextStyle(color: lightText)),
                            const Icon(Icons.calendar_today, color: accentTeal),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentTeal,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _submitJob,
                        child: const Text("Post Job",
                            style: TextStyle(
                                color: bgDeepNavy,
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                      ),
                    )
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: accentTeal)),
          const SizedBox(height: 8),
          TextFormField(
            controller: ctrl,
            style: const TextStyle(color: lightText),
            decoration: _inputDeco(),
            validator: (v) => v!.isEmpty ? 'Required' : null,
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDeco() {
    return InputDecoration(
      filled: true,
      fillColor: cardBg,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    );
  }
}
