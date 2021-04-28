import Foundation

extension Encodable {
    var data: Data? {
        try? JSONEncoder.shared.encode(self)
    }

    var asJSONString: String? {
        String(data: data ?? Data(), encoding: .utf8)
    }
}

extension Decodable {
    static func from(_ json: String) -> Self? {
        do {
            return try JSONDecoder.shared.decode(Self.self, from: json.data(using: .utf8) ?? Data())
        } catch {
            error.log(category: .json)
        }
        return nil
    }
}
