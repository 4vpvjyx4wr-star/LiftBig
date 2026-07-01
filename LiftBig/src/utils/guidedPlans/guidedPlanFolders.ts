import type { TemplateFolder } from '@/types/workout'

export const GUIDED_BEGINNER_FOLDER: TemplateFolder = {
  id: 'folder-guided-beginner',
  name: 'Guided — Beginner',
  purpose: 'Curated beginner programs from Pick a Plan — full body, upper/lower, and equipment-specific starters.',
}

export const GUIDED_INTERMEDIATE_FOLDER: TemplateFolder = {
  id: 'folder-guided-intermediate',
  name: 'Guided — Intermediate',
  purpose: 'Balanced splits and strength/hypertrophy blocks for lifters past the novice stage.',
}

export const GUIDED_EXPERIENCED_FOLDER: TemplateFolder = {
  id: 'folder-guided-experienced',
  name: 'Guided — Experienced',
  purpose: 'Higher-volume splits, powerbuilding, and performance-focused programs.',
}

export const GUIDED_LIFTAHOLIC_FOLDER: TemplateFolder = {
  id: 'folder-guided-liftaholic',
  name: 'Guided — Liftaholic',
  purpose: 'High-frequency and peaking-style blocks for dedicated lifters.',
}

export const GUIDED_GENERATED_FOLDER: TemplateFolder = {
  id: 'folder-guided-generated',
  name: 'Guided — Generated',
  purpose: 'Custom plans created by Pick a Plan when no catalog match scores high enough.',
}

export const GUIDED_PLAN_FOLDERS: TemplateFolder[] = [
  GUIDED_BEGINNER_FOLDER,
  GUIDED_INTERMEDIATE_FOLDER,
  GUIDED_EXPERIENCED_FOLDER,
  GUIDED_LIFTAHOLIC_FOLDER,
  GUIDED_GENERATED_FOLDER,
]
