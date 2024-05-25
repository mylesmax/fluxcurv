#imports for the INa HEK database
function protoImport(dataPath)
    WTfall_val = Dict(YAML.load_file(dataPath*"WTfall_val.yaml"))
    WTfall = Dict(YAML.load_file(dataPath*"WTfall.yaml"))
    WTgv_val = Dict(YAML.load_file(dataPath*"WTgv_val.yaml"))
    WTgv = Dict(YAML.load_file(dataPath*"WTgv.yaml"))
    WTinac_val = Dict(YAML.load_file(dataPath*"WTinac_val.yaml"))
    WTinac = Dict(YAML.load_file(dataPath*"WTinac.yaml"))
    WTmaxpo = Dict(YAML.load_file(dataPath*"WTmaxpo.yaml"))
    WTrecovery_val = Dict(YAML.load_file(dataPath*"WTrecovery_val.yaml"))
    WTrecovery = Dict(YAML.load_file(dataPath*"WTrecovery.yaml"))
    WTRUDB_val = Dict(YAML.load_file(dataPath*"WTRUDB_val.yaml"))
    WTRUDB = Dict(YAML.load_file(dataPath*"WTRUDB.yaml"))

    return protoData = (WTfall_val = WTfall_val,
                    WTfall= WTfall,
                    WTgv_val = WTgv_val,
                    WTgv = WTgv,
                    WTinac_val =WTinac_val,
                    WTinac = WTinac,
                    WTmaxpo = WTmaxpo,
                    WTrecovery_val = WTrecovery_val,
                    WTrecovery = WTrecovery,
                    WTRUDB_val = WTRUDB_val,
                    WTRUDB = WTRUDB)
end