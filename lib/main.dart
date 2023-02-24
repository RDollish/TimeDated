import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'reminder_form.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:timedated/database_helper.dart' as dbHelper;
import 'package:confetti/confetti.dart';
import 'dart:math';

import 'login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      return MaterialApp(
        title: 'TimeDated',
        theme: ThemeData(
          primarySwatch: Colors.pink,
        ),
        home: const MyHomePage(title: 'Daily Reminders'),
      );
    } else {
      return MaterialApp(
        title: 'Daily Reminders',
        theme: ThemeData(
          primarySwatch: Colors.pink,
        ),
        home: const LoginScreen(),
      );
    }
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String? userId;
  List<Reminder> reminders = [];
  final confettiController = ConfettiController();
  bool showConfetti = false;

  @override
  void dispose() {
    confettiController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    confettiController.duration = const Duration(seconds: 10);
    userId = FirebaseAuth.instance.currentUser?.uid;
    _getReminders();
  }

  void _getReminders() async {
    final db = await dbHelper.DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> remindersList = await db.rawQuery(
      'SELECT * FROM ${dbHelper.DatabaseHelper.remindersTable} WHERE ${dbHelper.DatabaseHelper.remindersColumnUserId} = ?',
      [userId],
    );
    final newReminders = remindersList
        .map((reminder) => Reminder(
              id: reminder[dbHelper.DatabaseHelper.remindersColumnId],
              name: reminder[dbHelper.DatabaseHelper.remindersColumnName],
              streak: reminder[dbHelper.DatabaseHelper.remindersColumnStreak],
              userId: reminder[dbHelper.DatabaseHelper.remindersColumnUserId],
              lastCompletionDateMillis: reminder['last_completion_date_millis'],
            ))
        .toList();
    setState(() {
      reminders = newReminders;
    });
  }

  void _deleteReminder(int id) async {
    final rowsDeleted =
        await dbHelper.DatabaseHelper.instance.deleteReminder(id);
    if (rowsDeleted > 0) {
      setState(() {
        reminders.removeWhere(
          (reminder) => reminder.id == id,
        );
      });
    }
  }

  void _addReminder() {
    print("Adding a new reminder");
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReminderFormPage(
          userId: userId!,
          onReminderAdded: (newReminder) async {
            // Check if the reminder already exists in the list
            bool reminderExists = false;
            for (var reminder in reminders) {
              if (reminder.id == newReminder.id) {
                reminderExists = true;
                break;
              }
            }
            if (!reminderExists) {
              setState(() {
                reminders.add(newReminder);
              });
            } else {
              print('Reminder already exists in the list');
            }
          },
        ),
      ),
    );
  }

  Future<String?> getAchievementName(int streak) async {
    final db = await dbHelper.DatabaseHelper.instance.database;
    final result = await db.query(
      dbHelper.DatabaseHelper.achievementsTable,
      where: '${dbHelper.DatabaseHelper.achievementsColumnStreak} <= ?',
      whereArgs: [streak],
      orderBy: '${dbHelper.DatabaseHelper.achievementsColumnStreak} DESC',
      limit: 1,
    );

    if (result.isNotEmpty) {
      return result.first[dbHelper.DatabaseHelper.achievementsColumnName]
          as String?;
    }

    return null;
  }

  void _completeReminder(Reminder reminder) async {
    final db = await dbHelper.DatabaseHelper.instance.database;

    // Get the last completion date from the database
    final result = await db.query(
      dbHelper.DatabaseHelper.remindersTable,
      where: '${dbHelper.DatabaseHelper.remindersColumnId} = ?',
      whereArgs: [reminder.id],
      columns: ['last_completion_date_millis'],
    );
    final lastCompletionDateMillis = result.isNotEmpty
        ? result.first['last_completion_date_millis'] as int?
        : null;

    // Calculate the current date in milliseconds since epoch
    final nowMillis = DateTime.now().millisecondsSinceEpoch;

    if (lastCompletionDateMillis == null ||
        !isSameDay(DateTime.fromMillisecondsSinceEpoch(nowMillis),
            DateTime.fromMillisecondsSinceEpoch(lastCompletionDateMillis))) {
      // Update the database with the new streak and the current date as the last completion date
      final rowsUpdated = await db.update(
        dbHelper.DatabaseHelper.remindersTable,
        {
          dbHelper.DatabaseHelper.remindersColumnStreak: reminder.streak + 1,
          'last_completion_date_millis': nowMillis,
        },
        where: '${dbHelper.DatabaseHelper.remindersColumnId} = ?',
        whereArgs: [reminder.id],
      );

      if (rowsUpdated > 0) {
        String? achievementName = await getAchievementName(reminder.streak + 1);
        setState(() {
          final index = reminders.indexWhere((r) => r.id == reminder.id);
          if (index != -1) {
            reminders[index] = reminder.copyWith(
              streak: reminder.streak + 1,
              lastCompletionDateMillis: nowMillis,
            );
          }
        });
        if (reminder.streak + 1 >= 1) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Achievement unlocked: $achievementName'),
              duration: const Duration(seconds: 10),
              behavior: SnackBarBehavior.floating,
            ),
          );
          setState(() {
            showConfetti = true;
          });
          confettiController.play();
        }
      }
    } else {
      print('Reminder already completed today');
    }
  }

  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  void _signOut() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
          ),
        ],
      ),
      body: Stack(
        children: [
          Center(
            child: reminders.isEmpty
                ? const Text('No reminders')
                : ListView.builder(
                    itemCount: reminders.length,
                    itemBuilder: (context, index) {
                      final reminder = reminders[index];
                      return Dismissible(
                        key: Key(reminder.id.toString()),
                        direction: DismissDirection.endToStart,
                        onDismissed: (direction) =>
                            _deleteReminder(reminder.id),
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          color: Colors.red,
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        child: ListTile(
                          title: Text(reminder.name),
                          subtitle: Text('Streak: ${reminder.streak}'),
                          trailing: ElevatedButton(
                            style: reminder.lastCompletionDate != null &&
                                    isSameDay(
                                        DateTime.now(),
                                        DateTime.fromMillisecondsSinceEpoch(
                                                reminder
                                                    .lastCompletionDateMillis!)
                                            .toLocal())
                                ? ButtonStyle(
                                    backgroundColor:
                                        MaterialStateProperty.all(Colors.green),
                                  )
                                : null,
                            onPressed: () => _completeReminder(reminder),
                            child: const Text('Complete'),
                          ),
                        ),
                      );
                    },
                  ),
          ),
    Visibility(
      visible: showConfetti,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConfettiWidget(
          confettiController: confettiController,
          blastDirection: -pi / 2, // shoot the confetti up
          emissionFrequency: 0.2, // adjust the emission frequency
          maxBlastForce: 50,
          minBlastForce: 20,
          numberOfParticles: 3, // increase the number of particles
          gravity: 0.05,
        ),
      ),
    ),
  ],
),
      floatingActionButton: FloatingActionButton(
        onPressed: _addReminder,
        child: const Icon(Icons.add),
        backgroundColor: Colors.pink,
      ),
    );
  }
}
