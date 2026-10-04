import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// No description provided for @chooseStartingDay.
  ///
  /// In en, this message translates to:
  /// **'Choose starting day'**
  String get chooseStartingDay;

  /// No description provided for @chooseStartingDayHint.
  ///
  /// In en, this message translates to:
  /// **'Start this cycle at any day, such as Push 2. Earlier days are marked unrecorded, not completed or skipped workouts. The next cycle starts at day 1. Available only before recording this cycle.'**
  String get chooseStartingDayHint;

  /// No description provided for @startingDayUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Finish or discard the draft first. The starting day cannot change after this cycle has recorded activity or today\'s action is locked.'**
  String get startingDayUnavailable;

  /// No description provided for @beforeStartingDay.
  ///
  /// In en, this message translates to:
  /// **'⊖ Before starting day · not recorded'**
  String get beforeStartingDay;

  /// No description provided for @redoTodayAction.
  ///
  /// In en, this message translates to:
  /// **'Restore today\'s action'**
  String get redoTodayAction;

  /// No description provided for @redoTodayHint.
  ///
  /// In en, this message translates to:
  /// **'Today\'s action was undone. Restore the original log and cycle state, or record a new action to replace it.'**
  String get redoTodayHint;

  /// No description provided for @todayActionRestored.
  ///
  /// In en, this message translates to:
  /// **'Today\'s action restored.'**
  String get todayActionRestored;

  /// No description provided for @redoUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Cannot restore: the date, plan or today\'s action has changed.'**
  String get redoUnavailable;

  /// No description provided for @discardWorkoutDraft.
  ///
  /// In en, this message translates to:
  /// **'Discard draft'**
  String get discardWorkoutDraft;

  /// No description provided for @discardWorkoutDraftHint.
  ///
  /// In en, this message translates to:
  /// **'Discard these unsaved inputs? Saved workout records will not change.'**
  String get discardWorkoutDraftHint;

  /// No description provided for @continueWorkoutDraft.
  ///
  /// In en, this message translates to:
  /// **'Continue workout draft'**
  String get continueWorkoutDraft;

  /// No description provided for @workoutDraftHint.
  ///
  /// In en, this message translates to:
  /// **'Inputs are saved locally as a draft. Leave and resume anytime. Only finishing advances the cycle. Blank sets are not logged.'**
  String get workoutDraftHint;

  /// No description provided for @weightInputLabel.
  ///
  /// In en, this message translates to:
  /// **'kg / text'**
  String get weightInputLabel;

  /// No description provided for @textWeightHandling.
  ///
  /// In en, this message translates to:
  /// **'Text weight: numeric value'**
  String get textWeightHandling;

  /// No description provided for @textWeightNull.
  ///
  /// In en, this message translates to:
  /// **'null · unknown / exclude from PR'**
  String get textWeightNull;

  /// No description provided for @textWeightZero.
  ///
  /// In en, this message translates to:
  /// **'0 · no measurable external load'**
  String get textWeightZero;

  /// No description provided for @prTitle.
  ///
  /// In en, this message translates to:
  /// **'Exercise PR'**
  String get prTitle;

  /// No description provided for @prExplanation.
  ///
  /// In en, this message translates to:
  /// **'Choose only the exercises you want to track. Curve: daily maximum logged load in kg, not estimated 1RM. Text mapped to null is excluded; 0 is included. Manual entries remain separate from workouts.'**
  String get prExplanation;

  /// No description provided for @trackExercise.
  ///
  /// In en, this message translates to:
  /// **'Choose an exercise to track'**
  String get trackExercise;

  /// No description provided for @addPr.
  ///
  /// In en, this message translates to:
  /// **'Add manual PR'**
  String get addPr;

  /// No description provided for @manualPr.
  ///
  /// In en, this message translates to:
  /// **'Manual PR'**
  String get manualPr;

  /// No description provided for @workoutPr.
  ///
  /// In en, this message translates to:
  /// **'Workout daily maximum'**
  String get workoutPr;

  /// No description provided for @removeTracking.
  ///
  /// In en, this message translates to:
  /// **'Stop tracking (keep records)'**
  String get removeTracking;

  /// No description provided for @noPr.
  ///
  /// In en, this message translates to:
  /// **'No numeric weight records yet.'**
  String get noPr;

  /// No description provided for @cardioTitle.
  ///
  /// In en, this message translates to:
  /// **'Cardio'**
  String get cardioTitle;

  /// No description provided for @cardioHint.
  ///
  /// In en, this message translates to:
  /// **'Independent of your strength cycle. Also available on rest days.'**
  String get cardioHint;

  /// No description provided for @addCardio.
  ///
  /// In en, this message translates to:
  /// **'Add cardio'**
  String get addCardio;

  /// No description provided for @cardioActivity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get cardioActivity;

  /// No description provided for @cardioMinutes.
  ///
  /// In en, this message translates to:
  /// **'Duration (minutes)'**
  String get cardioMinutes;

  /// No description provided for @cardioDistance.
  ///
  /// In en, this message translates to:
  /// **'Distance (km, optional)'**
  String get cardioDistance;

  /// No description provided for @cardioNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get cardioNotes;

  /// No description provided for @cardioPresets.
  ///
  /// In en, this message translates to:
  /// **'Walking,Running,Cycling,Swimming,Elliptical,Rowing,Stair climbing,Jump rope'**
  String get cardioPresets;

  /// No description provided for @invalidFitnessValue.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid name and finite non-negative values. Cardio duration must be greater than zero.'**
  String get invalidFitnessValue;

  /// No description provided for @dateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get dateLabel;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Three parts. One daily log.'**
  String get appTagline;

  /// No description provided for @appIntroduction.
  ///
  /// In en, this message translates to:
  /// **'Logria brings fitness, nutrition and body measurements into a private daily journal. Track training cycles, meals and progress, then copy your logs whenever you want to review them.'**
  String get appIntroduction;

  /// No description provided for @softwareDetails.
  ///
  /// In en, this message translates to:
  /// **'About Logria'**
  String get softwareDetails;

  /// No description provided for @developers.
  ///
  /// In en, this message translates to:
  /// **'Developers'**
  String get developers;

  /// No description provided for @developerProfile.
  ///
  /// In en, this message translates to:
  /// **'Developer on GitHub'**
  String get developerProfile;

  /// No description provided for @sourceCode.
  ///
  /// In en, this message translates to:
  /// **'Source code'**
  String get sourceCode;

  /// No description provided for @privacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Local and private'**
  String get privacyTitle;

  /// No description provided for @privacySummary.
  ///
  /// In en, this message translates to:
  /// **'Records stay on this device. No account, cloud sync, analytics or built-in AI requests. GitHub links open in your browser only when tapped. Copying puts logs on the system clipboard.'**
  String get privacySummary;

  /// No description provided for @firstReleaseScope.
  ///
  /// In en, this message translates to:
  /// **'Current features'**
  String get firstReleaseScope;

  /// No description provided for @firstReleaseScopeHint.
  ///
  /// In en, this message translates to:
  /// **'Fitness with resumable drafts, exercise PR curves, cardio, nutrition, body, daily logs and calendar are available. JSON import/export and weight-based nutrition templates are planned for later versions.'**
  String get firstReleaseScopeHint;

  /// No description provided for @openSourceLicenses.
  ///
  /// In en, this message translates to:
  /// **'Open-source licenses'**
  String get openSourceLicenses;

  /// No description provided for @linkCopiedFallback.
  ///
  /// In en, this message translates to:
  /// **'No browser could open this link. The URL was copied instead.'**
  String get linkCopiedFallback;

  /// No description provided for @previousMonth.
  ///
  /// In en, this message translates to:
  /// **'Previous month'**
  String get previousMonth;

  /// No description provided for @nextMonth.
  ///
  /// In en, this message translates to:
  /// **'Next month'**
  String get nextMonth;

  /// No description provided for @locateCycle.
  ///
  /// In en, this message translates to:
  /// **'Locate a training cycle'**
  String get locateCycle;

  /// No description provided for @allCycles.
  ///
  /// In en, this message translates to:
  /// **'All cycles'**
  String get allCycles;

  /// No description provided for @cycleCalendarHint.
  ///
  /// In en, this message translates to:
  /// **'Colors mark cycle spans, not scheduled workouts. Icons mark recorded activity. Select a cycle to locate it and highlight its dates.'**
  String get cycleCalendarHint;

  /// No description provided for @copySelectedLog.
  ///
  /// In en, this message translates to:
  /// **'Copy this date\'s log'**
  String get copySelectedLog;

  /// No description provided for @dateLogCopied.
  ///
  /// In en, this message translates to:
  /// **'Log for {date} copied.'**
  String dateLogCopied(Object date);

  /// No description provided for @calendarLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load calendar: {error}'**
  String calendarLoadError(Object error);

  /// No description provided for @noDateTraining.
  ///
  /// In en, this message translates to:
  /// **'No training or rest recorded on this date.'**
  String get noDateTraining;

  /// No description provided for @noDateFood.
  ///
  /// In en, this message translates to:
  /// **'No meals recorded on this date.'**
  String get noDateFood;

  /// No description provided for @noDateBody.
  ///
  /// In en, this message translates to:
  /// **'No body measurements recorded on this date.'**
  String get noDateBody;

  /// No description provided for @copyTodayLog.
  ///
  /// In en, this message translates to:
  /// **'Copy today\'s log'**
  String get copyTodayLog;

  /// No description provided for @copyTodaySection.
  ///
  /// In en, this message translates to:
  /// **'Copy {section}'**
  String copyTodaySection(Object section);

  /// No description provided for @openModule.
  ///
  /// In en, this message translates to:
  /// **'Open {module}'**
  String openModule(Object module);

  /// No description provided for @refreshToday.
  ///
  /// In en, this message translates to:
  /// **'Refresh today\'s log'**
  String get refreshToday;

  /// No description provided for @todayCopyHint.
  ///
  /// In en, this message translates to:
  /// **'Copy training, meals, nutrition totals and today\'s measurements together, or copy a section below.'**
  String get todayCopyHint;

  /// No description provided for @todayLogCopied.
  ///
  /// In en, this message translates to:
  /// **'Today\'s log copied.'**
  String get todayLogCopied;

  /// No description provided for @todayLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load today\'s log: {error}'**
  String todayLoadError(Object error);

  /// No description provided for @todayCopyFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not copy today\'s log: {error}'**
  String todayCopyFailed(Object error);

  /// No description provided for @noTodayTraining.
  ///
  /// In en, this message translates to:
  /// **'No training or rest recorded today.'**
  String get noTodayTraining;

  /// No description provided for @noTodayFood.
  ///
  /// In en, this message translates to:
  /// **'No meals recorded today.'**
  String get noTodayFood;

  /// No description provided for @noTodayBody.
  ///
  /// In en, this message translates to:
  /// **'No body measurements recorded today.'**
  String get noTodayBody;

  /// No description provided for @trainingRecorded.
  ///
  /// In en, this message translates to:
  /// **'Training recorded'**
  String get trainingRecorded;

  /// No description provided for @mealTotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Meal totals'**
  String get mealTotalLabel;

  /// No description provided for @manualTotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Manual daily total'**
  String get manualTotalLabel;

  /// No description provided for @caloriesEstimatedLabel.
  ///
  /// In en, this message translates to:
  /// **'Calories estimated from P/C/F'**
  String get caloriesEstimatedLabel;

  /// No description provided for @caloriesManualLabel.
  ///
  /// In en, this message translates to:
  /// **'Calories entered manually'**
  String get caloriesManualLabel;

  /// No description provided for @missingNutritionHint.
  ///
  /// In en, this message translates to:
  /// **'— means unrecorded, not zero. Meal totals may be partial.'**
  String get missingNutritionHint;

  /// No description provided for @nutrientGoal.
  ///
  /// In en, this message translates to:
  /// **'Goal'**
  String get nutrientGoal;

  /// No description provided for @nutrientLimit.
  ///
  /// In en, this message translates to:
  /// **'Limit'**
  String get nutrientLimit;

  /// No description provided for @remainingAllowance.
  ///
  /// In en, this message translates to:
  /// **'{amount} {unit} available'**
  String remainingAllowance(Object amount, Object unit);

  /// No description provided for @goalReached.
  ///
  /// In en, this message translates to:
  /// **'Goal reached'**
  String get goalReached;

  /// No description provided for @bodyMeasurements.
  ///
  /// In en, this message translates to:
  /// **'Measurements'**
  String get bodyMeasurements;

  /// No description provided for @recordMeasurements.
  ///
  /// In en, this message translates to:
  /// **'Record measurements'**
  String get recordMeasurements;

  /// No description provided for @bodyOptionalHint.
  ///
  /// In en, this message translates to:
  /// **'Fill only what you measured. Blank fields keep existing records; use Delete to remove a record.'**
  String get bodyOptionalHint;

  /// No description provided for @notRecorded.
  ///
  /// In en, this message translates to:
  /// **'Not recorded on this date'**
  String get notRecorded;

  /// No description provided for @bodyTrend.
  ///
  /// In en, this message translates to:
  /// **'Trends & history'**
  String get bodyTrend;

  /// No description provided for @measurementType.
  ///
  /// In en, this message translates to:
  /// **'Measurement'**
  String get measurementType;

  /// No description provided for @last30Days.
  ///
  /// In en, this message translates to:
  /// **'30 days'**
  String get last30Days;

  /// No description provided for @last90Days.
  ///
  /// In en, this message translates to:
  /// **'90 days'**
  String get last90Days;

  /// No description provided for @allHistory.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allHistory;

  /// No description provided for @latestMeasurement.
  ///
  /// In en, this message translates to:
  /// **'Latest as of selected date'**
  String get latestMeasurement;

  /// No description provided for @noBodyHistory.
  ///
  /// In en, this message translates to:
  /// **'No measurements in this period. Record a value or choose a longer period.'**
  String get noBodyHistory;

  /// No description provided for @deleteMeasurement.
  ///
  /// In en, this message translates to:
  /// **'Delete measurement?'**
  String get deleteMeasurement;

  /// No description provided for @deleteMeasurementHint.
  ///
  /// In en, this message translates to:
  /// **'Only this measurement on this date will be removed.'**
  String get deleteMeasurementHint;

  /// No description provided for @invalidBodyValue.
  ///
  /// In en, this message translates to:
  /// **'Enter a positive number. Body fat must be at most 100%.'**
  String get invalidBodyValue;

  /// No description provided for @bodyLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load measurements: {error}'**
  String bodyLoadError(Object error);

  /// No description provided for @bodyWeight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get bodyWeight;

  /// No description provided for @bodyHeight.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get bodyHeight;

  /// No description provided for @bodyFat.
  ///
  /// In en, this message translates to:
  /// **'Body fat'**
  String get bodyFat;

  /// No description provided for @bodyWaist.
  ///
  /// In en, this message translates to:
  /// **'Waist'**
  String get bodyWaist;

  /// No description provided for @bodyArm.
  ///
  /// In en, this message translates to:
  /// **'Arm'**
  String get bodyArm;

  /// No description provided for @bodyChest.
  ///
  /// In en, this message translates to:
  /// **'Chest'**
  String get bodyChest;

  /// No description provided for @bodyHip.
  ///
  /// In en, this message translates to:
  /// **'Hip'**
  String get bodyHip;

  /// No description provided for @bodyThigh.
  ///
  /// In en, this message translates to:
  /// **'Thigh'**
  String get bodyThigh;

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Logria'**
  String get appTitle;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @fitness.
  ///
  /// In en, this message translates to:
  /// **'Fitness'**
  String get fitness;

  /// No description provided for @nutrition.
  ///
  /// In en, this message translates to:
  /// **'Nutrition'**
  String get nutrition;

  /// No description provided for @body.
  ///
  /// In en, this message translates to:
  /// **'Body'**
  String get body;

  /// No description provided for @calendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendar;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @systemDefault.
  ///
  /// In en, this message translates to:
  /// **'Follow system language'**
  String get systemDefault;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @chinese.
  ///
  /// In en, this message translates to:
  /// **'简体中文'**
  String get chinese;

  /// No description provided for @offlineReady.
  ///
  /// In en, this message translates to:
  /// **'Your offline data foundation is ready. More features are on the way.'**
  String get offlineReady;

  /// No description provided for @todayDescription.
  ///
  /// In en, this message translates to:
  /// **'Review today\'s training, food, nutrition, and body records.'**
  String get todayDescription;

  /// No description provided for @fitnessDescription.
  ///
  /// In en, this message translates to:
  /// **'Manage training cycles, exercises, sets, reps, load, and RIR.'**
  String get fitnessDescription;

  /// No description provided for @nutritionDescription.
  ///
  /// In en, this message translates to:
  /// **'Keep food notes separate from daily nutrition totals.'**
  String get nutritionDescription;

  /// No description provided for @nutritionLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load nutrition data: {error}'**
  String nutritionLoadError(Object error);

  /// No description provided for @dailyIntake.
  ///
  /// In en, this message translates to:
  /// **'Daily intake'**
  String get dailyIntake;

  /// No description provided for @intakeIndependentNote.
  ///
  /// In en, this message translates to:
  /// **'Automatically summed from meals. Blank nutrients remain unrecorded; totals may be partial.'**
  String get intakeIndependentNote;

  /// No description provided for @manualDailyTotal.
  ///
  /// In en, this message translates to:
  /// **'Manual daily total. Meal changes will not update these values until you restore meal totals.'**
  String get manualDailyTotal;

  /// No description provided for @useMealTotals.
  ///
  /// In en, this message translates to:
  /// **'Restore meal totals'**
  String get useMealTotals;

  /// No description provided for @carbohydrateGoal.
  ///
  /// In en, this message translates to:
  /// **'Carbohydrate goal (g)'**
  String get carbohydrateGoal;

  /// No description provided for @fatGoal.
  ///
  /// In en, this message translates to:
  /// **'Fat goal (g)'**
  String get fatGoal;

  /// No description provided for @estimateCalories.
  ///
  /// In en, this message translates to:
  /// **'Estimate calories automatically'**
  String get estimateCalories;

  /// No description provided for @caloriesShort.
  ///
  /// In en, this message translates to:
  /// **'Calories'**
  String get caloriesShort;

  /// No description provided for @dailyGoals.
  ///
  /// In en, this message translates to:
  /// **'Daily goals'**
  String get dailyGoals;

  /// No description provided for @setGoals.
  ///
  /// In en, this message translates to:
  /// **'Set goals'**
  String get setGoals;

  /// No description provided for @setNutritionGoals.
  ///
  /// In en, this message translates to:
  /// **'Nutrition goals'**
  String get setNutritionGoals;

  /// No description provided for @proteinGoal.
  ///
  /// In en, this message translates to:
  /// **'Protein goal'**
  String get proteinGoal;

  /// No description provided for @proteinGoalGrams.
  ///
  /// In en, this message translates to:
  /// **'Protein goal (g)'**
  String get proteinGoalGrams;

  /// No description provided for @calorieLimit.
  ///
  /// In en, this message translates to:
  /// **'Calorie target / limit'**
  String get calorieLimit;

  /// No description provided for @calorieLimitKcal.
  ///
  /// In en, this message translates to:
  /// **'Calorie target / limit (kcal)'**
  String get calorieLimitKcal;

  /// No description provided for @noNutritionGoals.
  ///
  /// In en, this message translates to:
  /// **'Set P, C, F or calorie goals to see progress here.'**
  String get noNutritionGoals;

  /// No description provided for @blankGoalHint.
  ///
  /// In en, this message translates to:
  /// **'Leave a field blank to turn that goal off.'**
  String get blankGoalHint;

  /// No description provided for @remainingAmount.
  ///
  /// In en, this message translates to:
  /// **'{amount} {unit} remaining'**
  String remainingAmount(Object amount, Object unit);

  /// No description provided for @overLimitAmount.
  ///
  /// In en, this message translates to:
  /// **'{amount} {unit} over the limit'**
  String overLimitAmount(Object amount, Object unit);

  /// No description provided for @goalExceededAmount.
  ///
  /// In en, this message translates to:
  /// **'Goal exceeded by {amount} {unit}'**
  String goalExceededAmount(Object amount, Object unit);

  /// No description provided for @foodLog.
  ///
  /// In en, this message translates to:
  /// **'Food notes'**
  String get foodLog;

  /// No description provided for @foodLogIndependentNote.
  ///
  /// In en, this message translates to:
  /// **'Describe each meal. Nutrition values are optional and can be added later. Blank macros count as zero only for calorie estimation.'**
  String get foodLogIndependentNote;

  /// No description provided for @addFoodNote.
  ///
  /// In en, this message translates to:
  /// **'Add meal'**
  String get addFoodNote;

  /// No description provided for @editFoodNote.
  ///
  /// In en, this message translates to:
  /// **'Edit meal'**
  String get editFoodNote;

  /// No description provided for @emptyFoodLog.
  ///
  /// In en, this message translates to:
  /// **'No food notes for this date.'**
  String get emptyFoodLog;

  /// No description provided for @foodNoteHint.
  ///
  /// In en, this message translates to:
  /// **'What did you eat?'**
  String get foodNoteHint;

  /// No description provided for @foodNoteRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a food note before saving.'**
  String get foodNoteRequired;

  /// No description provided for @copyFoodLog.
  ///
  /// In en, this message translates to:
  /// **'Copy food notes'**
  String get copyFoodLog;

  /// No description provided for @foodLogCopied.
  ///
  /// In en, this message translates to:
  /// **'Food notes copied.'**
  String get foodLogCopied;

  /// No description provided for @copyIntake.
  ///
  /// In en, this message translates to:
  /// **'Copy nutrition totals'**
  String get copyIntake;

  /// No description provided for @intakeCopied.
  ///
  /// In en, this message translates to:
  /// **'Nutrition totals copied.'**
  String get intakeCopied;

  /// No description provided for @foodNoteOptions.
  ///
  /// In en, this message translates to:
  /// **'Food note options'**
  String get foodNoteOptions;

  /// No description provided for @deleteFoodNoteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this food note?'**
  String get deleteFoodNoteTitle;

  /// No description provided for @deleteFoodNoteBody.
  ///
  /// In en, this message translates to:
  /// **'This only deletes the selected note.'**
  String get deleteFoodNoteBody;

  /// No description provided for @previousDay.
  ///
  /// In en, this message translates to:
  /// **'Previous day'**
  String get previousDay;

  /// No description provided for @nextDay.
  ///
  /// In en, this message translates to:
  /// **'Next day'**
  String get nextDay;

  /// No description provided for @proteinGrams.
  ///
  /// In en, this message translates to:
  /// **'Protein (g)'**
  String get proteinGrams;

  /// No description provided for @carbohydrateGrams.
  ///
  /// In en, this message translates to:
  /// **'Carbohydrate (g)'**
  String get carbohydrateGrams;

  /// No description provided for @fatGrams.
  ///
  /// In en, this message translates to:
  /// **'Fat (g)'**
  String get fatGrams;

  /// No description provided for @caloriesKcal.
  ///
  /// In en, this message translates to:
  /// **'Calories (kcal)'**
  String get caloriesKcal;

  /// No description provided for @invalidNutritionValue.
  ///
  /// In en, this message translates to:
  /// **'Enter non-negative numbers, or leave fields blank.'**
  String get invalidNutritionValue;

  /// No description provided for @invalidTargetValue.
  ///
  /// In en, this message translates to:
  /// **'Goals must be positive numbers, or left blank.'**
  String get invalidTargetValue;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @bodyDescription.
  ///
  /// In en, this message translates to:
  /// **'Record body weight, body fat, and measurements when needed.'**
  String get bodyDescription;

  /// No description provided for @calendarDescription.
  ///
  /// In en, this message translates to:
  /// **'Review all records by date and training cycle.'**
  String get calendarDescription;

  /// No description provided for @selectTrainingCycle.
  ///
  /// In en, this message translates to:
  /// **'Choose a training cycle'**
  String get selectTrainingCycle;

  /// No description provided for @templateIntro.
  ///
  /// In en, this message translates to:
  /// **'Start with a template. Planned rest days can be taken earlier in each cycle.'**
  String get templateIntro;

  /// No description provided for @pplDescription.
  ///
  /// In en, this message translates to:
  /// **'Push, Pull, and Legs followed by one movable rest day'**
  String get pplDescription;

  /// No description provided for @ppl2Description.
  ///
  /// In en, this message translates to:
  /// **'Two PPL blocks, each followed by one movable rest day'**
  String get ppl2Description;

  /// No description provided for @fourSplit.
  ///
  /// In en, this message translates to:
  /// **'Four-day split'**
  String get fourSplit;

  /// No description provided for @fourSplitDescription.
  ///
  /// In en, this message translates to:
  /// **'Chest, Back, Shoulders, and Legs followed by one movable rest day'**
  String get fourSplitDescription;

  /// No description provided for @chest.
  ///
  /// In en, this message translates to:
  /// **'Chest'**
  String get chest;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @shoulders.
  ///
  /// In en, this message translates to:
  /// **'Shoulders'**
  String get shoulders;

  /// No description provided for @legs.
  ///
  /// In en, this message translates to:
  /// **'Legs'**
  String get legs;

  /// No description provided for @rest.
  ///
  /// In en, this message translates to:
  /// **'Rest'**
  String get rest;

  /// No description provided for @push.
  ///
  /// In en, this message translates to:
  /// **'Push'**
  String get push;

  /// No description provided for @pull.
  ///
  /// In en, this message translates to:
  /// **'Pull'**
  String get pull;

  /// No description provided for @useTemplate.
  ///
  /// In en, this message translates to:
  /// **'Use this template'**
  String get useTemplate;

  /// No description provided for @createPlanError.
  ///
  /// In en, this message translates to:
  /// **'Could not create plan: {error}'**
  String createPlanError(Object error);

  /// No description provided for @cycleNumber.
  ///
  /// In en, this message translates to:
  /// **'Cycle {number}'**
  String cycleNumber(int number);

  /// No description provided for @editPlan.
  ///
  /// In en, this message translates to:
  /// **'Edit plan'**
  String get editPlan;

  /// No description provided for @switchPlan.
  ///
  /// In en, this message translates to:
  /// **'Switch plan'**
  String get switchPlan;

  /// No description provided for @chooseDifferentPlan.
  ///
  /// In en, this message translates to:
  /// **'Choose a different plan'**
  String get chooseDifferentPlan;

  /// No description provided for @switchPlanIntro.
  ///
  /// In en, this message translates to:
  /// **'A new cycle will start. Your previous plan and workout history will be kept.'**
  String get switchPlanIntro;

  /// No description provided for @switchPlanConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Switch to {plan}?'**
  String switchPlanConfirmTitle(Object plan);

  /// No description provided for @switchPlanConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'The current plan will become inactive. Its history stays available, and the new plan starts at cycle 1.'**
  String get switchPlanConfirmBody;

  /// No description provided for @confirmSwitch.
  ///
  /// In en, this message translates to:
  /// **'Switch plan'**
  String get confirmSwitch;

  /// No description provided for @workoutHistory.
  ///
  /// In en, this message translates to:
  /// **'Workout history'**
  String get workoutHistory;

  /// No description provided for @current.
  ///
  /// In en, this message translates to:
  /// **'Up next'**
  String get current;

  /// No description provided for @startWorkout.
  ///
  /// In en, this message translates to:
  /// **'Start workout'**
  String get startWorkout;

  /// No description provided for @takeRest.
  ///
  /// In en, this message translates to:
  /// **'Take a rest day'**
  String get takeRest;

  /// No description provided for @skipTrainingDay.
  ///
  /// In en, this message translates to:
  /// **'Skip this training day'**
  String get skipTrainingDay;

  /// No description provided for @completeRestDay.
  ///
  /// In en, this message translates to:
  /// **'Complete rest day'**
  String get completeRestDay;

  /// No description provided for @skipConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Skip this training day?'**
  String get skipConfirmTitle;

  /// No description provided for @skipConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This day will be marked as skipped and the cycle will advance.'**
  String get skipConfirmBody;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirmSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip day'**
  String get confirmSkip;

  /// No description provided for @todayActionLocked.
  ///
  /// In en, this message translates to:
  /// **'Today’s training or rest action is already recorded.'**
  String get todayActionLocked;

  /// No description provided for @undoToChangeAction.
  ///
  /// In en, this message translates to:
  /// **'Undo it first if you want to choose a different action.'**
  String get undoToChangeAction;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @todayActionUndone.
  ///
  /// In en, this message translates to:
  /// **'Today’s action was undone.'**
  String get todayActionUndone;

  /// No description provided for @noTodayActionToUndo.
  ///
  /// In en, this message translates to:
  /// **'There is no action to undo today.'**
  String get noTodayActionToUndo;

  /// No description provided for @undoActionFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not undo the action: {error}'**
  String undoActionFailed(Object error);

  /// No description provided for @trainingSkipped.
  ///
  /// In en, this message translates to:
  /// **'Training day skipped'**
  String get trainingSkipped;

  /// No description provided for @plannedRestDone.
  ///
  /// In en, this message translates to:
  /// **'Planned rest day completed'**
  String get plannedRestDone;

  /// No description provided for @movedRestTaken.
  ///
  /// In en, this message translates to:
  /// **'Used the next planned rest day early'**
  String get movedRestTaken;

  /// No description provided for @extraRestTaken.
  ///
  /// In en, this message translates to:
  /// **'Extra rest recorded. The training position is unchanged.'**
  String get extraRestTaken;

  /// No description provided for @restRecorded.
  ///
  /// In en, this message translates to:
  /// **'Rest recorded'**
  String get restRecorded;

  /// No description provided for @cycleProgress.
  ///
  /// In en, this message translates to:
  /// **'Cycle progress'**
  String get cycleProgress;

  /// No description provided for @previousRoundSameDay.
  ///
  /// In en, this message translates to:
  /// **'Previous round · same day'**
  String get previousRoundSameDay;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @readWorkoutError.
  ///
  /// In en, this message translates to:
  /// **'Could not read workout data'**
  String get readWorkoutError;

  /// No description provided for @planName.
  ///
  /// In en, this message translates to:
  /// **'Plan name'**
  String get planName;

  /// No description provided for @trainingDayName.
  ///
  /// In en, this message translates to:
  /// **'Training day name'**
  String get trainingDayName;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @moveUp.
  ///
  /// In en, this message translates to:
  /// **'Move up'**
  String get moveUp;

  /// No description provided for @moveDown.
  ///
  /// In en, this message translates to:
  /// **'Move down'**
  String get moveDown;

  /// No description provided for @removeDay.
  ///
  /// In en, this message translates to:
  /// **'Remove day'**
  String get removeDay;

  /// No description provided for @noExercisesAssigned.
  ///
  /// In en, this message translates to:
  /// **'No exercises assigned yet.'**
  String get noExercisesAssigned;

  /// No description provided for @exerciseTargets.
  ///
  /// In en, this message translates to:
  /// **'Exercise targets'**
  String get exerciseTargets;

  /// No description provided for @editTargets.
  ///
  /// In en, this message translates to:
  /// **'Edit targets'**
  String get editTargets;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @targetSets.
  ///
  /// In en, this message translates to:
  /// **'Sets'**
  String get targetSets;

  /// No description provided for @minReps.
  ///
  /// In en, this message translates to:
  /// **'Minimum reps'**
  String get minReps;

  /// No description provided for @maxReps.
  ///
  /// In en, this message translates to:
  /// **'Maximum reps'**
  String get maxReps;

  /// No description provided for @suggestedWeight.
  ///
  /// In en, this message translates to:
  /// **'Suggested weight (kg)'**
  String get suggestedWeight;

  /// No description provided for @newDay.
  ///
  /// In en, this message translates to:
  /// **'New day'**
  String get newDay;

  /// No description provided for @newDayName.
  ///
  /// In en, this message translates to:
  /// **'New day name'**
  String get newDayName;

  /// No description provided for @dayType.
  ///
  /// In en, this message translates to:
  /// **'Day type'**
  String get dayType;

  /// No description provided for @trainingDay.
  ///
  /// In en, this message translates to:
  /// **'Training day'**
  String get trainingDay;

  /// No description provided for @plannedRest.
  ///
  /// In en, this message translates to:
  /// **'Planned rest'**
  String get plannedRest;

  /// No description provided for @addDay.
  ///
  /// In en, this message translates to:
  /// **'Add day'**
  String get addDay;

  /// No description provided for @historyLockedDay.
  ///
  /// In en, this message translates to:
  /// **'This day has history and cannot be removed. Rename it or keep it in the plan.'**
  String get historyLockedDay;

  /// No description provided for @choosePresetExercise.
  ///
  /// In en, this message translates to:
  /// **'Choose a preset exercise'**
  String get choosePresetExercise;

  /// No description provided for @createExercisePreset.
  ///
  /// In en, this message translates to:
  /// **'Create an exercise preset'**
  String get createExercisePreset;

  /// No description provided for @newExercisePreset.
  ///
  /// In en, this message translates to:
  /// **'New exercise preset'**
  String get newExercisePreset;

  /// No description provided for @addExercise.
  ///
  /// In en, this message translates to:
  /// **'Add exercise'**
  String get addExercise;

  /// No description provided for @exerciseRemoved.
  ///
  /// In en, this message translates to:
  /// **'Remove exercise'**
  String get exerciseRemoved;

  /// No description provided for @planLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load plan: {error}'**
  String planLoadError(Object error);

  /// No description provided for @historyLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load history: {error}'**
  String historyLoadError(Object error);

  /// No description provided for @emptyHistory.
  ///
  /// In en, this message translates to:
  /// **'Completed workouts will appear here.'**
  String get emptyHistory;

  /// No description provided for @workout.
  ///
  /// In en, this message translates to:
  /// **'Workout'**
  String get workout;

  /// No description provided for @freeWorkout.
  ///
  /// In en, this message translates to:
  /// **'Unplanned workout'**
  String get freeWorkout;

  /// No description provided for @exerciseCount.
  ///
  /// In en, this message translates to:
  /// **'{exercises} exercises · {sets} sets'**
  String exerciseCount(int exercises, int sets);

  /// No description provided for @setLine.
  ///
  /// In en, this message translates to:
  /// **'Set {number}: {weight} {unit} × {reps} reps · RIR {rir}{status}'**
  String setLine(
    int number,
    Object weight,
    Object unit,
    Object reps,
    Object rir,
    Object status,
  );

  /// No description provided for @skippedSuffix.
  ///
  /// In en, this message translates to:
  /// **' · skipped'**
  String get skippedSuffix;

  /// No description provided for @addFirstExercise.
  ///
  /// In en, this message translates to:
  /// **'Add your first exercise'**
  String get addFirstExercise;

  /// No description provided for @chooseExercise.
  ///
  /// In en, this message translates to:
  /// **'Choose an exercise'**
  String get chooseExercise;

  /// No description provided for @enterNewExercise.
  ///
  /// In en, this message translates to:
  /// **'Enter a new exercise'**
  String get enterNewExercise;

  /// No description provided for @exerciseName.
  ///
  /// In en, this message translates to:
  /// **'Exercise name'**
  String get exerciseName;

  /// No description provided for @exerciseHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Barbell bench press'**
  String get exerciseHint;

  /// No description provided for @oneTimeOnly.
  ///
  /// In en, this message translates to:
  /// **'This workout only'**
  String get oneTimeOnly;

  /// No description provided for @saveAsPreset.
  ///
  /// In en, this message translates to:
  /// **'Save as preset'**
  String get saveAsPreset;

  /// No description provided for @addAnotherSet.
  ///
  /// In en, this message translates to:
  /// **'Add a set'**
  String get addAnotherSet;

  /// No description provided for @removeSet.
  ///
  /// In en, this message translates to:
  /// **'Remove set'**
  String get removeSet;

  /// No description provided for @setLabel.
  ///
  /// In en, this message translates to:
  /// **'Set'**
  String get setLabel;

  /// No description provided for @repsLabel.
  ///
  /// In en, this message translates to:
  /// **'Reps'**
  String get repsLabel;

  /// No description provided for @rirLabel.
  ///
  /// In en, this message translates to:
  /// **'RIR'**
  String get rirLabel;

  /// No description provided for @workingCopyOnly.
  ///
  /// In en, this message translates to:
  /// **'Saved only in this workout'**
  String get workingCopyOnly;

  /// No description provided for @finishSaveWorkout.
  ///
  /// In en, this message translates to:
  /// **'Finish and save workout'**
  String get finishSaveWorkout;

  /// No description provided for @viewTodayWorkout.
  ///
  /// In en, this message translates to:
  /// **'View today’s workout'**
  String get viewTodayWorkout;

  /// No description provided for @todayWorkout.
  ///
  /// In en, this message translates to:
  /// **'Today’s workout'**
  String get todayWorkout;

  /// No description provided for @editTodayWorkout.
  ///
  /// In en, this message translates to:
  /// **'Edit today’s workout'**
  String get editTodayWorkout;

  /// No description provided for @editWorkout.
  ///
  /// In en, this message translates to:
  /// **'Edit workout'**
  String get editWorkout;

  /// No description provided for @saveWorkoutChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveWorkoutChanges;

  /// No description provided for @emptyExerciseName.
  ///
  /// In en, this message translates to:
  /// **'Exercise name cannot be empty.'**
  String get emptyExerciseName;

  /// No description provided for @atLeastOneSet.
  ///
  /// In en, this message translates to:
  /// **'{exercise} needs at least one set.'**
  String atLeastOneSet(Object exercise);

  /// No description provided for @invalidWeight.
  ///
  /// In en, this message translates to:
  /// **'{exercise} has an invalid weight.'**
  String invalidWeight(Object exercise);

  /// No description provided for @invalidReps.
  ///
  /// In en, this message translates to:
  /// **'{exercise} has invalid reps.'**
  String invalidReps(Object exercise);

  /// No description provided for @invalidRir.
  ///
  /// In en, this message translates to:
  /// **'{exercise}: RIR must be 0–10 in 0.5 steps.'**
  String invalidRir(Object exercise);

  /// No description provided for @saveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save: {error}'**
  String saveFailed(Object error);

  /// No description provided for @kg.
  ///
  /// In en, this message translates to:
  /// **'kg'**
  String get kg;

  /// No description provided for @editDay.
  ///
  /// In en, this message translates to:
  /// **'Rename day'**
  String get editDay;

  /// No description provided for @restSlotDescription.
  ///
  /// In en, this message translates to:
  /// **'This planned rest slot can be taken earlier during a cycle.'**
  String get restSlotDescription;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
