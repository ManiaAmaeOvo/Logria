// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get exerciseVariantNote => '备注变式 / 独立预设';

  @override
  String get exerciseVariantHint =>
      '添加握法、站距等备注会创建独立的新预设，原动作及历史记录不会改变。清空备注可回到基础动作，已创建的变式预设仍会保留。';

  @override
  String get exerciseVariantExample => '正手 · 宽距 / 反手 · 窄距';

  @override
  String get foodLibrary => '食材与常用饮食方案';

  @override
  String get foodLibraryHint => '选择食物后输入摄入量。通用参考值仅作粗略估算，成熟制品请以配料表为准，全程无需联网查询。';

  @override
  String get searchFood => '搜索食材或常用方案';

  @override
  String get createFoodPreset => '创建 / 编辑食物预设';

  @override
  String get foodPresetName => '食材、制品或餐食名称';

  @override
  String get foodBasisHint =>
      '以下营养值均对应你设定的参考量，如 100g 生肉、30g 蛋白粉、1 瓶奶或 1 份晚餐。克重、毫升与份数不会自动互换，需按标签定义基准。';

  @override
  String get foodUnit => '量纲';

  @override
  String get referenceQuantity => '标签对应的参考量';

  @override
  String get foodPreparation => '加工状态 / 称量依据';

  @override
  String get foodRaw => '生重 / 干重';

  @override
  String get foodCooked => '熟重';

  @override
  String get foodPackaged => '预包装制品';

  @override
  String get foodOther => '其他 / 自制餐食';

  @override
  String get foodPortion => '份';

  @override
  String get foodBottle => '瓶';

  @override
  String get foodScoop => '勺';

  @override
  String get foodBag => '袋';

  @override
  String get quantity => '本次摄入量';

  @override
  String get energyKilojoules => '能量（kJ）';

  @override
  String get extraNutrients => '矿物质与膳食纤维（可选）';

  @override
  String get nutrientSodium => '钠';

  @override
  String get nutrientPotassium => '钾';

  @override
  String get nutrientCalcium => '钙';

  @override
  String get nutrientIron => '铁';

  @override
  String get nutrientFiber => '膳食纤维';

  @override
  String get nutrientMinimum => '下限';

  @override
  String get foodMissingHint => '留空表示未记录，并非零摄入。汇总只累计已知数值，可能不完整；软件不会自动设置摄入标准。';

  @override
  String get invalidFoodPreset => '请填写名称、正数参考量和有效的非负营养值，未知项目可留空。';

  @override
  String get referenceFood => 'USDA 通用参考 · 只读，可复制修改';

  @override
  String get customFood => '自定义预设 / 饮食方案';

  @override
  String get copyFoodPreset => '复制为新的预设';

  @override
  String get deleteFoodPresetHint => '删除这个预设？之前已记录的饮食及其营养数值将保持不变。';

  @override
  String get foodPresetLogged => '已添加到所选日期的饮食记录。';

  @override
  String get dailyReview => '今日复盘备注';

  @override
  String get dailyReviewHint => '今天感觉如何？记录复盘或其他值得记住的事。保存后会加入复制的整日日志。';

  @override
  String get reviewSaved => '今日复盘已保存。';

  @override
  String get restartTraining => '重新开始训练轮次';

  @override
  String get restartTrainingHint =>
      '归档被打断的当前轮次，按相同计划开启新一轮。已保存的历史训练、PR、饮食及身体数据全部保留，未完成的计划日草稿及撤销恢复记录会被清除。之后可重新选择起始日。如今日已记录训练或休息，请先撤销今日操作；重开后不能再恢复该操作。';

  @override
  String get usePreviousTemplate => '使用上次记录作为模板';

  @override
  String get replaceWorkoutTemplateHint =>
      '用同一训练日的上次记录替换当前编辑内容？历史记录不会改变。完成今日训练前，请检查复制的数值。';

  @override
  String get firstSetFillHint =>
      '首次编辑第一组重量或次数时，自动填充下方未手动修改的对应字段；离开输入框后不再联动。RIR 不自动填充。';

  @override
  String get chooseStartingDay => '选择起始训练日';

  @override
  String get chooseStartingDayHint =>
      '可从任意日开始本轮，例如 Push 2。之前的日子标为未记录，不会生成完成或跳过训练的历史；下一轮仍从第 1 天开始。仅限本轮尚未记录活动时设置。';

  @override
  String get startingDayUnavailable => '请先完成或丢弃草稿。本轮已有记录或今日操作已锁定时，不能改变起始日。';

  @override
  String get beforeStartingDay => '⊖ 起始日前 · 未记录';

  @override
  String get redoTodayAction => '恢复今日操作';

  @override
  String get redoTodayHint => '今日操作已撤销。可恢复原记录与轮次状态，或记录一个新操作来替代。';

  @override
  String get todayActionRestored => '已恢复今日操作。';

  @override
  String get redoUnavailable => '日期、计划或今日操作已改变，无法恢复。';

  @override
  String get discardWorkoutDraft => '丢弃草稿';

  @override
  String get discardWorkoutDraftHint => '丢弃这些尚未保存的输入？已保存的训练记录不会改变。';

  @override
  String get continueWorkoutDraft => '继续编辑训练草稿';

  @override
  String get workoutDraftHint => '输入会自动保存为本地草稿，可退出后继续。只有完成训练才推进轮次，空白组不会计入记录。';

  @override
  String get weightInputLabel => 'kg / 文字';

  @override
  String get textWeightHandling => '文字重量的数值处理';

  @override
  String get textWeightNull => 'null · 未知，不计入 PR';

  @override
  String get textWeightZero => '0 · 无可测量外部负重';

  @override
  String get prTitle => '动作 PR';

  @override
  String get prExplanation =>
      '只选择想追踪的动作。曲线为每日最大记录重量（kg），不估算 1RM。文字按 null 时不参与，按 0 时参与。手动 PR 与训练记录独立保存。';

  @override
  String get trackExercise => '选择要追踪的动作';

  @override
  String get addPr => '补记 PR';

  @override
  String get manualPr => '手动 PR';

  @override
  String get workoutPr => '训练当日最大重量';

  @override
  String get removeTracking => '停止追踪（保留记录）';

  @override
  String get noPr => '暂无数值重量记录。';

  @override
  String get cardioTitle => '有氧';

  @override
  String get cardioHint => '独立于力量训练轮次，休息日也可记录。';

  @override
  String get addCardio => '添加有氧';

  @override
  String get cardioActivity => '有氧项目';

  @override
  String get cardioMinutes => '时长（分钟）';

  @override
  String get cardioDistance => '距离（km，可选）';

  @override
  String get cardioNotes => '备注（可选）';

  @override
  String get cardioPresets => '步行,跑步,骑行,游泳,椭圆机,划船机,爬楼,跳绳';

  @override
  String get invalidFitnessValue => '请填写有效名称和有限的非负数值；有氧时长需大于 0。';

  @override
  String get dateLabel => '日期';

  @override
  String get appTagline => '三个板块，一份每日记录。';

  @override
  String get appIntroduction =>
      'Logria 将训练、饮食和身体数据汇集为私人的每日日志。记录训练循环、每餐饮食与身体变化，需要复盘时可随时复制记录。';

  @override
  String get softwareDetails => '关于 Logria';

  @override
  String get developers => '开发人员';

  @override
  String get developerProfile => '开发者 GitHub 主页';

  @override
  String get sourceCode => '源代码';

  @override
  String get privacyTitle => '本地与隐私';

  @override
  String get privacySummary =>
      '记录保存在当前设备，无需账号，没有云同步、分析追踪或内置 AI 请求。仅在点击 GitHub 链接时打开浏览器；复制会将日志写入系统剪贴板。';

  @override
  String get firstReleaseScope => '当前功能';

  @override
  String get firstReleaseScopeHint =>
      '已提供可续写的训练草稿、动作 PR 曲线、有氧、营养、身体、每日汇总和日历功能。JSON 导入导出和按体重计算的营养模板将在后续版本加入。';

  @override
  String get openSourceLicenses => '开源许可证';

  @override
  String get linkCopiedFallback => '无法打开浏览器，已将链接复制到剪贴板。';

  @override
  String get previousMonth => '上个月';

  @override
  String get nextMonth => '下个月';

  @override
  String get locateCycle => '定位训练轮次';

  @override
  String get allCycles => '全部轮次';

  @override
  String get cycleCalendarHint => '颜色表示训练轮次跨度，不代表已安排训练；图标表示实际记录。选择轮次可定位并突出其日期。';

  @override
  String get copySelectedLog => '复制此日期全部记录';

  @override
  String dateLogCopied(Object date) {
    return '已复制 $date 的记录。';
  }

  @override
  String calendarLoadError(Object error) {
    return '读取日历失败：$error';
  }

  @override
  String get noDateTraining => '此日期尚未记录训练或休息。';

  @override
  String get noDateFood => '此日期尚未记录饮食。';

  @override
  String get noDateBody => '此日期尚未记录身体数据。';

  @override
  String get copyTodayLog => '复制今日全部记录';

  @override
  String copyTodaySection(Object section) {
    return '复制$section';
  }

  @override
  String openModule(Object module) {
    return '进入$module';
  }

  @override
  String get refreshToday => '刷新今日记录';

  @override
  String get todayCopyHint => '一键复制今日训练、饮食、营养汇总和身体数据，也可单独复制下方板块。';

  @override
  String get todayLogCopied => '今日记录已复制。';

  @override
  String todayLoadError(Object error) {
    return '读取今日记录失败：$error';
  }

  @override
  String todayCopyFailed(Object error) {
    return '复制今日记录失败：$error';
  }

  @override
  String get noTodayTraining => '今日尚未记录训练或休息。';

  @override
  String get noTodayFood => '今日尚未记录饮食。';

  @override
  String get noTodayBody => '今日尚未记录身体数据。';

  @override
  String get trainingRecorded => '已记录训练';

  @override
  String get mealTotalLabel => '逐餐汇总';

  @override
  String get manualTotalLabel => '手动总量';

  @override
  String get caloriesEstimatedLabel => '热量由 P/C/F 估算';

  @override
  String get caloriesManualLabel => '热量为手动填写';

  @override
  String get missingNutritionHint => '— 表示未记录，并非零摄入；逐餐汇总可能不完整。';

  @override
  String get nutrientGoal => '目标';

  @override
  String get nutrientLimit => '上限';

  @override
  String remainingAllowance(Object amount, Object unit) {
    return '还可摄入 $amount $unit';
  }

  @override
  String get goalReached => '已达标';

  @override
  String get bodyMeasurements => '身体数据';

  @override
  String get recordMeasurements => '记录身体数据';

  @override
  String get bodyOptionalHint => '仅填写本次测量的项目。留空保留已有记录，移除记录请使用删除。';

  @override
  String get notRecorded => '此日期未记录';

  @override
  String get bodyTrend => '趋势与历史';

  @override
  String get measurementType => '测量项目';

  @override
  String get last30Days => '近30天';

  @override
  String get last90Days => '近90天';

  @override
  String get allHistory => '全部';

  @override
  String get latestMeasurement => '截至所选日期的最近记录';

  @override
  String get noBodyHistory => '此时间段内暂无数据，可以记录测量值或选择更长时间段。';

  @override
  String get deleteMeasurement => '删除测量记录？';

  @override
  String get deleteMeasurementHint => '仅移除此日期的这一项测量记录。';

  @override
  String get invalidBodyValue => '请输入正数，体脂率不能超过100%。';

  @override
  String bodyLoadError(Object error) {
    return '读取身体数据失败：$error';
  }

  @override
  String get bodyWeight => '体重';

  @override
  String get bodyHeight => '身高';

  @override
  String get bodyFat => '体脂率';

  @override
  String get bodyWaist => '腰围';

  @override
  String get bodyArm => '臂围';

  @override
  String get bodyChest => '胸围';

  @override
  String get bodyHip => '臀围';

  @override
  String get bodyThigh => '大腿围';

  @override
  String get appTitle => 'Logria';

  @override
  String get today => '今日';

  @override
  String get fitness => '训练';

  @override
  String get nutrition => '饮食';

  @override
  String get body => '身体';

  @override
  String get calendar => '日历';

  @override
  String get settings => '设置';

  @override
  String get language => '语言';

  @override
  String get systemDefault => '跟随系统语言';

  @override
  String get english => 'English';

  @override
  String get chinese => '简体中文';

  @override
  String get offlineReady => '离线数据基础已就绪，更多功能将逐步加入。';

  @override
  String get todayDescription => '查看今天的训练、饮食、营养和身体记录。';

  @override
  String get fitnessDescription => '管理训练循环、动作、组数、次数、重量与 RIR。';

  @override
  String get nutritionDescription => '饮食文本与每日营养汇总分别记录。';

  @override
  String nutritionLoadError(Object error) {
    return '无法读取营养数据：$error';
  }

  @override
  String get dailyIntake => '每日营养摄入';

  @override
  String get intakeIndependentNote => '自动汇总各餐摄入。未填的营养值仍为未记录，汇总可能不完整。';

  @override
  String get manualDailyTotal => '当前使用手动总量。恢复逐餐汇总前，各餐修改不会改变这些数值。';

  @override
  String get useMealTotals => '恢复逐餐汇总';

  @override
  String get carbohydrateGoal => '碳水目标（g）';

  @override
  String get fatGoal => '脂肪目标（g）';

  @override
  String get estimateCalories => '自动估算热量';

  @override
  String get caloriesShort => '热量';

  @override
  String get dailyGoals => '每日目标';

  @override
  String get setGoals => '设置目标';

  @override
  String get setNutritionGoals => '营养目标';

  @override
  String get proteinGoal => '蛋白质目标';

  @override
  String get proteinGoalGrams => '蛋白质目标（g）';

  @override
  String get calorieLimit => '热量目标 / 上限';

  @override
  String get calorieLimitKcal => '热量目标 / 上限（kcal）';

  @override
  String get noNutritionGoals => '设置 P、C、F 或热量目标后，可在这里查看进度。';

  @override
  String get blankGoalHint => '留空即可关闭对应目标。';

  @override
  String remainingAmount(Object amount, Object unit) {
    return '还差 $amount $unit';
  }

  @override
  String overLimitAmount(Object amount, Object unit) {
    return '超出上限 $amount $unit';
  }

  @override
  String goalExceededAmount(Object amount, Object unit) {
    return '已超过目标 $amount $unit';
  }

  @override
  String get foodLog => '饮食记录';

  @override
  String get foodLogIndependentNote =>
      '逐餐记录吃了什么，营养值可留空，之后再补充。仅在估算热量时，未填的 P/C/F 按 0 计算。';

  @override
  String get addFoodNote => '添加饮食记录';

  @override
  String get editFoodNote => '编辑饮食记录';

  @override
  String get emptyFoodLog => '这一天还没有饮食记录。';

  @override
  String get foodNoteHint => '吃了什么？';

  @override
  String get foodNoteRequired => '请填写饮食内容后再保存。';

  @override
  String get copyFoodLog => '复制饮食记录';

  @override
  String get foodLogCopied => '饮食记录已复制。';

  @override
  String get copyIntake => '复制营养汇总';

  @override
  String get intakeCopied => '营养汇总已复制。';

  @override
  String get foodNoteOptions => '饮食记录操作';

  @override
  String get deleteFoodNoteTitle => '删除这条饮食记录？';

  @override
  String get deleteFoodNoteBody => '只会删除选中的这条记录。';

  @override
  String get previousDay => '前一天';

  @override
  String get nextDay => '后一天';

  @override
  String get proteinGrams => '蛋白质（g）';

  @override
  String get carbohydrateGrams => '碳水化合物（g）';

  @override
  String get fatGrams => '脂肪（g）';

  @override
  String get caloriesKcal => '热量（kcal）';

  @override
  String get invalidNutritionValue => '请输入非负数字，或将字段留空。';

  @override
  String get invalidTargetValue => '目标必须是正数，或留空关闭。';

  @override
  String get add => '添加';

  @override
  String get edit => '编辑';

  @override
  String get delete => '删除';

  @override
  String get bodyDescription => '按需记录体重、体脂率和身体围度。';

  @override
  String get calendarDescription => '按日期和训练轮次回顾所有记录。';

  @override
  String get selectTrainingCycle => '选择训练循环';

  @override
  String get templateIntro => '从模板开始。每轮中的预设休息日都可以提前使用。';

  @override
  String get pplDescription => 'Push、Pull、Legs，之后安排一个可移动休息日';

  @override
  String get ppl2Description => '两组 PPL，每组三天后安排一个可移动休息日';

  @override
  String get fourSplit => '四分化';

  @override
  String get fourSplitDescription => '胸、背、肩、腿，之后安排一个可移动休息日';

  @override
  String get chest => '胸';

  @override
  String get back => '背';

  @override
  String get shoulders => '肩';

  @override
  String get legs => '腿';

  @override
  String get rest => '休息';

  @override
  String get push => 'Push';

  @override
  String get pull => 'Pull';

  @override
  String get useTemplate => '使用此模板';

  @override
  String createPlanError(Object error) {
    return '无法建立计划：$error';
  }

  @override
  String cycleNumber(int number) {
    return '第 $number 轮';
  }

  @override
  String get editPlan => '编辑计划';

  @override
  String get switchPlan => '切换计划';

  @override
  String get chooseDifferentPlan => '选择其他计划';

  @override
  String get switchPlanIntro => '将从新计划的第 1 轮开始。原计划及其训练历史会保留。';

  @override
  String switchPlanConfirmTitle(Object plan) {
    return '切换到「$plan」？';
  }

  @override
  String get switchPlanConfirmBody => '当前计划将停用，但历史记录仍可查阅；新计划从第 1 轮开始。';

  @override
  String get confirmSwitch => '确认切换';

  @override
  String get workoutHistory => '训练历史';

  @override
  String get current => '当前训练';

  @override
  String get startWorkout => '开始记录训练';

  @override
  String get takeRest => '今天休息';

  @override
  String get skipTrainingDay => '跳过此训练日';

  @override
  String get completeRestDay => '完成休息日';

  @override
  String get skipConfirmTitle => '跳过当前训练？';

  @override
  String get skipConfirmBody => '该训练日会标记为跳过，循环将前进到下一天。';

  @override
  String get cancel => '取消';

  @override
  String get confirmSkip => '确认跳过';

  @override
  String get todayActionLocked => '今天的训练或休息操作已记录。';

  @override
  String get undoToChangeAction => '如需更换操作，请先撤回今天的记录。';

  @override
  String get undo => '撤回';

  @override
  String get todayActionUndone => '已撤回今天的操作。';

  @override
  String get noTodayActionToUndo => '今天没有可撤回的操作。';

  @override
  String undoActionFailed(Object error) {
    return '撤回失败：$error';
  }

  @override
  String get trainingSkipped => '已跳过当前训练日';

  @override
  String get plannedRestDone => '预设休息日已完成';

  @override
  String get movedRestTaken => '已提前使用本轮下一个预设休息日';

  @override
  String get extraRestTaken => '已记录额外休息，训练位置保持不变';

  @override
  String get restRecorded => '休息已记录';

  @override
  String get cycleProgress => '本轮进度';

  @override
  String get previousRoundSameDay => '上一轮 · 同一训练日';

  @override
  String get retry => '重试';

  @override
  String get readWorkoutError => '无法读取训练数据';

  @override
  String get planName => '计划名称';

  @override
  String get trainingDayName => '训练日名称';

  @override
  String get save => '保存';

  @override
  String get moveUp => '上移';

  @override
  String get moveDown => '下移';

  @override
  String get removeDay => '删除训练日';

  @override
  String get noExercisesAssigned => '尚未添加训练动作。';

  @override
  String get exerciseTargets => '动作目标';

  @override
  String get editTargets => '编辑目标';

  @override
  String get remove => '删除';

  @override
  String get targetSets => '组数';

  @override
  String get minReps => '最少次数';

  @override
  String get maxReps => '最多次数';

  @override
  String get suggestedWeight => '建议重量（kg）';

  @override
  String get newDay => '新训练日';

  @override
  String get newDayName => '训练日名称';

  @override
  String get dayType => '训练日类型';

  @override
  String get trainingDay => '训练日';

  @override
  String get plannedRest => '预设休息日';

  @override
  String get addDay => '添加训练日';

  @override
  String get historyLockedDay => '该训练日已有历史记录，无法删除。可以重命名或保留在计划中。';

  @override
  String get choosePresetExercise => '选择预设动作';

  @override
  String get createExercisePreset => '创建动作预设';

  @override
  String get newExercisePreset => '新动作预设';

  @override
  String get addExercise => '添加动作';

  @override
  String get exerciseRemoved => '删除动作';

  @override
  String planLoadError(Object error) {
    return '无法读取计划：$error';
  }

  @override
  String historyLoadError(Object error) {
    return '无法读取训练历史：$error';
  }

  @override
  String get emptyHistory => '完成的训练会显示在这里。';

  @override
  String get workout => '训练记录';

  @override
  String get freeWorkout => '计划外训练';

  @override
  String exerciseCount(int exercises, int sets) {
    return '$exercises 个动作 · $sets 组';
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
    return '第 $number 组：$weight $unit × $reps 次 · RIR $rir$status';
  }

  @override
  String get skippedSuffix => ' · 未完成';

  @override
  String get addFirstExercise => '添加今天的第一个动作';

  @override
  String get chooseExercise => '选择动作';

  @override
  String get enterNewExercise => '输入新动作';

  @override
  String get exerciseName => '动作名称';

  @override
  String get exerciseHint => '例如：平板卧推';

  @override
  String get oneTimeOnly => '仅本次训练';

  @override
  String get saveAsPreset => '保存为预设';

  @override
  String get addAnotherSet => '增加一组';

  @override
  String get removeSet => '删除此组';

  @override
  String get setLabel => '组';

  @override
  String get repsLabel => '次数';

  @override
  String get rirLabel => 'RIR';

  @override
  String get workingCopyOnly => '仅保存在本次训练中';

  @override
  String get finishSaveWorkout => '完成并保存训练';

  @override
  String get viewTodayWorkout => '查看今日训练';

  @override
  String get todayWorkout => '今日训练';

  @override
  String get editTodayWorkout => '编辑今日训练';

  @override
  String get editWorkout => '编辑训练';

  @override
  String get saveWorkoutChanges => '保存修改';

  @override
  String get emptyExerciseName => '动作名称不能为空。';

  @override
  String atLeastOneSet(Object exercise) {
    return '$exercise 至少需要一组。';
  }

  @override
  String invalidWeight(Object exercise) {
    return '$exercise 的重量无效。';
  }

  @override
  String invalidReps(Object exercise) {
    return '$exercise 的次数无效。';
  }

  @override
  String invalidRir(Object exercise) {
    return '$exercise 的 RIR 应为 0–10，步进 0.5。';
  }

  @override
  String saveFailed(Object error) {
    return '保存失败：$error';
  }

  @override
  String get quickAddFood => '从预设快捷添加';

  @override
  String get noFoodMatches => '没有匹配的预设，可在食材与常用饮食方案中创建。';

  @override
  String get userManual => '使用说明';

  @override
  String get userManualHint => '离线用户手册 · 简体中文 / English';

  @override
  String get kg => 'kg';

  @override
  String get editDay => '重命名训练日';

  @override
  String get restSlotDescription => '该预设休息日可以在循环中提前使用。';
}
