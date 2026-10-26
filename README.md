# EcoVision

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-%2302569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/V-Modal-SDK-6C5CE7?style=for-the-badge" alt="V-Modal SDK" />
  <img src="https://img.shields.io/badge/AI-Search-10B981?style=for-the-badge" alt="AI Search" />
</p>

<p align="center">
  <strong>Upload wildlife footage. Search by meaning. Jump directly to video moments.</strong><br>
  EcoVision helps researchers turn raw field recordings into searchable, timestamped AI observations.
</p>

EcoVision is a Flutter app for wildlife and environmental research. It uses the <a href="https://pub.dev/packages/vmodal_sdk_flutter" target="_blank">vmodal_sdk_flutter</a> SDK to upload videos, index them for semantic understanding, and return timestamped moments based on natural language text prompts or reference images.

The workflow is simple:

1. Upload a video
2. Let V-Modal index it
3. Search with text or an image
4. Review matched timestamped moments with frame thumbnails
5. Tap any moment to play the video right from that exact timestamp
6. Save important observations for field research

<div align="center">

## 📲 Android App Download

<a href="https://drive.google.com/file/d/1zLxiWbnAvKU0aHRR_UHyRVtONWquO-er/view?usp=sharing" target="_blank">
  <img src="https://img.shields.io/badge/Android-Download%20APK-34A853?style=for-the-badge&logo=android&logoColor=white" alt="Download EcoVision Android APK" width="260" />
</a>

<strong>Latest Android build</strong><br>
Install the APK to test the current EcoVision workflow.

</div>

## What the app does

- Upload wildlife and field videos to the V-Modal pipeline
- Index footage for semantic analysis and search
- Search using natural-language prompts such as “elephants near water”
- Add a reference image to find visually similar moments in footage
- Browse results as timestamped video moments with frame thumbnails (listing each appearance in a video as its own result)
- Tap any result to seek and play the source video starting at that exact moment
- Browse recent sightings in the Discovery Feed (sorted newest first) and play clips from their start times
- Save meaningful observations with video references and timestamps into field research records
- Review research dashboard statistics and recent species sightings

## App flow

### 1. Upload footage
Select a wildlife or environmental video from the device and prepare it for indexing.

### 2. Index content
The app sends the video to V-Modal so the footage can be analyzed and made searchable across all modalities.

### 3. Search by text or image
Use either:
- a text query like “lion near river”
- a reference image to find visually similar moments

### 4. Direct video moment playback
Every search hit and discovery feed item points to the exact timestamp in the source video:
- Shows video title, formatted timestamp (e.g., `01:23`), and a small thumbnail frame
- Tapping a result opens the video player and begins playback at that timestamp (seeks first, then plays)
- Lists each appearance of an animal as its own distinct result

### 5. Discovery Feed & Saved Observations
- **Discovery Feed**: Displays recent AI-detected sightings across indexed footage, sorted newest first with video references and start times
- **Saved Observations**: Save video references and timestamps so reopening an observation lands on the exact moment in the footage

## Core features

- **Video upload & indexing** — add footage into the app for V-Modal multimodal indexation
- **Semantic search** — find relevant moments from natural-language prompts
- **Reference image search** — search using an image as a visual query
- **Timestamped video moments** — direct seeking to exact video timestamps
- **Global archive search** — search across the broader indexed library
- **Semantic chips** — quick prompts for common research categories (“elephants near water”, “lion roaring”, etc.)
- **Discovery feed** — view recent AI-detected sightings with clip start timestamps
- **Saved observations** — save observations with species tags, field notes, video references, and timestamps
- **Robust error handling** — handles timestamps past video duration, deleted or missing files, slow buffering, and empty queries cleanly

## Tech stack

- **Flutter** — cross-platform mobile app framework
- **GetX** — reactive state management and routing
- **vmodal_sdk_flutter** — semantic indexing and AI search integration
- **video_player** — local video playback and precise seeking
- **localstore** — persistent storage for saved observations and bookmarks
- **video_snapshot_generator** — thumbnail frame generation from video timestamps

## Setup

1. **Install dependencies**

   ```bash
   flutter pub get
   ```

2. **Configure V-Modal**

   Configure your runtime API key directly in the app settings, or pass environment flags:
   ```bash
   flutter run --dart-define=VMODAL_API_KEY=your_api_key --dart-define=VMODAL_PROJECT_ID=your_project_id
   ```

3. **Android requirements**

   Make sure `minSdkVersion` is set to 21 or higher.

---

<p align="center">
  Built with <strong>EcoVision</strong> and <strong>V-Modal</strong>.
</p>
