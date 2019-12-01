rm(list = ls(all.names = TRUE))

library(tidyverse)
library(lubridate)
library(readxl)

region_schedule <- read_excel("~/R/R Data/S&OP/region_schedule.xlsx", 
                              col_types = c("skip", "text", "text", 
                                            "text", "text", "text", "text", "text", 
                                            "text", "text", "text", "text", "text", 
                                            "text", "numeric", "numeric", "numeric", 
                                            "numeric", "numeric"), skip = 5)
month <- read_excel("~/R/R Data/S&OP/month.xlsx")

regional_schedule_w_order <- region_schedule %>%
  fill(Order,
       `Project Type`,
       Builder,
       `Project Manager`,
       `Improvement Hot List`,
       `Planned Tons`,
       `Scheduled Hours`) %>%
  filter(!is.na(Cell)) %>%
  mutate(start_month = str_sub(`Plan Start`,1,3),
         start_day = str_sub(`Plan Start`,5,6),
         start_year = str_sub(`Plan Start`,8,11),
         end_month = str_sub(`Plan Complete`,1,3),
         end_day = str_sub(`Plan Complete`,5,6),
         end_year = str_sub(`Plan Complete`,8,11)) %>%
  left_join(month, by = c("start_month" = "Month")) %>%
  left_join(month, by = c("end_month" = "Month")) %>%
  select(Resource,
         Order,
         Cell,
         Task,
         `Project Type`,
         Builder,
         `Project Name`,
         `Project Manager`,
         `Improvement Hot List`,
         `Emp. Id`,
         `Billable Hrs`,
         `Planned Tons`,
         Number.x,
         start_day,
         start_year,
         Number.y,
         end_day,
         end_year) %>%
  rename("start_month" = "Number.x",
         "end_month" = "Number.y") %>%
  mutate(start_date = str_c(start_year, start_month, start_day, sep = "/"),
         end_date = str_c(end_year, end_month, end_day, sep = "/")) %>%
  mutate(start_date = ymd(start_date),
         end_date = ymd(end_date))

write.csv(regional_schedule_w_order, "~/R/R Data/S&OP/regional_schedule_w_order.csv")

## work from last night using pivot_longer. several columns are imported as characters because the 
## project starts and ends on the same day. need to update table and re-import

wide_regional_schedule <- read_csv("~/R/R Data/S&OP/regional_schedule_w_order.csv", 
                                      col_types = cols(X1 = col_skip()), skip = 4)

regional_schedule_spread <- read_excel("~/R/R Data/S&OP/regional_schedule_spread.xlsx", 
                                       sheet = "regional_schedule_w_order", 
                                       skip = 4)

long_regional_schedule <- regional_schedule_spread %>%
  pivot_longer(cols = starts_with("hours_"),
               names_to = "date",
               names_prefix = "hours_",
               values_to = "hours") %>%
  filter(hours != 0) %>%
  mutate(date_worked = mdy(date),
         week_ending_sunday = ceiling_date(date_worked, "week"),
         week_starting_monday = floor_date(date_worked, "week", week_start = 1)) %>%
  select(-date,-...1,-start_month,-start_day,-start_year,-end_day,-end_month,-end_year)

write.csv(long_regional_schedule, "~/R/R Data/S&OP/long_regional_schedule.csv")

long_regional_schedule %>%
  group_by(Cell, week_ending_sunday) %>%
  summarise(Hours = round(sum(hours),2)) %>%
  ggplot(aes(week_ending_sunday,Hours)) + 
  geom_bar(stat = "identity") +
  scale_x_date(breaks = "1 month", labels = scales::date_format("%Y-%b"))
