fx_version 'cerulean'
game 'gta5'

name 'nx-core'
description 'The pure core resource for the NX Framework'
version '1.2.0'

ox_lib 'locale'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    'shared/core.lua',
    'shared/modules/functions.lua',
    'shared/modules/locale.lua',
    'shared/jobs.lua',
    'shared/gangs.lua',
    'shared/items.lua',
    'shared/main.lua',
}

client_scripts {
    'client/core/main.lua',
    'client/modules/functions.lua',
    'client/modules/loops.lua',
    'client/modules/events.lua',
    'client/callbacks.lua',
    'client/time.lua',
    'client/vehicle-persistence.lua',
    'client/ban.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/core/main.lua',
    'server/database/init.lua',
    'server/player/manager.lua',
    'server/player/data.lua',
    'server/groups.lua',
    'server/callbacks.lua',
    'server/ban.lua',
    'server/logs.lua',
    'server/discord.lua',
    'server/time.lua',
    'server/loops.lua',
    'server/commands/admin.lua',
    'server/commands/staff.lua',
    'server/commands/public.lua',
    'server/events/handler.lua',
    'server/vehicle-persistence.lua',
}

files {
    'locales/*.json',
}

dependencies {
    '/server:10731',
    '/onesync',
    'ox_lib',
    'oxmysql',
}

lua54 'yes'
use_experimental_fxv2_oal 'yes'