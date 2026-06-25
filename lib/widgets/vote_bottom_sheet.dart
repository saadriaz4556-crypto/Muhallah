import 'package:flutter/material.dart';
import '../models/poll_model.dart';
import '../services/polls_service.dart';

class VoteBottomSheet extends StatefulWidget {
  final PollModel poll;
  final VoidCallback onVoteCast;

  const VoteBottomSheet({
    super.key,
    required this.poll,
    required this.onVoteCast,
  });

  @override
  State<VoteBottomSheet> createState() => _VoteBottomSheetState();
}

class _VoteBottomSheetState extends State<VoteBottomSheet> {
  final PollsService _pollsService = PollsService();
  List<String> _selectedOptionIds = [];
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    const Color background = Color(0xFF2A303C);
    const Color accent = Color(0xFF08D9D6);

    return Container(
      decoration: const BoxDecoration(
        color: background,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Cast Your Vote',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white70),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.poll.pollType == 'single' 
              ? 'Select one option' 
              : 'You can select multiple options',
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
          ),
          const SizedBox(height: 20),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                children: widget.poll.options.map((option) {
                  final isSelected = _selectedOptionIds.contains(option.optionId);
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          if (widget.poll.pollType == 'single') {
                            _selectedOptionIds = [option.optionId];
                          } else {
                            if (isSelected) {
                              _selectedOptionIds.remove(option.optionId);
                            } else {
                              _selectedOptionIds.add(option.optionId);
                            }
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: isSelected ? accent.withOpacity(0.1) : Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? accent : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                option.text,
                                style: TextStyle(
                                  color: isSelected ? accent : Colors.white,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                            if (widget.poll.pollType == 'single')
                              Radio<String>(
                                value: option.optionId,
                                groupValue: _selectedOptionIds.isEmpty ? null : _selectedOptionIds.first,
                                onChanged: (val) {
                                  if (val != null) setState(() => _selectedOptionIds = [val]);
                                },
                                activeColor: accent,
                              )
                            else
                              Checkbox(
                                value: isSelected,
                                onChanged: (val) {
                                  setState(() {
                                    if (val == true) {
                                      _selectedOptionIds.add(option.optionId);
                                    } else {
                                      _selectedOptionIds.remove(option.optionId);
                                    }
                                  });
                                },
                                activeColor: accent,
                                checkColor: Colors.black,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_selectedOptionIds.isEmpty || _isSubmitting) ? null : _handleVote,
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.black,
                disabledBackgroundColor: Colors.grey.withOpacity(0.3),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSubmitting
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : const Text('Confirm Vote', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
    );
  }

  Future<void> _handleVote() async {
    setState(() => _isSubmitting = true);
    try {
      await _pollsService.castVote(widget.poll.pollId, _selectedOptionIds, widget.poll.isAnonymous);
      widget.onVoteCast();
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vote cast successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
