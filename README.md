# EcoVision

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-%2302569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/V-Modal-SDK-6C5CE7?style=for-the-badge" alt="V-Modal SDK" />
  <img src="https://img.shields.io/badge/AI-Search-10B981?style=for-the-badge" alt="AI Search" />
</p>

<p align="center">
  <strong>Upload wildlife footage. Search by meaning. Review the results.</strong><br>
  EcoVision helps researchers turn raw field recordings into searchable, AI-driven observations.
</p>

EcoVision is a Flutter app for wildlife and environmental research. It uses the <a href="https://pub.dev/packages/vmodal_sdk_flutter" target="_blank">vmodal_sdk_flutter</a> SDK to upload videos, index them for semantic understanding, and return results based on text prompts or reference images.

This app is focused on discovery and analysis, not playback-first video viewing. The workflow is simple:

1. Upload a video
2. Let V-Modal index it
3. Search with text or an image
4. Review matched results and preview images
5. Save the most important observations

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
- Add a reference image to find visually similar moments
- Browse results as AI-matched observations with previews
- Save meaningful results into a local observation list
- Review discovery feed items across indexed footage

## App flow

### 1. Upload footage
Select a wildlife or environmental video from the device and prepare it for indexing.

### 2. Index content
The app sends the video to V-Modal so the footage can be analyzed and made searchable.

### 3. Search by text or image
Use either:

- a text query like “lion near river”
- a reference image to find visually similar content

### 4. Review results
Results are returned as matched observations with preview images and related metadata, rather than a full video playback experience.

### 5. Save highlights
Bookmark important findings for later review in the saved observations area.

## Core features

- **Video upload** — add media into the app for indexing
- **Semantic search** — find relevant scenes from natural-language prompts
- **Reference image search** — search using an image as a visual cue
- **Global archive search** — search across the wider indexed library
- **Semantic chips** — quick prompts for common research categories
- **Discovery feed** — view recent AI-detected sightings and moments
- **Saved observations** — keep important results for later review
- **Preview-based results** — inspect matching moments via image previews instead of playback-first viewing

## Tech stack

- **Flutter** — mobile app framework
- **GetX** — routing and state management
- **vmodal_sdk_flutter** — semantic indexing and AI search integration
- **localstore** — local persistence for saved observations
- **video_player** — supporting media handling for uploaded footage

## Setup

1. **Install dependencies**

   ```bash
   flutter pub get
   ```

2. **Configure V-Modal**

   ```bash
   flutter run --dart-define=VMODAL_API_KEY=your_api_key --dart-define=VMODAL_PROJECT_ID=your_project_id
   ```

3. **Android requirements**

   Make sure `minSdkVersion` is set to 21 or higher.

## Current usage model

The current experience is not a video-watching app. Instead, it is a search-and-analysis workflow:

- upload video
- index it
- query by text or image
- review result cards and previews
- save and revisit findings

That is the workflow the app is built around today.

---

<p align="center">
  Built with <strong>EcoVision</strong> and <strong>V-Modal</strong>.
</p>
