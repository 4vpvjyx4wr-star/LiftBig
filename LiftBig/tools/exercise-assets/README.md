# LiftBig Exercise Illustration Pipeline

Local Python pipeline that builds a cohesive exercise illustration library for the Form tutorial UI.

## What it does

1. Takes exercise names from `exercise_list.json`
2. Searches **ExerciseDB OSS** (free, no API key), then **Wikimedia Commons**
3. Downloads the best match (or draws a LiftBig silhouette fallback)
4. Applies the LiftBig theme (light background, grey athlete, blue muscle highlights)
5. Writes optimized assets into the Vue app `public/` folder

## Visual style

| Token | Value |
|---|---|
| Background | `#F8F9FA` |
| Primary muscle highlight | `#2563EB` |
| Secondary muscle highlight | `#60A5FA` |
| Thumbnail | 320×320 PNG, rounded corners |
| Animation | Looping GIF, ~3–5s, &lt; 1.5 MB |

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

## Add new exercises later

1. Add the display name to `exercise_list.json`
2. Add a mapping in `name_map.json`:

```json
"My New Lift": {
  "id": "my-new-lift",
  "edbQueries": ["my new lift", "alternate name"],
  "primaryMuscles": ["Chest"],
  "secondaryMuscles": ["Triceps"]
}
```

Use the same kebab-case `id` as in `src/utils/exerciseLibrary.ts`.

3. Re-run:

```powershell
python generate_assets.py --only my-new-lift --out ..\..\public
```

4. The Form tutorial sheet picks up assets automatically via `/data/exercise_assets.json`.

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
