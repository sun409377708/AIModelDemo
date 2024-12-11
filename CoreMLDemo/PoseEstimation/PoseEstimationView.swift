import SwiftUI
import PhotosUI

struct PoseEstimationView: View {
    @StateObject private var estimator = PoseEstimator()
    @State private var showingImagePicker = false
    @State private var inputImage: UIImage?
    @State private var selectedItem: PhotosPickerItem?
    @State private var isCamera = false
    
    var body: some View {
        VStack {
            if let image = estimator.currentImage {
                Image(uiImage: estimator.drawPoseOverlay(on: image))
                    .resizable()
                    .scaledToFit()
                    .padding()
            } else {
                Image(systemName: "figure.stand")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.gray)
                    .padding()
            }
            
            if estimator.isProcessing {
                ProgressView("处理中...")
            }
            
            if let error = estimator.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .padding()
            }
            
            if !estimator.keyPoints.isEmpty {
                VStack(alignment: .leading) {
                    Text("检测到的动作：\(estimator.currentAction.rawValue)")
                        .font(.headline)
                        .padding()
                    
                    Text("置信度：\(String(format: "%.2f", estimator.keyPoints.reduce(0) { $0 + $1.confidence } / Float(estimator.keyPoints.count)))")
                        .font(.subheadline)
                        .padding(.horizontal)
                }
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .padding()
            }
            
            HStack(spacing: 20) {
                PhotosPicker(selection: $selectedItem,
                           matching: .images) {
                    Label("从相册选择", systemImage: "photo.on.rectangle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.blue)
                
                Button {
                    isCamera = true
                    showingImagePicker = true
                } label: {
                    Label("拍照", systemImage: "camera")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.green)
            }
            .padding(.horizontal)
        }
        .navigationTitle("姿态估计")
        .sheet(isPresented: $showingImagePicker) {
            if isCamera {
                ImagePicker(image: $inputImage)
            }
        }
        .onChange(of: inputImage) { _ in
            if let image = inputImage {
                estimator.estimatePose(in: image)
            }
        }
        .onChange(of: selectedItem) { _ in
            if let selectedItem {
                Task {
                    if let data = try? await selectedItem.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        await MainActor.run {
                            estimator.estimatePose(in: image)
                        }
                    }
                }
            }
        }
    }
}
