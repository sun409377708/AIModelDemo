//
//  ContentView.swift
//  CoreMLDemo
//
//  Created by maoge on 2024/12/10.
//

import SwiftUI

struct MenuItem: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let icon: String
    let destination: AnyView
}

struct ContentView: View {
    let menuItems: [MenuItem] = [
        MenuItem(
            title: "情感分析",
            description: "使用自然语言处理分析文本情感倾向",
            icon: "text.bubble.fill",
            destination: AnyView(SentimentAnalysisView())
        ),
        MenuItem(
            title: "人脸情感分析",
            description: "使用Vision框架进行人脸检测和表情分析",
            icon: "face.smiling.fill",
            destination: AnyView(FaceAnalysisView())
        ),
        MenuItem(
            title: "手写识别",
            description: "使用Vision框架识别手写文字",
            icon: "text.viewfinder",
            destination: AnyView(HandwritingRecognitionView())
        )
        // 在这里可以添加更多功能项
    ]
    
    var body: some View {
        NavigationView {
            List(menuItems) { item in
                NavigationLink(destination: item.destination) {
                    HStack(spacing: 15) {
                        Image(systemName: item.icon)
                            .font(.title2)
                            .foregroundColor(.blue)
                            .frame(width: 35)
                        
                        VStack(alignment: .leading, spacing: 5) {
                            Text(item.title)
                                .font(.headline)
                            Text(item.description)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .lineLimit(2)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Core ML 演示")
        }
    }
}

// Preview {
//     ContentView()
// }
