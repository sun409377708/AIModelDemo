import SwiftUI
import PhotosUI

struct HandwritingRecognitionView: View {
    @StateObject private var recognizer = HandwritingRecognizer()
    @State private var showingImagePicker = false
    @State private var inputImage: UIImage?
    @State private var selectedItem: PhotosPickerItem?
    @State private var showingShareSheet = false
    
    var body: some View {
        NavigationView {
            VStack {
                if let image = recognizer.currentImage {
                    Image(uiImage: recognizer.drawTextBoxes(on: image))
                        .resizable()
                        .scaledToFit()
                        .padding()
                } else {
                    Image(systemName: "text.viewfinder")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .foregroundColor(.gray)
                        .padding()
                }
                
                if recognizer.isProcessing {
                    ProgressView("识别中...")
                }
                
                if let error = recognizer.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                }
                
                if !recognizer.recognizedText.isEmpty {
                    VStack(alignment: .leading) {
                        HStack {
                            Text("识别结果")
                                .font(.headline)
                            
                            Spacer()
                            
                            Button(action: {
                                showingShareSheet = true
                            }) {
                                Image(systemName: "square.and.arrow.up")
                            }
                        }
                        
                        ScrollView {
                            Text(recognizer.recognizedText)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(maxHeight: 200)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                    }
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
            }
            .navigationTitle("手写识别")
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $inputImage)
            }
            .onChange(of: inputImage) { _ in
                if let image = inputImage {
                    recognizer.recognizeText(in: image)
                }
            }
            .onChange(of: selectedItem) { _ in
                if let selectedItem {
                    Task {
                        if let data = try? await selectedItem.loadTransferable(type: Data.self),
                           let image = UIImage(data: data) {
                            await MainActor.run {
                                recognizer.recognizeText(in: image)
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                if #available(iOS 16.0, *) {
                    ShareSheet(items: [recognizer.recognizedText])
                } else {
                    ActivityViewController(activityItems: [recognizer.recognizedText])
                }
            }
        }
    }
}

// iOS 16 之前的分享sheet
struct ActivityViewController: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems,
                               applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController,
                              context: Context) {}
}

// iOS 16 及以后的分享sheet
@available(iOS 16.0, *)
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIViewController {
        let activityVC = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
        return activityVC
    }
    
    func updateUIViewController(_ uiViewController: UIViewController,
                              context: Context) {}
}
