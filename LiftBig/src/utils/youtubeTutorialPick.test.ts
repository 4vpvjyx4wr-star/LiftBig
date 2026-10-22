import { describe, expect, it } from 'vitest'
import { pickTutorial, type TutorialCandidate } from '@/utils/youtubeTutorialPick'

function video(
  id: string,
  title: string,
  channel: string,
  durationSeconds: number,
  description = '',
): TutorialCandidate {
  return { id, title, channel, durationSeconds, description }
}

describe('pickTutorial', () => {
  it('picks a short machine shoulder-press form tutorial from a known source', () => {
    const pick = pickTutorial(
      { id: 'machine-shoulder-press', name: 'Machine Shoulder Press', equipment: 'Machine' },
      [
        video('Wqq43dKW1TU', 'How To: Overhead Press (Cybex)', 'ScottHermanFitness', 137),
        video('2yjwXTZQDDI', 'How To: Standing Straight-Bar Military / Overhead Press', 'ScottHermanFitness', 168),
        video('qEwKCR5JCog', 'How To: Dumbbell Shoulder Press', 'ScottHermanFitness', 144),
        video(
          'oAadscMCGLU',
          'How to Use the Life Fitness Shoulder Press Machine (Proper Setup & Form)',
          'Fitness 19',
          123,
        ),
        video('BAZkFGeUy5U', 'Shoulder Press Machine | Tutorial for Gym Beginners', 'Tim Bullici', 180),
        video('3R14MnZbcpw', 'How to PROPERLY Shoulder Machine Press (LEARN FAST)', 'Colossus Fitness', 146),
      ],
    )
    expect(pick?.id).toBe('oAadscMCGLU')
  })

  it('picks a back-extension how-to and skips superman and long videos', () => {
    const pick = pickTutorial(
      { id: 'back-extension', name: 'Back Extension', equipment: 'Machine' },
      [
        video('goynWxHQCWw', 'How To: Superman Hyperextension', 'ScottHermanFitness', 102),
        video('H8Swl1N-uis', 'STOP Doing Back Extensions Like This!', 'Squat University', 220),
        video('EBui4Bt5N7o', 'STOP Doing Back Extensions Like This!', 'Squat University', 59, 'Get my book on fixing injury'),
        video('ph3pddpKzzw', 'How to Do Back Extensions', 'LIVESTRONG', 83),
        video(
          'WnsnESPx4JE',
          'How to use the Back Extension - Eagle NX',
          'Cybex',
          53,
          'Basic instruction for proper use of the Cybex Eagle NX Back Extension.',
        ),
      ],
    )
    expect(pick?.id).toBe('WnsnESPx4JE')
  })

  it('picks an assisted-dip machine tutorial, not a bodyweight dip critique', () => {
    const pick = pickTutorial(
      { id: 'assisted-dip', name: 'Assisted Dip', equipment: 'Machine' },
      [
        video('vi1-BOcj3cQ', 'Are You Doing Dips Properly? (AVOID MISTAKES!)', 'ATHLEAN-X™', 303),
        video('yZ83t4mrPrI', 'Assisted Dip', 'Renaissance Periodization', 11),
        video('kbmVlw-i0Vs', 'Exercise Tutorial: Assisted Dips', 'Travis Tarrant', 141),
        video('8zFcJWD9Y_E', 'How-To Use the "Dip/Chin Assist" machine', "Tri Cities Gold's Gym", 97),
      ],
    )
    expect(pick?.id).toBe('8zFcJWD9Y_E')
  })

  it('picks the Cybex arm-curl how-to for the machine biceps curl', () => {
    const pick = pickTutorial(
      { id: 'machine-bicep-curl', name: 'Machine Bicep Curl', equipment: 'Machine' },
      [
        video('4XQLqBelbPw', 'Cable Bicep Curl Tutorial', 'Luke and Sarah Bond', 18),
        video('AR-oARBkYxI', 'How to PROPERLY DO Machine Bicep Curls (Machine Preacher Curls)', 'Colossus Fitness', 125),
        video('kfE9Plm8Hks', 'Biceps Curl Machine Tutorial', "Anytime Fitness Bright's Grove", 56),
        video('M_uPvGrMx_o', 'How To: Arm Curl (Cybex)', 'ScottHermanFitness', 99),
      ],
    )
    expect(pick?.id).toBe('M_uPvGrMx_o')
  })

  it('picks a machine triceps extension and skips cable pushdowns', () => {
    const pick = pickTutorial(
      { id: 'machine-triceps-extension', name: 'Machine Triceps Extension', equipment: 'Machine' },
      [
        video('2-LAMcpzODU', 'How To: Tricep Pushdown (Life Fitness Cable)', 'ScottHermanFitness', 112),
        video('cBt1X8fwKKc', 'How To: Arm Extension (Cybex)', 'ScottHermanFitness', 111),
        video('GwOKIDT4h60', 'How To: Triceps Extension (Hammer Strength)', 'ScottHermanFitness', 108),
        video(
          'S_evjJzI4hA',
          'How to Use the Triceps Extension Machine (Life Fitness) | Proper Form & Setup',
          'Fitness 19',
          138,
        ),
      ],
    )
    expect(pick?.id).toBe('S_evjJzI4hA')
  })

  it('picks hip abduction and rejects hip adduction', () => {
    const pick = pickTutorial(
      { id: 'hip-abductor-machine', name: 'Hip Abductor Machine', equipment: 'Machine' },
      [
        video('GmRSV_n2E_0', 'How To: Hip Adduction (Cybex)', 'ScottHermanFitness', 139),
        video('1rbpTTzEnV4', 'How To: Hip Abduction (LF Cable)', 'ScottHermanFitness', 89),
        video('2b97cvyH9sE', 'How To: Hip Abduction (Cybex)', 'ScottHermanFitness', 119),
        video('OjI5OpV6IWA', 'How to PROPERLY Use The Abductor Machine (STOP DOING THIS)', 'Colossus Fitness', 234),
      ],
    )
    expect(pick?.id).toBe('2b97cvyH9sE')
  })

  it('picks a proper sit-up tutorial and skips kettlebell and long videos', () => {
    const pick = pickTutorial(
      { id: 'sit-up', name: 'Sit-Up', equipment: 'Bodyweight' },
      [
        video('wXZxPX4Cv04', 'How to Perform a Kettlebell Situp', 'Nuffield Health', 38),
        video('s3PPU_2z9qo', 'How To Do Sit Ups Correctly For Beginners', 'Live Lean TV', 319),
        video('pCX65Mtc_Kk', 'How To Do a Sit Up Correctly', 'Detroit Medical Center', 42),
        video('jDwoBqPH0jk', 'How to Do a Sit-Up Properly | Gym Workout', 'Howcast', 72),
      ],
    )
    expect(pick?.id).toBe('jDwoBqPH0jk')
  })

  it('returns nothing when every result is too long or off-exercise', () => {
    const pick = pickTutorial(
      { id: 'hack-squat', name: 'Hack Squat', equipment: 'Machine' },
      [
        video('aaaaaaaaaaa', 'How to Barbell Back Squat', 'ScottHermanFitness', 90),
        video('bbbbbbbbbbb', 'Hack Squat Workout Routine', 'ScottHermanFitness', 400),
      ],
    )
    expect(pick).toBeNull()
  })
})
