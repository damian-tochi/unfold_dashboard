# unfold_dashboard

A simple flutter dashboard for visualizing health and activity metrics (e.g., HRV, RHR, Steps) with annotations, rolling statistics, and journal insights — all backed by **Riverpod state management** and **fl_chart** for smooth, interactive time-series visualization.
This README covers setup, development, testing, and project layout.

## Preview

- https://unfold-dashboard.vercel.app/ -


## Features

- Multi-series charts: HRV, RHR, and Steps
- Pan/zoom with synced crosshair tooltips
- Shared hover/tap highlighting across charts
- Journal annotations (mood, notes, events)
- 7-day rolling mean bands for HRV with ±1σ deviation
- Adaptive downsampling (decimation) for fast rendering on large data
- Clean architecture using **Riverpod**, **StateNotifier**, and modular data services
- Light and dark themes
- Responsive layout for mobile and desktop
- Unit and widget tests for core functionality


## Prerequisites

- Flutter SDK (stable)
- Dart (bundled with Flutter)
- Android Studio / Xcode for device emulators
- macOS (development host)


## Decimation (Downsampling) Explained

To ensure smooth performance when visualizing large datasets, this dashboard employs a decimation algorithm that reduces the number of data points rendered on the charts without significantly compromising visual fidelity. The decimation process works as follows: 
1. **Data Segmentation**: The time-series data is divided into segments based on the current zoom level and viewport size. Each segment represents a range of data points that will be condensed into a single representative point.
2. **Point Selection**: For each segment, the algorithm selects key points that capture the overall trend and important features of the data. This typically includes the minimum, maximum, and average values within the segment.
3. **Rendering**: The selected points from each segment are then used to render the chart, significantly reducing the total number of points drawn while maintaining the integrity of the visual representation. This approach allows for efficient rendering and interaction, even with large datasets, ensuring a responsive user experience.  


## Performance Notes

- The decimation algorithm is optimized for real-time interaction, allowing users to pan and zoom through the data seamlessly.
- The algorithm dynamically adjusts the level of decimation based on the zoom level, providing more detail when zoomed in and more aggressive downsampling when zoomed out.
- This technique is particularly effective for time-series data, where trends and patterns are more important than individual data points.
- By leveraging decimation, the dashboard can handle large datasets efficiently, ensuring that users can explore their health and activity metrics without performance degradation.
- Rolling mean ± standard deviation visualized as shaded areas around the HRV line chart for quick trend analysis.
- Vertical lines mark journal entries; tapping reveals mood/note


## Getting started

1. Clone the repo:
   - `git clone <repository-url>`
2. Open the project:
   - `cd unfold_dashboard`
3. Install dependencies:
   - `flutter pub get`

## Running

- Run on an attached device or emulator:
  - `flutter run`
- Run a release build:
  - `flutter run --release`

## Testing

- Run unit and widget tests:
  - `flutter test`

## Formatting & Analysis

- Format code:
  - `dart format .`
- Static analysis:
  - `flutter analyze`

## Project structure

- `lib/` — application source code
  - `lib/main.dart` — app entry point
  - `lib/models/` — data models
  - `lib/services/` — data fetching and processing
  - `lib/state/` — Riverpod state management
  - `lib/widgets/` — reusable UI components
  - `lib/screens/` — app screens and layouts
  - `lib/providers/` — Riverpod providers
- `test/` — unit and widget tests
- `assets/` — images, fonts, etc.
- `web/` — web platform-specific project files
- `pubspec.yaml` — dependencies and metadata
- `README.md` — this file

## Contributing

- Fork the repository
- Create a feature branch: `git checkout -b feat/your-feature`
- Commit changes and open a Pull Request
- Ensure tests pass and code is formatted

## Troubleshooting

- If dependencies fail: `flutter pub get`
- If build fails: run `flutter clean` then `flutter pub get`

## Contact

- GitHub: `damian-tochi`