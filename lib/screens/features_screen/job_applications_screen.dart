import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class JobApplicationsScreen extends StatelessWidget {
  final String jobId;
  final String jobTitle;
  final String jobPosterId;

  const JobApplicationsScreen({
    required this.jobId,
    required this.jobTitle,
    required this.jobPosterId,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF252A34),
      appBar: AppBar(
        backgroundColor: const Color(0xFF252A34),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF08D9D6)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Applications - $jobTitle',
          style: const TextStyle(color: Color(0xFFEAEAEA)),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('job_applications')
            .where('jobId', isEqualTo: jobId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF08D9D6),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, color: Colors.grey, size: 64),
                  SizedBox(height: 16),
                  Text(
                    'No applications yet',
                    style: TextStyle(color: Color(0xFFEAEAEA)),
                  ),
                ],
              ),
            );
          }
          final applications = snapshot.data!.docs;
          return ListView.builder(
            itemCount: applications.length,
            itemBuilder: (context, index) {
              final data = applications[index].data() as Map<String, dynamic>;
              final appId = applications[index].id;
              return _buildApplicantCard(context, data, appId);
            },
          );
        },
      ),
    );
  }

  Widget _buildApplicantCard(BuildContext context, Map<String, dynamic> data, String appId) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    // Note: The prompt uses data['jobPosterId'] but usually we'd check if current user IS the poster of THIS job.
    // The prompt's logic: final isJobPoster = currentUid == data['jobPosterId'];
    final isJobPoster = currentUid == data['jobPosterId'];
    final cvUrl = data['cvDownloadUrl'] ?? '';
    final cvFileName = data['cvFileName'] ?? '';
    final isPdf = cvFileName.toLowerCase().endsWith('.pdf');

    return Card(
      color: const Color(0xFF1A1F2E),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Applicant Name
            Text(
              data['applicantName'] ?? 'Unknown',
              style: const TextStyle(
                color: Color(0xFFEAEAEA),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Email
            Row(children: [
              const Icon(Icons.email, color: Color(0xFF08D9D6), size: 16),
              const SizedBox(width: 8),
              Text(
                data['applicantEmail'] ?? '',
                style: const TextStyle(color: Colors.grey),
              ),
            ]),
            const SizedBox(height: 4),

            // Phone
            Row(children: [
              const Icon(Icons.phone, color: Color(0xFF08D9D6), size: 16),
              const SizedBox(width: 8),
              Text(
                data['applicantPhone'] ?? '',
                style: const TextStyle(color: Colors.grey),
              ),
            ]),
            const SizedBox(height: 8),

            // Cover Letter
            if (data['coverLetter'] != null && data['coverLetter'].toString().isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Cover Letter:',
                    style: TextStyle(
                      color: Color(0xFF08D9D6),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data['coverLetter'],
                    style: const TextStyle(color: Color(0xFFEAEAEA)),
                  ),
                  const SizedBox(height: 8),
                ],
              ),

            // CV VIEW - Only for job poster
            if (isJobPoster && cvUrl.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'CV / Resume:',
                    style: TextStyle(
                      color: Color(0xFF08D9D6),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // If image (jpg/png) - show directly
                  if (!isPdf)
                    GestureDetector(
                      onTap: () {
                        // Open full screen image
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => Scaffold(
                              backgroundColor: const Color(0xFF252A34),
                              appBar: AppBar(
                                title: Text('CV - ${data['applicantName']}'),
                                backgroundColor: const Color(0xFF252A34),
                              ),
                              body: Center(
                                child: InteractiveViewer(
                                  child: Image.network(
                                    cvUrl,
                                    loadingBuilder: (_, child, progress) {
                                      if (progress == null) return child;
                                      return const CircularProgressIndicator(
                                        color: Color(0xFF08D9D6),
                                      );
                                    },
                                    errorBuilder: (_, __, ___) => const Text(
                                      'Could not load image',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                      child: Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFF08D9D6),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            cvUrl,
                            fit: BoxFit.cover,
                            loadingBuilder: (_, child, progress) {
                              if (progress == null) return child;
                              return const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFF08D9D6),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),

                  // If PDF - show open button
                  if (isPdf)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF08D9D6),
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      icon: const Icon(Icons.picture_as_pdf, color: Colors.black),
                      label: const Text(
                        'Open PDF Resume',
                        style: TextStyle(color: Colors.black),
                      ),
                      onPressed: () async {
                        final uri = Uri.parse(cvUrl);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Could not open PDF'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                    ),
                ],
              ),

            const SizedBox(height: 12),

            // Status Dropdown
            Row(
              children: [
                const Text(
                  'Status: ',
                  style: TextStyle(color: Color(0xFFEAEAEA)),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: data['status'] ?? 'Pending',
                  dropdownColor: const Color(0xFF1A1F2E),
                  style: const TextStyle(color: Color(0xFFEAEAEA)),
                  items: ['Pending', 'Shortlisted', 'Rejected']
                      .map((s) => DropdownMenuItem(
                            value: s,
                            child: Text(
                              s,
                              style: TextStyle(
                                color: s == 'Pending'
                                    ? Colors.orange
                                    : s == 'Shortlisted'
                                        ? Colors.green
                                        : Colors.red,
                              ),
                            ),
                          ))
                      .toList(),
                  onChanged: (newStatus) async {
                    if (newStatus != null) {
                      await FirebaseFirestore.instance
                          .collection('job_applications')
                          .doc(appId)
                          .update({'status': newStatus});
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Status updated to $newStatus'),
                            backgroundColor: const Color(0xFF4CAF50),
                          ),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
