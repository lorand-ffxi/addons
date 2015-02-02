healBot

By default, healBot will monitor the party that it is in.  Commands to monitor
or ignore players can be found below.

If you have the shortcuts addon installed, your aliases.xml file from that addon
will be loaded, and those aliases will be available for use when specifying
buffs.

Config files will be added soon, but for now...
Trust NPCs that will be ignored: Joachim, Ulmia, Cherukiki, Tenzen
Buff lists:
['self'] = {'Haste II', 'Refresh II', 'Aquaveil', 'Protect V', 'Shell V', 'Phalanx', 'Reraise'},
['melee'] = {'Haste II', 'Phalanx II', 'Protect V', 'Shell V'},
['mage'] = {'Haste II', 'Refresh II', 'Protect V', 'Shell V', 'Phalanx II'},
['melee2'] = {'Haste II', 'Phalanx II'},
['mage2'] = {'Haste II', 'Refresh II', 'Phalanx II'}

Place the healBot folder in .../Windower/addons/

To load healBot: //lua load healbot
To unload healBot: //hb unload
To reload healBot: //hb reload

Command:                            Action:
//hb on                             Activate
//hb off                            Deactivate (note: follow will remain active)
//hb status                         Displays whether or not healBot is active in the chat log
//hb mincure #                      Set the minimum cure tier to # (default is 3)
//hb reset                          Reset buff & debuff monitors
//hb reset buffs                    Reset buff monitors
//hb reset debuffs                  Reset debuff monitors
//hb buff charName spellName        Maintain the buff spellName on player charName
//hb buff <t> spellName             Maintain the buff spellName on current target
//hb cancelbuff charName spellName  Stop maintaining the buff spellName on player charName
//hb cancelbuff <t> spellName       Stop maintaining the buff spellName on current target
//hb bufflist listName charName     Maintain the buffs in the given list of buffs on player charName
//hb bufflist listName <t>          Maintain the buffs in the given list of buffs on current target
//hb follow charName                Follow player charName
//hb follow <t>                     Follow current target
//hb follow off                     Stop following
//hb follow dist #                  Set the follow distance to #
//hb ignore charName                Ignore player charName so they won't be healed
//hb unignore charName              Stop ignoring player charName (note: will not watch a player that would not otherwise be watched)
//hb watch charName                 Watch player charName so they will be healed
//hb unwatch charName               Stop watching player charName (note: will not ignore a player that would be otherwise watched)
//hb ignoretrusts on                Ignore Trust NPCs
//hb ignoretrusts off               Heal Trust NPCs

Debugging commands:                 Action:
//hb moveinfo on                    Will display current (x,y,z) position and the amount of time spent at that location in the upper left corner.
//hb moveinfo off                   Hides the moveInfo display
//hb packetinfo on                  Adds to the chat log packet info about monitored players
//hb packetinfo off                 Prevents packet info from being added to the chat log