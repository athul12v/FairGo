// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'FairGo Rider';

  @override
  String get onboarding1Title => 'Go anywhere, anytime';

  @override
  String get onboarding1Subtitle =>
      'Cabs, autos, bikes — pick your ride and we\'ll get you there safely.';

  @override
  String get onboarding2Title => 'Send parcels instantly';

  @override
  String get onboarding2Subtitle =>
      'Same-day delivery for documents, packages and anything that fits.';

  @override
  String get onboarding3Title => 'Hire a driver for the day';

  @override
  String get onboarding3Subtitle =>
      'Your car, a professional driver. Hourly or full-day bookings.';

  @override
  String get onboarding4Title => 'Safe every trip';

  @override
  String get onboarding4Subtitle =>
      'SOS button, live trip sharing, and emergency contacts built in.';

  @override
  String get skip => 'Skip';

  @override
  String get next => 'Next';

  @override
  String get getStarted => 'Get Started';

  @override
  String get enterMobileNumber => 'Enter your mobile number';

  @override
  String get weWillSendOtp => 'We\'ll send you a verification code';

  @override
  String get getOtp => 'Get OTP';

  @override
  String get termsAndPrivacy =>
      'By continuing, you agree to our\nTerms of Service & Privacy Policy';

  @override
  String get verifyNumber => 'Verify your number';

  @override
  String codeSentTo(String phone) {
    return 'Code sent to $phone';
  }

  @override
  String get verify => 'Verify';

  @override
  String get resendCode => 'Resend OTP';

  @override
  String resendIn(String seconds) {
    return 'Resend code in 0:$seconds';
  }

  @override
  String get invalidOtp => 'Invalid OTP. Please check and try again.';

  @override
  String get whereTo => 'Where to?';

  @override
  String get home => 'Home';

  @override
  String get trips => 'Trips';

  @override
  String get wallet => 'Wallet';

  @override
  String get profile => 'Profile';

  @override
  String get selectService => 'Select Service';

  @override
  String get searchingDrivers => 'Searching for nearby drivers…';

  @override
  String get tripComplete => 'Trip Complete!';

  @override
  String get rateYourDriver => 'How was your trip with your driver?';

  @override
  String get submitRating => 'Submit Rating';

  @override
  String get cancel => 'Cancel';

  @override
  String get cancelSearch => 'Cancel Search';
}
