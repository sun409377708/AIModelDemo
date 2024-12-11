# CoreML Demo

A comprehensive iOS application showcasing various machine learning capabilities using Apple's CoreML framework. This demo includes multiple features demonstrating the power of on-device machine learning.

## Features

### 1. Face Analysis
- Real-time face detection and analysis
- Facial features recognition
- Expression analysis

### 2. Handwriting Recognition
- Real-time handwriting recognition
- Text conversion from handwritten input
- Support for multiple writing styles

### 3. Pose Estimation
- Real-time human pose detection
- Body keypoint tracking
- Support for multiple poses in frame

### 4. Text Analysis
- Sentiment analysis of text input
- Natural language processing capabilities
- Real-time text classification

## Technical Details

- Built with SwiftUI
- Utilizes CoreML framework
- Supports iOS 14.0+
- Implements various ML models including:
  - CPM model for pose estimation
  - Vision framework for face analysis
  - Custom models for handwriting recognition

## Requirements

- Xcode 12.0+
- iOS 14.0+
- Swift 5.0+
- CocoaPods

## Installation

1. Clone the repository:
```bash
git clone https://github.com/sun409377708/AIModelDemo.git
```

2. Install dependencies using CocoaPods:
```bash
pod install
```

3. Open `CoreMLDemo.xcworkspace` in Xcode

4. Build and run the project

## Project Structure

- `/CoreMLDemo`
  - `/FaceAnalysis` - Face detection and analysis implementation
  - `/HandwritingRecognition` - Handwriting recognition features
  - `/PoseEstimation` - Human pose estimation functionality
  - `/TextAnalysis` - Text sentiment analysis
  - `/Models` - CoreML model files

## Contributing

Feel free to submit issues and enhancement requests!
