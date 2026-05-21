class StringUtils {
  /// Converts a string to Sentence case (e.g., "MATHS TEXTBOOK" -> "Maths textbook")
  /// Also removes leading/trailing whitespace to prevent UI alignment issues.
  static String toSentenceCase(String text) {
    // Check for null, empty, or strings that are just spaces
    if (text.isEmpty || text.trim().isEmpty) {
      return text;
    }

    // 1. Remove accidental leading/trailing spaces
    // 2. Convert the entire string to lowercase
    String cleaned = text.trim().toLowerCase();

    // 3. Find the first actual letter (a-z) and capitalize it
    return cleaned.replaceFirstMapped(
      RegExp(r'[a-z]'),
          (match) => match.group(0)!.toUpperCase(),
    );
  }
}