import Foundation

extension URL: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self = URL(string: value)!
    }
}

extension URL {

    var removingLastSlash: URL {
        if let lastChar = self.absoluteString.last, lastChar == "/" {
            let value = String(self.absoluteString.dropLast())
            return URL(string: value) ?? self
        }
        return self
    }

    func appendingQuery(_ query: [String: String]) -> URL {
        let url = self
        guard var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            assertionFailure("Could not create urlComponents")
            return url
        }

        var queryItems = urlComponents.queryItems ?? []
        query.keys.forEach {key in
            queryItems.append(URLQueryItem(name: key, value: query[key]))
        }
        urlComponents.queryItems = queryItems
        guard let newURL = urlComponents.url else {
            return url
        }
        return newURL
    }

    func appending(_ path: String) -> URL {
        if path.isEmpty {
            return self
        }
        var new = self
        new.appendPathComponent(path)
        return new
    }
}

extension URLRequest {
    mutating func addWWWFormHTTPBody(parameter: [String: String]) {
        let all = parameter.map { "\($0.key.urlEncoded)=\($0.value.urlEncoded)" }
        guard let data = all.joined(separator: "&").data(using: .utf8) else { return }

        setValue("*/*", forHTTPHeaderField: "Accept")
        setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        setValue("\(data.count)", forHTTPHeaderField: "Content-Length")
        httpBody = data
    }

    mutating func addJSONDataHTTPBody(data: Data) {
        setValue("*/*", forHTTPHeaderField: "Accept")
        setValue("application/json", forHTTPHeaderField: "Content-Type")
        setValue("\(data.count)", forHTTPHeaderField: "Content-Length")
        httpBody = data
    }
}

extension HTTPParameter {
    static func createBasicAuth(login: String, password: String) -> Self {
        let userPasswordString = "\(login):\(password)"
        let data = userPasswordString.data(using: .utf8) ?? Data()
        let credential = data.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
        let authString = "Basic \(credential)"
        return ["Authorization": authString]
    }
}

extension URLSession {
    typealias DataTaskCompletion = (Data?, URLResponse?, Error?) -> Void
    func startDataTask(request: URLRequest, completion: @escaping DataTaskCompletion) -> URLSessionDataTask {
        let task = dataTask(with: request, completionHandler: completion)
        task.resume()
        return task
    }
}

extension String {
    var urlEncoded: String {
        // Taken from https://stackoverflow.com/a/34788364/2151463
        let unreservedChars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~"
        let encodedString = addingPercentEncoding(withAllowedCharacters: CharacterSet(charactersIn: unreservedChars))
        return encodedString ?? self
    }
}
