//
//  AIStartHelper.swift
//  DockCat
//
//  Created by apricity_peng on 17/5/2026.
//

import Foundation

struct MicroTaskSuggestion: Codable {
    let microTask: String
    let encouragement: String
    let minutes: Int
}

@MainActor
final class AIStartHelper {
    
    static let shared = AIStartHelper()
    
    private init() {}
    
    private var apiKey: String {
        UserDefaults.standard.string(forKey: "gemini_api_key") ?? ""
    }
    
    func generateMicroTask(from task: String) async -> MicroTaskSuggestion {
        let trimmedTask = task.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedTask.isEmpty else {
            return MicroTaskSuggestion(
                microTask: "先写下你现在最想推进的一件小事。",
                encouragement: "不用想完整计划，我们先找到入口就好。",
                minutes: 5
            )
        }
        
        do {
            return try await requestMicroTask(task: trimmedTask)
        } catch {
            print("========== ERROR ==========")
            print(error)
            print("==================================")

            return MicroTaskSuggestion(
                microTask: "先打开和「\(trimmedTask)」有关的文件、页面或工具，只做打开这一步。",
                encouragement: "AI 暂时没连上，但我们仍然可以先迈出最小的一步。",
                minutes: 5
            )
        }
    }
    
    private func requestMicroTask(task: String) async throws -> MicroTaskSuggestion {
        let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-3.5-flash:generateContent?key=\(apiKey)")!
        
        let prompt = """
        你是一个 ADHD 友好的启动助手。
        用户会输入一个想做但难以开始的任务。
        请把它拆成一个“最小启动单位”。

        要求：
        1. 不超过10分钟，但是也不要太短，最好是能让用户开始的同时，沉浸式干10分钟的那种
        2. 必须是一个具体动作
        3. 不要要求用户思考太多
        4. 语气温柔，不要施压
        5. 只输出 JSON，不要输出其他文字：
        {"microTask":"...","encouragement":"...","minutes":5}

        用户任务：\(task)
        """
        
        let body: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ]
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            print("========== GEMINI STATUS ==========")
            print(httpResponse.statusCode)
        }
        
        let raw = String(data: data, encoding: .utf8) ?? ""
        
        print("========== GEMINI RAW RESPONSE ==========")
        print(raw)
        print("========================================")
        
        guard let jsonText = extractGeminiText(from: raw),
              let jsonData = jsonText.data(using: .utf8) else {
            throw NSError(domain: "AIStartHelper", code: 1)
        }
        
        return try JSONDecoder().decode(MicroTaskSuggestion.self, from: jsonData)
    }
    
    private func extractGeminiText(from raw: String) -> String? {
        guard let data = raw.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = object["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first,
              let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let firstPart = parts.first,
              let text = firstPart["text"] as? String else {
            return nil
        }
        
        return text
    }
        

}
