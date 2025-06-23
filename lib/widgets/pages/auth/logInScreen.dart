import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:platform_v2/config/constants.dart';
import 'package:platform_v2/config/provider.dart';
import 'package:platform_v2/services/uiServices/navigationService.dart';
import 'package:platform_v2/services/uiServices/snackBarService.dart';
import 'package:platform_v2/widgets/components/buildingBlocks/buttons/callToActionButton.dart';
import 'package:platform_v2/widgets/components/buildingBlocks/buttons/googleSignInButton.dart';

class LogInScreen extends ConsumerStatefulWidget {
  const LogInScreen({super.key});

  @override
  ConsumerState<LogInScreen> createState() => _LogInScreenState();
}

class _LogInScreenState extends ConsumerState<LogInScreen> {
  String email = '';
  String password = '';

  @override
  Widget build(BuildContext context) {
    final Logger logger = Logger("LogIn");

    void successfullyLogIn() {
      NavigationService.navigateTo('/app/companies');
    }

    // Sign in with google. If new account. cancel and delete newly created OAuth account.
    void googleSignInClicked() async {
      try {
        final userCred = await ref.read(authProvider.notifier).signinWithGoogle();

        if (!userCred?.additionalUserInfo?.isNewUser) {
          successfullyLogIn();
        } else {
          // await ref.read(authProvider.notifier).deleteAccount();
          SnackBarService.showMessage("Can't sign in with this account", Colors.red, duration: 4);
        }
      } on Exception catch (e) {
        logger.info("error signing in with google: $e");
        SnackBarService.showMessage("Google sign in error, Please try again later or Reload Page", Colors.red, duration: 4);
      }
    }

    void emailPasswordSignIn() async {
      try {
        await ref.read(authProvider.notifier).signInWithEmailAndPassword(email, password);
        successfullyLogIn();
      } on FirebaseAuthException catch (e) {
        logger.info('Error logging in with Firebase Auth Account: ${e.code}');
        String errorText = '';
        switch (e.code) {
          case 'network-request-failed':
            errorText = "Network Error";
          case 'user-not-found':
            errorText = "User not found";
          case 'wrong-password':
            errorText = "Wrong password";
          case 'invalid-credential':
            errorText = "Invalid Credentials";
          default:
            errorText = "Error";
        }
        SnackBarService.showMessage("Sign in Error: $errorText", Colors.red);
      }
    }

    return Container(
      padding: const EdgeInsets.all(32),
      margin: const EdgeInsets.all(12),
      decoration: kAuthBoxDecoration,
      width: 350,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        spacing: 24,
        children: [
          Image.asset(
            'assets/logo/logo.jpg',
            width: 300,
          ),
          Column(
            spacing: 2,
            children: [
              Text("Email", style: kTextBodyR),
              TextField(
                onChanged: (value) => setState(() {
                  email = value;
                }),
              ),
            ],
          ),
          Column(
            spacing: 2,
            children: [
              Text("Password", style: kTextBodyR),
              TextField(
                onChanged: (value) => setState(() {
                  password = value;
                }),
              ),
            ],
          ),
          GoogleSignInButton(onPressed: () => googleSignInClicked()),
          Wrap(
            spacing: 32,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              BackButton(
                onPressed: () => NavigationService.navigateTo('/auth/landingPage'),
              ),
              // CallToActionButton(onPressed: () => NavigationService.navigateTo('/app/companies'), buttonText: "Log in"),
              CallToActionButton(onPressed: () => emailPasswordSignIn(), buttonText: "Log in"),
            ],
          ),
        ],
      ),
    );
  }
}
