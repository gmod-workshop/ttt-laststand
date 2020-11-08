# ttt-laststand

**NOTICE: This Addon only works for the "Trouble in Terrorist Town" and "TTT2" gamemodes.**

## Features

This is a passive feature for TTT. When an Innocent is last alive, they can wait out an amount of time (configurable) and have a chance (configurable) to become a Detective.

## ConVars

- ttt_laststand_enable (def: 1) - Is the Last Stand feature enabled?
- ttt_laststand_chance (def: 1.0) - Chance the last Innocent will become a Detective. (0.0 - 1.0)
- ttt_laststand_time (def: 60) - Time (seconds) the Innocent must wait before becoming a Detective.
- ttt_laststand_credits (def: 2) - Number of credits the Innocent will receive upon becoming a Detective.
- ttt_laststand_multiple (def: 0) - Can more than one Innocent be turned into a Detective per round? (Ex: If a new Detective revives somebody and then dies.)
- ttt_laststand_strict (def: 0) - Do Innocents become a Detective if they killed an Innocent last?

## Server Infos
Add it to your server by following this guide: http://wiki.garrysmod.com/page/Server/Workshop

You can add the following items to your translation file, to translate this addon:
- "laststand_name"
- "laststand_alert"
- "laststand_block"
- "laststand_update"
- "laststand_survived"
- "laststand_cancel"

## Source
The whole source code can be found on [GitHub](https://github.com/gmod-workshop/ttt-laststand), feel free to contribute.
