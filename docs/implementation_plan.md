# SDXL Style Preset Implementation

## Goal Description
Fully adopt official SDXL style presets in the UI and API, replacing previous custom style descriptions.

## User Review Required
None.

## Proposed Changes
### Services
#### [MODIFY] [stability_service.dart](file:///Users/buyang/.gemini/antigravity/playground/chrono-belt/chrono_app/lib/services/stability_service.dart)
- Update `generateImage` to accept `String? stylePreset` instead of generic `style`.
- Add `style_preset` to the API request text fields (Multipart) or JSON body.
- Remove the logic that appended "style: $style" to the prompt text.

### Feature: Character Creation
#### [MODIFY] [character_creation_page.dart](file:///Users/buyang/.gemini/antigravity/playground/chrono-belt/chrono_app/lib/features/create/character_creation_page.dart)
- **Update UI Options**: Replace current style list with official SDXL presets:
    - `3d-model` ("3D Model")
    - `anime` ("Anime")
    - `comic-book` ("Comic Book")
    - `digital-art` ("Digital Art")
    - `fantasy-art` ("Fantasy Art")
    - `line-art` ("Line Art")
    - `pixel-art` ("Pixel Art")
    - `photographic` ("Photographic")
    - `cinematic` ("Cinematic")
- **Logic**: Pass the selected raw preset value (e.g., `comic-book`) to `StabilityService`.

## Verification Plan
### Manual Verification
- **Test Generation**: Select "Comic Book" and generate.
- **Visual Check**: Confirm the generated image reflects the "Comic Book" style.
- **Log Check**: Verify `style_preset` parameter is sent in the API request.

### Story Consistency Verification
- **Create Character**: Create a new character with a detailed description.
- **Weave Story**: Create a story including this character.
- **Generate Page**: Tap a page to generate an illustration.
- **Verify**: Confirm the prompt in logs contains the character's description and the resulting image resembles the character.

## Storyboard Batch Generation (The "One Shot" Fix)
To strictly enforce consistency, we will generate multiple scenes in a single image generation pass (a 2x2 Grid). This forces the AI model to maintain character identity across the panels inherently.

1.  **Batching**: Group story pages into batches of 4 (2x2 grid).
2.  **Mega-Prompting**: Construct a prompt describing a "2x2 storyboard sheet".
    *   "Character Ref: [Enhanced Profile]" (Once at the top).
    *   "Panel 1 (Top-Left): [Scene 1]"
    *   "Panel 2 (Top-Right): [Scene 2]"...
3.  **Slicing**: Use Dart's `image` library to crop the 1024x1024 result into four 512x512 images.
4.  **Auto-Population**: Automatically assign these images to the pages immediately after story weaving.
5.  **Fallbacks**: If a story has < 4 pages, adjust the grid (e.g., 1x2 or single).

This fulfills the user's request for "doing it in one shot" and "generating all images".
