import Foundation

extension JSONDecoder {
    static var shared: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()
}

extension JSONEncoder {
    static var shared: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }()
}


func JSONDocumentURL(filename: String, for directory: FileManager.SearchPathDirectory) -> URL? {
    let urls = FileManager.default.urls(for: directory, in: .userDomainMask)
    return urls.first?.appendingPathComponent("\(filename).json")
}

extension NSError {
    static var cannotOpenFile: NSError {
        NSError(domain: NSURLErrorDomain, code: NSURLErrorCannotOpenFile, userInfo: nil)
    }
}

extension FileManager.SearchPathDirectory {
    static var defaultStore: Self {
        .documentDirectory
    }
}

extension Encodable {
    func store(name: String, at directory: FileManager.SearchPathDirectory = .defaultStore, ignoreLog: Bool = false) {
        do {
            guard let url = JSONDocumentURL(filename: name, for: directory) else {
                throw NSError.cannotOpenFile
            }
            let data = try JSONEncoder.shared.encode(self)
            try data.write(to: url, options: .atomicWrite)
        } catch {
            if !ignoreLog {
                error.log(category: .fileManager)
            }
        }
    }
}

extension Decodable {
    static func load(name: String, at directory: FileManager.SearchPathDirectory = .defaultStore, ignoreLog: Bool = false) throws -> Self {
        var decoded: Self?
        var jsonDecoderError: Error?
        do {
            guard let url = JSONDocumentURL(filename: name, for: directory) else {
                throw NSError.cannotOpenFile
            }
            let data = try Data(contentsOf: url)
            decoded = try JSONDecoder.shared.decode(Self.self, from: data)
        } catch {
            jsonDecoderError = error
        }
        guard let result = decoded else {
            let error = jsonDecoderError ?? NSError.cannotOpenFile
            if !ignoreLog {
                error.log(category: .fileManager)
            }
            throw error
        }
        return result
    }
}

extension FileManager {
    static func remove(name: String, at directory: FileManager.SearchPathDirectory = .defaultStore, ignoreLog: Bool = false) throws {
        guard let url = JSONDocumentURL(filename: name, for: directory) else {
            let error = NSError.cannotOpenFile
            if !ignoreLog {
                error.log(category: .fileManager)
            }
            throw error
        }
        try FileManager.default.removeItem(at: url)
    }
}

extension URL {
    func appendingQueryComponent(key: String, value: String) -> URL {
        var comps = URLComponents(string: absoluteString)
        var queryItems = comps?.queryItems ?? []
        queryItems.append(.init(name: key, value: value))
        comps?.queryItems = queryItems
        return comps?.url ?? self
    }

    func removingQueryComponent(key: String) -> URL {
        var comps = URLComponents(string: absoluteString)
        var queryItems = comps?.queryItems ?? []
        queryItems.removeAll(where: {$0.name == key})
        if queryItems.isEmpty {
            comps?.queryItems = nil
        } else {
            comps?.queryItems = queryItems
        }
        return comps?.url ?? self
    }

    var queryItems: [URLQueryItem] {
        URLComponents(string: absoluteString)?.queryItems ?? []
    }
}
