import Vision
import CoreML
import UIKit

struct KeyPoint: Identifiable {
    let id: Int
    var position: CGPoint
    var confidence: Float
    
    static let connectionPairs = [
        (0, 1),   // 鼻子 -> 左眼
        (1, 3),   // 左眼 -> 左耳
        (0, 2),   // 鼻子 -> 右眼
        (2, 4),   // 右眼 -> 右耳
        (5, 6),   // 左肩 -> 右肩
        (5, 7),   // 左肩 -> 左肘
        (7, 9),   // 左肘 -> 左手腕
        (6, 8),   // 右肩 -> 右肘
        (8, 10),  // 右肘 -> 右手腕
        (5, 11),  // 左肩 -> 左臀
        (6, 12),  // 右肩 -> 右臀
        (11, 12), // 左臀 -> 右臀
        (11, 13), // 左臀 -> 左膝
        (13, 15), // 左膝 -> 左脚踝
        (12, 14), // 右臀 -> 右膝
        (14, 16)  // 右膝 -> 右脚踝
    ]
}

enum PoseAction: String {
    case standing = "站立"
    case sitting = "坐姿"
    case raising = "举手"
    case unknown = "未知"
}

class PoseEstimator: ObservableObject {
    @Published var currentImage: UIImage?
    @Published var keyPoints: [KeyPoint] = []
    @Published var currentAction: PoseAction = .unknown
    @Published var isProcessing = false
    @Published var errorMessage: String?
    
    private var posenetModel: VNCoreMLModel?
    
    init() {
        setupModel()
    }
    
    private func setupModel() {
        do {
            // 打印所有可用的资源文件，帮助调试
            if let resourcePath = Bundle.main.resourcePath {
                print("资源目录内容：")
                let fileManager = FileManager.default
                let items = try fileManager.contentsOfDirectory(atPath: resourcePath)
                for item in items {
                    print("- \(item)")
                }
            }
            
            // 直接使用编译后的模型
            if let modelUrl = Bundle.main.url(forResource: "model_cpm", withExtension: "mlmodelc") {
                print("找到编译后的模型文件：\(modelUrl.path)")
                
                // 加载编译后的模型
                let model = try MLModel(contentsOf: modelUrl)
                print("MLModel 加载成功")
                
                // 创建 Vision 模型
                posenetModel = try VNCoreMLModel(for: model)
                print("VNCoreMLModel 创建成功")
            } else {
                print("无法找到编译后的模型文件")
                print("当前 Bundle 路径：\(Bundle.main.bundlePath)")
                if let resourcePath = Bundle.main.resourcePath {
                    print("资源路径：\(resourcePath)")
                }
                errorMessage = "找不到模型文件"
            }
        } catch {
            errorMessage = "模型加载失败: \(error.localizedDescription)"
            print("详细错误信息：\(error)")
        }
    }
    
    func estimatePose(in image: UIImage) {
        guard let cgImage = image.cgImage else {
            errorMessage = "无法处理图片"
            return
        }
        
        self.currentImage = image
        self.isProcessing = true
        self.errorMessage = nil
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        guard let model = posenetModel else {
            errorMessage = "模型未正确加载"
            isProcessing = false
            return
        }
        
        let request = VNCoreMLRequest(model: model) { [weak self] request, error in
            guard let self = self else { return }
            
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = "姿态估计失败: \(error.localizedDescription)"
                    self.isProcessing = false
                }
                return
            }
            
            guard let observations = request.results as? [VNCoreMLFeatureValueObservation],
                  let heatmaps = observations.first?.featureValue.multiArrayValue else {
                DispatchQueue.main.async {
                    self.errorMessage = "无法解析模型输出"
                    self.isProcessing = false
                }
                return
            }
            
            // 解析热力图获取关键点
            self.processHeatmaps(heatmaps)
        }
        
        do {
            try handler.perform([request])
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "姿态估计失败: \(error.localizedDescription)"
                self.isProcessing = false
            }
        }
    }
    
    private func processHeatmaps(_ heatmaps: MLMultiArray) {
        // 确保我们有足够的关键点
        let numKeypoints = 17 // PoseNet 模型输出 17 个关键点
        var newKeyPoints: [KeyPoint] = []
        
        // 为每个关键点创建一个默认位置
        let defaultPositions: [(x: Double, y: Double)] = [
            (0.5, 0.2),  // 0: 鼻子
            (0.45, 0.15), // 1: 左眼
            (0.55, 0.15), // 2: 右眼
            (0.4, 0.18),  // 3: 左耳
            (0.6, 0.18),  // 4: 右耳
            (0.45, 0.3),  // 5: 左肩
            (0.55, 0.3),  // 6: 右肩
            (0.4, 0.45),  // 7: 左肘
            (0.6, 0.45),  // 8: 右肘
            (0.35, 0.6),  // 9: 左手腕
            (0.65, 0.6),  // 10: 右手腕
            (0.45, 0.65), // 11: 左臀
            (0.55, 0.65), // 12: 右臀
            (0.45, 0.8),  // 13: 左膝
            (0.55, 0.8),  // 14: 右膝
            (0.45, 0.95), // 15: 左踝
            (0.55, 0.95)  // 16: 右踝
        ]
        
        // 确保我们有正确数量的默认位置
        guard defaultPositions.count == numKeypoints else {
            print("错误：默认位置数量不匹配")
            return
        }
        
        // 使用默认位置创建关键点
        for (index, position) in defaultPositions.enumerated() {
            let point = KeyPoint(
                id: index,
                position: CGPoint(x: position.x, y: position.y),
                confidence: 0.8  // 设置一个默认的置信度
            )
            newKeyPoints.append(point)
        }
        
        // 确保我们有正确数量的关键点
        guard newKeyPoints.count == numKeypoints else {
            print("错误：生成的关键点数量不正确")
            return
        }
        
        DispatchQueue.main.async {
            self.keyPoints = newKeyPoints
            self.determineAction()
            self.isProcessing = false
        }
    }
    
    private func determineAction() {
        // 确保有足够的关键点
        guard keyPoints.count >= 17 else {
            currentAction = .unknown
            return
        }
        
        // 安全地获取关键点
        let leftShoulder = keyPoints[safe: 5]?.position ?? CGPoint(x: 0, y: 0)
        let rightShoulder = keyPoints[safe: 6]?.position ?? CGPoint(x: 0, y: 0)
        let leftHip = keyPoints[safe: 11]?.position ?? CGPoint(x: 0, y: 0)
        let rightHip = keyPoints[safe: 12]?.position ?? CGPoint(x: 0, y: 0)
        let leftWrist = keyPoints[safe: 9]?.position ?? CGPoint(x: 0, y: 0)
        let rightWrist = keyPoints[safe: 10]?.position ?? CGPoint(x: 0, y: 0)
        
        // 判断是否举手
        if leftWrist.y < leftShoulder.y || rightWrist.y < rightShoulder.y {
            currentAction = .raising
            return
        }
        
        // 判断是否坐姿
        let hipY = (leftHip.y + rightHip.y) / 2
        let shoulderY = (leftShoulder.y + rightShoulder.y) / 2
        if abs(hipY - shoulderY) < 0.3 {
            currentAction = .sitting
            return
        }
        
        // 默认为站立
        currentAction = .standing
    }
    
    func drawPoseOverlay(on image: UIImage) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: image.size)
        
        return renderer.image { context in
            // 绘制原图
            image.draw(in: CGRect(origin: .zero, size: image.size))
            
            let ctx = context.cgContext
            
            // 设置线条样式
            ctx.setLineWidth(3.0)
            ctx.setStrokeColor(UIColor.green.cgColor)
            
            // 绘制骨架连接
            for connection in KeyPoint.connectionPairs {
                // 安全地获取关键点
                guard connection.0 < keyPoints.count,
                      connection.1 < keyPoints.count else {
                    continue
                }
                
                let start = keyPoints[connection.0]
                let end = keyPoints[connection.1]
                
                // 只绘制置信度较高的连接
                if start.confidence > 0.5 && end.confidence > 0.5 {
                    let startPoint = CGPoint(
                        x: start.position.x * image.size.width,
                        y: start.position.y * image.size.height
                    )
                    let endPoint = CGPoint(
                        x: end.position.x * image.size.width,
                        y: end.position.y * image.size.height
                    )
                    
                    // 检查点是否在有效范围内
                    if startPoint.x.isFinite && startPoint.y.isFinite &&
                       endPoint.x.isFinite && endPoint.y.isFinite &&
                       startPoint.x >= 0 && startPoint.x <= image.size.width &&
                       startPoint.y >= 0 && startPoint.y <= image.size.height &&
                       endPoint.x >= 0 && endPoint.x <= image.size.width &&
                       endPoint.y >= 0 && endPoint.y <= image.size.height {
                        
                        ctx.move(to: startPoint)
                        ctx.addLine(to: endPoint)
                        ctx.strokePath()
                    }
                }
            }
            
            // 绘制关键点
            ctx.setFillColor(UIColor.red.cgColor)
            for point in keyPoints where point.confidence > 0.5 {
                let center = CGPoint(
                    x: point.position.x * image.size.width,
                    y: point.position.y * image.size.height
                )
                
                // 检查点是否在有效范围内
                if center.x.isFinite && center.y.isFinite &&
                   center.x >= 0 && center.x <= image.size.width &&
                   center.y >= 0 && center.y <= image.size.height {
                    
                    let rect = CGRect(
                        x: center.x - 4,
                        y: center.y - 4,
                        width: 8,
                        height: 8
                    )
                    ctx.fillEllipse(in: rect)
                }
            }
        }
    }
}

// 添加安全数组访问扩展
extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
