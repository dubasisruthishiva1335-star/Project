# File Inspector (Flutter)

An AI-powered file/image/document analyzer. Upload a file and get back a
structured report: summary, detected content, extracted text, a structure
sketch, recommendations, and a confidence score.

## Supported file types

- Images (png, jpg, jpeg, gif, webp) — sent directly to Claude as an image
- PDF — sent directly as a document; Claude reads it natively
- DOCX — text extracted locally (unzips the file and reads word/document.xml)
- CSV — parsed locally into a column/row profile
- XLSX / XLS — parsed locally into a per-sheet column/row profile
- Anything else — read as plain text

## Setup

    flutter pub get
    flutter run

On first upload you'll be asked for an Anthropic API key. Get one at
https://console.anthropic.com/ — it's stored locally on-device via
shared_preferences and sent directly from the app to
https://api.anthropic.com/v1/messages.

Before shipping this to real users: embedding an API key in a client
app means anyone who inspects the app's traffic or storage can extract it.
For production, replace the direct http.post call in
lib/analyzer_service.dart with a call to your own backend, and have your
backend hold the API key and call Anthropic server-side.
