import Foundation
import Vision
import UIKit

class FaceAnalyzer: ObservableObject {
    @Published var currentImage: UIImage?
    @Published var detectedFaces: [VNFaceObservation] = []
    @Published var isProcessing = false
    @Published var errorMessage: String?
    
    enum Emotion: String {
        case happy = "😊"
        case sad = "😢"
        case angry = "😠"
        case neutral = "😐"
        case surprise = "😲"
    }
    
    func analyzeImage(_ image: UIImage) {
        self.currentImage = image
        self.isProcessing = true
        self.errorMessage = nil
        self.detectedFaces = []
        
        guard let cgImage = image.cgImage else {
            self.errorMessage = "无法处理图片"
            self.isProcessing = false
            return
        }
        
        let request = VNDetectFaceLandmarksRequest { [weak self] request, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = "分析失败: \(error.localizedDescription)"
                    self?.isProcessing = false
                    return
                }
                
                guard let observations = request.results as? [VNFaceObservation] else {
                    self?.errorMessage = "未检测到人脸"
                    self?.isProcessing = false
                    return
                }
                
                self?.detectedFaces = observations
                self?.isProcessing = false
            }
        }
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([request])
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "分析失败: \(error.localizedDescription)"
                self.isProcessing = false
            }
        }
    }
    
    func determineEmotion(for face: VNFaceObservation) -> Emotion {
        guard let landmarks = face.landmarks else {
            return .neutral
        }
        
        if let mouth = landmarks.outerLips?.normalizedPoints,
           let leftBrow = landmarks.leftEyebrow?.normalizedPoints,
           let rightBrow = landmarks.rightEyebrow?.normalizedPoints,
           let leftEye = landmarks.leftEye?.normalizedPoints,
           let rightEye = landmarks.rightEye?.normalizedPoints {
            
            // 计算嘴部特征
            let mouthHeight = mouth.map { $0.y }.max()! - mouth.map { $0.y }.min()!
            let mouthWidth = mouth.map { $0.x }.max()! - mouth.map { $0.x }.min()!
            let mouthAspectRatio = mouthHeight / mouthWidth
            
            // 计算嘴角弧度
            let mouthCorners = [mouth[0], mouth[mouth.count/2]] 
            let mouthAngle = atan2(mouthCorners[1].y - mouthCorners[0].y,
                                 mouthCorners[1].x - mouthCorners[0].x)
            
            // 计算眉毛高度
            let leftBrowHeight = leftBrow.map { $0.y }.reduce(0, +) / Double(leftBrow.count)
            let rightBrowHeight = rightBrow.map { $0.y }.reduce(0, +) / Double(rightBrow.count)
            let avgBrowHeight = (leftBrowHeight + rightBrowHeight) / 2
            
            // 计算眼睛开合度
            let leftEyeHeight = leftEye.map { $0.y }.max()! - leftEye.map { $0.y }.min()!
            let rightEyeHeight = rightEye.map { $0.y }.max()! - rightEye.map { $0.y }.min()!
            let avgEyeHeight = (leftEyeHeight + rightEyeHeight) / 2
            
            // 微笑判断：嘴角上扬，适当的宽高比
            if mouthAngle > 0.05 && mouthAspectRatio < 0.35 && mouthWidth > 0.3 {
                return .happy
            }
            
            // 悲伤判断：嘴角下垂，眉毛低垂
            if mouthAngle < -0.05 && avgBrowHeight < 0.65 && mouthWidth < 0.35 {
                return .sad
            }
            
            // 生气判断：眉毛低垂，嘴巴紧闭
            if avgBrowHeight < 0.55 && mouthHeight < 0.15 && mouthWidth < 0.3 {
                return .angry
            }
            
            // 惊讶判断：眉毛上扬，嘴巴张开，眼睛睁大
            if avgBrowHeight > 0.65 && mouthHeight > 0.25 && avgEyeHeight > 0.2 {
                return .surprise
            }
        }
        
        return .neutral
    }
    
    func drawFaceAnnotations(on image: UIImage) -> UIImage {
        guard let cgImage = image.cgImage else { return image }
        
        let imageSize = CGSize(width: CGFloat(cgImage.width),
                             height: CGFloat(cgImage.height))
        
        UIGraphicsBeginImageContextWithOptions(imageSize, false, 0.0)
        let context = UIGraphicsGetCurrentContext()
        
        let imageRect = CGRect(origin: .zero, size: imageSize)
        context?.translateBy(x: 0, y: imageSize.height)
        context?.scaleBy(x: 1.0, y: -1.0)
        context?.draw(cgImage, in: imageRect)
        context?.scaleBy(x: 1.0, y: -1.0)
        context?.translateBy(x: 0, y: -imageSize.height)
        
        for face in detectedFaces {
            let faceRect = VNImageRectForNormalizedRect(face.boundingBox,
                                                       Int(imageSize.width),
                                                       Int(imageSize.height))
            // 更精确地调整人脸框的位置
            let adjustedFaceRect = CGRect(x: faceRect.minX,
                                        y: faceRect.minY - faceRect.height * 0.15, // 调整为向上移动15%的高度
                                        width: faceRect.width,
                                        height: faceRect.height * 0.95) // 稍微减小高度以使框更贴合面部
            
            context?.setStrokeColor(UIColor.green.cgColor)
            context?.setLineWidth(3)
            context?.addRect(adjustedFaceRect)
            context?.strokePath()
            
            let emotion = determineEmotion(for: face)
            let emoji = emotion.rawValue
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: adjustedFaceRect.width * 0.3),
                .foregroundColor: UIColor.white
            ]
            let emojiSize = (emoji as NSString).size(withAttributes: attributes)
            let emojiPoint = CGPoint(x: adjustedFaceRect.minX + (adjustedFaceRect.width - emojiSize.width) / 2,
                                   y: adjustedFaceRect.minY - emojiSize.height - 2) // 将emoji稍微靠近框
            
            (emoji as NSString).draw(at: emojiPoint, withAttributes: attributes)
        }
        
        let annotatedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return annotatedImage ?? image
    }
}
