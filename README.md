# VisualAnalysis

R/Shiny interface to Medusa for visualizing geochemical data

# Description

[R](https://www.r-project.org/)/[Shiny](http://shiny.rstudio.com/) interface to [rails project -- medusa](https://github.com/misasa/medusa) for visualizing geochemical data. This app uses [Leaflet](https://leafletjs.com/), which is the leading open-source JavaScript library for interactive maps, and [r package -- chelyabinsk](https://github.com/misasa/chelyabinsk) to visualize geochemical dataset served by Medusa.

# Dependency

## [GNU R](https://www.r-project.org/)
## [r package -- chelyabinsk](https://github.com/misasa/chelyabinsk)
## [r package -- MedusaRClient](https://github.com/misasa/MedusaRClient)

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
