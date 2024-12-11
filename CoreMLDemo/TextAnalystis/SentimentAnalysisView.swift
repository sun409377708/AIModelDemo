import SwiftUI
import UIKit

struct SentimentAnalysisView: View {
    @State private var inputText = ""
    @State private var sentiment = ""
    private let analyzer = SentimentAnalyzer()
    @FocusState private var isTextEditorFocused: Bool
    
    // 示例文本数组
    private let sampleTexts = [
        ("😊 很开心", "今天真是太棒了！天气很好，心情愉快，一切都很顺利。"),
        ("😢 很难过", "这次考试考得很差，感觉很沮丧，付出的努力都白费了。"),
        ("😐 中性", "根据天气预报显示，明天的温度是25度，多云转晴。"),
        ("❤️ 表白", "你真是世界上最可爱的人，我好喜欢你！"),
        ("😠 生气", "这个服务太差了，态度很不好，一点都不专业。")
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("情感分析")
                    .font(.largeTitle)
                    .padding(.top)
                
                // 示例文本按钮
                VStack(alignment: .leading, spacing: 10) {
                    Text("示例文本：")
                        .font(.headline)
                        .padding(.leading)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(sampleTexts, id: \.0) { title, text in
                                Button(action: {
                                    inputText = text
                                    sentiment = analyzer.analyzeSentiment(text: text)
                                    hideKeyboard()
                                }) {
                                    Text(title)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(Color.blue.opacity(0.1))
                                        .foregroundColor(.blue)
                                        .cornerRadius(20)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 20)
                                                .stroke(Color.blue, lineWidth: 1)
                                        )
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical, 10)
                
                // 文本输入区域
                VStack(alignment: .leading, spacing: 8) {
                    Text("输入文本：")
                        .font(.headline)
                        .padding(.leading)
                    
                    ZStack(alignment: .topLeading) {
                        if inputText.isEmpty {
                            Text("在这里输入文本...")
                                .foregroundColor(.gray)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                        }
                        
                        TextEditor(text: $inputText)
                            .frame(minHeight: 100)
                            .padding(8)
                            .focused($isTextEditorFocused)
                    }
                    .frame(minHeight: 100)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray, lineWidth: 1)
                    )
                }
                .padding(.horizontal)
                
                // 分析按钮
                Button(action: {
                    sentiment = analyzer.analyzeSentiment(text: inputText)
                    hideKeyboard()
                }) {
                    Text("分析情感")
                        .foregroundColor(.white)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .cornerRadius(8)
                }
                .padding(.vertical, 10)
                
                // 结果显示
                if !sentiment.isEmpty {
                    HStack(spacing: 12) {
                        Text("情感倾向：")
                        Text(sentiment.localizedSentiment)
                            .foregroundColor(sentimentColor)
                            .bold()
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(sentimentColor.opacity(0.1))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(sentimentColor.opacity(0.3), lineWidth: 1)
                    )
                }
            }
            .padding(.bottom, 20)
        }
        .navigationTitle("情感分析")
        .gesture(
            DragGesture()
                .onChanged { _ in
                    hideKeyboard()
                }
        )
        .onTapGesture {
            hideKeyboard()
        }
    }
    
    private var sentimentColor: Color {
        switch sentiment {
        case "Positive":
            return .green
        case "Negative":
            return .red
        default:
            return .gray
        }
    }
    
    private func hideKeyboard() {
        isTextEditorFocused = false
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// 为情感结果添加本地化的扩展
extension String {
    var localizedSentiment: String {
        switch self {
        case "Positive":
            return "积极"
        case "Negative":
            return "消极"
        default:
            return "中性"
        }
    }
}
