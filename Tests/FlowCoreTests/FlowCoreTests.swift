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
    func decodeContent(
        type: String,
        from container: KeyedDecodingContainer<WidgetCodingKeys>
    ) throws -> (any WidgetContent)? {
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
        let json = Data(#"{"a": 1, "b": "two", "c": [true, null], "d": {"nested": 2.5}}"#.utf8)
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
        let color = try JSONDecoder().decode(ColorData.self, from: Data("\"#FF5722\"".utf8))
        XCTAssertEqual(color.hex, "#FF5722")
    }

    func testTextAcceptsBareString() throws {
        let text = try JSONDecoder().decode(TextData.self, from: Data(#""Hello""#.utf8))
        XCTAssertEqual(text.text, "Hello")
    }

    func testCornerRadiusUniformShorthand() throws {
        let uniform = try JSONDecoder().decode(CornerRadiusData.self, from: Data("12".utf8))
        XCTAssertEqual(uniform.uniformValue, 12)

        let perCorner = try JSONDecoder().decode(
            CornerRadiusData.self,
            from: Data(#"{"top_left": 8, "top_right": 8}"#.utf8)
        )
        XCTAssertEqual(perCorner.topLeft, 8)
        XCTAssertEqual(perCorner.bottomLeft, 0)
        XCTAssertNil(perCorner.uniformValue)
    }

    func testWidgetWidthParsing() throws {
        let decoder = JSONDecoder()
        XCTAssertEqual(try decoder.decode(WidgetWidth.self, from: Data(#""fill""#.utf8)), .fill)
        XCTAssertEqual(try decoder.decode(WidgetWidth.self, from: Data(#""hug""#.utf8)), .hug)
        XCTAssertEqual(try decoder.decode(WidgetWidth.self, from: Data("0.75".utf8)), .fraction(0.75))
        XCTAssertEqual(try decoder.decode(WidgetWidth.self, from: Data(#""0.5""#.utf8)), .fraction(0.5))
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
        let json = Data(#"{"arrangement": "hexagon_spiral"}"#.utf8)
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
        XCTAssertTrue(
            malformed.message.contains("title"),
            "Error should name the missing key, got: \(malformed.message)"
        )
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
        let json = Data(#"{"type": "toast", "message": "Saved"}"#.utf8)
        let action = try JSONDecoder().decode(ActionData.self, from: json)
        XCTAssertEqual(action.type, "toast")
        XCTAssertEqual(try action.payload(ToastPayload.self).message, "Saved")
    }

    // MARK: - Identity

    /// The blocker this whole suite exists to guard. `AnyWidget` is `Identifiable`
    /// and drives `ForEach`, so an id that differs between two decodes of the same
    /// bytes makes SwiftUI rebuild the entire page on every refresh instead of
    /// diffing it, taking scroll position and in flight image loads with it.
    func testIdentifiersAreStableAcrossDecodesOfTheSameBytes() throws {
        let data = try fixture("page_identity")

        func identifiers() throws -> [String] {
            let page = try makeDecoder().decode(PageResponse.self, from: data).page
            return page.allWidgets.map(\.id)
        }

        let first = try identifiers()
        let second = try identifiers()

        XCTAssertEqual(first, second, "Decoding the same bytes twice must produce the same widget ids")
        XCTAssertFalse(first.isEmpty)
    }

    /// Section and page identity has to be stable for the same reason.
    func testSectionAndPageIdentifiersAreStableAndPositional() throws {
        let json = Data(#"{"page": {"sections": [{"widgets": []}, {"widgets": []}]}}"#.utf8)
        let firstPage = try makeDecoder().decode(PageResponse.self, from: json).page
        let secondPage = try makeDecoder().decode(PageResponse.self, from: json).page

        XCTAssertEqual(firstPage.id, secondPage.id)
        XCTAssertEqual(firstPage.sections.map(\.id), secondPage.sections.map(\.id))
        // Two sections at different positions must not collide.
        XCTAssertNotEqual(firstPage.sections[0].id, firstPage.sections[1].id)
    }

    /// Widgets with no `id` must still be distinguishable from one another.
    func testGeneratedIdentifiersAreUniqueWithinAPage() throws {
        let page = try makeDecoder().decode(PageResponse.self, from: try fixture("page_identity")).page
        let identifiers = page.allWidgets.map(\.id)
        XCTAssertEqual(
            Set(identifiers).count,
            identifiers.count,
            "Every widget in a page needs a distinct id, got: \(identifiers)"
        )
    }

    /// A backend that repeats an id corrupts `ForEach` and makes mutations
    /// ambiguous, so the collision is renamed and reported rather than ignored.
    func testDuplicateIdentifiersAreRenamedAndReported() throws {
        let diagnostics = DecodeDiagnostics()
        let page = try makeDecoder(diagnostics: diagnostics)
            .decode(PageResponse.self, from: try fixture("page_identity")).page

        let identifiers = page.allWidgets.map(\.id)
        XCTAssertEqual(Set(identifiers).count, identifiers.count)

        // The fixture claims "dup" three times: once in the header, twice in sections.
        XCTAssertEqual(identifiers.filter { $0 == "dup" }.count, 1, "The first claimant keeps the plain id")
        XCTAssertTrue(identifiers.contains("dup#2"))
        XCTAssertTrue(identifiers.contains("dup#3"))

        let duplicates = diagnostics.entries.filter { $0.kind == .duplicateID }
        XCTAssertEqual(duplicates.count, 2, "Both collisions should be reported")
        XCTAssertTrue(duplicates.allSatisfy { $0.message.contains("dup") })
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

    /// A sticky footer button is as replaceable as a card in the middle of the
    /// list. Before this, `replace_widget` only ever walked section bodies, so a
    /// mutation aimed at a bar widget was accepted and then quietly did nothing.
    func testMutationsReachHeaderFooterAndSectionHeaders() throws {
        var page = try makeDecoder()
            .decode(PageResponse.self, from: try fixture("page_basic")).page

        func replacement(_ id: String, _ title: String) -> AnyWidget {
            AnyWidget(id: id, type: TestTextContent.widgetType, content: TestTextContent(title: title))
        }

        page.apply(.replaceWidget(id: "header_title", with: replacement("header_title", "New header")))
        XCTAssertEqual(
            (page.header?.widgets.first?.content as? TestTextContent)?.title,
            "New header",
            "replace_widget must reach the page header"
        )

        page.apply(.replaceWidget(id: "footer_cta", with: replacement("footer_cta", "New footer")))
        XCTAssertEqual(
            (page.footer?.widgets.first?.content as? TestTextContent)?.title,
            "New footer",
            "replace_widget must reach the page footer"
        )

        page.apply(.removeWidget(id: "header_title"))
        XCTAssertTrue(page.header?.widgets.isEmpty ?? false)
    }

    func testMutationsReachSectionHeaders() throws {
        var page = try makeDecoder()
            .decode(PageResponse.self, from: try fixture("page_identity")).page
        let headerID = try XCTUnwrap(page.sections.first?.header?.id)

        page.apply(.replaceWidget(
            id: headerID,
            with: AnyWidget(id: headerID, type: TestTextContent.widgetType, content: TestTextContent(title: "Swapped"))
        ))
        XCTAssertEqual((page.sections.first?.header?.content as? TestTextContent)?.title, "Swapped")

        page.apply(.removeWidget(id: headerID))
        XCTAssertNil(page.sections.first?.header)
    }
}
