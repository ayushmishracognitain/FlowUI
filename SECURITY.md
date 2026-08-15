# Security Policy

Flow-UI renders screens from data your backend sends, and it ships inside other
people's apps. That makes decoding and action dispatch worth reporting on if you
find something wrong.

## Supported versions

| Version | Supported |
| --- | --- |
| 1.0.x | Yes |
| Older previews | No |

Fixes land on the latest minor release. There are no long term support branches.

## Reporting a vulnerability

Please do not open a public issue for a vulnerability.

Report it privately, either way works:

- Open a draft advisory through GitHub, on the Security tab of the repository.
- Email ayush.mishra@cognitain.in with `Flow-UI security` in the subject.

Include enough to reproduce it. For Flow-UI that usually means the JSON payload,
the widget or action type involved, and what you expected to happen instead.

## What to expect

- An acknowledgement within three working days.
- An assessment of severity and affected versions once the report is confirmed.
- A fix released as a patch version, with credit in the changelog if you want it.

Please give a reasonable window to ship a fix before disclosing publicly.

## Scope

In scope: the `FlowCore`, `FlowRender` and `FlowWidgets` targets in this
repository. Decoding of untrusted payloads, action dispatch, and anything that
could crash a host app or leak data across widgets is worth reporting.

Out of scope: the demo app fixtures in `Examples/`, and anything that requires a
host app to deliberately misconfigure its own loader.

Flow-UI performs no network calls of its own and collects no data. Transport
security belongs to the `PageLoader` you implement.
