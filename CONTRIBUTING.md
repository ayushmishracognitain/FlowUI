# Contributing to Flow-UI

Flow-UI is free and open source under the MIT licence, and contributions are welcome.
You do not need permission to start: open an issue, or send a pull request.

Thanks for taking the time. This file covers what the project expects so a pull request
lands without a round of avoidable review comments. The conventions below are firm, but
they are about the code, never about you. Participation is covered by the
[Code of Conduct](CODE_OF_CONDUCT.md).

## Getting set up

```
git clone https://github.com/ayushmishracognitain/FlowUI.git
cd FlowUI
swift build
swift test
```

Xcode 16 or newer is required: the package builds in the Swift 6 language mode.

The demo app in `Examples/FlowDemo` references the package locally, so it always builds
against your working copy. It is the fastest way to see a change on screen.

## Before you open a pull request

All four of these must pass. CI runs the same set.

```
swift build
swift test
swiftlint --strict
xcodebuild -scheme FlowUI -destination 'generic/platform=iOS Simulator' build
```

## Conventions

These are not negotiable, because the whole codebase already follows them.

- **Vocabulary is page, section, widget.** Never "snippet", never "component".
- **No em-dashes anywhere.** Not in Markdown, code comments, doc comments, commit
  messages or the docs site. Use commas, colons, periods or parentheses. The docs site
  build fails on one.
- **Every public API gets a doc comment.** Every widget gets a preview and a JSON example
  in its doc comment.
- **JSON keys are snake_case.** Decoding is hand written `Decodable`, always
  `decodeIfPresent` with a default, arrays through `LossyArray`. No macro dependency.
- **Commit messages** are first person, plain, senior engineer tone, scoped to one logical
  change. No co-author trailers, no tool attributions.

## Adding a widget

You almost certainly do not need to change the framework. See
[ADDING_A_WIDGET.md](ADDING_A_WIDGET.md): model the payload, write the view, register it.
Widgets that belong in the starter library go in `Sources/FlowWidgets` with a test in
`Tests/FlowWidgetsTests`.

## Changing the JSON contract

The contract is public API. Additive fields are safe and ship in a minor version.
Anything that changes the meaning of an existing key, or makes a previously valid payload
invalid, is a major version and needs discussion in an issue first.

Update [SCHEMA.md](SCHEMA.md) in the same pull request.

## Accessibility

New views carry their weight:

- Meaningful images take an `alt`.
- Controls you build yourself get a label.
- Backend font sizes go through the theme so they scale with Dynamic Type.

## Reporting a bug

Include the JSON payload that reproduces it. That is usually the whole bug report, and
the Playground in the demo app renders anything you paste, so it is easy to confirm.

## Author

Flow-UI is maintained by [Ayush Mishra](https://www.cognitain.in/ayushmetaverse).
