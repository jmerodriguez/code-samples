#SENTIMENT ANALYSIS FOR GLOBAL ECONOMIC DATA
#This file parses quarterly reports from the Bank of International Settlements (BIS),
#a financial institution in Switzerland that produces research and reports focusing
#on central banks and the global economy.
#The file does web scraping to download the reports from the internet, so
#no previous data download is needed.
#Note that the file is written in a way such that you can increase the number
#of analyzed reports for year-comparison purposes.

#install.packages(tidytext)
#install.packages(rvest)
library(tidyverse)
library(tidytext)
library(rvest)


#Get website function
get_website <- function(year_month) {
  
  url <- paste0("https://www.bis.org/publ/qtrpdf/r_qt", year_month, "a.htm")
    read_html(url)
  
}


#Get the text of the selected BIS report
get_report_text <- function(website) {
  
  website %>%
    html_node(., "#cmsContent") %>%
    html_nodes(., "p") %>%
    html_text(.) %>%
    paste(., collapse = "")
  
}


#Sentiment analysis
year_month <- c("1912", "2012")  #more periods (in the form of YYMM) can be added here if needed

data <- list()
proportions_tables <- list()
words <- list()

i <- 1

for (ym in year_month) {
  
 data[[i]] <- get_website(ym) %>%
   get_report_text() %>%
   tibble()
  
  words[[i]] <- unnest_tokens(data[[i]], words, ., token = "words")
  
 for (s in c("nrc", "bing")) {
    
   words[[i]] <- words[[i]] %>%
   left_join(get_sentiments(s), by = c("words" = "word")) %>%
   plyr::rename(replace = c(sentiment = s, value = s), warn_missing = FALSE) 
    
  }
  
proportions_tables[[i]] <- words[[i]] %>%
  pivot_longer(nrc:bing, names_to = "type", values_to = "sentiment") %>%
  filter(!is.na(sentiment)) %>%
  select(-words) %>%
  group_by(type, sentiment) %>%
  summarise(tot = n()) %>%
  group_by(type) %>%
  mutate(!!ym := round(tot / sum(tot), 2)) %>%
  select(-tot)
  
i = i + 1
  
  
}

names(proportions_tables) <- year_month

table <- reduce(proportions_tables, full_join, by = c("type", "sentiment"))

#plot function
sentiments_plot <- function(x) {
  
  aux <- length(year_month) + 2
  
 table %>%
   filter(type == x) %>%
   pivot_longer(3:aux,
                names_to = "period",
                values_to = "proportion") %>%
   ggplot() +
   geom_col(aes(x = sentiment, y = proportion, fill = period), position = "dodge") +
   scale_x_discrete(guide = guide_axis(angle = 45)) +
   labs(title = paste0("BIS ", x, " sentiment analysis"),
        subtitle = "Time Series") +
   xlab("Sentiments") +
   ylab("Proportion") +
   theme(plot.title = element_text(hjust = 0.5),
         plot.subtitle = element_text(hjust = 0.5))

}


#OUTPUT

#Summary table
print(table)

#plots
sentiments_plot("nrc") 
sentiments_plot("bing")
