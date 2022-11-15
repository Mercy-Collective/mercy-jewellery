fx_version 'cerulean'
game 'gta5'

author 'Mercy Collective (https://dsc.gg/mercy-coll)'
description 'Jewellery'

dependencies {
    'qb-target',
    'ps-ui'
} 

shared_script 'shared/sh_*.lua'
client_script 'client/cl_*.lua'
server_script 'server/sv_*.lua'

provide 'qb-jewellery'

lua54 'yes'