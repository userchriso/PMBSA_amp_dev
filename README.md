# PMB Prosthetics SA (PMBSA)

Native iOS app, bundle ID `com.promptai.PMBSA`. Marketing version 1.0, Swift 5.0, iOS deployment target 26.5 (as configured in `project.pbxproj` — intentional, not a typo).

## What it is

A reference/companion app for South African medical scheme Prescribed Minimum Benefits (PMBs), focused on prosthetics/orthotics coverage for amputees. It's built around a hosted web app (`https://ampedlifepmbsa.netlify.app`) wrapped in a native shell, plus a native AI chat assistant specialized in PMB rules. Almost all of the actual PMB content (text, articles, whatever's on the Netlify site) lives outside this repo — the native code here is the shell, navigation, quick links, and the assistant.

## Architecture — two features bolted together

**1. WebView wrapper** (`PMBSA/ContentView.swift`)
The main screen is a `WKWebView` loading the Netlify site, with a bottom toolbar (back / forward / quick links / assistant / share / reload). Supporting pieces in the same file:
- `WebViewStore` — `@Observable` holder for the live `WKWebView` reference, so SwiftUI buttons can drive back/forward/reload/loadURL without the view owning the web view directly.
- `WebView` — `UIViewRepresentable` wrapping `WKWebView`.
- `WebView.Coordinator` — `WKNavigationDelegate`. Tracks loading/can-go-back/forward state and intercepts link clicks: anything to `youtube.com`, `youtu.be`, `integratedlife.co.za`, or `ilive.today` is forced out to Safari instead of loading in the in-app web view (see `externalDomains` in `Coordinator.webView(_:decidePolicyFor:decisionHandler:)`).
- `QuickLinksView` — sheet listing the 7 SA medical schemes it knows about (Discovery Health, Bonitas, Fedhealth, Momentum Health, Bestmed, Medshield, GEMS). Scheme links always open in Safari (not in-app) by design — see the button in `QuickLinksView`. Also has a support-email `mailto:` link and links to Integrated Life and the AmpedLife YouTube channel.
- `InAppBrowserView` — a separate sheet with its own `WebView`/`WebViewStore` pair for viewing a scheme (or other) URL in-app. Currently used for `selectedMedicalAidURL`, though at present nothing in `QuickLinksView` routes through it — scheme taps open Safari directly (see Developer Notes below).

Full behavior is documented inline via `///` doc comments in `ContentView.swift`.

**2. Native AI assistant** (`PMBSA/PMBAssistantView.swift` + `PMBSA/ClaudeService.swift`)
Presented as a sheet (`showAssistant`) from `ContentView`. `ClaudeService` is an `@Observable` class that calls the Anthropic Messages API directly from the client:
- `POST https://api.anthropic.com/v1/messages`
- model `claude-haiku-4-5-20251001`, `max_tokens: 1024`
- a hardcoded system prompt specializing the assistant in SA PMB/CDL/DTP rules, prosthetics coverage, claims/appeals, and the same 7 medical schemes listed above.

`PMBAssistantView` is the chat UI: message list, typing indicator, input bar, and a `WelcomeCard` with 4 canned suggestion prompts shown when there's no message history yet.

Full behavior is documented inline via `///` doc comments in `ClaudeService.swift`.

## Project structure

```
PMBSA.xcodeproj/            Xcode project (file-system-synchronized groups — see note below)
PMBSA/
  PMBSAApp.swift             @main entry point, just wraps ContentView in a WindowGroup
  ContentView.swift          Main screen: WebView wrapper, toolbar, QuickLinksView, InAppBrowserView, WebViewStore/WebView/Coordinator
  PMBAssistantView.swift     Chat UI for the PMB Assistant sheet (WelcomeCard, BubbleView, TypingIndicatorView, ErrorView)
  ClaudeService.swift        Calls the Anthropic API directly; holds chat state
  Item.swift                 Unused SwiftData template leftover — see Developer Notes
  Secrets.swift               NOT IN REPO (gitignored) — you must create this locally, see Setup below
  Assets.xcassets/            App icon + accent color only, nothing else
PMBSATests/                   Swift Testing target — template stub, no real tests
PMBSAUITests/                 XCTest UI target — template stub (empty test + launch performance test), no real coverage
PMBSAApp.swift                 Orphan duplicate at repo root — NOT part of any build target, see Developer Notes
```

## Setup — required before the project will build

`ClaudeService` references `Secrets.claudeAPIKey`, and `Secrets.swift` is gitignored (`**/Secrets.swift`, `Secrets.swift` in `.gitignore`). **A fresh checkout will not compile** until you create it yourself:

Create `PMBSA/Secrets.swift`:

```swift
enum Secrets {
    static let claudeAPIKey = "sk-ant-..."
}
```

Use an Anthropic API key with access to `claude-haiku-4-5-20251001`.

## Running it

1. Create `PMBSA/Secrets.swift` as above (first-time setup only).
2. Open `PMBSA.xcodeproj`.
3. Pick a simulator or device.
4. Cmd+R.

No SPM/CocoaPods dependencies, no build scripts, no environment config beyond the above.

## Code docs

The two classes that hold actual state/logic (as opposed to pure view code) are documented inline with `///` doc comments — read these for full behavioral detail:

- **`ClaudeService`** (`PMBSA/ClaudeService.swift`) — chat state (`messages`, `isLoading`, `errorMessage`), `send(_:)`, `clearHistory()`, and the private `callAPI()` request/response handling.
- **`WebViewStore`** (`PMBSA/ContentView.swift`) — the observable bridge between SwiftUI controls and the live `WKWebView`.
- **`WebView` / `WebView.Coordinator`** (`PMBSA/ContentView.swift`) — the `UIViewRepresentable` and its navigation delegate, including the external-domain redirect logic.

Everything else (`PMBAssistantView` and its subviews, `QuickLinksView`, `InAppBrowserView`, `MedicalAid`) is straightforward SwiftUI view code without hidden behavior worth separately documenting.

## Developer notes / known oddities

- **Duplicate `PMBSAApp.swift`.** There are two copies with identical content: `PMBSA/PMBSAApp.swift` (the real one, part of the app target) and `./PMBSAApp.swift` at the repo root. This project uses Xcode 16 file-system-synchronized groups (`PBXFileSystemSynchronizedRootGroup`) scoped only to `PMBSA/`, `PMBSATests/`, and `PMBSAUITests/`, so the root-level copy is **not part of any build target** — it's inert. Likely leftover from the "Add files via upload" commit in git history. Safe to delete; not urgent.
- **`Item.swift` is unused.** It defines a SwiftData `@Model final class Item` — the default Xcode template's SwiftData boilerplate. There's no `ModelContainer`, no `import SwiftData` in `PMBSAApp.swift`, and nothing else in the codebase references `Item`. It's not part of the app's actual data model (the app doesn't persist anything locally). Safe to delete whenever you touch this area.
- **Test coverage is template-only.** `PMBSATests` and `PMBSAUITests` both still contain the stock Xcode example tests (empty test in `PMBSATests`, empty test + launch performance test in `PMBSAUITests`). No real assertions exist yet.
- **`QuickLinksView` scheme links bypass `InAppBrowserView`.** The medical-aid-scheme buttons call `UIApplication.shared.open(aid.url)` directly (opens Safari) rather than setting `selectedURL`/`showingInAppBrowser` to route through `InAppBrowserView`. `InAppBrowserView` exists and is wired up in `ContentView`'s sheet modifiers, but nothing currently triggers it. <!-- TODO: verify whether this is intentional (scheme sites are "external" by design) or leftover from an earlier version that did use the in-app browser -->
- **API key is sent from the client.** `ClaudeService` calls the Anthropic API directly from the app with the key embedded via `Secrets.swift`, baked into the shipped binary. There's no backend proxy. Worth knowing if this ever needs to ship to the App Store — the key is extractable from the binary.
- **No local PMB data.** All PMB/DTP/CDL reference content is either on the external Netlify site or inside the `systemPrompt` string in `ClaudeService.swift`. There's no bundled JSON or local database of scheme rules.
