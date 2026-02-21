## [1.6.0] 2026-02-21

### Changed

* Updated the code to the new declarations syntax.

### Fixed

* Formatting fixes.
* Fixed numerous type mismatches.
* Added explicit return values for Action functions.

## [1.5.2] 2026-02-21

### Fixed

* Replaced deprecated GetMaxClients function with MaxClients.
* Replaced deprecated GetClientAuthString function with GetClientAuthId.

## [1.5.1] 2008-10-29

### Changed

* Change of heart, moved the rules out of showrules.phrases.txt and into showrulesdata.phrases.txt. This way if I update the primary translation file with new entries, you don't have to re-do your rules each time.

## [1.5.0] 2008-10-29

This version now automatically creates a config file in cfg/sourcemod/. Please utilize this file and remove sm_showrules cvars from other config files.

### Added

* Added convar sm_showrules_expiration. This plugin now makes use of the clientprefs extension in the SM 1.1 snapshots. When players agree to the rules, a cookie will be stored with a timestamp. The next time they connect, if the time period has been greater than sm_showrules_expiration, the rules will be displayed to them again.
* Added convar sm_showrules_joinsound. This allows you to specify a sound to be played to connecting clients. The sound will not be played on map change.

### Fixed

* Fixed some bugs in the translations.

### Removed

* sm_showrules_showonmapchange has been deprecated. This cvar will no longer do anything!

## [1.4.0] 2008-10-29

## [1.3.0] 2008-09-17

### Added

* Added log message when clients get kicked.
* Added convar sm_showrules_showmenuoptions. When set to false, clients will see a simple 1) Close Window option. Since there is no disagree option, clients will not be kicked.
* Added New Translations - If you update to 1.3, you must use the new translations file, sorry! This was a new feature only release, if the 1.2 is working fine for you, there's no reason to upgrade unless you want one of the new features.

### Changed

* Rewrote the command function using ProcessTargetString instead of FindTarget to support multiple targets as well as #userid as a target.

## [1.2.0] 2008-07-23

### Added

* Added extensive code to check for other types of menus before displaying the rules menu. If the client has another menu open, the rules menu will wait patiently for 60 seconds (default) to display it's menu. Additionally, if another mod or plugin opens a window which cancels the rules menu, it will again wait 60 seconds to redisplay the rules menu. These changes should make this plugin 100% friendly with mods such as GunGame, CSSDM, etc, which open menus on team selection and other various locations.
* Added Convar: sm_showrules_displayattempts.
* The menu re-display code is hardcoded using a 3 second repeating timer. This value is the number of times the timer will repeat. The default value is 20, which would be 60 seconds. The reasons a menu can not be displayed are limited. Client timing out, another window already open, or some sort of general client error.
*  Added Convar: sm_showrules_displayfailurekick. After the repeating timer has hit the maximum number of attempts to display the menu, should we kick the client? Default is yes. If they leave a menu open for 60 seconds, they're either blocking the rules menu, timing out, or afk.

## [1.1.0] 2008-07-18

### Added

* Convar: sm_showrules_showonmapchange.
* Hooked scoreboard on map end. Store a complete list of steam id's currently on the server into an array. When clients reconnect after map change, the connecting client ids are compared to the values within the array to determine if they were on the server previously. If they were, we assume they already agreed to the rules and don't show them the menu again. Obviously, setting this to 1 (true) will continue to display the rules to all clients on map change.

### Fixed

* Fixed a rare issue where PostAdminCheck was returning client not connected error messages. Assume it was due to the timing of clients disconnecting, or timing out. Fixed by issuing a isClientConnected check.

## [1.0.0] 2008-06-16

* Initial release.
