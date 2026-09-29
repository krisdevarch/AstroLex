# AstroLex: Engine Alternatives to Unity

> **Date:** 29 September 2026. **Question:** the plan fixes Unity (solutions doc §2.3: "Alternatives: none"). For a mobile-first game with a tiny budget, built by one owner and AI coding agents, is there a freer engine that fits, and what does switching cost later?
> **Method.** Web research over 2024–2026 sources. Several official domains (unity.com, godotengine.org, defold.com, w4games.com) could not be fetched directly from this session, so some figures come from search excerpts of official pages and secondary coverage. Anything marked *reported* should be verified on the vendor's page before budgeting.
> **Short answer.** Unity is genuinely free for AstroLex today, so the decision is not about money. Godot 4 is the recommended engine because its project format, tooling and licence fit an agent-driven solo project better, and its console path is a paid export layer rather than a rewrite. Defold is a strong second, and becomes first if the letters are pre-rendered rather than real 3D. Unity stays the pragmatic fallback.

---

## 1. Requirements the engine has to meet

From Draft 3 and the solutions document:

- iOS and Android first; PC/Steam cheap to add; console (Switch, PlayStation, Xbox) later.
- Portrait, one-handed touch. About 20–25 animated 3D letter meshes over hand-painted 2D parallax backdrops, particles, 60 fps on a mid-range phone, no thermal throttling in 15 minutes.
- Simple drift physics (no rigid-body simulation needed), seeded and deterministic for replays and ghosts.
- Adaptive music layers, haptics.
- In-app purchases (one-time unlock, later cosmetics), optional rewarded ads, cloud save, remote config, analytics, a daily puzzle with a shareable image.
- **Agent-driven development:** text-based scene and asset formats that diff in git, headless and CLI builds for CI, a scripting language LLMs know well, fast test loops.
- Very small budget. Preference for no licence fees and no revenue-threshold cliffs.

## 2. Unity's licensing as of September 2026

- **Personal is free** up to US$200,000 of trailing-12-month revenue plus funding. Pro is required from $200,001 to $25M at **$2,310 per seat per year** (a 5% rise on 12 January 2026). Enterprise above $25M.
- **The Runtime Fee was cancelled** on 12 September 2024. Seat-based subscriptions are the model, including for Unity 6. Unity also stated that if Editor terms change, you may keep using your current version under the terms you agreed to.
- **Seats on Personal are unlimited** (the previous three-seat cap was removed in late 2025). **The "Made with Unity" splash is optional** on all plans from Unity 6.
- **Unity 6.3 LTS** shipped 5 December 2025, supported to December 2027. Unity 6.0 LTS reaches end of life 16 October 2026. "Unity 7" is reported as a non-breaking continuation with a beta expected around December 2026.
- **Unity Gaming Services** have free tiers (Analytics to 50,000 MAU, 25 GB cloud storage, 100 Mac build minutes) and are pay-as-you-go above that.

**So is it free?** Yes, at AstroLex's scale, with no splash screen and no seat limit. The residual costs are: a $2,310 a year cliff at $200K; a Unity account and a revenue-audited licence; a project format (YAML scenes and prefabs with GUID references and `.meta` files) that is workable but noisier for agents and git than Godot's or Defold's; and trust, since the terms changed once already and the company has cut about 3,200 jobs since 2022 while pivoting toward its Vector advertising platform. None of these is a blocker. They are the reason to prefer an open engine if one meets the brief.

## 3. The candidates

### 3.1 Godot 4.7 (recommended)

- **Licence and cost.** MIT. No fees, no thresholds, no account, no telemetry.
- **Releases.** 4.5 (September 2025: shader baker to cut startup shader stalls, screen reader, iOS Metal exports default to A12+), 4.6 (January 2026: Jolt physics default for new 3D projects, node IDs, LibGodot), 4.7 (June 2026: HDR output, virtual joystick, new asset store). Current 4.7.1.
- **Mobile.** The Godot Foundation now has a dedicated mobile team. Its April 2026 update reports Android device mirroring in the editor, iOS export safeguards, native Android crash symbols, Perfetto profiling and Vulkan driver workarounds that "cut crash rates dramatically". Google's own developer site documents the three renderers. The **Mobile (Vulkan) renderer** is the right choice for 3D on 2018+ phones; a 2026 issue thread shows 80–90 fps on a mid-range Galaxy A35. Google Play's 16 KB page-size mandate (1 November 2025) is met by 4.5+ templates. **iOS export requires a Mac with Xcode.**
- **3D fit.** Fully adequate for 20–25 animated meshes with GPU particles and hand-rolled drift. Use pre-built glTF letter meshes (or `TextMesh` for extruded geometry), not dynamic `Label3D`, which can create a material per glyph. Rendering a 3D scene over a 2D parallax layer via `SubViewport` or a `CanvasLayer` HUD is standard.
- **Audio and haptics.** `AudioStreamInteractive`, `AudioStreamSynchronized` and `AudioStreamPlaylist` (since 4.3) give middleware-style clip switching and layering without FMOD. Built-in haptics expose only duration; use the `godot-haptics` plugin for light, medium and heavy on both platforms.
- **In-app purchases.** Android: first-party Google Play Billing plugin. iOS: the official plugin is still StoreKit 1, which Apple deprecated in 2024. Use **godot-iap** (OpenIAP: StoreKit 2 on iOS 15+, Play Billing v8+ on Android, one GDScript API) or **GodotApplePlugins** (StoreKit 2, Game Center, Sign in with Apple). Google requires Billing Library 8 for all new apps and updates by 31 August 2026, so plugin freshness matters.
- **Ads.** Poing Studios' AdMob plugin (Godot 4.2+, consent management, rewarded, mediation). No first-party ironSource or AppLovin plugin.
- **Analytics, backend, cloud save.** Firebase Analytics and Remote Config plugins exist. Play Games Services (sign-in, achievements, saved games) is Android-only; Game Center via GodotApplePlugins on iOS. Cross-platform cloud save means calling an HTTP backend (Supabase, PlayFab, Nakama) from GDScript. Straightforward, but glue you own.
- **Consoles.** Godot itself cannot ship console templates. **W4 Consoles** (from the company founded by Godot's lead developers) is a drop-in export layer for Godot 4.3+ covering Switch, Xbox Series and PS5, with **Switch 2 in beta since October 2025**. Its Starter tier is capped at $300K annual revenue; secondary sources *report* $800 a year per console or $2,000 a year for all three, and Premium Support at $7,000 a year. Alternatives are porting houses listed on Godot's consoles page.
- **PC and Steam.** GodotSteam GDExtension for Godot 4.4+. No third party needed.
- **Scripting and LLMs.** GDScript (Python-like), C#, C++ via GDExtension. **.NET export for mobile is still experimental** (Android via Mono, iOS only via NativeAOT), so **use GDScript for mobile**. A 2026 roundup ranks Claude models best at GDScript with the least drift into Godot 3 syntax, while noting all models still hallucinate APIs in fast-moving subsystems. Several MCP servers now let Claude Code drive a live editor (create scenes, attach scripts, run, read debugger output).
- **Formats and CI.** `.tscn` and `.tres` are text and diff cleanly. Headless export is one command (`godot --headless --export-release`). Docker images and GitHub Actions exist; gdUnit4 has an official action with JUnit output; GUT runs headless.
- **Shipped mobile evidence (2025–26).** Rift Riff (October 2025), Cassette Beasts mobile (January 2025), Kamaeru (December 2025), Dome Keeper mobile due December 2026. Directly relevant: **LetterLogic**, an open-source Wordle-style word game on Godot 4.7 and GDScript, live on Google Play, with GitHub Actions for AAB build, Play deployment and itch.io web export. Observers note that shipped Godot mobile titles so far are premium or pay-once rather than live-service, which is a fair warning for season-pass plans.
- **Pain points.** Mac required for iOS. iOS IAP relies on community plugins. No unified cloud save or analytics. Android Vulkan driver variance on cheap phones (mitigated but real). Web export is heavy for a phone browser.

### 3.2 Defold 1.13 (strong second)

- **Licence.** Free, source-available "Defold Licence" derived from Apache 2.0. You may commercialise games and extensions, not the engine itself. No fees, no thresholds.
- **Releases.** 1.13.0 (June 2026: Vulkan default on Android, smaller binaries, morph targets) and 1.13.1 (August 2026: first-class light components, instanced models, editor HTTP API).
- **Mobile.** Its heartland. Builds are 3–5 MB before compression. Lua 5.1 interpreted on iOS 64-bit (no JIT), fine for a word game.
- **3D fit.** glTF import, instancing, 3D textures. **No built-in PBR lighting model**: you write the lighting shader. Lights only became first-class in August 2026. For stylised unlit or toon letters this is acceptable; for anything richer it is extra work with less community precedent.
- **Services.** The Foundation itself maintains the extensions: IAP (iOS, Google Play, Amazon), AdMob, ironSource, AppLovin, Firebase Analytics and Remote Config, GameAnalytics, Steam. This is the best-maintained mobile services stack of any free engine. Whether the IAP extension has moved to StoreKit 2 could not be confirmed and must be checked. Haptics are the weak spot (separate, poorly maintained extensions).
- **Consoles.** **Switch, PS4 and PS5 builds are provided free** to developers approved by Nintendo or Sony (the former monthly source-access fee was removed). **No Xbox yet**: DX12 work started in 2025, paused, and is a 2026 focus item.
- **Scripting and agents.** Lua, which LLMs know well, though the Defold API surface is niche. Defold publishes an official **"Using AI coding agents with Defold"** manual. All project files are Protobuf text; `bob.jar` builds and bundles every platform headlessly, with a GitHub Action available.
- **Shipped evidence.** Family Island (Melsoft, 50M+ Android installs) and other large free-to-play titles. No specific 2025–26 indie *word* game publicly attributed to Defold was found.
- **Pain points.** Smaller community and asset pool. 3D only recently first-class. No Xbox. GUI system is more manual. Lua-only.

### 3.3 Unity 6.3 LTS (fallback)

Mature IAP, ads, analytics, remote config and cloud save; first-party console support; the largest LLM corpus. Costs as in §2: the $200K cliff, licensing trust, and heavier project files that produce noisier agent diffs and merge conflicts. If the owner already has years of Unity experience, staying is defensible. If not, the reasons to start here are weaker than they were in 2023.

### 3.4 Not recommended, and why

| Engine | Status (2026) | Why not for AstroLex |
|---|---|---|
| **Unreal 5.8** | Royalty-free to $1M lifetime per product, then 5% (3.5% with Epic Store day-and-date). 5.8 is the last UE5 release; UE6 early access targeted end-2027. | Empty Android APK is 40–60 MB. Blueprints and most assets are binary `.uasset`, which agents cannot review or merge in PRs. Overkill. |
| **Cocos Creator 3.8** | MIT, TypeScript, JSON scenes, CLI builds, Switch since 2022, official AdMob, community StoreKit 2 IAP. **Acquired by SUD for $72M in November 2025**; Cocos 4 promised as fully open source with an AI-oriented IDE. | A credible fourth choice. TypeScript is excellent for LLMs. But English documentation and community are thinner than Godot's, and the ownership transition is a live risk. |
| **Flutter + Flame, React Native + Three** | Excellent app shells, official IAP packages. `flame_3d` depends on the experimental Flutter GPU and is "not production ready". Expo and react-three-fiber version mismatches broke device builds in 2025. | No 3D path, no console path. Viable only for a fully 2D pre-rendered client. |
| **Bevy 0.19** | MIT/Apache, Rust, new text scene format. Maintainers: mobile is "possible, not easy", blocked by low adoption and Rust's lack of console platform-holder support. | No IAP or ads ecosystem, no editor. |
| **Web tech (Three.js, Babylon.js 8, PlayCanvas, Phaser 4) + Capacitor** | RevenueCat has a Capacitor IAP plugin. Apple allows embedded HTML5 games only with IAP and standard WebKit; Google tightened minimum-functionality enforcement in 2025–26. | WebView-bound performance on budget Android; store-policy risk; no console path. **Right for the web prototype and a web Daily Signal, wrong for the shipping mobile client.** |
| **MonoGame / FNA** | 3.8.5 (August 2026) supports iOS, Android, PS4/5, Xbox, Switch and Switch 2 for authorised developers. | A framework, not an editor. Every tool is yours to write. |
| **LÖVE, Solar2D** | LÖVE powered Balatro's mobile ports; LÖVE 12 still unreleased as of February 2026. Solar2D alive but small. | 2D only. |
| **Stride, O3DE** | Stride mobile has a history of broken builds; O3DE is an AAA-scale C++ engine. | Not a fit. |

## 4. Comparison table

| Engine | Licence / cost | Mobile | 3D fit | IAP / ads | Console path | Script and LLM fluency | Text formats and headless CI | Verdict |
|---|---|---|---|---|---|---|---|---|
| **Godot 4.7** | MIT, $0 | Mature; Mac needed for iOS; Foundation mobile team | Good (Mobile renderer, Jolt, GPU particles) | Play Billing first-party; StoreKit 2 via godot-iap or GodotApplePlugins; AdMob (Poing) | W4 Consoles, about $2K/yr Starter (*reported*) | GDScript; best LLM results; MCP editors | Yes, first-class | **1st** |
| **Defold 1.13** | Free, source-available | Excellent; 3–5 MB builds | Adequate for stylised; lighting DIY | Official extensions for everything | Switch/PS free with approval; no Xbox | Lua; official agent manual | Yes, first-class | **2nd** |
| **Unity 6.3 LTS** | Free under $200K; Pro $2,310/seat/yr | Best-in-class | Excellent | Best ecosystem | First-party | C#; largest corpus | YAML + GUIDs; batch mode | **3rd, fallback** |
| Cocos Creator 3.8 | MIT | Good | Good | Official AdMob; community IAP | Switch | TypeScript | JSON scenes; CLI | 4th; ownership risk |
| Unreal 5.8 | 5% over $1M | Heavy | Overkill | Built in | First-party | C++/Blueprints; binary assets | Poor for agents | No |
| Web + Capacitor | MIT | WebView-bound | OK on iOS, weak on cheap Android | RevenueCat | None | JS/TS | Yes | Prototype and web only |
| Bevy, Flutter/Flame, MonoGame, LÖVE, Solar2D, Stride, O3DE | Free | Varies | Varies | Weak or none | Varies | Varies | Varies | No |

## 5. Recommendation for AstroLex

**Build the shipping game in Godot 4.7 with GDScript.** It is the only free engine that natively covers the whole brief in one project: 2D parallax backdrops, a 3D layer for the letters, touch, interactive music, haptics through a small plugin, text scene files that diff like code, first-class headless export and test runners, a growing agent-tooling story, and a paid but drop-in console path. Concrete practices:

1. **Keep every store, ad, analytics and save call behind a thin GDScript interface** from day one, so a plugin swap (or an engine swap) is a one-file change. This is the solutions document's own G8 idea, applied where it matters.
2. **Keep the rules engine and all content tooling out of the engine.** The spawner logic, scoring, Babel's anagram validator, the blocklist scan, clue checks and the solver bot should be plain code with no scene dependencies: GDScript modules tested headlessly with gdUnit4 for the runtime rules, and a Python package under `tools/` for the content pipeline. AI agents are strongest exactly there, and CI runs it in seconds.
3. **Use the Mobile renderer, and test on a Mali mid-range Android early.** Keep the Compatibility renderer as a fallback quality profile, which also stops you from relying on Forward+-only effects.
4. **Budget a Mac.** A used Mac mini or paid macOS CI minutes. There is no production route to an iOS build without one, in any engine.
5. **Keep pre-rendered letters as a designed fallback.** Keep the letter meshes and a Blender render script in the repo. If mid-range profiling fails, or you decide to move to Defold for its services stack, the switch becomes an asset-pipeline change rather than an art redo. Do not make fake 3D the primary plan: real low-poly letters with unshaded or toon materials over a 2D layer cost almost nothing in Godot and give the intended look, free-axis tumble and cheap depth cues.
6. **Build the first prototype and the web Daily Signal with Three.js or PlayCanvas**, not with the engine. A browser prototype loads instantly on any phone, is shareable by link for playtesting, and is the format every recent small-team word-game breakout used. Godot's web export is large for a phone browser. The rules core from point 2 can be ported once it settles.

**Choose Defold instead if** you decide the letters will be pre-rendered sprites, or if the maintained services stack (IAP, AdMob, ironSource, AppLovin, Firebase, all by the Foundation) matters more to you than 3D flexibility and Xbox. **Stay on Unity if** you already have deep Unity experience and would spend more than a few weeks learning Godot; the licence is free at this scale, and only the format friction and the trust question argue against it.

## 6. What switching to console costs later

Low in code, non-trivial in money and process. W4 Consoles is an export layer: the project, scenes and GDScript stay the same. The costs are the W4 subscription (*reported* about $2,000 a year for three consoles under $300K revenue), platform-holder approval and NDAs (required in every engine), and porting work that is engine-independent: controller aiming for the tether, platform compliance (suspend and resume, save-data rules, user switching), stripping mobile-only plugins behind the service interfaces, and certification. If W4 disappeared, the fallback is a porting house, not a rewrite. PC and Steam need no third party at all.

## 7. Costs to budget regardless of engine

| Item | Cost |
|---|---|
| Apple Developer Program | $99 per year |
| Google Play developer account | $25 once |
| A Mac for iOS builds | A used Mac mini, or macOS CI minutes |
| Reference phones | One mid-range Android (Mali GPU) and the oldest iPhone you intend to support |
| Console later (Godot) | W4 Consoles subscription, *reported* about $2,000 per year |
| Console later (Defold) | Free engine builds once approved by Nintendo or Sony; no Xbox |
| Unity if revenue passes $200K | $2,310 per seat per year |

## Sources

- Unity: pricing updates (unity.com/products/pricing-updates); Runtime Fee cancellation (unity.com/blog/unity-is-canceling-the-runtime-fee); Game World Observer, 12 Sep 2024 (gameworldobserver.com/2024/09/12/unity-cancels-runtime-fee-new-pricing-changes); CG Channel, Nov 2025 price rise and unlimited Personal seats (cgchannel.com/2025/11/price-of-paid-unity-subscriptions-to-rise-but-free-subs-extended/); 80.lv, 2026 price changes (80.lv/articles/unity-announces-its-upcoming-2026-price-changes); Unity 6.3 LTS (unity.com/blog/unity-6-3-lts-is-now-available); Unity Analytics billing (docs.unity.com/ugs/en-us/manual/analytics/manual/billing).
- Godot: 4.5 (phoronix.com/news/Godot-4.5-Released); 4.6 (alternativeto.net/news/2026/1/godot-4-6-debuts-modern-theme-jolt-physics-node-ids-and-libgodot-embed); 4.7 (github.com/godotengine/godot/releases/tag/4.7-stable); mobile update April 2026 (godotengine.org/article/godot-mobile-update-apr-2026/); Android renderers guide (developer.android.com/games/engines/godot/godot-renderers); iOS export docs (docs.godotengine.org/en/4.5/tutorials/export/exporting_for_ios.html); C# platform state (godotengine.org/article/platform-state-in-csharp-for-godot-4-2/); Google Play Billing plugin (github.com/godot-sdk-integrations/godot-google-play-billing); StoreKit 1 deprecation issue (github.com/godot-sdk-integrations/godot-ios-plugins/issues/68); godot-iap (github.com/hyochan/godot-iap); GodotApplePlugins (github.com/migueldeicaza/GodotApplePlugins); Poing AdMob (github.com/poingstudios/godot-admob-plugin); godot-haptics (github.com/kyoz/godot-haptics); consoles page (godotengine.org/consoles/); W4 Consoles (w4games.com/w4consoles) and pricing post (w4games.com/blog/w4-games-news-1/w4-games-announces-pricing-model-for-console-ports-5); GameFromScratch on W4 pricing (gamefromscratch.com/w4-games-release-godot-w4-console-pricing/); GodotSteam (godotengine.org/asset-library/asset/2445); LLM ranking for GDScript (summerengine.com/blog/best-llm-for-godot); Godot MCP (github.com/hi-godot/godot-ai); godot-ci action (github.com/marketplace/actions/godot-ci); gdUnit4 action (github.com/marketplace/actions/gdunit4-test-runner-action); LetterLogic (github.com/OpenGameStack-Games/LetterLogic); Rift Riff (godotengine.org/showcase/rift-riff/); Cassette Beasts (godotengine.org/showcase/cassette-beasts/); Dome Keeper mobile (techtimes.com/articles/327340/20260911/dome-keeper-mobile-pre-orders-open-mining-roguelite-targets-december-launch.htm); Godot mobile in 2026 (ziva.sh/blogs/godot-mobile).
- Defold: licence (defold.com/license/); 1.13.0 (defold.com/2026/06/22/Defold-1-13-0/); 1.13.1 (defold.com/2026/08/17/Defold-1-13-1/); 2026 look ahead (defold.com/2026/02/10/Defold-A-look-ahead-for-2026/); PBR manual (defold.com/manuals/physically-based-rendering/); extension-iap (github.com/defold/extension-iap); ironSource and AppLovin extensions (defold.com/extension-ironsource/, defold.com/extension-applovin/); console access free (forum.defold.com/t/nintendo-switch-and-sony-playstation-source-code-access-is-now-free/75374); AI agents manual (defold.com/manuals/ai-agents/); Bob (defold.com/manuals/bob/); Melsoft partnership (defold.com/2020/08/11/Melsoft-Games-partners-with-the-Defold-Foundation/).
- Unreal: royalty change (cgchannel.com/2024/10/epic-games-to-cut-royalty-rate-on-unreal-engine-games/); 5.8 (unrealengine.com/news/unreal-engine-5-8-is-now-available); uasset and AI workflows (sackbirdstudios.com/news/uasset-binary-problem).
- Cocos: SUD acquisition (pocketgamer.biz/sud-acquires-cocos-in-a-72m-deal-to-deepen-platform-integration/); CLI publish (docs.cocos.com/creator/3.8/manual/en/editor/publish/publish-in-command-line.html).
- Others: flame_3d (pub.dev/packages/flame_3d); Bevy mobile discussion (github.com/bevyengine/bevy/discussions/20998); Capacitor games guide (capacitorjs.com/docs/guides/games); RevenueCat Capacitor (github.com/RevenueCat/purchases-capacitor); Apple App Review Guidelines 4.7 (developer.apple.com/app-store/review/guidelines/); MonoGame 3.8.5 (monogame.net/blog/2026-07-15-3.8.5-release-2026/); LÖVE 12 status (love2d.org/forums/viewtopic.php?t=96418).
