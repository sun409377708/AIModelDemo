import Vision
import UIKit

class HandwritingRecognizer: ObservableObject {
    @Published var currentImage: UIImage?
    @Published var recognizedText: String = ""
    @Published var isProcessing = false
    @Published var errorMessage: String?
    
    func recognizeText(in image: UIImage) {
        self.currentImage = image
        self.isProcessing = true
        self.errorMessage = nil
        self.recognizedText = ""
        
        guard let cgImage = image.cgImage else {
            self.errorMessage = "无法处理图片"
            self.isProcessing = false
            return
        }
        
        // 创建文字识别请求
        let request = VNRecognizeTextRequest { [weak self] request, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = "识别失败: \(error.localizedDescription)"
                    self?.isProcessing = false
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    self?.errorMessage = "未检测到文字"
                    self?.isProcessing = false
                    return
                }
                
                // 提取识别到的文字
                let recognizedStrings = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }
                
                // 合并所有识别到的文字
                self?.recognizedText = recognizedStrings.joined(separator: "\n")
                self?.isProcessing = false
            }
        }
        
        // 配置识别请求
        request.recognitionLevel = .accurate // 使用更精确的识别级别
        request.usesLanguageCorrection = true // 使用语言纠正
        request.recognitionLanguages = ["zh-Hans", "en-US"] // 支持中文和英文
        
        // 创建图像处理句柄
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        do {
            try handler.perform([request])
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "识别失败: \(error.localizedDescription)"
                self.isProcessing = false
            }
        }
    }
    
    func drawTextBoxes(on image: UIImage) -> UIImage {
        guard let cgImage = image.cgImage else { return image }
        
        let imageSize = CGSize(width: CGFloat(cgImage.width),
                             height: CGFloat(cgImage.height))
        
        UIGraphicsBeginImageContextWithOptions(imageSize, false, 0.0)
        let context = UIGraphicsGetCurrentContext()
        
        // 绘制原图
        let imageRect = CGRect(origin: .zero, size: imageSize)
        context?.translateBy(x: 0, y: imageSize.height)
        context?.scaleBy(x: 1.0, y: -1.0)
        context?.draw(cgImage, in: imageRect)
        
        // 重新进行文字检测以获取边界框
        let request = VNRecognizeTextRequest { request, _ in
            guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
            
            context?.scaleBy(x: 1.0, y: -1.0)
            context?.translateBy(x: 0, y: -imageSize.height)
            
            for observation in observations {
                // 转换坐标
                let rect = VNImageRectForNormalizedRect(observation.boundingBox,
                                                      Int(imageSize.width),
                                                      Int(imageSize.height))
                
                // 绘制边界框
                context?.setStrokeColor(UIColor.blue.cgColor)
                context?.setLineWidth(2)
                context?.stroke(rect)
                
                // 显示识别到的文字
                if let recognizedText = observation.topCandidates(1).first?.string {
                    let attributes: [NSAttributedString.Key: Any] = [
                        .font: UIFont.systemFont(ofSize: 12),
                        .foregroundColor: UIColor.white,
                        .backgroundColor: UIColor.blue.withAlphaComponent(0.3)
                    ]
                    
                    let textRect = CGRect(x: rect.minX,
                                        y: rect.minY - 20,
                                        width: rect.width,
                                        height: 20)
                    
                    (recognizedText as NSString).draw(in: textRect,
                                                    withAttributes: attributes)
                }
            }
        }
        
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.recognitionLanguages = ["zh-Hans", "en-US"]
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try? handler.perform([request])
        
        let annotatedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return annotatedImage ?? image
    }
}
