import type { TemplateExercise, TemplateFolder, WorkoutTemplate } from '@/types/workout'

function row(n: number, reps: string, weight: string) {
  return Array.from({ length: n }, () => ({ targetReps: reps, targetWeight: weight }))
}

function te(
  planId: string,
  slug: string,
  name: string,
  sets: number,
  reps: string,
  weight: string,
  isCircuit = false,
  libraryId?: string,
): TemplateExercise {
  return {
    id: `${planId}__${slug}`,
    name,
    libraryId,
    isCircuit,
    sets: row(sets, reps, weight),
  }
}

export const BUNS_AND_THIGHS_FOLDER: TemplateFolder = {
  id: 'folder-buns-and-thighs',
  name: 'Buns and Thighs',
  purpose:
    'This is a 3-week program for all my girly pops to get those peaches juicy.',
}

const WEEK_FOCUS: Record<1 | 2 | 3, string> = {
  1: 'Week 1 — Baseline Strength & Mind-Muscle Connection: Focus on mastering the tempo (control the eccentric/lowering phase for 2–3 seconds) and maximizing the mind-muscle connection.',
  2: 'Week 2 — Progressive Overload & Volume Escalation: Increase weight slightly on primary lifts (squats, hip thrusts, RDLs) or add 1–2 reps per set vs Week 1. Keep execution clean.',
  3: 'Week 3 — Peak Intensity & Metabolic Fatigue: Use AMRAP and burnout techniques to fully exhaust muscle fibers for maximum aesthetic definition.',
}

function planNotes(week: 1 | 2 | 3, activity: string, extra?: string): string {
  const parts = [WEEK_FOCUS[week], `Activity: ${activity}`]
  if (extra?.trim()) parts.push(extra.trim())
  return parts.join('\n\n')
}

function bunsPlanId(week: number, day: number): string {
  return `plan-buns-w${week}-d${day}`
}

type DaySpec = {
  day: number
  title: string
  activity: string
  extraNotes?: string
  exercises: (id: string) => TemplateExercise[]
}

function buildBunsWeekPlans(week: 1 | 2 | 3): WorkoutTemplate[] {
  const days: DaySpec[] = []

  if (week === 1) {
    days.push(
      {
        day: 1,
        title: 'Glutes (Lower/Max), Quads & Upper Abs',
        activity: 'Heavy Resistance Training + Core (45–60 mins)',
        exercises: (id) => [
          te(id, 'warmup-bridge', 'Warm-up: Glute Bridges (Bodyweight)', 2, '15', '0', false, 'glute-bridge'),
          te(id, 'goblet', 'Dumbbell Goblet Squats', 3, '8–10', '40', false, 'goblet-squat'),
          te(id, 'lunge', 'Walking Lunges', 3, '10/leg', '25', false, 'walking-lunge'),
          te(id, 'pull-through', 'Cable Pull-Throughs (or RDLs)', 3, '12', '50', false, 'cable-pull-through'),
          te(id, 'hanging-knee', 'Hanging Knee Raises (or Captain’s Chair)', 3, '10–12', '0', false, 'hanging-knee-raise'),
          te(id, 'ab-wheel', 'Ab Wheel Rollouts', 3, '8', '0', false, 'ab-wheel-rollout'),
        ],
      },
      {
        day: 2,
        title: 'Cardio & Deep Core',
        activity: 'LISS Cardio & Isometric Core Waist-Trimming (30–40 mins)',
        exercises: (id) => [
          te(id, 'incline-walk', 'Incline Treadmill Walking', 1, '25–30 min', '0', false, 'incline-treadmill-walk'),
          te(id, 'plank-tap', 'Plank with Shoulder Taps', 3, '45 sec', '0', false, 'plank-shoulder-tap'),
          te(id, 'pallof', 'Pallof Press', 3, '12/side', '30', false, 'pallof-press'),
        ],
      },
      {
        day: 3,
        title: 'Glutes (Posterior), Hamstrings & Calves',
        activity: 'Lower Body Posterior Chain Focus (45 mins)',
        exercises: (id) => [
          te(id, 'hip-thrust', 'Barbell or Dumbbell Hip Thrusts', 4, '10', '135', false, 'hip-thrust'),
          te(id, 'rdl', 'Dumbbell Romanian Deadlifts (RDLs)', 3, '8–10', '50', false, 'dumbbell-romanian-deadlift'),
          te(id, 'bulgarian', 'Bulgarian Split Squats', 3, '8/leg', '30', false, 'bulgarian-split-squat'),
          te(id, 'calf', 'Standing Calf Raises', 3, '15', '135', false, 'calf-raise'),
        ],
      },
      {
        day: 4,
        title: 'Active Recovery & Mobility',
        activity: 'Dynamic Stretching & Hip Opening (20–30 mins)',
        exercises: (id) => [
          te(id, 'hip-90', '90/90 Hip Switches', 1, '2 min', '0', false, 'hip-90-90-switch'),
          te(id, 'cat-cow', 'Cat-Cow to Child’s Pose', 1, '3 min', '0', false, 'cat-cow-child-pose'),
          te(id, 'wgs', 'World’s Greatest Stretch', 1, '5/side', '0', false, 'worlds-greatest-stretch'),
          te(id, 'frog', 'Frog Stretch', 1, '2 min hold', '0', false, 'frog-stretch'),
          te(id, 'walk', 'Light Brisk Walk', 1, '15–20 min', '0', false, 'brisk-walk'),
        ],
      },
      {
        day: 5,
        title: 'Glute Isolation, Thigh Sculpting & Lower Abs',
        activity: 'High-Volume Hypertrophy (45 mins)',
        exercises: (id) => [
          te(id, 'kickback', 'Glute Kickbacks (Cable or Banded)', 3, '12–15/leg', '25', false, 'glute-kickback'),
          te(id, 'clam', 'Seated or Banded Clamshells', 3, '20', '0', false, 'banded-clamshell'),
          te(id, 'sumo', 'Sumo Squats (Plie Squats)', 3, '12', '50', false, 'sumo-squat'),
          te(id, 'rev-crunch', 'Reverse Crunches', 3, '12–15', '0', false, 'reverse-crunch'),
          te(id, 'deadbug', 'Deadbugs', 3, '10/side', '0', false, 'deadbug'),
        ],
      },
      {
        day: 6,
        title: 'HIIT & Core Burnout',
        activity: 'Metabolic Conditioning (25 mins)',
        extraNotes: 'HIIT circuit: 4 rounds — 45 seconds work, 15 seconds rest between stations.',
        exercises: (id) => [
          te(id, 'jump-squat', 'Jump Squats', 4, '45 sec', '0', true, 'jump-squat'),
          te(id, 'mountain', 'Mountain Climbers', 4, '45 sec', '0', true, 'mountain-climber'),
          te(id, 'kb-swing', 'Kettlebell Swings (or Pop Squats)', 4, '45 sec', '35', true, 'kettlebell-swing'),
          te(id, 'russian', 'Russian Twists', 4, '45 sec', '0', true, 'russian-twist'),
          te(id, 'plank', 'Plank Hold', 4, '45 sec', '0', true, 'plank'),
        ],
      },
      {
        day: 7,
        title: 'Full Rest & Regeneration',
        activity: 'Passive Rest & Targeted Stretching (15 mins)',
        exercises: (id) => [
          te(id, 'foam', 'Foam Rolling (Quads, IT Bands, Glutes)', 1, '5 min', '0', false, 'foam-roll-lower-body'),
          te(id, 'ham-stretch', 'Long-Hold Hamstring Stretch', 1, '30–60 sec/side', '0', false, 'hamstring-stretch-hold'),
          te(id, 'hip-flex', 'Long-Hold Hip Flexor Stretch', 1, '30–60 sec/side', '0', false, 'hip-flexor-stretch'),
        ],
      },
    )
  } else if (week === 2) {
    days.push(
      {
        day: 1,
        title: 'Glutes (Lower/Max), Quads & Upper Abs',
        activity: 'Heavy Resistance Training + Core (45–60 mins)',
        exercises: (id) => [
          te(id, 'warmup-bridge', 'Warm-up: Glute Bridges (Bodyweight)', 2, '20', '0', false, 'glute-bridge'),
          te(id, 'goblet', 'Dumbbell Goblet Squats', 3, '10', '45', false, 'goblet-squat'),
          te(id, 'lunge', 'Walking Lunges', 3, '12/leg', '30', false, 'walking-lunge'),
          te(id, 'pull-through', 'Cable Pull-Throughs (or RDLs)', 3, '12', '55', false, 'cable-pull-through'),
          te(id, 'hanging-knee', 'Hanging Knee Raises', 3, '12', '0', false, 'hanging-knee-raise'),
          te(id, 'ab-wheel', 'Ab Wheel Rollouts', 3, '10', '0', false, 'ab-wheel-rollout'),
        ],
      },
      {
        day: 2,
        title: 'Cardio & Deep Core',
        activity: 'LISS Cardio & Isometric Core (35–45 mins)',
        exercises: (id) => [
          te(id, 'incline-walk', 'Incline Treadmill Walking', 1, '30 min', '0', false, 'incline-treadmill-walk'),
          te(id, 'plank-tap', 'Plank with Shoulder Taps', 3, '60 sec', '0', false, 'plank-shoulder-tap'),
          te(id, 'pallof', 'Pallof Press', 3, '15/side', '35', false, 'pallof-press'),
        ],
      },
      {
        day: 3,
        title: 'Glutes (Posterior), Hamstrings & Calves',
        activity: 'Lower Body Posterior Chain Focus (45–50 mins)',
        exercises: (id) => [
          te(id, 'hip-thrust', 'Barbell or Dumbbell Hip Thrusts', 4, '12', '145', false, 'hip-thrust'),
          te(id, 'rdl', 'Dumbbell Romanian Deadlifts (RDLs)', 3, '10', '55', false, 'dumbbell-romanian-deadlift'),
          te(id, 'bulgarian', 'Bulgarian Split Squats', 3, '10/leg', '35', false, 'bulgarian-split-squat'),
          te(id, 'calf', 'Standing Calf Raises', 3, '18', '145', false, 'calf-raise'),
        ],
      },
      {
        day: 4,
        title: 'Active Recovery & Mobility',
        activity: 'Yoga-Inspired Flow & Low-Impact Movement (30 mins)',
        exercises: (id) => [
          te(id, 'dog-cobra', 'Downward Dog to Cobra Flow', 1, '5 rounds', '0', false, 'downward-dog-cobra-flow'),
          te(id, 'pigeon', 'Pigeon Pose', 1, '90 sec/side', '0', false, 'pigeon-pose'),
          te(id, 'low-lunge', 'Low Lunge Hip Flexor Stretch', 1, '60 sec/side', '0', false, 'low-lunge-hip-flexor-stretch'),
          te(id, 'walk', 'Light Outdoor Walk', 1, '20 min', '0', false, 'brisk-walk'),
        ],
      },
      {
        day: 5,
        title: 'Glute Isolation, Thigh Sculpting & Lower Abs',
        activity: 'High-Volume Hypertrophy (45 mins)',
        exercises: (id) => [
          te(id, 'kickback', 'Glute Kickbacks (Cable or Banded)', 3, '15/leg', '30', false, 'glute-kickback'),
          te(id, 'clam', 'Seated or Banded Clamshells', 3, '25', '0', false, 'banded-clamshell'),
          te(id, 'sumo', 'Sumo Squats (Plie Squats)', 3, '15', '55', false, 'sumo-squat'),
          te(id, 'rev-crunch', 'Reverse Crunches', 3, '15', '0', false, 'reverse-crunch'),
          te(id, 'deadbug', 'Deadbugs', 3, '12/side', '0', false, 'deadbug'),
        ],
      },
      {
        day: 6,
        title: 'HIIT & Core Burnout',
        activity: 'Metabolic Conditioning (25 mins)',
        extraNotes: 'HIIT circuit: 4 rounds — 50 seconds work, 10 seconds rest between stations.',
        exercises: (id) => [
          te(id, 'jump-squat', 'Jump Squats', 4, '50 sec', '0', true, 'jump-squat'),
          te(id, 'mountain', 'Mountain Climbers', 4, '50 sec', '0', true, 'mountain-climber'),
          te(id, 'kb-swing', 'Kettlebell Swings', 4, '50 sec', '35', true, 'kettlebell-swing'),
          te(id, 'russian', 'Russian Twists', 4, '50 sec', '0', true, 'russian-twist'),
          te(id, 'plank', 'Plank Hold', 4, '50 sec', '0', true, 'plank'),
        ],
      },
      {
        day: 7,
        title: 'Full Rest & Regeneration',
        activity: 'Rest & Lower Body Foam Rolling (15 mins)',
        exercises: (id) => [
          te(id, 'foam', 'Foam Rolling (Quads, IT Bands, Glutes)', 1, '8 min', '0', false, 'foam-roll-lower-body'),
          te(id, 'ham-stretch', 'Long-Hold Hamstring Stretch', 1, '45 sec/side', '0', false, 'hamstring-stretch-hold'),
          te(id, 'hip-flex', 'Long-Hold Hip Flexor Stretch', 1, '45 sec/side', '0', false, 'hip-flexor-stretch'),
        ],
      },
    )
  } else {
    days.push(
      {
        day: 1,
        title: 'Glutes (Lower/Max), Quads & Upper Abs',
        activity: 'Heavy Resistance + Metabolic Burnout (50–60 mins)',
        exercises: (id) => [
          te(id, 'warmup-bridge', 'Warm-up: Glute Bridges', 2, '20', '0', false, 'glute-bridge'),
          te(id, 'goblet', 'Dumbbell Goblet Squats', 3, '12', '50', false, 'goblet-squat'),
          te(id, 'lunge', 'Walking Lunges', 3, '14/leg', '35', false, 'walking-lunge'),
          te(id, 'pull-through', 'Cable Pull-Throughs (or RDLs)', 3, '15', '60', false, 'cable-pull-through'),
          te(id, 'hanging-knee', 'Hanging Knee Raises', 3, '12', '0', false, 'hanging-knee-raise'),
          te(id, 'ab-wheel', 'Ab Wheel Rollouts', 3, '12', '0', false, 'ab-wheel-rollout'),
        ],
      },
      {
        day: 2,
        title: 'Cardio & Deep Core',
        activity: 'LISS Cardio & Core Waist-Trimming (45 mins)',
        exercises: (id) => [
          te(id, 'incline-walk', 'Incline Treadmill Walking', 1, '35 min', '0', false, 'incline-treadmill-walk'),
          te(id, 'plank-tap', 'Plank with Shoulder Taps', 3, '60 sec', '0', false, 'plank-shoulder-tap'),
          te(id, 'pallof', 'Pallof Press', 3, '15/side', '40', false, 'pallof-press'),
        ],
      },
      {
        day: 3,
        title: 'Glutes (Posterior), Hamstrings & Calves',
        activity: 'Lower Body Posterior Peak (50 mins)',
        extraNotes:
          'Hip thrusts: 3 sets of 10, then 1 AMRAP set at Week 1 weight with 2-second pause on last reps. Bulgarian split squat final set: drop weights and do 8 bodyweight reps immediately after.',
        exercises: (id) => [
          te(id, 'hip-thrust', 'Barbell or Dumbbell Hip Thrusts', 4, '10 (last set AMRAP)', '155', false, 'hip-thrust'),
          te(id, 'rdl', 'Dumbbell Romanian Deadlifts (RDLs)', 3, '12', '60', false, 'dumbbell-romanian-deadlift'),
          te(id, 'bulgarian', 'Bulgarian Split Squats', 3, '10/leg', '40', false, 'bulgarian-split-squat'),
          te(id, 'calf', 'Standing Calf Raises', 3, '20', '155', false, 'calf-raise'),
        ],
      },
      {
        day: 4,
        title: 'Active Recovery & Mobility',
        activity: 'Hip Mobility & Core Decompression (25 mins)',
        exercises: (id) => [
          te(id, 'hip-90', '90/90 Hip Switches', 1, '3 min', '0', false, 'hip-90-90-switch'),
          te(id, 'frog', 'Frog Stretch', 1, '3 min hold', '0', false, 'frog-stretch'),
          te(id, 'spinal-twist', 'Spinal Twists (Lying Flat)', 1, '2 min/side', '0', false, 'lying-spinal-twist'),
          te(id, 'bike', 'Easy Stationary Cycling or Walking', 1, '15 min', '0', false, 'easy-stationary-bike'),
        ],
      },
      {
        day: 5,
        title: 'Glute Isolation, Thigh Sculpting & Lower Abs',
        activity: 'High-Volume Pump Circuit (45 mins)',
        exercises: (id) => [
          te(id, 'kickback', 'Glute Kickbacks', 3, '15/leg (2 sec squeeze)', '35', false, 'glute-kickback'),
          te(id, 'clam', 'Seated or Banded Clamshells', 3, '30', '0', false, 'banded-clamshell'),
          te(id, 'sumo', 'Sumo Squats (Plie Squats)', 3, '15', '60', false, 'sumo-squat'),
          te(id, 'rev-crunch', 'Reverse Crunches', 3, '15', '0', false, 'reverse-crunch'),
          te(id, 'deadbug', 'Deadbugs', 3, '15/side', '0', false, 'deadbug'),
        ],
      },
      {
        day: 6,
        title: 'HIIT & Functional Core Conditioning',
        activity: 'Metabolic Conditioning (30 mins)',
        extraNotes: 'HIIT circuit: 5 rounds — 45 seconds work, 15 seconds rest between stations.',
        exercises: (id) => [
          te(id, 'jump-squat', 'Jump Squats', 5, '45 sec', '0', true, 'jump-squat'),
          te(id, 'mountain', 'Mountain Climbers', 5, '45 sec', '0', true, 'mountain-climber'),
          te(id, 'kb-swing', 'Kettlebell Swings (or Pop Squats)', 5, '45 sec', '35', true, 'kettlebell-swing'),
          te(id, 'russian', 'Russian Twists', 5, '45 sec', '0', true, 'russian-twist'),
          te(id, 'plank', 'Plank Hold', 5, '45 sec', '0', true, 'plank'),
        ],
      },
      {
        day: 7,
        title: 'Full Rest & Deep Stretch',
        activity: 'Total Body Recovery & Relaxation (20 mins)',
        extraNotes:
          'Focus on deep, static stretching of the hip flexors, glutes, hamstrings, and lower back to encourage optimal muscle recovery.',
        exercises: (id) => [
          te(id, 'deep-stretch', 'Deep Static Stretch (Hips & Lower Back)', 1, '20 min', '0', false, 'deep-static-stretch-lower'),
        ],
      },
    )
  }

  return days.map((spec) => {
    const id = bunsPlanId(week, spec.day)
    const globalDay = (week - 1) * 7 + spec.day
    return {
      id,
      name: `Week ${week} - Day ${globalDay}: ${spec.title}`,
      folderId: BUNS_AND_THIGHS_FOLDER.id,
      notes: planNotes(week, spec.activity, spec.extraNotes),
      exercises: spec.exercises(id),
    }
  })
}

export const BUNS_AND_THIGHS_PLANS: WorkoutTemplate[] = [
  ...buildBunsWeekPlans(1),
  ...buildBunsWeekPlans(2),
  ...buildBunsWeekPlans(3),
]
