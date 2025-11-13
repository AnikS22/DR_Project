//
//  ContentView.swift
//  VideoContinuousImageDetection
//
//  Early Detection of Diabetic Retinopathy
//  Created by Danika Gupta on 3/12/24.
//

import AVFoundation
import SwiftUI

/// Manages video capture and real-time image classification for diabetic retinopathy detection
class VideoCapture: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    // MARK: - Properties
    
    var captureSession: AVCaptureSession?
    let videoOutput = AVCaptureVideoDataOutput()
    let sessionQueue = DispatchQueue(label: "sessionQueue")
    
    /// Core ML model for diabetic retinopathy classification
    /// Alternative models available: DRDetection_1(), DR_Image_Classifer_1()
    let model = Images_2024_0509_1()
    
    @Published var processedText: String = ""
    @Published var isAnalyzing: Bool = false
    
    /// Maps model predictions to user-friendly diagnostic messages
    let displayMap: [String: String] = [
        "Zoom_In": "Please move closer for better image quality",
        "DR_1": "Early Stage DR Detected - Stage 1",
        "DR_2": "Moderate DR Detected - Stage 2",
        "DR_3": "Severe DR Detected - Stage 3",
        "DR_4": "Proliferative DR Detected - Stage 4",
        "DR_Healthy": "No Diabetic Retinopathy Detected"
    ]
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        self.setupCaptureSession()
    }
    
    // MARK: - Camera Setup
    
    /// Configures the camera session for video capture
    private func setupCaptureSession() {
        let session = AVCaptureSession()
        session.beginConfiguration()
        
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice),
              session.canAddInput(videoDeviceInput) else {
            print("Error: Unable to access camera")
            return
        }
        
        session.addInput(videoDeviceInput)
        
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
            videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
            videoOutput.alwaysDiscardsLateVideoFrames = true
            videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        }
        
        session.commitConfiguration()
        self.captureSession = session
    }
    
    // MARK: - Session Control
    
    func startSession() {
        sessionQueue.async {
            self.captureSession?.startRunning()
            DispatchQueue.main.async {
                self.isAnalyzing = true
            }
        }
    }
    
    func stopSession() {
        sessionQueue.async {
            self.captureSession?.stopRunning()
            DispatchQueue.main.async {
                self.isAnalyzing = false
                self.processedText = ""
            }
        }
    }
    
    // MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
    
    /// Processes each video frame for real-time classification
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        do {
            let prediction = try self.model.prediction(image: pixelBuffer).target
            DispatchQueue.main.async {
                let visiblePrediction = self.displayMap[prediction] ?? prediction
                self.processedText = visiblePrediction
            }
        } catch {
            DispatchQueue.main.async {
                print("Error processing frame: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Camera Preview

/// SwiftUI wrapper for camera preview layer
struct CameraPreview: UIViewRepresentable {
    @ObservedObject var videoCapture: VideoCapture
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: CGRect(
            x: 0,
            y: 0,
            width: UIScreen.main.bounds.width,
            height: UIScreen.main.bounds.height * 0.70
        ))
        
        guard let captureSession = videoCapture.captureSession else {
            return view
        }
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // Update preview layer frame if needed
        if let previewLayer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
            previewLayer.frame = uiView.bounds
        }
    }
}

// MARK: - Main View

struct ContentView: View {
    @ObservedObject var videoCapture = VideoCapture()
    @State private var isSessionActive = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 8) {
                Text("Diabetic Retinopathy")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.primary)
                
                Text("Early Detection System")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(.top, 20)
            
            // Diagnostic Result
            VStack(spacing: 8) {
                if !videoCapture.processedText.isEmpty {
                    Text(videoCapture.processedText)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(diagnosticColor(for: videoCapture.processedText))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                } else if isSessionActive {
                    Text("Analyzing...")
                        .font(.system(size: 18))
                        .foregroundColor(.secondary)
                } else {
                    Text("Tap Start to begin analysis")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                }
            }
            .frame(minHeight: 60)
            .padding()
            
            // Camera Preview
            CameraPreview(videoCapture: videoCapture)
                .cornerRadius(12)
                .padding(.horizontal)
            
            Spacer()
            
            // Control Button
            Button(action: {
                if isSessionActive {
                    videoCapture.stopSession()
                } else {
                    videoCapture.startSession()
                }
                isSessionActive.toggle()
            }) {
                HStack {
                    Image(systemName: isSessionActive ? "stop.circle.fill" : "play.circle.fill")
                        .font(.system(size: 24))
                    Text(isSessionActive ? "Stop Analysis" : "Start Analysis")
                        .font(.system(size: 18, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(isSessionActive ? Color.red : Color.blue)
                .cornerRadius(12)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 30)
        }
        .background(Color(.systemBackground))
    }
    
    /// Returns appropriate color based on diagnostic result
    private func diagnosticColor(for text: String) -> Color {
        if text.contains("No Diabetic Retinopathy") {
            return .green
        } else if text.contains("Early Stage") {
            return .orange
        } else if text.contains("Detected") {
            return .red
        } else {
            return .blue
        }
    }
}

