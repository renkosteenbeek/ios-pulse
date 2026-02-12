# Pulse

A heart rate zone training app for Apple Watch + iPhone. Train smarter by seeing exactly where your heart rate sits across all five zones in real-time.

## What it does

- **Full-screen zone map** — Your entire screen becomes a vertical zone visualization during workouts. A glowing line tracks your heart rate as it moves between zones.
- **Audio coaching** — Get spoken zone updates so you can train without looking at your wrist.
- **Workout history** — Every session is saved with detailed zone breakdowns, charts, and target zone hit percentages.
- **Personalized zones** — Set your max heart rate by age or manually, and all five zones calculate automatically.

## Why

Because training in the right heart rate zone is one of the simplest ways to get better at running — and it should feel good to do it. No cluttered dashboards, no overwhelming stats mid-run. Just a clear, colorful view of where you are and where you want to be. Glance down, see the line, keep going.

## Screenshots

| Home | Workout | Detail |
|------|---------|--------|
| Zone selector with glow | Full-screen zone bands with HR line | Hero header + ring chart |

## Tech

- SwiftUI + HealthKit
- HKWorkoutSession + HKLiveWorkoutBuilder for real-time heart rate
- SwiftData for workout persistence
- AVSpeechSynthesizer for audio coaching
- iOS 17+

## License

MIT
