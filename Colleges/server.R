library(shiny)
library(leaflet)
library(RSQLite)
library(dplyr)
library(data.table)
library(ggplot2)
library(magrittr)
library(htmltools)

db <- dbConnect(dbDriver("SQLite"), "C:\\Users\\Craig\\Documents\\R\\Projects\\Colleges\\output\\database.sqlite")

colleges <- dbGetQuery(db, "SELECT UNITID AS id,INSTNM AS name, CITY AS city,STABBR AS state, 
                       INSTURL AS url,main AS main_campus,CONTROL AS ownership,region AS region_id,LOCALE AS locale,LATITUDE AS latitude, 
                       LONGITUDE AS longitude,RELAFFIL AS religious_affiliation, ADM_RATE AS admission_rate, 
                       SAT_AVG AS sat_avg, SATVR25 AS sat_reading_25, SATVR75 AS sat_reading_75, SATVRMID AS sat_reading_mid,SATMT25 AS sat_math_25, 
                       SATMT75 AS sat_math_75, SATMTMID AS sat_math_mid, SATWR25 AS sat_writing_25, SATWR75 AS sat_writing_75, SATWRMID AS sat_writing_mid, 
                       ACTCM25 AS act_cum_25, ACTCM75 AS act_cum_75, ACTCMMID AS act_cum_mid, ACTEN25 AS act_english_25, ACTEN75 AS act_english_75, 
                       ACTENMID AS act_english_mid, ACTMT25 AS act_math_25, ACTMT75 AS act_math_75, ACTMTMID AS act_math_mid, ACTWR25 AS act_writing_25, 
                       ACTWR75 AS act_writing_75, ACTWRMID AS act_writing_mid, PCIP01 AS pct_agriculture, PCIP03 AS pct_resources, PCIP04 AS pct_architecture, 
                       PCIP05 AS pct_ethnic_cultural_gender, PCIP09 AS pct_communication, PCIP10 AS pct_communications_technology, PCIP11 AS pct_computer, 
                       PCIP12 AS pct_personal_culinary, PCIP13 AS pct_education, PCIP14 AS pct_engineering, PCIP15 AS pct_engineering_technology, 
                       PCIP16 AS pct_language, PCIP19 AS pct_family_consumer_science, PCIP22 AS pct_legal, PCIP23 AS pct_english, PCIP24 AS pct_humanities, 
                       PCIP25 AS pct_library, PCIP26 AS pct_biological, PCIP27 AS pct_mathematics, PCIP29 AS pct_military, PCIP30 AS pct_multidiscipline, 
                       PCIP31 AS pct_parks_recreation_fitness, PCIP38 AS pct_philosophy_religious, PCIP39 AS pct_theology_religious_vocation, 
                       PCIP40 AS pct_physical_science, PCIP41 AS pct_science_technology, PCIP42 AS pct_psychology, PCIP43 AS pct_security_law_enforcement, 
                       PCIP44 AS pct_public_administration_social_service, PCIP45 AS pct_social_science, PCIP46 AS pct_construction, PCIP47 AS pct_mechanic_repair_technology, 
                       PCIP48 AS pct_precision_production, PCIP49 AS pct_transportation,PCIP50 AS pct_visual_performing, PCIP51 AS pct_health, 
                       PCIP52 AS pct_business_marketing, PCIP54 AS pct_history,UGDS AS size, CURROPER AS currently_operating, NPT4_PUB AS avg_net_price_public, 
                       NPT4_PRIV AS avg_net_price_private, TUITIONFEE_IN AS tuition_in_state, TUITIONFEE_OUT AS tuition_out_of_state, 
                       INEXPFTE AS instructional_spend_per_fte, AVGFACSAL AS avg_faculty_salary, PFTFAC AS ft_faculty_rate
                       FROM scorecard
                       WHERE currently_operating = 'Currently certified as operating'
                       AND latitude <> 'NA'
                       AND size >= 500
                       AND size <= 100000
                       AND tuition_in_state > 0
                       AND tuition_out_of_state > 0
                       AND admission_rate > 0
                       AND admission_rate <= 1
                       ORDER BY admission_rate")

columns <- colnames(colleges[40:76])
columns <- gsub("pct_", "", columns)
columns <- gsub("_", " ", columns)


# Define a server for the Shiny app
shinyServer(function(input, output) {
  
  filteredData <- reactive({
    # filter on the type of college (public, private, etc.)
    if (input$ownership != "All") {
      colleges <- colleges[colleges$ownership == input$ownership,]
    }
    # filter on the region
    if (input$region_id != "All") {
      colleges <- colleges[colleges$region_id == input$region_id,]
    }

    # apply all filters
    colleges <- filter(colleges,
                      size >= input$enrollment[1] &
                      size <= input$enrollment[2] &
                      tuition_in_state >= input$tuition_in_state[1] &
                      tuition_in_state <= input$tuition_in_state[2] &
                      tuition_out_of_state >= input$tuition_out_state[1] &
                      tuition_out_of_state <= input$tuition_out_state[2])
    
    
    #-------------------------------------------
    # still need to get this part working
    #-------------------------------------------
    # if (interest != "All"){
    #   # clean up interest input for matching
    #   interest <- gsub(" ", "_", interest)
    #   interest <- paste("pct_",interest)
    #   interest <- gsub(" ", "", interest)
    # 
    #   
    #   # calculate 75th percentile of % of degrees awarded for the given are of interest
    #   pct_75 <- quantile(colleges[,interest],na.rm = TRUE)[4]
    #   
    #   # keep the top 75th percentile of degrees awarded
    #   colleges <- colleges[which(colleges[,interest] >= pct_75),]
    # }
    
    colleges
  })
  
  # generate an HTML table view of the data
  output$table <- renderTable({
    data.frame(x=filteredData())
  })
  
  
  # generate a map view of the data
  output$mymap <- renderLeaflet({
    leaflet(data=colleges) %>%
      addTiles() %>%
      addMarkers(~longitude,~latitude,popup=~as.character(name))
  })
  
  observe({
    leafletProxy("mymap", data = filteredData()) %>%
      clearMarkers() %>%
      addMarkers(~longitude,~latitude,popup=~as.character(name))
  })
  
})