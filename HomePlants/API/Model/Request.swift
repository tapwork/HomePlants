import Foundation

typealias JSON = [String: Any]
public typealias HTTPParameter = [String: String]

extension URL {
    static var base: URL {
        /// Replace with your wordpress instance and
        /// Install the following plugins:
        /// - Advanced Custom Fields (import ACF from json in this repository)
        /// - ACF to REST API
        /// - JWT Authentication for WP-API
        URL(string: "https://simpleradio.tapwork.de/wp-json")!
    }
}

extension URLRequest {
    static func POST( _ path: String, body: Request.Body? = nil, header: HTTPParameter? = nil) -> URLRequest {
        Request(body: body, queryParameter: nil, path: path, httpMethod: .POST, header: header).urlRequest()
    }

    static func PUT( _ path: String, body: Request.Body? = nil, header: HTTPParameter? = nil) -> URLRequest {
        Request(body: body, queryParameter: nil, path: path, httpMethod: .PUT, header: header).urlRequest()
    }

    static func GET(_ path: String, queryParameter: HTTPParameter? = nil, header: HTTPParameter? = nil) -> URLRequest {
        Request(body: nil, queryParameter: queryParameter, path: path, httpMethod: .GET, header: header).urlRequest()
    }

    static func HEAD( _ path: String, queryParameter: HTTPParameter? = nil, header: HTTPParameter? = nil) -> URLRequest {
        Request(body: nil, queryParameter: queryParameter, path: path, httpMethod: .HEAD, header: header).urlRequest()
    }

    static func GET(url: URL) -> URLRequest {
        Request(baseURL: url, body: nil, queryParameter: nil, path: "", httpMethod: .GET, header: nil).urlRequest()
    }
}

struct Request {

    enum Body {
        case jsonEncodable(Encodable)
        case wwwForm(HTTPParameter)
    }

    static var defaultHeaderFields: HTTPParameter?

    enum HTTPMethod: String {
        case POST
        case GET
        case HEAD
        case PUT
    }

    var baseURL: URL?
    let body: Body?
    let queryParameter: HTTPParameter?
    let path: String
    let httpMethod: HTTPMethod
    let header: HTTPParameter?

    func urlRequest(baseURL: URL? = nil) -> URLRequest {
        let base: URL = (self.baseURL ?? baseURL) ?? .base
        var request = URLRequest(url: base.appending(path))
        request.httpMethod = httpMethod.rawValue

        if let parameter = queryParameter, let url = request.url {
            request.url = url.appendingQuery(parameter)
        }
        switch body {
        case .some(.jsonEncodable(let content)) where content.data != nil:
            request.addJSONDataHTTPBody(data: content.data!)
        case .some(.wwwForm(let content)):
            request.addWWWFormHTTPBody(parameter: content)
        default:
            break
        }
        request.setValue("keep-alive", forHTTPHeaderField: "Connection")
        if let defaultHeader = Request.defaultHeaderFields {
            request.update(header: defaultHeader)
        }
        if let header = header {
            request.update(header: header)
        }

        return request
    }
}

extension URLRequest {

    static var empty: Self {
        URLRequest(url: URL(string: "https://www.example.com")!)
    }
    mutating func update(header: HTTPParameter) {
        header.forEach { setValue($0.value, forHTTPHeaderField: $0.key) }
    }
}

extension Request.Body: Equatable {
    static func == (lhs: Request.Body, rhs: Request.Body) -> Bool {
        switch (lhs, rhs) {
        case (.jsonEncodable(let left), .jsonEncodable(let right)):
            return left.asJSONString == right.asJSONString
        case (.wwwForm(let left), .wwwForm(let right)):
            return left == right
        default:
            return false
        }
    }
}
