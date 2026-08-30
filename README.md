# Smartphone Diabetic Retinopathy Detector

An iOS app that screens for **diabetic retinopathy (DR)** from retinal images
captured on a phone — paired with a robotic-arm jig that standardizes the
capture distance so results stay consistent shot to shot.

🏆 **1st Place — Florida State Science & Engineering Fair (2024)**

## What it does

- Runs a **MobileNetV2** image classifier (exported to **Core ML**) on-device to
  distinguish healthy retinas from DR-affected ones.
- Trained on **500+ smartphone-captured fundus images**, reaching **>90%**
  accuracy on the healthy-vs-DR task.
- Uses **live continuous video detection** so the app classifies frames in real
  time and guides capture, rather than relying on a single perfect still.
- A **robotic-arm jig** holds the phone at a fixed distance from the eye,
  removing the biggest source of variance in low-cost retinal imaging.

The goal: a low-cost, portable screening path for a leading global cause of
blindness — where the diagnostic equipment usually isn't where the patients are.

## Repo layout

```
VideoContinuousImageDetection/       iOS app source (Swift/SwiftUI)
VideoContinuousImageDetection.xcodeproj
Images_2024_0509.mlproj              Create ML training project
Images_2024_0509 1.mlmodel           trained Core ML model
docs/                                poster, logo, screenshots
archive/                             earlier scaffolding, kept for reference
```

## Running it

Open `VideoContinuousImageDetection.xcodeproj` in Xcode and build to a device
with a camera. The Core ML model is bundled; no training step is required to try
the classifier.

## Poster

The full science-fair writeup is in
[`docs/A.Sahai_FY24_RoboticArm_RetinalImage.pdf`](docs/A.Sahai_FY24_RoboticArm_RetinalImage.pdf).
