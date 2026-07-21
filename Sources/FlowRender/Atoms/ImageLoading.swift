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

extension Image {
    /// Builds an `Image` from raw bytes on whichever platform we are on.
    init?(flowData data: Data) {
        #if canImport(UIKit)
        guard let image = UIImage(data: data) else { return nil }
        self.init(uiImage: image)
        #elseif canImport(AppKit)
        guard let image = NSImage(data: data) else { return nil }
        self.init(nsImage: image)
        #else
        return nil
        #endif
    }
}
