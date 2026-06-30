export {
  d as getEquipmentOptions,
  g as searchExercises,
  n as MUSCLE_GROUP_KEYS,
  r as MUSCLE_GROUP_LABELS,
} from '../../../dist/assets/exerciseLibrary-PHUUbGWG.js';

export type Exercise = {
  id: string;
  name: string;
  equipment?: string;
  summary: string;
  muscleGroups: string[];
  tags?: string[];
  isCardio?: boolean;
  tutorialUrl?: string;
  instructions?: string[];
  cues?: string[];
  tips?: string[];
};
