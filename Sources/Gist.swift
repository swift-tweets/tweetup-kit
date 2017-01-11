import Foundation

internal struct Gist {
    static func createGist(description: String, code: Code, accessToken: String, callback: @escaping (() throws -> String) -> ()) {
        let session = URLSession(configuration: .ephemeral)
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
        let task = session.uploadTask(with: request, from: data) { responseData, response, error in
            callback {
                if let error = error { throw error }
                
                let responseJson: [String: Any] = try! JSONSerialization.jsonObject(with: responseData!) as! [String: Any] // never fails
                guard let id = responseJson["id"] as? String else {
                    throw GistError(json: responseJson)
                }
                
                return id
            }
        }
        task.resume()
    }
}

internal struct GistError: Error {
    let json: Any
}
