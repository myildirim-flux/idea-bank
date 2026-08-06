import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:idea_bank/core/constants.dart';
import 'package:idea_bank/features/cloud/presentation/cloud_providers.dart';
import 'package:idea_bank/features/auth/presentation/auth_providers.dart';
import 'package:idea_bank/features/notes/presentation/passphrase_setup_page.dart';
import 'package:idea_bank/features/auth/presentation/passphrase_providers.dart';
import 'package:idea_bank/features/auth/presentation/passphrase_authentication_page.dart';
import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  // Initialize FFI for desktop platforms
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Set up a global error handler
  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint('Caught Flutter Error: ${details.exception}');
    debugPrint('Stack trace: ${details.stack}');
    // You might want to report this to a logging service in production
  };

  runApp(const ProviderScope(child: NotesApp()));
}

class NotesApp extends ConsumerStatefulWidget {
  const NotesApp({super.key});

  @override
  ConsumerState<NotesApp> createState() => _NotesAppState();
}

/*testAppwrite() async{
  final client = Client()
        .setEndpoint(Env.appwriteEndpoint!)
        .setProject(Env.appwriteProjectId!);
  final databaseee = Databases(client);
  try {
        print("appwrite-1");
        final document = await databaseee.createDocument(
            databaseId: Env.appwriteDatabaseId!,
            collectionId: Env.appwriteTableId!,
            documentId: ID.unique(),
            data: { "title": "Hamlet" }
        );
        
        print("appwrite-2");
    } on AppwriteException catch(e) {
      
        print("appwrite-3");
        print(e);
    }
}*/

class _NotesAppState extends ConsumerState<NotesApp> {
  @override
  void initState() {
    //testAppwrite();
    super.initState();
    _restoreSessionOrCheckLoginStatus();
  }

  Future<void> _restoreSessionOrCheckLoginStatus() async {
    final authService = ref.read(authServiceProvider);

    // First, try to restore a previous session from secure storage
    final user = await authService.restoreSession();
    if (mounted) {
      if (user != null) {
        debugPrint('_NotesAppState: Session restored from storage.');
        ref.read(authStatusProvider.notifier).state = AuthStatus.loggedIn;
      } else {
        debugPrint(
          '_NotesAppState: No valid session found. User is logged out.',
        );
        ref.read(authStatusProvider.notifier).state = AuthStatus.loggedOut;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasMasterKeyAsync = ref.watch(hasMasterKeyProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Idea Bank',
      theme: ThemeData(
        colorScheme: ColorScheme.dark(
          primary: AppColors.primary,
          secondary: AppColors.accent,
          surface: AppColors.surfaceDark,
          error: AppColors.error,
          onPrimary: AppColors.white,
          onSecondary: AppColors.white,
          onSurface: AppColors.textPrimary,
          onError: AppColors.white,
        ),
        brightness: Brightness.dark,
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.scaffoldBackground,

        // AppBar Theme
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.surfaceDark,
          elevation: 0,
          scrolledUnderElevation: 2,
          foregroundColor: AppColors.textPrimary,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: AppSizes.font_20,
            letterSpacing: 0.15,
          ),
        ),

        // Card Theme
        cardTheme: CardThemeData(
          color: AppColors.surfaceDark,
          elevation: 2,
          shadowColor: AppColors.shadow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),

        // Elevated Button Theme
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            elevation: 2,
            shadowColor: AppColors.primary.withValues(alpha: 0.3),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),

        // Outlined Button Theme
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textPrimary,
            side: BorderSide(
              color: AppColors.blueGrey600.withValues(alpha: 0.5),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),

        // Text Button Theme
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),

        // Input Decoration Theme
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surfaceDark,
          labelStyle: const TextStyle(color: AppColors.textSecondary),
          hintStyle: const TextStyle(color: AppColors.textHint),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: AppColors.blueGrey700.withValues(alpha: 0.3),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: AppColors.blueGrey700.withValues(alpha: 0.3),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.error),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),

        // Floating Action Button Theme
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),

        // Drawer Theme
        drawerTheme: const DrawerThemeData(
          backgroundColor: AppColors.surfaceDark,
        ),

        // Dialog Theme
        dialogTheme: DialogThemeData(
          backgroundColor: AppColors.surfaceLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          titleTextStyle: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),

        // Snackbar Theme
        snackBarTheme: SnackBarThemeData(
          backgroundColor: AppColors.surfaceLight,
          contentTextStyle: const TextStyle(color: AppColors.textPrimary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          behavior: SnackBarBehavior.floating,
        ),

        // Divider Theme
        dividerTheme: DividerThemeData(
          color: AppColors.blueGrey700.withValues(alpha: 0.3),
          thickness: 1,
        ),

        // List Tile Theme
        listTileTheme: const ListTileThemeData(
          iconColor: AppColors.textSecondary,
          textColor: AppColors.textPrimary,
        ),
      ),
      home: hasMasterKeyAsync.when(
        data: (hasKey) {
          if (hasKey) {
            return const PassphraseAuthenticationPage();
          } else {
            // No local key - check if we should recover from cloud
            final shouldRecoverAsync = ref.watch(
              shouldRecoverFromCloudProvider,
            );
            return shouldRecoverAsync.when(
              data: (shouldRecover) {
                if (shouldRecover) {
                  // User has cloud settings - route to authentication for recovery
                  return const PassphraseAuthenticationPage();
                } else {
                  // No cloud settings - route to setup for new passphrase
                  return const PassphraseSetupPage();
                }
              },
              loading: () => const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              ),
              error: (err, stack) {
                // On error, default to setup page
                return const PassphraseSetupPage();
              },
            );
          }
        },
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (err, stack) =>
            Scaffold(body: Center(child: Text('Error: \$err'))),
      ),
    );
  }
}
