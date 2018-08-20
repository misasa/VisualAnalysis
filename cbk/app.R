library(shiny)
library(yaml)
library(chelyabinsk)
library(MedusaRClient)

config <- yaml.load_file("../config/medusa.yaml")
con <- Connection$new(list(uri=config$uri, user=config$user, password=config$password))

ui <- bootstrapPage(
  tags$head(tags$script(src="https://cdnjs.cloudflare.com/ajax/libs/iframe-resizer/3.5.16/iframeResizer.contentWindow.min.js",type="text/javascript")),
  textOutput("specified_var"),
  uiOutput("plotControls"),
  uiOutput("legendControls"),
  plotOutput("cbkplot"),
  HTML('<div data-iframe-height></div>')
)

server <- function(input, output, session){

  getID <- reactive({
    query <- parseQueryString(session$clientData$url_search)
    id <- NULL
    if (exists('id', where=query)){
      id <- query[['id']]
    }
    if (exists("global_id")){
      id <- global_id
    }
    id
  })
  
  get_df <- reactive({
    df <- NULL
    tryCatch({
      pmlame <- Pmlame$new(con)
      id <- getID()
      if (!(is.null(id))){
        tab <- pmlame$read(id,list(Recursivep=TRUE))
        if (nrow(tab) > 0){
          df <- tab
        }
      }
    },error= function(e){
      print(e)
    })
    df
  })

  output$specified_var <- renderText({
    id <- getID()
    if (!is.null(id)){
      paste("ID:", id)
    } else {
      "ID: NULL"
    }
  })
  
  output$plotControls <- renderUI({
    pmlame <- get_df()
    if (class(pmlame) != "try-error" && length(pmlame)){
      catgs <- cbk.category(pmlame)
      selectInput("category", "Category", catgs[catgs != "spots"])
    }
  })

  output$legendControls <- renderUI({
    pmlame <- get_df()
    if (class(pmlame) != "try-error" && length(pmlame)){
      checkboxInput("legend", "Legend", value = FALSE, width = NULL)
    }
  })
  
  output$cbkplot <- renderPlot({
    pmlame <- get_df()
    if (is.null(pmlame))
      return(NULL)
    if (nrow(pmlame) == 0)
      return(NULL)
    opts <- list(legendp=input$legend)
    cbk.plot(pmlame, category = input$category, opts = opts)
  })

}

shinyApp(ui = ui, server = server)
