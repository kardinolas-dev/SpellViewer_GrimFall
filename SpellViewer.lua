--[[
    SpellViewer - WoW 3.3.5a / Project Ascension Wildcard Roll Addon
    - Minimap button to toggle the window
    - Starts recording CUSTOM_CLASSLESS_WILDCARD_SPELL_ROLLED automatically on load
    - Displays player's Active Specialization at the top (dynamic, supports 2+ specs)
    - Dropdown to switch which specialization's ability/talent pool is viewed
    - Automatically persists ability pools & talent pools per specialization into SpellViewerDB
    - Two buttons to the left of the scrollable list switch between abilities and talents
    - Determines whether incoming roll is an ability or talent pool by checking first item
    - If pool is empty, loads from persistent storage or prompts: "Make sure you re-rolled an ability" / "Make sure you re-rolled a talent"
    - When rolls occur, always saves to the ACTIVE specialization (not the dropdown selection)
    - Item rows show icon, name, and class
]]--

-- Initialize SavedVariables
SpellViewerDB = SpellViewerDB or {
    minimapPos = 220,
    shown = false,          -- Default window state is closed when game starts
    viewMode = "abilities", -- "abilities" or "talents"
    pools = {},            -- [specIndex] = { spellID1, spellID2, ... }
    talentPools = {},      -- [specIndex] = { talentID1, talentID2, ... }
    lastActiveSpec = 1,
}

-- Global references matching Ascension wildcard roll script conventions
GF = GF or nil
GFLAST = GFLAST or nil
GFPOOL = GFPOOL or {}
GFTALENTPOOL = GFTALENTPOOL or {}
GF1 = GF1 or {}
GFTALENT1 = GFTALENT1 or {}

local viewedSpec = 1
local currentViewMode = "abilities"
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

-- Database of known abilities per class (auto-generated from classAbilities.ts)
local KNOWN_SPELL_CLASSES = {
    ['death coil'] = { class = 'Death Knight', color = 'C41F3B' },
    ['death grip'] = { class = 'Death Knight', color = 'C41F3B' },
    ['death strike'] = { class = 'Death Knight', color = 'C41F3B' },
    ['death and decay'] = { class = 'Death Knight', color = 'C41F3B' },
    ['heart strike'] = { class = 'Death Knight', color = 'C41F3B' },
    ['blood strike'] = { class = 'Death Knight', color = 'C41F3B' },
    ['blood boil'] = { class = 'Death Knight', color = 'C41F3B' },
    ['obliterate'] = { class = 'Death Knight', color = 'C41F3B' },
    ['frost strike'] = { class = 'Death Knight', color = 'C41F3B' },
    ['howling blast'] = { class = 'Death Knight', color = 'C41F3B' },
    ['icy touch'] = { class = 'Death Knight', color = 'C41F3B' },
    ['plague strike'] = { class = 'Death Knight', color = 'C41F3B' },
    ['scourge strike'] = { class = 'Death Knight', color = 'C41F3B' },
    ['festering strike'] = { class = 'Death Knight', color = 'C41F3B' },
    ['anti-magic shell'] = { class = 'Death Knight', color = 'C41F3B' },
    ['anti-magic zone'] = { class = 'Death Knight', color = 'C41F3B' },
    ['icebound fortitude'] = { class = 'Death Knight', color = 'C41F3B' },
    ['vampiric blood'] = { class = 'Death Knight', color = 'C41F3B' },
    ['rune tap'] = { class = 'Death Knight', color = 'C41F3B' },
    ['mind freeze'] = { class = 'Death Knight', color = 'C41F3B' },
    ['strangulate'] = { class = 'Death Knight', color = 'C41F3B' },
    ['chains of ice'] = { class = 'Death Knight', color = 'C41F3B' },
    ['path of frost'] = { class = 'Death Knight', color = 'C41F3B' },
    ['army of the dead'] = { class = 'Death Knight', color = 'C41F3B' },
    ['summon gargoyle'] = { class = 'Death Knight', color = 'C41F3B' },
    ['dancing rune weapon'] = { class = 'Death Knight', color = 'C41F3B' },
    ['breath of sindragosa'] = { class = 'Death Knight', color = 'C41F3B' },
    ['bonestorm'] = { class = 'Death Knight', color = 'C41F3B' },
    ['blood mirror'] = { class = 'Death Knight', color = 'C41F3B' },
    ['rune weapon'] = { class = 'Death Knight', color = 'C41F3B' },
    ['apocalypse'] = { class = 'Death Knight', color = 'C41F3B' },
    ['dark transformation'] = { class = 'Death Knight', color = 'C41F3B' },
    ['unholy frenzy'] = { class = 'Death Knight', color = 'C41F3B' },
    ['summon abomination'] = { class = 'Death Knight', color = 'C41F3B' },
    ['soul reaper'] = { class = 'Death Knight', color = 'C41F3B' },
    ['necrotic strike'] = { class = 'Death Knight', color = 'C41F3B' },
    ['death\'s advance'] = { class = 'Death Knight', color = 'C41F3B' },
    ['death\'s caress'] = { class = 'Death Knight', color = 'C41F3B' },
    ['wraith walk'] = { class = 'Death Knight', color = 'C41F3B' },
    ['lichborne'] = { class = 'Death Knight', color = 'C41F3B' },
    ['gorefiend\'s grasp'] = { class = 'Death Knight', color = 'C41F3B' },
    ['abomination limb'] = { class = 'Death Knight', color = 'C41F3B' },
    ['swarming mist'] = { class = 'Death Knight', color = 'C41F3B' },
    ['blood tap'] = { class = 'Death Knight', color = 'C41F3B' },
    ['runic empowerment'] = { class = 'Death Knight', color = 'C41F3B' },
    ['runic corruption'] = { class = 'Death Knight', color = 'C41F3B' },
    ['horn of winter'] = { class = 'Death Knight', color = 'C41F3B' },
    ['bone shield'] = { class = 'Death Knight', color = 'C41F3B' },
    ['death pact'] = { class = 'Death Knight', color = 'C41F3B' },
    ['raise dead'] = { class = 'Death Knight', color = 'C41F3B' },
    ['corpse explosion'] = { class = 'Death Knight', color = 'C41F3B' },
    ['blood presence'] = { class = 'Death Knight', color = 'C41F3B' },
    ['frost presence'] = { class = 'Death Knight', color = 'C41F3B' },
    ['unholy presence'] = { class = 'Death Knight', color = 'C41F3B' },
    ['pestilence'] = { class = 'Death Knight', color = 'C41F3B' },
    ['blood caked blade'] = { class = 'Death Knight', color = 'C41F3B' },
    ['threat of thassarian'] = { class = 'Death Knight', color = 'C41F3B' },
    ['killing machine'] = { class = 'Death Knight', color = 'C41F3B' },
    ['hungering cold'] = { class = 'Death Knight', color = 'C41F3B' },
    ['improved icy talons'] = { class = 'Death Knight', color = 'C41F3B' },
    ['improved unholy presence'] = { class = 'Death Knight', color = 'C41F3B' },
    ['master of ghouls'] = { class = 'Death Knight', color = 'C41F3B' },
    ['ghoul frenzy'] = { class = 'Death Knight', color = 'C41F3B' },
    ['night of the dead'] = { class = 'Death Knight', color = 'C41F3B' },
    ['unholy blight'] = { class = 'Death Knight', color = 'C41F3B' },
    ['bone armor'] = { class = 'Death Knight', color = 'C41F3B' },
    ['veteran of the third war'] = { class = 'Death Knight', color = 'C41F3B' },
    ['blade barrier'] = { class = 'Death Knight', color = 'C41F3B' },
    ['will of the necropolis'] = { class = 'Death Knight', color = 'C41F3B' },
    ['hysteria'] = { class = 'Death Knight', color = 'C41F3B' },
    ['spell deflection'] = { class = 'Death Knight', color = 'C41F3B' },
    ['improved blood presence'] = { class = 'Death Knight', color = 'C41F3B' },
    ['improved death strike'] = { class = 'Death Knight', color = 'C41F3B' },
    ['two-handed weapon specialization'] = { class = 'Death Knight', color = 'C41F3B' },
    ['might of mograine'] = { class = 'Death Knight', color = 'C41F3B' },
    ['bloody vengeance'] = { class = 'Death Knight', color = 'C41F3B' },
    ['abomination\'s might'] = { class = 'Death Knight', color = 'C41F3B' },
    ['unholy command'] = { class = 'Death Knight', color = 'C41F3B' },
    ['virulence'] = { class = 'Death Knight', color = 'C41F3B' },
    ['epidemic'] = { class = 'Death Knight', color = 'C41F3B' },
    ['morbidity'] = { class = 'Death Knight', color = 'C41F3B' },
    ['ravenous dead'] = { class = 'Death Knight', color = 'C41F3B' },
    ['outbreak'] = { class = 'Death Knight', color = 'C41F3B' },
    ['desecration'] = { class = 'Death Knight', color = 'C41F3B' },
    ['crypt fever'] = { class = 'Death Knight', color = 'C41F3B' },
    ['earthen power'] = { class = 'Death Knight', color = 'C41F3B' },
    ['wandering plague'] = { class = 'Death Knight', color = 'C41F3B' },
    ['reaping'] = { class = 'Death Knight', color = 'C41F3B' },
    ['improved raise dead'] = { class = 'Death Knight', color = 'C41F3B' },
    ['magic suppression'] = { class = 'Death Knight', color = 'C41F3B' },
    ['improved frost presence'] = { class = 'Death Knight', color = 'C41F3B' },
    ['toughness'] = { class = 'Death Knight', color = 'C41F3B' },
    ['icy reach'] = { class = 'Death Knight', color = 'C41F3B' },
    ['black ice'] = { class = 'Death Knight', color = 'C41F3B' },
    ['nerves of cold steel'] = { class = 'Death Knight', color = 'C41F3B' },
    ['improved icy touch'] = { class = 'Death Knight', color = 'C41F3B' },
    ['runic power mastery'] = { class = 'Death Knight', color = 'C41F3B' },
    ['annihilation'] = { class = 'Death Knight', color = 'C41F3B' },
    ['chill of the grave'] = { class = 'Death Knight', color = 'C41F3B' },
    ['endless winter'] = { class = 'Death Knight', color = 'C41F3B' },
    ['frigid dreadplate'] = { class = 'Death Knight', color = 'C41F3B' },
    ['glacier rot'] = { class = 'Death Knight', color = 'C41F3B' },
    ['blood of the north'] = { class = 'Death Knight', color = 'C41F3B' },
    ['unbreakable armor'] = { class = 'Death Knight', color = 'C41F3B' },
    ['improved blood strike'] = { class = 'Death Knight', color = 'C41F3B' },
    ['bladed armor'] = { class = 'Death Knight', color = 'C41F3B' },
    ['dark conviction'] = { class = 'Death Knight', color = 'C41F3B' },
    ['death rune mastery'] = { class = 'Death Knight', color = 'C41F3B' },
    ['improved rune tap'] = { class = 'Death Knight', color = 'C41F3B' },
    ['vampiric blood'] = { class = 'Death Knight', color = 'C41F3B' },
    ['heart strike'] = { class = 'Death Knight', color = 'C41F3B' },
    ['hysteria'] = { class = 'Death Knight', color = 'C41F3B' },
    ['dancing rune weapon'] = { class = 'Death Knight', color = 'C41F3B' },
    ['might of mograine'] = { class = 'Death Knight', color = 'C41F3B' },
    ['bloody vengeance'] = { class = 'Death Knight', color = 'C41F3B' },
    ['abomination\'s might'] = { class = 'Death Knight', color = 'C41F3B' },
    ['wrath'] = { class = 'Druid', color = 'FF7D0A' },
    ['starfire'] = { class = 'Druid', color = 'FF7D0A' },
    ['moonfire'] = { class = 'Druid', color = 'FF7D0A' },
    ['starsurge'] = { class = 'Druid', color = 'FF7D0A' },
    ['starfall'] = { class = 'Druid', color = 'FF7D0A' },
    ['ferocious bite'] = { class = 'Druid', color = 'FF7D0A' },
    ['rip'] = { class = 'Druid', color = 'FF7D0A' },
    ['rake'] = { class = 'Druid', color = 'FF7D0A' },
    ['shred'] = { class = 'Druid', color = 'FF7D0A' },
    ['swipe'] = { class = 'Druid', color = 'FF7D0A' },
    ['mangle'] = { class = 'Druid', color = 'FF7D0A' },
    ['thrash'] = { class = 'Druid', color = 'FF7D0A' },
    ['maul'] = { class = 'Druid', color = 'FF7D0A' },
    ['frenzied regeneration'] = { class = 'Druid', color = 'FF7D0A' },
    ['survival instincts'] = { class = 'Druid', color = 'FF7D0A' },
    ['barkskin'] = { class = 'Druid', color = 'FF7D0A' },
    ['ironbark'] = { class = 'Druid', color = 'FF7D0A' },
    ['healing touch'] = { class = 'Druid', color = 'FF7D0A' },
    ['regrowth'] = { class = 'Druid', color = 'FF7D0A' },
    ['rejuvenation'] = { class = 'Druid', color = 'FF7D0A' },
    ['wild growth'] = { class = 'Druid', color = 'FF7D0A' },
    ['lifebloom'] = { class = 'Druid', color = 'FF7D0A' },
    ['swiftmend'] = { class = 'Druid', color = 'FF7D0A' },
    ['nourish'] = { class = 'Druid', color = 'FF7D0A' },
    ['tranquility'] = { class = 'Druid', color = 'FF7D0A' },
    ['innervate'] = { class = 'Druid', color = 'FF7D0A' },
    ['rebirth'] = { class = 'Druid', color = 'FF7D0A' },
    ['mark of the wild'] = { class = 'Druid', color = 'FF7D0A' },
    ['thorns'] = { class = 'Druid', color = 'FF7D0A' },
    ['entangling roots'] = { class = 'Druid', color = 'FF7D0A' },
    ['hibernate'] = { class = 'Druid', color = 'FF7D0A' },
    ['cyclone'] = { class = 'Druid', color = 'FF7D0A' },
    ['bear form'] = { class = 'Druid', color = 'FF7D0A' },
    ['cat form'] = { class = 'Druid', color = 'FF7D0A' },
    ['travel form'] = { class = 'Druid', color = 'FF7D0A' },
    ['aquatic form'] = { class = 'Druid', color = 'FF7D0A' },
    ['flight form'] = { class = 'Druid', color = 'FF7D0A' },
    ['moonkin form'] = { class = 'Druid', color = 'FF7D0A' },
    ['tree of life'] = { class = 'Druid', color = 'FF7D0A' },
    ['incarnation'] = { class = 'Druid', color = 'FF7D0A' },
    ['convoke the spirits'] = { class = 'Druid', color = 'FF7D0A' },
    ['fury of elune'] = { class = 'Druid', color = 'FF7D0A' },
    ['adaptive swarm'] = { class = 'Druid', color = 'FF7D0A' },
    ['ravage'] = { class = 'Druid', color = 'FF7D0A' },
    ['berserk'] = { class = 'Druid', color = 'FF7D0A' },
    ['tiger\'s fury'] = { class = 'Druid', color = 'FF7D0A' },
    ['pulverize'] = { class = 'Druid', color = 'FF7D0A' },
    ['guardian of elune'] = { class = 'Druid', color = 'FF7D0A' },
    ['grove guardian'] = { class = 'Druid', color = 'FF7D0A' },
    ['flourish'] = { class = 'Druid', color = 'FF7D0A' },
    ['eclipse'] = { class = 'Druid', color = 'FF7D0A' },
    ['lunar guidance'] = { class = 'Druid', color = 'FF7D0A' },
    ['improved moonfire'] = { class = 'Druid', color = 'FF7D0A' },
    ['nature\'s grace'] = { class = 'Druid', color = 'FF7D0A' },
    ['nature\'s majesty'] = { class = 'Druid', color = 'FF7D0A' },
    ['vengeance'] = { class = 'Druid', color = 'FF7D0A' },
    ['dreamstate'] = { class = 'Druid', color = 'FF7D0A' },
    ['force of nature'] = { class = 'Druid', color = 'FF7D0A' },
    ['gale winds'] = { class = 'Druid', color = 'FF7D0A' },
    ['earth and moon'] = { class = 'Druid', color = 'FF7D0A' },
    ['typhoon'] = { class = 'Druid', color = 'FF7D0A' },
    ['owlkin frenzy'] = { class = 'Druid', color = 'FF7D0A' },
    ['improved insect swarm'] = { class = 'Druid', color = 'FF7D0A' },
    ['brambles'] = { class = 'Druid', color = 'FF7D0A' },
    ['nature\'s grasp'] = { class = 'Druid', color = 'FF7D0A' },
    ['furor'] = { class = 'Druid', color = 'FF7D0A' },
    ['feral instinct'] = { class = 'Druid', color = 'FF7D0A' },
    ['feral swiftness'] = { class = 'Druid', color = 'FF7D0A' },
    ['thick hide'] = { class = 'Druid', color = 'FF7D0A' },
    ['feral charge'] = { class = 'Druid', color = 'FF7D0A' },
    ['brutal impact'] = { class = 'Druid', color = 'FF7D0A' },
    ['sharpened claws'] = { class = 'Druid', color = 'FF7D0A' },
    ['shredding attacks'] = { class = 'Druid', color = 'FF7D0A' },
    ['predatory instincts'] = { class = 'Druid', color = 'FF7D0A' },
    ['primal fury'] = { class = 'Druid', color = 'FF7D0A' },
    ['primal precision'] = { class = 'Druid', color = 'FF7D0A' },
    ['improved shred'] = { class = 'Druid', color = 'FF7D0A' },
    ['survival of the fittest'] = { class = 'Druid', color = 'FF7D0A' },
    ['leader of the pack'] = { class = 'Druid', color = 'FF7D0A' },
    ['improved leader of the pack'] = { class = 'Druid', color = 'FF7D0A' },
    ['king of the jungle'] = { class = 'Druid', color = 'FF7D0A' },
    ['improved mark of the wild'] = { class = 'Druid', color = 'FF7D0A' },
    ['naturalist'] = { class = 'Druid', color = 'FF7D0A' },
    ['intensity'] = { class = 'Druid', color = 'FF7D0A' },
    ['subtlety'] = { class = 'Druid', color = 'FF7D0A' },
    ['natural shapeshifter'] = { class = 'Druid', color = 'FF7D0A' },
    ['omen of clarity'] = { class = 'Druid', color = 'FF7D0A' },
    ['master shapeshifter'] = { class = 'Druid', color = 'FF7D0A' },
    ['tranquil spirit'] = { class = 'Druid', color = 'FF7D0A' },
    ['improved rejuvenation'] = { class = 'Druid', color = 'FF7D0A' },
    ['natural perfection'] = { class = 'Druid', color = 'FF7D0A' },
    ['empowered touch'] = { class = 'Druid', color = 'FF7D0A' },
    ['nature\'s swiftness'] = { class = 'Druid', color = 'FF7D0A' },
    ['gift of nature'] = { class = 'Druid', color = 'FF7D0A' },
    ['improved tranquility'] = { class = 'Druid', color = 'FF7D0A' },
    ['improved tree of life'] = { class = 'Druid', color = 'FF7D0A' },
    ['living seed'] = { class = 'Druid', color = 'FF7D0A' },
    ['revitalize'] = { class = 'Druid', color = 'FF7D0A' },
    ['auto shot'] = { class = 'Hunter', color = 'ABD473' },
    ['arcane shot'] = { class = 'Hunter', color = 'ABD473' },
    ['serpent sting'] = { class = 'Hunter', color = 'ABD473' },
    ['steady shot'] = { class = 'Hunter', color = 'ABD473' },
    ['aimed shot'] = { class = 'Hunter', color = 'ABD473' },
    ['multi-shot'] = { class = 'Hunter', color = 'ABD473' },
    ['explosive shot'] = { class = 'Hunter', color = 'ABD473' },
    ['kill command'] = { class = 'Hunter', color = 'ABD473' },
    ['raptor strike'] = { class = 'Hunter', color = 'ABD473' },
    ['mongoose bite'] = { class = 'Hunter', color = 'ABD473' },
    ['carve'] = { class = 'Hunter', color = 'ABD473' },
    ['butchery'] = { class = 'Hunter', color = 'ABD473' },
    ['disengage'] = { class = 'Hunter', color = 'ABD473' },
    ['aspect of the cheetah'] = { class = 'Hunter', color = 'ABD473' },
    ['aspect of the turtle'] = { class = 'Hunter', color = 'ABD473' },
    ['aspect of the hawk'] = { class = 'Hunter', color = 'ABD473' },
    ['aspect of the wild'] = { class = 'Hunter', color = 'ABD473' },
    ['aspect of the viper'] = { class = 'Hunter', color = 'ABD473' },
    ['aspect of the dragonhawk'] = { class = 'Hunter', color = 'ABD473' },
    ['hunter\'s mark'] = { class = 'Hunter', color = 'ABD473' },
    ['concussive shot'] = { class = 'Hunter', color = 'ABD473' },
    ['wing clip'] = { class = 'Hunter', color = 'ABD473' },
    ['freezing trap'] = { class = 'Hunter', color = 'ABD473' },
    ['frost trap'] = { class = 'Hunter', color = 'ABD473' },
    ['explosive trap'] = { class = 'Hunter', color = 'ABD473' },
    ['tar trap'] = { class = 'Hunter', color = 'ABD473' },
    ['flare'] = { class = 'Hunter', color = 'ABD473' },
    ['track beasts'] = { class = 'Hunter', color = 'ABD473' },
    ['track humanoids'] = { class = 'Hunter', color = 'ABD473' },
    ['eagle eye'] = { class = 'Hunter', color = 'ABD473' },
    ['eyes of the beast'] = { class = 'Hunter', color = 'ABD473' },
    ['mend pet'] = { class = 'Hunter', color = 'ABD473' },
    ['revive pet'] = { class = 'Hunter', color = 'ABD473' },
    ['dismiss pet'] = { class = 'Hunter', color = 'ABD473' },
    ['call pet'] = { class = 'Hunter', color = 'ABD473' },
    ['beast lore'] = { class = 'Hunter', color = 'ABD473' },
    ['tame beast'] = { class = 'Hunter', color = 'ABD473' },
    ['exhilaration'] = { class = 'Hunter', color = 'ABD473' },
    ['counter shot'] = { class = 'Hunter', color = 'ABD473' },
    ['muzzle'] = { class = 'Hunter', color = 'ABD473' },
    ['intimidation'] = { class = 'Hunter', color = 'ABD473' },
    ['bestial wrath'] = { class = 'Hunter', color = 'ABD473' },
    ['stampede'] = { class = 'Hunter', color = 'ABD473' },
    ['trueshot'] = { class = 'Hunter', color = 'ABD473' },
    ['volley'] = { class = 'Hunter', color = 'ABD473' },
    ['rapid fire'] = { class = 'Hunter', color = 'ABD473' },
    ['readiness'] = { class = 'Hunter', color = 'ABD473' },
    ['chimera shot'] = { class = 'Hunter', color = 'ABD473' },
    ['kill shot'] = { class = 'Hunter', color = 'ABD473' },
    ['silencing shot'] = { class = 'Hunter', color = 'ABD473' },
    ['black arrow'] = { class = 'Hunter', color = 'ABD473' },
    ['immolation trap'] = { class = 'Hunter', color = 'ABD473' },
    ['scorpid sting'] = { class = 'Hunter', color = 'ABD473' },
    ['viper sting'] = { class = 'Hunter', color = 'ABD473' },
    ['wyvern sting'] = { class = 'Hunter', color = 'ABD473' },
    ['deterrence'] = { class = 'Hunter', color = 'ABD473' },
    ['master\'s call'] = { class = 'Hunter', color = 'ABD473' },
    ['beast within'] = { class = 'Hunter', color = 'ABD473' },
    ['animal handler'] = { class = 'Hunter', color = 'ABD473' },
    ['ferocious inspiration'] = { class = 'Hunter', color = 'ABD473' },
    ['bestial discipline'] = { class = 'Hunter', color = 'ABD473' },
    ['focused fire'] = { class = 'Hunter', color = 'ABD473' },
    ['improved kill command'] = { class = 'Hunter', color = 'ABD473' },
    ['cobra strikes'] = { class = 'Hunter', color = 'ABD473' },
    ['longevity'] = { class = 'Hunter', color = 'ABD473' },
    ['serpent\'s swiftness'] = { class = 'Hunter', color = 'ABD473' },
    ['the beast within'] = { class = 'Hunter', color = 'ABD473' },
    ['improved aspect of the hawk'] = { class = 'Hunter', color = 'ABD473' },
    ['focused aim'] = { class = 'Hunter', color = 'ABD473' },
    ['lethal shots'] = { class = 'Hunter', color = 'ABD473' },
    ['careful aim'] = { class = 'Hunter', color = 'ABD473' },
    ['mortal shots'] = { class = 'Hunter', color = 'ABD473' },
    ['efficiency'] = { class = 'Hunter', color = 'ABD473' },
    ['concussive barrage'] = { class = 'Hunter', color = 'ABD473' },
    ['improved arcane shot'] = { class = 'Hunter', color = 'ABD473' },
    ['improved stings'] = { class = 'Hunter', color = 'ABD473' },
    ['rapid killing'] = { class = 'Hunter', color = 'ABD473' },
    ['trueshot aura'] = { class = 'Hunter', color = 'ABD473' },
    ['improved tracking'] = { class = 'Hunter', color = 'ABD473' },
    ['survival instincts'] = { class = 'Hunter', color = 'ABD473' },
    ['survivalist'] = { class = 'Hunter', color = 'ABD473' },
    ['surefooted'] = { class = 'Hunter', color = 'ABD473' },
    ['entrapment'] = { class = 'Hunter', color = 'ABD473' },
    ['trap mastery'] = { class = 'Hunter', color = 'ABD473' },
    ['clever traps'] = { class = 'Hunter', color = 'ABD473' },
    ['survival tactics'] = { class = 'Hunter', color = 'ABD473' },
    ['lock and load'] = { class = 'Hunter', color = 'ABD473' },
    ['hunting party'] = { class = 'Hunter', color = 'ABD473' },
    ['noxious stings'] = { class = 'Hunter', color = 'ABD473' },
    ['point of no escape'] = { class = 'Hunter', color = 'ABD473' },
    ['thrill of the hunt'] = { class = 'Hunter', color = 'ABD473' },
    ['exposed weakness'] = { class = 'Hunter', color = 'ABD473' },
    ['master tactician'] = { class = 'Hunter', color = 'ABD473' },
    ['wild quiver'] = { class = 'Hunter', color = 'ABD473' },
    ['improved steady shot'] = { class = 'Hunter', color = 'ABD473' },
    ['sniper training'] = { class = 'Hunter', color = 'ABD473' },
    ['fireball'] = { class = 'Mage', color = '69CCF0' },
    ['frostbolt'] = { class = 'Mage', color = '69CCF0' },
    ['arcane blast'] = { class = 'Mage', color = '69CCF0' },
    ['arcane missiles'] = { class = 'Mage', color = '69CCF0' },
    ['fire blast'] = { class = 'Mage', color = '69CCF0' },
    ['ice lance'] = { class = 'Mage', color = '69CCF0' },
    ['flamestrike'] = { class = 'Mage', color = '69CCF0' },
    ['blizzard'] = { class = 'Mage', color = '69CCF0' },
    ['frost nova'] = { class = 'Mage', color = '69CCF0' },
    ['polymorph'] = { class = 'Mage', color = '69CCF0' },
    ['counterspell'] = { class = 'Mage', color = '69CCF0' },
    ['spellsteal'] = { class = 'Mage', color = '69CCF0' },
    ['blink'] = { class = 'Mage', color = '69CCF0' },
    ['ice block'] = { class = 'Mage', color = '69CCF0' },
    ['invisibility'] = { class = 'Mage', color = '69CCF0' },
    ['mirror image'] = { class = 'Mage', color = '69CCF0' },
    ['combustion'] = { class = 'Mage', color = '69CCF0' },
    ['icy veins'] = { class = 'Mage', color = '69CCF0' },
    ['arcane power'] = { class = 'Mage', color = '69CCF0' },
    ['pyroblast'] = { class = 'Mage', color = '69CCF0' },
    ['dragon\'s breath'] = { class = 'Mage', color = '69CCF0' },
    ['cone of cold'] = { class = 'Mage', color = '69CCF0' },
    ['arcane orb'] = { class = 'Mage', color = '69CCF0' },
    ['supernova'] = { class = 'Mage', color = '69CCF0' },
    ['meteor'] = { class = 'Mage', color = '69CCF0' },
    ['ray of frost'] = { class = 'Mage', color = '69CCF0' },
    ['glacial spike'] = { class = 'Mage', color = '69CCF0' },
    ['flurry'] = { class = 'Mage', color = '69CCF0' },
    ['blazing barrier'] = { class = 'Mage', color = '69CCF0' },
    ['ice barrier'] = { class = 'Mage', color = '69CCF0' },
    ['prismatic barrier'] = { class = 'Mage', color = '69CCF0' },
    ['alter time'] = { class = 'Mage', color = '69CCF0' },
    ['displacement'] = { class = 'Mage', color = '69CCF0' },
    ['greater invisibility'] = { class = 'Mage', color = '69CCF0' },
    ['time warp'] = { class = 'Mage', color = '69CCF0' },
    ['arcane explosion'] = { class = 'Mage', color = '69CCF0' },
    ['arcane barrage'] = { class = 'Mage', color = '69CCF0' },
    ['slow'] = { class = 'Mage', color = '69CCF0' },
    ['arcane intellect'] = { class = 'Mage', color = '69CCF0' },
    ['arcane brilliance'] = { class = 'Mage', color = '69CCF0' },
    ['dampen magic'] = { class = 'Mage', color = '69CCF0' },
    ['amplify magic'] = { class = 'Mage', color = '69CCF0' },
    ['remove curse'] = { class = 'Mage', color = '69CCF0' },
    ['teleport'] = { class = 'Mage', color = '69CCF0' },
    ['portal'] = { class = 'Mage', color = '69CCF0' },
    ['conjure water'] = { class = 'Mage', color = '69CCF0' },
    ['conjure food'] = { class = 'Mage', color = '69CCF0' },
    ['conjure mana gem'] = { class = 'Mage', color = '69CCF0' },
    ['arcane subtlety'] = { class = 'Mage', color = '69CCF0' },
    ['arcane focus'] = { class = 'Mage', color = '69CCF0' },
    ['spell impact'] = { class = 'Mage', color = '69CCF0' },
    ['arcane fortitude'] = { class = 'Mage', color = '69CCF0' },
    ['magic absorption'] = { class = 'Mage', color = '69CCF0' },
    ['arcane concentration'] = { class = 'Mage', color = '69CCF0' },
    ['arcane potency'] = { class = 'Mage', color = '69CCF0' },
    ['prismatic cloak'] = { class = 'Mage', color = '69CCF0' },
    ['arcane empowerment'] = { class = 'Mage', color = '69CCF0' },
    ['arcane mind'] = { class = 'Mage', color = '69CCF0' },
    ['arcane instability'] = { class = 'Mage', color = '69CCF0' },
    ['student of the mind'] = { class = 'Mage', color = '69CCF0' },
    ['netherwind presence'] = { class = 'Mage', color = '69CCF0' },
    ['missile barrage'] = { class = 'Mage', color = '69CCF0' },
    ['improved fireball'] = { class = 'Mage', color = '69CCF0' },
    ['ignite'] = { class = 'Mage', color = '69CCF0' },
    ['improved fire blast'] = { class = 'Mage', color = '69CCF0' },
    ['incineration'] = { class = 'Mage', color = '69CCF0' },
    ['improved scorch'] = { class = 'Mage', color = '69CCF0' },
    ['master of elements'] = { class = 'Mage', color = '69CCF0' },
    ['playing with fire'] = { class = 'Mage', color = '69CCF0' },
    ['critical mass'] = { class = 'Mage', color = '69CCF0' },
    ['blast wave'] = { class = 'Mage', color = '69CCF0' },
    ['blazing speed'] = { class = 'Mage', color = '69CCF0' },
    ['fire power'] = { class = 'Mage', color = '69CCF0' },
    ['pyromaniac'] = { class = 'Mage', color = '69CCF0' },
    ['molten fury'] = { class = 'Mage', color = '69CCF0' },
    ['hot streak'] = { class = 'Mage', color = '69CCF0' },
    ['burnout'] = { class = 'Mage', color = '69CCF0' },
    ['living bomb'] = { class = 'Mage', color = '69CCF0' },
    ['improved frostbolt'] = { class = 'Mage', color = '69CCF0' },
    ['ice floes'] = { class = 'Mage', color = '69CCF0' },
    ['ice shards'] = { class = 'Mage', color = '69CCF0' },
    ['frostbite'] = { class = 'Mage', color = '69CCF0' },
    ['improved frost nova'] = { class = 'Mage', color = '69CCF0' },
    ['permafrost'] = { class = 'Mage', color = '69CCF0' },
    ['piercing ice'] = { class = 'Mage', color = '69CCF0' },
    ['improved blizzard'] = { class = 'Mage', color = '69CCF0' },
    ['arctic reach'] = { class = 'Mage', color = '69CCF0' },
    ['frost channeling'] = { class = 'Mage', color = '69CCF0' },
    ['shatter'] = { class = 'Mage', color = '69CCF0' },
    ['cold snap'] = { class = 'Mage', color = '69CCF0' },
    ['improved cone of cold'] = { class = 'Mage', color = '69CCF0' },
    ['arctic winds'] = { class = 'Mage', color = '69CCF0' },
    ['empowered frostbolt'] = { class = 'Mage', color = '69CCF0' },
    ['fingers of frost'] = { class = 'Mage', color = '69CCF0' },
    ['brain freeze'] = { class = 'Mage', color = '69CCF0' },
    ['summon water elemental'] = { class = 'Mage', color = '69CCF0' },
    ['deep freeze'] = { class = 'Mage', color = '69CCF0' },
    ['holy light'] = { class = 'Paladin', color = 'F58CBA' },
    ['flash of light'] = { class = 'Paladin', color = 'F58CBA' },
    ['holy shock'] = { class = 'Paladin', color = 'F58CBA' },
    ['word of glory'] = { class = 'Paladin', color = 'F58CBA' },
    ['light of dawn'] = { class = 'Paladin', color = 'F58CBA' },
    ['lay on hands'] = { class = 'Paladin', color = 'F58CBA' },
    ['blessing of protection'] = { class = 'Paladin', color = 'F58CBA' },
    ['blessing of freedom'] = { class = 'Paladin', color = 'F58CBA' },
    ['blessing of sacrifice'] = { class = 'Paladin', color = 'F58CBA' },
    ['divine shield'] = { class = 'Paladin', color = 'F58CBA' },
    ['divine protection'] = { class = 'Paladin', color = 'F58CBA' },
    ['guardian of ancient kings'] = { class = 'Paladin', color = 'F58CBA' },
    ['ardent defender'] = { class = 'Paladin', color = 'F58CBA' },
    ['avenging wrath'] = { class = 'Paladin', color = 'F58CBA' },
    ['crusader strike'] = { class = 'Paladin', color = 'F58CBA' },
    ['judgment'] = { class = 'Paladin', color = 'F58CBA' },
    ['templar\'s verdict'] = { class = 'Paladin', color = 'F58CBA' },
    ['divine storm'] = { class = 'Paladin', color = 'F58CBA' },
    ['hammer of wrath'] = { class = 'Paladin', color = 'F58CBA' },
    ['consecration'] = { class = 'Paladin', color = 'F58CBA' },
    ['hammer of the righteous'] = { class = 'Paladin', color = 'F58CBA' },
    ['shield of the righteous'] = { class = 'Paladin', color = 'F58CBA' },
    ['avenger\'s shield'] = { class = 'Paladin', color = 'F58CBA' },
    ['hand of reckoning'] = { class = 'Paladin', color = 'F58CBA' },
    ['rebuke'] = { class = 'Paladin', color = 'F58CBA' },
    ['cleanse'] = { class = 'Paladin', color = 'F58CBA' },
    ['blinding light'] = { class = 'Paladin', color = 'F58CBA' },
    ['repentance'] = { class = 'Paladin', color = 'F58CBA' },
    ['hammer of justice'] = { class = 'Paladin', color = 'F58CBA' },
    ['aura mastery'] = { class = 'Paladin', color = 'F58CBA' },
    ['devotion aura'] = { class = 'Paladin', color = 'F58CBA' },
    ['retribution aura'] = { class = 'Paladin', color = 'F58CBA' },
    ['crusader aura'] = { class = 'Paladin', color = 'F58CBA' },
    ['concentration aura'] = { class = 'Paladin', color = 'F58CBA' },
    ['beacon of light'] = { class = 'Paladin', color = 'F58CBA' },
    ['bestow faith'] = { class = 'Paladin', color = 'F58CBA' },
    ['light\'s hammer'] = { class = 'Paladin', color = 'F58CBA' },
    ['blessing of the seasons'] = { class = 'Paladin', color = 'F58CBA' },
    ['divine toll'] = { class = 'Paladin', color = 'F58CBA' },
    ['ashen hollow'] = { class = 'Paladin', color = 'F58CBA' },
    ['blessing of summer'] = { class = 'Paladin', color = 'F58CBA' },
    ['blessing of autumn'] = { class = 'Paladin', color = 'F58CBA' },
    ['blessing of winter'] = { class = 'Paladin', color = 'F58CBA' },
    ['blessing of spring'] = { class = 'Paladin', color = 'F58CBA' },
    ['divine favor'] = { class = 'Paladin', color = 'F58CBA' },
    ['divine illumination'] = { class = 'Paladin', color = 'F58CBA' },
    ['illumination'] = { class = 'Paladin', color = 'F58CBA' },
    ['improved lay on hands'] = { class = 'Paladin', color = 'F58CBA' },
    ['divine intellect'] = { class = 'Paladin', color = 'F58CBA' },
    ['spiritual focus'] = { class = 'Paladin', color = 'F58CBA' },
    ['seal of wisdom'] = { class = 'Paladin', color = 'F58CBA' },
    ['judgment of wisdom'] = { class = 'Paladin', color = 'F58CBA' },
    ['seal of light'] = { class = 'Paladin', color = 'F58CBA' },
    ['judgment of light'] = { class = 'Paladin', color = 'F58CBA' },
    ['seal of justice'] = { class = 'Paladin', color = 'F58CBA' },
    ['judgment of justice'] = { class = 'Paladin', color = 'F58CBA' },
    ['seal of righteousness'] = { class = 'Paladin', color = 'F58CBA' },
    ['seal of command'] = { class = 'Paladin', color = 'F58CBA' },
    ['seal of corruption'] = { class = 'Paladin', color = 'F58CBA' },
    ['seal of vengeance'] = { class = 'Paladin', color = 'F58CBA' },
    ['holy shield'] = { class = 'Paladin', color = 'F58CBA' },
    ['redoubt'] = { class = 'Paladin', color = 'F58CBA' },
    ['toughness'] = { class = 'Paladin', color = 'F58CBA' },
    ['improved righteous fury'] = { class = 'Paladin', color = 'F58CBA' },
    ['blessing of kings'] = { class = 'Paladin', color = 'F58CBA' },
    ['improved blessing of might'] = { class = 'Paladin', color = 'F58CBA' },
    ['improved blessing of wisdom'] = { class = 'Paladin', color = 'F58CBA' },
    ['divine strength'] = { class = 'Paladin', color = 'F58CBA' },
    ['divine guardian'] = { class = 'Paladin', color = 'F58CBA' },
    ['sacred shield'] = { class = 'Paladin', color = 'F58CBA' },
    ['improved devotion aura'] = { class = 'Paladin', color = 'F58CBA' },
    ['guardian\'s favor'] = { class = 'Paladin', color = 'F58CBA' },
    ['divinity'] = { class = 'Paladin', color = 'F58CBA' },
    ['stoicism'] = { class = 'Paladin', color = 'F58CBA' },
    ['improved hammer of justice'] = { class = 'Paladin', color = 'F58CBA' },
    ['reckoning'] = { class = 'Paladin', color = 'F58CBA' },
    ['one-handed weapon specialization'] = { class = 'Paladin', color = 'F58CBA' },
    ['benediction'] = { class = 'Paladin', color = 'F58CBA' },
    ['sanctity of battle'] = { class = 'Paladin', color = 'F58CBA' },
    ['conviction'] = { class = 'Paladin', color = 'F58CBA' },
    ['crusade'] = { class = 'Paladin', color = 'F58CBA' },
    ['two-handed weapon specialization'] = { class = 'Paladin', color = 'F58CBA' },
    ['sanctified wrath'] = { class = 'Paladin', color = 'F58CBA' },
    ['judgements of the wise'] = { class = 'Paladin', color = 'F58CBA' },
    ['sheath of light'] = { class = 'Paladin', color = 'F58CBA' },
    ['smite'] = { class = 'Priest', color = 'FFFFFF' },
    ['shadow word: pain'] = { class = 'Priest', color = 'FFFFFF' },
    ['shadow word: death'] = { class = 'Priest', color = 'FFFFFF' },
    ['mind blast'] = { class = 'Priest', color = 'FFFFFF' },
    ['mind flay'] = { class = 'Priest', color = 'FFFFFF' },
    ['holy fire'] = { class = 'Priest', color = 'FFFFFF' },
    ['power word: shield'] = { class = 'Priest', color = 'FFFFFF' },
    ['power word: fortitude'] = { class = 'Priest', color = 'FFFFFF' },
    ['renew'] = { class = 'Priest', color = 'FFFFFF' },
    ['flash heal'] = { class = 'Priest', color = 'FFFFFF' },
    ['heal'] = { class = 'Priest', color = 'FFFFFF' },
    ['prayer of healing'] = { class = 'Priest', color = 'FFFFFF' },
    ['holy nova'] = { class = 'Priest', color = 'FFFFFF' },
    ['dispel magic'] = { class = 'Priest', color = 'FFFFFF' },
    ['fade'] = { class = 'Priest', color = 'FFFFFF' },
    ['psychic scream'] = { class = 'Priest', color = 'FFFFFF' },
    ['mind control'] = { class = 'Priest', color = 'FFFFFF' },
    ['levitate'] = { class = 'Priest', color = 'FFFFFF' },
    ['shadowform'] = { class = 'Priest', color = 'FFFFFF' },
    ['vampiric touch'] = { class = 'Priest', color = 'FFFFFF' },
    ['devouring plague'] = { class = 'Priest', color = 'FFFFFF' },
    ['void eruption'] = { class = 'Priest', color = 'FFFFFF' },
    ['power infusion'] = { class = 'Priest', color = 'FFFFFF' },
    ['pain suppression'] = { class = 'Priest', color = 'FFFFFF' },
    ['guardian spirit'] = { class = 'Priest', color = 'FFFFFF' },
    ['hymn of hope'] = { class = 'Priest', color = 'FFFFFF' },
    ['divine hymn'] = { class = 'Priest', color = 'FFFFFF' },
    ['spirit of redemption'] = { class = 'Priest', color = 'FFFFFF' },
    ['apotheosis'] = { class = 'Priest', color = 'FFFFFF' },
    ['holy word: salvation'] = { class = 'Priest', color = 'FFFFFF' },
    ['shadow covenant'] = { class = 'Priest', color = 'FFFFFF' },
    ['mind games'] = { class = 'Priest', color = 'FFFFFF' },
    ['thoughtsteal'] = { class = 'Priest', color = 'FFFFFF' },
    ['dominate mind'] = { class = 'Priest', color = 'FFFFFF' },
    ['psychic horror'] = { class = 'Priest', color = 'FFFFFF' },
    ['silence'] = { class = 'Priest', color = 'FFFFFF' },
    ['shadow word: void'] = { class = 'Priest', color = 'FFFFFF' },
    ['void bolt'] = { class = 'Priest', color = 'FFFFFF' },
    ['shadowfiend'] = { class = 'Priest', color = 'FFFFFF' },
    ['mindbender'] = { class = 'Priest', color = 'FFFFFF' },
    ['greater heal'] = { class = 'Priest', color = 'FFFFFF' },
    ['lesser heal'] = { class = 'Priest', color = 'FFFFFF' },
    ['circle of healing'] = { class = 'Priest', color = 'FFFFFF' },
    ['binding heal'] = { class = 'Priest', color = 'FFFFFF' },
    ['prayer of mending'] = { class = 'Priest', color = 'FFFFFF' },
    ['lightwell'] = { class = 'Priest', color = 'FFFFFF' },
    ['dispersion'] = { class = 'Priest', color = 'FFFFFF' },
    ['vampiric embrace'] = { class = 'Priest', color = 'FFFFFF' },
    ['improved shadow word: pain'] = { class = 'Priest', color = 'FFFFFF' },
    ['spirit tap'] = { class = 'Priest', color = 'FFFFFF' },
    ['improved spirit tap'] = { class = 'Priest', color = 'FFFFFF' },
    ['shadow focus'] = { class = 'Priest', color = 'FFFFFF' },
    ['improved mind blast'] = { class = 'Priest', color = 'FFFFFF' },
    ['mind melt'] = { class = 'Priest', color = 'FFFFFF' },
    ['veiled shadows'] = { class = 'Priest', color = 'FFFFFF' },
    ['darkness'] = { class = 'Priest', color = 'FFFFFF' },
    ['shadow weaving'] = { class = 'Priest', color = 'FFFFFF' },
    ['misery'] = { class = 'Priest', color = 'FFFFFF' },
    ['focused mind'] = { class = 'Priest', color = 'FFFFFF' },
    ['improved vampiric touch'] = { class = 'Priest', color = 'FFFFFF' },
    ['pain and suffering'] = { class = 'Priest', color = 'FFFFFF' },
    ['twisted faith'] = { class = 'Priest', color = 'FFFFFF' },
    ['improved power word: shield'] = { class = 'Priest', color = 'FFFFFF' },
    ['twin disciplines'] = { class = 'Priest', color = 'FFFFFF' },
    ['focused power'] = { class = 'Priest', color = 'FFFFFF' },
    ['enlightenment'] = { class = 'Priest', color = 'FFFFFF' },
    ['renewed hope'] = { class = 'Priest', color = 'FFFFFF' },
    ['rapture'] = { class = 'Priest', color = 'FFFFFF' },
    ['aspiration'] = { class = 'Priest', color = 'FFFFFF' },
    ['divine aegis'] = { class = 'Priest', color = 'FFFFFF' },
    ['grace'] = { class = 'Priest', color = 'FFFFFF' },
    ['penance'] = { class = 'Priest', color = 'FFFFFF' },
    ['improved renew'] = { class = 'Priest', color = 'FFFFFF' },
    ['divine fury'] = { class = 'Priest', color = 'FFFFFF' },
    ['improved healing'] = { class = 'Priest', color = 'FFFFFF' },
    ['holy specialization'] = { class = 'Priest', color = 'FFFFFF' },
    ['spell warding'] = { class = 'Priest', color = 'FFFFFF' },
    ['blessed recovery'] = { class = 'Priest', color = 'FFFFFF' },
    ['inspiration'] = { class = 'Priest', color = 'FFFFFF' },
    ['holy reach'] = { class = 'Priest', color = 'FFFFFF' },
    ['improved holy nova'] = { class = 'Priest', color = 'FFFFFF' },
    ['spiritual guidance'] = { class = 'Priest', color = 'FFFFFF' },
    ['surge of light'] = { class = 'Priest', color = 'FFFFFF' },
    ['spiritual healing'] = { class = 'Priest', color = 'FFFFFF' },
    ['holy concentration'] = { class = 'Priest', color = 'FFFFFF' },
    ['serendipity'] = { class = 'Priest', color = 'FFFFFF' },
    ['empowered healing'] = { class = 'Priest', color = 'FFFFFF' },
    ['sinister strike'] = { class = 'Rogue', color = 'FFF569' },
    ['eviscerate'] = { class = 'Rogue', color = 'FFF569' },
    ['backstab'] = { class = 'Rogue', color = 'FFF569' },
    ['ambush'] = { class = 'Rogue', color = 'FFF569' },
    ['cheap shot'] = { class = 'Rogue', color = 'FFF569' },
    ['kidney shot'] = { class = 'Rogue', color = 'FFF569' },
    ['garrote'] = { class = 'Rogue', color = 'FFF569' },
    ['rupture'] = { class = 'Rogue', color = 'FFF569' },
    ['slice and dice'] = { class = 'Rogue', color = 'FFF569' },
    ['stealth'] = { class = 'Rogue', color = 'FFF569' },
    ['vanish'] = { class = 'Rogue', color = 'FFF569' },
    ['sap'] = { class = 'Rogue', color = 'FFF569' },
    ['blind'] = { class = 'Rogue', color = 'FFF569' },
    ['evasion'] = { class = 'Rogue', color = 'FFF569' },
    ['cloak of shadows'] = { class = 'Rogue', color = 'FFF569' },
    ['sprint'] = { class = 'Rogue', color = 'FFF569' },
    ['kick'] = { class = 'Rogue', color = 'FFF569' },
    ['gouge'] = { class = 'Rogue', color = 'FFF569' },
    ['distract'] = { class = 'Rogue', color = 'FFF569' },
    ['pick pocket'] = { class = 'Rogue', color = 'FFF569' },
    ['poisoned blade'] = { class = 'Rogue', color = 'FFF569' },
    ['deadly poison'] = { class = 'Rogue', color = 'FFF569' },
    ['wound poison'] = { class = 'Rogue', color = 'FFF569' },
    ['crippling poison'] = { class = 'Rogue', color = 'FFF569' },
    ['blade flurry'] = { class = 'Rogue', color = 'FFF569' },
    ['adrenaline rush'] = { class = 'Rogue', color = 'FFF569' },
    ['killing spree'] = { class = 'Rogue', color = 'FFF569' },
    ['shadow dance'] = { class = 'Rogue', color = 'FFF569' },
    ['shadowstep'] = { class = 'Rogue', color = 'FFF569' },
    ['preparation'] = { class = 'Rogue', color = 'FFF569' },
    ['vendetta'] = { class = 'Rogue', color = 'FFF569' },
    ['death from above'] = { class = 'Rogue', color = 'FFF569' },
    ['marked for death'] = { class = 'Rogue', color = 'FFF569' },
    ['symbols of death'] = { class = 'Rogue', color = 'FFF569' },
    ['roll the bones'] = { class = 'Rogue', color = 'FFF569' },
    ['between the eyes'] = { class = 'Rogue', color = 'FFF569' },
    ['dispatch'] = { class = 'Rogue', color = 'FFF569' },
    ['crimson tempest'] = { class = 'Rogue', color = 'FFF569' },
    ['toxic blade'] = { class = 'Rogue', color = 'FFF569' },
    ['shiv'] = { class = 'Rogue', color = 'FFF569' },
    ['mutilate'] = { class = 'Rogue', color = 'FFF569' },
    ['envenom'] = { class = 'Rogue', color = 'FFF569' },
    ['hemorrhage'] = { class = 'Rogue', color = 'FFF569' },
    ['ghostly strike'] = { class = 'Rogue', color = 'FFF569' },
    ['riposte'] = { class = 'Rogue', color = 'FFF569' },
    ['premeditation'] = { class = 'Rogue', color = 'FFF569' },
    ['honor among thieves'] = { class = 'Rogue', color = 'FFF569' },
    ['sleight of hand'] = { class = 'Rogue', color = 'FFF569' },
    ['master poisoner'] = { class = 'Rogue', color = 'FFF569' },
    ['deadly brew'] = { class = 'Rogue', color = 'FFF569' },
    ['vile poisons'] = { class = 'Rogue', color = 'FFF569' },
    ['improved poisons'] = { class = 'Rogue', color = 'FFF569' },
    ['fleet footed'] = { class = 'Rogue', color = 'FFF569' },
    ['quick recovery'] = { class = 'Rogue', color = 'FFF569' },
    ['seal fate'] = { class = 'Rogue', color = 'FFF569' },
    ['murderous intent'] = { class = 'Rogue', color = 'FFF569' },
    ['focused attacks'] = { class = 'Rogue', color = 'FFF569' },
    ['find weakness'] = { class = 'Rogue', color = 'FFF569' },
    ['vigor'] = { class = 'Rogue', color = 'FFF569' },
    ['cut to the chase'] = { class = 'Rogue', color = 'FFF569' },
    ['hunger for blood'] = { class = 'Rogue', color = 'FFF569' },
    ['improved sinister strike'] = { class = 'Rogue', color = 'FFF569' },
    ['dual wield specialization'] = { class = 'Rogue', color = 'FFF569' },
    ['improved slice and dice'] = { class = 'Rogue', color = 'FFF569' },
    ['precision'] = { class = 'Rogue', color = 'FFF569' },
    ['endurance'] = { class = 'Rogue', color = 'FFF569' },
    ['lightning reflexes'] = { class = 'Rogue', color = 'FFF569' },
    ['improved gouge'] = { class = 'Rogue', color = 'FFF569' },
    ['deflection'] = { class = 'Rogue', color = 'FFF569' },
    ['combat potency'] = { class = 'Rogue', color = 'FFF569' },
    ['weapon expertise'] = { class = 'Rogue', color = 'FFF569' },
    ['blade twisting'] = { class = 'Rogue', color = 'FFF569' },
    ['vitality'] = { class = 'Rogue', color = 'FFF569' },
    ['surprise attacks'] = { class = 'Rogue', color = 'FFF569' },
    ['savage combat'] = { class = 'Rogue', color = 'FFF569' },
    ['prey on the weak'] = { class = 'Rogue', color = 'FFF569' },
    ['opportunity'] = { class = 'Rogue', color = 'FFF569' },
    ['camouflage'] = { class = 'Rogue', color = 'FFF569' },
    ['elusiveness'] = { class = 'Rogue', color = 'FFF569' },
    ['serrated blades'] = { class = 'Rogue', color = 'FFF569' },
    ['setup'] = { class = 'Rogue', color = 'FFF569' },
    ['initiative'] = { class = 'Rogue', color = 'FFF569' },
    ['improved ambush'] = { class = 'Rogue', color = 'FFF569' },
    ['dirty deeds'] = { class = 'Rogue', color = 'FFF569' },
    ['master of subtlety'] = { class = 'Rogue', color = 'FFF569' },
    ['deadliness'] = { class = 'Rogue', color = 'FFF569' },
    ['enveloping shadows'] = { class = 'Rogue', color = 'FFF569' },
    ['cheat death'] = { class = 'Rogue', color = 'FFF569' },
    ['sinister calling'] = { class = 'Rogue', color = 'FFF569' },
    ['filthy tricks'] = { class = 'Rogue', color = 'FFF569' },
    ['slaughter from the shadows'] = { class = 'Rogue', color = 'FFF569' },
    ['earth shock'] = { class = 'Shaman', color = '0070DE' },
    ['flame shock'] = { class = 'Shaman', color = '0070DE' },
    ['frost shock'] = { class = 'Shaman', color = '0070DE' },
    ['lightning bolt'] = { class = 'Shaman', color = '0070DE' },
    ['chain lightning'] = { class = 'Shaman', color = '0070DE' },
    ['lava burst'] = { class = 'Shaman', color = '0070DE' },
    ['healing wave'] = { class = 'Shaman', color = '0070DE' },
    ['chain heal'] = { class = 'Shaman', color = '0070DE' },
    ['riptide'] = { class = 'Shaman', color = '0070DE' },
    ['healing rain'] = { class = 'Shaman', color = '0070DE' },
    ['wind shear'] = { class = 'Shaman', color = '0070DE' },
    ['purge'] = { class = 'Shaman', color = '0070DE' },
    ['ghost wolf'] = { class = 'Shaman', color = '0070DE' },
    ['bloodlust'] = { class = 'Shaman', color = '0070DE' },
    ['heroism'] = { class = 'Shaman', color = '0070DE' },
    ['earth elemental'] = { class = 'Shaman', color = '0070DE' },
    ['fire elemental'] = { class = 'Shaman', color = '0070DE' },
    ['earth shield'] = { class = 'Shaman', color = '0070DE' },
    ['water shield'] = { class = 'Shaman', color = '0070DE' },
    ['lightning shield'] = { class = 'Shaman', color = '0070DE' },
    ['capacitor totem'] = { class = 'Shaman', color = '0070DE' },
    ['tremor totem'] = { class = 'Shaman', color = '0070DE' },
    ['healing stream totem'] = { class = 'Shaman', color = '0070DE' },
    ['windfury totem'] = { class = 'Shaman', color = '0070DE' },
    ['stormstrike'] = { class = 'Shaman', color = '0070DE' },
    ['lava lash'] = { class = 'Shaman', color = '0070DE' },
    ['crash lightning'] = { class = 'Shaman', color = '0070DE' },
    ['feral spirit'] = { class = 'Shaman', color = '0070DE' },
    ['maelstrom weapon'] = { class = 'Shaman', color = '0070DE' },
    ['spirit wolf'] = { class = 'Shaman', color = '0070DE' },
    ['astral shift'] = { class = 'Shaman', color = '0070DE' },
    ['earthquake'] = { class = 'Shaman', color = '0070DE' },
    ['elemental overload'] = { class = 'Shaman', color = '0070DE' },
    ['enhanced elements'] = { class = 'Shaman', color = '0070DE' },
    ['totem of wrath'] = { class = 'Shaman', color = '0070DE' },
    ['elemental mastery'] = { class = 'Shaman', color = '0070DE' },
    ['thunderstorm'] = { class = 'Shaman', color = '0070DE' },
    ['shamanistic rage'] = { class = 'Shaman', color = '0070DE' },
    ['tidal force'] = { class = 'Shaman', color = '0070DE' },
    ['earthliving weapon'] = { class = 'Shaman', color = '0070DE' },
    ['tidal waves'] = { class = 'Shaman', color = '0070DE' },
    ['healing way'] = { class = 'Shaman', color = '0070DE' },
    ['nature\'s swiftness'] = { class = 'Shaman', color = '0070DE' },
    ['improved chain heal'] = { class = 'Shaman', color = '0070DE' },
    ['tidal mastery'] = { class = 'Shaman', color = '0070DE' },
    ['ancestral healing'] = { class = 'Shaman', color = '0070DE' },
    ['restorative totems'] = { class = 'Shaman', color = '0070DE' },
    ['tidal focus'] = { class = 'Shaman', color = '0070DE' },
    ['healing grace'] = { class = 'Shaman', color = '0070DE' },
    ['totemic focus'] = { class = 'Shaman', color = '0070DE' },
    ['improved water shield'] = { class = 'Shaman', color = '0070DE' },
    ['improved healing wave'] = { class = 'Shaman', color = '0070DE' },
    ['nature\'s guidance'] = { class = 'Shaman', color = '0070DE' },
    ['mana tide totem'] = { class = 'Shaman', color = '0070DE' },
    ['cleansing waters'] = { class = 'Shaman', color = '0070DE' },
    ['blessing of the eternals'] = { class = 'Shaman', color = '0070DE' },
    ['improved earth shield'] = { class = 'Shaman', color = '0070DE' },
    ['enhanced weapon'] = { class = 'Shaman', color = '0070DE' },
    ['flurry'] = { class = 'Shaman', color = '0070DE' },
    ['elemental devastation'] = { class = 'Shaman', color = '0070DE' },
    ['elemental fury'] = { class = 'Shaman', color = '0070DE' },
    ['call of thunder'] = { class = 'Shaman', color = '0070DE' },
    ['concussion'] = { class = 'Shaman', color = '0070DE' },
    ['convection'] = { class = 'Shaman', color = '0070DE' },
    ['elemental focus'] = { class = 'Shaman', color = '0070DE' },
    ['elemental precision'] = { class = 'Shaman', color = '0070DE' },
    ['lightning mastery'] = { class = 'Shaman', color = '0070DE' },
    ['lightning overload'] = { class = 'Shaman', color = '0070DE' },
    ['elemental oath'] = { class = 'Shaman', color = '0070DE' },
    ['lava flows'] = { class = 'Shaman', color = '0070DE' },
    ['storm, earth and fire'] = { class = 'Shaman', color = '0070DE' },
    ['shamanism'] = { class = 'Shaman', color = '0070DE' },
    ['improved stormstrike'] = { class = 'Shaman', color = '0070DE' },
    ['dual wield'] = { class = 'Shaman', color = '0070DE' },
    ['unleashed rage'] = { class = 'Shaman', color = '0070DE' },
    ['improved windfury weapon'] = { class = 'Shaman', color = '0070DE' },
    ['elemental weapons'] = { class = 'Shaman', color = '0070DE' },
    ['spirit weapons'] = { class = 'Shaman', color = '0070DE' },
    ['mental dexterity'] = { class = 'Shaman', color = '0070DE' },
    ['improved lightning shield'] = { class = 'Shaman', color = '0070DE' },
    ['static shock'] = { class = 'Shaman', color = '0070DE' },
    ['shadow bolt'] = { class = 'Warlock', color = '9482C9' },
    ['incinerate'] = { class = 'Warlock', color = '9482C9' },
    ['chaos bolt'] = { class = 'Warlock', color = '9482C9' },
    ['conflagrate'] = { class = 'Warlock', color = '9482C9' },
    ['immolate'] = { class = 'Warlock', color = '9482C9' },
    ['corruption'] = { class = 'Warlock', color = '9482C9' },
    ['unstable affliction'] = { class = 'Warlock', color = '9482C9' },
    ['agony'] = { class = 'Warlock', color = '9482C9' },
    ['drain soul'] = { class = 'Warlock', color = '9482C9' },
    ['fear'] = { class = 'Warlock', color = '9482C9' },
    ['howl of terror'] = { class = 'Warlock', color = '9482C9' },
    ['death coil'] = { class = 'Warlock', color = '9482C9' },
    ['banish'] = { class = 'Warlock', color = '9482C9' },
    ['summon imp'] = { class = 'Warlock', color = '9482C9' },
    ['summon voidwalker'] = { class = 'Warlock', color = '9482C9' },
    ['summon succubus'] = { class = 'Warlock', color = '9482C9' },
    ['summon felhunter'] = { class = 'Warlock', color = '9482C9' },
    ['summon felguard'] = { class = 'Warlock', color = '9482C9' },
    ['summon doomguard'] = { class = 'Warlock', color = '9482C9' },
    ['summon infernal'] = { class = 'Warlock', color = '9482C9' },
    ['soul fire'] = { class = 'Warlock', color = '9482C9' },
    ['rain of fire'] = { class = 'Warlock', color = '9482C9' },
    ['hellfire'] = { class = 'Warlock', color = '9482C9' },
    ['seed of corruption'] = { class = 'Warlock', color = '9482C9' },
    ['soulburn'] = { class = 'Warlock', color = '9482C9' },
    ['dark soul: misery'] = { class = 'Warlock', color = '9482C9' },
    ['dark soul: instability'] = { class = 'Warlock', color = '9482C9' },
    ['dark soul: knowledge'] = { class = 'Warlock', color = '9482C9' },
    ['demon soul'] = { class = 'Warlock', color = '9482C9' },
    ['metamorphosis'] = { class = 'Warlock', color = '9482C9' },
    ['demonic empowerment'] = { class = 'Warlock', color = '9482C9' },
    ['summon demonic tyrant'] = { class = 'Warlock', color = '9482C9' },
    ['grimoire of sacrifice'] = { class = 'Warlock', color = '9482C9' },
    ['grimoire of service'] = { class = 'Warlock', color = '9482C9' },
    ['grimoire of supremacy'] = { class = 'Warlock', color = '9482C9' },
    ['phantom singularity'] = { class = 'Warlock', color = '9482C9' },
    ['nether portal'] = { class = 'Warlock', color = '9482C9' },
    ['soul rot'] = { class = 'Warlock', color = '9482C9' },
    ['impending catastrophe'] = { class = 'Warlock', color = '9482C9' },
    ['decimating bolt'] = { class = 'Warlock', color = '9482C9' },
    ['scouring tithe'] = { class = 'Warlock', color = '9482C9' },
    ['curse of agony'] = { class = 'Warlock', color = '9482C9' },
    ['curse of elements'] = { class = 'Warlock', color = '9482C9' },
    ['curse of shadow'] = { class = 'Warlock', color = '9482C9' },
    ['curse of tongues'] = { class = 'Warlock', color = '9482C9' },
    ['curse of weakness'] = { class = 'Warlock', color = '9482C9' },
    ['curse of recklessness'] = { class = 'Warlock', color = '9482C9' },
    ['curse of doom'] = { class = 'Warlock', color = '9482C9' },
    ['drain life'] = { class = 'Warlock', color = '9482C9' },
    ['drain mana'] = { class = 'Warlock', color = '9482C9' },
    ['health funnel'] = { class = 'Warlock', color = '9482C9' },
    ['life tap'] = { class = 'Warlock', color = '9482C9' },
    ['soul link'] = { class = 'Warlock', color = '9482C9' },
    ['soulshatter'] = { class = 'Warlock', color = '9482C9' },
    ['ritual of summoning'] = { class = 'Warlock', color = '9482C9' },
    ['ritual of souls'] = { class = 'Warlock', color = '9482C9' },
    ['create healthstone'] = { class = 'Warlock', color = '9482C9' },
    ['create soulstone'] = { class = 'Warlock', color = '9482C9' },
    ['create spellstone'] = { class = 'Warlock', color = '9482C9' },
    ['create firestone'] = { class = 'Warlock', color = '9482C9' },
    ['fel domination'] = { class = 'Warlock', color = '9482C9' },
    ['shadowfury'] = { class = 'Warlock', color = '9482C9' },
    ['shadowflame'] = { class = 'Warlock', color = '9482C9' },
    ['haunt'] = { class = 'Warlock', color = '9482C9' },
    ['soul siphon'] = { class = 'Warlock', color = '9482C9' },
    ['death\'s embrace'] = { class = 'Warlock', color = '9482C9' },
    ['improved curse of agony'] = { class = 'Warlock', color = '9482C9' },
    ['suppression'] = { class = 'Warlock', color = '9482C9' },
    ['improved corruption'] = { class = 'Warlock', color = '9482C9' },
    ['improved drain soul'] = { class = 'Warlock', color = '9482C9' },
    ['improved life tap'] = { class = 'Warlock', color = '9482C9' },
    ['fel concentration'] = { class = 'Warlock', color = '9482C9' },
    ['amplify curse'] = { class = 'Warlock', color = '9482C9' },
    ['grim reach'] = { class = 'Warlock', color = '9482C9' },
    ['nightfall'] = { class = 'Warlock', color = '9482C9' },
    ['empowered corruption'] = { class = 'Warlock', color = '9482C9' },
    ['shadow embrace'] = { class = 'Warlock', color = '9482C9' },
    ['siphon life'] = { class = 'Warlock', color = '9482C9' },
    ['curse of exhaustion'] = { class = 'Warlock', color = '9482C9' },
    ['shadow mastery'] = { class = 'Warlock', color = '9482C9' },
    ['contagion'] = { class = 'Warlock', color = '9482C9' },
    ['dark pact'] = { class = 'Warlock', color = '9482C9' },
    ['improved howl of terror'] = { class = 'Warlock', color = '9482C9' },
    ['everlasting affliction'] = { class = 'Warlock', color = '9482C9' },
    ['demonic embrace'] = { class = 'Warlock', color = '9482C9' },
    ['fel synergy'] = { class = 'Warlock', color = '9482C9' },
    ['improved healthstone'] = { class = 'Warlock', color = '9482C9' },
    ['demonic brutality'] = { class = 'Warlock', color = '9482C9' },
    ['fel vitality'] = { class = 'Warlock', color = '9482C9' },
    ['demonic aegis'] = { class = 'Warlock', color = '9482C9' },
    ['unholy power'] = { class = 'Warlock', color = '9482C9' },
    ['master summoner'] = { class = 'Warlock', color = '9482C9' },
    ['master demonologist'] = { class = 'Warlock', color = '9482C9' },
    ['molten core'] = { class = 'Warlock', color = '9482C9' },
    ['demonic resilience'] = { class = 'Warlock', color = '9482C9' },
    ['demonic sacrifice'] = { class = 'Warlock', color = '9482C9' },
    ['improved shadow bolt'] = { class = 'Warlock', color = '9482C9' },
    ['bane'] = { class = 'Warlock', color = '9482C9' },
    ['cataclysm'] = { class = 'Warlock', color = '9482C9' },
    ['aftermath'] = { class = 'Warlock', color = '9482C9' },
    ['demonic power'] = { class = 'Warlock', color = '9482C9' },
    ['ruin'] = { class = 'Warlock', color = '9482C9' },
    ['intensity'] = { class = 'Warlock', color = '9482C9' },
    ['destructive reach'] = { class = 'Warlock', color = '9482C9' },
    ['improved immolate'] = { class = 'Warlock', color = '9482C9' },
    ['devastation'] = { class = 'Warlock', color = '9482C9' },
    ['emberstorm'] = { class = 'Warlock', color = '9482C9' },
    ['backlash'] = { class = 'Warlock', color = '9482C9' },
    ['shadow and flame'] = { class = 'Warlock', color = '9482C9' },
    ['soul leech'] = { class = 'Warlock', color = '9482C9' },
    ['pyroclasm'] = { class = 'Warlock', color = '9482C9' },
    ['fire and brimstone'] = { class = 'Warlock', color = '9482C9' },
    ['backdraft'] = { class = 'Warlock', color = '9482C9' },
    ['empowered imp'] = { class = 'Warlock', color = '9482C9' },
    ['charge'] = { class = 'Warrior', color = 'C79C6E' },
    ['heroic strike'] = { class = 'Warrior', color = 'C79C6E' },
    ['mortal strike'] = { class = 'Warrior', color = 'C79C6E' },
    ['overpower'] = { class = 'Warrior', color = 'C79C6E' },
    ['execute'] = { class = 'Warrior', color = 'C79C6E' },
    ['whirlwind'] = { class = 'Warrior', color = 'C79C6E' },
    ['bloodthirst'] = { class = 'Warrior', color = 'C79C6E' },
    ['rampage'] = { class = 'Warrior', color = 'C79C6E' },
    ['raging blow'] = { class = 'Warrior', color = 'C79C6E' },
    ['shield slam'] = { class = 'Warrior', color = 'C79C6E' },
    ['thunder clap'] = { class = 'Warrior', color = 'C79C6E' },
    ['demoralizing shout'] = { class = 'Warrior', color = 'C79C6E' },
    ['battle shout'] = { class = 'Warrior', color = 'C79C6E' },
    ['commanding shout'] = { class = 'Warrior', color = 'C79C6E' },
    ['berserker rage'] = { class = 'Warrior', color = 'C79C6E' },
    ['pummel'] = { class = 'Warrior', color = 'C79C6E' },
    ['shield block'] = { class = 'Warrior', color = 'C79C6E' },
    ['spell reflection'] = { class = 'Warrior', color = 'C79C6E' },
    ['taunt'] = { class = 'Warrior', color = 'C79C6E' },
    ['challenging shout'] = { class = 'Warrior', color = 'C79C6E' },
    ['intervene'] = { class = 'Warrior', color = 'C79C6E' },
    ['rallying cry'] = { class = 'Warrior', color = 'C79C6E' },
    ['die by the sword'] = { class = 'Warrior', color = 'C79C6E' },
    ['avatar'] = { class = 'Warrior', color = 'C79C6E' },
    ['bladestorm'] = { class = 'Warrior', color = 'C79C6E' },
    ['recklessness'] = { class = 'Warrior', color = 'C79C6E' },
    ['deadly calm'] = { class = 'Warrior', color = 'C79C6E' },
    ['colossus smash'] = { class = 'Warrior', color = 'C79C6E' },
    ['war breaker'] = { class = 'Warrior', color = 'C79C6E' },
    ['shield wall'] = { class = 'Warrior', color = 'C79C6E' },
    ['last stand'] = { class = 'Warrior', color = 'C79C6E' },
    ['ignore pain'] = { class = 'Warrior', color = 'C79C6E' },
    ['victory rush'] = { class = 'Warrior', color = 'C79C6E' },
    ['impending victory'] = { class = 'Warrior', color = 'C79C6E' },
    ['frothing berserker'] = { class = 'Warrior', color = 'C79C6E' },
    ['massacre'] = { class = 'Warrior', color = 'C79C6E' },
    ['sudden death'] = { class = 'Warrior', color = 'C79C6E' },
    ['anger management'] = { class = 'Warrior', color = 'C79C6E' },
    ['rend'] = { class = 'Warrior', color = 'C79C6E' },
    ['sunder armor'] = { class = 'Warrior', color = 'C79C6E' },
    ['revenge'] = { class = 'Warrior', color = 'C79C6E' },
    ['cleave'] = { class = 'Warrior', color = 'C79C6E' },
    ['slam'] = { class = 'Warrior', color = 'C79C6E' },
    ['hamstring'] = { class = 'Warrior', color = 'C79C6E' },
    ['intimidating shout'] = { class = 'Warrior', color = 'C79C6E' },
    ['disarm'] = { class = 'Warrior', color = 'C79C6E' },
    ['shield bash'] = { class = 'Warrior', color = 'C79C6E' },
    ['concussion blow'] = { class = 'Warrior', color = 'C79C6E' },
    ['bloodrage'] = { class = 'Warrior', color = 'C79C6E' },
    ['retaliation'] = { class = 'Warrior', color = 'C79C6E' },
    ['death wish'] = { class = 'Warrior', color = 'C79C6E' },
    ['sweeping strikes'] = { class = 'Warrior', color = 'C79C6E' },
    ['shockwave'] = { class = 'Warrior', color = 'C79C6E' },
    ['heroic leap'] = { class = 'Warrior', color = 'C79C6E' },
    ['heroic throw'] = { class = 'Warrior', color = 'C79C6E' },
    ['shattering throw'] = { class = 'Warrior', color = 'C79C6E' },
    ['intercept'] = { class = 'Warrior', color = 'C79C6E' },
    ['vigilance'] = { class = 'Warrior', color = 'C79C6E' },
    ['safeguard'] = { class = 'Warrior', color = 'C79C6E' },
    ['warbringer'] = { class = 'Warrior', color = 'C79C6E' },
    ['improved heroic strike'] = { class = 'Warrior', color = 'C79C6E' },
    ['improved charge'] = { class = 'Warrior', color = 'C79C6E' },
    ['improved rend'] = { class = 'Warrior', color = 'C79C6E' },
    ['improved thunder clap'] = { class = 'Warrior', color = 'C79C6E' },
    ['improved overpower'] = { class = 'Warrior', color = 'C79C6E' },
    ['deep wounds'] = { class = 'Warrior', color = 'C79C6E' },
    ['impale'] = { class = 'Warrior', color = 'C79C6E' },
    ['improved mortal strike'] = { class = 'Warrior', color = 'C79C6E' },
    ['axe specialization'] = { class = 'Warrior', color = 'C79C6E' },
    ['mace specialization'] = { class = 'Warrior', color = 'C79C6E' },
    ['sword specialization'] = { class = 'Warrior', color = 'C79C6E' },
    ['poleaxe specialization'] = { class = 'Warrior', color = 'C79C6E' },
    ['blood frenzy'] = { class = 'Warrior', color = 'C79C6E' },
    ['wrecking crew'] = { class = 'Warrior', color = 'C79C6E' },
    ['taste for blood'] = { class = 'Warrior', color = 'C79C6E' },
    ['improved slam'] = { class = 'Warrior', color = 'C79C6E' },
    ['unrelenting assault'] = { class = 'Warrior', color = 'C79C6E' },
    ['trauma'] = { class = 'Warrior', color = 'C79C6E' },
    ['armored to the teeth'] = { class = 'Warrior', color = 'C79C6E' },
    ['booming voice'] = { class = 'Warrior', color = 'C79C6E' },
    ['cruelty'] = { class = 'Warrior', color = 'C79C6E' },
    ['improved demoralizing shout'] = { class = 'Warrior', color = 'C79C6E' },
    ['unbridled wrath'] = { class = 'Warrior', color = 'C79C6E' },
    ['improved cleave'] = { class = 'Warrior', color = 'C79C6E' },
    ['commanding presence'] = { class = 'Warrior', color = 'C79C6E' },
    ['dual wield specialization'] = { class = 'Warrior', color = 'C79C6E' },
    ['improved execute'] = { class = 'Warrior', color = 'C79C6E' },
    ['enrage'] = { class = 'Warrior', color = 'C79C6E' },
    ['improved whirlwind'] = { class = 'Warrior', color = 'C79C6E' },
    ['improved intercept'] = { class = 'Warrior', color = 'C79C6E' },
    ['blood craze'] = { class = 'Warrior', color = 'C79C6E' },
    ['improved berserker rage'] = { class = 'Warrior', color = 'C79C6E' },
    ['furious attacks'] = { class = 'Warrior', color = 'C79C6E' },
    ['intensify rage'] = { class = 'Warrior', color = 'C79C6E' },
    ['bloodsurge'] = { class = 'Warrior', color = 'C79C6E' },
    ['unending fury'] = { class = 'Warrior', color = 'C79C6E' },
    ['titan\'s grip'] = { class = 'Warrior', color = 'C79C6E' },
    ['improved bloodrage'] = { class = 'Warrior', color = 'C79C6E' },
    ['tactical mastery'] = { class = 'Warrior', color = 'C79C6E' },
    ['improved revenge'] = { class = 'Warrior', color = 'C79C6E' },
    ['shield specialization'] = { class = 'Warrior', color = 'C79C6E' },
    ['toughness'] = { class = 'Warrior', color = 'C79C6E' },
    ['improved shield block'] = { class = 'Warrior', color = 'C79C6E' },
    ['improved sunder armor'] = { class = 'Warrior', color = 'C79C6E' },
    ['improved disarm'] = { class = 'Warrior', color = 'C79C6E' },
    ['puncture'] = { class = 'Warrior', color = 'C79C6E' },
    ['improved spell reflection'] = { class = 'Warrior', color = 'C79C6E' },
    ['improved defensive stance'] = { class = 'Warrior', color = 'C79C6E' },
    ['focused rage'] = { class = 'Warrior', color = 'C79C6E' },
    ['vitality'] = { class = 'Warrior', color = 'C79C6E' },
    ['shield mastery'] = { class = 'Warrior', color = 'C79C6E' },
    ['one-handed weapon specialization'] = { class = 'Warrior', color = 'C79C6E' },
    ['damage shield'] = { class = 'Warrior', color = 'C79C6E' },
    ['devastate'] = { class = 'Warrior', color = 'C79C6E' },
    ['critical block'] = { class = 'Warrior', color = 'C79C6E' },
    ['sword and board'] = { class = 'Warrior', color = 'C79C6E' },
};

-- Database of known talents per class (auto-generated from classTalents.ts)
local KNOWN_TALENT_CLASSES = {
    ['butcher'] = { class = 'Death Knight', color = 'C41F3B' },
    ['subversion'] = { class = 'Death Knight', color = 'C41F3B' },
    ['blade barrier'] = { class = 'Death Knight', color = 'C41F3B' },
    ['bladed armor'] = { class = 'Death Knight', color = 'C41F3B' },
    ['scent of blood'] = { class = 'Death Knight', color = 'C41F3B' },
    ['two-handed weapon specialization'] = { class = 'Death Knight', color = 'C41F3B' },
    ['dark conviction'] = { class = 'Death Knight', color = 'C41F3B' },
    ['death rune mastery'] = { class = 'Death Knight', color = 'C41F3B' },
    ['spell deflection'] = { class = 'Death Knight', color = 'C41F3B' },
    ['vendetta'] = { class = 'Death Knight', color = 'C41F3B' },
    ['bloody strikes'] = { class = 'Death Knight', color = 'C41F3B' },
    ['veteran of the third war'] = { class = 'Death Knight', color = 'C41F3B' },
    ['bloody vengeance'] = { class = 'Death Knight', color = 'C41F3B' },
    ['abomination\'s might'] = { class = 'Death Knight', color = 'C41F3B' },
    ['blood-caked blade'] = { class = 'Death Knight', color = 'C41F3B' },
    ['improved blood presence'] = { class = 'Death Knight', color = 'C41F3B' },
    ['improved death strike'] = { class = 'Death Knight', color = 'C41F3B' },
    ['sudden doom'] = { class = 'Death Knight', color = 'C41F3B' },
    ['might of mograine'] = { class = 'Death Knight', color = 'C41F3B' },
    ['will of the necropolis'] = { class = 'Death Knight', color = 'C41F3B' },
    ['improved icy touch'] = { class = 'Death Knight', color = 'C41F3B' },
    ['runic power mastery'] = { class = 'Death Knight', color = 'C41F3B' },
    ['toughness'] = { class = 'Death Knight', color = 'C41F3B' },
    ['icy reach'] = { class = 'Death Knight', color = 'C41F3B' },
    ['black ice'] = { class = 'Death Knight', color = 'C41F3B' },
    ['nerves of cold steel'] = { class = 'Death Knight', color = 'C41F3B' },
    ['annihilation'] = { class = 'Death Knight', color = 'C41F3B' },
    ['killing machine'] = { class = 'Death Knight', color = 'C41F3B' },
    ['chill of the grave'] = { class = 'Death Knight', color = 'C41F3B' },
    ['endless winter'] = { class = 'Death Knight', color = 'C41F3B' },
    ['frigid dreadplate'] = { class = 'Death Knight', color = 'C41F3B' },
    ['glacier rot'] = { class = 'Death Knight', color = 'C41F3B' },
    ['improved frost presence'] = { class = 'Death Knight', color = 'C41F3B' },
    ['merciless combat'] = { class = 'Death Knight', color = 'C41F3B' },
    ['rime'] = { class = 'Death Knight', color = 'C41F3B' },
    ['chilblains'] = { class = 'Death Knight', color = 'C41F3B' },
    ['improved icy talons'] = { class = 'Death Knight', color = 'C41F3B' },
    ['blood of the north'] = { class = 'Death Knight', color = 'C41F3B' },
    ['threat of thassarian'] = { class = 'Death Knight', color = 'C41F3B' },
    ['guile of gorefiend'] = { class = 'Death Knight', color = 'C41F3B' },
    ['tundra stalker'] = { class = 'Death Knight', color = 'C41F3B' },
    ['vicious strikes'] = { class = 'Death Knight', color = 'C41F3B' },
    ['virulence'] = { class = 'Death Knight', color = 'C41F3B' },
    ['anticipation'] = { class = 'Death Knight', color = 'C41F3B' },
    ['epidemic'] = { class = 'Death Knight', color = 'C41F3B' },
    ['morbidity'] = { class = 'Death Knight', color = 'C41F3B' },
    ['ravenous dead'] = { class = 'Death Knight', color = 'C41F3B' },
    ['outbreak'] = { class = 'Death Knight', color = 'C41F3B' },
    ['necrosis'] = { class = 'Death Knight', color = 'C41F3B' },
    ['night of the dead'] = { class = 'Death Knight', color = 'C41F3B' },
    ['impurity'] = { class = 'Death Knight', color = 'C41F3B' },
    ['dirge'] = { class = 'Death Knight', color = 'C41F3B' },
    ['desecration'] = { class = 'Death Knight', color = 'C41F3B' },
    ['magic suppression'] = { class = 'Death Knight', color = 'C41F3B' },
    ['reaping'] = { class = 'Death Knight', color = 'C41F3B' },
    ['master of ghouls'] = { class = 'Death Knight', color = 'C41F3B' },
    ['desolation'] = { class = 'Death Knight', color = 'C41F3B' },
    ['crypt fever'] = { class = 'Death Knight', color = 'C41F3B' },
    ['ebon plaguebringer'] = { class = 'Death Knight', color = 'C41F3B' },
    ['wandering plague'] = { class = 'Death Knight', color = 'C41F3B' },
    ['rage of rivendare'] = { class = 'Death Knight', color = 'C41F3B' },
    ['starlight wrath'] = { class = 'Druid', color = 'FF7D0A' },
    ['genesis'] = { class = 'Druid', color = 'FF7D0A' },
    ['moonglow'] = { class = 'Druid', color = 'FF7D0A' },
    ['nature\'s majesty'] = { class = 'Druid', color = 'FF7D0A' },
    ['improved moonfire'] = { class = 'Druid', color = 'FF7D0A' },
    ['brambles'] = { class = 'Druid', color = 'FF7D0A' },
    ['nature\'s grace'] = { class = 'Druid', color = 'FF7D0A' },
    ['celestial focus'] = { class = 'Druid', color = 'FF7D0A' },
    ['lunar guidance'] = { class = 'Druid', color = 'FF7D0A' },
    ['nature\'s reach'] = { class = 'Druid', color = 'FF7D0A' },
    ['vengeance'] = { class = 'Druid', color = 'FF7D0A' },
    ['dreamstate'] = { class = 'Druid', color = 'FF7D0A' },
    ['gale winds'] = { class = 'Druid', color = 'FF7D0A' },
    ['balance of power'] = { class = 'Druid', color = 'FF7D0A' },
    ['owlkin frenzy'] = { class = 'Druid', color = 'FF7D0A' },
    ['wrath of cenarius'] = { class = 'Druid', color = 'FF7D0A' },
    ['eclipse'] = { class = 'Druid', color = 'FF7D0A' },
    ['improved faerie fire'] = { class = 'Druid', color = 'FF7D0A' },
    ['earth and moon'] = { class = 'Druid', color = 'FF7D0A' },
    ['ferocity'] = { class = 'Druid', color = 'FF7D0A' },
    ['feral aggression'] = { class = 'Druid', color = 'FF7D0A' },
    ['feral instinct'] = { class = 'Druid', color = 'FF7D0A' },
    ['savage fury'] = { class = 'Druid', color = 'FF7D0A' },
    ['thick hide'] = { class = 'Druid', color = 'FF7D0A' },
    ['feral swiftness'] = { class = 'Druid', color = 'FF7D0A' },
    ['sharpened claws'] = { class = 'Druid', color = 'FF7D0A' },
    ['shredding attacks'] = { class = 'Druid', color = 'FF7D0A' },
    ['predatory strikes'] = { class = 'Druid', color = 'FF7D0A' },
    ['primal fury'] = { class = 'Druid', color = 'FF7D0A' },
    ['primal precision'] = { class = 'Druid', color = 'FF7D0A' },
    ['brutal impact'] = { class = 'Druid', color = 'FF7D0A' },
    ['heart of the wild'] = { class = 'Druid', color = 'FF7D0A' },
    ['survival of the fittest'] = { class = 'Druid', color = 'FF7D0A' },
    ['leader of the pack'] = { class = 'Druid', color = 'FF7D0A' },
    ['improved leader of the pack'] = { class = 'Druid', color = 'FF7D0A' },
    ['predatory instincts'] = { class = 'Druid', color = 'FF7D0A' },
    ['king of the jungle'] = { class = 'Druid', color = 'FF7D0A' },
    ['infected wounds'] = { class = 'Druid', color = 'FF7D0A' },
    ['natural reaction'] = { class = 'Druid', color = 'FF7D0A' },
    ['rend and tear'] = { class = 'Druid', color = 'FF7D0A' },
    ['improved mark of the wild'] = { class = 'Druid', color = 'FF7D0A' },
    ['nature\'s focus'] = { class = 'Druid', color = 'FF7D0A' },
    ['furor'] = { class = 'Druid', color = 'FF7D0A' },
    ['naturalist'] = { class = 'Druid', color = 'FF7D0A' },
    ['subtlety'] = { class = 'Druid', color = 'FF7D0A' },
    ['natural shapeshifter'] = { class = 'Druid', color = 'FF7D0A' },
    ['omen of clarity'] = { class = 'Druid', color = 'FF7D0A' },
    ['master shapeshifter'] = { class = 'Druid', color = 'FF7D0A' },
    ['tranquil spirit'] = { class = 'Druid', color = 'FF7D0A' },
    ['improved rejuvenation'] = { class = 'Druid', color = 'FF7D0A' },
    ['gift of nature'] = { class = 'Druid', color = 'FF7D0A' },
    ['empowered touch'] = { class = 'Druid', color = 'FF7D0A' },
    ['improved regrowth'] = { class = 'Druid', color = 'FF7D0A' },
    ['living seed'] = { class = 'Druid', color = 'FF7D0A' },
    ['revitalize'] = { class = 'Druid', color = 'FF7D0A' },
    ['improved tree of life'] = { class = 'Druid', color = 'FF7D0A' },
    ['empowered rejuvenation'] = { class = 'Druid', color = 'FF7D0A' },
    ['gift of the earthmother'] = { class = 'Druid', color = 'FF7D0A' },
    ['improved aspect of the hawk'] = { class = 'Hunter', color = 'ABD473' },
    ['endurance training'] = { class = 'Hunter', color = 'ABD473' },
    ['focused fire'] = { class = 'Hunter', color = 'ABD473' },
    ['improved aspect of the monkey'] = { class = 'Hunter', color = 'ABD473' },
    ['thick hide'] = { class = 'Hunter', color = 'ABD473' },
    ['improved revive pet'] = { class = 'Hunter', color = 'ABD473' },
    ['pathfinding'] = { class = 'Hunter', color = 'ABD473' },
    ['aspect mastery'] = { class = 'Hunter', color = 'ABD473' },
    ['unleashed fury'] = { class = 'Hunter', color = 'ABD473' },
    ['improved mend pet'] = { class = 'Hunter', color = 'ABD473' },
    ['ferocity'] = { class = 'Hunter', color = 'ABD473' },
    ['spirit bond'] = { class = 'Hunter', color = 'ABD473' },
    ['frenzy'] = { class = 'Hunter', color = 'ABD473' },
    ['ferocious inspiration'] = { class = 'Hunter', color = 'ABD473' },
    ['bestial discipline'] = { class = 'Hunter', color = 'ABD473' },
    ['animal handler'] = { class = 'Hunter', color = 'ABD473' },
    ['cobra strikes'] = { class = 'Hunter', color = 'ABD473' },
    ['longevity'] = { class = 'Hunter', color = 'ABD473' },
    ['kindred spirits'] = { class = 'Hunter', color = 'ABD473' },
    ['beast mastery'] = { class = 'Hunter', color = 'ABD473' },
    ['invigoration'] = { class = 'Hunter', color = 'ABD473' },
    ['improved concussive shot'] = { class = 'Hunter', color = 'ABD473' },
    ['focused aim'] = { class = 'Hunter', color = 'ABD473' },
    ['lethal shots'] = { class = 'Hunter', color = 'ABD473' },
    ['careful aim'] = { class = 'Hunter', color = 'ABD473' },
    ['improved hunter\'s mark'] = { class = 'Hunter', color = 'ABD473' },
    ['mortal shots'] = { class = 'Hunter', color = 'ABD473' },
    ['go for the throat'] = { class = 'Hunter', color = 'ABD473' },
    ['improved arcane shot'] = { class = 'Hunter', color = 'ABD473' },
    ['rapid killing'] = { class = 'Hunter', color = 'ABD473' },
    ['combat experience'] = { class = 'Hunter', color = 'ABD473' },
    ['piercing shots'] = { class = 'Hunter', color = 'ABD473' },
    ['concussive barrage'] = { class = 'Hunter', color = 'ABD473' },
    ['master marksman'] = { class = 'Hunter', color = 'ABD473' },
    ['wild quiver'] = { class = 'Hunter', color = 'ABD473' },
    ['improved steady shot'] = { class = 'Hunter', color = 'ABD473' },
    ['marked for death'] = { class = 'Hunter', color = 'ABD473' },
    ['improved tracking'] = { class = 'Hunter', color = 'ABD473' },
    ['hawk eye'] = { class = 'Hunter', color = 'ABD473' },
    ['savage strikes'] = { class = 'Hunter', color = 'ABD473' },
    ['surefooted'] = { class = 'Hunter', color = 'ABD473' },
    ['entrapment'] = { class = 'Hunter', color = 'ABD473' },
    ['trap mastery'] = { class = 'Hunter', color = 'ABD473' },
    ['survival instincts'] = { class = 'Hunter', color = 'ABD473' },
    ['survivalist'] = { class = 'Hunter', color = 'ABD473' },
    ['deflection'] = { class = 'Hunter', color = 'ABD473' },
    ['lock and load'] = { class = 'Hunter', color = 'ABD473' },
    ['clever traps'] = { class = 'Hunter', color = 'ABD473' },
    ['survival tactics'] = { class = 'Hunter', color = 'ABD473' },
    ['tnt'] = { class = 'Hunter', color = 'ABD473' },
    ['killer instinct'] = { class = 'Hunter', color = 'ABD473' },
    ['resourcefulness'] = { class = 'Hunter', color = 'ABD473' },
    ['lightning reflexes'] = { class = 'Hunter', color = 'ABD473' },
    ['thrill of the hunt'] = { class = 'Hunter', color = 'ABD473' },
    ['expose weakness'] = { class = 'Hunter', color = 'ABD473' },
    ['hunter vs. wild'] = { class = 'Hunter', color = 'ABD473' },
    ['noxious stings'] = { class = 'Hunter', color = 'ABD473' },
    ['point of no escape'] = { class = 'Hunter', color = 'ABD473' },
    ['sniper training'] = { class = 'Hunter', color = 'ABD473' },
    ['hunting party'] = { class = 'Hunter', color = 'ABD473' },
    ['arcane subtlety'] = { class = 'Mage', color = '69CCF0' },
    ['arcane focus'] = { class = 'Mage', color = '69CCF0' },
    ['arcane stability'] = { class = 'Mage', color = '69CCF0' },
    ['arcane fortitude'] = { class = 'Mage', color = '69CCF0' },
    ['magic absorption'] = { class = 'Mage', color = '69CCF0' },
    ['arcane concentration'] = { class = 'Mage', color = '69CCF0' },
    ['magic attunement'] = { class = 'Mage', color = '69CCF0' },
    ['spell impact'] = { class = 'Mage', color = '69CCF0' },
    ['student of the mind'] = { class = 'Mage', color = '69CCF0' },
    ['arcane shielding'] = { class = 'Mage', color = '69CCF0' },
    ['improved counterspell'] = { class = 'Mage', color = '69CCF0' },
    ['arcane meditation'] = { class = 'Mage', color = '69CCF0' },
    ['torment the weak'] = { class = 'Mage', color = '69CCF0' },
    ['improved blink'] = { class = 'Mage', color = '69CCF0' },
    ['arcane mind'] = { class = 'Mage', color = '69CCF0' },
    ['prismatic cloak'] = { class = 'Mage', color = '69CCF0' },
    ['arcane instability'] = { class = 'Mage', color = '69CCF0' },
    ['arcane potency'] = { class = 'Mage', color = '69CCF0' },
    ['empowered arcane missiles'] = { class = 'Mage', color = '69CCF0' },
    ['incanter\'s absorption'] = { class = 'Mage', color = '69CCF0' },
    ['arcane flows'] = { class = 'Mage', color = '69CCF0' },
    ['mind mastery'] = { class = 'Mage', color = '69CCF0' },
    ['missile barrage'] = { class = 'Mage', color = '69CCF0' },
    ['netherwind presence'] = { class = 'Mage', color = '69CCF0' },
    ['spell power'] = { class = 'Mage', color = '69CCF0' },
    ['improved fireball'] = { class = 'Mage', color = '69CCF0' },
    ['ignite'] = { class = 'Mage', color = '69CCF0' },
    ['fire throwing'] = { class = 'Mage', color = '69CCF0' },
    ['impact'] = { class = 'Mage', color = '69CCF0' },
    ['pyroclasm'] = { class = 'Mage', color = '69CCF0' },
    ['burning determination'] = { class = 'Mage', color = '69CCF0' },
    ['improved scorch'] = { class = 'Mage', color = '69CCF0' },
    ['molten shields'] = { class = 'Mage', color = '69CCF0' },
    ['master of elements'] = { class = 'Mage', color = '69CCF0' },
    ['playing with fire'] = { class = 'Mage', color = '69CCF0' },
    ['critical mass'] = { class = 'Mage', color = '69CCF0' },
    ['fire power'] = { class = 'Mage', color = '69CCF0' },
    ['pyromaniac'] = { class = 'Mage', color = '69CCF0' },
    ['improved flamestrike'] = { class = 'Mage', color = '69CCF0' },
    ['molten fury'] = { class = 'Mage', color = '69CCF0' },
    ['empowered fire'] = { class = 'Mage', color = '69CCF0' },
    ['firestarter'] = { class = 'Mage', color = '69CCF0' },
    ['hot streak'] = { class = 'Mage', color = '69CCF0' },
    ['burnout'] = { class = 'Mage', color = '69CCF0' },
    ['frostbite'] = { class = 'Mage', color = '69CCF0' },
    ['improved frostbolt'] = { class = 'Mage', color = '69CCF0' },
    ['ice floes'] = { class = 'Mage', color = '69CCF0' },
    ['ice shards'] = { class = 'Mage', color = '69CCF0' },
    ['precision'] = { class = 'Mage', color = '69CCF0' },
    ['permafrost'] = { class = 'Mage', color = '69CCF0' },
    ['piercing ice'] = { class = 'Mage', color = '69CCF0' },
    ['improved frost nova'] = { class = 'Mage', color = '69CCF0' },
    ['arctic reach'] = { class = 'Mage', color = '69CCF0' },
    ['frost channeling'] = { class = 'Mage', color = '69CCF0' },
    ['shatter'] = { class = 'Mage', color = '69CCF0' },
    ['improved blizzard'] = { class = 'Mage', color = '69CCF0' },
    ['arctic winds'] = { class = 'Mage', color = '69CCF0' },
    ['empowered frostbolt'] = { class = 'Mage', color = '69CCF0' },
    ['fingers of frost'] = { class = 'Mage', color = '69CCF0' },
    ['brain freeze'] = { class = 'Mage', color = '69CCF0' },
    ['enduring winter'] = { class = 'Mage', color = '69CCF0' },
    ['chilled to the bone'] = { class = 'Mage', color = '69CCF0' },
    ['spiritual focus'] = { class = 'Paladin', color = 'F58CBA' },
    ['seals of the pure'] = { class = 'Paladin', color = 'F58CBA' },
    ['healing light'] = { class = 'Paladin', color = 'F58CBA' },
    ['divine intellect'] = { class = 'Paladin', color = 'F58CBA' },
    ['unyielding faith'] = { class = 'Paladin', color = 'F58CBA' },
    ['illumination'] = { class = 'Paladin', color = 'F58CBA' },
    ['improved lay on hands'] = { class = 'Paladin', color = 'F58CBA' },
    ['pure of heart'] = { class = 'Paladin', color = 'F58CBA' },
    ['blessed hands'] = { class = 'Paladin', color = 'F58CBA' },
    ['light\'s grace'] = { class = 'Paladin', color = 'F58CBA' },
    ['holy guidance'] = { class = 'Paladin', color = 'F58CBA' },
    ['infusion of light'] = { class = 'Paladin', color = 'F58CBA' },
    ['sacred cleansing'] = { class = 'Paladin', color = 'F58CBA' },
    ['judgements of the pure'] = { class = 'Paladin', color = 'F58CBA' },
    ['divinity'] = { class = 'Paladin', color = 'F58CBA' },
    ['divine strength'] = { class = 'Paladin', color = 'F58CBA' },
    ['stoicism'] = { class = 'Paladin', color = 'F58CBA' },
    ['guardian\'s favor'] = { class = 'Paladin', color = 'F58CBA' },
    ['anticipation'] = { class = 'Paladin', color = 'F58CBA' },
    ['improved righteous fury'] = { class = 'Paladin', color = 'F58CBA' },
    ['toughness'] = { class = 'Paladin', color = 'F58CBA' },
    ['improved hammer of justice'] = { class = 'Paladin', color = 'F58CBA' },
    ['improved devotion aura'] = { class = 'Paladin', color = 'F58CBA' },
    ['reckoning'] = { class = 'Paladin', color = 'F58CBA' },
    ['sacred duty'] = { class = 'Paladin', color = 'F58CBA' },
    ['one-handed weapon specialization'] = { class = 'Paladin', color = 'F58CBA' },
    ['spiritual attunement'] = { class = 'Paladin', color = 'F58CBA' },
    ['ardent defender'] = { class = 'Paladin', color = 'F58CBA' },
    ['redoubt'] = { class = 'Paladin', color = 'F58CBA' },
    ['combat readiness'] = { class = 'Paladin', color = 'F58CBA' },
    ['guarded by the light'] = { class = 'Paladin', color = 'F58CBA' },
    ['shield of the templar'] = { class = 'Paladin', color = 'F58CBA' },
    ['judgements of the just'] = { class = 'Paladin', color = 'F58CBA' },
    ['touched by the light'] = { class = 'Paladin', color = 'F58CBA' },
    ['deflection'] = { class = 'Paladin', color = 'F58CBA' },
    ['benediction'] = { class = 'Paladin', color = 'F58CBA' },
    ['improved judgements'] = { class = 'Paladin', color = 'F58CBA' },
    ['heart of the crusader'] = { class = 'Paladin', color = 'F58CBA' },
    ['improved blessing of might'] = { class = 'Paladin', color = 'F58CBA' },
    ['vindication'] = { class = 'Paladin', color = 'F58CBA' },
    ['conviction'] = { class = 'Paladin', color = 'F58CBA' },
    ['pursuit of justice'] = { class = 'Paladin', color = 'F58CBA' },
    ['eye for an eye'] = { class = 'Paladin', color = 'F58CBA' },
    ['sanctity of battle'] = { class = 'Paladin', color = 'F58CBA' },
    ['crusade'] = { class = 'Paladin', color = 'F58CBA' },
    ['two-handed weapon specialization'] = { class = 'Paladin', color = 'F58CBA' },
    ['sanctified retribution'] = { class = 'Paladin', color = 'F58CBA' },
    ['vengeance'] = { class = 'Paladin', color = 'F58CBA' },
    ['the art of war'] = { class = 'Paladin', color = 'F58CBA' },
    ['fanaticism'] = { class = 'Paladin', color = 'F58CBA' },
    ['sheath of light'] = { class = 'Paladin', color = 'F58CBA' },
    ['swift retribution'] = { class = 'Paladin', color = 'F58CBA' },
    ['righteous vengeance'] = { class = 'Paladin', color = 'F58CBA' },
    ['unbreakable will'] = { class = 'Priest', color = 'FFFFFF' },
    ['twin disciplines'] = { class = 'Priest', color = 'FFFFFF' },
    ['silent resolve'] = { class = 'Priest', color = 'FFFFFF' },
    ['improved inner fire'] = { class = 'Priest', color = 'FFFFFF' },
    ['improved power word: fortitude'] = { class = 'Priest', color = 'FFFFFF' },
    ['martyrdom'] = { class = 'Priest', color = 'FFFFFF' },
    ['meditation'] = { class = 'Priest', color = 'FFFFFF' },
    ['improved power word: shield'] = { class = 'Priest', color = 'FFFFFF' },
    ['absolution'] = { class = 'Priest', color = 'FFFFFF' },
    ['mental agility'] = { class = 'Priest', color = 'FFFFFF' },
    ['improved mana burn'] = { class = 'Priest', color = 'FFFFFF' },
    ['mental strength'] = { class = 'Priest', color = 'FFFFFF' },
    ['soul warding'] = { class = 'Priest', color = 'FFFFFF' },
    ['focused power'] = { class = 'Priest', color = 'FFFFFF' },
    ['enlightenment'] = { class = 'Priest', color = 'FFFFFF' },
    ['focused will'] = { class = 'Priest', color = 'FFFFFF' },
    ['reflective shield'] = { class = 'Priest', color = 'FFFFFF' },
    ['rapture'] = { class = 'Priest', color = 'FFFFFF' },
    ['aspiration'] = { class = 'Priest', color = 'FFFFFF' },
    ['divine aegis'] = { class = 'Priest', color = 'FFFFFF' },
    ['grace'] = { class = 'Priest', color = 'FFFFFF' },
    ['borrowed time'] = { class = 'Priest', color = 'FFFFFF' },
    ['renewed hope'] = { class = 'Priest', color = 'FFFFFF' },
    ['holy specialization'] = { class = 'Priest', color = 'FFFFFF' },
    ['spell warding'] = { class = 'Priest', color = 'FFFFFF' },
    ['divine fury'] = { class = 'Priest', color = 'FFFFFF' },
    ['blessed recovery'] = { class = 'Priest', color = 'FFFFFF' },
    ['inspiration'] = { class = 'Priest', color = 'FFFFFF' },
    ['holy reach'] = { class = 'Priest', color = 'FFFFFF' },
    ['improved renew'] = { class = 'Priest', color = 'FFFFFF' },
    ['healing focus'] = { class = 'Priest', color = 'FFFFFF' },
    ['improved healing'] = { class = 'Priest', color = 'FFFFFF' },
    ['searing light'] = { class = 'Priest', color = 'FFFFFF' },
    ['spirit of redemption'] = { class = 'Priest', color = 'FFFFFF' },
    ['spiritual guidance'] = { class = 'Priest', color = 'FFFFFF' },
    ['surge of light'] = { class = 'Priest', color = 'FFFFFF' },
    ['spiritual healing'] = { class = 'Priest', color = 'FFFFFF' },
    ['holy concentration'] = { class = 'Priest', color = 'FFFFFF' },
    ['serendipity'] = { class = 'Priest', color = 'FFFFFF' },
    ['empowered healing'] = { class = 'Priest', color = 'FFFFFF' },
    ['test of faith'] = { class = 'Priest', color = 'FFFFFF' },
    ['empowered reserve'] = { class = 'Priest', color = 'FFFFFF' },
    ['spirit tap'] = { class = 'Priest', color = 'FFFFFF' },
    ['improved spirit tap'] = { class = 'Priest', color = 'FFFFFF' },
    ['darkness'] = { class = 'Priest', color = 'FFFFFF' },
    ['shadow affinity'] = { class = 'Priest', color = 'FFFFFF' },
    ['improved shadow word: pain'] = { class = 'Priest', color = 'FFFFFF' },
    ['shadow focus'] = { class = 'Priest', color = 'FFFFFF' },
    ['improved psychic scream'] = { class = 'Priest', color = 'FFFFFF' },
    ['improved mind blast'] = { class = 'Priest', color = 'FFFFFF' },
    ['veiled shadows'] = { class = 'Priest', color = 'FFFFFF' },
    ['shadow reach'] = { class = 'Priest', color = 'FFFFFF' },
    ['shadow weaving'] = { class = 'Priest', color = 'FFFFFF' },
    ['vampiric embrace'] = { class = 'Priest', color = 'FFFFFF' },
    ['improved vampiric embrace'] = { class = 'Priest', color = 'FFFFFF' },
    ['focused mind'] = { class = 'Priest', color = 'FFFFFF' },
    ['mind melt'] = { class = 'Priest', color = 'FFFFFF' },
    ['misery'] = { class = 'Priest', color = 'FFFFFF' },
    ['shadow power'] = { class = 'Priest', color = 'FFFFFF' },
    ['improved shadowform'] = { class = 'Priest', color = 'FFFFFF' },
    ['pain and suffering'] = { class = 'Priest', color = 'FFFFFF' },
    ['twisted faith'] = { class = 'Priest', color = 'FFFFFF' },
    ['improved eviscerate'] = { class = 'Rogue', color = 'FFF569' },
    ['remorseless attacks'] = { class = 'Rogue', color = 'FFF569' },
    ['malice'] = { class = 'Rogue', color = 'FFF569' },
    ['ruthlessness'] = { class = 'Rogue', color = 'FFF569' },
    ['blood spatter'] = { class = 'Rogue', color = 'FFF569' },
    ['puncturing wounds'] = { class = 'Rogue', color = 'FFF569' },
    ['vigor'] = { class = 'Rogue', color = 'FFF569' },
    ['improved expose armor'] = { class = 'Rogue', color = 'FFF569' },
    ['lethality'] = { class = 'Rogue', color = 'FFF569' },
    ['vile poisons'] = { class = 'Rogue', color = 'FFF569' },
    ['improved poisons'] = { class = 'Rogue', color = 'FFF569' },
    ['fleet footed'] = { class = 'Rogue', color = 'FFF569' },
    ['seal fate'] = { class = 'Rogue', color = 'FFF569' },
    ['murder'] = { class = 'Rogue', color = 'FFF569' },
    ['deadly brew'] = { class = 'Rogue', color = 'FFF569' },
    ['overkill'] = { class = 'Rogue', color = 'FFF569' },
    ['focused attacks'] = { class = 'Rogue', color = 'FFF569' },
    ['find weakness'] = { class = 'Rogue', color = 'FFF569' },
    ['master poisoner'] = { class = 'Rogue', color = 'FFF569' },
    ['cut to the chase'] = { class = 'Rogue', color = 'FFF569' },
    ['improved sinister strike'] = { class = 'Rogue', color = 'FFF569' },
    ['dual wield specialization'] = { class = 'Rogue', color = 'FFF569' },
    ['improved slice and dice'] = { class = 'Rogue', color = 'FFF569' },
    ['deflection'] = { class = 'Rogue', color = 'FFF569' },
    ['precision'] = { class = 'Rogue', color = 'FFF569' },
    ['endurance'] = { class = 'Rogue', color = 'FFF569' },
    ['lightning reflexes'] = { class = 'Rogue', color = 'FFF569' },
    ['improved gouge'] = { class = 'Rogue', color = 'FFF569' },
    ['improved kick'] = { class = 'Rogue', color = 'FFF569' },
    ['improved sprint'] = { class = 'Rogue', color = 'FFF569' },
    ['combat potency'] = { class = 'Rogue', color = 'FFF569' },
    ['blade twisting'] = { class = 'Rogue', color = 'FFF569' },
    ['weapon expertise'] = { class = 'Rogue', color = 'FFF569' },
    ['aggression'] = { class = 'Rogue', color = 'FFF569' },
    ['mace specialization'] = { class = 'Rogue', color = 'FFF569' },
    ['sword specialization'] = { class = 'Rogue', color = 'FFF569' },
    ['close quarters combat'] = { class = 'Rogue', color = 'FFF569' },
    ['hack and slash'] = { class = 'Rogue', color = 'FFF569' },
    ['vitality'] = { class = 'Rogue', color = 'FFF569' },
    ['surprise attacks'] = { class = 'Rogue', color = 'FFF569' },
    ['savage combat'] = { class = 'Rogue', color = 'FFF569' },
    ['unfair advantage'] = { class = 'Rogue', color = 'FFF569' },
    ['prey on the weak'] = { class = 'Rogue', color = 'FFF569' },
    ['relentless strikes'] = { class = 'Rogue', color = 'FFF569' },
    ['master of deception'] = { class = 'Rogue', color = 'FFF569' },
    ['opportunity'] = { class = 'Rogue', color = 'FFF569' },
    ['sleight of hand'] = { class = 'Rogue', color = 'FFF569' },
    ['camouflage'] = { class = 'Rogue', color = 'FFF569' },
    ['elusiveness'] = { class = 'Rogue', color = 'FFF569' },
    ['initiative'] = { class = 'Rogue', color = 'FFF569' },
    ['setup'] = { class = 'Rogue', color = 'FFF569' },
    ['improved ambush'] = { class = 'Rogue', color = 'FFF569' },
    ['serrated blades'] = { class = 'Rogue', color = 'FFF569' },
    ['heightened senses'] = { class = 'Rogue', color = 'FFF569' },
    ['deadliness'] = { class = 'Rogue', color = 'FFF569' },
    ['dirty deeds'] = { class = 'Rogue', color = 'FFF569' },
    ['master of subtlety'] = { class = 'Rogue', color = 'FFF569' },
    ['enveloping shadows'] = { class = 'Rogue', color = 'FFF569' },
    ['cheat death'] = { class = 'Rogue', color = 'FFF569' },
    ['waylay'] = { class = 'Rogue', color = 'FFF569' },
    ['sinister calling'] = { class = 'Rogue', color = 'FFF569' },
    ['honor among thieves'] = { class = 'Rogue', color = 'FFF569' },
    ['filthy tricks'] = { class = 'Rogue', color = 'FFF569' },
    ['slaughter from the shadows'] = { class = 'Rogue', color = 'FFF569' },
    ['convection'] = { class = 'Shaman', color = '0070DE' },
    ['concussion'] = { class = 'Shaman', color = '0070DE' },
    ['call of flame'] = { class = 'Shaman', color = '0070DE' },
    ['elemental warding'] = { class = 'Shaman', color = '0070DE' },
    ['elemental devastation'] = { class = 'Shaman', color = '0070DE' },
    ['reverberation'] = { class = 'Shaman', color = '0070DE' },
    ['elemental focus'] = { class = 'Shaman', color = '0070DE' },
    ['elemental fury'] = { class = 'Shaman', color = '0070DE' },
    ['improved fire nova'] = { class = 'Shaman', color = '0070DE' },
    ['eye of the storm'] = { class = 'Shaman', color = '0070DE' },
    ['elemental reach'] = { class = 'Shaman', color = '0070DE' },
    ['call of thunder'] = { class = 'Shaman', color = '0070DE' },
    ['unrelenting storm'] = { class = 'Shaman', color = '0070DE' },
    ['elemental precision'] = { class = 'Shaman', color = '0070DE' },
    ['lightning mastery'] = { class = 'Shaman', color = '0070DE' },
    ['elemental shields'] = { class = 'Shaman', color = '0070DE' },
    ['elemental oath'] = { class = 'Shaman', color = '0070DE' },
    ['lightning overload'] = { class = 'Shaman', color = '0070DE' },
    ['astral shift'] = { class = 'Shaman', color = '0070DE' },
    ['lava flows'] = { class = 'Shaman', color = '0070DE' },
    ['storm, earth and fire'] = { class = 'Shaman', color = '0070DE' },
    ['shamanism'] = { class = 'Shaman', color = '0070DE' },
    ['enhancing totems'] = { class = 'Shaman', color = '0070DE' },
    ['earth\'s grasp'] = { class = 'Shaman', color = '0070DE' },
    ['ancestral knowledge'] = { class = 'Shaman', color = '0070DE' },
    ['guardian totems'] = { class = 'Shaman', color = '0070DE' },
    ['thundering strikes'] = { class = 'Shaman', color = '0070DE' },
    ['improved ghost wolf'] = { class = 'Shaman', color = '0070DE' },
    ['improved lightning shield'] = { class = 'Shaman', color = '0070DE' },
    ['anticipation'] = { class = 'Shaman', color = '0070DE' },
    ['flurry'] = { class = 'Shaman', color = '0070DE' },
    ['ancestral healing'] = { class = 'Shaman', color = '0070DE' },
    ['elemental weapons'] = { class = 'Shaman', color = '0070DE' },
    ['spirit weapons'] = { class = 'Shaman', color = '0070DE' },
    ['weapon mastery'] = { class = 'Shaman', color = '0070DE' },
    ['frozen power'] = { class = 'Shaman', color = '0070DE' },
    ['toughness'] = { class = 'Shaman', color = '0070DE' },
    ['dual wield specialization'] = { class = 'Shaman', color = '0070DE' },
    ['dual wield'] = { class = 'Shaman', color = '0070DE' },
    ['unleashed rage'] = { class = 'Shaman', color = '0070DE' },
    ['improved stormstrike'] = { class = 'Shaman', color = '0070DE' },
    ['static shock'] = { class = 'Shaman', color = '0070DE' },
    ['mental quickness'] = { class = 'Shaman', color = '0070DE' },
    ['maelstrom weapon'] = { class = 'Shaman', color = '0070DE' },
    ['earthen power'] = { class = 'Shaman', color = '0070DE' },
    ['improved healing wave'] = { class = 'Shaman', color = '0070DE' },
    ['totemic focus'] = { class = 'Shaman', color = '0070DE' },
    ['improved reincarnation'] = { class = 'Shaman', color = '0070DE' },
    ['healing grace'] = { class = 'Shaman', color = '0070DE' },
    ['restorative totems'] = { class = 'Shaman', color = '0070DE' },
    ['tidal focus'] = { class = 'Shaman', color = '0070DE' },
    ['healing guidance'] = { class = 'Shaman', color = '0070DE' },
    ['healing way'] = { class = 'Shaman', color = '0070DE' },
    ['nature\'s guidance'] = { class = 'Shaman', color = '0070DE' },
    ['tidal mastery'] = { class = 'Shaman', color = '0070DE' },
    ['purifying waters'] = { class = 'Shaman', color = '0070DE' },
    ['healing mind'] = { class = 'Shaman', color = '0070DE' },
    ['improved water shield'] = { class = 'Shaman', color = '0070DE' },
    ['cleansing waters'] = { class = 'Shaman', color = '0070DE' },
    ['ancestral awakening'] = { class = 'Shaman', color = '0070DE' },
    ['tidal waves'] = { class = 'Shaman', color = '0070DE' },
    ['blessing of the eternals'] = { class = 'Shaman', color = '0070DE' },
    ['improved curse of agony'] = { class = 'Warlock', color = '9482C9' },
    ['suppression'] = { class = 'Warlock', color = '9482C9' },
    ['improved corruption'] = { class = 'Warlock', color = '9482C9' },
    ['frailty'] = { class = 'Warlock', color = '9482C9' },
    ['improved drain soul'] = { class = 'Warlock', color = '9482C9' },
    ['improved life tap'] = { class = 'Warlock', color = '9482C9' },
    ['soul siphon'] = { class = 'Warlock', color = '9482C9' },
    ['fel concentration'] = { class = 'Warlock', color = '9482C9' },
    ['amplify curse'] = { class = 'Warlock', color = '9482C9' },
    ['grim reach'] = { class = 'Warlock', color = '9482C9' },
    ['nightfall'] = { class = 'Warlock', color = '9482C9' },
    ['empowered corruption'] = { class = 'Warlock', color = '9482C9' },
    ['shadow embrace'] = { class = 'Warlock', color = '9482C9' },
    ['siphon life'] = { class = 'Warlock', color = '9482C9' },
    ['shadow mastery'] = { class = 'Warlock', color = '9482C9' },
    ['contagion'] = { class = 'Warlock', color = '9482C9' },
    ['improved howl of terror'] = { class = 'Warlock', color = '9482C9' },
    ['malediction'] = { class = 'Warlock', color = '9482C9' },
    ['death\'s embrace'] = { class = 'Warlock', color = '9482C9' },
    ['everlasting affliction'] = { class = 'Warlock', color = '9482C9' },
    ['pandemic'] = { class = 'Warlock', color = '9482C9' },
    ['improved healthstone'] = { class = 'Warlock', color = '9482C9' },
    ['demonic embrace'] = { class = 'Warlock', color = '9482C9' },
    ['improved voidwalker'] = { class = 'Warlock', color = '9482C9' },
    ['fel synergy'] = { class = 'Warlock', color = '9482C9' },
    ['demonic brutality'] = { class = 'Warlock', color = '9482C9' },
    ['fel vitality'] = { class = 'Warlock', color = '9482C9' },
    ['improved succubus'] = { class = 'Warlock', color = '9482C9' },
    ['soul link'] = { class = 'Warlock', color = '9482C9' },
    ['demonic aegis'] = { class = 'Warlock', color = '9482C9' },
    ['unholy power'] = { class = 'Warlock', color = '9482C9' },
    ['master summoner'] = { class = 'Warlock', color = '9482C9' },
    ['mana feed'] = { class = 'Warlock', color = '9482C9' },
    ['master conjuror'] = { class = 'Warlock', color = '9482C9' },
    ['master demonologist'] = { class = 'Warlock', color = '9482C9' },
    ['molten core'] = { class = 'Warlock', color = '9482C9' },
    ['demonic resilience'] = { class = 'Warlock', color = '9482C9' },
    ['demonic knowledge'] = { class = 'Warlock', color = '9482C9' },
    ['demonic tactics'] = { class = 'Warlock', color = '9482C9' },
    ['decimation'] = { class = 'Warlock', color = '9482C9' },
    ['nemesis'] = { class = 'Warlock', color = '9482C9' },
    ['demonic pact'] = { class = 'Warlock', color = '9482C9' },
    ['improved shadow bolt'] = { class = 'Warlock', color = '9482C9' },
    ['bane'] = { class = 'Warlock', color = '9482C9' },
    ['aftermath'] = { class = 'Warlock', color = '9482C9' },
    ['molten skin'] = { class = 'Warlock', color = '9482C9' },
    ['cataclysm'] = { class = 'Warlock', color = '9482C9' },
    ['demonic power'] = { class = 'Warlock', color = '9482C9' },
    ['ruin'] = { class = 'Warlock', color = '9482C9' },
    ['intensity'] = { class = 'Warlock', color = '9482C9' },
    ['destructive reach'] = { class = 'Warlock', color = '9482C9' },
    ['improved searing pain'] = { class = 'Warlock', color = '9482C9' },
    ['backlash'] = { class = 'Warlock', color = '9482C9' },
    ['improved immolate'] = { class = 'Warlock', color = '9482C9' },
    ['devastation'] = { class = 'Warlock', color = '9482C9' },
    ['nether protection'] = { class = 'Warlock', color = '9482C9' },
    ['emberstorm'] = { class = 'Warlock', color = '9482C9' },
    ['soul leech'] = { class = 'Warlock', color = '9482C9' },
    ['pyroclasm'] = { class = 'Warlock', color = '9482C9' },
    ['shadow and flame'] = { class = 'Warlock', color = '9482C9' },
    ['improved soul leech'] = { class = 'Warlock', color = '9482C9' },
    ['backdraft'] = { class = 'Warlock', color = '9482C9' },
    ['fire and brimstone'] = { class = 'Warlock', color = '9482C9' },
    ['empowered imp'] = { class = 'Warlock', color = '9482C9' },
    ['improved heroic strike'] = { class = 'Warrior', color = 'C79C6E' },
    ['deflection'] = { class = 'Warrior', color = 'C79C6E' },
    ['improved rend'] = { class = 'Warrior', color = 'C79C6E' },
    ['improved charge'] = { class = 'Warrior', color = 'C79C6E' },
    ['iron will'] = { class = 'Warrior', color = 'C79C6E' },
    ['tactical mastery'] = { class = 'Warrior', color = 'C79C6E' },
    ['improved overpower'] = { class = 'Warrior', color = 'C79C6E' },
    ['anger management'] = { class = 'Warrior', color = 'C79C6E' },
    ['deep wounds'] = { class = 'Warrior', color = 'C79C6E' },
    ['two-handed weapon specialization'] = { class = 'Warrior', color = 'C79C6E' },
    ['impale'] = { class = 'Warrior', color = 'C79C6E' },
    ['poleaxe specialization'] = { class = 'Warrior', color = 'C79C6E' },
    ['mace specialization'] = { class = 'Warrior', color = 'C79C6E' },
    ['sword specialization'] = { class = 'Warrior', color = 'C79C6E' },
    ['weapon mastery'] = { class = 'Warrior', color = 'C79C6E' },
    ['taste for blood'] = { class = 'Warrior', color = 'C79C6E' },
    ['improved slam'] = { class = 'Warrior', color = 'C79C6E' },
    ['trauma'] = { class = 'Warrior', color = 'C79C6E' },
    ['second wind'] = { class = 'Warrior', color = 'C79C6E' },
    ['blood frenzy'] = { class = 'Warrior', color = 'C79C6E' },
    ['strength of arms'] = { class = 'Warrior', color = 'C79C6E' },
    ['juggernaut'] = { class = 'Warrior', color = 'C79C6E' },
    ['improved mortal strike'] = { class = 'Warrior', color = 'C79C6E' },
    ['unrelenting assault'] = { class = 'Warrior', color = 'C79C6E' },
    ['sudden death'] = { class = 'Warrior', color = 'C79C6E' },
    ['endless rage'] = { class = 'Warrior', color = 'C79C6E' },
    ['wrecking crew'] = { class = 'Warrior', color = 'C79C6E' },
    ['armored to the teeth'] = { class = 'Warrior', color = 'C79C6E' },
    ['booming voice'] = { class = 'Warrior', color = 'C79C6E' },
    ['cruelty'] = { class = 'Warrior', color = 'C79C6E' },
    ['improved demoralizing shout'] = { class = 'Warrior', color = 'C79C6E' },
    ['unbridled wrath'] = { class = 'Warrior', color = 'C79C6E' },
    ['improved cleave'] = { class = 'Warrior', color = 'C79C6E' },
    ['commanding presence'] = { class = 'Warrior', color = 'C79C6E' },
    ['dual wield specialization'] = { class = 'Warrior', color = 'C79C6E' },
    ['improved execute'] = { class = 'Warrior', color = 'C79C6E' },
    ['enrage'] = { class = 'Warrior', color = 'C79C6E' },
    ['precision'] = { class = 'Warrior', color = 'C79C6E' },
    ['improved berserker rage'] = { class = 'Warrior', color = 'C79C6E' },
    ['flurry'] = { class = 'Warrior', color = 'C79C6E' },
    ['intensify rage'] = { class = 'Warrior', color = 'C79C6E' },
    ['blood craze'] = { class = 'Warrior', color = 'C79C6E' },
    ['improved whirlwind'] = { class = 'Warrior', color = 'C79C6E' },
    ['improved intercept'] = { class = 'Warrior', color = 'C79C6E' },
    ['furious attacks'] = { class = 'Warrior', color = 'C79C6E' },
    ['rampage'] = { class = 'Warrior', color = 'C79C6E' },
    ['bloodsurge'] = { class = 'Warrior', color = 'C79C6E' },
    ['unending fury'] = { class = 'Warrior', color = 'C79C6E' },
    ['titan\'s grip'] = { class = 'Warrior', color = 'C79C6E' },
    ['shield specialization'] = { class = 'Warrior', color = 'C79C6E' },
    ['anticipation'] = { class = 'Warrior', color = 'C79C6E' },
    ['improved bloodrage'] = { class = 'Warrior', color = 'C79C6E' },
    ['toughness'] = { class = 'Warrior', color = 'C79C6E' },
    ['improved spell reflection'] = { class = 'Warrior', color = 'C79C6E' },
    ['improved thunder clap'] = { class = 'Warrior', color = 'C79C6E' },
    ['incite'] = { class = 'Warrior', color = 'C79C6E' },
    ['improved disarm'] = { class = 'Warrior', color = 'C79C6E' },
    ['puncture'] = { class = 'Warrior', color = 'C79C6E' },
    ['improved revenge'] = { class = 'Warrior', color = 'C79C6E' },
    ['shield mastery'] = { class = 'Warrior', color = 'C79C6E' },
    ['improved defensive stance'] = { class = 'Warrior', color = 'C79C6E' },
    ['safeguard'] = { class = 'Warrior', color = 'C79C6E' },
    ['one-handed weapon specialization'] = { class = 'Warrior', color = 'C79C6E' },
    ['improved disciplines'] = { class = 'Warrior', color = 'C79C6E' },
    ['gag order'] = { class = 'Warrior', color = 'C79C6E' },
    ['focused rage'] = { class = 'Warrior', color = 'C79C6E' },
    ['vitality'] = { class = 'Warrior', color = 'C79C6E' },
    ['devastate'] = { class = 'Warrior', color = 'C79C6E' },
    ['critical block'] = { class = 'Warrior', color = 'C79C6E' },
    ['sword and board'] = { class = 'Warrior', color = 'C79C6E' },
    ['damage shield'] = { class = 'Warrior', color = 'C79C6E' },
    ['warbringer'] = { class = 'Warrior', color = 'C79C6E' },
};

-- Detect ability or talent class for Ascension 3.3.5a using known databases
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

    local sName = name:lower():gsub("%s*%b()", ""):match("^%s*(.-)%s*$")
    if not sName or sName == "" then return "General", "D4AF37" end

    -- 1. Direct match in known abilities database
    if KNOWN_SPELL_CLASSES and KNOWN_SPELL_CLASSES[sName] then
        local entry = KNOWN_SPELL_CLASSES[sName]
        return entry.class, entry.color
    end

    -- 2. Direct match in known talents database
    if KNOWN_TALENT_CLASSES and KNOWN_TALENT_CLASSES[sName] then
        local entry = KNOWN_TALENT_CLASSES[sName]
        return entry.class, entry.color
    end

    -- 3. Substring/prefix search in known abilities database
    if KNOWN_SPELL_CLASSES then
        for kName, entry in pairs(KNOWN_SPELL_CLASSES) do
            if sName:find(kName, 1, true) or kName:find(sName, 1, true) then
                return entry.class, entry.color
            end
        end
    end

    -- 4. Substring/prefix search in known talents database
    if KNOWN_TALENT_CLASSES then
        for kName, entry in pairs(KNOWN_TALENT_CLASSES) do
            if sName:find(kName, 1, true) or kName:find(sName, 1, true) then
                return entry.class, entry.color
            end
        end
    end

    return "General", "D4AF37"
end

-- Requirement 2: Check if first item in returned pool is an ability
local function IsFirstItemAbility(pool)
    if not pool or #pool == 0 then return true end
    local firstID = pool[1]
    if not firstID then return true end
    local name = GetSpellInfo(firstID)
    if not name then return true end
    local sName = name:lower():gsub("%s*%b()", ""):match("^%s*(.-)%s*$")
    if sName and KNOWN_SPELL_CLASSES and KNOWN_SPELL_CLASSES[sName] then
        return true
    end
    -- If recognized in talents database, it is definitely a talent
    if sName and KNOWN_TALENT_CLASSES and KNOWN_TALENT_CLASSES[sName] then
        return false
    end
    return true
end

-- Get number of specializations available (accounts for 2 or more coming soon)
local function GetTotalSpecs()
    local num = 2
    if type(GetNumTalentGroups) == "function" then
        num = math.max(num, GetNumTalentGroups())
    end
    return num
end

-- Forward declaration of functions
local RefreshPoolList
local UpdateModeButtons
local UpdateChangesSection

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
MainFrame:Hide() -- Default window state closed on startup

-- Remember window open/closed state
MainFrame:SetScript("OnShow", function()
    if SpellViewerDB then
        SpellViewerDB.shown = true
    end
end)
MainFrame:SetScript("OnHide", function()
    if SpellViewerDB then
        SpellViewerDB.shown = false
    end
end)

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
StatusText:SetPoint("CENTER", MainFrame, "CENTER", 14, 10)
StatusText:SetWidth(300)
StatusText:SetJustifyH("CENTER")
StatusText:SetText("|cffff5555Make sure you re-rolled an ability|r")

------------------------------------------------------
-- 2b. Ability / Talent View Mode Toggle Buttons
-- Positioned to the left of the scrollable list
------------------------------------------------------
local AbilityModeBtn = CreateFrame("Button", "SpellViewerAbilityModeBtn", MainFrame)
AbilityModeBtn:SetSize(24, 24)
AbilityModeBtn:SetPoint("TOPLEFT", MainFrame, "TOPLEFT", 8, -76)
SetElvUIStyle(AbilityModeBtn, { 0.08, 0.08, 0.10, 1 }, { 0, 0, 0, 1 })

local abilityIcon = AbilityModeBtn:CreateTexture(nil, "ARTWORK")
abilityIcon:SetPoint("TOPLEFT", AbilityModeBtn, "TOPLEFT", 2, -2)
abilityIcon:SetPoint("BOTTOMRIGHT", AbilityModeBtn, "BOTTOMRIGHT", -2, 2)
abilityIcon:SetTexture("Interface\\Icons\\Spell_Holy_MagicalSentry")
abilityIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

local abilityActiveBar = AbilityModeBtn:CreateTexture(nil, "OVERLAY")
abilityActiveBar:SetTexture("Interface\\Buttons\\WHITE8X8")
abilityActiveBar:SetSize(2, 24)
abilityActiveBar:SetPoint("RIGHT", AbilityModeBtn, "RIGHT", 0, 0)
abilityActiveBar:SetVertexColor(0, 0.75, 0.98, 1)

local TalentModeBtn = CreateFrame("Button", "SpellViewerTalentModeBtn", MainFrame)
TalentModeBtn:SetSize(24, 24)
TalentModeBtn:SetPoint("TOPLEFT", AbilityModeBtn, "BOTTOMLEFT", 0, -6)
SetElvUIStyle(TalentModeBtn, { 0.08, 0.08, 0.10, 1 }, { 0, 0, 0, 1 })

local talentIcon = TalentModeBtn:CreateTexture(nil, "ARTWORK")
talentIcon:SetPoint("TOPLEFT", TalentModeBtn, "TOPLEFT", 2, -2)
talentIcon:SetPoint("BOTTOMRIGHT", TalentModeBtn, "BOTTOMRIGHT", -2, 2)
talentIcon:SetTexture("Interface\\Icons\\Ability_Marksmanship")
talentIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

local talentActiveBar = TalentModeBtn:CreateTexture(nil, "OVERLAY")
talentActiveBar:SetTexture("Interface\\Buttons\\WHITE8X8")
talentActiveBar:SetSize(2, 24)
talentActiveBar:SetPoint("RIGHT", TalentModeBtn, "RIGHT", 0, 0)
talentActiveBar:SetVertexColor(1, 0.82, 0, 1)

UpdateModeButtons = function()
    if currentViewMode == "abilities" then
        AbilityModeBtn:SetBackdropBorderColor(0, 0.75, 0.98, 1)
        abilityIcon:SetAlpha(1.0)
        abilityActiveBar:Show()

        TalentModeBtn:SetBackdropBorderColor(0.25, 0.25, 0.25, 1)
        talentIcon:SetAlpha(0.4)
        talentActiveBar:Hide()
    else
        AbilityModeBtn:SetBackdropBorderColor(0.25, 0.25, 0.25, 1)
        abilityIcon:SetAlpha(0.4)
        abilityActiveBar:Hide()

        TalentModeBtn:SetBackdropBorderColor(1, 0.82, 0, 1)
        talentIcon:SetAlpha(1.0)
        talentActiveBar:Show()
    end
end

AbilityModeBtn:SetScript("OnClick", function()
    currentViewMode = "abilities"
    SpellViewerDB.viewMode = "abilities"
    UpdateModeButtons()
    RefreshPoolList()
end)

AbilityModeBtn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:AddLine("Abilities Pool", 1, 1, 1)
    GameTooltip:AddLine("Switch to viewing available Wildcard Abilities", 0.7, 0.7, 0.7)
    GameTooltip:Show()
end)
AbilityModeBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

TalentModeBtn:SetScript("OnClick", function()
    currentViewMode = "talents"
    SpellViewerDB.viewMode = "talents"
    UpdateModeButtons()
    RefreshPoolList()
end)

TalentModeBtn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:AddLine("Talents Pool", 1, 0.82, 0)
    GameTooltip:AddLine("Switch to viewing available Wildcard Talents", 0.7, 0.7, 0.7)
    GameTooltip:Show()
end)
TalentModeBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

------------------------------------------------------
-- 3. Ability & Talent List Scroll Frame & Rows (ElvUI Styled)
------------------------------------------------------
local ROW_HEIGHT = 36
local NUM_ROWS = 10
local rows = {}

local ScrollFrame = CreateFrame("ScrollFrame", "SpellViewerScrollFrame", MainFrame, "FauxScrollFrameTemplate")
ScrollFrame:SetPoint("TOPLEFT", 36, -74)
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
                local label = currentViewMode == "talents" and " talents" or " abilities"
                row.classText:SetText("|cff888888" .. item.count .. label .. countSuffix .. "|r")
            else
                -- Item Row (ElvUI style)
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
    row:SetPoint("TOPLEFT", MainFrame, "TOPLEFT", 36, -74 - ((i - 1) * ROW_HEIGHT))
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

    -- Item Name
    local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    nameText:SetPoint("LEFT", iconBorder, "RIGHT", 8, 0)
    nameText:SetJustifyH("LEFT")
    nameText:SetWidth(156)
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
    UpdateModeButtons()

    local activeSpec = 1
    if type(GetActiveTalentGroup) == "function" then
        activeSpec = GetActiveTalentGroup() or 1
    end

    local modeLabel = currentViewMode == "talents" and "talent" or "ability"
    if viewedSpec == activeSpec then
        PoolInfoText:SetText("Viewing " .. modeLabel .. " pool for |cff00c0faSpec " .. viewedSpec .. " (Active)|r")
    else
        PoolInfoText:SetText("Viewing " .. modeLabel .. " pool for |cffffd100Spec " .. viewedSpec .. " (Saved)|r | Rolls save to Spec " .. activeSpec)
    end

    -- Requirement 3 & 5: Load pool according to active view mode and viewedSpec
    local rawPool = nil
    if currentViewMode == "talents" then
        if viewedSpec == activeSpec and GFTALENTPOOL and #GFTALENTPOOL > 0 then
            rawPool = GFTALENTPOOL
        elseif SpellViewerDB.talentPools and SpellViewerDB.talentPools[viewedSpec] and #SpellViewerDB.talentPools[viewedSpec] > 0 then
            rawPool = SpellViewerDB.talentPools[viewedSpec]
        end
    else
        if viewedSpec == activeSpec and GFPOOL and #GFPOOL > 0 then
            rawPool = GFPOOL
        elseif SpellViewerDB.pools and SpellViewerDB.pools[viewedSpec] and #SpellViewerDB.pools[viewedSpec] > 0 then
            rawPool = SpellViewerDB.pools[viewedSpec]
        end
    end

    if not rawPool or #rawPool == 0 then
        StatusText:SetText(currentViewMode == "talents" and "|cffff5555Make sure you re-rolled a talent|r" or "|cffff5555Make sure you re-rolled an ability|r")
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

    -- 3. Sort items within each class alphabetically ascending by name (A-Z)
    for _, cName in ipairs(classOrder) do
        local grp = grouped[cName]
        table.sort(grp.spells, function(a, b)
            return a.name:lower() < b.name:lower()
        end)

        -- 4. Flatten into displayedList: Header followed by sorted items (if not collapsed)
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
        StatusText:SetText(currentViewMode == "talents" and "|cffff5555Make sure you re-rolled a talent|r" or "|cffff5555Make sure you re-rolled an ability|r")
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
    local changesStore = (currentViewMode == "talents" and SpellViewerDB and SpellViewerDB.recentChangesTalents) or (SpellViewerDB and SpellViewerDB.recentChanges)
    local changes = changesStore and changesStore[viewedSpec]
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
-- 6. Minimap Toggle Button (Traditional WoW Round Look)
------------------------------------------------------
local MinimapBtn = CreateFrame("Button", "SpellViewerMinimapButton", Minimap)
MinimapBtn:SetSize(33, 33)
MinimapBtn:SetFrameStrata("MEDIUM")
MinimapBtn:SetToplevel(true)
MinimapBtn:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

-- Inner circular spell icon
local btnIcon = MinimapBtn:CreateTexture(nil, "BACKGROUND")
btnIcon:SetSize(21, 21)
btnIcon:SetPoint("CENTER", MinimapBtn, "CENTER", 0, 0)
btnIcon:SetTexture("Interface\\Icons\\INV_Misc_Book_09")
btnIcon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

-- Classic WoW Circular Golden Border Frame
local btnBorder = MinimapBtn:CreateTexture(nil, "OVERLAY")
btnBorder:SetSize(54, 54)
btnBorder:SetPoint("TOPLEFT", MinimapBtn, "TOPLEFT", 0, 0)
btnBorder:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

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
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:AddLine("|cffffd100[SpellViewer]|r")
    GameTooltip:AddLine("Left-Click: |cffffffffToggle Wildcard Window|r", 0.8, 0.8, 0.8)
    GameTooltip:AddLine("Right-Click & Drag: |cffffffffMove Minimap Button|r", 0.8, 0.8, 0.8)
    GameTooltip:Show()
end)

MinimapBtn:SetScript("OnLeave", function(self)
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
        SpellViewerDB.talentPools = SpellViewerDB.talentPools or {}
        
        if SpellViewerDB.viewMode then
            currentViewMode = SpellViewerDB.viewMode
        end
        UpdateModeButtons()

        UpdateMinimapButtonPosition(SpellViewerDB.minimapPos or 220)
        
        -- Automatic recording initialization
        if type(FlushClasslessWildcardSpellRollResults) == "function" then
            FlushClasslessWildcardSpellRollResults()
        end

        GF = GF or CreateFrame("Frame")
        GF:RegisterEvent("CUSTOM_CLASSLESS_WILDCARD_SPELL_ROLLED")

        -- Buffers to save pools before reroll
        GF1 = GF1 or {}
        GFTALENT1 = GFTALENT1 or {}

        -- Requirement 2 & 6: When pool changes, detect if it's ability or talent, and save for ACTIVE spec
        GF:SetScript("OnEvent", function(subSelf, rollEvent, id)
            GFLAST = id
            local activeSpec = 1
            if type(GetActiveTalentGroup) == "function" then
                activeSpec = GetActiveTalentGroup() or 1
            end

            -- 1. Fetch new candidates
            local candidates = nil
            if type(GetClasslessWildcardRollCandidates) == "function" then
                candidates = GetClasslessWildcardRollCandidates(id)
            end

            if not candidates or #candidates == 0 then
                return
            end

            -- Check if first item is an ability or talent
            local isAbility = IsFirstItemAbility(candidates)

            if isAbility then
                -- Ability Pool handling
                wipe(GF1)
                local prevPool = (GFPOOL and #GFPOOL > 0 and GFPOOL) or (SpellViewerDB.pools and SpellViewerDB.pools[activeSpec])
                if prevPool then
                    for i, v in ipairs(prevPool) do GF1[i] = v end
                end

                GFPOOL = candidates

                -- Collect gained and lost
                local gained = {}
                local lost = {}
                if #GFPOOL > 0 and #GF1 > 0 then
                    for _, v in ipairs(GFPOOL) do
                        local f = false
                        for _, x in ipairs(GF1) do if x == v then f = true; break end end
                        if not f then table.insert(gained, v) end
                    end
                    for _, v in ipairs(GF1) do
                        local f = false
                        for _, x in ipairs(GFPOOL) do if x == v then f = true; break end end
                        if not f then table.insert(lost, v) end
                    end
                end

                SpellViewerDB.pools = SpellViewerDB.pools or {}
                SpellViewerDB.pools[activeSpec] = GFPOOL

                SpellViewerDB.recentChanges = SpellViewerDB.recentChanges or {}
                local sName = GetSpellInfo(id) or "Unknown"
                SpellViewerDB.recentChanges[activeSpec] = {
                    rolledName = sName,
                    rolledId = id,
                    gained = gained,
                    lost = lost,
                }

                if currentViewMode == "abilities" and viewedSpec == activeSpec and MainFrame:IsShown() then
                    RefreshPoolList()
                end
            else
                -- Talent Pool handling
                wipe(GFTALENT1)
                local prevTalents = (GFTALENTPOOL and #GFTALENTPOOL > 0 and GFTALENTPOOL) or (SpellViewerDB.talentPools and SpellViewerDB.talentPools[activeSpec])
                if prevTalents then
                    for i, v in ipairs(prevTalents) do GFTALENT1[i] = v end
                end

                GFTALENTPOOL = candidates

                -- Collect gained and lost
                local gained = {}
                local lost = {}
                if #GFTALENTPOOL > 0 and #GFTALENT1 > 0 then
                    for _, v in ipairs(GFTALENTPOOL) do
                        local f = false
                        for _, x in ipairs(GFTALENT1) do if x == v then f = true; break end end
                        if not f then table.insert(gained, v) end
                    end
                    for _, v in ipairs(GFTALENT1) do
                        local f = false
                        for _, x in ipairs(GFTALENTPOOL) do if x == v then f = true; break end end
                        if not f then table.insert(lost, v) end
                    end
                end

                SpellViewerDB.talentPools = SpellViewerDB.talentPools or {}
                SpellViewerDB.talentPools[activeSpec] = GFTALENTPOOL

                SpellViewerDB.recentChangesTalents = SpellViewerDB.recentChangesTalents or {}
                local sName = GetSpellInfo(id) or "Unknown"
                SpellViewerDB.recentChangesTalents[activeSpec] = {
                    rolledName = sName,
                    rolledId = id,
                    gained = gained,
                    lost = lost,
                }

                if currentViewMode == "talents" and viewedSpec == activeSpec and MainFrame:IsShown() then
                    RefreshPoolList()
                end
            end
        end)

        local activeSpec = (type(GetActiveTalentGroup) == "function" and GetActiveTalentGroup()) or 1
        viewedSpec = activeSpec
        UIDropDownMenu_SetSelectedValue(SpecDropdown, viewedSpec)
        UIDropDownMenu_SetText(SpecDropdown, "View: Spec " .. viewedSpec)
        UpdateActiveSpecHeader()

        -- Requirements 1 & 2: Default window state is closed; remember state across reloads
        if SpellViewerDB.shown == nil then
            SpellViewerDB.shown = false
        end

        if SpellViewerDB.shown then
            MainFrame:Show()
            RefreshPoolList()
        else
            MainFrame:Hide()
        end

    elseif event == "ACTIVE_TALENT_GROUP_CHANGED" then
        -- Requirement 3: Update player active specialization on talent change
        UpdateActiveSpecHeader()
        local activeSpec = (type(GetActiveTalentGroup) == "function" and GetActiveTalentGroup()) or 1
        if MainFrame:IsShown() then
            RefreshPoolList()
        end

    elseif event == "PLAYER_LOGOUT" then
        -- Requirements 1 & 4: Save open/closed window state, viewMode, and pools on reload/logout
        if SpellViewerDB then
            SpellViewerDB.shown = (MainFrame:IsShown() == 1 or MainFrame:IsShown() == true)
            SpellViewerDB.viewMode = currentViewMode
        end
        local activeSpec = (type(GetActiveTalentGroup) == "function" and GetActiveTalentGroup()) or 1
        if GFPOOL and #GFPOOL > 0 then
            SpellViewerDB.pools = SpellViewerDB.pools or {}
            SpellViewerDB.pools[activeSpec] = GFPOOL
        end
        if GFTALENTPOOL and #GFTALENTPOOL > 0 then
            SpellViewerDB.talentPools = SpellViewerDB.talentPools or {}
            SpellViewerDB.talentPools[activeSpec] = GFTALENTPOOL
        end
    end
end)
