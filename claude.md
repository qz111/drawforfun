# Core Background
- **Project**: A children's coloring app designed for iPad (target audience: 3-8 years old).
- **Tech Stack**: Flutter (Dart).

# Environmental Constraints (CRITICAL)
- **Current OS**: Windows.
- **Testing Method**: Prioritize Windows Desktop (`flutter run -d windows`) or Chrome Web for local previews.
- **Prohibited Actions**: NEVER attempt to run macOS/iOS-exclusive build commands (e.g., `pod install`, `xcodebuild`) in the terminal, as they will fail on this Windows environment.

# Architecture & Coding Standards
- **State Management**: Keep it simple. Use `Provider` or built-in `State`/`ValueNotifier` as needed.
- **Code Style**: Maintain a modular structure. Separate UI components from business logic (e.g., image processing, canvas drawing). Include clear comments to explain complex logic.
- **UI/UX Principles**: Strictly adhere to a child-friendly, minimalist design (large buttons, vibrant colors, rounded corners). Do NOT implement complex sliders or parameter settings for the end user.

# AI Behavior Guidelines
- **Autonomous Debugging**: After writing or modifying code, proactively run `flutter analyze` or `flutter test` in the terminal to check for errors and fix them automatically before reporting back to me.
- **Ask Before Action**: Before introducing heavy third-party packages or performing massive refactoring, explain your reasoning and wait for my approval.
- **Visual Blindness**: Acknowledge that you lack visual perception. When modifying UI styles, brush realism, or image processing filters, provide the code and wait for my manual visual QA feedback. Do not blindly guess the visual outcome.