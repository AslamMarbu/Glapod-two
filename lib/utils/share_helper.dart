import 'package:glapod/constants/api_constants.dart';

class ShareHelper {
  /// Formats a teaser message for sharing questions and answers.
  /// Shows the full question but only a snippet of the answer.
  static String getQuestionShareText({
    required String question,
    required String answer,
  }) {
    // 1. Clean HTML tags (if any)
    String cleanQ = question.replaceAll(RegExp(r'<[^>]*>'), '').trim();
    String cleanA = answer.replaceAll(RegExp(r'<[^>]*>'), '').trim();

    // 2. Logic: Show 1/3 of answer if < 90 chars, otherwise cap at 80
    String answerTeaser;
    int totalLen = cleanA.length;

    if (totalLen == 0) {
      answerTeaser = "[Open app to see answer]";
    } else if (totalLen < 30) {
      int oneThird = (totalLen / 3).floor();
      answerTeaser = "${cleanA.substring(0, oneThird)}...";
    } else {
      answerTeaser = "${cleanA.substring(0, 30)}...";
    }

    // 3. Construct the final professional message
    return "❓ *Question:*\n$cleanQ\n\n"
        "💡 *Answer:*\n$answerTeaser\n\n"
        "📖 *Read the full answer on Glapod App!*\n"
        "Get solved papers, Q-banks, and more.\n\n"
        "👇 *Download Link:*\n"
        "${ApiConstants.appLink}";
  }
}