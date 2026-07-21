import Foundation

/// Describes one fetch of a page.
public struct PageRequest: Sendable {
    public enum Kind: Sendable {
        case initial
        case refresh
        /// Requests the next page. `postback` is whatever the backend sent in the
        /// previous response's `pagination.postback`, echoed untouched.
        case nextPage(postback: JSONValue?)
        /// A fetch triggered by an `api` action; the payload is the action's raw object.
        case action(JSONValue)
    }

    public let pageID: String
    public let kind: Kind

    public init(pageID: String, kind: Kind) {
        self.pageID = pageID
        self.kind = kind
    }
}

/// The host's networking, seen from Flow-UI's side.
///
/// Flow-UI ships no HTTP stack on purpose. The host implements this protocol with
/// whatever client it already has and returns raw response bytes; Flow-UI does the
/// decoding. This is the seam that keeps the framework portable.
public protocol PageLoader: Sendable {
    func loadPage(_ request: PageRequest) async throws -> Data
}
