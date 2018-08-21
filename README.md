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

To setup VisualAnalysis issue following command.

    $ git clone https://github.com/misasa/VisualAnalysis.git
    $ cd VisualAnalysis
    $ cp config/medusa.yaml.default config/medusa.yaml

To install required packages issue following command.
    
    $ sudo R
    R> install.packages('shiny')
    R> install.packages('leaflet')
    R> install.packages('htmltools')
    R> install.packages('htmlwidgets')
    R> install.packages('yaml')
    R> install.packages('rjson')
    R> install.packages('devtools')
    R> devtools::install_github('misasa/chelyabinsk')
    R> devtools::install_github('misasa/MedusaRClient')

To run the application issue following command.
    
    $ R
    R> library(shiny)
    R> global_id <- '20150916080446-153762'
    R> runApp('map')
