import 'package:flutter/material.dart';
import 'database_helper.dart';

class Reminder {
  final int id;
  final String name;
  final int streak;
  final String userId;
  final int? lastCompletionDateMillis;

  Reminder({
    required this.id,
    required this.name,
    required this.streak,
    required this.userId,
    this.lastCompletionDateMillis,
  });

  DateTime? get lastCompletionDate {
    if (lastCompletionDateMillis != null) {
      return DateTime.fromMillisecondsSinceEpoch(lastCompletionDateMillis!);
    } else {
      return null;
    }
  }

  Reminder copyWith({
    int? id,
    String? name,
    int? streak,
    String? userId,
    int? lastCompletionDateMillis,
  }) {
    return Reminder(
      id: id ?? this.id,
      name: name ?? this.name,
      streak: streak ?? this.streak,
      userId: userId ?? this.userId,
      lastCompletionDateMillis: lastCompletionDateMillis ?? this.lastCompletionDateMillis,
    );
  }
}


class ReminderFormPage extends StatefulWidget {
  final String userId;
  final Function(Reminder) onReminderAdded;

  const ReminderFormPage({
    Key? key,
    required this.userId,
    required this.onReminderAdded,
  }) : super(key: key);

  @override
  ReminderFormPageState createState() => ReminderFormPageState();
}

class ReminderFormPageState extends State<ReminderFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();


void _saveReminder() async {
  if (_formKey.currentState!.validate()) {
    final newReminder = Reminder(
      id: 0, // ID will be assigned by the database
      name: _nameController.text,
      streak: 0,
      userId: widget.userId,
    );

    // Insert the new reminder into the database
    final db = await DatabaseHelper.instance.database;
    final id = await db.insert(
      DatabaseHelper.remindersTable,
      {
        DatabaseHelper.remindersColumnName: newReminder.name,
        DatabaseHelper.remindersColumnStreak: 0,
        DatabaseHelper.remindersColumnUserId: widget.userId,
      },
    );

    final reminder = Reminder(
      id: id,
      name: newReminder.name,
      streak: newReminder.streak,
      userId: newReminder.userId,
    );

    // Update the new reminder in the list
    widget.onReminderAdded(reminder);

    Navigator.pop(context);
  }
}


  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Reminder'),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a name';
                }
                return null;
              },
            ),
            ElevatedButton(
              onPressed: _saveReminder,
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}