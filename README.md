# Island Expeditions Weekly

Tired of always having to return to that table to check your progress? So was I and that's why I made this little addon.
As soon as you log in with a character or collect azerite in an island your progress will be fetched and saved.

<del>The addon will also track your weekly world quest completion for winning an island expedition.</del> No longer the case as this world quest was removed in 8.1

## Available commands

All commands work with either <i>/IslandExpeditionsWeekly</i> or <i>/iew</i>

*    <i>/iew show</i>: Show the progress of all your characters (levels 110+) in chat
*    <i>/iew showgui</i>: Show the progress in a simple window
*    <i>/iew ignore Realm.Name</i>: Ignore a character so it will not be displayed. Using the command again will unignore. Example: if I want to ignore character Abc on realm Xyz, I have to use the command /iew ignore Xyz.Abc
*    <i>/iew ignorelist</i>: Show a list of all ignored characters
*    <i>/iew clearignore</i>: Clear the ignore list
*    <i>/iew reset</i>: Reset the database of the addon. This should be the same as doing a complete reinstall if you restart wow after this. Might be needed if things go south

### Upcoming features

Note that none of these are hard promises but more like they seem useful to me and when I have some free time to work on the addon, are probably next on the todo list

*    <del>UI window to show the progress in a more structured format</del> Currently with Ace3 library. I might redo this without the library because I cannot name the frame now and therefor cannot close it with ESC
*    Minimap button with click options to show progress/manage ignore list
*    <del>Blizzard options page to enable/disable tracking azerite/WQ progress</del> With only one of the two options remaining, this is highly unlikely to be added
*    ...
