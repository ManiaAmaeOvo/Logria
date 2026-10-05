// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get exerciseVariantNote => 'Variant note / separate preset';

  @override
  String get exerciseVariantHint =>
      'A note creates a separate preset, e.g. a different grip or stance. The original preset and its records stay unchanged. Clear the note to use the base exercise; existing variant presets are kept.';

  @override
  String get exerciseVariantExample =>
      'Overhand · wide grip / Underhand · narrow grip';

  @override
  String get foodLibrary => 'Foods & meal presets';

  @override
  String get foodLibraryHint =>
      'Tap a food to enter its amount. Generic reference values are approximate; use your product label for branded foods. No online lookup is needed.';

  @override
  String get searchFood => 'Search foods or presets';

  @override
  String get createFoodPreset => 'Create / edit food preset';

  @override
  String get foodPresetName => 'Food, product or meal name';

  @override
  String get foodBasisHint =>
      'Enter all values for the reference amount below, such as 100 g raw meat, 30 g protein powder, 1 bottle or 1 dinner portion. Units do not convert grams into portions or mL automatically.';

  @override
  String get foodUnit => 'Unit';

  @override
  String get referenceQuantity => 'Reference amount on label';

  @override
  String get foodPreparation => 'Preparation / weighing basis';

  @override
  String get foodRaw => 'Raw / dry weight';

  @override
  String get foodCooked => 'Cooked weight';

  @override
  String get foodPackaged => 'Packaged product';

  @override
  String get foodOther => 'Other / homemade meal';

  @override
  String get foodPortion => 'portion';

  @override
  String get foodBottle => 'bottle';

  @override
  String get foodScoop => 'scoop';

  @override
  String get foodBag => 'bag';

  @override
  String get quantity => 'Amount eaten';

  @override
  String get energyKilojoules => 'Energy (kJ)';

  @override
  String get extraNutrients => 'Minerals & fiber (optional)';

  @override
  String get nutrientSodium => 'Sodium';

  @override
  String get nutrientPotassium => 'Potassium';

  @override
  String get nutrientCalcium => 'Calcium';

  @override
  String get nutrientIron => 'Iron';

  @override
  String get nutrientFiber => 'Dietary fiber';

  @override
  String get nutrientMinimum => 'Minimum';

  @override
  String get foodMissingHint =>
      'Blank means unrecorded, not zero. Totals count only known values and may be incomplete. No intake standards are set automatically.';

  @override
  String get invalidFoodPreset =>
      'Enter a name, a positive reference amount and finite, non-negative nutrients. Leave unknown values blank.';

  @override
  String get referenceFood => 'USDA reference · read-only, copy to customize';

  @override
  String get customFood => 'Your preset / meal';

  @override
  String get copyFoodPreset => 'Copy as a new preset';

  @override
  String get deleteFoodPresetHint =>
      'Delete this preset? Previously logged meals and their nutrient snapshots will stay unchanged.';

  @override
  String get foodPresetLogged => 'Food logged for the selected date.';

  @override
  String get dailyReview => 'Daily review';

  @override
  String get dailyReviewHint =>
      'How did today feel? Add a reflection or anything worth remembering. Save to include it in your copied log.';

  @override
  String get reviewSaved => 'Daily review saved.';

  @override
  String get restartTraining => 'Restart training cycle';

  @override
  String get restartTrainingHint =>
      'Archive this interrupted cycle and start a new one with the same plan. Saved history, PRs, nutrition and body data are kept. Unfinished plan-day drafts and undo recovery will be cleared. You can then choose a starting day. If today\'s action is recorded, undo it first; it cannot be restored after restarting.';

  @override
  String get usePreviousTemplate => 'Use last record as template';

  @override
  String get replaceWorkoutTemplateHint =>
      'Replace the current editor inputs with the last record for this same training day? The historical record stays unchanged. Review the copied values before finishing today\'s workout.';

  @override
  String get firstSetFillHint =>
      'The first weight/reps edit fills untouched later sets until you leave that field. Later edits stay independent; RIR is never auto-filled.';

  @override
  String get chooseStartingDay => 'Choose starting day';

  @override
  String get chooseStartingDayHint =>
      'Start this cycle at any day, such as Push 2. Earlier days are marked unrecorded, not completed or skipped workouts. The next cycle starts at day 1. Available only before recording this cycle.';

  @override
  String get startingDayUnavailable =>
      'Finish or discard the draft first. The starting day cannot change after this cycle has recorded activity or today\'s action is locked.';

  @override
  String get beforeStartingDay => '⊖ Before starting day · not recorded';

  @override
  String get redoTodayAction => 'Restore today\'s action';

  @override
  String get redoTodayHint =>
      'Today\'s action was undone. Restore the original log and cycle state, or record a new action to replace it.';

  @override
  String get todayActionRestored => 'Today\'s action restored.';

  @override
  String get redoUnavailable =>
      'Cannot restore: the date, plan or today\'s action has changed.';

  @override
  String get discardWorkoutDraft => 'Discard draft';

  @override
  String get discardWorkoutDraftHint =>
      'Discard these unsaved inputs? Saved workout records will not change.';

  @override
  String get continueWorkoutDraft => 'Continue workout draft';

  @override
  String get workoutDraftHint =>
      'Inputs are saved locally as a draft. Leave and resume anytime. Only finishing advances the cycle. Blank sets are not logged.';

  @override
  String get weightInputLabel => 'kg / text';

  @override
  String get textWeightHandling => 'Text weight: numeric value';

  @override
  String get textWeightNull => 'null · unknown / exclude from PR';

  @override
  String get textWeightZero => '0 · no measurable external load';

  @override
  String get prTitle => 'Exercise PR';

  @override
  String get prExplanation =>
      'Choose only the exercises you want to track. Curve: daily maximum logged load in kg, not estimated 1RM. Text mapped to null is excluded; 0 is included. Manual entries remain separate from workouts.';

  @override
  String get trackExercise => 'Choose an exercise to track';

  @override
  String get addPr => 'Add manual PR';

  @override
  String get manualPr => 'Manual PR';

  @override
  String get workoutPr => 'Workout daily maximum';

  @override
  String get removeTracking => 'Stop tracking (keep records)';

  @override
  String get noPr => 'No numeric weight records yet.';

  @override
  String get cardioTitle => 'Cardio';

  @override
  String get cardioHint =>
      'Independent of your strength cycle. Also available on rest days.';

  @override
  String get addCardio => 'Add cardio';

  @override
  String get cardioActivity => 'Activity';

  @override
  String get cardioMinutes => 'Duration (minutes)';

  @override
  String get cardioDistance => 'Distance (km, optional)';

  @override
  String get cardioNotes => 'Notes (optional)';

  @override
  String get cardioPresets =>
      'Walking,Running,Cycling,Swimming,Elliptical,Rowing,Stair climbing,Jump rope';

  @override
  String get invalidFitnessValue =>
      'Enter a valid name and finite non-negative values. Cardio duration must be greater than zero.';

  @override
  String get dateLabel => 'Date';

  @override
  String get appTagline => 'Three parts. One daily log.';

  @override
  String get appIntroduction =>
      'Logria brings fitness, nutrition and body measurements into a private daily journal. Track training cycles, meals and progress, then copy your logs whenever you want to review them.';

  @override
  String get softwareDetails => 'About Logria';

  @override
  String get developers => 'Developers';

  @override
  String get developerProfile => 'Developer on GitHub';

  @override
  String get sourceCode => 'Source code';

  @override
  String get privacyTitle => 'Local and private';

  @override
  String get privacySummary =>
      'Records stay on this device. No account, cloud sync, analytics or built-in AI requests. GitHub links open in your browser only when tapped. Copying puts logs on the system clipboard.';

  @override
  String get firstReleaseScope => 'Current features';

  @override
  String get firstReleaseScopeHint =>
      'Fitness with resumable drafts, exercise PR curves, cardio, nutrition, body, daily logs and calendar are available. JSON import/export and weight-based nutrition templates are planned for later versions.';

  @override
  String get openSourceLicenses => 'Open-source licenses';

  @override
  String get linkCopiedFallback =>
      'No browser could open this link. The URL was copied instead.';

  @override
  String get previousMonth => 'Previous month';

  @override
  String get nextMonth => 'Next month';

  @override
  String get locateCycle => 'Locate a training cycle';

  @override
  String get allCycles => 'All cycles';

  @override
  String get cycleCalendarHint =>
      'Colors mark cycle spans, not scheduled workouts. Icons mark recorded activity. Select a cycle to locate it and highlight its dates.';

  @override
  String get copySelectedLog => 'Copy this date\'s log';

  @override
  String dateLogCopied(Object date) {
    return 'Log for $date copied.';
  }

  @override
  String calendarLoadError(Object error) {
    return 'Could not load calendar: $error';
  }

  @override
  String get noDateTraining => 'No training or rest recorded on this date.';

  @override
  String get noDateFood => 'No meals recorded on this date.';

  @override
  String get noDateBody => 'No body measurements recorded on this date.';

  @override
  String get copyTodayLog => 'Copy today\'s log';

  @override
  String copyTodaySection(Object section) {
    return 'Copy $section';
  }

  @override
  String openModule(Object module) {
    return 'Open $module';
  }

  @override
  String get refreshToday => 'Refresh today\'s log';

  @override
  String get todayCopyHint =>
      'Copy training, meals, nutrition totals and today\'s measurements together, or copy a section below.';

  @override
  String get todayLogCopied => 'Today\'s log copied.';

  @override
  String todayLoadError(Object error) {
    return 'Could not load today\'s log: $error';
  }

  @override
  String todayCopyFailed(Object error) {
    return 'Could not copy today\'s log: $error';
  }

  @override
  String get noTodayTraining => 'No training or rest recorded today.';

  @override
  String get noTodayFood => 'No meals recorded today.';

  @override
  String get noTodayBody => 'No body measurements recorded today.';

  @override
  String get trainingRecorded => 'Training recorded';

  @override
  String get mealTotalLabel => 'Meal totals';

  @override
  String get manualTotalLabel => 'Manual daily total';

  @override
  String get caloriesEstimatedLabel => 'Calories estimated from P/C/F';

  @override
  String get caloriesManualLabel => 'Calories entered manually';

  @override
  String get missingNutritionHint =>
      '— means unrecorded, not zero. Meal totals may be partial.';

  @override
  String get nutrientGoal => 'Goal';

  @override
  String get nutrientLimit => 'Limit';

  @override
  String remainingAllowance(Object amount, Object unit) {
    return '$amount $unit available';
  }

  @override
  String get goalReached => 'Goal reached';

  @override
  String get bodyMeasurements => 'Measurements';

  @override
  String get recordMeasurements => 'Record measurements';

  @override
  String get bodyOptionalHint =>
      'Fill only what you measured. Blank fields keep existing records; use Delete to remove a record.';

  @override
  String get notRecorded => 'Not recorded on this date';

  @override
  String get bodyTrend => 'Trends & history';

  @override
  String get measurementType => 'Measurement';

  @override
  String get last30Days => '30 days';

  @override
  String get last90Days => '90 days';

  @override
  String get allHistory => 'All';

  @override
  String get latestMeasurement => 'Latest as of selected date';

  @override
  String get noBodyHistory =>
      'No measurements in this period. Record a value or choose a longer period.';

  @override
  String get deleteMeasurement => 'Delete measurement?';

  @override
  String get deleteMeasurementHint =>
      'Only this measurement on this date will be removed.';

  @override
  String get invalidBodyValue =>
      'Enter a positive number. Body fat must be at most 100%.';

  @override
  String bodyLoadError(Object error) {
    return 'Could not load measurements: $error';
  }

  @override
  String get bodyWeight => 'Weight';

  @override
  String get bodyHeight => 'Height';

  @override
  String get bodyFat => 'Body fat';

  @override
  String get bodyWaist => 'Waist';

  @override
  String get bodyArm => 'Arm';

  @override
  String get bodyChest => 'Chest';

  @override
  String get bodyHip => 'Hip';

  @override
  String get bodyThigh => 'Thigh';

  @override
  String get appTitle => 'Logria';

  @override
  String get today => 'Today';

  @override
  String get fitness => 'Fitness';

  @override
  String get nutrition => 'Nutrition';

  @override
  String get body => 'Body';

  @override
  String get calendar => 'Calendar';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get systemDefault => 'Follow system language';

  @override
  String get english => 'English';

  @override
  String get chinese => '简体中文';

  @override
  String get offlineReady =>
      'Your offline data foundation is ready. More features are on the way.';

  @override
  String get todayDescription =>
      'Review today\'s training, food, nutrition, and body records.';

  @override
  String get fitnessDescription =>
      'Manage training cycles, exercises, sets, reps, load, and RIR.';

  @override
  String get nutritionDescription =>
      'Keep food notes separate from daily nutrition totals.';

  @override
  String nutritionLoadError(Object error) {
    return 'Could not load nutrition data: $error';
  }

  @override
  String get dailyIntake => 'Daily intake';

  @override
  String get intakeIndependentNote =>
      'Automatically summed from meals. Blank nutrients remain unrecorded; totals may be partial.';

  @override
  String get manualDailyTotal =>
      'Manual daily total. Meal changes will not update these values until you restore meal totals.';

  @override
  String get useMealTotals => 'Restore meal totals';

  @override
  String get carbohydrateGoal => 'Carbohydrate goal (g)';

  @override
  String get fatGoal => 'Fat goal (g)';

  @override
  String get estimateCalories => 'Estimate calories automatically';

  @override
  String get caloriesShort => 'Calories';

  @override
  String get dailyGoals => 'Daily goals';

  @override
  String get setGoals => 'Set goals';

  @override
  String get setNutritionGoals => 'Nutrition goals';

  @override
  String get proteinGoal => 'Protein goal';

  @override
  String get proteinGoalGrams => 'Protein goal (g)';

  @override
  String get calorieLimit => 'Calorie target / limit';

  @override
  String get calorieLimitKcal => 'Calorie target / limit (kcal)';

  @override
  String get noNutritionGoals =>
      'Set P, C, F or calorie goals to see progress here.';

  @override
  String get blankGoalHint => 'Leave a field blank to turn that goal off.';

  @override
  String remainingAmount(Object amount, Object unit) {
    return '$amount $unit remaining';
  }

  @override
  String overLimitAmount(Object amount, Object unit) {
    return '$amount $unit over the limit';
  }

  @override
  String goalExceededAmount(Object amount, Object unit) {
    return 'Goal exceeded by $amount $unit';
  }

  @override
  String get foodLog => 'Food notes';

  @override
  String get foodLogIndependentNote =>
      'Describe each meal. Nutrition values are optional and can be added later. Blank macros count as zero only for calorie estimation.';

  @override
  String get addFoodNote => 'Add meal';

  @override
  String get editFoodNote => 'Edit meal';

  @override
  String get emptyFoodLog => 'No food notes for this date.';

  @override
  String get foodNoteHint => 'What did you eat?';

  @override
  String get foodNoteRequired => 'Enter a food note before saving.';

  @override
  String get copyFoodLog => 'Copy food notes';

  @override
  String get foodLogCopied => 'Food notes copied.';

  @override
  String get copyIntake => 'Copy nutrition totals';

  @override
  String get intakeCopied => 'Nutrition totals copied.';

  @override
  String get foodNoteOptions => 'Food note options';

  @override
  String get deleteFoodNoteTitle => 'Delete this food note?';

  @override
  String get deleteFoodNoteBody => 'This only deletes the selected note.';

  @override
  String get previousDay => 'Previous day';

  @override
  String get nextDay => 'Next day';

  @override
  String get proteinGrams => 'Protein (g)';

  @override
  String get carbohydrateGrams => 'Carbohydrate (g)';

  @override
  String get fatGrams => 'Fat (g)';

  @override
  String get caloriesKcal => 'Calories (kcal)';

  @override
  String get invalidNutritionValue =>
      'Enter non-negative numbers, or leave fields blank.';

  @override
  String get invalidTargetValue =>
      'Goals must be positive numbers, or left blank.';

  @override
  String get add => 'Add';

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Delete';

  @override
  String get bodyDescription =>
      'Record body weight, body fat, and measurements when needed.';

  @override
  String get calendarDescription =>
      'Review all records by date and training cycle.';

  @override
  String get selectTrainingCycle => 'Choose a training cycle';

  @override
  String get templateIntro =>
      'Start with a template. Planned rest days can be taken earlier in each cycle.';

  @override
  String get pplDescription =>
      'Push, Pull, and Legs followed by one movable rest day';

  @override
  String get ppl2Description =>
      'Two PPL blocks, each followed by one movable rest day';

  @override
  String get fourSplit => 'Four-day split';

  @override
  String get fourSplitDescription =>
      'Chest, Back, Shoulders, and Legs followed by one movable rest day';

  @override
  String get chest => 'Chest';

  @override
  String get back => 'Back';

  @override
  String get shoulders => 'Shoulders';

  @override
  String get legs => 'Legs';

  @override
  String get rest => 'Rest';

  @override
  String get push => 'Push';

  @override
  String get pull => 'Pull';

  @override
  String get useTemplate => 'Use this template';

  @override
  String createPlanError(Object error) {
    return 'Could not create plan: $error';
  }

  @override
  String cycleNumber(int number) {
    return 'Cycle $number';
  }

  @override
  String get editPlan => 'Edit plan';

  @override
  String get switchPlan => 'Switch plan';

  @override
  String get chooseDifferentPlan => 'Choose a different plan';

  @override
  String get switchPlanIntro =>
      'A new cycle will start. Your previous plan and workout history will be kept.';

  @override
  String switchPlanConfirmTitle(Object plan) {
    return 'Switch to $plan?';
  }

  @override
  String get switchPlanConfirmBody =>
      'The current plan will become inactive. Its history stays available, and the new plan starts at cycle 1.';

  @override
  String get confirmSwitch => 'Switch plan';

  @override
  String get workoutHistory => 'Workout history';

  @override
  String get current => 'Up next';

  @override
  String get startWorkout => 'Start workout';

  @override
  String get takeRest => 'Take a rest day';

  @override
  String get skipTrainingDay => 'Skip this training day';

  @override
  String get completeRestDay => 'Complete rest day';

  @override
  String get skipConfirmTitle => 'Skip this training day?';

  @override
  String get skipConfirmBody =>
      'This day will be marked as skipped and the cycle will advance.';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirmSkip => 'Skip day';

  @override
  String get todayActionLocked =>
      'Today’s training or rest action is already recorded.';

  @override
  String get undoToChangeAction =>
      'Undo it first if you want to choose a different action.';

  @override
  String get undo => 'Undo';

  @override
  String get todayActionUndone => 'Today’s action was undone.';

  @override
  String get noTodayActionToUndo => 'There is no action to undo today.';

  @override
  String undoActionFailed(Object error) {
    return 'Could not undo the action: $error';
  }

  @override
  String get trainingSkipped => 'Training day skipped';

  @override
  String get plannedRestDone => 'Planned rest day completed';

  @override
  String get movedRestTaken => 'Used the next planned rest day early';

  @override
  String get extraRestTaken =>
      'Extra rest recorded. The training position is unchanged.';

  @override
  String get restRecorded => 'Rest recorded';

  @override
  String get cycleProgress => 'Cycle progress';

  @override
  String get previousRoundSameDay => 'Previous round · same day';

  @override
  String get retry => 'Retry';

  @override
  String get readWorkoutError => 'Could not read workout data';

  @override
  String get planName => 'Plan name';

  @override
  String get trainingDayName => 'Training day name';

  @override
  String get save => 'Save';

  @override
  String get moveUp => 'Move up';

  @override
  String get moveDown => 'Move down';

  @override
  String get removeDay => 'Remove day';

  @override
  String get noExercisesAssigned => 'No exercises assigned yet.';

  @override
  String get exerciseTargets => 'Exercise targets';

  @override
  String get editTargets => 'Edit targets';

  @override
  String get remove => 'Remove';

  @override
  String get targetSets => 'Sets';

  @override
  String get minReps => 'Minimum reps';

  @override
  String get maxReps => 'Maximum reps';

  @override
  String get suggestedWeight => 'Suggested weight (kg)';

  @override
  String get newDay => 'New day';

  @override
  String get newDayName => 'New day name';

  @override
  String get dayType => 'Day type';

  @override
  String get trainingDay => 'Training day';

  @override
  String get plannedRest => 'Planned rest';

  @override
  String get addDay => 'Add day';

  @override
  String get historyLockedDay =>
      'This day has history and cannot be removed. Rename it or keep it in the plan.';

  @override
  String get choosePresetExercise => 'Choose a preset exercise';

  @override
  String get createExercisePreset => 'Create an exercise preset';

  @override
  String get newExercisePreset => 'New exercise preset';

  @override
  String get addExercise => 'Add exercise';

  @override
  String get exerciseRemoved => 'Remove exercise';

  @override
  String planLoadError(Object error) {
    return 'Could not load plan: $error';
  }

  @override
  String historyLoadError(Object error) {
    return 'Could not load history: $error';
  }

  @override
  String get emptyHistory => 'Completed workouts will appear here.';

  @override
  String get workout => 'Workout';

  @override
  String get freeWorkout => 'Unplanned workout';

  @override
  String exerciseCount(int exercises, int sets) {
    return '$exercises exercises · $sets sets';
  }

  @override
  String setLine(
    int number,
    Object weight,
    Object unit,
    Object reps,
    Object rir,
    Object status,
  ) {
    return 'Set $number: $weight $unit × $reps reps · RIR $rir$status';
  }

  @override
  String get skippedSuffix => ' · skipped';

  @override
  String get addFirstExercise => 'Add your first exercise';

  @override
  String get chooseExercise => 'Choose an exercise';

  @override
  String get enterNewExercise => 'Enter a new exercise';

  @override
  String get exerciseName => 'Exercise name';

  @override
  String get exerciseHint => 'e.g. Barbell bench press';

  @override
  String get oneTimeOnly => 'This workout only';

  @override
  String get saveAsPreset => 'Save as preset';

  @override
  String get addAnotherSet => 'Add a set';

  @override
  String get removeSet => 'Remove set';

  @override
  String get setLabel => 'Set';

  @override
  String get repsLabel => 'Reps';

  @override
  String get rirLabel => 'RIR';

  @override
  String get workingCopyOnly => 'Saved only in this workout';

  @override
  String get finishSaveWorkout => 'Finish and save workout';

  @override
  String get viewTodayWorkout => 'View today’s workout';

  @override
  String get todayWorkout => 'Today’s workout';

  @override
  String get editTodayWorkout => 'Edit today’s workout';

  @override
  String get editWorkout => 'Edit workout';

  @override
  String get saveWorkoutChanges => 'Save changes';

  @override
  String get emptyExerciseName => 'Exercise name cannot be empty.';

  @override
  String atLeastOneSet(Object exercise) {
    return '$exercise needs at least one set.';
  }

  @override
  String invalidWeight(Object exercise) {
    return '$exercise has an invalid weight.';
  }

  @override
  String invalidReps(Object exercise) {
    return '$exercise has invalid reps.';
  }

  @override
  String invalidRir(Object exercise) {
    return '$exercise: RIR must be 0–10 in 0.5 steps.';
  }

  @override
  String saveFailed(Object error) {
    return 'Could not save: $error';
  }

  @override
  String get quickAddFood => 'Quick add from presets';

  @override
  String get noFoodMatches =>
      'No matching presets. Create one in Foods & meal presets.';

  @override
  String get userManual => 'User manual';

  @override
  String get userManualHint => 'Offline instructions · English / 简体中文';

  @override
  String get kg => 'kg';

  @override
  String get editDay => 'Rename day';

  @override
  String get restSlotDescription =>
      'This planned rest slot can be taken earlier during a cycle.';
}
