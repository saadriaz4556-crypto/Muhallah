import 'package:flutter/material.dart';
import '../../services/polls_service.dart';
import '../../models/poll_model.dart';
import '../../models/vote_model.dart';
import '../../widgets/poll_card.dart';
import '../../widgets/app_header_gradient.dart';
import 'create_poll_screen.dart';

class PollsScreen extends StatefulWidget {
  const PollsScreen({super.key});

  @override
  State<PollsScreen> createState() => _PollsScreenState();
}

class _PollsScreenState extends State<PollsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final PollsService _pollsService = PollsService();
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _checkAdmin();
  }

  Future<void> _checkAdmin() async {
    final isAdmin = await _pollsService.isAdmin();
    if (mounted) {
      setState(() {
        _isAdmin = isAdmin;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color background = Color(0xFF252A34);
    const Color accent = Color(0xFF08D9D6);

    return Scaffold(
      backgroundColor: background,
      appBar: GradientHeaderAppBar(
        title: 'Polls & Voting',
        titleWidget: const Text(
          'Polls & Voting',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            indicatorColor: accent,
            labelColor: accent,
            unselectedLabelColor: Colors.white54,
            tabs: const [
              Tab(text: 'Active Polls'),
              Tab(text: 'Completed'),
              Tab(text: 'My Votes'),
              Tab(text: 'Create Poll'),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildActivePolls(),
          _buildCompletedPolls(),
          _buildMyVotes(),
          _buildCreatePollTab(),
        ],
      ),
    );
  }

  Widget _buildActivePolls() {
    return StreamBuilder<List<PollModel>>(
      stream: _pollsService.getActivePolls(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFF08D9D6)));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState(
              'No active polls right now', Icons.poll_outlined);
        }

        return ListView.builder(
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final poll = snapshot.data![index];
            return FutureBuilder<bool>(
              future: _pollsService.hasUserVoted(poll.pollId),
              builder: (context, voteSnapshot) {
                return PollCard(
                  poll: poll,
                  alreadyVoted: voteSnapshot.data ?? false,
                  onVoteCast: () => setState(() {}),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildCompletedPolls() {
    return StreamBuilder<List<PollModel>>(
      stream: _pollsService.getCompletedPolls(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFF08D9D6)));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState('No completed polls found', Icons.history);
        }

        return ListView.builder(
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            return PollCard(
              poll: snapshot.data![index],
              isCompleted: true,
              onVoteCast: () {},
            );
          },
        );
      },
    );
  }

  Widget _buildMyVotes() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _pollsService.getMyVotes(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFF08D9D6)));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState("You haven't voted yet", Icons.how_to_vote);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final data = snapshot.data![index];
            final PollModel poll = data['poll'];
            final VoteModel vote = data['vote'];
            final isClosed = poll.status == 'completed';

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          poll.title,
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: vote.selectedOptions.map((optId) {
                            final optText = poll.options
                                .firstWhere((o) => o.optionId == optId)
                                .text;
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF08D9D6)
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                optText,
                                style: const TextStyle(
                                    color: Color(0xFF08D9D6), fontSize: 11),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isClosed
                          ? Colors.grey.withValues(alpha: 0.2)
                          : Colors.green.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isClosed ? 'Closed' : 'Active',
                      style: TextStyle(
                        color: isClosed ? Colors.grey : Colors.green,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCreatePollTab() {
    if (!_isAdmin) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 64, color: Colors.white24),
            const SizedBox(height: 16),
            const Text(
              'Admin Access Only',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Only moderators can create new polls.',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
            ),
          ],
        ),
      );
    }

    return const CreatePollScreen();
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.white24),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5), fontSize: 16),
          ),
        ],
      ),
    );
  }
}
