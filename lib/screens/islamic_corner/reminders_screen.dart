import 'package:flutter/material.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  static const Color deepNavy = Color(0xFF252A34);
  static const Color sectionBg = Color(0xFF2A303C);
  static const Color teal = Color(0xFF08D9D6);
  static const Color premiumWhite = Color(0xFFEAEAEA);

  final List<Map<String, dynamic>> _presetReminders = [
    {
      'title': 'Jummah Reminder',
      'desc': 'Every Friday morning',
      'enabled': true
    },
    {
      'title': 'Ramadan Start',
      'desc': 'Remind me 1 day before Ramadan',
      'enabled': false
    },
    {'title': 'Eid days', 'desc': 'Remind me on Eid morning', 'enabled': true},
    {
      'title': 'Laylatul Qadr',
      'desc': 'Odd nights of last 10 days of Ramadan',
      'enabled': false
    },
  ];

  void _toggleReminder(int index, bool val) {
    setState(() {
      _presetReminders[index]['enabled'] = val;
    });

    // Here we would use flutter_local_notifications to schedule or cancel
    if (val) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${_presetReminders[index]['title']} enabled')));
    }
  }

  void _addCustomReminder() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: sectionBg,
        title: const Text('Add Custom Reminder',
            style: TextStyle(color: premiumWhite)),
        content: TextField(
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Reminder title...',
            hintStyle: const TextStyle(color: Colors.white54),
            filled: true,
            fillColor: deepNavy,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Custom reminder added!')));
            },
            child: const Text('Save', style: TextStyle(color: teal)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: deepNavy,
      appBar: AppBar(
        backgroundColor: deepNavy,
        title: const Text('Islamic Reminders',
            style: TextStyle(color: premiumWhite)),
        iconTheme: const IconThemeData(color: teal),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: teal,
        onPressed: _addCustomReminder,
        child: const Icon(Icons.add, color: Colors.black),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text('Preset Reminders',
                style: TextStyle(
                    color: teal, fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          ...List.generate(_presetReminders.length, (index) {
            final reminder = _presetReminders[index];
            return Card(
              color: sectionBg,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: SwitchListTile(
                activeThumbColor: teal,
                title: Text(reminder['title'],
                    style: const TextStyle(
                        color: premiumWhite, fontWeight: FontWeight.bold)),
                subtitle: Text(reminder['desc'],
                    style: const TextStyle(color: Colors.white70)),
                value: reminder['enabled'],
                onChanged: (val) => _toggleReminder(index, val),
              ),
            );
          }),
        ],
      ),
    );
  }
}
