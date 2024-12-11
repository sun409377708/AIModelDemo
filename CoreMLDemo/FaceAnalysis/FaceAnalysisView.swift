import SwiftUI
import Vision
import PhotosUI

struct FaceAnalysisView: View {
    @StateObject private var analyzer = FaceAnalyzer()
    @State private var showingImagePicker = false
    @State private var inputImage: UIImage?
    @State private var selectedItem: PhotosPickerItem?
    
    var body: some View {
        NavigationView {
            VStack {
                if let image = analyzer.currentImage {
                    Image(uiImage: analyzer.drawFaceAnnotations(on: image))
                        .resizable()
                        .scaledToFit()
                } else {
                    Image(systemName: "face.smiling")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .foregroundColor(.gray)
                        .padding()
                }
                
                if analyzer.isProcessing {
                    ProgressView("分析中...")
                }
                
                if let error = analyzer.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
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
                        showingImagePicker = true
                    } label: {
                        Label("拍照", systemImage: "camera")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(.green)
                }
                .padding(.horizontal)
                
                if !analyzer.detectedFaces.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("检测结果：")
                            .font(.headline)
                            .padding(.top)
                        
                        Text("• 检测到 \(analyzer.detectedFaces.count) 张人脸")
                        
                        ForEach(Array(analyzer.detectedFaces.enumerated()), id: \.offset) { index, face in
                            let emotion = analyzer.determineEmotion(for: face)
                            Text("• 人脸 \(index + 1) 的情绪: \(emotion.rawValue)")
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                    .padding()
                }
            }
            .padding()
            .navigationTitle("人脸分析")
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $inputImage)
            }
            .onChange(of: inputImage) { _ in
                if let image = inputImage {
                    analyzer.analyzeImage(image)
                }
            }
            .onChange(of: selectedItem) { _ in
                if let selectedItem {
                    Task {
                        if let data = try? await selectedItem.loadTransferable(type: Data.self),
                           let image = UIImage(data: data) {
                            await MainActor.run {
                                analyzer.analyzeImage(image)
                            }
                        }
                    }
                }
            }
        }
    }
}

// UIKit 相机视图包装器
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    let sourceType: UIImagePickerController.SourceType = .camera
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = sourceType
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController,
                                 didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            picker.dismiss(animated: true)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

#Preview {
    NavigationView {
        FaceAnalysisView()
    }
}
