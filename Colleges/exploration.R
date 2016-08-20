
library(RSQLite)
library(dplyr)
library(data.table)
library(ggplot2)
library(magrittr)


db <- dbConnect(dbDriver("SQLite"), "C:\\Users\\Craig\\Documents\\R\\Projects\\Colleges\\output\\database.sqlite")
dbGetQuery(db, "PRAGMA temp_store=2;") 

tables <- dbGetQuery(db, "SELECT Name FROM sqlite_master WHERE type = 'table'")

# get list of column names - there are 1729 columns, but we don't need that many
checker <- dbGetQuery(db, "SELECT * FROM scorecard limit 5")
column_names <- colnames(checker)

# plan:  user enters answer to a questionnaire.  Use classification algorithm to recommend colleges
# incorporate reach and safety schools, geography, test scores, gpa, desired majors (with college ranks within major)

checker <- dbGetQuery(db, "select sat_scores.average.overall FROM scorecard")

colleges <- dbGetQuery(db, "SELECT UNITID AS id,INSTNM AS name, CITY AS city,STABBR AS state,AccredAgency AS accreditor, 
INSTURL AS url,main AS main_campus,CONTROL AS ownership,region AS region_id,LOCALE AS locale,LATITUDE AS latitude, 
LONGITUDE AS longitude,MENONLY AS men_only, WOMENONLY AS women_only, RELAFFIL AS religious_affiliation, ADM_RATE AS admission_rate, 
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
                       FROM scorecard")

# only keep currently operating colleges
colleges <- filter(colleges, currently_operating == "Currently certified as operating", !is.na(latitude))

colleges <- colleges[order(colleges$admission_rate),]







