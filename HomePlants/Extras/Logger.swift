import Foundation
import Combine

class Logger {

    enum Level: Int, CustomStringConvertible {
        case info, warning, error
        var name: String {
            switch self {
            case .info: return "INFO"
            case .warning: return "WARNING"
            case .error: return "ERROR"
            }
        }
        var icon: String {
            switch self {
            case .info: return "ℹ️"
            case .warning: return "⚠️"
            case .error: return "❌"
            }
        }
        var description: String { "\(icon) [\(name.localizedUppercase)]" }
    }

    enum Category: String, CustomStringConvertible {
        case system, network, keychain, fileManager, json, notification
        var description: String { "\(icon) [\(rawValue.localizedUppercase)]" }
        var icon: String {
            switch self {
            case .system: return "📱"
            case .network: return "📡"
            case .notification: return "📨"
            case .keychain: return "🔑"
            case .fileManager: return "📁"
            case .json: return "📝"
            }
        }
    }

    private static var level: Level {
        Level(rawValue: UserDefaults.standard.integer(forKey: "LogLevel")) ?? Level.error
    }
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = NSLocale.current
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter
    }()
    static var shared: Logger!
    let level: Level

    init(level: Level) {
        self.level = level
    }

    func warning(_ msg: String,
                  category: Category,
                  functionName: String = #function,
                  fileName: String = #file,
                  lineNumber: Int = #line) {
        log(msg,
            category: category,
            level: .warning,
            functionName: functionName,
            fileName: fileName,
            lineNumber: lineNumber)
    }

    func error(_ msg: String,
                  category: Category,
                  functionName: String = #function,
                  fileName: String = #file,
                  lineNumber: Int = #line) {
        log(msg,
            category: category,
            level: .error,
            functionName: functionName,
            fileName: fileName,
            lineNumber: lineNumber)
    }

    func log(_ msg: String,
             category: Category,
             level: Level = .info,
             functionName: String = #function,
             fileName: String = #file,
             lineNumber: Int = #line) {
        let message = "[\((fileName as NSString).lastPathComponent):\(lineNumber) - \(functionName)] \(msg)"
        if level.rawValue >= self.level.rawValue {
            let date = dateFormatter.string(from: Date())
            print("\(level.description) => \(category.description) => \(date): \(message)")
        }
    }

    func log(_ error: Error, category: Category) {
        log((error as NSError).debugDescription, category: category, level: .error)
    }
}

extension URLRequest {
    func logStart() -> Date {
        Logger.shared.log("Start \(self)", category: .network)
        return Date()
    }
}

extension URLResponse {
    func logFinished(started: Date) {
        Logger.shared.log("Request done: Duration: \(Date().timeIntervalSince(started)) sec\n\(self)", category: .network)
    }
}

extension Error {
    @discardableResult
    func log(category: Logger.Category) -> Self {
        Logger.shared.log(self, category: category)
        return self
    }
}
