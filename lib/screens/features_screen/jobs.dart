import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

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
// MODELS
// ==========================================
class JobModel {
  final String jobId;
  final String title;
  final String company;
  final String description;
  final String location;
  final String salary;
  final String jobType;
  final String category;
  final DateTime lastDate;
  final String postedBy;
  final String postedByName;
  final DateTime createdAt;
  final bool isActive;

  JobModel({
    required this.jobId,
    required this.title,
    required this.company,
    required this.description,
    required this.location,
    required this.salary,
    required this.jobType,
    required this.category,
    required this.lastDate,
    required this.postedBy,
    required this.postedByName,
    required this.createdAt,
    required this.isActive,
  });

  factory JobModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return JobModel(
      jobId: doc.id,
      title: data['title'] ?? '',
      company: data['company'] ?? '',
      description: data['description'] ?? '',
      location: data['location'] ?? '',
      salary: data['salary'] ?? '',
      jobType: data['jobType'] ?? '',
      category: data['category'] ?? '',
      lastDate: (data['lastDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      postedBy: data['postedBy'] ?? '',
      postedByName: data['postedByName'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] ?? true,
    );
  }
}

class JobAppModel {
  final String applicationId;
  final String jobId;
  final String jobTitle;
  final String applicantId;
  final String applicantName;
  final String applicantEmail;
  final String applicantPhone;
  final String coverLetter;
  final String cvFileName;
  final String cvDownloadUrl;
  final String status;
  final DateTime appliedAt;
  final String jobPosterId;

  JobAppModel({
    required this.applicationId,
    required this.jobId,
    required this.jobTitle,
    required this.applicantId,
    required this.applicantName,
    required this.applicantEmail,
    required this.applicantPhone,
    required this.coverLetter,
    required this.cvFileName,
    required this.cvDownloadUrl,
    required this.status,
    required this.appliedAt,
    required this.jobPosterId,
  });

  factory JobAppModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return JobAppModel(
      applicationId: doc.id,
      jobId: data['jobId'] ?? '',
      jobTitle: data['jobTitle'] ?? '',
      applicantId: data['applicantId'] ?? '',
      applicantName: data['applicantName'] ?? '',
      applicantEmail: data['applicantEmail'] ?? '',
      applicantPhone: data['applicantPhone'] ?? '',
      coverLetter: data['coverLetter'] ?? '',
      cvFileName: data['cvFileName'] ?? '',
      cvDownloadUrl: data['cvDownloadUrl'] ?? '',
      status: data['status'] ?? 'Pending',
      appliedAt: (data['appliedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      jobPosterId: data['jobPosterId'] ?? '',
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
                onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
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
                .where('isActive', isEqualTo: true)
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('No jobs available.'));
              }

              final docs = snapshot.data!.docs;
              final jobs = docs.map((d) => JobModel.fromDocument(d)).where((job) {
                final matchesSearch = job.title.toLowerCase().contains(_searchQuery) ||
                                      job.company.toLowerCase().contains(_searchQuery);
                final matchesType = _selectedType == 'All' || job.jobType == _selectedType;
                return matchesSearch && matchesType;
              }).toList();

              if (jobs.isEmpty) {
                return const Center(child: Text('No jobs match your criteria.'));
              }

              return ListView.builder(
                itemCount: jobs.length,
                padding: const EdgeInsets.symmetric(horizontal: 16),
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
      color: cardBg,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        onTap: onTap,
        title: Text(
          job.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.business, size: 16, color: accentTeal),
                const SizedBox(width: 6),
                Expanded(child: Text(job.company, style: const TextStyle(color: lightText))),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: accentTeal),
                const SizedBox(width: 6),
                Expanded(child: Text(job.location, style: const TextStyle(color: Colors.white70))),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  job.salary,
                  style: const TextStyle(color: successGreen, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: accentTeal.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: accentTeal),
                  ),
                  child: Text(
                    job.jobType,
                    style: const TextStyle(color: accentTeal, fontSize: 12),
                  ),
                ),
              ],
            )
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

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final isPoster = currentUid == job.postedBy;

    return Scaffold(
      appBar: AppBar(title: const Text('Job Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(job.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(job.company, style: const TextStyle(fontSize: 18, color: accentTeal)),
            const SizedBox(height: 20),
            
            _buildDetailRow(Icons.location_on, "Location", job.location),
            _buildDetailRow(Icons.monetization_on, "Salary", job.salary),
            _buildDetailRow(Icons.work, "Job Type", job.jobType),
            _buildDetailRow(Icons.category, "Category", job.category),
            _buildDetailRow(Icons.calendar_today, "Deadline", DateFormat('dd MMM, yyyy').format(job.lastDate)),
            
            const SizedBox(height: 24),
            const Text("Job Description", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(job.description, style: const TextStyle(height: 1.5, color: Colors.white70)),
            
            const SizedBox(height: 40),
            
            if (isPoster)
              Center(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('job_applications')
                      .where('jobId', isEqualTo: job.jobId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
                    return Text("You have received $count applications.",
                      style: const TextStyle(color: accentTeal, fontWeight: FontWeight.bold));
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ApplyJobScreen(job: job)),
                    );
                  },
                  child: const Text("Apply Now", style: TextStyle(color: bgDeepNavy, fontSize: 18, fontWeight: FontWeight.bold)),
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
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold))),
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
  final _formKey = GlobalKey<FormState>();
  final _coverLetterCtrl = TextEditingController();
  
  File? _cvFile;
  bool _isLoading = false;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final size = await file.length();
      if (size > 5 * 1024 * 1024) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('File must be less than 5MB'), backgroundColor: dangerCoral));
        return;
      }
      setState(() {
        _cvFile = file;
      });
    }
  }

  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate()) return;
    if (_cvFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please upload your CV (PDF)'), backgroundColor: dangerCoral));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      
      // Check if already applied
      final existing = await FirebaseFirestore.instance
          .collection('job_applications')
          .where('jobId', isEqualTo: widget.job.jobId)
          .where('applicantId', isEqualTo: user.uid)
          .get();
          
      if (existing.docs.isNotEmpty) {
        throw Exception("You have already applied for this job!");
      }

      // Upload CV
      final fileName = 'cv_${user.uid}.pdf';
      final ref = FirebaseStorage.instance.ref().child('job_applications/${widget.job.jobId}/${user.uid}/$fileName');
      
      await ref.putFile(_cvFile!, SettableMetadata(contentType: 'application/pdf'));
      final cvUrl = await ref.getDownloadURL();

      // Fetch user data (fallback to dummy if not exist in users collection)
      String applicantName = user.displayName ?? 'Unknown';
      String applicantPhone = user.phoneNumber ?? 'Not provided';
      
      try {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          applicantName = userDoc.data()?['fullName'] ?? applicantName;
          applicantPhone = userDoc.data()?['phone'] ?? applicantPhone;
        }
      } catch(e) {
        debugPrint("Could not fetch user details: $e");
      }

      // Save App
      final appRef = FirebaseFirestore.instance.collection('job_applications').doc();
      await appRef.set({
        'jobId': widget.job.jobId,
        'jobTitle': widget.job.title,
        'applicantId': user.uid,
        'applicantName': applicantName,
        'applicantEmail': user.email ?? '',
        'applicantPhone': applicantPhone,
        'coverLetter': _coverLetterCtrl.text.trim(),
        'cvFileName': _cvFile!.path.split('/').last,
        'cvDownloadUrl': cvUrl,
        'status': 'Pending',
        'appliedAt': FieldValue.serverTimestamp(),
        'jobPosterId': widget.job.postedBy,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Application Submitted Successfully!'), backgroundColor: successGreen));
      Navigator.pop(context); // Go back

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll("Exception: ", "")), backgroundColor: dangerCoral));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Apply: ${widget.job.title}")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Cover Letter (Optional)", style: TextStyle(color: accentTeal, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _coverLetterCtrl,
                      maxLines: 5,
                      style: const TextStyle(color: lightText),
                      decoration: InputDecoration(
                        hintText: "Write why you are a good fit...",
                        filled: true,
                        fillColor: cardBg,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text("CV / Resume (PDF Only, Max 5MB)", style: TextStyle(color: accentTeal, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _pickFile,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: accentTeal, style: BorderStyle.solid),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.upload_file, size: 40, color: accentTeal),
                            const SizedBox(height: 8),
                            Text(
                              _cvFile == null ? "Tap to select PDF" : _cvFile!.path.split('/').last,
                              style: const TextStyle(color: Colors.white70),
                              textAlign: TextAlign.center,
                            ),
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
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _submitApplication,
                        child: const Text("Submit Application", style: TextStyle(color: bgDeepNavy, fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    )
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
class MyApplicationsScreen extends StatelessWidget {
  const MyApplicationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('job_applications')
          .where('applicantId', isEqualTo: uid)
          .orderBy('appliedAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("You haven't applied to any jobs yet."));

        final apps = snapshot.data!.docs.map((d) => JobAppModel.fromDocument(d)).toList();

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: apps.length,
          itemBuilder: (context, index) {
            final app = apps[index];
            return Card(
              color: cardBg,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                title: Text(app.jobTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text("Applied on: ${DateFormat('dd MMM, yyyy').format(app.appliedAt)}", style: const TextStyle(color: Colors.white54)),
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
    } else if (status == 'Rejected') color = dangerCoral;
    else color = warningOrange; // Pending

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(status, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }
}

// ==========================================
// TAB 3: POSTED JOBS
// ==========================================
class PostedJobsScreen extends StatelessWidget {
  const PostedJobsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('jobs')
          .where('postedBy', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("You haven't posted any jobs."));

        final jobs = snapshot.data!.docs.map((d) => JobModel.fromDocument(d)).toList();

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: jobs.length,
          itemBuilder: (context, index) {
            final job = jobs[index];
            return Card(
              color: cardBg,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                title: Text(job.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                subtitle: Text("Expires: ${DateFormat('dd MMM, yyyy').format(job.lastDate)}", style: const TextStyle(color: Colors.white54)),
                trailing: const Icon(Icons.arrow_forward_ios, color: accentTeal, size: 16),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => ApplicationsListScreen(job: job)));
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

  Future<void> _updateStatus(String appId, String status, BuildContext context) async {
    try {
      await FirebaseFirestore.instance.collection('job_applications').doc(appId).update({'status': status});
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status updated to $status'), backgroundColor: successGreen));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: dangerCoral));
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not open CV: $e'), backgroundColor: dangerCoral));
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    // Security check: only poster can view
    if (currentUid != job.postedBy) {
      return Scaffold(
        appBar: AppBar(title: const Text("Access Denied")),
        body: const Center(child: Text("Only the job poster can view applications.")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text("Applicants: ${job.title}")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('job_applications')
            .where('jobId', isEqualTo: job.jobId)
            .orderBy('appliedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("No applications yet."));

          final apps = snapshot.data!.docs.map((d) => JobAppModel.fromDocument(d)).toList();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: apps.length,
            itemBuilder: (context, index) {
              final app = apps[index];
              return Card(
                color: cardBg,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text(app.applicantName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
                          DropdownButton<String>(
                            value: app.status,
                            dropdownColor: bgDeepNavy,
                            underline: const SizedBox(),
                            icon: const Icon(Icons.arrow_drop_down, color: accentTeal),
                            style: const TextStyle(color: accentTeal, fontWeight: FontWeight.bold),
                            items: ['Pending', 'Shortlisted', 'Rejected']
                                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) _updateStatus(app.applicationId, val, context);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(children: [const Icon(Icons.email, size: 16, color: Colors.white54), const SizedBox(width: 8), Text(app.applicantEmail, style: const TextStyle(color: Colors.white70))]),
                      const SizedBox(height: 4),
                      Row(children: [const Icon(Icons.phone, size: 16, color: Colors.white54), const SizedBox(width: 8), Text(app.applicantPhone, style: const TextStyle(color: Colors.white70))]),
                      
                      if (app.coverLetter.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        const Text("Cover Letter:", style: TextStyle(fontWeight: FontWeight.bold, color: accentTeal)),
                        const SizedBox(height: 4),
                        Text(app.coverLetter, style: const TextStyle(color: Colors.white70)),
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
                          onPressed: () => _downloadCV(app.cvDownloadUrl, context),
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

  final List<String> _types = ['Full-time', 'Part-time', 'Freelance'];
  final List<String> _categories = ['IT', 'Construction', 'Education', 'Healthcare', 'Retail', 'Driver', 'Other'];

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(primary: accentTeal, onPrimary: bgDeepNavy, surface: bgDeepNavy),
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a last date to apply."), backgroundColor: dangerCoral));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      String posterName = user.displayName ?? 'Unknown';

      // Attempt to get name from users collection
      try {
        final uDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (uDoc.exists) {
          posterName = uDoc.data()?['fullName'] ?? posterName;
        }
      } catch (_) {}

      final docRef = FirebaseFirestore.instance.collection('jobs').doc();
      await docRef.set({
        'title': _titleCtrl.text.trim(),
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Job Posted Successfully!'), backgroundColor: successGreen));
      Navigator.pop(context);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: dangerCoral));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Post a Job")),
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
                    _buildField("Salary Range (e.g., 30k - 50k PKR)", _salaryCtrl),
                    
                    const Text("Job Description", style: TextStyle(color: accentTeal)),
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
                              const Text("Job Type", style: TextStyle(color: accentTeal)),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                initialValue: _jobType,
                                dropdownColor: bgDeepNavy,
                                decoration: _inputDeco(),
                                items: _types.map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(color: lightText)))).toList(),
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
                              const Text("Category", style: TextStyle(color: accentTeal)),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                initialValue: _category,
                                dropdownColor: bgDeepNavy,
                                decoration: _inputDeco(),
                                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(color: lightText)))).toList(),
                                onChanged: (v) => setState(() => _category = v!),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    const Text("Last Date to Apply", style: TextStyle(color: accentTeal)),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _selectDate(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_lastDate == null ? "Select Date" : DateFormat('dd MMM, yyyy').format(_lastDate!), style: const TextStyle(color: lightText)),
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
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _submitJob,
                        child: const Text("Post Job", style: TextStyle(color: bgDeepNavy, fontSize: 18, fontWeight: FontWeight.bold)),
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
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    );
  }
}
