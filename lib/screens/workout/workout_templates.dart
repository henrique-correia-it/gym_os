import 'package:flutter/material.dart';
import 'package:gym_os/l10n/app_localizations.dart';

class TemplateExercise {
  final String name;
  final int sets;
  final String reps;
  const TemplateExercise(this.name, this.sets, this.reps);
}

class TemplateDay {
  final String name;
  final List<TemplateExercise> exercises;
  const TemplateDay(this.name, this.exercises);
}

class WorkoutTemplate {
  final String name;
  final String description;
  final String badge;
  final Color color;
  final List<TemplateDay> days;

  const WorkoutTemplate({
    required this.name,
    required this.description,
    required this.badge,
    required this.color,
    required this.days,
  });
}

const List<WorkoutTemplate> workoutTemplates = [
  WorkoutTemplate(
    name: 'PPL – Push / Pull / Legs',
    description: '3 a 6 dias por semana. Ideal para hipertrofia intermédia.',
    badge: 'PPL',
    color: Color(0xFF00E676),
    days: [
      TemplateDay('Push (Empurrar)', [
        TemplateExercise('Supino Plano (Barra)', 4, '6-10'),
        TemplateExercise('Supino Inclinado (Halteres)', 3, '8-12'),
        TemplateExercise('Peck Deck', 3, '12-15'),
        TemplateExercise('Desenvolvimento (Halteres)', 4, '8-12'),
        TemplateExercise('Elevação Lateral', 4, '12-15'),
        TemplateExercise('Tríceps Pulley (Corda)', 3, '12-15'),
        TemplateExercise('Tríceps Francês', 3, '10-12'),
      ]),
      TemplateDay('Pull (Puxar)', [
        TemplateExercise('Puxada Frontal', 4, '6-10'),
        TemplateExercise('Remada Curvada (Barra)', 4, '6-10'),
        TemplateExercise('Remada Unilateral (Halter)', 3, '8-12'),
        TemplateExercise('Face Pull', 3, '15-20'),
        TemplateExercise('Rosca Direta (Barra)', 3, '8-12'),
        TemplateExercise('Rosca Martelo', 3, '10-12'),
      ]),
      TemplateDay('Legs (Pernas)', [
        TemplateExercise('Agachamento Livre', 4, '6-10'),
        TemplateExercise('Leg Press 45°', 3, '10-12'),
        TemplateExercise('Extensão de Pernas', 3, '12-15'),
        TemplateExercise('Stiff', 3, '10-12'),
        TemplateExercise('Leg Curl Deitado', 3, '10-12'),
        TemplateExercise('Panturrilha em Pé (Máquina)', 4, '15-20'),
      ]),
    ],
  ),
  WorkoutTemplate(
    name: 'Upper / Lower',
    description: '4 dias por semana. Ótimo para força e volume equilibrado.',
    badge: 'U/L',
    color: Color(0xFF2196F3),
    days: [
      TemplateDay('Superior A', [
        TemplateExercise('Supino Plano (Barra)', 4, '5-8'),
        TemplateExercise('Remada Curvada (Barra)', 4, '5-8'),
        TemplateExercise('Supino Inclinado (Halteres)', 3, '10-12'),
        TemplateExercise('Puxada Frontal', 3, '10-12'),
        TemplateExercise('Tríceps Pulley (Barra)', 3, '12-15'),
        TemplateExercise('Rosca Direta (Barra)', 3, '12-15'),
      ]),
      TemplateDay('Inferior A', [
        TemplateExercise('Agachamento Livre', 4, '5-8'),
        TemplateExercise('Leg Press 45°', 3, '10-12'),
        TemplateExercise('Extensão de Pernas', 3, '12-15'),
        TemplateExercise('Stiff', 3, '8-10'),
        TemplateExercise('Leg Curl Deitado', 3, '10-12'),
        TemplateExercise('Panturrilha em Pé (Máquina)', 4, '15-20'),
      ]),
      TemplateDay('Superior B', [
        TemplateExercise('Desenvolvimento (Barra)', 4, '5-8'),
        TemplateExercise('Puxada Frontal', 4, '5-8'),
        TemplateExercise('Peck Deck', 3, '12-15'),
        TemplateExercise('Remada com Cabo', 3, '10-12'),
        TemplateExercise('Elevação Lateral', 3, '15-20'),
        TemplateExercise('Rosca Martelo', 3, '12-15'),
        TemplateExercise('Tríceps Corda', 3, '12-15'),
      ]),
      TemplateDay('Inferior B', [
        TemplateExercise('Levantamento Terra', 4, '4-6'),
        TemplateExercise('Agachamento Búlgaro', 3, '8-10'),
        TemplateExercise('Leg Press Horizontal', 3, '12-15'),
        TemplateExercise('Mesa Romana', 3, '10-12'),
        TemplateExercise('Leg Curl Sentado', 3, '12-15'),
        TemplateExercise('Panturrilha Sentado', 4, '15-20'),
      ]),
    ],
  ),
  WorkoutTemplate(
    name: 'Full Body',
    description: '3 dias por semana. Ideal para iniciantes e recomposição.',
    badge: 'FB',
    color: Color(0xFFFF9800),
    days: [
      TemplateDay('Treino A', [
        TemplateExercise('Agachamento Livre', 3, '8-10'),
        TemplateExercise('Supino Plano (Barra)', 3, '8-10'),
        TemplateExercise('Remada Curvada (Barra)', 3, '8-10'),
        TemplateExercise('Desenvolvimento (Halteres)', 3, '10-12'),
        TemplateExercise('Rosca Direta (Halteres)', 3, '10-12'),
        TemplateExercise('Tríceps Pulley (Barra)', 3, '10-12'),
        TemplateExercise('Prancha', 3, '45s'),
      ]),
      TemplateDay('Treino B', [
        TemplateExercise('Leg Press 45°', 3, '10-12'),
        TemplateExercise('Supino Inclinado (Halteres)', 3, '10-12'),
        TemplateExercise('Puxada Frontal', 3, '10-12'),
        TemplateExercise('Elevação Lateral', 3, '12-15'),
        TemplateExercise('Rosca Martelo', 3, '10-12'),
        TemplateExercise('Tríceps Corda', 3, '12-15'),
        TemplateExercise('Crunch', 3, '15-20'),
      ]),
      TemplateDay('Treino C', [
        TemplateExercise('Stiff', 3, '8-10'),
        TemplateExercise('Peck Deck', 3, '12-15'),
        TemplateExercise('Remada Unilateral (Halter)', 3, '10-12'),
        TemplateExercise('Face Pull', 3, '15-20'),
        TemplateExercise('Rosca Scott', 3, '10-12'),
        TemplateExercise('Tríceps Francês', 3, '10-12'),
        TemplateExercise('Panturrilha em Pé (Máquina)', 3, '15-20'),
      ]),
    ],
  ),
  WorkoutTemplate(
    name: 'Bro Split',
    description: '5 dias por semana. Clássico com foco muscular por sessão.',
    badge: 'BRO',
    color: Color(0xFFE91E63),
    days: [
      TemplateDay('Peito', [
        TemplateExercise('Supino Plano (Barra)', 4, '6-10'),
        TemplateExercise('Supino Inclinado (Halteres)', 4, '8-12'),
        TemplateExercise('Supino Declinado (Barra)', 3, '8-12'),
        TemplateExercise('Peck Deck', 3, '12-15'),
        TemplateExercise('Crucifixo Plano', 3, '12-15'),
        TemplateExercise('Flexão', 3, '15-20'),
      ]),
      TemplateDay('Costas', [
        TemplateExercise('Puxada Frontal', 4, '6-10'),
        TemplateExercise('Remada Curvada (Barra)', 4, '6-10'),
        TemplateExercise('Remada Unilateral (Halter)', 3, '8-12'),
        TemplateExercise('Barra Fixa', 3, '6-10'),
        TemplateExercise('Pullover', 3, '12-15'),
      ]),
      TemplateDay('Ombros', [
        TemplateExercise('Desenvolvimento (Barra)', 4, '6-10'),
        TemplateExercise('Elevação Lateral', 4, '12-15'),
        TemplateExercise('Elevação Frontal', 3, '12-15'),
        TemplateExercise('Face Pull', 3, '15-20'),
        TemplateExercise('Remada Alta', 3, '12-15'),
        TemplateExercise('Encolhimento (Barra)', 3, '12-15'),
      ]),
      TemplateDay('Braços', [
        TemplateExercise('Rosca Direta (Barra)', 4, '8-12'),
        TemplateExercise('Rosca Martelo', 3, '10-12'),
        TemplateExercise('Rosca Scott', 3, '10-12'),
        TemplateExercise('Tríceps Pulley (Corda)', 4, '12-15'),
        TemplateExercise('Tríceps Francês', 3, '10-12'),
        TemplateExercise('Mergulho (Paralelas)', 3, '10-15'),
      ]),
      TemplateDay('Pernas', [
        TemplateExercise('Agachamento Livre', 4, '6-10'),
        TemplateExercise('Leg Press 45°', 3, '10-12'),
        TemplateExercise('Extensão de Pernas', 3, '12-15'),
        TemplateExercise('Stiff', 3, '10-12'),
        TemplateExercise('Leg Curl Deitado', 3, '10-12'),
        TemplateExercise('Panturrilha em Pé (Máquina)', 4, '15-20'),
      ]),
    ],
  ),
  WorkoutTemplate(
    name: 'Arnold Split',
    description:
        '6 dias por semana. Avançado — Peito+Costas, Ombros+Braços, Pernas.',
    badge: 'ARN',
    color: Color(0xFF9C27B0),
    days: [
      TemplateDay('Peito & Costas A', [
        TemplateExercise('Supino Plano (Barra)', 4, '6-10'),
        TemplateExercise('Puxada Frontal', 4, '6-10'),
        TemplateExercise('Supino Inclinado (Halteres)', 3, '8-12'),
        TemplateExercise('Remada Curvada (Barra)', 3, '8-12'),
        TemplateExercise('Peck Deck', 3, '12-15'),
        TemplateExercise('Remada com Cabo', 3, '12-15'),
      ]),
      TemplateDay('Ombros & Braços A', [
        TemplateExercise('Desenvolvimento Arnold', 4, '8-12'),
        TemplateExercise('Elevação Lateral', 4, '12-15'),
        TemplateExercise('Rosca Direta (Barra)', 4, '8-12'),
        TemplateExercise('Tríceps Pulley (Corda)', 4, '12-15'),
        TemplateExercise('Rosca Martelo', 3, '10-12'),
        TemplateExercise('Tríceps Francês', 3, '10-12'),
      ]),
      TemplateDay('Pernas A', [
        TemplateExercise('Agachamento Livre', 4, '6-10'),
        TemplateExercise('Leg Press 45°', 3, '10-12'),
        TemplateExercise('Extensão de Pernas', 3, '12-15'),
        TemplateExercise('Stiff', 3, '10-12'),
        TemplateExercise('Leg Curl Deitado', 3, '10-12'),
        TemplateExercise('Panturrilha em Pé (Máquina)', 4, '15-20'),
      ]),
      TemplateDay('Peito & Costas B', [
        TemplateExercise('Supino Inclinado (Barra)', 4, '6-10'),
        TemplateExercise('Remada Unilateral (Halter)', 4, '8-12'),
        TemplateExercise('Peck Deck', 3, '12-15'),
        TemplateExercise('Pullover', 3, '12-15'),
        TemplateExercise('Crucifixo Inclinado', 3, '12-15'),
        TemplateExercise('Barra Fixa', 3, '6-10'),
      ]),
      TemplateDay('Ombros & Braços B', [
        TemplateExercise('Desenvolvimento (Halteres)', 4, '8-12'),
        TemplateExercise('Face Pull', 3, '15-20'),
        TemplateExercise('Remada Alta', 3, '12-15'),
        TemplateExercise('Rosca Scott', 3, '10-12'),
        TemplateExercise('Tríceps Testa', 3, '10-12'),
        TemplateExercise('Rosca Concentrada', 3, '12-15'),
      ]),
      TemplateDay('Pernas B', [
        TemplateExercise('Levantamento Terra', 4, '4-6'),
        TemplateExercise('Agachamento Búlgaro', 3, '8-10'),
        TemplateExercise('Hip Thrust', 3, '10-12'),
        TemplateExercise('Mesa Romana', 3, '10-12'),
        TemplateExercise('Leg Curl Sentado', 3, '12-15'),
        TemplateExercise('Panturrilha Sentado', 4, '15-20'),
      ]),
    ],
  ),
  WorkoutTemplate(
    name: 'PHUL (Força e Hipertrofia)',
    description: '4 dias por semana. 2 dias foco em força (Power), 2 dias hipertrofia.',
    badge: 'PHUL',
    color: Color(0xFFF44336), // Vermelho
    days: [
      TemplateDay('Upper Power', [
        TemplateExercise('Supino Plano (Barra)', 4, '3-5'),
        TemplateExercise('Remada Curvada (Barra)', 4, '3-5'),
        TemplateExercise('Desenvolvimento Militar', 3, '5-8'),
        TemplateExercise('Puxada Frontal', 3, '6-10'),
        TemplateExercise('Rosca Direta (Barra)', 3, '6-10'),
        TemplateExercise('Tríceps Testa', 3, '6-10'),
      ]),
      TemplateDay('Lower Power', [
        TemplateExercise('Agachamento Livre', 4, '3-5'),
        TemplateExercise('Levantamento Terra', 4, '3-5'),
        TemplateExercise('Leg Press', 3, '10-12'),
        TemplateExercise('Leg Curl', 3, '10-12'),
        TemplateExercise('Panturrilha em Pé', 4, '10-12'),
      ]),
      TemplateDay('Upper Hipertrofia', [
        TemplateExercise('Supino Inclinado (Halteres)', 4, '8-12'),
        TemplateExercise('Crucifixo Plano', 3, '10-15'),
        TemplateExercise('Remada com Cabo', 4, '8-12'),
        TemplateExercise('Face Pull', 3, '12-15'),
        TemplateExercise('Elevação Lateral', 4, '12-15'),
        TemplateExercise('Rosca Inclinada', 3, '10-12'),
        TemplateExercise('Tríceps Pulley', 3, '10-12'),
      ]),
      TemplateDay('Lower Hipertrofia', [
        TemplateExercise('Agachamento Frontal', 3, '8-12'),
        TemplateExercise('Afundos (Halteres)', 3, '10-12'),
        TemplateExercise('Extensão de Pernas', 3, '12-15'),
        TemplateExercise('Mesa Romana', 3, '12-15'),
        TemplateExercise('Panturrilha Sentado', 4, '15-20'),
      ]),
    ],
  ),
  WorkoutTemplate(
    name: 'Híbrido 5 Dias (U/L + PPL)',
    description: '5 dias por semana. Combina a frequência do Upper/Lower com o volume do PPL.',
    badge: '5-DAY',
    color: Color(0xFF00BCD4), // Ciano
    days: [
      TemplateDay('Upper', [
        TemplateExercise('Supino Plano (Barra)', 4, '6-8'),
        TemplateExercise('Remada Curvada (Barra)', 4, '6-8'),
        TemplateExercise('Desenvolvimento (Halteres)', 3, '8-10'),
        TemplateExercise('Puxada Frontal', 3, '8-10'),
        TemplateExercise('Bíceps e Tríceps (Super-série)', 3, '10-12'),
      ]),
      TemplateDay('Lower', [
        TemplateExercise('Agachamento Livre', 4, '6-8'),
        TemplateExercise('Leg Press', 3, '10-12'),
        TemplateExercise('Stiff', 3, '8-10'),
        TemplateExercise('Leg Curl', 3, '12-15'),
        TemplateExercise('Panturrilha em Pé', 4, '12-15'),
      ]),
      TemplateDay('Push', [
        TemplateExercise('Supino Inclinado (Halteres)', 4, '8-12'),
        TemplateExercise('Peck Deck', 3, '12-15'),
        TemplateExercise('Elevação Lateral', 4, '12-15'),
        TemplateExercise('Tríceps Pulley', 3, '12-15'),
      ]),
      TemplateDay('Pull', [
        TemplateExercise('Puxada Supinada', 4, '8-12'),
        TemplateExercise('Remada Baixa (Máquina)', 3, '10-12'),
        TemplateExercise('Face Pull', 3, '15-20'),
        TemplateExercise('Rosca Direta', 3, '10-12'),
      ]),
      TemplateDay('Legs', [
        TemplateExercise('Leg Press', 4, '10-15'),
        TemplateExercise('Agachamento Búlgaro', 3, '10-12'),
        TemplateExercise('Extensão de Pernas', 3, '15-20'),
        TemplateExercise('Panturrilha Sentado', 4, '15-20'),
      ]),
    ],
  ),
];

typedef TemplateSaveCallback = Future<void> Function(WorkoutTemplate template);

class WorkoutTemplatePicker extends StatelessWidget {
  final TemplateSaveCallback onUseTemplate;

  const WorkoutTemplatePicker({super.key, required this.onUseTemplate});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              _buildHandle(context),
              _buildHeader(AppLocalizations.of(context)!),
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  itemCount: workoutTemplates.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    return _TemplateCard(
                      template: workoutTemplates[index],
                      onUse: () => onUseTemplate(workoutTemplates[index]),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHandle(BuildContext context) {
    return Container(
      width: 40,
      height: 4,
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Row(
        children: [
          const _HeaderIcon(),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.workoutTemplatesTitle,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18)),
                Text(l10n.workoutTemplatesSub,
                    style:
                        const TextStyle(fontSize: 13, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF00E676).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.auto_awesome_rounded,
          color: Color(0xFF00E676), size: 22),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  final WorkoutTemplate template;
  final VoidCallback onUse;

  const _TemplateCard({required this.template, required this.onUse});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: template.color.withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: template.color.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                _BadgeIcon(template: template),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(template.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 2),
                      Text(template.description,
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              children: template.days
                  .map((d) => _DayChip(day: d, color: template.color))
                  .toList(),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: template.color,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: onUse,
                child: Text(AppLocalizations.of(context)!.useThisTemplate,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeIcon extends StatelessWidget {
  final WorkoutTemplate template;
  const _BadgeIcon({required this.template});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [template.color, template.color.withValues(alpha: 0.6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          template.badge,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  final TemplateDay day;
  final Color color;
  const _DayChip({required this.day, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        day.name,
        style: TextStyle(
            fontSize: 11, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
