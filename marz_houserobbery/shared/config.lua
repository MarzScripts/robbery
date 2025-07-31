lib.locale()

Config = {}

-- ════════════════════════════════════════════════════════════════
--                          DEBUG SETTINGS
-- ════════════════════════════════════════════════════════════════

Config.Debug = false

-- ════════════════════════════════════════════════════════════════
--                        FRAMEWORK SETTINGS
-- ════════════════════════════════════════════════════════════════

Config.Framework = "qbcore"              -- qbcore, ESX, standalone
Config.NewESX = false                      -- if you use esx 1.1 set this to false

-- ════════════════════════════════════════════════════════════════
--                       INTERACTION SETTINGS
-- ════════════════════════════════════════════════════════════════

Config.HouseType = "AllHouses"            -- AllHouses only 
Config.InteractionType = "target"         -- target, textui, 3dtext
Config.Target = "ox_target"               -- qb-target, qtarget, ox_target

-- ════════════════════════════════════════════════════════════════
--                         UI SETTINGS
-- ════════════════════════════════════════════════════════════════

Config.NotificationType = "ox_lib"        -- ESX, ox_lib, qbcore
Config.Progress = "ox_lib"                -- progressBars, ox_lib, qbcore
Config.TextUI = "ox_lib"                  -- esx, ox_lib, luke
Config.Context = "ox_lib"                 -- ox_lib, qbcore
Config.Input = "ox_lib"                   -- ox_lib, qb-input

-- ════════════════════════════════════════════════════════════════
--                        MINIGAME SETTINGS
-- ════════════════════════════════════════════════════════════════

Config.Minigames = {
    -- Door Lockpicking Configuration
    DoorLockpick = {
        difficulty = {'easy', 'easy', 'medium'},  -- Skill check difficulty pattern
        inputs = {'w', 'a', 's', 'd'},           -- Keys to use for skill check
    },
    
    -- Safe Cracking Configuration
    SafeCracking = {
        difficulty = {'easy', 'medium', 'medium', 'hard', 'hard'},  -- More difficult for safes
        inputs = {'w', 'a', 's', 'd'},                              -- Keys to use
    },
    
    -- Hacking Configuration (for future use)
    Hacking = {
        difficulty = {'medium', 'medium', 'hard', 'hard'},
        inputs = {'w', 'a', 's', 'd'},
    }
}

-- ════════════════════════════════════════════════════════════════
--                        POLICE SETTINGS
-- ════════════════════════════════════════════════════════════════

Config.PoliceJobs = { 'police', 'sheriff' }

Config.Dispatch = {
    enabled = true,
    script = "cd_dispatch"                -- cd_dispatch, linden_outlawalert, ps-disptach, core-dispatch
}

-- ════════════════════════════════════════════════════════════════
--                        SECURITY SETTINGS
-- ════════════════════════════════════════════════════════════════

Config.Logs = {
    enabled = true,
    type = "webhook"                      -- Change webhook in server/sv_utils.lua
}

Config.DropPlayer = false                -- Drop (Kick) Player if tries to cheat!
Config.DirtyMoney = false

-- ════════════════════════════════════════════════════════════════
--                         HOUSE SETTINGS
-- ════════════════════════════════════════════════════════════════

Config.ResetHousesAfterTime = true       -- Reset houses after time
Config.ResetTime = 120                   -- Reset time in minutes

-- ════════════════════════════════════════════════════════════════
--                        ROBBERY SETTINGS
-- ════════════════════════════════════════════════════════════════

-- Lockpick Requirements
Config.Lockpick = {
    item = "lockpick",
    remove = true                         -- Remove lockpick on use
}

-- Duffel Bag System
Config.RequireDuffelBag = true           -- Require duffel bag to rob houses
Config.DuffelBagItem = "loot_bag"        -- Item name for duffel bag
Config.MaxDuffelCapacity = 50            -- Max items that can fit in duffel bag

-- Night Robbery Restrictions
Config.NightRob = {
    enabled = false,                      -- Only allow robbery at night
    time = {
        from = 23,                        -- Start hour (24h format)
        to = 6                           -- End hour (24h format)
    }
}

-- ════════════════════════════════════════════════════════════════
--                        STEALTH SYSTEM
-- ════════════════════════════════════════════════════════════════

Config.StealthSystem = {
    enabled = true,                       -- Enable stealth mechanics
    
    -- Noise Bar Settings
    noiseBar = {
        maxNoise = 100,                   -- Maximum noise level before NPC wakes up
        wakeupThreshold = 85,             -- Noise level that wakes up NPC (lowered for easier testing)
        decayRate = 0.8,                  -- How fast noise decreases per frame (when quiet)
        position = { x = 0.92, y = 0.3 }, -- Screen position of noise bar
        size = { width = 0.015, height = 0.25 }, -- Size of noise bar
    },
    
    -- Footstep Noise
    footsteps = {
        walkingNoise = 1.2,               -- Noise increase per frame while walking
        runningNoise = 3.5,               -- Noise increase per frame while running
        crouchingNoise = 0.1,             -- Noise increase per frame while crouching
        sprintingNoise = 6.0,             -- Noise increase per frame while sprinting
    },
    
    -- Voice Detection (requires voice chat)
    voice = {
        enabled = true,                   -- Enable voice detection
        whisperThreshold = 20,            -- Voice level considered whispering (no noise)
        normalThreshold = 50,             -- Voice level considered normal talking
        shoutThreshold = 80,              -- Voice level considered shouting
        whisperNoise = 0,                 -- Noise increase for whispering
        normalNoise = 2.0,                -- Noise increase for normal talking
        shoutNoise = 7.0,                 -- Noise increase for shouting
    },
    
    -- NPC Behavior
    npc = {
        wakeupTime = 3000,                -- Time (ms) for NPC to fully wake up and attack
        searchTime = 30000,               -- Time (ms) NPC searches before going back to sleep
        alertRadius = 15.0,               -- Distance NPC can detect player when awakened
    }
}

-- ════════════════════════════════════════════════════════════════
--                        SHELL DEPENDENCIES
-- ════════════════════════════════════════════════════════════════

-- Add these shells as dependencies in your fxmanifest.lua:
-- dependencies {
--     'K4MB1-StarterShells',
--     'envi-shells',
--     'lynx_shells'
-- }

-- ════════════════════════════════════════════════════════════════
--                    HOUSE LOCATIONS & CONFIGURATIONS
-- ════════════════════════════════════════════════════════════════

Config.HousesToRob = {
    -- ══════════════════════════════════════════════════════════════
    --                    LOW TIER HOUSES (Using Lynx T1)
    -- ══════════════════════════════════════════════════════════════
    ["Mirror Park House"] = {
        Coords = vec4(1301.08, -574.48, 71.73, 163.11),
        Shell = "t1_furn_shell", -- Lynx Tier 1 Furnished
        Tier = "Low Tier",
        ReportChanceWhenEntering = 75,
        NeedPoliceCount = 0,
        
        InsidePositions = {
            ["Exit"] = { 
                coords = vector4(-43.76, -621.26, -29.20, 163.11), -- Lynx T1 furnished exit
            },
            ["Living Room"] = {
                ChanceToFindNothing = 30,
                coords = vector3(-46.23, -614.85, -29.20),        
                Items = {
                    { Item = "10kgoldchain", Chance = 60.9, MinCount = 1, MaxCount = 1 },
                    { Item = "laptop", Chance = 50.5, MinCount = 1, MaxCount = 1 },
                    { Item = "panties", Chance = 50.5, MinCount = 1, MaxCount = 1 },
                    { Item = "bracelet", Chance = 50.5, MinCount = 1, MaxCount = 1 },
                    { Item = "sandwich", Chance = 55.5, MinCount = 1, MaxCount = 1 },
                }
            },
            ["Kitchen"] = {
                ChanceToFindNothing = 40,
                coords = vector3(-48.52, -617.23, -29.20),        
                Items = {
                    { Item = "WEAPON_KITCHENKNIFE", Chance = 2.0, MinCount = 1, MaxCount = 1 },
                    { Item = "money", Chance = 25.5, MinCount = 500, MaxCount = 2000 },
                    { Item = "chickensandwich", Chance = 40.5, MinCount = 1, MaxCount = 1 },
                }
            },
            ["Bedroom"] = {
                ChanceToFindNothing = 25,
                coords = vector3(-41.28, -617.89, -29.20),
                Items = {
                    { Item = "rolex", Chance = 30.9, MinCount = 1, MaxCount = 1 },
                    { Item = "money", Chance = 35.5, MinCount = 200, MaxCount = 1500 },
                }
            },
        },
        
        Safes = {
            ["safe"] = { 
                model = `prop_ld_int_safe_01`, 
                Label = "Safe", 
                NeedItem = true, 
                Item = "lockpick", 
                Coords = vec4(-39.68, -620.35, -29.20, 250.0), 
                ChanceToFindNothing = 10,
                Items = {
                    { Item = "weed", Chance = 50.0, MinCount = 20, MaxCount = 50},
                    { Item = "diamond_ring", Chance = 50.5, MinCount = 2, MaxCount = 6 },
                    { Item = "weapon_pistol", Chance = 1.0, MinCount = 1, MaxCount = 1 },
                    { Item = "black_money", Chance = 40.5, MinCount = 1000, MaxCount = 5000 },
                },
            }
        },
        
        Ped = {
            chance = 100,
            model = `s_m_y_dealer_01`, 
            coords = vec4(-43.45, -613.84, -29.20, 340.0),
            sleeping = true,
            sleepScenario = "WORLD_HUMAN_BUM_SLUMPED",
            weapon = { 
                enabled = true, 
                chance = 50,
                weapon = `WEAPON_COMBATPISTOL`, 
                DisableWeaponDrop = true 
            }
        },
        
        StaticProps = {
            TV = { model = `prop_tv_03`, Label = "TV", Item = "television", Count = 1 },
            BOOMBOX = { model = `prop_boombox_01`, Label = "Boombox", Item = "boombox", Count = 1 },
        },
        
        CreateProps = {},
    },

    ["El Burro Heights 1"] = {
        Coords = vec4(1391.078, -1508.35, 58.43, 180.93),
        Shell = "envi_shell_01_furnished", -- Envi Shell 01 Furnished
        Tier = "Low Tier",
        ReportChanceWhenEntering = 75,
        NeedPoliceCount = 0,
        
        InsidePositions = {
            ["Exit"] = { 
                coords = vector4(4.69, -6.74, 1.03, 0.0), -- Envi typical exit location
            },
            ["Living Room"] = {
                ChanceToFindNothing = 30,
                coords = vector3(0.82, -2.50, 1.03),        
                Items = {
                    { Item = "10kgoldchain", Chance = 60.9, MinCount = 1, MaxCount = 1 },
                    { Item = "laptop", Chance = 50.5, MinCount = 1, MaxCount = 1 },
                    { Item = "vvs_ap", Chance = 40.5, MinCount = 1, MaxCount = 1 },
                    { Item = "panties", Chance = 50.5, MinCount = 1, MaxCount = 1 },
                    { Item = "bracelet", Chance = 50.5, MinCount = 1, MaxCount = 1 },
                }
            },
            ["Kitchen"] = {
                ChanceToFindNothing = 40,
                coords = vector3(6.09, 0.31, 1.03),        
                Items = {
                    { Item = "WEAPON_KITCHENKNIFE", Chance = 2.0, MinCount = 1, MaxCount = 1 },
                    { Item = "money", Chance = 25.5, MinCount = 500, MaxCount = 2000 },
                    { Item = "chickensandwich", Chance = 40.5, MinCount = 1, MaxCount = 1 },
                }
            },
            ["Bedroom"] = {
                ChanceToFindNothing = 25,
                coords = vector3(-5.66, -0.61, 1.03),
                Items = {
                    { Item = "panties", Chance = 50.5, MinCount = 1, MaxCount = 2 },
                    { Item = "money", Chance = 35.5, MinCount = 200, MaxCount = 1500 },
                }
            },
        },
        
        Safes = {
            ["safe"] = { 
                model = `prop_ld_int_safe_01`, 
                Label = "Safe", 
                NeedItem = true, 
                Item = "lockpick", 
                Coords = vec4(-3.59, 2.30, 1.03, 90.0), 
                ChanceToFindNothing = 30,
                Items = {
                    { Item = "weed", Chance = 50.0, MinCount = 20, MaxCount = 50},
                    { Item = "diamond_ring", Chance = 50.5, MinCount = 2, MaxCount = 6 },
                    { Item = "lockpick", Chance = 1.0, MinCount = 1, MaxCount = 1 },
                    { Item = "black_money", Chance = 35.0, MinCount = 5000, MaxCount = 15000 },
                },
            }
        },
        
        Ped = {
            chance = 70,
            model = `s_m_y_dealer_01`, 
            coords = vec4(-0.75, 5.18, 1.03, 180.0),
            sleeping = true,
            sleepScenario = "WORLD_HUMAN_BUM_SLUMPED",
            weapon = { 
                enabled = true, 
                chance = 50,
                weapon = `WEAPON_COMBATPISTOL`, 
                DisableWeaponDrop = true 
            }
        },
        
        StaticProps = {
            TV = { model = `prop_tv_03`, Label = "TV", Item = "television", Count = 1 },
            BOOMBOX = { model = `prop_boombox_01`, Label = "Boombox", Item = "speaker", Count = 1 },
        },
        
        CreateProps = {},
    },

    -- ══════════════════════════════════════════════════════════════
    --                    MID TIER HOUSES (Using Lynx T2)
    -- ══════════════════════════════════════════════════════════════
    ["Vespucci Beach House"] = {
        Coords = vec4(-957.30, -1566.75, 5.02, 180.93),
        Shell = "t2_furn_shell", -- Lynx Tier 2 Furnished
        Tier = "Mid Tier",
        ReportChanceWhenEntering = 80,
        NeedPoliceCount = 0,
        
        InsidePositions = {
            ["Exit"] = { 
                coords = vector4(-590.68, -713.26, -42.45, 180.93), -- Lynx T2 furnished exit
            },
            ["Living Room"] = {
                ChanceToFindNothing = 20,
                coords = vector3(-594.75, -707.88, -42.45),
                Items = {
                    { Item = "laptop", Chance = 70.9, MinCount = 1, MaxCount = 1 },
                    { Item = "tablet", Chance = 60.5, MinCount = 1, MaxCount = 1 },
                    { Item = "money", Chance = 60.5, MinCount = 2000, MaxCount = 8000 },
                    { Item = "rolex", Chance = 50.5, MinCount = 1, MaxCount = 3 },
                }
            },
            ["Kitchen"] = {
                ChanceToFindNothing = 25,
                coords = vector3(-586.42, -708.76, -42.45),
                Items = {
                    { Item = "weapon_knife", Chance = 35.9, MinCount = 1, MaxCount = 1 },
                    { Item = "money", Chance = 40.5, MinCount = 1000, MaxCount = 4000 },
                    { Item = "phone", Chance = 50.5, MinCount = 1, MaxCount = 1 },
                }
            },
            ["Bedroom"] = {
                ChanceToFindNothing = 20,
                coords = vector3(-593.97, -716.03, -42.45),
                Items = {
                    { Item = "rolex", Chance = 55.9, MinCount = 1, MaxCount = 2 },
                    { Item = "perfume", Chance = 45.5, MinCount = 1, MaxCount = 2 },
                    { Item = "money", Chance = 35.5, MinCount = 500, MaxCount = 3000 },
                }
            },
            ["Bathroom"] = {
                ChanceToFindNothing = 35,
                coords = vector3(-588.24, -716.24, -42.45),
                Items = {
                    { Item = "toothpaste", Chance = 40.9, MinCount = 1, MaxCount = 1 },
                    { Item = "shampoo", Chance = 40.9, MinCount = 1, MaxCount = 1 },
                    { Item = "soap", Chance = 50.9, MinCount = 1, MaxCount = 1 },
                }
            },
        },
        
        Safes = {
            ["safe"] = { 
                model = `prop_ld_int_safe_01`, 
                Label = "Safe", 
                NeedItem = true, 
                Item = "lockpick", 
                Coords = vec4(-596.07, -712.83, -42.45, 270.0), 
                ChanceToFindNothing = 20,
                Items = {
                    { Item = "diamond_ring", Chance = 60.5, MinCount = 1, MaxCount = 2 },
                    { Item = "gold_necklace", Chance = 70.5, MinCount = 1, MaxCount = 3 },
                    { Item = "rolex", Chance = 80.5, MinCount = 1, MaxCount = 2 },
                    { Item = "money", Chance = 50.5, MinCount = 5000, MaxCount = 25000 },
                },
            }
        },
        
        Ped = { 
            chance = 60, 
            model = `s_m_y_businessman_01`, 
            coords = vec4(-592.58, -710.10, -42.45, 270.0),
            sleeping = true,
            sleepScenario = "WORLD_HUMAN_BUM_SLUMPED",
            weapon = { 
                enabled = true, 
                chance = 40, 
                weapon = `WEAPON_PISTOL`, 
                DisableWeaponDrop = true 
            } 
        },
        
        StaticProps = {
            TV = { model = `prop_tv_06`, Label = "Smart TV", Item = "television", Count = 1 },
            STEREO = { model = `prop_hifi_01`, Label = "Stereo System", Item = "electronics", Count = 1 },
        },
        
        CreateProps = {},
    },

    ["Sandy Shores House"] = {
        Coords = vec4(1842.28, 3778.73, 33.59, 120.0),
        Shell = "envi_shell_02_furnished", -- Envi Shell 02 Furnished
        Tier = "Mid Tier",
        ReportChanceWhenEntering = 70,
        NeedPoliceCount = 0,
        
        InsidePositions = {
            ["Exit"] = { 
                coords = vector4(6.25, -8.73, 1.03, 0.0), -- Envi typical exit
            },
            ["Living Room"] = {
                ChanceToFindNothing = 25,
                coords = vector3(1.53, -3.75, 1.03),
                Items = {
                    { Item = "laptop", Chance = 60.9, MinCount = 1, MaxCount = 1 },
                    { Item = "money", Chance = 50.5, MinCount = 1500, MaxCount = 6000 },
                    { Item = "gold_watch", Chance = 40.5, MinCount = 1, MaxCount = 2 },
                }
            },
            ["Kitchen"] = {
                ChanceToFindNothing = 30,
                coords = vector3(8.42, 1.23, 1.03),
                Items = {
                    { Item = "weapon_knife", Chance = 25.9, MinCount = 1, MaxCount = 1 },
                    { Item = "money", Chance = 35.5, MinCount = 800, MaxCount = 3000 },
                }
            },
            ["Bedroom"] = {
                ChanceToFindNothing = 25,
                coords = vector3(-6.84, -1.28, 1.03),
                Items = {
                    { Item = "gold_bracelet", Chance = 45.9, MinCount = 1, MaxCount = 1 },
                    { Item = "money", Chance = 40.5, MinCount = 1000, MaxCount = 4000 },
                }
            },
            ["Office"] = {
                ChanceToFindNothing = 20,
                coords = vector3(-3.65, 5.73, 1.03),
                Items = {
                    { Item = "laptop", Chance = 70.9, MinCount = 1, MaxCount = 1 },
                    { Item = "notepad", Chance = 80.5, MinCount = 1, MaxCount = 3 },
                }
            },
        },
        
        Safes = {
            ["safe"] = { 
                model = `prop_ld_int_safe_01`, 
                Label = "Safe", 
                NeedItem = true, 
                Item = "lockpick", 
                Coords = vec4(-5.23, 3.65, 1.03, 180.0), 
                ChanceToFindNothing = 25,
                Items = {
                    { Item = "gold_necklace", Chance = 60.5, MinCount = 1, MaxCount = 2 },
                    { Item = "money", Chance = 70.5, MinCount = 3000, MaxCount = 20000 },
                },
            }
        },
        
        Ped = { 
            chance = 50, 
            model = `a_m_m_farmer_01`, 
            coords = vec4(-1.75, 6.43, 1.03, 180.0),
            sleeping = true,
            sleepScenario = "WORLD_HUMAN_BUM_SLUMPED",
            weapon = { 
                enabled = true, 
                chance = 60, 
                weapon = `WEAPON_PUMPSHOTGUN`, 
                DisableWeaponDrop = true 
            } 
        },
        
        StaticProps = {
            TV = { model = `prop_tv_03`, Label = "TV", Item = "television", Count = 1 },
        },
        
        CreateProps = {},
    },

    -- ══════════════════════════════════════════════════════════════
    --                    HIGH TIER HOUSES (Using Lynx T3)
    -- ══════════════════════════════════════════════════════════════
    ["Vinewood Hills Mansion"] = {
        Coords = vec4(216.44, 620.49, 187.75, 181.04),
        Shell = "t3_furn_shell", -- Lynx Tier 3 Furnished
        Tier = "High Tier",
        ReportChanceWhenEntering = 100,
        NeedPoliceCount = 2,
        
        InsidePositions = {
            ["Exit"] = { 
                coords = vector4(-66.29, -817.39, -20.31, 181.04), -- Lynx T3 furnished exit
            },
            ["Living Room"] = {
                ChanceToFindNothing = 15,
                coords = vector3(-70.15, -810.89, -20.31),        
                Items = {
                    { Item = "laptop", Chance = 80.9, MinCount = 1, MaxCount = 2 },
                    { Item = "tablet", Chance = 70.5, MinCount = 1, MaxCount = 1 },
                    { Item = "money", Chance = 60.5, MinCount = 5000, MaxCount = 15000 },
                    { Item = "rolex", Chance = 50.5, MinCount = 1, MaxCount = 2 },
                    { Item = "art_piece", Chance = 30.9, MinCount = 1, MaxCount = 1 },
                }
            },
            ["Kitchen"] = { 
                ChanceToFindNothing = 20,
                coords = vector3(-62.34, -810.93, -20.31),        
                Items = {
                    { Item = "wine", Chance = 70.9, MinCount = 1, MaxCount = 3 },
                    { Item = "money", Chance = 50.0, MinCount = 2000, MaxCount = 8000 },
                },
            },
            ["Master Bedroom"] = {
                ChanceToFindNothing = 10,
                coords = vector3(-69.85, -822.48, -20.31),        
                Items = {
                    { Item = "rolex", Chance = 60.9, MinCount = 1, MaxCount = 2 },
                    { Item = "diamond_ring", Chance = 50.9, MinCount = 1, MaxCount = 3 },
                    { Item = "gold_necklace", Chance = 60.9, MinCount = 1, MaxCount = 2 },
                    { Item = "money", Chance = 70.5, MinCount = 8000, MaxCount = 25000 },
                },
            },
            ["Office"] = {
                ChanceToFindNothing = 15,
                coords = vector3(-60.75, -822.75, -20.31),        
                Items = {
                    { Item = "laptop", Chance = 90.9, MinCount = 1, MaxCount = 1 },
                    { Item = "notepad", Chance = 80.9, MinCount = 1, MaxCount = 3 },
                    { Item = "bonds", Chance = 40.9, MinCount = 1, MaxCount = 5 },
                },
            },
            ["Guest Bedroom"] = {
                ChanceToFindNothing = 20,
                coords = vector3(-72.43, -816.24, -20.31),        
                Items = {
                    { Item = "gold_watch", Chance = 50.9, MinCount = 1, MaxCount = 1 },
                    { Item = "perfume", Chance = 60.9, MinCount = 1, MaxCount = 2 },
                    { Item = "money", Chance = 40.9, MinCount = 3000, MaxCount = 10000 },
                },
            },
        },
        
        CreateProps = {
            ["statue"] = { 
                model = `m24_1_prop_m41_statue_01a`, 
                Label = "Ancient Statue", 
                Item = "statue", 
                Coords = vec4(-66.85, -813.45, -20.31, 0.0), 
                NeedTrunk = true,
                propPlacement = { 
                    pos = vec3(0.17, 0.0, 0.05), 
                    rot = vec3(16.0, 0.0, 0.0), 
                    bone = 18905
                }, 
                CarryAnim = { 
                    dict = "anim@heists@box_carry@", 
                    anim = "idle" 
                },
                Weight = "heavy",
                NoiseLevel = 10.0,
                MovementSpeed = 0.5,
                RequiresVehicle = true,
                Value = 5000,
                Description = "A priceless ancient artifact that requires careful transport"
            },
        },
        
        Safes = {
            ["master_safe"] = { 
                model = `prop_ld_int_safe_01`, 
                Label = "Master Safe", 
                NeedItem = true, 
                Item = "lockpick", 
                Coords = vec4(-73.12, -820.35, -20.31, 270.0),
                ChanceToFindNothing = 5,
                Items = {
                    { Item = "gold_watch", Chance = 70.9, MinCount = 2, MaxCount = 3 },
                    { Item = "gold_bracelet", Chance = 70.9, MinCount = 2, MaxCount = 4 },
                    { Item = "diamond_ring", Chance = 60.9, MinCount = 2, MaxCount = 4 },
                    { Item = "art_piece", Chance = 40.9, MinCount = 1, MaxCount = 2 },
                    { Item = "money", Chance = 80.5, MinCount = 15000, MaxCount = 50000 },
                },
            },
            ["office_safe"] = { 
                model = `prop_ld_int_safe_01`, 
                Label = "Office Safe", 
                NeedItem = true, 
                Item = "lockpick", 
                Coords = vec4(-58.45, -824.12, -20.31, 90.0),
                ChanceToFindNothing = 10,
                Items = {
                    { Item = "bonds", Chance = 60.9, MinCount = 5, MaxCount = 10 },
                    { Item = "money", Chance = 70.5, MinCount = 10000, MaxCount = 35000 },
                },
            }
        },
        
        Ped = {
            chance = 100, 
            model = `a_m_m_bevhills_02`, 
            coords = vec4(-68.54, -819.73, -20.31, 90.0),
            sleeping = true,
            sleepScenario = "WORLD_HUMAN_SUNBATHE_BACK",
            weapon = { 
                enabled = true, 
                chance = 100, 
                weapon = `WEAPON_ASSAULTRIFLE`, 
                DisableWeaponDrop = true 
            }
        },
        
        StaticProps = {
            TV = { model = `prop_tv_flat_01`, Label = "Premium TV", Item = "television", Count = 1 },
            Laptop = { model = `prop_laptop_01a`, Label = "Laptop", Item = "laptop", Count = 1 },
            SCULPTER = { model = `v_res_sculpt_decb`, Label = "Sculpter", Item = "sculpter", Count = 1 },
            TELESCOPE = { model = `prop_t_telescope_01b`, Label = "Telescope", Item = "telescope", Count = 1 },
        },
    },

    ["Rockford Hills Mansion"] = {
        Coords = vec4(-815.59, 177.51, 72.15, 220.0),
        Shell = "envi_shell_03_furnished", -- Envi Shell 03 Furnished (Premium)
        Tier = "High Tier",
        ReportChanceWhenEntering = 95,
        NeedPoliceCount = 3,
        
        InsidePositions = {
            ["Exit"] = { 
                coords = vector4(11.53, -10.45, 1.03, 0.0), -- Envi typical exit
            },
            ["Living Room"] = {
                ChanceToFindNothing = 10,
                coords = vector3(3.82, -4.15, 1.03),
                Items = {
                    { Item = "laptop", Chance = 85.9, MinCount = 1, MaxCount = 2 },
                    { Item = "art_piece", Chance = 45.9, MinCount = 1, MaxCount = 1 },
                    { Item = "money", Chance = 70.5, MinCount = 8000, MaxCount = 20000 },
                }
            },
            ["Master Suite"] = {
                ChanceToFindNothing = 5,
                coords = vector3(-8.35, -2.76, 1.03),
                Items = {
                    { Item = "rolex", Chance = 70.9, MinCount = 2, MaxCount = 3 },
                    { Item = "diamond_ring", Chance = 65.9, MinCount = 2, MaxCount = 4 },
                    { Item = "gold_necklace", Chance = 70.9, MinCount = 2, MaxCount = 3 },
                    { Item = "money", Chance = 80.5, MinCount = 10000, MaxCount = 30000 },
                }
            },
            ["Wine Cellar"] = {
                ChanceToFindNothing = 15,
                coords = vector3(12.45, 2.83, 1.03),
                Items = {
                    { Item = "wine", Chance = 90.9, MinCount = 3, MaxCount = 5 },
                    { Item = "money", Chance = 40.5, MinCount = 5000, MaxCount = 15000 },
                }
            },
            ["Study"] = {
                ChanceToFindNothing = 10,
                coords = vector3(-4.25, 8.65, 1.03),
                Items = {
                    { Item = "bonds", Chance = 60.9, MinCount = 5, MaxCount = 15 },
                    { Item = "art_piece", Chance = 50.9, MinCount = 1, MaxCount = 2 },
                    { Item = "laptop", Chance = 90.9, MinCount = 1, MaxCount = 1 },
                }
            },
        },
        
        CreateProps = {},
        
        Safes = {
            ["vault"] = { 
                model = `prop_ld_int_safe_01`, 
                Label = "Vault", 
                NeedItem = true, 
                Item = "lockpick", 
                Coords = vec4(-10.23, 5.45, 1.03, 180.0),
                ChanceToFindNothing = 0,
                Items = {
                    { Item = "gold_watch", Chance = 80.5, MinCount = 3, MaxCount = 5 },
                    { Item = "diamond_ring", Chance = 75.5, MinCount = 3, MaxCount = 6 },
                    { Item = "art_piece", Chance = 60.5, MinCount = 1, MaxCount = 3 },
                    { Item = "bonds", Chance = 70.5, MinCount = 10, MaxCount = 20 },
                    { Item = "money", Chance = 90.5, MinCount = 25000, MaxCount = 75000 },
                },
            }
        },
        
        Ped = { 
            chance = 100, 
            model = `s_m_m_security_01`, 
            coords = vec4(8.25, -6.43, 1.03, 270.0),
            sleeping = true,
            sleepScenario = "WORLD_HUMAN_GUARD_STAND",
            weapon = { 
                enabled = true, 
                chance = 100, 
                weapon = `WEAPON_CARBINERIFLE`, 
                DisableWeaponDrop = true 
            } 
        },
        
        StaticProps = {
            TV = { model = `prop_tv_06`, Label = "Premium TV", Item = "television", Count = 1 },
            SCULPTER = { model = `v_res_sculpt_decb`, Label = "Sculpter", Item = "sculpter", Count = 1 },
           ART = { model = `v_res_r_painting`, Label = "Painting", Item = "art_piece", Count = 1 },
       },
   },
}

-- ════════════════════════════════════════════════════════════════
--                   SHELL SPAWN OFFSETS REFERENCE
-- ════════════════════════════════════════════════════════════════

-- These are the shell spawn offsets used for different shells
Config.ShellOffsets = {
   -- K4MB1 Starter Shells
   ["starter_shells_k4mb1"] = {
       exit = vector4(0.0, 0.0, 0.0, 0.0), -- Need to determine actual offsets
   },
   
   -- Envi Shells (typical offsets)
   ["envi_shell_01_furnished"] = {
       exit = vector4(4.69, -6.74, 1.03, 0.0),
       livingroom = vector3(0.82, -2.50, 1.03),
       kitchen = vector3(6.09, 0.31, 1.03),
       bedroom = vector3(-5.66, -0.61, 1.03),
   },
   ["envi_shell_02_furnished"] = {
       exit = vector4(6.25, -8.73, 1.03, 0.0),
       livingroom = vector3(1.53, -3.75, 1.03),
       kitchen = vector3(8.42, 1.23, 1.03),
       bedroom = vector3(-6.84, -1.28, 1.03),
       office = vector3(-3.65, 5.73, 1.03),
   },
   ["envi_shell_03_furnished"] = {
       exit = vector4(11.53, -10.45, 1.03, 0.0),
       livingroom = vector3(3.82, -4.15, 1.03),
       bedroom = vector3(-8.35, -2.76, 1.03),
       extra1 = vector3(12.45, 2.83, 1.03),
       extra2 = vector3(-4.25, 8.65, 1.03),
   },
   
   -- Lynx Shells (from README)
   ["t1_furn_shell"] = {
       exit = vector4(-43.76, -621.26, -29.20, 163.11),
       -- Other positions relative to shell spawn
   },
   ["t2_furn_shell"] = {
       exit = vector4(-590.68, -713.26, -42.45, 180.93),
       -- Other positions relative to shell spawn
   },
   ["t3_furn_shell"] = {
       exit = vector4(-66.29, -817.39, -20.31, 181.04),
       -- Other positions relative to shell spawn
   },
}

-- For backwards compatibility, create the Config.Tier reference
Config.Tier = {}
for houseName, houseData in pairs(Config.HousesToRob) do
    if not Config.Tier[houseData.Tier] then
        Config.Tier[houseData.Tier] = houseData
    end
end

-- ════════════════════════════════════════════════════════════════
--                        EQUIPMENT SHOP
-- ════════════════════════════════════════════════════════════════

Config.Shop = {
    enabled = true,   
    Header = "Equipment Shop",
    
    Items = {
        { 
            label = 'Lockpick', 
            item = 'lockpick', 
            description = "Essential tool for breaking into houses", 
            price = 850, 
            MinAmount = 1, 
            MaxAmount = 20 
        },
        { 
            label = 'Duffel Bag', 
            item = 'loot_bag', 
            description = "Large bag for carrying stolen goods", 
            price = 1000, 
            MinAmount = 1, 
            MaxAmount = 5 
        },
        { 
            label = 'Wire Cutters', 
            item = 'wire_cutters', 
            description = "For cutting security wires", 
            price = 750, 
            MinAmount = 1, 
            MaxAmount = 15 
        },
        { 
            label = 'Night Vision Goggles', 
            item = 'nvg', 
            description = "See in the dark for better stealth", 
            price = 2500, 
            MinAmount = 1, 
            MaxAmount = 3 
        },
        { 
            label = 'Silenced Shoes', 
            item = 'stealth_shoes', 
            description = "Reduces footstep noise significantly", 
            price = 1200, 
            MinAmount = 1, 
            MaxAmount = 5 
        },
    },
    
    Ped = {
        model = `a_m_o_acult_02`, 
        coords = vector4(1189.19, 2638.31, 37.44, 49.19), 
        scenario = "WORLD_HUMAN_AA_SMOKE"
    },
}

-- ════════════════════════════════════════════════════════════════
--                       STOLEN GOODS SHOP
-- ════════════════════════════════════════════════════════════════

Config.TabletShop = {
    enabled = true,   
    Header = "Underground Fence",
    
    Items = {
        -- Electronics
        { label = 'TV', item = 'television', price = 1500, MinAmount = 1, MaxAmount = 20 },
        { label = 'Smart TV', item = 'smart_tv', price = 2500, MinAmount = 1, MaxAmount = 20 },
        { label = 'Flat Screen TV', item = 'flatscreentv', price = 2200, MinAmount = 1, MaxAmount = 15 },
        { label = 'Laptop', item = 'laptop', price = 1800, MinAmount = 1, MaxAmount = 20 },
        { label = 'Tablet', item = 'tablet', price = 1200, MinAmount = 1, MaxAmount = 15 },
        { label = 'Phone', item = 'phone', price = 400, MinAmount = 1, MaxAmount = 20 },
        { label = 'Electronics', item = 'electronics', price = 600, MinAmount = 1, MaxAmount = 20 },
        { label = 'Speaker', item = 'speaker', price = 300, MinAmount = 1, MaxAmount = 20 },
        { label = 'Boombox', item = 'boombox', price = 250, MinAmount = 1, MaxAmount = 15 },
        { label = 'Radio', item = 'radio', price = 200, MinAmount = 1, MaxAmount = 20 },
        { label = 'Guitar', item = 'guitar', price = 800, MinAmount = 1, MaxAmount = 10 },
        { label = 'Hero Action Figure', item = 'hero', price = 150, MinAmount = 1, MaxAmount = 25 },
        
        -- Plants & Decorative
        { label = 'Bonsai Tree', item = 'bonsai_tree', price = 180, MinAmount = 1, MaxAmount = 15 },
        
        -- Jewelry
        { label = 'Gold Watch', item = 'gold_watch', price = 2100, MinAmount = 1, MaxAmount = 20 },
        { label = 'Gold Bracelet', item = 'gold_bracelet', price = 1300, MinAmount = 1, MaxAmount = 20 },
        { label = 'Diamond Ring', item = 'diamond_ring', price = 3500, MinAmount = 1, MaxAmount = 10 },
        { label = 'Gold Necklace', item = 'gold_necklace', price = 2500, MinAmount = 1, MaxAmount = 15 },
        { label = 'Rolex', item = 'rolex', price = 4000, MinAmount = 1, MaxAmount = 10 },
        { label = '10K Gold Chain', item = '10kgoldchain', price = 1500, MinAmount = 1, MaxAmount = 15 },
        { label = 'VVS Watch', item = 'vvs_ap', price = 3200, MinAmount = 1, MaxAmount = 8 },
        { label = 'Bracelet', item = 'bracelet', price = 800, MinAmount = 1, MaxAmount = 20 },
        
        -- Art & Collectibles
        { label = 'Art Piece', item = 'art_piece', price = 5000, MinAmount = 1, MaxAmount = 5 },
        { label = 'Ancient Statue', item = 'statue', price = 15000, MinAmount = 1, MaxAmount = 2 }, -- NEW: High value for carried statue
        
        -- Weapons & Attachments
        { label = 'Weapon Attachment', item = 'weapon_attachment', price = 2000, MinAmount = 1, MaxAmount = 10 },
        { label = 'Pistol Ammo', item = 'pistol_ammo', price = 100, MinAmount = 1, MaxAmount = 50 },
        { label = 'Rifle Ammo', item = 'rifle_ammo', price = 150, MinAmount = 1, MaxAmount = 50 },
        
        -- Miscellaneous Items
        { label = 'Shoe Box', item = 'shoebox', price = 100, MinAmount = 1, MaxAmount = 20 },
        { label = 'Bong', item = 'bong', price = 80, MinAmount = 1, MaxAmount = 20 },
        { label = 'Perfume', item = 'perfume', price = 250, MinAmount = 1, MaxAmount = 25 },
        { label = 'Wine', item = 'wine', price = 200, MinAmount = 1, MaxAmount = 15 },
        { label = 'Panties', item = 'panties', price = 50, MinAmount = 1, MaxAmount = 30 },
        
        -- Food & Consumables
        { label = 'Sandwich', item = 'sandwich', price = 10, MinAmount = 1, MaxAmount = 50 },
        { label = 'Chicken Sandwich', item = 'chickensandwich', price = 15, MinAmount = 1, MaxAmount = 40 },
        { label = 'Water Bottle', item = 'water_bottle', price = 5, MinAmount = 1, MaxAmount = 50 },
        { label = 'Toothpaste', item = 'toothpaste', price = 8, MinAmount = 1, MaxAmount = 20 },
        { label = 'Shampoo', item = 'shampoo', price = 12, MinAmount = 1, MaxAmount = 20 },
        { label = 'Soap', item = 'soap', price = 6, MinAmount = 1, MaxAmount = 20 },
        
        -- Books & Stationery
        { label = 'Romantic Book', item = 'romantic_book', price = 25, MinAmount = 1, MaxAmount = 40 },
        { label = 'Book', item = 'book', price = 20, MinAmount = 1, MaxAmount = 40 },
        { label = 'Notepad', item = 'notepad', price = 10, MinAmount = 1, MaxAmount = 50 },
        { label = 'Pencil', item = 'pencil', price = 5, MinAmount = 1, MaxAmount = 100 },
    },
    
    Ped = {
        model = `a_m_m_fatlatin_01`, 
        coords = vector4(1187.08, 2637.35, 37.4, 349.92), 
        scenario = "WORLD_HUMAN_AA_COFFEE"
    },
}