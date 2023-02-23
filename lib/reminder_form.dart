import 'package:flutter/material.dart';

import 'database_helper.dart';

class ReminderFormPage extends StatefulWidget {
  const ReminderFormPage({Key? key}) : super(key: key);

  @override
  ReminderFormPageState createState() => ReminderFormPageState();
}

class ReminderFormPageState extends State<ReminderFormPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _streakController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _streakController.dispose();
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
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  final name = _nameController.text;
                  const streak = 0;
final reminder = {'name': name, 'streak': streak};
DatabaseHelper.instance.insertReminder(reminder);
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}
