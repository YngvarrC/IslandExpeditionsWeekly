# Island Expeditions Weekly

Tired of always having to return to that table to check your progress? So was I and that's why I made this little addon.
As soon as you log in with a character or collect azerite in an island your progress will be fetched and saved.

The addon will also track your weekly world quest completion for winning an island expedition.

Currently only via chat commands and prints in the default chat window. I'll get to implementing a UI for this at some point.

## Available commands
All commands work with either `/IslandExpeditionsWeekly` or `/iew`
* `/iew show` Show the progress of all your characters (levels 110+)
* `/iew ignore Realm.Name` Ignore a character so it will not be displayed. Using the command again will unignore. Example: if I want to ignore character `Abc` on realm `Xyz`, I have to use the command `/iew ignore Xyz.Abc`
* `/iew ignorelist` Show a list of all ignored characters
* `/iew clearignore` Erase the ignore list
* `/iew reset` Reset the database of the addon. This should be the same as doing a complete reinstall. Might be needed if things go south
