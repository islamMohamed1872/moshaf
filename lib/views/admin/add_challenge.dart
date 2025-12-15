import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../services/firestore_service.dart';

class AdminAddChallengeScreen extends StatefulWidget {
  const AdminAddChallengeScreen({super.key});

  @override
  State<AdminAddChallengeScreen> createState() => _AdminAddChallengeScreenState();
}

class _AdminAddChallengeScreenState extends State<AdminAddChallengeScreen> {
  final dateController = TextEditingController();
  final questionController = TextEditingController();
  final List<TextEditingController> optionControllers =
  List.generate(4, (_) => TextEditingController());
  int correctIndex = 0;

  @override
  Widget build(BuildContext context) {
    final fs = FirestoreService();

    return Scaffold(
      appBar: AppBar(title: const Text("Add Daily Challenge")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: questionController,
              decoration: const InputDecoration(
                labelText: "Question",
              ),
            ),
            const SizedBox(height: 12),

            const Text("Options:"),
            ...List.generate(4, (index) {
              return TextField(
                controller: optionControllers[index],
                decoration: InputDecoration(labelText: "Option ${index + 1}"),
              );
            }),

            const SizedBox(height: 12),
            DropdownButton<int>(
              value: correctIndex,
              items: List.generate(4, (i) => DropdownMenuItem(
                value: i,
                child: Text("Correct Answer: Option ${i + 1}"),
              )),
              onChanged: (v) => setState(() => correctIndex = v!),
            ),

            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {

                // Firebase.token.admin = true;

                final dateId = DateFormat('yyyy-MM-dd').format(DateTime.now());
                final question = questionController.text.trim();
                final options = optionControllers.map((e) => e.text.trim()).toList();

                if (dateId.isEmpty || question.isEmpty || options.contains("")) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(const SnackBar(content: Text("Fill all fields")));
                  return;
                }

                await fs.setChallenge(dateId, {
                  "question": question,
                  "options": options,
                  "correct_index": correctIndex,
                });

                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Challenge added!")));

                Navigator.pop(context);
              },
              child: const Text("Save Challenge"),
            )
          ],
        ),
      ),
    );
  }
}
