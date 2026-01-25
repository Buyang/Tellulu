# Tellulu Tales - Project Walkthrough

**Mission**: Create an AI-powered storybook creator that generates consistent characters and illustrations.

## 🎯 The Challenge: "Nono's Identity Crisis"
The initial implementation suffered from severe inconsistency. The main character, "Nono", would change age, hair color, and clothing style on every page.
Additionally, the scenes often ignored the text, or the character ignored the scene.

## 🛠️ The Solution: "Smart Fusion Architecture"

We solved this with a three-pillar approach:

### 1. The Brain: Gemini 2.0 Flash Exp
- **Problem**: Lower-tier models (1.5 Flash) were failing (404s) or giving weak descriptions.
- **Fix**: Upgraded to `gemini-2.0-flash-exp`.
- **Innovation**: We instructed the Brain to write **Self-Contained Visual Prompts**.
    - *Before*: "Nono is swimming." + (Separate Bio)
    - *After*: "Nono, a 7-year-old girl with pink hair in a blue swimsuit, is swimming in a river."

### 2. The Anchor: Global Seed Persistence
- **Problem**: Image Generators are random by nature.
- **Fix**: We generate a unique `storySeed` (e.g., `123456`) when the story is born.
- **Lock**: Every single page uses this EXACT seed. This mathematically forces the AI to use the same art style and character interpretation across the entire book.
- **Persistence**: This seed is saved to the file, so even "Regenerating" a page uses a mathematical variation of the Master Seed (`Seed + 1`), keeping it in the family.

### 3. The Composition: Prompt Engineering
- **Discovery**: "Scene First" prompts worked best.
- **Strategy**: `[Action/Scene] + [Integrated Character Bio]`.
- **Result**: The AI draws the *context* (School, Forest) first, then places the *specific* character into it.

## 📦 Deliverables
- **Codebase**: Flutter app with `GeminiService` and `StabilityService`.
- **Docs**: `docs/` folder contains the task list and implementation plan.
- **Repo**: Fully git-initialized locally.

## 🚀 How to Run
1.  `flutter run -d macos`
2.  Create a **New Story** (to generate a fresh Seed).
3.  Enjoy consistent, illustrated tales!
