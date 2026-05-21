import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart'; // 🔹 Ensure this is in your pubspec.yaml
import '../providers/solved_papers_provider.dart';
import '../utils/app_colors.dart';
import 'widgets.dart/appbar_page.dart';
import 'widgets.dart/empty_state_widget.dart';
import 'solved_papers_year_wise_listing_page.dart';

class SolvedPapersPage extends StatefulWidget {
  const SolvedPapersPage({super.key});

  @override
  State<SolvedPapersPage> createState() => _SolvedPapersPageState();
}

class _SolvedPapersPageState extends State<SolvedPapersPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        context.read<SolvedPapersProvider>().fetchSolvedPapers()
    );
  }

  @override
  Widget build(BuildContext context) {
    final spProvider = context.watch<SolvedPapersProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF1FAF2),
      appBar: const CustomAppBar(height: 40, title: "Solved Papers"),
      body: spProvider.isLoading
          ? _buildShimmerLoading() // 🔹 Replaced CircularProgressIndicator
          : !spProvider.hasDataToShow
          ? const EmptyStateWidget(msg: "No solved papers are available at this time.")
          : ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
        itemCount: spProvider.papers.length,
        itemBuilder: (context, index) {
          final subjectData = spProvider.papers[index];
          final List years = subjectData['years'] ?? [];

          if (years.isEmpty) return const SizedBox.shrink();

          return _buildDynamicSubjectCard(subjectData);
        },
      ),
    );
  }

  // 🔹 New: Skeleton loading screen
  Widget _buildShimmerLoading() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
      itemCount: 6, // Show 6 skeleton cards
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            margin: const EdgeInsets.only(bottom: 15),
            height: 70, // Matches the approximate height of a collapsed ExpansionTile
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDynamicSubjectCard(dynamic subjectData) {
    final String subjectName = subjectData['subject'] ?? "Unknown";
    final List<dynamic> years = subjectData['years'] ?? [];
    final String subjectId = subjectData['id'].toString();

    final formattedName = subjectName.split(' ').map((str) => str.isNotEmpty
        ? '${str[0].toUpperCase()}${str.substring(1).toLowerCase()}'
        : '').join(' ');

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 4))],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          title: Text(formattedName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textHeadingBlack)),
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20, top: 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: years.map((year) => _buildYearButton(year.toString(), formattedName, subjectId)).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildYearButton(String year, String subjectName, String subjectId) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SolvedPapersYearWiseListingPage(
              subjectId: subjectId,
              subjectName: subjectName,
              year: year,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF4FACFE), Color(0xFF00F2FE)]),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: const Color(0xFF4FACFE).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Text(year, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
      ),
    );
  }
}