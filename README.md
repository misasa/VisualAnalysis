# VisualAnalysis

R/Shiny interface to Medusa for visualizing geochemical data

# Description

This is an [R][r]/[Shiny][shiny] interface to [Medusa][medusa].
This app uses [Leaflet][leaflet], which is the leading open-source JavaScript library for interactive maps, and [chelyabinsk][] to visualize geochemical dataset served by Medusa.

[medusa]: https://github.com/misasa/medusa/        "Medusa"
[leaflet]: https://leafletjs.com/ "Leaflet"
[chelyabinsk]: https://github.com/misasa/chelyabinsk   "Chelyabinsk"
[shiny]: http://shiny.rstudio.com/ "Shiny"
[r]: https://www.r-project.org/ "R"


# Dependency

## [GNU R](https://www.r-project.org/ "follow instruction")
## [r package -- chelyabinsk](https://github.com/misasa/chelyabinsk "follow instruction")
## [r package -- MedusaRClient](https://github.com/misasa/MedusaRClient "follow instruction")

# User's guide

To install required packages issue following command.

    R> install.packages('shiny')
    R> install.packages('devtools')
    R> devtools::install_github('misasa/chelyabinsk')
    R> devtools::install_github('misasa/MedusaRClient')

To run the application issue following command.

    R> library('devtools')
    R> runApp('maps')
