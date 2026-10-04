import 'training_cycle.dart';

class TrainingPlanTemplate {
  const TrainingPlanTemplate({
    required this.id,
    required this.name,
    required this.descriptionKey,
    required this.days,
  });

  final String id;
  final String name;
  final String descriptionKey;
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
    descriptionKey: 'pplDescription',
    days: [
      TrainingPlanTemplateDay('push', CycleDayType.training),
      TrainingPlanTemplateDay('pull', CycleDayType.training),
      TrainingPlanTemplateDay('legs', CycleDayType.training),
      TrainingPlanTemplateDay('rest', CycleDayType.rest),
    ],
  ),
  TrainingPlanTemplate(
    id: 'ppl_x2',
    name: 'PPL × 2',
    descriptionKey: 'ppl2Description',
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
    name: 'Four-day split',
    descriptionKey: 'fourSplitDescription',
    days: [
      TrainingPlanTemplateDay('chest', CycleDayType.training),
      TrainingPlanTemplateDay('back', CycleDayType.training),
      TrainingPlanTemplateDay('shoulders', CycleDayType.training),
      TrainingPlanTemplateDay('legs', CycleDayType.training),
      TrainingPlanTemplateDay('rest', CycleDayType.rest),
    ],
  ),
];
