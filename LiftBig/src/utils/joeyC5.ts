import type { TemplateFolder, WorkoutTemplate } from '@/types/workout'
import raw from './joeyC5.json'

type JoeyC5File = {
  templates: WorkoutTemplate[]
  folders: TemplateFolder[]
}

const data = raw as JoeyC5File
const folder = data.folders[0]

if (!folder) {
  throw new Error('Joey C5 folder is missing from joeyC5.json')
}

export const JOEY_C5_FOLDER: TemplateFolder = folder
export const JOEY_C5_PLANS: WorkoutTemplate[] = data.templates
