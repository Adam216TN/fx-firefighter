fx_version 'cerulean'
game 'gta5'

client_scripts {
    'client/utils.lua', 
    'client/cl_main.lua',
    'client/cl_panel.lua',
    'client/cl_hose.lua',
    'client/cl_refillhose.lua',
    'client/cl_waterjet.lua'
}

server_scripts {            
    'server/server.lua'      
}

files {
    'stream/**'
}

data_file 'DLC_ITYP_REQUEST' 'stream/prop_pipe_firefighter.ytyp'