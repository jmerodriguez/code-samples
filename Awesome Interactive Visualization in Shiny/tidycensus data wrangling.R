#This code downloads variables from the US Census Bureau using the tidycensus R package,
#as well as US States geometries using the polygon data that comes in the spData R package.

#install.packages("tidycensus")
#install.packages("sf")
library(tidycensus)
library(tidyverse)
library(sf)
library(spData)
library(glue)
census_api_key("294056f8026e13298e326dabe95389cb23dd2fad")
census_key <- Sys.getenv("CENSUS_API_KEY")


###DATA WRANGLING:


##1-year ACS
#Table codes
#if more tables are desired, look for codes in
#https://data.census.gov/cedsci/all?d=ACS%201-Year%20Estimates%20Subject%20Tables
#syntax: tableID_column
tablesID <- c(
  education      = "S1501_C02",
  health_ins     = "S2704_C03",
  unemployment   = "S2301_C04",
  income_households = "S1901_C01",
  household_size    = "S1101_C01" 
)

#Row numbers of the desired variables of each table
#you search them by running the following code:
#acs_var <- load_variables(2019, "acs1/subject", cache = TRUE)
codes_education <- c(14:15)
code_health_ins <- c("06")
codes_income    <- c(12)
codes_unemployment  <- c("01")
codes_household_size<- c("02", 10:12)


append_vars <- function(tableID, codes) {
  aux2 <- c(glue('{tableID}_0{codes}'))
  rbind(aux2)
}


vars <- append_vars(tablesID["education"], codes_education) %>%
  cbind(append_vars(tablesID["health_ins"], code_health_ins),
        append_vars(tablesID["unemployment"], codes_unemployment),
        append_vars(tablesID["income_households"], codes_income),
        append_vars(tablesID["household_size"], codes_household_size)
  )

var_names <- tibble(code = c("S1101_C01_002", "S1101_C01_010", "S1101_C01_011", "S1101_C01_012",
                             "S1501_C02_014", "S1501_C02_015", "S1901_C01_012", "S2301_C04_001",
                             "S2704_C03_006"),
                    var_name = c("hs_size", "under18", "over60", "alone", "HSch",
                                 "BachDeg", "med_inc", "unempl", "medic"))


years <- c(2017, 2018, 2019)

data <- list()
i <- 1
for (y in years) {
  data[[i]] <- get_acs(
    geography = "state",
    variables = vars,
    survey = "acs1",
    year = y,
    geometry = "false") %>%
    select(-moe) %>%
    mutate(year = y) %>%
    pivot_wider(names_from  = "variable",
                values_from = "estimate")
  
  i = i + 1
  
}

acs_data <- rbind(data[[1]], data[[2]], data[[3]]) %>%
  rename_at(vars(S1101_C01_002:S2704_C03_006), ~var_names$var_name) 
  


##US States polygons
states_geometry <- select(us_states, GEOID, geometry)


##Joining the two datasets
full_df <- acs_data %>%
  left_join(states_geometry, by = "GEOID") %>%
  filter(NAME != "Alaska" & NAME != "Hawaii" & NAME != "Puerto Rico" & NAME != "District of Columbia") %>%
  select(GEOID, NAME, year, geometry, everything()) %>%
  st_as_sf(crs = 4326)


#Run only if you want to download the data table in your computer, but you do not need it
#for seeing my shinyapp online.
#install.packages("here")
#library(here)
# path <- "" #directory in which you want to save the file
# 
# st_write(full_df,
#          here(path, "census_data.shp"),
#          delete_dsn = TRUE)
