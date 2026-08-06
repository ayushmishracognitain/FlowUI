import XCTest
import FlowCore
@testable import FlowWidgets

/// Decode coverage for the starter widget payloads.
///
/// The framework promises that a bad array element is dropped while the rest
/// survives. That held for the envelope arrays from the start, but the starter
/// widgets used synthesized `Decodable`, which is all or nothing: one malformed
/// button emptied an entire `button_row`. These tests pin the promise down.
final class StarterWidgetDecodingTests: XCTestCase {

    private func decode<T: Decodable>(_ type: T.Type, _ json: String) throws -> T {
        try JSONDecoder().decode(type, from: Data(json.utf8))
    }

    // MARK: - Lossy payload arrays

    func testButtonRowDropsOnlyTheBadButton() throws {
        // The middle button has no `title`, which is required.
        let content = try decode(ButtonRowContent.self, """
        {
          "buttons": [
            { "title": "Accept" },
            { "bg_color": "#FF0000" },
            { "title": "Reject", "style": "outline" }
          ]
        }
        """)

        XCTAssertEqual(content.buttons.count, 2, "One malformed button must not empty the row")
        XCTAssertEqual(content.buttons.map(\.title.text), ["Accept", "Reject"])
    }

    func testTagRailDropsOnlyTheBadTag() throws {
        let content = try decode(TagRailContent.self, """
        { "tags": [ { "text": "All" }, { "bg_color": "#FFF" }, { "text": "Audio" } ] }
        """)

        XCTAssertEqual(content.tags.count, 2)
        XCTAssertEqual(content.tags.map(\.text.text), ["All", "Audio"])
    }

    func testImageTextCardDropsOnlyTheBadTag() throws {
        let content = try decode(ImageTextCardContent.self, """
        {
          "title": "AirPods Pro 2",
          "tags": [ { "text": "BESTSELLER" }, { "no_text_here": true } ]
        }
        """)

        XCTAssertEqual(content.title.text, "AirPods Pro 2")
        XCTAssertEqual(content.tags?.count, 1)
    }

    func testMissingButtonsKeyDecodesToAnEmptyRow() throws {
        let content = try decode(ButtonRowContent.self, "{}")
        XCTAssertTrue(content.buttons.isEmpty)
    }

    // MARK: - Required fields still fail, so the widget is contained

    /// Containment depends on the payload actually throwing when the widget cannot
    /// be rendered meaningfully. A card with no title is not a card.
    func testCardWithoutTitleStillThrows() {
        XCTAssertThrowsError(try decode(ImageTextCardContent.self, #"{"subtitle": "no title"}"#))
    }

    func testBannerWithoutImageStillThrows() {
        XCTAssertThrowsError(try decode(BannerContent.self, #"{"title": "no image"}"#))
    }

    // MARK: - Optional fields and shorthand

    func testStepperRowDefaultsEverythingButTitle() throws {
        let content = try decode(StepperRowContent.self, #"{"title": "USB C Cable"}"#)
        XCTAssertEqual(content.title.text, "USB C Cable")
        XCTAssertNil(content.min)
        XCTAssertNil(content.max)
        XCTAssertNil(content.initial)
    }

    func testTitleBlockAcceptsBareStringShorthand() throws {
        let content = try decode(TitleBlockContent.self, #"{"title": "Popular", "subtitle": "Curated"}"#)
        XCTAssertEqual(content.title.text, "Popular")
        XCTAssertEqual(content.subtitle?.text, "Curated")
    }

    func testSeparatorPayloadIsTheSeparatorItself() throws {
        let content = try decode(SeparatorContent.self, #"{"style": "dashed", "thickness": 2}"#)
        XCTAssertEqual(content.separator.style, "dashed")
        XCTAssertEqual(content.separator.thickness, 2)
    }

    func testAccordionKeepsNestedWidgetsLossy() throws {
        let content = try decode(AccordionContent.self, """
        {
          "header": "How do refunds work?",
          "items": [
            { "type": "title_block", "data": { "title": "Five to seven days" } },
            { "no_type_key": true }
          ]
        }
        """)

        XCTAssertEqual(content.header.text, "How do refunds work?")
        XCTAssertEqual(content.items.count, 1, "The element with no type is dropped, the good one survives")
    }

    // MARK: - Accessibility surface

    /// Images carry alt text now, and its absence is what marks an image as
    /// decorative rather than simply unlabelled.
    func testImageAltTextDecodes() throws {
        let labelled = try decode(ImageData.self, #"{"url": "https://x/y.png", "alt": "AirPods in a case"}"#)
        XCTAssertEqual(labelled.alt, "AirPods in a case")

        let decorative = try decode(ImageData.self, #""https://x/y.png""#)
        XCTAssertNil(decorative.alt)
        XCTAssertEqual(decorative.url, "https://x/y.png")
    }
}
