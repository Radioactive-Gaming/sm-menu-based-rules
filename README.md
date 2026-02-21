# SourceMod: Menu-Based Rules

A fork of [XARIUS'S plugin](https://forums.alliedmods.net/showthread.php?t=72788). 

This plugin will automatically display a list of rules in a menu panel to all connecting clients. 

Features:
* a command line option for admins to display the rules to an individual user (or group, @all etc..).
* Clients then have the choice of either agreeing, or disagreeing to the rules and conditions presented to them. If they agree, they recieve a nice message. If they disagree, they get kicked (also with a nice message).
* Plays a welcome sound to all connecting clients. The sound will not play on map change.
* If the menu dissolves or gets cancelled, the user WILL get kicked after menutime expires! This prevents people from cancelling the menu with another menu, or ignoring it all together.
* The rules are defined in showrulesdata.phrases.txt. This gives you the ability to have multi-lingual rules. There are 10 rule lines available. If you don't need 10, simply leave the unused ones blank. Do not rewmove the unused lines, it will cause errors.

The menu panel has a maximum of 511 characters.

## Commands

* `sm_showrules`:
  * Description: display the server rules to a specific player.
  * Parameters:
    * Player: (Mandatory) the player's display name or Steam ID.

## Configuration

### AutoExec

```
// Number of times to attempt to display the rules menu. (3 second intervals)
// -
// Default: "20"
sm_showrules_displayattempts "20"

// Kick the client if the rules cannot be displayed after defined display attempts.
// -
// Default: "1"
sm_showrules_displayfailurekick "1"

// Enable this plugin.  0 = Disabled.
// -
// Default: "1"
sm_showrules_enabled "1"

// Number of hours before the previous terms agreement expires.
// -
// Default: "24"
sm_showrules_expiration "24"

// Sound file to play to connecting clients.  Relative to the sound/ folder.  Example: 'welcome.mp3' or 'mysounds/welcome.mp3'
// -
// Default: ""
sm_showrules_joinsound ""

// Time to display rules menu to client before dissolving (and kicking them).
// -
// Default: "120"
sm_showrules_menutime "120"

// Shows agree/disagree options instead of a single option to close the rules menu.
// -
// Default: "1"
sm_showrules_showmenuoptions "1"

// Display Rules menu to clients automatically upon joining the server.
// -
// Default: "1"
sm_showrules_showonjoin "1"

// On join, display menu to admins.
// -
// Default: "0"
sm_showrules_showtoadmins "0"

```
## Installation

Follow the standard SourceMod process for installation by adding:

- The compiled plugin `showrules.smx` to `tf/addons/sourcemod/plugins/`.
- The translation files to `/tf/addons/sourcemod/translation/`.
- Reload all plugins or restart the server.
