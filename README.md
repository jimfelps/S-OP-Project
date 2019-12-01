# S-OP-Project
Work on datasets for S&amp;OP project analysis

## Purpose

The idea of an S&OP process seems like more of a business buzz phrase than an actual policy, but once we started to dig into what this process would accomplish, I started to realize that this project could end up being a valuable excercise for the company. The project started with a couple basic requirements:

1. Analyze customer data for the past 6 years and determine if there's a way to segment our customers into a tierred system. We conducted interviews with employees from many different functional areas, as well as the business leaders to determine the most preferred way of segmenting customers. Some of the options included:
 * Revenue
 * Margin
 * Geography
 * Loyalty
 * Stategic (future growth opportunity, earnings potential)
 * Brand
 * Engineering Complexity
 * Other (k-means analysis)
It was determined that the top 4 would be used, with some sort of score for strategic initiative layered in at a later date potentially. Loyalty will be a difficult item to measure, as we don't really know how many customers are purchasing from our competitors. The sop_customer_analysis_3 years file is the work I've put together for our 6 year analysis (don't let the name fool you, we switched from 3 to 6 years of data in the middle of my work).

2. Determine what KPI's the company should be looking at on a regular basis. These KPI's should tell us a story from the beginning of the pipeline (sales) all the way through the end (MFG). Each KPI should indicate some sort of change in business environment or upcoming internal challenge to the business, whether that be softening economic conditions, a change in the mix of building types that the market is demanding (e.g. small, simple buildings to more complex buildings), or a capacity problem in our production teams.

Once we set up the KPI's and set up dashboards to view, the organization will set up short review meetings with a person from each functional area. Prior to these reviews, the S&OP manager will create an itinerary to guide the group through all or some of the KPI's, depending on what the metrics are telling us. Meeting will be kept to under an hour and the output will be a short narrative that will be taken to the ELT meeting, which will be the day after review, as to not have outdated data.

Having a representative from each functional area will help each group understand how each other group within the organization is measured, providing a better understanding of how the organization is performing. They will be able to take this information back to their teams for discussion, allowing the information to organically spread throughout the company. Since the information will be based upon a shared understanding of facts, this should effectively reduce the amount of word-of-mouth anecdotes about business issues that flood the organization currently.

## Data

Historically the organization has kept data on sales/shipments in what's called a margin analysis table. This report includes a lot of data, broken out by HISTORY_DATE, which indicates the accounting period in which we recognized the revenue/cost/variance. 

There are a lot of challenges I faced when cleaning this data. First, the report defaults to the sales region that the customer was set up with at the time the data was written to the table. There are several examples where a customer was set up in, for example, the VWE region, we shipped a portion of their order and recognized they were in the incorrect region, fixed the region and have the remaining records for that order showing a different region. There's also a similar issue of customers set up with one name and changed along the way. Since this analysis only looked down to the brand level, the region issue was not a huge problem, but I was able to pull a modified report that queried the current region assigned to the customer. The customer name difference was a bigger problem because the totals by fiscal year for sales/margin didn't include all data for a particular customer if this was a problem. This was corrected in a similar fashion to the region, by modifying the report to pull the current customer name assigned to the account number.

Another goal of the S&OP team was to get a good understanding of engineering capacity. Our engineering group has an idea of their capacity, but none of it seems to be supported by data. At the very least, the data isn't shared with anyone outside of engineering, which is a problem since we all have access to the same data. More than likely, they are looking at headcount and making some utilization assumptions. At best these are back-of-napkin calculations. Our engineering group has a centralized scheduling software but report writing in this software is...challenging to say the least. The main format for showing the schedule looks like this:

![image of scheduling software](https://github.com/jimfelps/S-OP-Project/blob/master/eng_schedule.png)

The report pulling this data out of the software is a mess as well. I'm not sure exactly what the format is called, but I've referred to it as a nested list, where you can expand/collapse to see summary and detail views. I can clean up this format pretty easily with R, but then found another issue. I worked on getting this report into a tidy format, but part of the problem is that each line for individuals still only shows total hours for a date range rather than one line for each order/employee/date worked. I wasn't sure how to correct with an R function. I need some sort of pivot_wider function that looks at the min/max dates within the date vectors to determine how wide to go. The function would also need to skip weekends and holidays. This is on the to do list.