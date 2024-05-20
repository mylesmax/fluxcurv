#imports for the INa HEK database
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

protoInfo = WTinac