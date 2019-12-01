library(tidyverse)
ma_table_201811_201910 <- read_csv("~/R/R Data/S&OP/ma_table_201811_201910/ma_table_201811_201910.csv", 
                                   col_types = cols(ORDER_NUMBER = col_character()))

shipp_tons <- read_csv("~/R/R Data/S&OP/customer_analysis_3_years/shipp_tons.csv", 
                       col_types = cols(ORDER_NUMBER = col_character()))


ma_table_last_12 <- ma_table_201811_201910 %>%
  select(ORDER_NUMBER,CUSTOMER_NAME, BILLED_AMOUNT, COGS_AMOUNT, PUR_VAR_ACCT, CUSTOMER_NUMBER, DIVISION, REGION, HISTORY_DATE) %>%
  left_join(shipp_tons, by = c("ORDER_NUMBER" = "ORDER_NUMBER")) %>%
  replace_na(list(total_tons = 0, buyout_tons = 0, bbna_tons = 0)) %>%
  group_by(DIVISION, CUSTOMER_NAME, CUSTOMER_NUMBER, HISTORY_DATE) %>%
  summarise(revenue = round(sum(BILLED_AMOUNT),2),
            mat_cost = round(sum(COGS_AMOUNT),2),
            ppv = round(sum(PUR_VAR_ACCT),2),
            total_cost = mat_cost + ppv,
            margin = revenue - total_cost,
            total_tons = round(sum(total_tons),2),
            buyout_tons = round(sum(buyout_tons),2),
            bbna_tons = round(sum(bbna_tons),2))

ma_table_spread <- ma_table_last_12 %>%
  pivot_wider(names_from = HISTORY_DATE, values_from = c(revenue, margin, total_tons)) %>%
  replace(.,is.na(.),0)

write.csv(ma_table_last_12, "~/R/R Data/S&OP/ma_table_201811_201910/ma_table_last_12.csv")
write.csv(ma_table_spread, "~/R/R Data/S&OP/ma_table_201811_201910/ma_table_spread.csv")

# testing to see if all costs are in
#View(ma_table_last_12 %>%
#       group_by(HISTORY_DATE, DIVISION) %>%
#       summarise(revenue = round(sum(revenue),2),
#                 margin = sum(margin),
#                 margin_pct = margin/revenue))

View(ma_table_201811_201910 %>%
  replace_na(list(PUR_VAR_ACCT = 0)) %>%
  group_by(ORDER_NUMBER) %>%
  summarise(variance = round(sum(PUR_VAR_ACCT),2)))

test1 <- ma_table_201811_201910 %>%
  filter(ORDER_NUMBER == 1803252101)

write.csv(test1, "~/R/R Data/S&OP/ma_table_201811_201910/test1.csv")
