import SwiftUI
import Combine

struct NetworkImage: View {
    @ObservedObject var loader: NetworkImageLoader
    let placeholder: String
    init(url: URL?, placeholder: String) {
        self.placeholder = placeholder
        self.loader = NetworkImageLoader(url: url)
    }

    var body: some View {
        if let image = loader.image {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else {
            Image(systemName: placeholder)
        }
    }
}

class NetworkImageLoader: ObservableObject {

    static let urlCache: URLCache = {
        let cache = URLCache()
        cache.diskCapacity = 100_000_000 // 100 MB
        cache.memoryCapacity = 50_000_000 // 50 MB
        return cache
    }()
    static let imageCache = NSCache<NSURL, UIImage>()
    static var configuration: URLSessionConfiguration = {
        let configuration = URLSessionConfiguration.default
        configuration.urlCache = urlCache
        configuration.httpShouldSetCookies = true
        configuration.httpCookieAcceptPolicy = .always
        return configuration
    }()
    static var session: URLSession = {
        URLSession(configuration: configuration, delegate: nil, delegateQueue: nil)
    }()
    @Published var image: UIImage? {
        didSet {
            guard let image = image else {
                return Self.imageCache.remove(for: url)
            }
            if let querySize = url.queryItems.first(where: {$0.name == "size"}),
               let size = Int(querySize.value ?? ""),
               let thumb = image.copy(baseWidth: CGFloat(size)) {
                Self.imageCache.store(thumb, for: url)
                Self.imageCache.store(image, for: url.removingQueryComponent(key: "size"))
            } else {
                Self.imageCache.store(image, for: url)
            }
        }
    }
    var subscriptions = [AnyCancellable]()
    let url: URL

    init(url: URL?) {
        guard let url = url else {
            self.url = URL(string: "https://www.nothing.com")!
            return
        }
        self.url = url
        if let image = Self.imageCache.object(forKey: url as NSURL) {
            self.image = image
            return
        }
        let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 60.0)
        Self.session.dataTaskPublisher(for: request)
            .compactMap { UIImage(data: $0.data) }
            .replaceError(with: nil)
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
            .assign(to: \.image, on: self)
            .store(in: &subscriptions)
    }
}

extension NSCache where KeyType == NSURL, ObjectType == UIImage {
    func store(_ image: UIImage, for url: URL) {
        setObject(image, forKey: url as NSURL)
    }
    func image(for url: URL) -> UIImage? {
        object(forKey: url as NSURL)
    }
    func remove(for url: URL) {
        removeObject(forKey: url as NSURL)
    }
}

extension UIImage {
    func copy(baseWidth: CGFloat, retina: Bool = true) -> UIImage? {
        let factor = size.width < size.height ? size.width / size.height : size.height / size.width
        let newSize = CGSize(width: baseWidth, height: baseWidth / factor)
        UIGraphicsBeginImageContextWithOptions(
            /* size: */ newSize,
            /* opaque: */ false,
            /* scale: */ retina ? 0 : 1
        )
        defer { UIGraphicsEndImageContext() }

        draw(in: CGRect(origin: .zero, size: newSize))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}
