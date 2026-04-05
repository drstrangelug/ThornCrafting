# ThornCraft

**ThornCraft** is a lightweight, high-performance World of Warcraft addon that enhances your item tooltips with detailed profession and crafting information. Never wonder "what is this reagent used for?" or "can my alt craft with this?" ever again.

## ✨ Features

* **Smart Reagent Tooltips:** Hover over any crafting material to instantly see a list of recipes that use it, complete with native, borderless profession icons.
* **Color coded:** Recipes are color coded for those you have learnt, those that are unleaned and those that belong to professions you do not have.
* **Warband / Alt Tracking:** Silently learns your characters' professions as you log into them. 
* **Native Options Menu:** Fully integrated into WoW's modern Settings API. Customize which professions to track, filter out unlearned recipes, and toggle alt-tracking.
* **Customizable Colors:** Built-in color picker support to change the text colors for Learned, Unlearned, and Untrained recipes to suit your visual preferences.
* **Zero-Lag Performance:** Unlike older addons that scan thousands of items every time you log in or open a bag, ThornCraft uses an Ahead-of-Time (AOT) compiled database. It reads a pre-calculated index, meaning zero impact on your framerate.

Many thanks to https://github.com/kaldown/CraftLib for supplying the recipe data!

## 📥 Installation

### Option 1: CurseForge / Addon Manager
*(Link to your CurseForge page goes here once published)*

### Option 2: Manual Install
1. Download the latest release `.zip` from the Releases tab.
2. Extract the folder.
3. Place the `ThornCraft` folder into your World of Warcraft directory:
   `World of Warcraft\_retail_\Interface\AddOns\`
4. Boot up the game and ensure "Load Out of Date Addons" is checked if a new patch recently dropped.

## ⚙️ Usage & Commands

ThornCraft works out of the box, but you can configure it to your exact needs.

* **Settings Menu:** Press `Escape` -> `Options` -> `AddOns` -> `ThornCraft`.
* **Slash Commands:** * `/tc` or `/thorncraft` - Prints addon status and version.
  * `/tc debug` - Toggles the developer chat logging on/off.
 
## Settings
**Enable Debug Logging to Chat Frame** Turns on and off whether Thorncraft logs debug information to the frame
**Show '(unlearned)' text in tooltips** Turns on and off whether recipes are shown with the literal text "(unlearned)" after them
**Tooltip Colors** Modify the colours of the three classes of tooltip item class (learnt, unlearnt, not your profession).

For each profession you can tick a box to enable/disable recipes, to only show learnt recipes and to include recipes that belong to professions that your alts have.

## Alts / Warband
In order for ThornCraft to recognise the professions of each Alt you will need to log into that Alt at least once.

## 🛠️ Building from Source (For Developers)

ThornCraft uses a custom build pipeline to generate its high-performance reverse-lookup index. If you are cloning the repository to add new recipes or professions, you must run the build script before testing.

**Prerequisites:** You must have [Lua](https://www.lua.org/download.html) installed on your machine.

1. Clone the repository.
2. Add or modify data inside the raw data files (e.g., `Blacksmithing.lua`).
3. Open your terminal in the root directory and run:
   ```bash
   lua builder.lua
