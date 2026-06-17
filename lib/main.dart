import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // 1. Import Provider
import 'login.dart';
import 'register_page.dart';
import 'storage/local_storage_service.dart';
import 'student_dashboard.dart';
import 'free_trial.dart';
import 'splash_screen.dart';
import 'activate_continue_page.dart';
import 'profile.dart';
import 'providers/study_provider.dart'; // 2. Import your StudyProvider
import 'providers/chapter_provider.dart';
import 'providers/notes_provider.dart';
import 'providers/video_provider.dart';
import 'providers/question_provider.dart';
import 'providers/paper_set_provider.dart';
import 'providers/question_bank_provider.dart';
import 'providers/question_view_provider.dart';
import 'providers/solved_papers_provider.dart';
import 'providers/prediction_provider.dart';
import 'providers/prediction_name_provider.dart';
import 'providers/prediction_tense_provider.dart';
import 'providers/prediction_opposite_provider.dart';
import 'providers/sample_paper_provider.dart';
import 'providers/textbook_provider.dart';
import 'providers/questions_year_wise_lprovider.dart';
import 'providers/solved_papers_yearwise_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  bool isLoggedIn = await LocalStorageService.isUserLoggedIn();

  // Default page for logged-out users
  Widget startPage = const MyHomePage();

  if (isLoggedIn) {
    final status = await LocalStorageService.getLicenseStatus();

    switch (status) {
      case LicenseStatus.needProfileUpdate:
        startPage = const ProfilePage();
        break;
      case LicenseStatus.activated:
        startPage = const StudentDashboardPage();
        break;
      case LicenseStatus.trialing:
        startPage = const FreeTrialPage();
        break;
      case LicenseStatus.expired:
      case LicenseStatus.trialExpired:
        startPage = const ActivateContinuePage();
        break;
      default:
        startPage = const MyHomePage();
    }
  }

  // 3. Wrap MyApp with MultiProvider
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => StudyProvider()),
        //   ChangeNotifierProvider(create: (_) => ChapterProvider()), // Add this
        ChangeNotifierProvider(create: (_) => NotesProvider()),
        ChangeNotifierProvider(create: (_) => VideoProvider()),
        ChangeNotifierProvider(create: (_) => QuestionProvider()),
        ChangeNotifierProvider(create: (_) => PaperSetProvider()),
        ChangeNotifierProvider(create: (_) => QuestionBankProvider()),
        ChangeNotifierProvider(create: (_) => QuestionViewProvider()),
        ChangeNotifierProvider(create: (_) => SolvedPapersProvider()),
        ChangeNotifierProvider(create: (_) => PredictionProvider()),
        ChangeNotifierProvider(create: (_) => PredictionGameProvider()),
        ChangeNotifierProvider(create: (_) => PredictionTenseProvider()),
        ChangeNotifierProvider(create: (_) => PredictionOppositeProvider()),
        ChangeNotifierProvider(create: (_) => SamplePaperProvider()),
        ChangeNotifierProvider(create: (_) => TextbookProvider()),
        ChangeNotifierProvider(create: (_) => YearwiseQPaperProvider()),
        ChangeNotifierProvider(create: (_) => SolvedPaperSetProvider()),
      ],
      child: MyApp(initialPage: startPage, isLoggedIn: isLoggedIn),
    ),
  );
}

class MyApp extends StatelessWidget {
  final Widget initialPage;
  final bool isLoggedIn;

  const MyApp({super.key, required this.initialPage, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Glapod',
      theme: ThemeData(
        fontFamily: 'Montserrat',
        colorScheme: const ColorScheme(
          brightness: Brightness.light,
          primary: Color.fromARGB(255, 0, 0, 0),
          onPrimary: Color.fromARGB(255, 255, 255, 255),
          secondary: Color.fromARGB(255, 28, 192, 178),
          onSecondary: Color.fromARGB(255, 134, 67, 67),
          error: Color(0xFFB00020),
          onError: Color(0xFFFFFFFF),
          surface: Color(0xFFFFFFFF),
          onSurface: Color(0xFF000000),
          outline: Color.fromARGB(255, 206, 204, 204),
        ),
        useMaterial3: true,
      ),
      // SplashScreen handles the navigation to initialPage internally
      home: SplashScreen(isLoggedIn: isLoggedIn),
      routes: {
        '/login': (context) => const MyHomePage(),
        '/register': (context) => const RegisterPage(),
        '/dashboard': (context) => const StudentDashboardPage(),
      },
    );
  }
}
