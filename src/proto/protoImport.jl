using YAML

#imports for the INa HEK database
WTfall_val = Dict(YAML.load_file("INaHEK/WTfall_val.yaml"))
WTfall = Dict(YAML.load_file("INaHEK/WTfall.yaml"))
WTgv_val = Dict(YAML.load_file("INaHEK/WTgv_val.yaml"))
WTgv = Dict(YAML.load_file("INaHEK/WTgv.yaml"))
WTinac_val = Dict(YAML.load_file("INaHEK/WTinac_val.yaml"))
WTinac = Dict(YAML.load_file("INaHEK/WTinac.yaml"))
WTmaxpo = Dict(YAML.load_file("INaHEK/WTmaxpo.yaml"))
WTrecovery_val = Dict(YAML.load_file("INaHEK/WTrecovery_val.yaml"))
WTrecovery = Dict(YAML.load_file("INaHEK/WTrecovery.yaml"))
WTRUDB_val = Dict(YAML.load_file("INaHEK/WTRUDB_val.yaml"))
WTRUDB = Dict(YAML.load_file("INaHEK/WTRUDB.yaml"))

protoInfo = WTinac