import type { TemplateFolder, WorkoutTemplate } from '@/types/workout'
import raw from './joeyC4.json'

type JoeyC4File = {
  templates: WorkoutTemplate[]
  folders: TemplateFolder[]
}

const data = raw as JoeyC4File
const folder = data.folders[0]

if (!folder) {
  throw new Error('Joey C4 folder is missing from joeyC4.json')
}

export const JOEY_C4_FOLDER: TemplateFolder = folder
export const JOEY_C4_PLANS: WorkoutTemplate[] = data.templates
