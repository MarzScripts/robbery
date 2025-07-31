fx_version 'cerulean'

game 'gta5'

author 'Marz Scripts'
description 'Marz House Robbery System'

version '1.0.0'

lua54 'yes'

dependencies {
    'ox_lib',
    'oxmysql',
    -- Shell dependencies
    'K4MB1-StarterShells',
    'envi-shells',
    'lynx_shells'
}

shared_scripts {
    '@ox_lib/init.lua',
    'shared/config.lua',
}

client_scripts {
    'client/cl_utils.lua',
    'client/cl_stealth.lua',
    'client/cl_main.lua',
    'client/cl_tablet.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/sv_utils.lua',
    'server/sv_main.lua',
    'server/sv_shop.lua',
    'server/sv_tablet.lua',
}

files {
    'locales/en.json',
    'html/tablet.html',
    'html/tablet.css',
    'html/tablet.js',
    'html/stealth.html',
}

ui_page 'html/stealth.html'