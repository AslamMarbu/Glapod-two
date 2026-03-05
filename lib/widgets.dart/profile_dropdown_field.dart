import 'package:flutter/material.dart';
Widget buildDropdownField({
  required String label,
  required String? value,
  required List<dynamic> items,
  required Function(String?) onChanged,
}) {
  // --- SAFETY CHECK ---
  // Ensure 'value' actually exists in the 'items' list.
  // If not, set it to null so the dropdown doesn't crash.
  bool valueExists = items.any((item) => item["id"].toString() == value);
  String? validatedValue = valueExists ? value : null;

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 40),
    child: Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 20),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButtonFormField<String>(
                value: validatedValue, // Use the validated value
                isExpanded: true,
                alignment: AlignmentDirectional.centerEnd,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isCollapsed: true,
                  contentPadding: EdgeInsets.zero,
                ),
                icon: const Icon(Icons.arrow_drop_down),
                hint: const Align(
                    alignment: Alignment.centerRight,
                    child: Text("Select", style: TextStyle(fontWeight: FontWeight.bold))
                ),
                // Ensure the map uses the correct key from your API
                items: items.map<DropdownMenuItem<String>>((item) {
                  return DropdownMenuItem<String>(
                    value: item["id"].toString(),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        item["class"].toString(), // Use the key from your API (e.g., 'class_name' or 'class')
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                }).toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}