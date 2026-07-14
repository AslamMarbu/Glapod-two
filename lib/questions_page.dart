import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart'; // Added for the effect
import '../providers/question_provider.dart';
import '../models/question_year_model.dart';
import 'questions_year_wise_listing_page.dart';
import 'widgets.dart/appbar_page.dart';
import 'package:glapod/utils/app_colors.dart';
import 'widgets.dart/empty_state_widget.dart';

class QuestionsPage extends StatefulWidget {
  final String subjectId;
  final String subjectName;

  const QuestionsPage({
    super.key,
    required this.subjectId,
    required this.subjectName,
  });

  @override
  State<QuestionsPage> createState() => _QuestionsPageState();
}

class _QuestionsPageState extends State<QuestionsPage> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      context.read<QuestionProvider>().fetchYears(widget.subjectId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final qProvider = context.watch<QuestionProvider>();
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppColors.mintBackground,
      appBar: CustomAppBar(height: 40, title: widget.subjectName),
      body: qProvider.isLoading
          ? _buildShimmerLoading(width) // Replaced CircularProgressIndicator
          : qProvider.years.isEmpty
          ? const EmptyStateWidget(
              msg: "No years available for this subject yet.",
            )
          : ListView.builder(
              padding: EdgeInsets.all(width * 0.05),
              itemCount: qProvider.years.length,
              itemBuilder: (context, index) {
                return _buildYearCard(context, qProvider.years[index], width);
              },
            ),
    );
  }

  /// Shimmer loading skeleton that matches your card UI
  Widget _buildShimmerLoading(double width) {
    return ListView.builder(
      padding: EdgeInsets.all(width * 0.05),
      itemCount: 8, // Pre-render 8 skeleton items
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            margin: EdgeInsets.symmetric(vertical: width * 0.02),
            height: width * 0.22, // Approximate height of your ListTile card
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        );
      },
    );
  }

  Widget _buildYearCard(BuildContext context, YearSetData data, double width) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: width * 0.02),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(
          horizontal: width * 0.06,
          vertical: width * 0.025,
        ),
        title: Text(
          "Year ${data.year}",
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: width * 0.045,
            color: AppColors.textHeadingBlack,
          ),
        ),
        subtitle: Padding(
          padding: EdgeInsets.only(top: width * 0.01),
          child: Text(
            "${data.totalSets} Sets",
            style: TextStyle(
              color: AppColors.textSubtitle,
              fontSize: width * 0.035,
            ),
          ),
        ),
        trailing: Container(
          padding: EdgeInsets.all(width * 0.025),
          decoration: BoxDecoration(
            color: const Color(0xFF1B75BB).withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.arrow_forward_ios,
            size: width * 0.04,
            color: AppColors.primaryBlue,
          ),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => YearSetListingPage(
                subjectId: widget.subjectId,
                year: data.year,
              ),
            ),
          );
        },
      ),
    );
  }
}
