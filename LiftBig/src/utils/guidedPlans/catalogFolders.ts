import type { TemplateFolder } from '@/types/workout'
import { EXPANSION_CATALOG_FOLDERS } from './catalogExpansion'

function catalogFolder(
  slug: string,
  name: string,
  purpose: string,
): TemplateFolder {
  return {
    id: `folder-catalog-${slug}`,
    name,
    purpose,
  }
}

/** Dedicated weekly folders for each Pick a Plan catalog program */
export const CATALOG_WEEKLY_FOLDERS: TemplateFolder[] = [
  catalogFolder(
    'beginner-full-body-3d',
    'Beginner Full Body (3d)',
    'Simple full-body sessions three times per week. Perfect for learning movement patterns.',
  ),
  catalogFolder(
    'beginner-upper-lower-4d',
    'Beginner Upper Lower (4d)',
    'Four-day upper/lower split with manageable volume for steady progress.',
  ),
  catalogFolder(
    'busy-beginner',
    'Busy Beginner (3×30)',
    'Quick circuit sessions around 30 minutes. Great when time is tight.',
  ),
  catalogFolder(
    'beginner-weight-loss',
    'Beginner Weight Loss',
    'Circuit training plus cardio to burn calories while keeping muscle.',
  ),
  catalogFolder(
    'planet-fitness-starter',
    'Planet Fitness Starter',
    'Full-body barbell and dumbbell training for Planet Fitness — compounds plus cable accessories.',
  ),
  catalogFolder(
    'dumbbell-starter',
    'Dumbbell Starter',
    'Full-body dumbbell training for home or minimal equipment setups.',
  ),
  catalogFolder(
    'intermediate-ul-hypertrophy',
    'Upper Lower Hypertrophy',
    'Classic four-day upper/lower split with hypertrophy-focused rep ranges.',
  ),
  catalogFolder(
    'intermediate-ppl',
    'Push Pull Legs',
    'Three-day PPL rotation. Run once or twice per week depending on recovery.',
  ),
  catalogFolder(
    'powerbuilding-4d',
    'Powerbuilding 4 Day',
    'Heavy compounds paired with hypertrophy accessories across four days.',
  ),
  catalogFolder(
    'lean-muscle-builder',
    'Lean Muscle Builder',
    'Recomposition-focused training with moderate volume and cardio finishers.',
  ),
  catalogFolder(
    'busy-professional',
    'Busy Professional',
    'Efficient sessions for lifters with limited time but solid gym experience.',
  ),
  catalogFolder(
    'machine-hypertrophy',
    'Machine Hypertrophy',
    'Joint-friendly machine volume for consistent hypertrophy stimulus.',
  ),
  catalogFolder(
    'aesthetic-v-taper',
    'Aesthetic V-Taper',
    'Shoulder and back emphasis for the classic V-taper physique.',
  ),
  catalogFolder(
    'high-volume-ppl',
    'High Volume PPL',
    'High-volume push/pull/legs for experienced lifters who recover well.',
  ),
  catalogFolder(
    'upper-lower-arms',
    'Upper Lower Arms',
    'Upper/lower split with a dedicated arm day for sleeve-stretching volume.',
  ),
  catalogFolder(
    'powerbuilding-advanced',
    'Powerbuilding Advanced',
    'Heavy strength days with dedicated accessory work for advanced lifters.',
  ),
  catalogFolder(
    'summer-cut',
    'Summer Cut',
    'Superset-friendly cut phase with cardio finishers to lean out.',
  ),
  catalogFolder(
    'strength-hybrid',
    'Strength Hybrid',
    'Strength-first full body with heavy compounds. Repeat 3–4× per week.',
  ),
  catalogFolder(
    'liftbig-extreme',
    'LiftBig Extreme',
    'Maximum volume PPL for lifters who want serious training stimulus.',
  ),
  catalogFolder(
    'arnold-ppl',
    'Arnold x PPL',
    'Classic bodybuilding volume inspired by golden-era splits.',
  ),
  catalogFolder(
    'double-split',
    'Double Split',
    'AM/PM training splits for maximum weekly frequency and volume.',
  ),
  catalogFolder(
    'mass-monster',
    'Mass Monster',
    'High-volume body part split for maximum hypertrophy stimulus.',
  ),
  catalogFolder(
    'high-freq-full-body',
    'High Frequency Full Body',
    'Full body repeated 5–6× per week with submaximal loads.',
  ),
  catalogFolder(
    'advanced-aesthetics',
    'Advanced Aesthetics',
    'Refined upper/lower rotation with aesthetic emphasis on proportions.',
  ),
  ...EXPANSION_CATALOG_FOLDERS,
]

export const CATALOG_FOLDER_BY_SLUG = Object.fromEntries(
  CATALOG_WEEKLY_FOLDERS.map((f) => [f.id.replace('folder-catalog-', ''), f]),
) as Record<string, TemplateFolder>

export function catalogFolderId(slug: string): string {
  return `folder-catalog-${slug}`
}
