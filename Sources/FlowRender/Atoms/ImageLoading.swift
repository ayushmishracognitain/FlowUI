import SwiftUI
import FlowCore

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Fetches raw image bytes for `FlowImage`.
///
/// The protocol works in bytes rather than platform image types so implementations
/// stay `Sendable` and hosts can plug in any pipeline (their own cache, a third
/// party library, a bundled asset lookup) by decoding on their side of the seam.
public protocol FlowImageLoader: Sendable {
    func imageData(for url: URL) async throws -> Data
}

/// The loader used when the host installs nothing: `URLSession` with a dedicated
/// `URLCache`, good enough for real lists without any dependency.
public struct DefaultImageLoader: FlowImageLoader {
    private static let session: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.urlCache = URLCache(
            memoryCapacity: 32 * 1024 * 1024,
            diskCapacity: 256 * 1024 * 1024
        )
        configuration.requestCachePolicy = .returnCacheDataElseLoad
        return URLSession(configuration: configuration)
    }()

    public init() {}

    public func imageData(for url: URL) async throws -> Data {
        let (data, response) = try await Self.session.data(from: url)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw URLError(.badServerResponse)
        }
        return data
    }
}

#if canImport(UIKit)
typealias FlowPlatformImage = UIImage
#elseif canImport(AppKit)
typealias FlowPlatformImage = NSImage
#endif

#if canImport(UIKit) || canImport(AppKit)
/// A decoded bitmap on its way from a background decode to the main actor.
///
/// `UIImage` and `NSImage` disagree about `Sendable`, and an image that has just
/// been decoded and not yet published is owned by exactly one task, so the box is
/// the narrowest place to state that.
struct FlowDecodedImage: @unchecked Sendable {
    let platform: FlowPlatformImage
}

/// A small in memory cache of *decoded* images.
///
/// `URLCache` stores bytes. Turning bytes into a bitmap is the expensive half and
/// it used to happen on every appearance, on the main thread. `NSCache` is already
/// thread safe and evicts under memory pressure, which is exactly the policy we want.
final class FlowDecodedImageCache: @unchecked Sendable {
    static let shared = FlowDecodedImageCache()

    private let cache = NSCache<NSString, FlowPlatformImage>()

    private init() {
        cache.countLimit = 250
    }

    func image(for key: String) -> FlowPlatformImage? {
        cache.object(forKey: key as NSString)
    }

    func insert(_ image: FlowPlatformImage, for key: String) {
        cache.setObject(image, forKey: key as NSString)
    }

    /// Decodes off the main actor, so a long scroll does not turn into a stutter.
    static func decode(_ data: Data) async -> FlowDecodedImage? {
        await Task.detached(priority: .userInitiated) {
            FlowPlatformImage(data: data).map(FlowDecodedImage.init(platform:))
        }.value
    }
}

extension Image {
    /// Builds an `Image` from an already decoded platform bitmap.
    init(flowPlatformImage image: FlowPlatformImage) {
        #if canImport(UIKit)
        self.init(uiImage: image)
        #else
        self.init(nsImage: image)
        #endif
    }
}
#endif
