import Foundation

internal struct Gist {
    static func createGist(description: String, code: Code, accessToken: String, callback: @escaping (() throws -> URL) -> ()) {
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
                guard let urlString = responseJson["html_url"] as? String else {
                    throw GistError(json: responseJson)
                }
                
                return URL(string: urlString)!
            }
        }
        task.resume()
    }
}

internal struct GistError: Error {
    let json: Any
}
