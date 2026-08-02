import XCTest
@testable import FlowCore

/// A minimal widget payload used across the suite.
private struct TestTextContent: WidgetContent, Hashable {
    static let widgetType = "test_text"
    let title: String
}

/// A tiny registry standing in for FlowRender's real one, so FlowCore decoding is
/// testable without SwiftUI.
private struct TestRegistry: WidgetDecoding {
    func decodeContent(type: String, from container: KeyedDecodingContainer<WidgetCodingKeys>) throws -> (any WidgetContent)? {
        guard type == TestTextContent.widgetType else { return nil }
        return try container.decode(TestTextContent.self, forKey: .data)
    }
}

final class FlowCoreTests: XCTestCase {

    private func fixture(_ name: String) throws -> Data {
        let url = try XCTUnwrap(
            Bundle.module.url(forResource: name, withExtension: "json", subdirectory: "Fixtures"),
            "Missing fixture \(name).json"
        )
        return try Data(contentsOf: url)
    }

    private func makeDecoder(diagnostics: DecodeDiagnostics? = nil) -> JSONDecoder {
        FlowDecoder.make(widgetDecoding: TestRegistry(), diagnostics: diagnostics)
    }

    // MARK: - JSONValue

    func testJSONValueRoundTrip() throws {
        let json = #"{"a": 1, "b": "two", "c": [true, null], "d": {"nested": 2.5}}"#.data(using: .utf8)!
        let value = try JSONDecoder().decode(JSONValue.self, from: json)
        XCTAssertEqual(value["a"]?.intValue, 1)
        XCTAssertEqual(value["b"]?.stringValue, "two")
        XCTAssertEqual(value["c"]?[0]?.boolValue, true)
        XCTAssertEqual(value["c"]?[1], .null)
        XCTAssertEqual(value["d"]?["nested"]?.doubleValue, 2.5)

        let reencoded = try JSONEncoder().encode(value)
        let decodedAgain = try JSONDecoder().decode(JSONValue.self, from: reencoded)
        XCTAssertEqual(value, decodedAgain)
    }

    // MARK: - Atoms

    func testColorAcceptsBareHexString() throws {
        let color = try JSONDecoder().decode(ColorData.self, from: "\"#FF5722\"".data(using: .utf8)!)
        XCTAssertEqual(color.hex, "#FF5722")
    }

    func testTextAcceptsBareString() throws {
        let text = try JSONDecoder().decode(TextData.self, from: #""Hello""#.data(using: .utf8)!)
        XCTAssertEqual(text.text, "Hello")
    }

    func testCornerRadiusUniformShorthand() throws {
        let uniform = try JSONDecoder().decode(CornerRadiusData.self, from: "12".data(using: .utf8)!)
        XCTAssertEqual(uniform.uniformValue, 12)

        let perCorner = try JSONDecoder().decode(
            CornerRadiusData.self,
            from: #"{"top_left": 8, "top_right": 8}"#.data(using: .utf8)!
        )
        XCTAssertEqual(perCorner.topLeft, 8)
        XCTAssertEqual(perCorner.bottomLeft, 0)
        XCTAssertNil(perCorner.uniformValue)
    }

    func testWidgetWidthParsing() throws {
        let decoder = JSONDecoder()
        XCTAssertEqual(try decoder.decode(WidgetWidth.self, from: #""fill""#.data(using: .utf8)!), .fill)
        XCTAssertEqual(try decoder.decode(WidgetWidth.self, from: #""hug""#.data(using: .utf8)!), .hug)
        XCTAssertEqual(try decoder.decode(WidgetWidth.self, from: "0.75".data(using: .utf8)!), .fraction(0.75))
        XCTAssertEqual(try decoder.decode(WidgetWidth.self, from: #""0.5""#.data(using: .utf8)!), .fraction(0.5))
    }

    // MARK: - Page decoding

    func testBasicPageDecodes() throws {
        let response = try makeDecoder().decode(PageResponse.self, from: try fixture("page_basic"))
        let page = response.page

        XCTAssertEqual(page.id, "home")
        XCTAssertEqual(page.nav?.title?.text, "Home")
        XCTAssertEqual(page.sections.count, 2)
        XCTAssertEqual(page.sections[0].widgets.count, 2)
        XCTAssertEqual(page.sections[1].layout.arrangement, .carousel)
        XCTAssertEqual(page.header?.widgets.count, 1)
        XCTAssertEqual(page.footer?.widgets.count, 1)

        let first = page.sections[0].widgets[0]
        XCTAssertEqual(first.id, "w_1")
        XCTAssertEqual((first.content as? TestTextContent)?.title, "First card")
        XCTAssertEqual(first.layout.cornerRadius?.uniformValue, 12)
        XCTAssertEqual(first.layout.margin?.left, 16)
        XCTAssertEqual(first.actions.tap?.type, "toast")
        XCTAssertEqual(first.tracking?["impression_id"]?.stringValue, "imp_1")

        XCTAssertEqual(page.pagination?.hasMore, true)
        XCTAssertEqual(page.pagination?.postback?["cursor"]?.stringValue, "abc123")

        let carouselWidths = page.sections[1].widgets.map(\.layout.width)
        XCTAssertEqual(carouselWidths, [.fraction(0.75), .fraction(0.75)])
    }

    func testUnknownArrangementFallsBackToVertical() throws {
        let json = #"{"arrangement": "hexagon_spiral"}"#.data(using: .utf8)!
        let layout = try JSONDecoder().decode(SectionLayout.self, from: json)
        XCTAssertEqual(layout.arrangement, .vertical)
    }

    // MARK: - Resilience

    func testProblemWidgetsNeverFailThePage() throws {
        let diagnostics = DecodeDiagnostics()
        let response = try makeDecoder(diagnostics: diagnostics)
            .decode(PageResponse.self, from: try fixture("page_problem_widgets"))
        let widgets = response.page.sections[0].widgets

        // The widget with no type key is dropped, everything else survives.
        XCTAssertEqual(widgets.count, 4)

        XCTAssertTrue(widgets[0].content is TestTextContent)
        XCTAssertTrue(widgets[1].content is UnknownWidgetContent)
        XCTAssertTrue(widgets[2].content is MalformedWidgetContent)
        XCTAssertTrue(widgets[3].content is TestTextContent)

        let kinds = diagnostics.entries.map(\.kind)
        XCTAssertTrue(kinds.contains(.unknownType))
        XCTAssertTrue(kinds.contains(.malformedPayload))
        XCTAssertTrue(kinds.contains(.droppedElement))

        let malformed = try XCTUnwrap(widgets[2].content as? MalformedWidgetContent)
        XCTAssertTrue(malformed.message.contains("title"), "Error should name the missing key, got: \(malformed.message)")
    }

    func testDecodingWithoutRegistryProducesUnknownContent() throws {
        let decoder = FlowDecoder.make()
        let response = try decoder.decode(PageResponse.self, from: try fixture("page_basic"))
        XCTAssertTrue(response.page.sections[0].widgets.allSatisfy { $0.content is UnknownWidgetContent })
    }

    // MARK: - Sheets

    func testSheetDecodes() throws {
        let response = try makeDecoder().decode(SheetResponse.self, from: try fixture("sheet_basic"))
        let sheet = response.sheet

        XCTAssertEqual(sheet.id, "confirm_sheet")
        XCTAssertEqual(sheet.header?.widgets.count, 1)
        XCTAssertEqual(sheet.sections[0].widgets.count, 2)
        XCTAssertEqual(sheet.footer?.widgets.count, 1)
        XCTAssertEqual(sheet.config.detents?.count, 2)
        XCTAssertEqual(sheet.config.cornerRadius, 24)
    }

    // MARK: - Actions

    func testActionPreservesRawObjectForHandlers() throws {
        struct ToastPayload: Decodable {
            let message: String
        }
        let json = #"{"type": "toast", "message": "Saved"}"#.data(using: .utf8)!
        let action = try JSONDecoder().decode(ActionData.self, from: json)
        XCTAssertEqual(action.type, "toast")
        XCTAssertEqual(try action.payload(ToastPayload.self).message, "Saved")
    }

    // MARK: - Mutations

    func testPageMutations() throws {
        var page = try makeDecoder()
            .decode(PageResponse.self, from: try fixture("page_basic")).page

        let replacement = AnyWidget(
            id: "w_1",
            type: TestTextContent.widgetType,
            content: TestTextContent(title: "Replaced")
        )
        page.apply(.replaceWidget(id: "w_1", with: replacement))
        XCTAssertEqual((page.sections[0].widgets[0].content as? TestTextContent)?.title, "Replaced")

        page.apply(.removeWidget(id: "w_2"))
        XCTAssertEqual(page.sections[0].widgets.count, 1)

        page.apply(.appendSections([SectionModel(id: "appended")]))
        XCTAssertEqual(page.sections.last?.id, "appended")

        page.apply(.prependSections([SectionModel(id: "prepended")]))
        XCTAssertEqual(page.sections.first?.id, "prepended")
    }
}
