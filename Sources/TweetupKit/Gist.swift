import Foundation
import PromiseK

internal struct Gist {
    static func createGist(description: String, code: Code, accessToken: String) -> Promise<() throws -> String> {
        let session = URLSession(configuration: .ephemeral, delegate: nil, delegateQueue: .current)
        var request = URLRequest(url: URL(string: "https://api.github.com/gists")!)
        request.httpMethod = "POST"
        request.addValue("token \(accessToken)", forHTTPHeaderField: "Authorization")
        let files: [String: Any] = [
            code.fileName: [
                "content": code.body
            ]
        ]
        let json: [String: Any] = [
            "description": description,
            "public": false,
            "files": files
        ]
        let data = try! JSONSerialization.data(withJSONObject: json)
        return Promise { fulfill in
            let task = session.uploadTask(with: request, from: data) { responseData, response, error in
                if let error = error { fulfill { throw error }; return }
                guard let response = response as? HTTPURLResponse else {
                    fatalError("Never reaches here.")
                }
                let responseJson: [String: Any] = try! JSONSerialization.jsonObject(with: responseData!) as! [String: Any] // never fails
                guard response.statusCode == 201 else {
                    fulfill { throw APIError(response: response, json: responseJson) }
                    return
                }
                guard let id = responseJson["id"] as? String else {
                    fatalError("Never reaches here.")
                }
                
                fulfill { id }
            }
            task.resume()
        }
    }
}
