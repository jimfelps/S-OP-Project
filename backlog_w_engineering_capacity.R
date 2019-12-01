rm(list = ls(all.names = TRUE))
library(tidyverse)
library(lubridate)
library(readxl)

eng_complexity_lookup <- read_csv("~/R/R Data/Engineering/MBR Charts/eng_complexity_lookup.csv")
backlog_tons_detail <- read_csv("~/R/R Data/Engineering/MBR Charts/backlog_tons_detail.csv")
eng_backlog <- read_csv("~/R/R Data/Engineering/MBR Charts/eng_backlog.csv")

# create project number field in a given data frame

eng_hours <- eng_complexity_lookup %>%
  group_by(`Order Number`) %>%
  summarise(act_hours = round(sum(`Actual Hours`),2),
            budget_hours = round(sum(`Budget Hours`),2)) %>%
  rename(order_number = `Order Number`)

eng_backlog2 <- eng_backlog %>% 
  mutate(proj_num = str_sub(`Order Number`, 1, 8)) %>%
  select(`Order Number`,
         Region,
         Division,
         `Customer Name`,
         proj_num)

eng_complexity <- eng_complexity_lookup %>% 
  mutate(proj_num = str_sub(`Order Number`, 1, 8)) %>%
  select(`Project Name`,
         Status, 
         `Order Number`,
         `Budget Hours`,
         `Actual Hours`,
         Complexity,
         Division,
         Region,
         proj_num)

no_val <- eng_complexity$`Budget Hours` == 0
eng_complexity$Complexity[no_val] <- "No Engineering Budget"

backlog_w_proj_num <- backlog_tons_detail %>%
  mutate(proj_num = str_sub(`Order Number`, 1, 8))

mat_backlog_w_complex <- backlog_w_proj_num %>%
  filter(Region != "BLA") %>%
  left_join(eng_complexity, by = "proj_num") %>%
  replace_na(list(Complexity = "Parts Order/Buyout - No Eng", `Budget Hours` = 0, `Actual Hours` = 0)) %>%
  rename(division = Division.x, 
         region = Region.x, 
         project_name = `Project Name.x`,
         order_number = `Order Number.x`,
         backlog_dollars = `Backlog Dollars`, 
         margin_dollars = `Margin with Exch Rate`,
         total_tons = `Total Tons`,
         buyout_tons = `Buyout Tons`,
         budget_hours = `Budget Hours`,
         actual_hours = `Actual Hours`) %>%
  select(division,
         region,
         `Project Manager`,
         `Customer Name`,
         project_name,
         order_number,
         backlog_dollars,
         margin_dollars,
         total_tons,
         buyout_tons,
         Bucket,
         `Record Type`,
         `Transaction Type`,
         `Ordered Date`,
         Status,
         Complexity) %>%
  left_join(eng_hours, by = "order_number")
  

write.csv(mat_backlog_w_complex, "~/R/R Data/S&OP/mat_backlog_w_complex.csv")

  
