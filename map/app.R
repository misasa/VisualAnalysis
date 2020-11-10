library(shiny)
library(leaflet)
library(htmltools)
library(htmlwidgets)
library(yaml)
library(jsonlite)
library(MedusaRClient)
library(chelyabinsk)
source("../lib/func.R")
#global_id <- "20200318094021-774984"
#global_id <- "20200219105529-203562"
#global_id <- "20191212092751-166561"
#global_id <- "20150914105617-117249"
#global_id <- "20200221094909-267444"
#global_id <- "20190607100630-468419"
#global_id <- "20200117092729-333909"
#global_id <- "20200311132716-107216"
#global_id <- "20190424160427-729097"
#global_id <- "20200409105742-366515"
#global_id <- "20190306171521-621773"
#global_id <- "20120224095412-627-620"
#global_id <- "20190110091940-824859"
#global_id <- "20160820170853-707954"
#global_id <- "20190115102242-432018"
maxZoom <- 12
config <- yaml.load_file("../config/medusa.yaml")
con <- Connection$new(list(protocol=config$protocol, uri=config$uri, user=config$user, password=config$password))

absPanel_plot <- absolutePanel(
  id = "plot-controls", class = "panel panel-default", fixed = FALSE,
  draggable = TRUE, top = 0, left = "auto", right = 0, bottom = "auto",
  width = "50%", height = "auto",
  uiOutput("idControls"),
  uiOutput("plotControls"),
  uiOutput("legendControls"),
  plotOutput("cbkplot")
)

absPanel_spot <- absolutePanel(
  id = "spot-controls", class = "panel panel-default", fixed = FALSE,
  draggable = TRUE, top = 0, right = "50%", left = "auto", bottom = "auto",
  width = "30%", height = "auto",
  uiOutput("itemControls"),
  uiOutput("spotSizeControls")
)


contents <- c(
  absPanel_plot,
  absPanel_spot
)

main_div <- div(
  class="outer",
  tags$head(
    includeCSS("styles.css"),
    includeScript("../js/L.Control.MyScale.js")
  ),
  leafletOutput("mymap", width="100%", height="100%"),
  contents
)

ui <- shinyUI(bootstrapPage(
  main_div
))

server <- function(input, output, session) {

  getQuery <- function(){
    parseQueryString(session$clientData$url_search)
  }

  get_surface <- eventReactive(input$surface,{
    selection <- as.numeric(input$surface)
    surface <- NULL
    if (!(is.na(selection))){
      surfaces <- getSurfaces()
      surface <- surfaces[selection,]
    }
    surface
  })

  get_df <- eventReactive(input$surface,{
    surface <- get_surface()
    object <- getObject()
    df <- NULL
    tab <- getDataFrame()
    if (is.null(surface)){
      df <- tab
    } else {
      tab <- tab[!is.na(tab$surface_id),]
      tab <- tab[!is.nan(tab$surface_id),]
      tab <- tab[!is.null(tab$surface_id),]
      tab <- tab[(tab$surface_id == surface$global_id),]
      if (nrow(tab) > 0){
        if (surface$globe){
          df <- tab
        } else {
          df <- addLatLng(tab, surface$center, surface$length)
        }
      }
    }
    df
  })

  get_grid <- eventReactive(input$surface, {
    surface <- get_surface()
    grid = NA
    if (!(is.null(surface))){
      interval <- 1000
      center <- unlist(surface$center)
      length <- unlist(surface$length)
      left <- center[1] - length/2
      upper <- center[2] + length/2
      right <- center[1] + length/2
      bottom <- center[2] - length/2
      xs <- seq(from = ceiling(left/interval)*interval, to = floor(right/interval)*interval, by = interval)
      ys <- seq(from = ceiling(bottom/interval)*interval, to = floor(upper/interval)*interval, by = interval)
      features <- list()

      x_vs = numeric(0)
      y_vs = numeric(0)
      for(i in 1:length(xs)){
        x_vs <- append(x_vs, rep(xs[i],3))
        y_vs <- append(y_vs, c(bottom, 0.0, upper))
      }
      df_xs <- addLatLng(data.frame(x_vs = x_vs, y_vs = y_vs), surface$center, surface$length)

      x_vs = numeric(0)
      y_vs = numeric(0)
      for(i in 1:length(ys)){
        x_vs <- append(x_vs, c(left, 0.0, right))
        y_vs <- append(y_vs, rep(ys[i],3))
      }
      df_ys <- addLatLng(data.frame(x_vs = x_vs, y_vs = y_vs), surface$center, surface$length)

      for(i in 1:length(xs)){
        sdf <- subset(df_xs, x_vs == xs[i], select = c(lng,lat), drop = TRUE)
        coordinates <- list()
        for(j in 1:nrow(sdf)){
          row <- sdf[j,]
          coordinates[[j]] <- c(row$lng, row$lat)
        }
        geometry <- list(type="LineString",coordinates=coordinates)
        property <- list(name=paste("x =", toString(xs[i])))
        feature <- list(type="Feature",geometry=geometry,properties=property)
        features[[i]] <- feature
      }

      for(i in 1:length(ys)){
        sdf <- subset(df_ys, y_vs == ys[i], select = c(lng,lat), drop = TRUE)
        coordinates <- list()
        for(j in 1:nrow(sdf)){
          row <- sdf[j,]
          coordinates[[j]] <- c(row$lng, row$lat)
        }
        geometry <- list(type="LineString",coordinates=coordinates)
        property <- list(name=paste("y =", toString(ys[i])))
        feature <- list(type="Feature",geometry=geometry,properties=property)
        features[[length(xs) + i]] <- feature
      }
      grid <- rjson::toJSON(list(type="FeatureCollection", features=features))
    }
    grid
  })

  getID <- reactive({
    query <- getQuery()
    id <- NULL
    if (exists('id', where=query)){
      id <- query[['id']]
    }
    if (exists("global_id")){
      id <- global_id
    }
    id
  })

  getObject <- reactive({
    id <- getID()
    record <- NULL
    if (!(is.null(id))){
      withProgress(message = paste('Getting', id), value = 0, {
        Record <- MedusaRClient::Resource$new("records", con)
        record <- Record$find_by_global_id(id)
        incProgress(0.9)
      })
    }
    record
  })

  getDataFrame <- reactive({
    object <- getObject()
    gdata <- NULL
    tryCatch({
      cat(file=stderr(), paste("reading data from RDS [",config$RDS,"]...\n",sep=""))
      gdata <- readRDS(config$RDS)
    },error= function(e){
      print(e)
    })

    if ((is.null(object))){
      tab <- NULL
    } else {
      withProgress(message = 'Getting data', value = 0, {
        incProgress(0.2)
        tab <- NULL
        tryCatch({
          if (!(is.null(gdata)) && length(object$pmlame_ids) > 0){
            tab <- gdata[(gdata$analysis_id %in% object$pmlame_ids),]
            tab <- tab[,!apply(tab, 2, function(x){ all(is.na(x))})]
          } else {
            pmlame <- Pmlame$new(con)
            tab <- pmlame$read(object$global_id,list(Recursivep=TRUE))
          }
          incProgress(1.0, detail = 'part 2')
        },error= function(e){
          print(e)
        })
      })
    }
    tab
  })

  getSurfaces <- reactive({
    tab <- getDataFrame()
    if (!(is.null(tab$surface_id))){
      surface_ids <- unique(tab$surface_id[is.na(tab$surface_id) == F])
      withProgress(message = 'Getting maps', value = 0, {
        #Surface <- MedusaRClient::Resource$new("surfaces", con)
        #surfaces <- Surface$find_all()
        #surfaces <- surfaces[(surfaces$global_id %in% surface_ids),]
        incProgress(0.1)
        Record <- MedusaRClient::Resource$new("records", con)
        records <- list()
        for(i in 1:length(surface_ids)){
          global_id <- surface_ids[i]
          record <- Record$find_by_global_id(global_id)
          records[[i]] <- record
        }
        incProgress(0.8)
      })
      surfaces <- fromJSON(toJSON(records, auto_unbox = TRUE))
      surfaces
    }
  })

  filteredData <- reactive({
    df <- get_df()
    surface <- get_surface()
    if (!(is.null(surface))){
      item <- input$item
      if (is.null(input$size)){
        size <- 100
      } else {
        size <- input$size
      }
      range <- input$range
      if (!is.null(item) && (item %in% names(df))){
        df$item <- df[item][[1]]
      } else {
        df$item <- df[names(df)[1]][[1]]
      }
      if (surface$globe){
        df$radius <- size
      } else {
        df$radius <- vsLength2geoLength(size/2,df$x_vs,df$y_vs, surface)
      }
    }
    df
  })

  output$idControls <- renderUI({
    iid <- getID()
    surfaces <- getSurfaces()
    if (length(surfaces$global_id) == 0){
      selected <- NA
      vars <- list("Not available" = "")
    } else {
      vars <- list("all" = "")
      selected <- 1
      for(i in 1:length(surfaces$global_id)){
        global_id <- surfaces[i,]$global_id
        if (!is.na(global_id)){
          if (!is.null(iid) && global_id == iid){
            selected <- i
          }
          vars[surfaces[i, ]$name] = i
        }
      }
    }
    selectInput("surface", "Map", vars, selected = selected, selectize = FALSE)
  })

  output$itemControls <- renderUI({
    surface <- get_surface()
    if (!(is.null(surface))){
      df <- get_df()
      items <- names(df)

      rm_items <- c("lng", "lat", "x_image", "y_image", "x_vs", "y_vs")
      for (i in 1:length(items)){
        if (!(is.numeric(df[,items[i]]))){
          rm_items <- c(rm_items, items[i])
        }
      }
      if (length(items) > 0){
        if (length(rm_items) > 0) {
          items <- items[-which(items %in% rm_items)]
        }
      }
      selectInput("item","Chem",items, selectize = FALSE)
    }
  })

  output$spotSizeControls <- renderUI({
    df <- get_df()
    surface <- get_surface()
    if (!(is.null(surface))){
      sliderInput("size", "Size",min=0, max=1000, value=surface$length/100)
    }
  })

  output$rangeControls <- renderUI({
    df <- get_df()
    surface <- get_surface()
    if (!(is.null(surface))){
      item <- input$item
      if (!is.null(item) && (item %in% names(df))){
        sliderInput("range","", min(df[item], na.rm = TRUE),max(df[item], na.rm = TRUE), value = range(df[item]))
      }
    }
  })

  output$plotControls <- renderUI({
    pmlame <- get_df()
    if (class(pmlame) != "try-error" && length(pmlame)){
      catgs <- cbk.category(pmlame)
      if (!is.null(catgs)){
        selectInput("category", "Category", catgs[catgs != "spots"], selectize = FALSE)
      } else {
        "No category is available."
      }
    }
  })

  output$legendControls <- renderUI({
    pmlame <- get_df()
    if (class(pmlame) != "try-error" && length(pmlame)){
      catgs <- cbk.category(pmlame)
      if (!is.null(catgs)){
        checkboxInput("legend", "Legend", value = FALSE, width = NULL)
      }
    }
  })

  colorpal <- reactive({
    pal <- NULL
    df <- get_df()
    item <- input$item
    if (!is.null(item) && (item %in% names(df))){
      tryCatch({
        pal <- colorNumeric("Spectral", df[item])
      },error= function(e){
        print(e)
      })
    }
    pal
  })

  output$mymap <- renderLeaflet({
    surface <- get_surface()
    map_data <- surface$map_data
    data <- get_df()
    if (!(is.null(surface))){
      withProgress(message = paste('Rendering', surface$name), value = 0, {
        myPlugin <- htmlDependency("leaflet.esri", "1.0.3",
                                 src = c(href = "js"),
                                 script = "L.Control.BetterScale.js"
        )
        registerPlugin <- function(map, plugin) {
          map$dependencies <- c(map$dependencies, list(plugin))
          map
        }
        incProgress(0.1)
        m <- leaflet()
        if (surface$globe) {
          m <- addTiles(m, group = "base")
          m <- addLayersControl(m,
                                overlayGroups = c("grid"),
                                position = "topleft")
        } else {
          base_images <- map_data$base_images[[1]]
          if (length(base_images) > 0){
            for(i in 1:length(base_images$id)){
              base_image <- base_images[i,]
              url_template <- paste(map_data$base_url, map_data$global_id, '/', base_image$id, '/{z}/{x}_{y}.png', sep="")
              options <- tileOptions(maxNativeZoom = base_image$max_zoom)
              m <- addTiles(m, urlTemplate = url_template, options = options, group = base_image$name)
            }
          }
          overlays <- c()
          if ('top' %in% names(map_data$images)){
            overlays <- append(overlays, 'top')
            images <- map_data$images["top"][[1]][[1]]
            for(j in 1:length(images$id)){
              url_template <- paste(map_data$base_url, map_data$global_id, '/', images$id[j], '/{z}/{x}_{y}.png', sep="")
              options <- tileOptions(maxNativeZoom = images$max_zoom[j])
              m <- addTiles(m, urlTemplate = url_template, options = options, group = 'top')
            }
          }
          layer_groups <- map_data$layer_groups[[1]]
          if (length(layer_groups) > 0){
            overlays <- append(overlays, layer_groups$name)
            for(i in 1:length(layer_groups$id)){
              images <- map_data$images[layer_groups$name[i]][[1]][[1]]
              for(j in 1:length(images$id)){
                url_template <- paste(map_data$base_url, map_data$global_id, '/', images$id[j], '/{z}/{x}_{y}.png', sep="")
                options <- tileOptions(maxNativeZoom = images$max_zoom[j])
                m <- addTiles(m, urlTemplate = url_template, options = options, group = layer_groups$name[i])
              }
            }
          }
          if (length(base_images) > 0){
            m <- addLayersControl(m,
                              baseGroups = base_images$name,
                              overlayGroups = append(overlays, "grid"),
                              position = "topleft")
          } else {
            m <- addLayersControl(m,
                                  overlayGroups = c("top", layer_groups$name, "grid"),
                                  position = "topleft")
          }
          m <- onRender(m, paste("function(el, x) { L.control.myscale({length:", surface$length, "}).addTo(this);}"))
          incProgress(0.9)
        }

        m <- hideGroup(m, c("top", "grid"))
        lng1 <- min(data$lng, na.rm = TRUE)
        lat1 <- min(data$lat, na.rm = TRUE)
        lng2 <- max(data$lng, na.rm = TRUE)
        lat2 <- max(data$lat, na.rm = TRUE)
        #maxZoom <- 15
        if ((lng1 == lng2) && (lat1 == lat2)){
          m <- setView(m, lng1, lat1, maxZoom)
        } else {
          m <- fitBounds(m, lng1 = lng1, lat1 = lat1, lng2 = lng2, lat2 = lat2)
        }
        m
      })
    }
  })

  dataInBounds <- reactive({
    df <- get_df()
    if (is.null(df))
      return(df)
    if (is.null(input$mymap_bounds))
      return(df)
    bounds <- input$mymap_bounds
    bounds <- input$mymap_bounds
    latRng <- range(bounds$north, bounds$south)
    lngRng <- range(bounds$east, bounds$west)
    subset(df,
           lat >= latRng[1] & lat <= latRng[2] &
             lng >= lngRng[1] & lng <= lngRng[2])
  })

  output$cbkplot <- renderPlot({
    surface <- get_surface()
    if (is.null(input$category)){
      return()
    }
    withProgress(message = paste('Rendering plot'), value = 0, {
      incProgress(0.1)
      if (!(is.null(surface))){
        pmlame <- dataInBounds()
      } else {
        pmlame <- get_df()
      }
      incProgress(0.3)
      if (is.null(pmlame))
        return(NULL)
      if (nrow(pmlame) == 0)
        return(NULL)
      opts <- list(legendp=input$legend)
      cbk.plot(pmlame, category = input$category, opts = opts)
      incProgress(0.9)
      })
  }, bg="transparent")

  observe({
    surface <- get_surface()
    if (! (is.null(surface))){
      withProgress(message = paste('Plotting spots'), value = 0, {
        incProgress(0.3)
        grid <- get_grid()
        data <- filteredData()
        pal <- colorpal()
        item <- input$item
        if (!is.null(data) && nrow(data) > 0 && !is.null(item) && (item %in% names(data))){
          m <- leafletProxy("mymap", data = data)
          m <- clearShapes(m)
          m <- addGeoJSON(m, grid, color = "#FF0000", weight = 1, group = "grid")
          if (surface$globe){
            m <- addMarkers(m)
            m <- addCircles(m, radius = ~radius, weight = 1, color = "#777777", fillColor = ~pal(item), fillOpacity = 0.7, popup = ~paste0("lat:", lat,", lng:", lng, ", radius:", radius))
          } else {
            m <- addMarkers(m)
            if(!is.null(pal)){
              m <- addCircles(m, radius = ~radius, weight = 1, color = "#777777", fillColor = ~pal(item), fillOpacity = 0.7, popup = ~paste0("x:", x_vs,", y:", y_vs, ", radius:", radius))
            }
          }
          m
        } else {
          m <- leafletProxy("mymap")
          m <- clearShapes(m)
          m <- addGeoJSON(m, grid, color = "#FF0000", weight = 1, group = "grid")
          m
        }
        m
      })
    }
  })

  observe({
    surface <- get_surface()
    data <- get_df()
    if (! (is.null(surface))){
      pal <- colorpal()
      item <- input$item
      if (!is.null(data) && nrow(data) > 0 && !is.null(item) && (item %in% names(data))){
        proxy <- leafletProxy("mymap", data = data)
        proxy <- clearControls(proxy)
        if(!is.null(pal)){
          proxy <- addLegend(proxy, position = "topleft",
                           title = item, pal = pal, values =c(max(data[item], na.rm = TRUE),min(data[item], na.rm = TRUE)), labFormat = labelFormat(digits=7)
          )
        }
      }
    }
  })
}

shinyApp(ui, server)
