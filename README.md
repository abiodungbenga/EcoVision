# EcoVision

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-%2302569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/V-Modal-SDK-6C5CE7?style=for-the-badge" alt="V-Modal SDK" />
  <img src="https://img.shields.io/badge/AI-Video%20Search-10B981?style=for-the-badge" alt="AI Video Search" />
</p>

<p align="center">
  <strong>Search wildlife footage by meaning.</strong><br>
  Discover the moments that matter in field recordings using semantic search and AI-powered video intelligence.
</p>

EcoVision is a premium proof-of-concept for environmental researchers and conservation teams. It uses the <a href="https://pub.dev/packages/vmodal_sdk_flutter" target="_blank">vmodal_sdk_flutter</a> SDK to upload wildlife footage, index it, and perform natural-language searches for specific moments in video content.

> EcoVision turns raw field footage into searchable, actionable wildlife intelligence.

<div align="center">

## 📲 Android App Download

<a href="https://drive.google.com/file/d/1zLxiWbnAvKU0aHRR_UHyRVtONWquO-er/view?usp=sharing" target="_blank">
  <img src="https://img.shields.io/badge/Android-Download%20APK-34A853?style=for-the-badge&logo=android&logoColor=white" alt="Download EcoVision Android APK" width="260" />
</a>

<strong>Latest Android build</strong><br>
Install the APK to explore the latest wildlife intelligence experience on Android.

</div>

## Why EcoVision

- Explore wildlife footage without manual tagging or keyword-heavy review.
- Search by behavior, event, or visual similarity using natural language.
- Archive and revisit high-value moments from field research collections.
- Accelerate conservation monitoring with AI-powered semantic indexing.

## Key Features

- **Wildlife Library** — View and organize field footage from research collections.
- **Smart Upload** — Upload videos directly into the V-Modal pipeline.
- **AI Indexing** — Automatically analyze visual and semantic content for searchable moments.
- **Semantic Search** — Find moments like “elephants near water” without relying on manual labels.
- **Global Archive Search** — Query across an entire indexed research library in one step.
- **Semantic Filters** — Jump to common behaviors such as predation, drinking, and human intrusion.
- **Discovery Feed** — Track the latest AI-detected wildlife activity across all footage.
- **Saved Observations** — Bookmark important wildlife moments and keep them locally on-device.
- **Visual Reference Search** — Search using an image to find matching subjects and events.
- **AI Video Thumbnails** — Generate preview frames for instant context before playback.
- **Moment Navigation** — Jump directly to relevant timestamps in the source video.

## How It Works

1. **Upload**: Add raw field footage into the app.
2. **Index**: V-Modal processes the video and creates searchable semantic context.
3. **Search**: Query using natural language or visual examples to find precise moments.
4. **Review**: Open the matching timestamp and inspect the result in context.

## Architecture

EcoVision follows a feature-first architecture built with **Flutter** and **GetX**:

- **app/** — Routes, themes, and app-level configuration.
- **core/** — Shared constants, utilities, and extensions.
- **services/** — V-Modal SDK integration and backend helpers.
- **features/** — UI modules for home, upload, search, and video playback.
- **shared/** — Reusable widgets, models, and common components.

## Tech Stack

- **Flutter** — Cross-platform mobile app development
- **GetX** — State management, routing, and dependency injection
- **vmodal_sdk_flutter** — Semantic video indexing and search
- **video_player** — Native video playback experience
- **localstore** — Local persistence for bookmarks and saved observations

## Visual Search Experience

EcoVision supports image-to-video search for identifying specific animals or patterns that are difficult to describe in words.

1. Open the **Search** screen.
2. Tap the **Camera/Photo** icon in the search bar.
3. Choose an image from your gallery.
4. The search engine uses that image to find visually similar appearances in your footage.
5. Review matching timestamps and moments across the archive.

## Global Archive & Smart Filters

Researchers can uncover patterns across large media libraries without manually reviewing every clip.

1. Toggle **Global Archive** to search across the full indexed library.
2. Use semantic chips such as `🐾 Predation` or `💧 Drinking` for fast discovery.
3. Explore the **Discovery Feed** for recent AI-detected wildlife activity.
4. Save significant moments to **Saved Observations** for later reporting.

## Data Persistence & Visual Previews

EcoVision is designed for long-term field research with resilient storage and user-friendly review workflows.

- **Local Persistence** — Save observations locally with `localstore` so research work is retained between sessions.
- **Dynamic AI Thumbnails** — Fetch contextual frames from V-Modal for every result and feed item.
- **Interactive Feed** — Explore moments directly from the home dashboard and jump to the relevant video segment.

## Setup

1. **V-Modal API Key**

   Obtain an API key from V-Modal and configure it with `dart-define`:

   ```bash
   flutter run --dart-define=VMODAL_API_KEY=your_api_key --dart-define=VMODAL_PROJECT_ID=your_project_id
   ```

2. **Install dependencies**

   ```bash
   flutter pub get
   ```

3. **Android configuration**

   Ensure `minSdkVersion` is set to 21 or higher.

## Demo Flow

1. **Home** — View the wildlife intelligence dashboard.
2. **Add** — Upload a new field recording.
3. **Index** — Wait for V-Modal to finish semantic analysis.
4. **Search** — Enter a natural-language query or use the visual reference feature.
5. **Discover** — Tap a result to jump directly to that moment in the footage.

---

<p align="center">
  Built with <strong>EcoVision</strong> and <strong>V-Modal</strong>.
</p>
