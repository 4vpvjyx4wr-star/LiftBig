# LiftBig Exercise Illustration Pipeline

Local Python pipeline that builds a cohesive exercise illustration library for the Form tutorial UI.

## What it does

1. Takes exercise names from `exercise_list.json`
2. Searches **ExerciseDB OSS** (free, no API key), then **Wikimedia Commons**
3. Downloads the best match (or draws a LiftBig silhouette fallback)
4. Applies the LiftBig theme (light background, grey athlete, blue muscle highlights)
5. Writes optimized assets into the Vue app `public/` folder

## Visual style (design system — required)

| Token | Value |
|---|---|
| Background | `#F8F9FA` |
| Athlete / model | Grey anatomical model (not a photo of a real person) |
| Primary muscle highlight | `#2563EB` |
| Secondary muscle highlight | `#60A5FA` |
| Thumbnail | 320×320 PNG, rounded corners |
| Animation | Looping GIF, ~3–5s, &lt; 1.5 MB, seamless loop, smooth stable crop |
| Angle | ¾ view preferred |
| Content | No text, logos, or watermarks |
| Source preference | ExerciseDB OSS anatomical GIFs first; correct equipment matching; no stock photos |

**Skip GIFs for:** cardio and sports (`isCardio: true`). Some mobility / stretch entries may intentionally omit a GIF (leave `animation: null` and clear thumbnail if the illustration slot should stay empty).

## Setup (Windows)

```powershell
cd LiftBig\tools\exercise-assets
python -m venv .venv
.\.venv\Scripts\activate
pip install -r requirements.txt
```

`rembg` pulls a small ONNX model on first use (needs network once). If install fails, run with `--no-rembg`.

## Generate the initial 25 exercises

```powershell
python generate_assets.py --out ..\..\public
```

## Sync full gym catalog from the Vue library

Non-cardio entries in `src/utils/exerciseLibrary.ts` can be synced into the asset maps:

```powershell
python sync_from_library.py
python generate_assets.py --no-rembg --out ..\..\public
```

`sync_from_library.py` skips `isCardio: true` exercises, derives `edbQueries` / muscle labels from the library, and **keeps curated `edbQueries`** from an existing `name_map.json` when the library `id` already matches.

If the API rate-limits, generate in batches:

```powershell
python generate_assets.py --no-rembg --only pull-up --only deadlift --out ..\..\public
```

Outputs:

```
LiftBig/public/assets/exercises/*.png
LiftBig/public/assets/exercises/gifs/*.gif
LiftBig/public/data/exercise_assets.json
```

### Useful flags

```powershell
# One exercise
python generate_assets.py --only bench-press --out ..\..\public

# Skip GIFs (PNG only)
python generate_assets.py --skip-gif --out ..\..\public

# Faster / no rembg model
python generate_assets.py --no-rembg --out ..\..\public
```

## Checklist: adding a library exercise (required standard)

Whenever you add an exercise to the library, complete **all** of the following (GIF + YouTube are mandatory for gym / non-cardio lifts unless intentionally omitted for mobility):

1. **Library entry** — add to `src/utils/exerciseLibrary.ts` (same kebab-case `id` everywhere).
2. **YouTube tutorial** — add URL in `src/utils/exerciseTutorials.ts` (or the library field the app uses for tutorials).
3. **Asset maps** — add to `name_map.json` + `exercise_list.json`, **or** run:

   ```powershell
   python sync_from_library.py
   ```

4. **Generate illustration** (gym / non-cardio):

   ```powershell
   python generate_assets.py --only {id} --out ..\..\public
   ```

   Prefer ExerciseDB OSS anatomical GIFs with correct equipment. Meet the design system criteria above. Cardio/sports skip GIFs. Some mobility may omit GIF intentionally (`animation: null`; clear thumbnail too if the Form illustration slot should stay empty).

5. **Verify** — Form tutorial sheet shows GIF (or intentional empty slot) + YouTube via `/data/exercise_assets.json`. No broken `img` src (null/empty animation and thumbnail → no image block).

### Copy an existing asset to another id

```powershell
python _copy_asset.py source-id destination-id
```

## License notes

- **ExerciseDB OSS**: non-commercial + attribution (AscendAPI). For commercial/SaaS distribution, use a paid AscendAPI plan or rely on Wikimedia / silhouettes only.
- **Wikimedia**: follow each file’s CC license; see `attributions.md` after a run.
- Do **not** scrape Google Images or copyrighted stock.

## Example manifest entry

```json
{
  "id": "bench-press",
  "name": "Bench Press",
  "thumbnail": "/assets/exercises/bench-press.png",
  "animation": "/assets/exercises/gifs/bench-press.gif",
  "primaryMuscles": ["Chest"],
  "secondaryMuscles": ["Triceps", "Shoulders"],
  "source": "exercisedb-oss",
  "licenseNote": "Non-commercial; attribute AscendAPI / ExerciseDB OSS"
}
```

## Pipeline modules

| Module | Functions |
|---|---|
| `pipeline/search.py` | `search_exercise_image` |
| `pipeline/download.py` | `download_asset` |
| `pipeline/process.py` | `remove_background`, `apply_liftbig_theme`, `create_thumbnail`, `create_looping_gif` |
| `pipeline/silhouette.py` | silhouette fallback |
| `generate_assets.py` | `build_asset_library` CLI |
