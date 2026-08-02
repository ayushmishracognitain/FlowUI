import SwiftUI
import FlowCore
import FlowRender

/// The live sandbox: JSON on top, rendered page below.
///
/// Edit, tap Render, see the result instantly, including how decoding problems
/// surface. The templates menu inserts a starting point for every widget type.
struct PlaygroundView: View {
    @State private var json: String = PlaygroundTemplates.startingPage
    @State private var store: PageStore?
    @State private var dispatcher: ActionDispatcher?
    @State private var renderTick = 0

    var body: some View {
        VStack(spacing: 0) {
            editor
            Divider()
            preview
        }
        .navigationTitle("Playground")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Menu("Templates") {
                    ForEach(PlaygroundTemplates.all, id: \.name) { template in
                        Button(template.name) {
                            json = template.json
                            render()
                        }
                    }
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Render", action: render)
                    .buttonStyle(.borderedProminent)
            }
        }
        .onAppear {
            if store == nil { render() }
        }
    }

    private var editor: some View {
        TextEditor(text: $json)
            .font(.system(size: 12, design: .monospaced))
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .frame(maxHeight: 260)
            .padding(.horizontal, 8)
    }

    @ViewBuilder
    private var preview: some View {
        if let store, let dispatcher {
            FlowPageView(store: store, dispatcher: dispatcher)
                .flowDebugOverlay(store: store)
                .id(renderTick)
        } else {
            Color.clear
        }
    }

    private func render() {
        store = PageStore(
            pageID: "playground",
            loader: StaticPageLoader(data: Data(json.utf8)),
            registry: Demo.makeRegistry()
        )
        if dispatcher == nil {
            dispatcher = Demo.makeDispatcher()
        }
        renderTick += 1
    }
}

/// Ready made JSON examples, one per widget, so anyone can see the contract and
/// start from something that works.
enum PlaygroundTemplates {
    struct Template {
        let name: String
        let json: String
    }

    static let all: [Template] = [
        Template(name: "Full page", json: startingPage),
        Template(name: "title_block", json: wrap("""
        {
          "type": "title_block",
          "data": {
            "title": { "text": "A heading", "font": { "size": 20, "weight": "bold" } },
            "subtitle": "And a subtitle"
          }
        }
        """)),
        Template(name: "image_text_card", json: wrap("""
        {
          "type": "image_text_card",
          "layout": {
            "margin": { "left": 16, "right": 16 },
            "padding": { "top": 10, "left": 10, "right": 10, "bottom": 10 },
            "corner_radius": 12,
            "background": { "hex": "#F8F8F8", "dark_hex": "#1C1C1E" }
          },
          "data": {
            "image": {
              "url": "https://picsum.photos/id/9/144",
              "aspect_ratio": 1,
              "corner_radius": 10
            },
            "title": "A card",
            "subtitle": { "text": "With a subtitle", "color": "#767676" }
          },
          "actions": { "tap": { "type": "toast", "message": "Tapped" } }
        }
        """)),
        Template(name: "banner", json: wrap("""
        {
          "type": "banner",
          "layout": { "margin": { "left": 16, "right": 16 } },
          "data": {
            "image": {
              "url": "https://picsum.photos/800/360",
              "aspect_ratio": 2.2,
              "corner_radius": 14,
              "shimmer": true
            },
            "title": {
              "text": "Overlay title",
              "font": { "size": 22, "weight": "bold" },
              "color": "#FFFFFF"
            }
          }
        }
        """)),
        Template(name: "button_row", json: wrap("""
        {
          "type": "button_row",
          "layout": { "margin": { "left": 16, "right": 16 } },
          "data": {
            "buttons": [
              {
                "title": { "text": "Primary", "color": "#FFFFFF" },
                "bg_color": "#E23744",
                "full_width": true,
                "action": { "type": "toast", "message": "Primary" }
              },
              {
                "title": "Outline",
                "style": "outline",
                "action": { "type": "toast", "message": "Outline" }
              }
            ]
          }
        }
        """)),
        Template(name: "tag_rail", json: wrap("""
        {
          "type": "tag_rail",
          "layout": { "padding": { "left": 16 } },
          "data": {
            "tags": [
              {
                "text": { "text": "One", "color": "#FFFFFF" },
                "bg_color": "#E23744",
                "corner_radius": 14
              },
              { "text": "Two", "corner_radius": 14 },
              { "text": "Three", "corner_radius": 14 }
            ]
          }
        }
        """)),
        Template(name: "stepper_row", json: wrap("""
        {
          "type": "stepper_row",
          "id": "qty",
          "layout": { "padding": { "left": 16, "right": 16 } },
          "data": { "title": "Quantity", "min": 0, "max": 5, "initial": 1 },
          "actions": { "change": { "type": "toast", "message": "Changed" } }
        }
        """)),
        Template(name: "accordion", json: wrap("""
        {
          "type": "accordion",
          "id": "acc",
          "layout": {
            "margin": { "left": 16, "right": 16 },
            "padding": { "top": 14, "left": 14, "right": 14, "bottom": 14 },
            "corner_radius": 12,
            "background": { "hex": "#F8F8F8", "dark_hex": "#1C1C1E" }
          },
          "data": {
            "header": {
              "text": "Tap to expand",
              "font": { "size": 16, "weight": "semibold" }
            },
            "items": [
              { "type": "image_text_card", "data": { "title": "Nested widget" } }
            ]
          }
        }
        """)),
        Template(name: "separator", json: wrap("""
        {
          "type": "separator",
          "data": { "style": "dashed", "insets": { "left": 16, "right": 16 } }
        }
        """)),
        Template(name: "order_card (host widget)", json: wrap("""
        {
          "type": "order_card",
          "layout": {
            "margin": { "left": 16, "right": 16 },
            "padding": { "top": 14, "left": 14, "right": 14, "bottom": 14 },
            "corner_radius": 14,
            "border": { "width": 1, "color": "#EAEAEA" }
          },
          "data": {
            "order_number": {
              "text": "Order #1",
              "font": { "size": 16, "weight": "semibold" }
            },
            "status": {
              "text": {
                "text": "READY",
                "color": "#267E3E",
                "font": { "size": 10, "weight": "bold" }
              },
              "bg_color": "#DCFCE7"
            },
            "items": [ "1 x Magic Keyboard" ],
            "total": "Total 99"
          }
        }
        """)),
        Template(name: "open_bottom_sheet action", json: wrap("""
        {
          "type": "button_row",
          "layout": { "margin": { "left": 16, "right": 16 } },
          "data": {
            "buttons": [
              {
                "title": "Open a sheet",
                "full_width": true,
                "action": {
                  "type": "open_bottom_sheet",
                  "sheet": {
                    "config": { "detents": ["medium"], "corner_radius": 24 },
                    "header": {
                      "widgets": [
                        {
                          "type": "title_block",
                          "layout": {
                            "padding": { "top": 20, "left": 16, "bottom": 8 }
                          },
                          "data": {
                            "title": {
                              "text": "A server driven sheet",
                              "font": { "size": 18, "weight": "bold" }
                            }
                          }
                        }
                      ]
                    },
                    "sections": [
                      {
                        "widgets": [
                          {
                            "type": "image_text_card",
                            "layout": { "margin": { "left": 16, "right": 16 } },
                            "data": { "title": "Sheets reuse the same widgets" }
                          }
                        ]
                      }
                    ],
                    "footer": {
                      "widgets": [
                        {
                          "type": "button_row",
                          "layout": {
                            "padding": {
                              "top": 12,
                              "left": 16,
                              "right": 16,
                              "bottom": 12
                            }
                          },
                          "data": {
                            "buttons": [
                              {
                                "title": { "text": "Done", "color": "#FFFFFF" },
                                "bg_color": "#267E3E",
                                "full_width": true,
                                "action": { "type": "dismiss" }
                              }
                            ]
                          }
                        }
                      ]
                    }
                  }
                }
              }
            ]
          }
        }
        """)),
        Template(name: "Broken widget (see debug)", json: wrap("""
        {
          "type": "image_text_card",
          "data": { "not_title": "title is required, this will fail" }
        }
        """))
    ]

    static let startingPage = wrap("""
    {
      "type": "title_block",
      "layout": { "padding": { "top": 16, "left": 16, "right": 16 } },
      "data": {
        "title": { "text": "Edit me", "font": { "size": 22, "weight": "bold" } },
        "subtitle": "Change the JSON above and tap Render"
      }
    },
    {
      "type": "image_text_card",
      "layout": {
        "margin": { "top": 8, "left": 16, "right": 16 },
        "padding": { "top": 10, "left": 10, "right": 10, "bottom": 10 },
        "corner_radius": 12,
        "background": { "hex": "#F8F8F8", "dark_hex": "#1C1C1E" }
      },
      "data": {
        "image": {
          "url": "https://picsum.photos/id/9/144",
          "aspect_ratio": 1,
          "corner_radius": 10
        },
        "title": "A live rendered card",
        "subtitle": { "text": "Tap me", "color": "#767676" }
      },
      "actions": {
        "tap": {
          "type": "toast",
          "message": "The playground dispatches real actions"
        }
      }
    }
    """)

    private static func wrap(_ widgets: String) -> String {
        """
        {
          "page": {
            "id": "playground",
            "sections": [
              {
                "id": "sandbox",
                "layout": { "item_spacing": 8, "insets": { "top": 12 } },
                "widgets": [
        \(widgets)
                ]
              }
            ]
          }
        }
        """
    }
}
