library(shiny)


# Define the overall UI
shinyUI(
  fluidPage(
    titlePanel("Colleges"),
    sidebarLayout(
      sidebarPanel(
        selectInput("ownership",
                    "Type:",
                    c("All",
                      unique(as.character(colleges$ownership)))),
        selectInput("region_id",
                    "Region:",
                    c("All",
                      unique(as.character(colleges$region_id)))),
        selectInput("interest",
                    "Field of Interest:",
                    c("All",
                      unique(as.character(columns)))),
        sliderInput("enrollment", "Undergraduate Enrollment:",
                    min = 0, max = max(colleges$size), value = c(0, max(colleges$size))),
        sliderInput("tuition_in_state", "Tuition - In State:",
                    min = 0, max = max(colleges$tuition_in_state), value = c(0, max(colleges$tuition_in_state))),
        sliderInput("tuition_out_state", "Tuition - Out of State:",
                    min = 0, max = max(colleges$tuition_out_of_state), value = c(0, max(colleges$tuition_out_of_state)))
      ),
      mainPanel(
        tabsetPanel(type="tabs",
                    tabPanel("Table", tableOutput("table")),
                    tabPanel("Map", height = "1000px", leafletOutput("mymap")),
                    style='width: 1000px; height: 1000px')
        
      )
    )
  )
)



