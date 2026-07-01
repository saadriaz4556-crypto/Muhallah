import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../models/poll_model.dart';
import 'vote_bottom_sheet.dart';

class PollCard extends StatefulWidget {
  final PollModel poll;
  final bool isCompleted;
  final bool alreadyVoted;
  final String? votedOptionId;
  final VoidCallback onVoteCast;

  const PollCard({
    super.key,
    required this.poll,
    this.isCompleted = false,
    this.alreadyVoted = false,
    this.votedOptionId,
    required this.onVoteCast,
  });

  @override
  State<PollCard> createState() => _PollCardState();
}

class _PollCardState extends State<PollCard> {
  bool _isExpanded = false;
  late Timer _timer;
  String _timeRemaining = '';

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) _updateTime();
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _updateTime() {
    final now = DateTime.now();
    if (now.isAfter(widget.poll.endDate)) {
      setState(() {
        _timeRemaining = 'Ended';
      });
      return;
    }

    final diff = widget.poll.endDate.difference(now);
    final days = diff.inDays;
    final hours = diff.inHours % 24;
    final minutes = diff.inMinutes % 60;
    final seconds = diff.inSeconds % 60;

    setState(() {
      if (days > 0) {
        _timeRemaining = '${days}d ${hours}h left';
      } else if (hours > 0) {
        _timeRemaining = '${hours}h ${minutes}m left';
      } else {
        _timeRemaining = '${minutes}m ${seconds}s left';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color background = Color(0xFF2A303C);
    const Color accent = Color(0xFF08D9D6);
    final int totalVotes = widget.poll.options.fold(0, (sum, item) => sum + item.voteCount);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.isCompleted ? Colors.amber.withValues(alpha: 0.3) : accent.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with chips and share
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
            child: Row(
              children: [
                if (widget.poll.isAnonymous)
                  _buildChip('Anonymous', Colors.grey),
                if (widget.poll.isAnonymous) const SizedBox(width: 8),
                _buildChip(widget.poll.targetAudience, accent),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.share, color: Colors.white70, size: 20),
                  onPressed: () {
                    Share.share('Vote on: ${widget.poll.title} — Digital Mohallah App');
                  },
                ),
              ],
            ),
          ),

          // Title & Description
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.poll.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => setState(() => _isExpanded = !_isExpanded),
                  child: Text(
                    widget.poll.description,
                    maxLines: _isExpanded ? null : 2,
                    overflow: _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Voter count & Time remaining
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.people, size: 16, color: Colors.white.withValues(alpha: 0.5)),
                const SizedBox(width: 4),
                Text(
                  '$totalVotes voters',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                ),
                const Spacer(),
                Icon(Icons.timer, size: 16, color: widget.isCompleted ? Colors.red : accent),
                const SizedBox(width: 4),
                Text(
                  widget.isCompleted ? 'Completed' : _timeRemaining,
                  style: TextStyle(
                    color: widget.isCompleted ? Colors.red : accent,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Options / Results
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: widget.poll.options.map((option) {
                final double percent = totalVotes == 0 ? 0 : option.voteCount / totalVotes;
                final bool isWinner = widget.isCompleted &&
                    option.voteCount == widget.poll.options.map((e) => e.voteCount).reduce((a, b) => a > b ? a : b) &&
                    totalVotes > 0;
                final bool isUserChoice = widget.votedOptionId == option.optionId;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    option.text,
                                    style: TextStyle(
                                      color: isWinner ? Colors.amber : Colors.white,
                                      fontWeight: isWinner || isUserChoice ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                ),
                                if (isWinner) ...[
                                  const SizedBox(width: 4),
                                  const Icon(Icons.emoji_events, color: Colors.amber, size: 16),
                                ],
                                if (isUserChoice) ...[
                                  const SizedBox(width: 4),
                                  const Icon(Icons.check_circle, color: accent, size: 16),
                                ]
                              ],
                            ),
                          ),
                          Text(
                            '${(percent * 100).toStringAsFixed(1)}%',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Stack(
                        children: [
                          Container(
                            height: 8,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 800),
                            height: 8,
                            width: MediaQuery.of(context).size.width * 0.8 * percent, // Approximation
                            decoration: BoxDecoration(
                              color: isWinner ? Colors.amber : accent,
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: [
                                if (isWinner)
                                  BoxShadow(
                                    color: Colors.amber.withValues(alpha: 0.3),
                                    blurRadius: 4,
                                    spreadRadius: 1,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

          // Bottom Section
          if (!widget.isCompleted && !widget.alreadyVoted)
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _showVoteBottomSheet(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Cast Vote', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            )
          else if (widget.alreadyVoted)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'You have already voted',
                  style: TextStyle(color: accent.withValues(alpha: 0.7), fontStyle: FontStyle.italic),
                ),
              ),
            ),

          if (widget.isCompleted)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Ended on ${DateFormat('MMM dd, yyyy').format(widget.poll.endDate)}',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _showVoteBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => VoteBottomSheet(
        poll: widget.poll,
        onVoteCast: widget.onVoteCast,
      ),
    );
  }
}
