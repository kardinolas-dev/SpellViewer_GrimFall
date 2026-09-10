--[[
    SpellViewer - WoW 3.3.5a / Project Ascension Wildcard Roll Addon
    - Minimap button to toggle the window
    - Starts recording CUSTOM_CLASSLESS_WILDCARD_SPELL_ROLLED automatically on load
    - Displays player's Active Specialization at the top (dynamic, supports 2+ specs)
    - Dropdown to switch which specialization's ability pool is viewed
    - Automatically persists ability pools per specialization into SpellViewerDB
    - If GFPOOL is empty, loads from persistent storage or prompts: "Make sure you re-rolled an ability"
    - When rolls occur, always saves to the ACTIVE specialization (not the dropdown selection)
    - Ability rows show ONLY ability icon, ability name, and class
]]--

-- Initialize SavedVariables
SpellViewerDB = SpellViewerDB or {
    minimapPos = 220,
    shown = true,
    pools = {},        -- [specIndex] = { spellID1, spellID2, ... }
    lastActiveSpec = 1,
}

-- Global references matching Ascension wildcard roll script conventions
GF = GF or nil
GFLAST = GFLAST or nil
GFPOOL = GFPOOL or {}

local viewedSpec = 1
local displayedList = {}
local collapsedClasses = {}

-- RAID Class Colors mapping for 3.3.5a
local CLASS_COLORS = {
    ["PALADIN"]     = "F58CBA",
    ["MAGE"]        = "69CCF0",
    ["WARRIOR"]     = "C79C6E",
    ["DEATHKNIGHT"] = "C41F3B",
    ["PRIEST"]      = "FFFFFF",
    ["ROGUE"]       = "FFF569",
    ["HUNTER"]      = "ABD473",
    ["SHAMAN"]      = "0070DE",
    ["WARLOCK"]     = "9482C9",
    ["DRUID"]       = "FF7D0A",
}

-- Database of known abilities & talents per class (auto-generated from classAbilities.ts)
local KNOWN_SPELL_CLASSES = {
    ['battle stance'] = { class = 'Warrior', color = 'C79C6E' },
    ['defensive stance'] = { class = 'Warrior', color = 'C79C6E' },
    ['berserker stance'] = { class = 'Warrior', color = 'C79C6E' },
    ['heroic strike'] = { class = 'Warrior', color = 'C79C6E' },
    ['rend'] = { class = 'Warrior', color = 'C79C6E' },
    ['charge'] = { class = 'Warrior', color = 'C79C6E' },
    ['thunder clap'] = { class = 'Warrior', color = 'C79C6E' },
    ['hamstring'] = { class = 'Warrior', color = 'C79C6E' },
    ['bloodrage'] = { class = 'Warrior', color = 'C79C6E' },
    ['overpower'] = { class = 'Warrior', color = 'C79C6E' },
    ['battle shout'] = { class = 'Warrior', color = 'C79C6E' },
    ['demoralizing shout'] = { class = 'Warrior', color = 'C79C6E' },
    ['commanding shout'] = { class = 'Warrior', color = 'C79C6E' },
    ['challenging shout'] = { class = 'Warrior', color = 'C79C6E' },
    ['intimidating shout'] = { class = 'Warrior', color = 'C79C6E' },
    ['sunder armor'] = { class = 'Warrior', color = 'C79C6E' },
    ['shield bash'] = { class = 'Warrior', color = 'C79C6E' },
    ['revenge'] = { class = 'Warrior', color = 'C79C6E' },
    ['mocking blow'] = { class = 'Warrior', color = 'C79C6E' },
    ['shield block'] = { class = 'Warrior', color = 'C79C6E' },
    ['disarm'] = { class = 'Warrior', color = 'C79C6E' },
    ['cleave'] = { class = 'Warrior', color = 'C79C6E' },
    ['retaliation'] = { class = 'Warrior', color = 'C79C6E' },
    ['pummel'] = { class = 'Warrior', color = 'C79C6E' },
    ['whirlwind'] = { class = 'Warrior', color = 'C79C6E' },
    ['berserker rage'] = { class = 'Warrior', color = 'C79C6E' },
    ['execute'] = { class = 'Warrior', color = 'C79C6E' },
    ['slam'] = { class = 'Warrior', color = 'C79C6E' },
    ['intercept'] = { class = 'Warrior', color = 'C79C6E' },
    ['intervene'] = { class = 'Warrior', color = 'C79C6E' },
    ['shield wall'] = { class = 'Warrior', color = 'C79C6E' },
    ['recklessness'] = { class = 'Warrior', color = 'C79C6E' },
    ['spell reflection'] = { class = 'Warrior', color = 'C79C6E' },
    ['victory rush'] = { class = 'Warrior', color = 'C79C6E' },
    ['enraged regeneration'] = { class = 'Warrior', color = 'C79C6E' },
    ['shattering throw'] = { class = 'Warrior', color = 'C79C6E' },
    ['heroic throw'] = { class = 'Warrior', color = 'C79C6E' },
    ['taunt'] = { class = 'Warrior', color = 'C79C6E' },
    ['mortal strike'] = { class = 'Warrior', color = 'C79C6E' },
    ['sweeping strikes'] = { class = 'Warrior', color = 'C79C6E' },
    ['bladestorm'] = { class = 'Warrior', color = 'C79C6E' },
    ['taste for blood'] = { class = 'Warrior', color = 'C79C6E' },
    ['juggernaut'] = { class = 'Warrior', color = 'C79C6E' },
    ['sudden death'] = { class = 'Warrior', color = 'C79C6E' },
    ['trauma'] = { class = 'Warrior', color = 'C79C6E' },
    ['second wind'] = { class = 'Warrior', color = 'C79C6E' },
    ['unrelenting assault'] = { class = 'Warrior', color = 'C79C6E' },
    ['bloodthirst'] = { class = 'Warrior', color = 'C79C6E' },
    ['death wish'] = { class = 'Warrior', color = 'C79C6E' },
    ['rampage'] = { class = 'Warrior', color = 'C79C6E' },
    ['flurry'] = { class = 'Warrior', color = 'C79C6E' },
    ['titan\'s grip'] = { class = 'Warrior', color = 'C79C6E' },
    ['piercing howl'] = { class = 'Warrior', color = 'C79C6E' },
    ['bloodsurge'] = { class = 'Warrior', color = 'C79C6E' },
    ['heroic fury'] = { class = 'Warrior', color = 'C79C6E' },
    ['shield slam'] = { class = 'Warrior', color = 'C79C6E' },
    ['concussion blow'] = { class = 'Warrior', color = 'C79C6E' },
    ['shockwave'] = { class = 'Warrior', color = 'C79C6E' },
    ['devastate'] = { class = 'Warrior', color = 'C79C6E' },
    ['last stand'] = { class = 'Warrior', color = 'C79C6E' },
    ['vigilance'] = { class = 'Warrior', color = 'C79C6E' },
    ['warbringer'] = { class = 'Warrior', color = 'C79C6E' },
    ['damage shield'] = { class = 'Warrior', color = 'C79C6E' },
    ['gag order'] = { class = 'Warrior', color = 'C79C6E' },
    ['flash of light'] = { class = 'Paladin', color = 'F58CBA' },
    ['holy light'] = { class = 'Paladin', color = 'F58CBA' },
    ['lay on hands'] = { class = 'Paladin', color = 'F58CBA' },
    ['blessing of might'] = { class = 'Paladin', color = 'F58CBA' },
    ['blessing of wisdom'] = { class = 'Paladin', color = 'F58CBA' },
    ['blessing of kings'] = { class = 'Paladin', color = 'F58CBA' },
    ['blessing of sanctuary'] = { class = 'Paladin', color = 'F58CBA' },
    ['greater blessing of might'] = { class = 'Paladin', color = 'F58CBA' },
    ['greater blessing of wisdom'] = { class = 'Paladin', color = 'F58CBA' },
    ['greater blessing of kings'] = { class = 'Paladin', color = 'F58CBA' },
    ['greater blessing of sanctuary'] = { class = 'Paladin', color = 'F58CBA' },
    ['seal of righteousness'] = { class = 'Paladin', color = 'F58CBA' },
    ['seal of justice'] = { class = 'Paladin', color = 'F58CBA' },
    ['seal of light'] = { class = 'Paladin', color = 'F58CBA' },
    ['seal of wisdom'] = { class = 'Paladin', color = 'F58CBA' },
    ['seal of corruption'] = { class = 'Paladin', color = 'F58CBA' },
    ['seal of vengeance'] = { class = 'Paladin', color = 'F58CBA' },
    ['seal of command'] = { class = 'Paladin', color = 'F58CBA' },
    ['seal of the martyr'] = { class = 'Paladin', color = 'F58CBA' },
    ['judgement of light'] = { class = 'Paladin', color = 'F58CBA' },
    ['judgement of wisdom'] = { class = 'Paladin', color = 'F58CBA' },
    ['judgement of justice'] = { class = 'Paladin', color = 'F58CBA' },
    ['devotion aura'] = { class = 'Paladin', color = 'F58CBA' },
    ['retribution aura'] = { class = 'Paladin', color = 'F58CBA' },
    ['concentration aura'] = { class = 'Paladin', color = 'F58CBA' },
    ['shadow resistance aura'] = { class = 'Paladin', color = 'F58CBA' },
    ['frost resistance aura'] = { class = 'Paladin', color = 'F58CBA' },
    ['fire resistance aura'] = { class = 'Paladin', color = 'F58CBA' },
    ['crusader aura'] = { class = 'Paladin', color = 'F58CBA' },
    ['hammer of justice'] = { class = 'Paladin', color = 'F58CBA' },
    ['hand of protection'] = { class = 'Paladin', color = 'F58CBA' },
    ['hand of freedom'] = { class = 'Paladin', color = 'F58CBA' },
    ['hand of salvation'] = { class = 'Paladin', color = 'F58CBA' },
    ['hand of sacrifice'] = { class = 'Paladin', color = 'F58CBA' },
    ['hand of reckoning'] = { class = 'Paladin', color = 'F58CBA' },
    ['purify'] = { class = 'Paladin', color = 'F58CBA' },
    ['cleanse'] = { class = 'Paladin', color = 'F58CBA' },
    ['divine shield'] = { class = 'Paladin', color = 'F58CBA' },
    ['divine protection'] = { class = 'Paladin', color = 'F58CBA' },
    ['righteous defense'] = { class = 'Paladin', color = 'F58CBA' },
    ['exorcism'] = { class = 'Paladin', color = 'F58CBA' },
    ['holy wrath'] = { class = 'Paladin', color = 'F58CBA' },
    ['consecration'] = { class = 'Paladin', color = 'F58CBA' },
    ['hammer of wrath'] = { class = 'Paladin', color = 'F58CBA' },
    ['turn evil'] = { class = 'Paladin', color = 'F58CBA' },
    ['sense undead'] = { class = 'Paladin', color = 'F58CBA' },
    ['righteous fury'] = { class = 'Paladin', color = 'F58CBA' },
    ['avenging wrath'] = { class = 'Paladin', color = 'F58CBA' },
    ['divine plea'] = { class = 'Paladin', color = 'F58CBA' },
    ['shield of righteousness'] = { class = 'Paladin', color = 'F58CBA' },
    ['sacred shield'] = { class = 'Paladin', color = 'F58CBA' },
    ['holy shock'] = { class = 'Paladin', color = 'F58CBA' },
    ['beacon of light'] = { class = 'Paladin', color = 'F58CBA' },
    ['divine favor'] = { class = 'Paladin', color = 'F58CBA' },
    ['divine illumination'] = { class = 'Paladin', color = 'F58CBA' },
    ['aura mastery'] = { class = 'Paladin', color = 'F58CBA' },
    ['infusion of light'] = { class = 'Paladin', color = 'F58CBA' },
    ['holy shield'] = { class = 'Paladin', color = 'F58CBA' },
    ['avenger\'s shield'] = { class = 'Paladin', color = 'F58CBA' },
    ['hammer of the righteous'] = { class = 'Paladin', color = 'F58CBA' },
    ['redoubt'] = { class = 'Paladin', color = 'F58CBA' },
    ['ardent defender'] = { class = 'Paladin', color = 'F58CBA' },
    ['crusader strike'] = { class = 'Paladin', color = 'F58CBA' },
    ['divine storm'] = { class = 'Paladin', color = 'F58CBA' },
    ['repentance'] = { class = 'Paladin', color = 'F58CBA' },
    ['vindication'] = { class = 'Paladin', color = 'F58CBA' },
    ['the art of war'] = { class = 'Paladin', color = 'F58CBA' },
    ['sheath of light'] = { class = 'Paladin', color = 'F58CBA' },
    ['righteous vengeance'] = { class = 'Paladin', color = 'F58CBA' },
    ['sanctified retribution'] = { class = 'Paladin', color = 'F58CBA' },
    ['eye for an eye'] = { class = 'Paladin', color = 'F58CBA' },
    ['heart of the crusader'] = { class = 'Paladin', color = 'F58CBA' },
    ['fireball'] = { class = 'Mage', color = '69CCF0' },
    ['frostbolt'] = { class = 'Mage', color = '69CCF0' },
    ['arcane missiles'] = { class = 'Mage', color = '69CCF0' },
    ['arcane explosion'] = { class = 'Mage', color = '69CCF0' },
    ['fire blast'] = { class = 'Mage', color = '69CCF0' },
    ['scorch'] = { class = 'Mage', color = '69CCF0' },
    ['pyroblast'] = { class = 'Mage', color = '69CCF0' },
    ['flamestrike'] = { class = 'Mage', color = '69CCF0' },
    ['cone of cold'] = { class = 'Mage', color = '69CCF0' },
    ['blizzard'] = { class = 'Mage', color = '69CCF0' },
    ['ice lance'] = { class = 'Mage', color = '69CCF0' },
    ['frost nova'] = { class = 'Mage', color = '69CCF0' },
    ['frost armor'] = { class = 'Mage', color = '69CCF0' },
    ['ice armor'] = { class = 'Mage', color = '69CCF0' },
    ['mage armor'] = { class = 'Mage', color = '69CCF0' },
    ['molten armor'] = { class = 'Mage', color = '69CCF0' },
    ['arcane intellect'] = { class = 'Mage', color = '69CCF0' },
    ['arcane brilliance'] = { class = 'Mage', color = '69CCF0' },
    ['dampen magic'] = { class = 'Mage', color = '69CCF0' },
    ['amplify magic'] = { class = 'Mage', color = '69CCF0' },
    ['blink'] = { class = 'Mage', color = '69CCF0' },
    ['mana shield'] = { class = 'Mage', color = '69CCF0' },
    ['evocation'] = { class = 'Mage', color = '69CCF0' },
    ['polymorph'] = { class = 'Mage', color = '69CCF0' },
    ['counterspell'] = { class = 'Mage', color = '69CCF0' },
    ['slow fall'] = { class = 'Mage', color = '69CCF0' },
    ['invisibility'] = { class = 'Mage', color = '69CCF0' },
    ['ice block'] = { class = 'Mage', color = '69CCF0' },
    ['mirror image'] = { class = 'Mage', color = '69CCF0' },
    ['spellsteal'] = { class = 'Mage', color = '69CCF0' },
    ['conjure water'] = { class = 'Mage', color = '69CCF0' },
    ['conjure food'] = { class = 'Mage', color = '69CCF0' },
    ['conjure refreshment'] = { class = 'Mage', color = '69CCF0' },
    ['ritual of refreshment'] = { class = 'Mage', color = '69CCF0' },
    ['conjure mana gem'] = { class = 'Mage', color = '69CCF0' },
    ['teleport: stormwind'] = { class = 'Mage', color = '69CCF0' },
    ['teleport: ironforge'] = { class = 'Mage', color = '69CCF0' },
    ['teleport: darnassus'] = { class = 'Mage', color = '69CCF0' },
    ['teleport: exodar'] = { class = 'Mage', color = '69CCF0' },
    ['teleport: orgrimmar'] = { class = 'Mage', color = '69CCF0' },
    ['teleport: undercity'] = { class = 'Mage', color = '69CCF0' },
    ['teleport: thunder bluff'] = { class = 'Mage', color = '69CCF0' },
    ['teleport: silvermoon'] = { class = 'Mage', color = '69CCF0' },
    ['teleport: dalaran'] = { class = 'Mage', color = '69CCF0' },
    ['portal: stormwind'] = { class = 'Mage', color = '69CCF0' },
    ['portal: ironforge'] = { class = 'Mage', color = '69CCF0' },
    ['portal: darnassus'] = { class = 'Mage', color = '69CCF0' },
    ['portal: exodar'] = { class = 'Mage', color = '69CCF0' },
    ['portal: orgrimmar'] = { class = 'Mage', color = '69CCF0' },
    ['portal: undercity'] = { class = 'Mage', color = '69CCF0' },
    ['portal: thunder bluff'] = { class = 'Mage', color = '69CCF0' },
    ['portal: silvermoon'] = { class = 'Mage', color = '69CCF0' },
    ['portal: dalaran'] = { class = 'Mage', color = '69CCF0' },
    ['arcane barrage'] = { class = 'Mage', color = '69CCF0' },
    ['arcane power'] = { class = 'Mage', color = '69CCF0' },
    ['presence of mind'] = { class = 'Mage', color = '69CCF0' },
    ['slow'] = { class = 'Mage', color = '69CCF0' },
    ['focus magic'] = { class = 'Mage', color = '69CCF0' },
    ['missile barrage'] = { class = 'Mage', color = '69CCF0' },
    ['torment the weak'] = { class = 'Mage', color = '69CCF0' },
    ['incanter\'s absorption'] = { class = 'Mage', color = '69CCF0' },
    ['blast wave'] = { class = 'Mage', color = '69CCF0' },
    ['dragon\'s breath'] = { class = 'Mage', color = '69CCF0' },
    ['living bomb'] = { class = 'Mage', color = '69CCF0' },
    ['combustion'] = { class = 'Mage', color = '69CCF0' },
    ['hot streak'] = { class = 'Mage', color = '69CCF0' },
    ['firestarter'] = { class = 'Mage', color = '69CCF0' },
    ['ignite'] = { class = 'Mage', color = '69CCF0' },
    ['pyroclasm'] = { class = 'Mage', color = '69CCF0' },
    ['ice barrier'] = { class = 'Mage', color = '69CCF0' },
    ['deep freeze'] = { class = 'Mage', color = '69CCF0' },
    ['icy veins'] = { class = 'Mage', color = '69CCF0' },
    ['cold snap'] = { class = 'Mage', color = '69CCF0' },
    ['fingers of frost'] = { class = 'Mage', color = '69CCF0' },
    ['brain freeze'] = { class = 'Mage', color = '69CCF0' },
    ['summon water elemental'] = { class = 'Mage', color = '69CCF0' },
    ['freeze'] = { class = 'Mage', color = '69CCF0' },
    ['winter\'s chill'] = { class = 'Mage', color = '69CCF0' },
    ['blood strike'] = { class = 'Death Knight', color = 'C41F3B' },
    ['plague strike'] = { class = 'Death Knight', color = 'C41F3B' },
    ['icy touch'] = { class = 'Death Knight', color = 'C41F3B' },
    ['death coil'] = { class = 'Death Knight', color = 'C41F3B' },
    ['death grip'] = { class = 'Death Knight', color = 'C41F3B' },
    ['death and decay'] = { class = 'Death Knight', color = 'C41F3B' },
    ['blood presence'] = { class = 'Death Knight', color = 'C41F3B' },
    ['frost presence'] = { class = 'Death Knight', color = 'C41F3B' },
    ['unholy presence'] = { class = 'Death Knight', color = 'C41F3B' },
    ['mind freeze'] = { class = 'Death Knight', color = 'C41F3B' },
    ['strangulate'] = { class = 'Death Knight', color = 'C41F3B' },
    ['chains of ice'] = { class = 'Death Knight', color = 'C41F3B' },
    ['horn of winter'] = { class = 'Death Knight', color = 'C41F3B' },
    ['dark command'] = { class = 'Death Knight', color = 'C41F3B' },
    ['raise dead'] = { class = 'Death Knight', color = 'C41F3B' },
    ['army of the dead'] = { class = 'Death Knight', color = 'C41F3B' },
    ['empower rune weapon'] = { class = 'Death Knight', color = 'C41F3B' },
    ['icebound fortitude'] = { class = 'Death Knight', color = 'C41F3B' },
    ['anti-magic shell'] = { class = 'Death Knight', color = 'C41F3B' },
    ['death gate'] = { class = 'Death Knight', color = 'C41F3B' },
    ['pestilence'] = { class = 'Death Knight', color = 'C41F3B' },
    ['blood boil'] = { class = 'Death Knight', color = 'C41F3B' },
    ['obliterate'] = { class = 'Death Knight', color = 'C41F3B' },
    ['death pact'] = { class = 'Death Knight', color = 'C41F3B' },
    ['path of frost'] = { class = 'Death Knight', color = 'C41F3B' },
    ['rune strike'] = { class = 'Death Knight', color = 'C41F3B' },
    ['heart strike'] = { class = 'Death Knight', color = 'C41F3B' },
    ['vampiric blood'] = { class = 'Death Knight', color = 'C41F3B' },
    ['rune tap'] = { class = 'Death Knight', color = 'C41F3B' },
    ['hysteria'] = { class = 'Death Knight', color = 'C41F3B' },
    ['dancing rune weapon'] = { class = 'Death Knight', color = 'C41F3B' },
    ['will of the necropolis'] = { class = 'Death Knight', color = 'C41F3B' },
    ['bloodworms'] = { class = 'Death Knight', color = 'C41F3B' },
    ['mark of blood'] = { class = 'Death Knight', color = 'C41F3B' },
    ['frost strike'] = { class = 'Death Knight', color = 'C41F3B' },
    ['howling blast'] = { class = 'Death Knight', color = 'C41F3B' },
    ['hungering cold'] = { class = 'Death Knight', color = 'C41F3B' },
    ['unbreakable armor'] = { class = 'Death Knight', color = 'C41F3B' },
    ['rime'] = { class = 'Death Knight', color = 'C41F3B' },
    ['killing machine'] = { class = 'Death Knight', color = 'C41F3B' },
    ['threat of thassarian'] = { class = 'Death Knight', color = 'C41F3B' },
    ['icy talons'] = { class = 'Death Knight', color = 'C41F3B' },
    ['lichborne'] = { class = 'Death Knight', color = 'C41F3B' },
    ['scourge strike'] = { class = 'Death Knight', color = 'C41F3B' },
    ['corpse explosion'] = { class = 'Death Knight', color = 'C41F3B' },
    ['summon gargoyle'] = { class = 'Death Knight', color = 'C41F3B' },
    ['unholy blight'] = { class = 'Death Knight', color = 'C41F3B' },
    ['anti-magic zone'] = { class = 'Death Knight', color = 'C41F3B' },
    ['bone shield'] = { class = 'Death Knight', color = 'C41F3B' },
    ['ghoul frenzy'] = { class = 'Death Knight', color = 'C41F3B' },
    ['ebon plaguebringer'] = { class = 'Death Knight', color = 'C41F3B' },
    ['desecration'] = { class = 'Death Knight', color = 'C41F3B' },
    ['wandering plague'] = { class = 'Death Knight', color = 'C41F3B' },
    ['lesser heal'] = { class = 'Priest', color = 'FFFFFF' },
    ['heal'] = { class = 'Priest', color = 'FFFFFF' },
    ['flash heal'] = { class = 'Priest', color = 'FFFFFF' },
    ['greater heal'] = { class = 'Priest', color = 'FFFFFF' },
    ['renew'] = { class = 'Priest', color = 'FFFFFF' },
    ['resurrection'] = { class = 'Priest', color = 'FFFFFF' },
    ['smite'] = { class = 'Priest', color = 'FFFFFF' },
    ['holy fire'] = { class = 'Priest', color = 'FFFFFF' },
    ['power word: shield'] = { class = 'Priest', color = 'FFFFFF' },
    ['power word: fortitude'] = { class = 'Priest', color = 'FFFFFF' },
    ['inner fire'] = { class = 'Priest', color = 'FFFFFF' },
    ['mana burn'] = { class = 'Priest', color = 'FFFFFF' },
    ['shadow word: pain'] = { class = 'Priest', color = 'FFFFFF' },
    ['mind blast'] = { class = 'Priest', color = 'FFFFFF' },
    ['mind flay'] = { class = 'Priest', color = 'FFFFFF' },
    ['psychic scream'] = { class = 'Priest', color = 'FFFFFF' },
    ['fade'] = { class = 'Priest', color = 'FFFFFF' },
    ['dispel magic'] = { class = 'Priest', color = 'FFFFFF' },
    ['cure disease'] = { class = 'Priest', color = 'FFFFFF' },
    ['abolish disease'] = { class = 'Priest', color = 'FFFFFF' },
    ['shadow protection'] = { class = 'Priest', color = 'FFFFFF' },
    ['divine spirit'] = { class = 'Priest', color = 'FFFFFF' },
    ['prayer of healing'] = { class = 'Priest', color = 'FFFFFF' },
    ['prayer of mending'] = { class = 'Priest', color = 'FFFFFF' },
    ['binding heal'] = { class = 'Priest', color = 'FFFFFF' },
    ['mind soothe'] = { class = 'Priest', color = 'FFFFFF' },
    ['mind vision'] = { class = 'Priest', color = 'FFFFFF' },
    ['shackle undead'] = { class = 'Priest', color = 'FFFFFF' },
    ['levitate'] = { class = 'Priest', color = 'FFFFFF' },
    ['mass dispel'] = { class = 'Priest', color = 'FFFFFF' },
    ['shadowfiend'] = { class = 'Priest', color = 'FFFFFF' },
    ['chastise'] = { class = 'Priest', color = 'FFFFFF' },
    ['fear ward'] = { class = 'Priest', color = 'FFFFFF' },
    ['mind control'] = { class = 'Priest', color = 'FFFFFF' },
    ['hymn of hope'] = { class = 'Priest', color = 'FFFFFF' },
    ['divine hymn'] = { class = 'Priest', color = 'FFFFFF' },
    ['shadow word: death'] = { class = 'Priest', color = 'FFFFFF' },
    ['penance'] = { class = 'Priest', color = 'FFFFFF' },
    ['power infusion'] = { class = 'Priest', color = 'FFFFFF' },
    ['pain suppression'] = { class = 'Priest', color = 'FFFFFF' },
    ['rapture'] = { class = 'Priest', color = 'FFFFFF' },
    ['borrowed time'] = { class = 'Priest', color = 'FFFFFF' },
    ['grace'] = { class = 'Priest', color = 'FFFFFF' },
    ['circle of healing'] = { class = 'Priest', color = 'FFFFFF' },
    ['guardian spirit'] = { class = 'Priest', color = 'FFFFFF' },
    ['desperate prayer'] = { class = 'Priest', color = 'FFFFFF' },
    ['holy nova'] = { class = 'Priest', color = 'FFFFFF' },
    ['spirit of redemption'] = { class = 'Priest', color = 'FFFFFF' },
    ['surge of light'] = { class = 'Priest', color = 'FFFFFF' },
    ['lightwell'] = { class = 'Priest', color = 'FFFFFF' },
    ['serendipity'] = { class = 'Priest', color = 'FFFFFF' },
    ['empowered healing'] = { class = 'Priest', color = 'FFFFFF' },
    ['shadowform'] = { class = 'Priest', color = 'FFFFFF' },
    ['vampiric embrace'] = { class = 'Priest', color = 'FFFFFF' },
    ['vampiric touch'] = { class = 'Priest', color = 'FFFFFF' },
    ['dispersion'] = { class = 'Priest', color = 'FFFFFF' },
    ['silence'] = { class = 'Priest', color = 'FFFFFF' },
    ['psychic horror'] = { class = 'Priest', color = 'FFFFFF' },
    ['mind melt'] = { class = 'Priest', color = 'FFFFFF' },
    ['shadow weaving'] = { class = 'Priest', color = 'FFFFFF' },
    ['misery'] = { class = 'Priest', color = 'FFFFFF' },
    ['stealth'] = { class = 'Rogue', color = 'FFF569' },
    ['sinister strike'] = { class = 'Rogue', color = 'FFF569' },
    ['eviscerate'] = { class = 'Rogue', color = 'FFF569' },
    ['pick lock'] = { class = 'Rogue', color = 'FFF569' },
    ['gouge'] = { class = 'Rogue', color = 'FFF569' },
    ['backstab'] = { class = 'Rogue', color = 'FFF569' },
    ['pick pocket'] = { class = 'Rogue', color = 'FFF569' },
    ['sprint'] = { class = 'Rogue', color = 'FFF569' },
    ['kick'] = { class = 'Rogue', color = 'FFF569' },
    ['feint'] = { class = 'Rogue', color = 'FFF569' },
    ['garrote'] = { class = 'Rogue', color = 'FFF569' },
    ['ambush'] = { class = 'Rogue', color = 'FFF569' },
    ['vanish'] = { class = 'Rogue', color = 'FFF569' },
    ['cheap shot'] = { class = 'Rogue', color = 'FFF569' },
    ['distract'] = { class = 'Rogue', color = 'FFF569' },
    ['kidney shot'] = { class = 'Rogue', color = 'FFF569' },
    ['blind'] = { class = 'Rogue', color = 'FFF569' },
    ['safe fall'] = { class = 'Rogue', color = 'FFF569' },
    ['sap'] = { class = 'Rogue', color = 'FFF569' },
    ['slice and dice'] = { class = 'Rogue', color = 'FFF569' },
    ['expose armor'] = { class = 'Rogue', color = 'FFF569' },
    ['rupture'] = { class = 'Rogue', color = 'FFF569' },
    ['evasion'] = { class = 'Rogue', color = 'FFF569' },
    ['cloak of shadows'] = { class = 'Rogue', color = 'FFF569' },
    ['tricks of the trade'] = { class = 'Rogue', color = 'FFF569' },
    ['fan of knives'] = { class = 'Rogue', color = 'FFF569' },
    ['dismantle'] = { class = 'Rogue', color = 'FFF569' },
    ['mutilate'] = { class = 'Rogue', color = 'FFF569' },
    ['hunger for blood'] = { class = 'Rogue', color = 'FFF569' },
    ['overkill'] = { class = 'Rogue', color = 'FFF569' },
    ['cold blood'] = { class = 'Rogue', color = 'FFF569' },
    ['vigor'] = { class = 'Rogue', color = 'FFF569' },
    ['seal fate'] = { class = 'Rogue', color = 'FFF569' },
    ['cut to the chase'] = { class = 'Rogue', color = 'FFF569' },
    ['blade flurry'] = { class = 'Rogue', color = 'FFF569' },
    ['adrenaline rush'] = { class = 'Rogue', color = 'FFF569' },
    ['killing spree'] = { class = 'Rogue', color = 'FFF569' },
    ['riposte'] = { class = 'Rogue', color = 'FFF569' },
    ['combat potency'] = { class = 'Rogue', color = 'FFF569' },
    ['surprise attacks'] = { class = 'Rogue', color = 'FFF569' },
    ['shadowstep'] = { class = 'Rogue', color = 'FFF569' },
    ['shadow dance'] = { class = 'Rogue', color = 'FFF569' },
    ['preparation'] = { class = 'Rogue', color = 'FFF569' },
    ['hemorrhage'] = { class = 'Rogue', color = 'FFF569' },
    ['ghostly strike'] = { class = 'Rogue', color = 'FFF569' },
    ['premeditation'] = { class = 'Rogue', color = 'FFF569' },
    ['cheat death'] = { class = 'Rogue', color = 'FFF569' },
    ['waylay'] = { class = 'Rogue', color = 'FFF569' },
    ['honor among thieves'] = { class = 'Rogue', color = 'FFF569' },
    ['auto shot'] = { class = 'Hunter', color = 'ABD473' },
    ['raptor strike'] = { class = 'Hunter', color = 'ABD473' },
    ['serpent sting'] = { class = 'Hunter', color = 'ABD473' },
    ['arcane shot'] = { class = 'Hunter', color = 'ABD473' },
    ['hunter\'s mark'] = { class = 'Hunter', color = 'ABD473' },
    ['concussive shot'] = { class = 'Hunter', color = 'ABD473' },
    ['aspect of the monkey'] = { class = 'Hunter', color = 'ABD473' },
    ['aspect of the hawk'] = { class = 'Hunter', color = 'ABD473' },
    ['aspect of the cheetah'] = { class = 'Hunter', color = 'ABD473' },
    ['aspect of the pack'] = { class = 'Hunter', color = 'ABD473' },
    ['aspect of the beast'] = { class = 'Hunter', color = 'ABD473' },
    ['aspect of the wild'] = { class = 'Hunter', color = 'ABD473' },
    ['aspect of the viper'] = { class = 'Hunter', color = 'ABD473' },
    ['aspect of the dragonhawk'] = { class = 'Hunter', color = 'ABD473' },
    ['revive pet'] = { class = 'Hunter', color = 'ABD473' },
    ['call pet'] = { class = 'Hunter', color = 'ABD473' },
    ['dismiss pet'] = { class = 'Hunter', color = 'ABD473' },
    ['mend pet'] = { class = 'Hunter', color = 'ABD473' },
    ['tame beast'] = { class = 'Hunter', color = 'ABD473' },
    ['eagle eye'] = { class = 'Hunter', color = 'ABD473' },
    ['immolation trap'] = { class = 'Hunter', color = 'ABD473' },
    ['freezing trap'] = { class = 'Hunter', color = 'ABD473' },
    ['frost trap'] = { class = 'Hunter', color = 'ABD473' },
    ['explosive trap'] = { class = 'Hunter', color = 'ABD473' },
    ['snake trap'] = { class = 'Hunter', color = 'ABD473' },
    ['distracting shot'] = { class = 'Hunter', color = 'ABD473' },
    ['mongoose bite'] = { class = 'Hunter', color = 'ABD473' },
    ['multi-shot'] = { class = 'Hunter', color = 'ABD473' },
    ['viper sting'] = { class = 'Hunter', color = 'ABD473' },
    ['scorpid sting'] = { class = 'Hunter', color = 'ABD473' },
    ['feign death'] = { class = 'Hunter', color = 'ABD473' },
    ['flare'] = { class = 'Hunter', color = 'ABD473' },
    ['disengage'] = { class = 'Hunter', color = 'ABD473' },
    ['tranquilizing shot'] = { class = 'Hunter', color = 'ABD473' },
    ['volley'] = { class = 'Hunter', color = 'ABD473' },
    ['kill command'] = { class = 'Hunter', color = 'ABD473' },
    ['kill shot'] = { class = 'Hunter', color = 'ABD473' },
    ['master\'s call'] = { class = 'Hunter', color = 'ABD473' },
    ['freezing arrow'] = { class = 'Hunter', color = 'ABD473' },
    ['misdirection'] = { class = 'Hunter', color = 'ABD473' },
    ['deterrence'] = { class = 'Hunter', color = 'ABD473' },
    ['rapid fire'] = { class = 'Hunter', color = 'ABD473' },
    ['bestial wrath'] = { class = 'Hunter', color = 'ABD473' },
    ['the beast within'] = { class = 'Hunter', color = 'ABD473' },
    ['intimidation'] = { class = 'Hunter', color = 'ABD473' },
    ['exotic beasts'] = { class = 'Hunter', color = 'ABD473' },
    ['invigoration'] = { class = 'Hunter', color = 'ABD473' },
    ['ferocious inspiration'] = { class = 'Hunter', color = 'ABD473' },
    ['aimed shot'] = { class = 'Hunter', color = 'ABD473' },
    ['chimera shot'] = { class = 'Hunter', color = 'ABD473' },
    ['silencing shot'] = { class = 'Hunter', color = 'ABD473' },
    ['trueshot aura'] = { class = 'Hunter', color = 'ABD473' },
    ['readiness'] = { class = 'Hunter', color = 'ABD473' },
    ['piercing shots'] = { class = 'Hunter', color = 'ABD473' },
    ['scatter shot'] = { class = 'Hunter', color = 'ABD473' },
    ['wyvern sting'] = { class = 'Hunter', color = 'ABD473' },
    ['explosive shot'] = { class = 'Hunter', color = 'ABD473' },
    ['black arrow'] = { class = 'Hunter', color = 'ABD473' },
    ['lock and load'] = { class = 'Hunter', color = 'ABD473' },
    ['counterattack'] = { class = 'Hunter', color = 'ABD473' },
    ['sniper training'] = { class = 'Hunter', color = 'ABD473' },
    ['hunting party'] = { class = 'Hunter', color = 'ABD473' },
    ['lightning bolt'] = { class = 'Shaman', color = '0070DE' },
    ['chain lightning'] = { class = 'Shaman', color = '0070DE' },
    ['earth shock'] = { class = 'Shaman', color = '0070DE' },
    ['flame shock'] = { class = 'Shaman', color = '0070DE' },
    ['frost shock'] = { class = 'Shaman', color = '0070DE' },
    ['healing wave'] = { class = 'Shaman', color = '0070DE' },
    ['lesser healing wave'] = { class = 'Shaman', color = '0070DE' },
    ['chain heal'] = { class = 'Shaman', color = '0070DE' },
    ['lightning shield'] = { class = 'Shaman', color = '0070DE' },
    ['water shield'] = { class = 'Shaman', color = '0070DE' },
    ['earth shield'] = { class = 'Shaman', color = '0070DE' },
    ['windfury weapon'] = { class = 'Shaman', color = '0070DE' },
    ['flametongue weapon'] = { class = 'Shaman', color = '0070DE' },
    ['frostbrand weapon'] = { class = 'Shaman', color = '0070DE' },
    ['rockbiter weapon'] = { class = 'Shaman', color = '0070DE' },
    ['earthliving weapon'] = { class = 'Shaman', color = '0070DE' },
    ['ghost wolf'] = { class = 'Shaman', color = '0070DE' },
    ['astral recall'] = { class = 'Shaman', color = '0070DE' },
    ['reincarnation'] = { class = 'Shaman', color = '0070DE' },
    ['purge'] = { class = 'Shaman', color = '0070DE' },
    ['cleanse spirit'] = { class = 'Shaman', color = '0070DE' },
    ['water breathing'] = { class = 'Shaman', color = '0070DE' },
    ['water walking'] = { class = 'Shaman', color = '0070DE' },
    ['far sight'] = { class = 'Shaman', color = '0070DE' },
    ['grounding totem'] = { class = 'Shaman', color = '0070DE' },
    ['tremor totem'] = { class = 'Shaman', color = '0070DE' },
    ['earthbind totem'] = { class = 'Shaman', color = '0070DE' },
    ['stoneclaw totem'] = { class = 'Shaman', color = '0070DE' },
    ['stoneskin totem'] = { class = 'Shaman', color = '0070DE' },
    ['strength of earth totem'] = { class = 'Shaman', color = '0070DE' },
    ['searing totem'] = { class = 'Shaman', color = '0070DE' },
    ['magma totem'] = { class = 'Shaman', color = '0070DE' },
    ['fire nova'] = { class = 'Shaman', color = '0070DE' },
    ['fire resistance totem'] = { class = 'Shaman', color = '0070DE' },
    ['frost resistance totem'] = { class = 'Shaman', color = '0070DE' },
    ['nature resistance totem'] = { class = 'Shaman', color = '0070DE' },
    ['healing stream totem'] = { class = 'Shaman', color = '0070DE' },
    ['mana spring totem'] = { class = 'Shaman', color = '0070DE' },
    ['cleansing totem'] = { class = 'Shaman', color = '0070DE' },
    ['windfury totem'] = { class = 'Shaman', color = '0070DE' },
    ['wrath of air totem'] = { class = 'Shaman', color = '0070DE' },
    ['heroism'] = { class = 'Shaman', color = '0070DE' },
    ['bloodlust'] = { class = 'Shaman', color = '0070DE' },
    ['hex'] = { class = 'Shaman', color = '0070DE' },
    ['lava burst'] = { class = 'Shaman', color = '0070DE' },
    ['wind shear'] = { class = 'Shaman', color = '0070DE' },
    ['thunderstorm'] = { class = 'Shaman', color = '0070DE' },
    ['elemental mastery'] = { class = 'Shaman', color = '0070DE' },
    ['totem of wrath'] = { class = 'Shaman', color = '0070DE' },
    ['elemental focus'] = { class = 'Shaman', color = '0070DE' },
    ['eye of the storm'] = { class = 'Shaman', color = '0070DE' },
    ['stormstrike'] = { class = 'Shaman', color = '0070DE' },
    ['lava lash'] = { class = 'Shaman', color = '0070DE' },
    ['feral spirit'] = { class = 'Shaman', color = '0070DE' },
    ['shamanistic rage'] = { class = 'Shaman', color = '0070DE' },
    ['maelstrom weapon'] = { class = 'Shaman', color = '0070DE' },
    ['dual wield'] = { class = 'Shaman', color = '0070DE' },
    ['spirit weapons'] = { class = 'Shaman', color = '0070DE' },
    ['mana tide totem'] = { class = 'Shaman', color = '0070DE' },
    ['nature\'s swiftness'] = { class = 'Shaman', color = '0070DE' },
    ['riptide'] = { class = 'Shaman', color = '0070DE' },
    ['tidal waves'] = { class = 'Shaman', color = '0070DE' },
    ['ancestral awakening'] = { class = 'Shaman', color = '0070DE' },
    ['ancestral healing'] = { class = 'Shaman', color = '0070DE' },
    ['shadow bolt'] = { class = 'Warlock', color = '9482C9' },
    ['immolate'] = { class = 'Warlock', color = '9482C9' },
    ['corruption'] = { class = 'Warlock', color = '9482C9' },
    ['curse of agony'] = { class = 'Warlock', color = '9482C9' },
    ['curse of doom'] = { class = 'Warlock', color = '9482C9' },
    ['curse of the elements'] = { class = 'Warlock', color = '9482C9' },
    ['curse of tongues'] = { class = 'Warlock', color = '9482C9' },
    ['curse of exhaustion'] = { class = 'Warlock', color = '9482C9' },
    ['curse of weakness'] = { class = 'Warlock', color = '9482C9' },
    ['drain life'] = { class = 'Warlock', color = '9482C9' },
    ['drain mana'] = { class = 'Warlock', color = '9482C9' },
    ['drain soul'] = { class = 'Warlock', color = '9482C9' },
    ['life tap'] = { class = 'Warlock', color = '9482C9' },
    ['hellfire'] = { class = 'Warlock', color = '9482C9' },
    ['rain of fire'] = { class = 'Warlock', color = '9482C9' },
    ['searing pain'] = { class = 'Warlock', color = '9482C9' },
    ['incinerate'] = { class = 'Warlock', color = '9482C9' },
    ['soul fire'] = { class = 'Warlock', color = '9482C9' },
    ['death coil'] = { class = 'Warlock', color = '9482C9' },
    ['fear'] = { class = 'Warlock', color = '9482C9' },
    ['howl of terror'] = { class = 'Warlock', color = '9482C9' },
    ['banish'] = { class = 'Warlock', color = '9482C9' },
    ['demon armor'] = { class = 'Warlock', color = '9482C9' },
    ['fel armor'] = { class = 'Warlock', color = '9482C9' },
    ['shadow ward'] = { class = 'Warlock', color = '9482C9' },
    ['unending breath'] = { class = 'Warlock', color = '9482C9' },
    ['create healthstone'] = { class = 'Warlock', color = '9482C9' },
    ['create soulstone'] = { class = 'Warlock', color = '9482C9' },
    ['ritual of summoning'] = { class = 'Warlock', color = '9482C9' },
    ['ritual of souls'] = { class = 'Warlock', color = '9482C9' },
    ['soulshatter'] = { class = 'Warlock', color = '9482C9' },
    ['summon imp'] = { class = 'Warlock', color = '9482C9' },
    ['summon voidwalker'] = { class = 'Warlock', color = '9482C9' },
    ['summon succubus'] = { class = 'Warlock', color = '9482C9' },
    ['summon felhunter'] = { class = 'Warlock', color = '9482C9' },
    ['summon felguard'] = { class = 'Warlock', color = '9482C9' },
    ['eye of kilrogg'] = { class = 'Warlock', color = '9482C9' },
    ['enslave demon'] = { class = 'Warlock', color = '9482C9' },
    ['inferno'] = { class = 'Warlock', color = '9482C9' },
    ['seed of corruption'] = { class = 'Warlock', color = '9482C9' },
    ['shadowflame'] = { class = 'Warlock', color = '9482C9' },
    ['demonic circle: summon'] = { class = 'Warlock', color = '9482C9' },
    ['demonic circle: teleport'] = { class = 'Warlock', color = '9482C9' },
    ['haunt'] = { class = 'Warlock', color = '9482C9' },
    ['unstable affliction'] = { class = 'Warlock', color = '9482C9' },
    ['dark pact'] = { class = 'Warlock', color = '9482C9' },
    ['siphon life'] = { class = 'Warlock', color = '9482C9' },
    ['pandemic'] = { class = 'Warlock', color = '9482C9' },
    ['everlasting affliction'] = { class = 'Warlock', color = '9482C9' },
    ['shadow embrace'] = { class = 'Warlock', color = '9482C9' },
    ['metamorphosis'] = { class = 'Warlock', color = '9482C9' },
    ['soul link'] = { class = 'Warlock', color = '9482C9' },
    ['demonic empowerment'] = { class = 'Warlock', color = '9482C9' },
    ['demonic pact'] = { class = 'Warlock', color = '9482C9' },
    ['decimation'] = { class = 'Warlock', color = '9482C9' },
    ['molten core'] = { class = 'Warlock', color = '9482C9' },
    ['fel domination'] = { class = 'Warlock', color = '9482C9' },
    ['immolation aura'] = { class = 'Warlock', color = '9482C9' },
    ['demon charge'] = { class = 'Warlock', color = '9482C9' },
    ['chaos bolt'] = { class = 'Warlock', color = '9482C9' },
    ['shadowfury'] = { class = 'Warlock', color = '9482C9' },
    ['conflagrate'] = { class = 'Warlock', color = '9482C9' },
    ['nether protection'] = { class = 'Warlock', color = '9482C9' },
    ['backdraft'] = { class = 'Warlock', color = '9482C9' },
    ['shadowburn'] = { class = 'Warlock', color = '9482C9' },
    ['ruin'] = { class = 'Warlock', color = '9482C9' },
    ['wrath'] = { class = 'Druid', color = 'FF7D0A' },
    ['moonfire'] = { class = 'Druid', color = 'FF7D0A' },
    ['starfire'] = { class = 'Druid', color = 'FF7D0A' },
    ['entangling roots'] = { class = 'Druid', color = 'FF7D0A' },
    ['thorns'] = { class = 'Druid', color = 'FF7D0A' },
    ['barkskin'] = { class = 'Druid', color = 'FF7D0A' },
    ['soothe animal'] = { class = 'Druid', color = 'FF7D0A' },
    ['hibernate'] = { class = 'Druid', color = 'FF7D0A' },
    ['faerie fire'] = { class = 'Druid', color = 'FF7D0A' },
    ['faerie fire (feral)'] = { class = 'Druid', color = 'FF7D0A' },
    ['hurricane'] = { class = 'Druid', color = 'FF7D0A' },
    ['claw'] = { class = 'Druid', color = 'FF7D0A' },
    ['rake'] = { class = 'Druid', color = 'FF7D0A' },
    ['rip'] = { class = 'Druid', color = 'FF7D0A' },
    ['shred'] = { class = 'Druid', color = 'FF7D0A' },
    ['ferocious bite'] = { class = 'Druid', color = 'FF7D0A' },
    ['maim'] = { class = 'Druid', color = 'FF7D0A' },
    ['ravage'] = { class = 'Druid', color = 'FF7D0A' },
    ['pounce'] = { class = 'Druid', color = 'FF7D0A' },
    ['cower'] = { class = 'Druid', color = 'FF7D0A' },
    ['dash'] = { class = 'Druid', color = 'FF7D0A' },
    ['tiger\'s fury'] = { class = 'Druid', color = 'FF7D0A' },
    ['maul'] = { class = 'Druid', color = 'FF7D0A' },
    ['swipe (bear)'] = { class = 'Druid', color = 'FF7D0A' },
    ['swipe (cat)'] = { class = 'Druid', color = 'FF7D0A' },
    ['swipe'] = { class = 'Druid', color = 'FF7D0A' },
    ['growl'] = { class = 'Druid', color = 'FF7D0A' },
    ['demoralizing roar'] = { class = 'Druid', color = 'FF7D0A' },
    ['enrage'] = { class = 'Druid', color = 'FF7D0A' },
    ['bash'] = { class = 'Druid', color = 'FF7D0A' },
    ['challenging roar'] = { class = 'Druid', color = 'FF7D0A' },
    ['frenzied regeneration'] = { class = 'Druid', color = 'FF7D0A' },
    ['healing touch'] = { class = 'Druid', color = 'FF7D0A' },
    ['regrowth'] = { class = 'Druid', color = 'FF7D0A' },
    ['rejuvenation'] = { class = 'Druid', color = 'FF7D0A' },
    ['tranquility'] = { class = 'Druid', color = 'FF7D0A' },
    ['mark of the wild'] = { class = 'Druid', color = 'FF7D0A' },
    ['gift of the wild'] = { class = 'Druid', color = 'FF7D0A' },
    ['revive'] = { class = 'Druid', color = 'FF7D0A' },
    ['rebirth'] = { class = 'Druid', color = 'FF7D0A' },
    ['remove curse'] = { class = 'Druid', color = 'FF7D0A' },
    ['abolish poison'] = { class = 'Druid', color = 'FF7D0A' },
    ['bear form'] = { class = 'Druid', color = 'FF7D0A' },
    ['dire bear form'] = { class = 'Druid', color = 'FF7D0A' },
    ['cat form'] = { class = 'Druid', color = 'FF7D0A' },
    ['aquatic form'] = { class = 'Druid', color = 'FF7D0A' },
    ['travel form'] = { class = 'Druid', color = 'FF7D0A' },
    ['flight form'] = { class = 'Druid', color = 'FF7D0A' },
    ['swift flight form'] = { class = 'Druid', color = 'FF7D0A' },
    ['innervate'] = { class = 'Druid', color = 'FF7D0A' },
    ['lifebloom'] = { class = 'Druid', color = 'FF7D0A' },
    ['nourish'] = { class = 'Druid', color = 'FF7D0A' },
    ['savage roar'] = { class = 'Druid', color = 'FF7D0A' },
    ['starfall'] = { class = 'Druid', color = 'FF7D0A' },
    ['force of nature'] = { class = 'Druid', color = 'FF7D0A' },
    ['typhoon'] = { class = 'Druid', color = 'FF7D0A' },
    ['insect swarm'] = { class = 'Druid', color = 'FF7D0A' },
    ['moonkin form'] = { class = 'Druid', color = 'FF7D0A' },
    ['eclipse'] = { class = 'Druid', color = 'FF7D0A' },
    ['earth and moon'] = { class = 'Druid', color = 'FF7D0A' },
    ['mangle'] = { class = 'Druid', color = 'FF7D0A' },
    ['mangle (cat)'] = { class = 'Druid', color = 'FF7D0A' },
    ['mangle (bear)'] = { class = 'Druid', color = 'FF7D0A' },
    ['feral charge'] = { class = 'Druid', color = 'FF7D0A' },
    ['feral charge - bear'] = { class = 'Druid', color = 'FF7D0A' },
    ['feral charge - cat'] = { class = 'Druid', color = 'FF7D0A' },
    ['berserk'] = { class = 'Druid', color = 'FF7D0A' },
    ['survival instincts'] = { class = 'Druid', color = 'FF7D0A' },
    ['leader of the pack'] = { class = 'Druid', color = 'FF7D0A' },
    ['predatory strikes'] = { class = 'Druid', color = 'FF7D0A' },
    ['king of the jungle'] = { class = 'Druid', color = 'FF7D0A' },
    ['tree of life'] = { class = 'Druid', color = 'FF7D0A' },
    ['swiftmend'] = { class = 'Druid', color = 'FF7D0A' },
    ['wild growth'] = { class = 'Druid', color = 'FF7D0A' },
    ['living seed'] = { class = 'Druid', color = 'FF7D0A' },
    ['nature\'s swiftness'] = { class = 'Druid', color = 'FF7D0A' },
    ['omen of clarity'] = { class = 'Druid', color = 'FF7D0A' },
};

-- Detect ability class for Ascension 3.3.5a using known ability database
local function GetSpellClass(spellID)
    if not spellID then return "General", "FFFFFF" end

    -- Check Ascension specific class API if present
    if type(GetClasslessSpellClass) == "function" then
        local cToken = GetClasslessSpellClass(spellID)
        if cToken and CLASS_COLORS[cToken] then
            return cToken:sub(1,1) .. cToken:sub(2):lower(), CLASS_COLORS[cToken]
        end
    end

    -- Check spell info
    local name, _, _, _, _, _, _, _, _ = GetSpellInfo(spellID)
    if not name then return "General", "D4AF37" end

    -- 1. Direct match in known abilities & talents database
    local sName = name:lower():gsub("%s*%b()", ""):match("^%s*(.-)%s*$")
    if sName and KNOWN_SPELL_CLASSES[sName] then
        local entry = KNOWN_SPELL_CLASSES[sName]
        return entry.class, entry.color
    end

    -- 2. Substring/prefix search in known abilities database
    if sName and sName ~= "" then
        for kName, entry in pairs(KNOWN_SPELL_CLASSES) do
            if sName:find(kName, 1, true) or kName:find(sName, 1, true) then
                return entry.class, entry.color
            end
        end
    end

    return "General", "D4AF37"
end

-- Get number of specializations available (accounts for 2 or more coming soon)
local function GetTotalSpecs()
    local num = 2
    if type(GetNumTalentGroups) == "function" then
        num = math.max(num, GetNumTalentGroups())
    end
    return num
end

-- Forward declaration of RefreshPoolList
local RefreshPoolList

------------------------------------------------------
-- 1. Main Window Frame Creation (ElvUI Flat Minimalist Style)
------------------------------------------------------
-- ElvUI Flat Matte Styling Helper (1px black border, #111111 dark charcoal background)
local function SetElvUIStyle(frame, bgColor, borderColor)
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false, tileSize = 0, edgeSize = 1,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    local bg = bgColor or { 0.066, 0.066, 0.066, 0.95 }
    local border = borderColor or { 0, 0, 0, 1 }
    frame:SetBackdropColor(bg[1], bg[2], bg[3], bg[4] or 1)
    frame:SetBackdropBorderColor(border[1], border[2], border[3], border[4] or 1)
end

local MainFrame = CreateFrame("Frame", "SpellViewerFrame", UIParent)
MainFrame:SetSize(540, 460)
MainFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
MainFrame:SetFrameStrata("MEDIUM")
MainFrame:SetToplevel(true)
MainFrame:EnableMouse(true)
MainFrame:SetMovable(true)
MainFrame:RegisterForDrag("LeftButton")
MainFrame:SetScript("OnDragStart", MainFrame.StartMoving)
MainFrame:SetScript("OnDragStop", MainFrame.StopMovingOrSizing)
MainFrame:SetClampedToScreen(true)

-- Authentic ElvUI 1px border & flat dark background
SetElvUIStyle(MainFrame, { 0.066, 0.066, 0.066, 0.97 }, { 0, 0, 0, 1 })

-- Inner accent ring (Classic ElvUI 1px inside border)
local InnerBorder = CreateFrame("Frame", nil, MainFrame)
InnerBorder:SetPoint("TOPLEFT", MainFrame, "TOPLEFT", 1, -1)
InnerBorder:SetPoint("BOTTOMRIGHT", MainFrame, "BOTTOMRIGHT", -1, 1)
SetElvUIStyle(InnerBorder, { 0, 0, 0, 0 }, { 0.16, 0.16, 0.16, 1 })

-- ElvUI Header Bar
local HeaderBar = CreateFrame("Frame", nil, MainFrame)
HeaderBar:SetHeight(26)
HeaderBar:SetPoint("TOPLEFT", MainFrame, "TOPLEFT", 2, -2)
HeaderBar:SetPoint("TOPRIGHT", MainFrame, "TOPRIGHT", -2, -2)
SetElvUIStyle(HeaderBar, { 0.09, 0.09, 0.09, 1 }, { 0, 0, 0, 1 })

local TitleText = HeaderBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
TitleText:SetPoint("LEFT", HeaderBar, "LEFT", 8, 0)
TitleText:SetText("|cff00c0fa[SpellViewer]|r |cffffffffWildcard Roll Pool|r")

-- ElvUI Flat Square Close Button
local CloseBtn = CreateFrame("Button", nil, HeaderBar)
CloseBtn:SetSize(18, 18)
CloseBtn:SetPoint("RIGHT", HeaderBar, "RIGHT", -4, 0)
SetElvUIStyle(CloseBtn, { 0.12, 0.12, 0.12, 1 }, { 0, 0, 0, 1 })

local closeText = CloseBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
closeText:SetPoint("CENTER", 0, 0)
closeText:SetText("x")
closeText:SetTextColor(0.7, 0.7, 0.7, 1)
CloseBtn:SetScript("OnEnter", function(self)
    self:SetBackdropColor(0.77, 0.12, 0.23, 1)
    closeText:SetTextColor(1, 1, 1, 1)
end)
CloseBtn:SetScript("OnLeave", function(self)
    self:SetBackdropColor(0.12, 0.12, 0.12, 1)
    closeText:SetTextColor(0.7, 0.7, 0.7, 1)
end)
CloseBtn:SetScript("OnClick", function()
    MainFrame:Hide()
end)

------------------------------------------------------
-- 2. Specialization Header & Dropdown Selector (ElvUI Style)
------------------------------------------------------
-- Active Specialization Display Text (Top of window)
local ActiveSpecText = MainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
ActiveSpecText:SetPoint("TOPLEFT", MainFrame, "TOPLEFT", 12, -34)
ActiveSpecText:SetText("Active Spec: |cff00c0faSpec 1|r")

local function UpdateActiveSpecHeader()
    local activeSpec = 1
    if type(GetActiveTalentGroup) == "function" then
        activeSpec = GetActiveTalentGroup() or 1
    end
    ActiveSpecText:SetText("Active Spec: |cff00c0faSpec " .. activeSpec .. "|r")
end

-- Specialization Dropdown Frame
local SpecDropdown = CreateFrame("Frame", "SpellViewerSpecDropdown", MainFrame, "UIDropDownMenuTemplate")
SpecDropdown:SetPoint("TOPRIGHT", MainFrame, "TOPRIGHT", 8, -28)

local function SpecDropdown_OnClick(self)
    viewedSpec = self.value
    UIDropDownMenu_SetSelectedValue(SpecDropdown, viewedSpec)
    UIDropDownMenu_SetText(SpecDropdown, "View: Spec " .. viewedSpec)
    RefreshPoolList()
end

local function SpecDropdown_Initialize(self, level)
    local activeSpec = (type(GetActiveTalentGroup) == "function" and GetActiveTalentGroup()) or 1
    local totalSpecs = GetTotalSpecs()

    for i = 1, totalSpecs do
        local info = UIDropDownMenu_CreateInfo()
        local isCurrent = (i == activeSpec)
        info.text = "Spec " .. i .. (isCurrent and " |cff00c0fa(Active)|r" or "")
        info.value = i
        info.func = SpecDropdown_OnClick
        info.checked = (i == viewedSpec)
        UIDropDownMenu_AddButton(info)
    end
end

UIDropDownMenu_Initialize(SpecDropdown, SpecDropdown_Initialize)
UIDropDownMenu_SetWidth(SpecDropdown, 115)
UIDropDownMenu_SetSelectedValue(SpecDropdown, 1)
UIDropDownMenu_SetText(SpecDropdown, "View: Spec 1")

-- Sub-bar info text
local PoolInfoText = MainFrame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
PoolInfoText:SetPoint("TOPLEFT", MainFrame, "TOPLEFT", 12, -56)
PoolInfoText:SetPoint("TOPRIGHT", MainFrame, "TOPRIGHT", -12, -56)
PoolInfoText:SetJustifyH("LEFT")
PoolInfoText:SetText("Viewing pool for Spec 1. Rolls save to your active spec.")

-- Empty / Status Message Text
local StatusText = MainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
StatusText:SetPoint("CENTER", MainFrame, "CENTER", 0, 10)
StatusText:SetWidth(320)
StatusText:SetJustifyH("CENTER")
StatusText:SetText("|cffff5555Make sure you re-rolled an ability|r")

------------------------------------------------------
-- 3. Ability List Scroll Frame & Rows (ElvUI Styled)
------------------------------------------------------
local ROW_HEIGHT = 36
local NUM_ROWS = 10
local rows = {}

local ScrollFrame = CreateFrame("ScrollFrame", "SpellViewerScrollFrame", MainFrame, "FauxScrollFrameTemplate")
ScrollFrame:SetPoint("TOPLEFT", 10, -74)
ScrollFrame:SetPoint("BOTTOMRIGHT", -160, 24)

local function UpdateScrollList()
    local total = #displayedList
    FauxScrollFrame_Update(ScrollFrame, total, NUM_ROWS, ROW_HEIGHT)
    local offset = FauxScrollFrame_GetOffset(ScrollFrame)

    for i = 1, NUM_ROWS do
        local row = rows[i]
        local idx = offset + i

        if idx <= total then
            local item = displayedList[idx]
            if item.isHeader then
                -- Class Section Header (ElvUI style with Expand/Collapse indicator)
                row.isHeader = true
                row.headerClass = item.className
                row.spellID = nil
                row:SetBackdropColor(0.08, 0.08, 0.10, 1)
                row:SetBackdropBorderColor(0, 0, 0, 1)
                row.accentBar:Show()

                -- Set accent color based on class color hex
                local r, g, b = 1, 1, 1
                if item.classColor and #item.classColor == 6 then
                    r = (tonumber(item.classColor:sub(1, 2), 16) or 255) / 255
                    g = (tonumber(item.classColor:sub(3, 4), 16) or 255) / 255
                    b = (tonumber(item.classColor:sub(5, 6), 16) or 255) / 255
                end
                row.accentBar:SetVertexColor(r, g, b, 1)

                row.iconBorder:Hide()
                row.nameText:SetPoint("LEFT", row, "LEFT", 12, 0)
                local indicator = item.isCollapsed and "|cff00c0fa[+]|r " or "|cff888888[-]|r "
                row.nameText:SetText(indicator .. "|cff" .. item.classColor .. item.className:upper() .. "|r")
                local countSuffix = item.isCollapsed and " (Collapsed)" or ""
                row.classText:SetText("|cff888888" .. item.count .. (item.count == 1 and " ability" or " abilities") .. countSuffix .. "|r")
            else
                -- Ability Row (ElvUI style)
                row.isHeader = false
                row.headerClass = nil
                row.spellID = item.id
                row:SetBackdropColor(0.05, 0.05, 0.06, 0.95)
                row:SetBackdropBorderColor(0, 0, 0, 1)
                row.accentBar:Hide()

                row.iconBorder:Show()
                row.icon:SetTexture(item.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
                row.nameText:SetPoint("LEFT", row.iconBorder, "RIGHT", 8, 0)
                row.nameText:SetText(item.name or ("Spell #" .. item.id))
                row.classText:SetText("|cff" .. item.classColor .. item.className .. "|r")
            end
            row:Show()
        else
            row:Hide()
        end
    end
end

ScrollFrame:SetScript("OnVerticalScroll", function(self, offset)
    FauxScrollFrame_OnVerticalScroll(self, offset, ROW_HEIGHT, UpdateScrollList)
end)

-- Create visual row buttons on left side
for i = 1, NUM_ROWS do
    local row = CreateFrame("Button", "SpellViewerRow"..i, MainFrame)
    row:SetHeight(ROW_HEIGHT - 2)
    row:SetPoint("TOPLEFT", MainFrame, "TOPLEFT", 10, -74 - ((i - 1) * ROW_HEIGHT))
    row:SetPoint("TOPRIGHT", MainFrame, "TOPRIGHT", -160, -74 - ((i - 1) * ROW_HEIGHT))

    SetElvUIStyle(row, { 0.05, 0.05, 0.06, 0.95 }, { 0, 0, 0, 1 })

    -- Left Accent Bar for Class Section Headers
    local accentBar = row:CreateTexture(nil, "ARTWORK")
    accentBar:SetTexture("Interface\\Buttons\\WHITE8X8")
    accentBar:SetSize(3, ROW_HEIGHT - 2)
    accentBar:SetPoint("LEFT", row, "LEFT", 0, 0)
    accentBar:Hide()
    row.accentBar = accentBar

    -- Icon Container (ElvUI Sharp 1px Border)
    local iconBorder = CreateFrame("Frame", nil, row)
    iconBorder:SetSize(26, 26)
    iconBorder:SetPoint("LEFT", row, "LEFT", 4, 0)
    SetElvUIStyle(iconBorder, { 0, 0, 0, 1 }, { 0, 0, 0, 1 })
    row.iconBorder = iconBorder

    local icon = iconBorder:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("TOPLEFT", iconBorder, "TOPLEFT", 1, -1)
    icon:SetPoint("BOTTOMRIGHT", iconBorder, "BOTTOMRIGHT", -1, 1)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92) -- ElvUI Zoomed Crop
    row.icon = icon

    -- Ability Name
    local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    nameText:SetPoint("LEFT", iconBorder, "RIGHT", 8, 0)
    nameText:SetJustifyH("LEFT")
    nameText:SetWidth(180)
    row.nameText = nameText

    -- Class Name
    local classText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    classText:SetPoint("RIGHT", row, "RIGHT", -8, 0)
    classText:SetJustifyH("RIGHT")
    row.classText = classText

    -- Click handler for expanding / collapsing class sections
    row:SetScript("OnClick", function(self)
        if self.isHeader and self.headerClass then
            collapsedClasses[self.headerClass] = not collapsedClasses[self.headerClass]
            RefreshPoolList()
        end
    end)

    -- Hover highlight & Tooltip
    row:SetScript("OnEnter", function(self)
        if self.isHeader then
            self:SetBackdropColor(0.14, 0.14, 0.16, 1)
            self:SetBackdropBorderColor(0, 0.75, 0.98, 0.6)
            if self.headerClass then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:AddLine(self.headerClass, 1, 1, 1)
                GameTooltip:AddLine("Click to expand or collapse this class section", 0.7, 0.7, 0.7)
                GameTooltip:Show()
            end
        else
            self:SetBackdropColor(0.12, 0.12, 0.14, 1)
            self:SetBackdropBorderColor(0, 0.75, 0.98, 1) -- #00c0fa
            if self.spellID then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetHyperlink("spell:"..self.spellID)
                GameTooltip:Show()
            end
        end
    end)

    row:SetScript("OnLeave", function(self)
        if self.isHeader then
            self:SetBackdropColor(0.08, 0.08, 0.10, 1)
            self:SetBackdropBorderColor(0, 0, 0, 1)
        else
            self:SetBackdropColor(0.05, 0.05, 0.06, 0.95)
            self:SetBackdropBorderColor(0, 0, 0, 1)
        end
        GameTooltip:Hide()
    end)

    row:Hide()
    rows[i] = row
end

-- ElvUI Clean ScrollBar Styling (Anchored cleanly with dedicated clearance)
local scrollBar = _G["SpellViewerScrollFrameScrollBar"]
if scrollBar then
    scrollBar:ClearAllPoints()
    scrollBar:SetPoint("TOPLEFT", ScrollFrame, "TOPRIGHT", 4, -16)
    scrollBar:SetPoint("BOTTOMLEFT", ScrollFrame, "BOTTOMRIGHT", 4, 16)
    scrollBar:SetWidth(12)
    local thumb = _G["SpellViewerScrollFrameScrollBarThumbTexture"]
    if thumb then
        thumb:SetTexture("Interface\\Buttons\\WHITE8X8")
        thumb:SetVertexColor(0.22, 0.22, 0.25, 1)
        thumb:SetWidth(10)
    end
end

-- Refresh and populate list grouped by class and sorted alphabetically (A-Z)
RefreshPoolList = function()
    wipe(displayedList)
    UpdateActiveSpecHeader()

    local activeSpec = 1
    if type(GetActiveTalentGroup) == "function" then
        activeSpec = GetActiveTalentGroup() or 1
    end

    -- Update sub-bar message
    if viewedSpec == activeSpec then
        PoolInfoText:SetText("Viewing pool for |cff00c0faSpec " .. viewedSpec .. " (Active)|r")
    else
        PoolInfoText:SetText("Viewing pool for |cffffd100Spec " .. viewedSpec .. " (Saved)|r | Rolls save to Spec " .. activeSpec)
    end

    -- Requirement 5: If gfPool has no abilities available load them from persistent storage
    local rawPool = nil
    if viewedSpec == activeSpec and GFPOOL and #GFPOOL > 0 then
        rawPool = GFPOOL
    elseif SpellViewerDB.pools and SpellViewerDB.pools[viewedSpec] and #SpellViewerDB.pools[viewedSpec] > 0 then
        rawPool = SpellViewerDB.pools[viewedSpec]
    end

    if not rawPool or #rawPool == 0 then
        StatusText:SetText("|cffff5555Make sure you re-rolled an ability|r")
        StatusText:Show()
        ScrollFrame:Hide()
        for i = 1, NUM_ROWS do rows[i]:Hide() end
        return
    end

    -- 1. Gather all spell info and group by class
    local grouped = {}
    local classOrder = {}

    for _, spellID in ipairs(rawPool) do
        if spellID then
            local name, _, icon = GetSpellInfo(spellID)
            local className, classColor = GetSpellClass(spellID)
            local spellItem = {
                id = spellID,
                name = name or ("Spell #" .. spellID),
                icon = icon or "Interface\\Icons\\INV_Misc_QuestionMark",
                className = className,
                classColor = classColor,
            }

            if not grouped[className] then
                grouped[className] = {
                    className = className,
                    classColor = classColor,
                    spells = {},
                }
                table.insert(classOrder, className)
            end
            table.insert(grouped[className].spells, spellItem)
        end
    end

    -- 2. Sort class sections alphabetically (A-Z)
    table.sort(classOrder, function(a, b)
        return a:lower() < b:lower()
    end)

    -- 3. Sort abilities within each class alphabetically ascending by name (A-Z)
    for _, cName in ipairs(classOrder) do
        local grp = grouped[cName]
        table.sort(grp.spells, function(a, b)
            return a.name:lower() < b.name:lower()
        end)

        -- 4. Flatten into displayedList: Header followed by sorted abilities (if not collapsed)
        local isCollapsed = collapsedClasses[grp.className]
        table.insert(displayedList, {
            isHeader = true,
            className = grp.className,
            classColor = grp.classColor,
            count = #grp.spells,
            isCollapsed = isCollapsed,
        })

        if not isCollapsed then
            for _, sp in ipairs(grp.spells) do
                table.insert(displayedList, {
                    isHeader = false,
                    id = sp.id,
                    name = sp.name,
                    icon = sp.icon,
                    className = sp.className,
                    classColor = sp.classColor,
                })
            end
        end
    end

    if #displayedList == 0 then
        StatusText:SetText("|cffff5555Make sure you re-rolled an ability|r")
        StatusText:Show()
        ScrollFrame:Hide()
        for i = 1, NUM_ROWS do rows[i]:Hide() end
    else
        StatusText:Hide()
        ScrollFrame:Show()
        UpdateScrollList()
    end

    if UpdateChangesSection then
        UpdateChangesSection()
    end
end

------------------------------------------------------
-- 4. Roll Pool Changes Section (To the Right of Ability List)
------------------------------------------------------
-- Distinct Vertical Separator between Ability List and Changes Panel
local SectionDivider = CreateFrame("Frame", nil, MainFrame)
SectionDivider:SetWidth(2)
SectionDivider:SetPoint("TOPLEFT", MainFrame, "TOPRIGHT", -136, -74)
SectionDivider:SetPoint("BOTTOMLEFT", MainFrame, "BOTTOMRIGHT", -136, 24)
SetElvUIStyle(SectionDivider, { 0.18, 0.18, 0.20, 1 }, { 0, 0, 0, 1 })

local ChangesPanel = CreateFrame("Frame", "SpellViewerChangesPanel", MainFrame)
ChangesPanel:SetPoint("TOPLEFT", MainFrame, "TOPRIGHT", -128, -74)
ChangesPanel:SetPoint("BOTTOMRIGHT", MainFrame, "BOTTOMRIGHT", -10, 24)
SetElvUIStyle(ChangesPanel, { 0.05, 0.05, 0.06, 0.98 }, { 0, 0, 0, 1 })

local ChangesHeader = CreateFrame("Frame", "SpellViewerChangesHeader", ChangesPanel)
ChangesHeader:SetHeight(22)
ChangesHeader:SetPoint("TOPLEFT", ChangesPanel, "TOPLEFT", 0, 0)
ChangesHeader:SetPoint("TOPRIGHT", ChangesPanel, "TOPRIGHT", 0, 0)
SetElvUIStyle(ChangesHeader, { 0.09, 0.09, 0.11, 1 }, { 0, 0, 0, 1 })

local changesTitle = ChangesHeader:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
changesTitle:SetPoint("LEFT", ChangesHeader, "LEFT", 6, 0)
changesTitle:SetText("|cff00c0faChanges|r")

local changesBadge = ChangesHeader:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
changesBadge:SetPoint("RIGHT", ChangesHeader, "RIGHT", -6, 0)
changesBadge:SetText("")

-- Gained Subpanel (Top Half - 3x3 Icon Grid)
local GainedBox = CreateFrame("Frame", nil, ChangesPanel)
GainedBox:SetPoint("TOPLEFT", ChangesHeader, "BOTTOMLEFT", 4, -4)
GainedBox:SetPoint("BOTTOMRIGHT", ChangesPanel, "RIGHT", -4, 4)
SetElvUIStyle(GainedBox, { 0.04, 0.09, 0.06, 0.95 }, { 0.1, 0.26, 0.16, 1 })

local GainedTitle = GainedBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
GainedTitle:SetPoint("TOPLEFT", GainedBox, "TOPLEFT", 6, -5)
GainedTitle:SetText("|cff00ff88+ Gained|r")

local GainedCount = GainedBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
GainedCount:SetPoint("TOPRIGHT", GainedBox, "TOPRIGHT", -6, -5)
GainedCount:SetText("|cff00ff880|r")

local GRID_SIZE = 28
local GRID_GAP = 3
local START_X = 6
local START_Y = -22

-- Create 3x3 grid for Gained
local gainedButtons = {}
for i = 1, 9 do
    local row = math.floor((i - 1) / 3)
    local col = (i - 1) % 3
    local btn = CreateFrame("Button", "SpellViewerGainedSlot" .. i, GainedBox)
    btn:SetSize(GRID_SIZE, GRID_SIZE)
    btn:SetPoint("TOPLEFT", GainedBox, "TOPLEFT", START_X + (col * (GRID_SIZE + GRID_GAP)), START_Y - (row * (GRID_SIZE + GRID_GAP)))
    SetElvUIStyle(btn, { 0.02, 0.04, 0.03, 1 }, { 0.1, 0.35, 0.18, 1 })

    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("TOPLEFT", btn, "TOPLEFT", 1, -1)
    icon:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -1, 1)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    icon:Hide()
    btn.icon = icon

    btn:SetScript("OnEnter", function(self)
        if self.spellID then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetHyperlink("spell:" .. self.spellID)
            GameTooltip:Show()
        end
    end)
    btn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    gainedButtons[i] = btn
end

-- Lost Subpanel (Bottom Half - 3x3 Icon Grid)
local LostBox = CreateFrame("Frame", nil, ChangesPanel)
LostBox:SetPoint("TOPLEFT", ChangesPanel, "LEFT", 4, -4)
LostBox:SetPoint("BOTTOMRIGHT", ChangesPanel, "BOTTOMRIGHT", -4, 4)
SetElvUIStyle(LostBox, { 0.09, 0.04, 0.05, 0.95 }, { 0.28, 0.1, 0.13, 1 })

local LostTitle = LostBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
LostTitle:SetPoint("TOPLEFT", LostBox, "TOPLEFT", 6, -5)
LostTitle:SetText("|cffff5555- Lost|r")

local LostCount = LostBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
LostCount:SetPoint("TOPRIGHT", LostBox, "TOPRIGHT", -6, -5)
LostCount:SetText("|cffff55550|r")

-- Create 3x3 grid for Lost
local lostButtons = {}
for i = 1, 9 do
    local row = math.floor((i - 1) / 3)
    local col = (i - 1) % 3
    local btn = CreateFrame("Button", "SpellViewerLostSlot" .. i, LostBox)
    btn:SetSize(GRID_SIZE, GRID_SIZE)
    btn:SetPoint("TOPLEFT", LostBox, "TOPLEFT", START_X + (col * (GRID_SIZE + GRID_GAP)), START_Y - (row * (GRID_SIZE + GRID_GAP)))
    SetElvUIStyle(btn, { 0.04, 0.02, 0.02, 1 }, { 0.35, 0.1, 0.15, 1 })

    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("TOPLEFT", btn, "TOPLEFT", 1, -1)
    icon:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -1, 1)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    icon:Hide()
    btn.icon = icon

    btn:SetScript("OnEnter", function(self)
        if self.spellID then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetHyperlink("spell:" .. self.spellID)
            GameTooltip:Show()
        end
    end)
    btn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    lostButtons[i] = btn
end

UpdateChangesSection = function()
    local changes = SpellViewerDB and SpellViewerDB.recentChanges and SpellViewerDB.recentChanges[viewedSpec]
    local gainedList = (changes and changes.gained) or {}
    local lostList = (changes and changes.lost) or {}
    local numGained = #gainedList
    local numLost = #lostList

    if numGained > 0 or numLost > 0 then
        changesBadge:SetText("|cff00ff88+" .. numGained .. "|r |cffff5555-" .. numLost .. "|r")
    else
        changesBadge:SetText("")
    end

    GainedCount:SetText("|cff00ff88" .. numGained .. "|r")
    LostCount:SetText("|cffff5555" .. numLost .. "|r")

    for i = 1, 9 do
        local gBtn = gainedButtons[i]
        if i <= numGained then
            local sid = gainedList[i]
            gBtn.spellID = sid
            local sIcon = select(3, GetSpellInfo(sid)) or "Interface\\Icons\\INV_Misc_QuestionMark"
            gBtn.icon:SetTexture(sIcon)
            gBtn.icon:Show()
            gBtn:SetAlpha(1)
        else
            gBtn.spellID = nil
            gBtn.icon:Hide()
            gBtn:SetAlpha(0.25)
        end

        local lBtn = lostButtons[i]
        if i <= numLost then
            local sid = lostList[i]
            lBtn.spellID = sid
            local sIcon = select(3, GetSpellInfo(sid)) or "Interface\\Icons\\INV_Misc_QuestionMark"
            lBtn.icon:SetTexture(sIcon)
            lBtn.icon:Show()
            lBtn:SetAlpha(0.85)
        else
            lBtn.spellID = nil
            lBtn.icon:Hide()
            lBtn:SetAlpha(0.25)
        end
    end
end

------------------------------------------------------
-- 5. Status Bar Info (Auto-Sync Active)
------------------------------------------------------
local FooterStatusText = MainFrame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
FooterStatusText:SetPoint("BOTTOMLEFT", MainFrame, "BOTTOMLEFT", 12, 8)
FooterStatusText:SetPoint("BOTTOMRIGHT", MainFrame, "BOTTOMRIGHT", -12, 8)
FooterStatusText:SetJustifyH("LEFT")
FooterStatusText:SetText("|cff00ff88Auto-sync active|r | Click headers to expand/collapse")

------------------------------------------------------
-- 6. Minimap Toggle Button (ElvUI Square Minimalist)
------------------------------------------------------
local MinimapBtn = CreateFrame("Button", "SpellViewerMinimapButton", Minimap)
MinimapBtn:SetSize(26, 26)
MinimapBtn:SetFrameStrata("MEDIUM")
MinimapBtn:SetToplevel(true)
SetElvUIStyle(MinimapBtn, { 0.08, 0.08, 0.08, 1 }, { 0, 0, 0, 1 })

local btnIcon = MinimapBtn:CreateTexture(nil, "ARTWORK")
btnIcon:SetPoint("TOPLEFT", MinimapBtn, "TOPLEFT", 2, -2)
btnIcon:SetPoint("BOTTOMRIGHT", MinimapBtn, "BOTTOMRIGHT", -2, 2)
btnIcon:SetTexture("Interface\\Icons\\Spell_Holy_MagicalSentry")
btnIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92) -- ElvUI Zoomed Crop

local function UpdateMinimapButtonPosition(angle)
    local rad = math.rad(angle or SpellViewerDB.minimapPos or 220)
    local radius = 80
    local x = math.cos(rad) * radius
    local y = math.sin(rad) * radius
    MinimapBtn:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

local isDragging = false
MinimapBtn:RegisterForDrag("RightButton", "LeftButton")
MinimapBtn:RegisterForClicks("AnyUp")

MinimapBtn:SetScript("OnDragStart", function(self)
    isDragging = true
end)

MinimapBtn:SetScript("OnDragStop", function(self)
    isDragging = false
end)

MinimapBtn:SetScript("OnUpdate", function(self)
    if isDragging then
        local mx, my = Minimap:GetCenter()
        local cx, cy = GetCursorPosition()
        local scale = Minimap:GetEffectiveScale()
        cx, cy = cx / scale, cy / scale
        local angle = math.deg(math.atan2(cy - my, cx - mx))
        if angle < 0 then angle = angle + 360 end
        SpellViewerDB.minimapPos = angle
        UpdateMinimapButtonPosition(angle)
    end
end)

MinimapBtn:SetScript("OnClick", function(self, button)
    if button == "LeftButton" and not isDragging then
        if MainFrame:IsShown() then
            MainFrame:Hide()
        else
            MainFrame:Show()
            RefreshPoolList()
        end
    end
end)

MinimapBtn:SetScript("OnEnter", function(self)
    self:SetBackdropBorderColor(0, 0.75, 0.98, 1) -- ElvUI Cyan
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:AddLine("|cff00c0fa[SpellViewer]|r")
    GameTooltip:AddLine("Left-Click: |cffffffffToggle Wildcard Window|r", 0.8, 0.8, 0.8)
    GameTooltip:AddLine("Right-Click & Drag: |cffffffffMove Minimap Button|r", 0.8, 0.8, 0.8)
    GameTooltip:Show()
end)

MinimapBtn:SetScript("OnLeave", function(self)
    self:SetBackdropBorderColor(0, 0, 0, 1)
    GameTooltip:Hide()
end)

------------------------------------------------------
-- 6. Automatic Recording on Addon Load & Event Registry
------------------------------------------------------
SLASH_SPELLVIEWER1 = "/spellviewer"
SLASH_SPELLVIEWER2 = "/sv"
SlashCmdList["SPELLVIEWER"] = function()
    if MainFrame:IsShown() then
        MainFrame:Hide()
    else
        MainFrame:Show()
        RefreshPoolList()
    end
end

-- Requirement 2: Start recording automatically when addon loads
local InitFrame = CreateFrame("Frame")
InitFrame:RegisterEvent("PLAYER_LOGIN")
InitFrame:RegisterEvent("PLAYER_LOGOUT")
InitFrame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")

InitFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        -- Initialize persistent storage tables
        SpellViewerDB = SpellViewerDB or {}
        SpellViewerDB.pools = SpellViewerDB.pools or {}
        
        UpdateMinimapButtonPosition(SpellViewerDB.minimapPos or 220)
        
        -- Automatic recording initialization
        if type(FlushClasslessWildcardSpellRollResults) == "function" then
            FlushClasslessWildcardSpellRollResults()
        end

        GF = GF or CreateFrame("Frame")
        GF:RegisterEvent("CUSTOM_CLASSLESS_WILDCARD_SPELL_ROLLED")

        -- Table to save pool before reroll (User logic: GF1={}; for i,v in ipairs(GFPOOL) do GF1[i]=v end)
        GF1 = GF1 or {}

        -- Requirement 6: When pool changes, save for ACTIVE player specialization
        GF:SetScript("OnEvent", function(subSelf, rollEvent, id)
            GFLAST = id
            local activeSpec = 1
            if type(GetActiveTalentGroup) == "function" then
                activeSpec = GetActiveTalentGroup() or 1
            end

            -- 1. Save pool before reroll (GF1)
            wipe(GF1)
            local prevPool = (GFPOOL and #GFPOOL > 0 and GFPOOL) or (SpellViewerDB.pools and SpellViewerDB.pools[activeSpec])
            if prevPool then
                for i, v in ipairs(prevPool) do
                    GF1[i] = v
                end
            end
            print("|cff00ccff[SpellViewer]|r SAVED " .. (#GF1) .. " abilities before reroll (GF1)")

            -- 2. Fetch new candidates
            if type(GetClasslessWildcardRollCandidates) == "function" then
                GFPOOL = GetClasslessWildcardRollCandidates(id)
            end

            -- 3. Print & collect GAINED and LOST abilities (Ascension macro logic)
            local gained = {}
            local lost = {}

            if GFPOOL and #GFPOOL > 0 and #GF1 > 0 then
                -- Check gained: in GFPOOL but not in GF1
                for _, v in ipairs(GFPOOL) do
                    local f = false
                    for _, x in ipairs(GF1) do
                        if x == v then f = true; break end
                    end
                    if not f then
                        table.insert(gained, v)
                        local sName = GetSpellInfo(v) or ("Spell #" .. v)
                        print("|cff00ff88[SpellViewer] GAINED:|r " .. v .. " " .. sName)
                    end
                end

                -- Check lost: in GF1 but not in GFPOOL
                for _, v in ipairs(GF1) do
                    local f = false
                    for _, x in ipairs(GFPOOL) do
                        if x == v then f = true; break end
                    end
                    if not f then
                        table.insert(lost, v)
                        local sName = GetSpellInfo(v) or ("Spell #" .. v)
                        print("|cffff5555[SpellViewer] LOST:|r " .. v .. " " .. sName)
                    end
                end
            end

            -- Persist to active specialization
            SpellViewerDB.pools[activeSpec] = GFPOOL
            
            -- Persist recent changes for activeSpec
            SpellViewerDB.recentChanges = SpellViewerDB.recentChanges or {}
            local sName = GetSpellInfo(id) or "Unknown"
            SpellViewerDB.recentChanges[activeSpec] = {
                rolledName = sName,
                rolledId = id,
                gained = gained,
                lost = lost,
            }

            print("|cff00ccff[SpellViewer]|r ROLLED: " .. (sName) .. " (" .. id .. ") | Pool: " .. (GFPOOL and #GFPOOL or 0) .. " | Changes: |cff00ff88+" .. #gained .. "|r / |cffff5555-" .. #lost .. "|r | Saved to Spec " .. activeSpec)
            
            -- If user is currently looking at active spec, live refresh
            if viewedSpec == activeSpec and MainFrame:IsShown() then
                RefreshPoolList()
            end
        end)

        local activeSpec = (type(GetActiveTalentGroup) == "function" and GetActiveTalentGroup()) or 1
        viewedSpec = activeSpec
        UIDropDownMenu_SetSelectedValue(SpecDropdown, viewedSpec)
        UIDropDownMenu_SetText(SpecDropdown, "View: Spec " .. viewedSpec)
        UpdateActiveSpecHeader()

        print("|cff00ccff[SpellViewer]|r loaded! Recording active. Active Spec: |cff00ff88" .. activeSpec .. "|r.")

    elseif event == "ACTIVE_TALENT_GROUP_CHANGED" then
        -- Requirement 3: Update player active specialization on talent change
        UpdateActiveSpecHeader()
        local activeSpec = (type(GetActiveTalentGroup) == "function" and GetActiveTalentGroup()) or 1
        print("|cff00ccff[SpellViewer]|r Active specialization switched to: Spec " .. activeSpec)
        if MainFrame:IsShown() then
            RefreshPoolList()
        end

    elseif event == "PLAYER_LOGOUT" then
        -- Requirement 4: Save current available ability pool on reload/game exit
        local activeSpec = (type(GetActiveTalentGroup) == "function" and GetActiveTalentGroup()) or 1
        if GFPOOL and #GFPOOL > 0 then
            SpellViewerDB.pools = SpellViewerDB.pools or {}
            SpellViewerDB.pools[activeSpec] = GFPOOL
        end
    end
end)
