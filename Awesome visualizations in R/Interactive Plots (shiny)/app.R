#You can see the resulting shiny app here:
# https://jmerodriguez.shinyapps.io/ACS-interactive/


#install.packages("leaflet")
#install.packages("tmap")
#install.packages("sf")
#install.packages("shinyWidgets")
library(shiny)
library(leaflet)
library(shinyWidgets)
library(sf)
library(tidyverse)
library(tmap)

df <- st_read("census_data.shp") %>%
  rename("Median household size" = "hs_size",
         "% of households with children under 18" = "under18",
         "% of households with adults over 60" = "over60",
         "% of households living alone" = "alone",
         "% of residents with high school degree or higher" = "HSch",
         "% of residents with bachelor degree or higher" = "BachDeg",
         "Median household income" = "med_inc",
         "Unemployment Rate" = "unempl")

df_mod <- df %>%
  st_drop_geometry() %>%
  select(-NAME, -year, -GEOID, -medic) 


ui <- fluidPage(
  
  fluidRow(h1("American Community Survey Visualizer")),
  
 column(width = 6.5,
        tags$style(type = "text/css", "#USmap {height: calc(100vh - 80px) !important;}"),
        leafletOutput(outputId = "USmap")),

 absolutePanel(id = "options",
               class = "panel panel-default",
               
               fluidRow(align = "center",
                        tags$h2("Variable Explorer")),
               
               fluidRow(align = "center",
                        column(width = 6,
                               selectInput(inputId = "var",
                                              label   = "Variable",
                                              choices = colnames(df_mod))),
                        column(width = 6,
                               selectInput(inputId = "year",
                                           label   = "Year",
                                           choices = c(2017, 2018, 2019)))
                        ),
               
               fluidRow(
                 column(width = 6,
                        plotOutput("histog")),
                 column(width = 6,
                        plotOutput("corr_med"))),
              
               top    = 120,
               left   = "auto",
               right  = 40,
               bottom = "auto",
               width  = 700,
               height = "auto")
)


server <- function(input, output) {
  
   data1 <- reactive({

     df %>%
       st_drop_geometry() %>%
       filter(year == input$year) %>%
       select(input$var, medic)
  })
  
   data2 <- reactive({
     
     df %>%
       filter(year == input$year) %>%
       select(input$var)
   })
   

  output$USmap <- renderLeaflet({

    tmap_mode("view")
    
      map <- tm_shape(shp = data2()) +
       tm_fill(col = input$var,
               title = input$var,
               n = 4,
               style = "jenks",
               alpha = 0.7,
               popup.vars = c(input$var))  +
       tm_borders() +
       tm_view(view.legend.position = c("left","bottom")) +
       tm_basemap(server = "OpenStreetMap", alpha = 0.7)
      
      tmap_leaflet(map) %>%
        setView(lng = -65, lat = 37.45, zoom = 3.5)
  })
  
  
 output$histog <- renderPlot({
   ggplot(data1()) +
     geom_histogram(aes(x = data1()[, input$var]),
                    position = "dodge",
                    color = "darkslategray4",
                    fill  = "darkslategray3") +
     labs(title    = "Histogram for Selected Variable",
          subtitle = input$year,
          x = input$var) +
     theme_minimal() +
     theme(plot.title    = element_text(hjust = 0.5, size = 15, face = "bold"),
           plot.subtitle = element_text(hjust = 0.5, size = 14, face = "bold"),
           axis.title    = element_text(size = 14),
           legend.position = "none") +
           scale_fill_manual(values = c("blue", "red"))
   })
          
          
output$corr_med <- renderPlot({
  ggplot(data1()) +
    geom_point(aes(x = data1()[, input$var], y = medic),
               color = "darkslategray4",
               fill  = "darkslategray3") +
    geom_smooth(aes(x = data1()[, input$var], y = medic), method = lm, color = "black") +
    labs(title = "Linear Fit",
         x = input$var,
         y = "Percentage of Residents on Medicaid",
         color = "State\nGovernor\nParty") +
    theme_minimal() +
    theme(plot.title = element_text(hjust = 0.5, size = 15, face = "bold"),
          axis.title = element_text(size = 14)) +
          scale_color_manual(values = c("blue", "red"))
  })

}

shinyApp(ui = ui, server = server)
