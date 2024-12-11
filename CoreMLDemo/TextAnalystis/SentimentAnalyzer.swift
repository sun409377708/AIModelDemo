import CoreML
import NaturalLanguage

class SentimentAnalyzer {
    private var tagger: NLTagger
    
    init() {
        tagger = NLTagger(tagSchemes: [.sentimentScore])
    }
    
    func analyzeSentiment(text: String) -> String {
        tagger.string = text
        
        // Get the sentiment score
        guard let sentiment = tagger.tag(at: text.startIndex, unit: .paragraph, scheme: .sentimentScore).0,
              let score = Double(sentiment.rawValue) else {
            return "Neutral"
        }
        
        print("Debug - Sentiment score:", score) // 添加调试输出
        
        // 调整阈值使判断更准确
        if score < -0.1 {
            return "Negative"
        } else if score > 0.1 {
            return "Positive"
        } else {
            return "Neutral"
        }
    }
}
