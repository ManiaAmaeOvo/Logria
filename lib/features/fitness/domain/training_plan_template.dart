import 'training_cycle.dart';

class TrainingPlanTemplate {
  const TrainingPlanTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.days,
  });

  final String id;
  final String name;
  final String description;
  final List<TrainingPlanTemplateDay> days;
}

class TrainingPlanTemplateDay {
  const TrainingPlanTemplateDay(this.name, this.type);

  final String name;
  final CycleDayType type;
}

const builtInTrainingPlanTemplates = <TrainingPlanTemplate>[
  TrainingPlanTemplate(
    id: 'ppl',
    name: 'PPL',
    description: 'Push、Pull、Legs 后安排一个可移动休息日',
    days: [
      TrainingPlanTemplateDay('Push', CycleDayType.training),
      TrainingPlanTemplateDay('Pull', CycleDayType.training),
      TrainingPlanTemplateDay('Legs', CycleDayType.training),
      TrainingPlanTemplateDay('Rest', CycleDayType.rest),
    ],
  ),
  TrainingPlanTemplate(
    id: 'ppl_x2',
    name: 'PPL × 2',
    description: '两套 PPL，每组三天后各有一个可移动休息日',
    days: [
      TrainingPlanTemplateDay('Push 1', CycleDayType.training),
      TrainingPlanTemplateDay('Pull 1', CycleDayType.training),
      TrainingPlanTemplateDay('Legs 1', CycleDayType.training),
      TrainingPlanTemplateDay('Rest 1', CycleDayType.rest),
      TrainingPlanTemplateDay('Push 2', CycleDayType.training),
      TrainingPlanTemplateDay('Pull 2', CycleDayType.training),
      TrainingPlanTemplateDay('Legs 2', CycleDayType.training),
      TrainingPlanTemplateDay('Rest 2', CycleDayType.rest),
    ],
  ),
  TrainingPlanTemplate(
    id: 'four_day_split',
    name: '四分化',
    description: '胸、背、肩、腿后安排一个可移动休息日',
    days: [
      TrainingPlanTemplateDay('胸', CycleDayType.training),
      TrainingPlanTemplateDay('背', CycleDayType.training),
      TrainingPlanTemplateDay('肩', CycleDayType.training),
      TrainingPlanTemplateDay('腿', CycleDayType.training),
      TrainingPlanTemplateDay('Rest', CycleDayType.rest),
    ],
  ),
];
