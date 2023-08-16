source("renv/activate.R")

for (package in renv::dependencies()$Package) {
    if (!requireNamespace(package)) {
        print(paste0("Installing required package: ", package))
        renv::install(package)
    }
}
