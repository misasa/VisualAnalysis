library(MedusaRClient)
library(yaml)

initial.options <- commandArgs(trailingOnly = FALSE)
file.arg.name <- "--file="
script.name <- sub(file.arg.name,"",initial.options[grep(file.arg.name, initial.options)])
script.basename <- dirname(script.name)
config_path <- file.path(script.basename,"../config/medusa.yaml")
config <- yaml.load_file(config_path)
con <- Connection$new(list(uri=config$uri, user=config$user, password=config$password))
rds_path <- config$RDS

json_path <- commandArgs(trailingOnly=TRUE)[1]
obj <- Pmlame$new()
df <- obj$read_local(json_path)
saveRDS(df,rds_path)
