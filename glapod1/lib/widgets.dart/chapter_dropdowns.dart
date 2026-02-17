import 'package:flutter/material.dart';

class ChapterDropdowns extends StatelessWidget {
  const ChapterDropdowns({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(6, (index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: index == 5 ? 'Chapter n' : 'Chapter ${index + 1}',
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              border: const OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'Topic 1', child: Text('Topic 1')),
              DropdownMenuItem(value: 'Topic 2', child: Text('Topic 2')),
            ],
            onChanged: (value) {},
          ),
        );
      }),
    );
  }
}
