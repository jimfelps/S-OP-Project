rm(list = ls(all.names = TRUE))

library(tidyverse)
library(lubridate)
library(readxl)

eng_complexity_lookup <- read_csv("~/R/R Data/Engineering/MBR Charts/eng_complexity_lookup.csv")
backlog_tons_detail <- read_csv("~/R/R Data/Engineering/MBR Charts/backlog_tons_detail.csv")
eng_backlog <- read_csv("~/R/R Data/Engineering/MBR Charts/eng_backlog.csv")
pa_expenditures_20160701_20190630 <- read_csv("~/R/R Data/S&OP/customer_analysis_3_years/pa_expenditures_20160701_20190630.csv", 
                                              col_types = cols(CUSTOMER_NUMBER = col_character(), 
                                                               EXPENDITURE_ENDING_DATE = col_date(format = "%m/%d/%Y"), 
                                                               EXPENDITURE_ITEM_DATE = col_date(format = "%m/%d/%Y"), 
                                                               PROJECT_NUMBER = col_character()))
pa_expenditures_20190701_20190927 <- read_csv("~/R/R Data/S&OP/customer_analysis_3_years/pa_expenditures_20190701_20190927.csv", 
                                              col_types = cols(CUSTOMER_NUMBER = col_character(), 
                                                               EXPENDITURE_ENDING_DATE = col_date(format = "%m/%d/%Y"), 
                                                               EXPENDITURE_ITEM_DATE = col_date(format = "%m/%d/%Y"), 
                                                               PROJECT_NUMBER = col_character()))

pa_exp_all <- bind_rows(pa_expenditures_20160701_20190630, pa_expenditures_20190701_20190927)

pa_exp_all_summary <- pa_exp_all %>%
  group_by(ORDER_NUMBER) %>%
  summarise(
    quantity = round(sum(QUANTITY),2),
    cost = round(sum(BURDEN_COST),2))

#some clean up before beginning...

x <- str_detect(names(eng_backlog), "Date")
lapply(eng_backlog[,x], ymd)



clar <- eng_backlog$COC_Act_Compl_Date
des <- eng_backlog$DES_Act_Compl_Date
dtl <- eng_backlog$DTL_Act_Compl_Date
eck <- eng_backlog$ECK_Act_Compl_Date
ship <- eng_backlog$`Ship AC Date`

#add backlog bucket for engineering pipeline

eng_backlog$eng_status <- ifelse(!is.na(ship), "Shipped",
                                 ifelse(!is.na(eck) & is.na(ship), "MFG",
                                        ifelse(!is.na(des) & is.na(dtl) & is.na(eck) & is.na(ship), "Detailing", 
                                               ifelse(!is.na(clar) & is.na(des) & is.na(dtl) & is.na(eck) & is.na(ship), "Design","Clarification"))))

# change the orders with scheduled ship dates of 1/1/2030 to "On Hold"
# even if the order has been ECK'd
# customer may request changes, requiring additional engineering resources

no_val <- is.na(eng_backlog$`Ship SC Date`)
eng_backlog$`Ship SC Date`[no_val] <- "2000-01-01"

on_hold <- eng_backlog$`Ship SC Date` > "2029-10-30"

eng_backlog$eng_status[on_hold] <- "On Hold"

# create project number field in a given data frame

eng_backlog2 <- eng_backlog %>% mutate(proj_num = str_sub(`Order Number`, 1, 8))

eng_complexity <- eng_complexity_lookup %>% mutate(proj_num = str_sub(`Order Number`, 1, 8))

# select only some of the columns from eng_complexity

eng_complexity2 <- select(eng_complexity, c(2,3,5,6,11,12,13,14,15,16,21,24,25,26))

#merge eng complexity with the eng status for all orders using a left join function

eng_master <- merge(eng_backlog2, eng_complexity2, by = "proj_num", all.x = TRUE)

# changes projects with missing complexity to undefined
# when I created this script, less than 1% of orders had undefined complexity
# these orders should be reviewed after running script

no_val <- is.na(eng_master$Complexity)
eng_master$Complexity[no_val] <- "Undefined"

# change orders with zero budget hours to no engineering Budget

no_val <- eng_master$`Budget Hours` == 0
eng_master$Complexity[no_val] <- "No Engineering Budget"

# only need a couple of the columns in eng_master...

eng_master2 <- select(eng_master, c(1,2,5,27,31:38))

# add proj_num to material backlog

mat_backlog <- backlog_tons_detail %>% mutate(proj_num = str_sub(`Order Number`, 1, 8))

# merge mat backlog w/ eng_master file to get a material backlog that includes an engineering complexity
# as well as an engineering status

colnames(eng_master2)[2] <- "Order"
colnames(mat_backlog)[7] <- "Order"

mat_backlog_w_eng <- merge(mat_backlog, eng_master2, by = "Order", all.x = TRUE)

# update missing complexity to "Parts Order/Buyout - No Eng"

no_val <- is.na(mat_backlog_w_eng$Complexity)
mat_backlog_w_eng$Complexity[no_val] <- "Parts Order/Buyout - No Eng"

# update eng_status to "No Eng"

no_val <- is.na(mat_backlog_w_eng$eng_status)
mat_backlog_w_eng$eng_status[no_val] <- "No Eng"

# update shipped status to MFG (some items have shipped but order is not shipped complete)

no_val <- mat_backlog_w_eng$eng_status == "Shipped"
mat_backlog_w_eng$eng_status[no_val] <- "MFG"



#mat_backlog_w_eng2 <- mat_backlog_w_eng %>%
#  select(1:13,17,22:25) %>%
#  replace_na(list(`Budget Hours` = 0, `Actual Hours` = 0, `Engineering Amt` = 0)) %>%
#  group_by(Order, Bucket, Division, Region, `Customer Name`, `Project Name`, `Transaction Type`, Complexity) %>%
#  summarise(tons = round(sum(`Total Tons`),2),
#            revenue = round(sum(`Backlog Dollars`),2),
#            margin = round(sum(`Margin with Exch Rate`),2),
#            budget_hrs = round(mean(`Budget Hours`),2),
#            actual_hrs_maybe = round(mean(`Actual Hours`),2),
#            eng_amt_whatdoesthismean = round(mean(`Engineering Amt`),2)) %>%
#  left_join(pa_exp_all_summary, by = c("Order" = "ORDER_NUMBER")) %>%
#  replace_na(list(quantity = 0, cost = 0))
#
#write.csv(mat_backlog_w_eng2, "~/R/R Data/S&OP/customer_analysis_3_years/mat_backlog_w_eng.csv")  

backlog_w_complexity <- mat_backlog_w_eng %>%
  select(Division, 
         Region, 
         `Project Manager`, 
         `Customer Name`,
         Order,
         `Order Number`, 
         `Backlog Dollars`, 
         `Margin with Exch Rate`, 
         `Total Tons`,
         Bucket, 
         `Record Type`, 
         `Ordered Date`,
         `Transaction Type`,
         Complexity) %>%
  rename(Project = Order) %>%
  arrange(Division, Region, `Order Number`)

write.csv(backlog_w_complexity, "~/R/R Data/S&OP/backlog_w_complexity.csv")
