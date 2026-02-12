# Pulse

A heart rate zone training app for iPhone. Works with Apple Watch and AirPods Pro 3 for real-time heart rate monitoring. Train smarter by seeing exactly where your heart rate sits across all five zones.

## What it does

- **Full-screen zone map** — Your entire screen becomes a vertical zone visualization during workouts. A glowing line tracks your heart rate as it moves between zones.
- **Apple Watch & AirPods Pro 3** — Real-time heart rate via Apple Watch or AirPods Pro 3 built-in heart rate sensor.
- **Audio coaching** — Get spoken zone updates so you can train without looking at your phone.
- **Workout history** — Every session is saved with detailed zone breakdowns, charts, and target zone hit percentages.
- **Personalized zones** — Set your max heart rate by age or manually, and all five zones calculate automatically.

## Why

Because training in the right heart rate zone is one of the simplest ways to get better at running — and it should feel good to do it. No cluttered dashboards, no overwhelming stats mid-run. Just a clear, colorful view of where you are and where you want to be. Glance down, see the line, keep going.

## Tech

- SwiftUI + HealthKit
- HKWorkoutSession + HKLiveWorkoutBuilder for real-time heart rate
- Apple Watch + AirPods Pro 3 heart rate via HealthKit
- SwiftData for workout persistence
- AVSpeechSynthesizer for audio coaching
- iOS 17+

## License

MIT
