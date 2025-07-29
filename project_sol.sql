use yash_db;
select * from projects;

-- --------------------------------------------------------------------------------------------------------------------------------------------------------
##  Question 1
select ProjectID, name, state, country, 
from_unixtime(created_at) as created_date, 
from_unixtime(deadline) as deadline_date, 
from_unixtime(updated_at) as updated_date, 
from_unixtime(state_changed_at) as state_changed_date, 
from_unixtime(launched_at) as launched_date from projects;

-- --------------------------------------------------------------------------------------------------------------------------------------------------------

## Question 2
SET @@cte_max_recursion_depth = 5000;
with recursive calendar as (
select date(from_unixtime((select min(created_at) from projects))) as cal_date
union all
select date_add(cal_date, interval 1 day)
from calendar
where cal_date < date(from_unixtime((select MAX(created_at) from projects)))
)
select 
    cal_date as Date,
    Year(cal_date) as Year,
    Month(cal_date) as MonthNo,
    monthname(cal_date) as MonthFullName,
    Quarter(cal_date) as Quarter,
    Date_format(cal_date, '%Y-%b') as YearMonth,
    Weekday(cal_date) + 1 as WeekdayNo, -- 1=Monday, 7=Sunday
    Dayname(cal_date) as WeekdayName,
    
    ## Financial Month Calculation (April = FM1, March = FM12)
    CASE 
        when month(cal_date) = 4 then 'FM1'
        when month(cal_date) = 5 then 'FM2'
        when month(cal_date) = 6 then 'FM3'
		when month(cal_date) = 7 then 'FM4'
		when month(cal_date) = 8 then 'FM5'
        when month(cal_date) = 9 then 'FM6'
        when month(cal_date) = 10 then 'FM7'
        when month(cal_date) = 11 then 'FM8'
        when month(cal_date) = 12 then 'FM9'
        when month(cal_date) = 1 then 'FM10'
        When month(cal_date) = 2 then 'FM11'
        when month(cal_date) = 3 then 'FM12'
    end as  FinancialMonth,
    
    ##Financial Quarter Calculation
    case 
        when month(cal_date) between 4 AND 6 then 'FQ-1'
        when month(cal_date) between 7 AND 9 then 'FQ-2'
        when month(cal_date) between 10 AND 12 then 'FQ-3'
        when month(cal_date) between 1 AND 3 then 'FQ-4'
    end as  FinancialQuarter
    from calendar;

    -- --------------------------------------------------------------------------------------------------------------------------------------------------------
    
    ## Question 4
    SELECT ProjectID,name,country,currency,goal, 
    case 
        when currency = 'EUR' then goal * 1.1         ## 1 EUR = 1.1 USD
        when currency = 'GBP' then goal * 1.3         ## 1 GBP = 1.3 USD
        when currency = 'INR' then goal * 0.012       ## 1 INR = 0.012 USD
        when currency = 'AUD' then goal * 0.65        ## 1 AUD = 0.65 USD
        when currency = 'CAD' then goal * 0.75        ## 1 CAD = 0.75 USD
        else goal end as goal_in_usd from projects;

-- --------------------------------------------------------------------------------------------------------------------------------------------------------

## 	Question 5
## Total Number of Projects Based on Outcome
select state, count(*) as total_projects from projects
group by state;


## Total Number of Projects Based on Locations
select state, count(*) as total_projects from crowdfunding_location
group by state;


## Total Number of Projects Based on Category
select name, count(*) as total_projects from crowdfunding_category
group by name;


## Total Number of Projects Created by Year, Quarter, and Month
select 
    Year(from_unixtime(created_at)) as Year,
    Quarter(from_unixtime(created_at)) as Quarter,
    Month(from_unixtime(created_at)) as Month
from projects group by Year, Quarter, Month order by Year DESC, Quarter DESC, Month DESC;

-- ------------------------------------------------------------------------------------------------------------------------------------------------------

##Question6##

# No of Successful projects
SELECT 
    state, 
    COUNT(*) AS successful_project_count
FROM projects
WHERE state = 'successful'
GROUP BY state;

#6.1 Total Amount raised
SELECT 
    state,
    COUNT(*) AS successful_projects,
    SUM(usd_pledged) AS total_amount_raised
    from projects
    where state = 'successful'
    group by state;
    
#6.2 NO of Backers
SELECT 
    state,
    COUNT(*) AS successful_projects,
    count(backers_count) AS No_of_backers
    from projects
    where state = 'successful'
    group by state;
    
#6.3 Avg No of days for successful projects
SELECT 
    state,
    COUNT(*) AS successful_projects,
    AVG(DATEDIFF(deadline_date, created_date)) AS avg_days_to_success
    from projects
    where state = 'successful'
    group by state;
    
    
## 7.1TOP SUCCESSFUL PROJECTS BASED ON BACKERS COUNT##
    SELECT 
    ProjectID, 
    name AS project_name, 
    backers_count,
    state
FROM projects
WHERE state = 'successful'
ORDER BY backers_count DESC
LIMIT 10;

## 7.2TOP SUCCESSFUL PROJECTS BASED ON AMOUNT_RAISED##
 SELECT 
    ProjectID, 
    name AS project_name, 
    usd_pledged,
    state
FROM projects
WHERE state = 'successful'
ORDER BY usd_pledged DESC
LIMIT 10;

#8.1 PERCENTAGE OF OVERALL PROJECTS#
SELECT 
    state, 
    COUNT(*) AS project_count, 
    ROUND((COUNT(*) * 100.0) / (SELECT COUNT(*) FROM projects), 2) AS percentage
FROM projects
GROUP BY state
ORDER BY percentage DESC;

#8.2 PERCENTAGE OF SUCCESSFUL PROJECTS BASED ON CATEGORY#
SELECT 
    c.name AS category_name,
    COUNT(CASE WHEN p.state = 'successful' THEN p.ProjectID ELSE NULL END) AS successful_projects, 
    COUNT(*) AS total_projects_in_category,
    ROUND((COUNT(CASE WHEN p.state = 'successful' THEN p.ProjectID ELSE NULL END) * 100.0) / COUNT(*), 2) AS success_percentage
FROM 
    projects p
JOIN 
    `crowdfunding_category 1(category)` c ON p.category_id = c.id
GROUP BY 
    c.name
ORDER BY 
    success_percentage DESC;
    
#8.3 PERCENTAGE OF SUCCESSFUL PROJECTS BASED ON LOCATION #
SELECT 
    l.name AS location_name,
    COUNT(CASE WHEN p.state = 'successful' THEN p.ProjectID ELSE NULL END) AS successful_projects, 
    COUNT(*) AS total_projects_in_location,
    ROUND((COUNT(CASE WHEN p.state = 'successful' THEN p.ProjectID ELSE NULL END) * 100.0) / COUNT(*), 2) AS success_percentage
FROM 
    projects p
JOIN 
    `crowdfunding_location 1(sheet1)` l ON p.location_id = l.id  
GROUP BY 
    l.name
ORDER BY 
    success_percentage DESC;

#8.4 PERCENTAGE OF SUCCESSFUL PORJECTS BASED YEAR MONTH QUARTER #
SELECT
    c.year,
    c.month_name,
    c.quarter,
    COUNT(CASE WHEN p.state = 'successful' THEN p.ProjectID ELSE NULL END) AS successful_projects,
    COUNT(*) AS total_projects,
    ROUND((COUNT(CASE WHEN p.state = 'successful' THEN p.ProjectID ELSE NULL END) * 100.0) / COUNT(*), 2) AS success_percentage
FROM
    projects p
JOIN
    calendar c ON p.created_date=c.calendar_date
GROUP BY
    c.year, c.month_name, c.quarter
ORDER BY
    c.year, c.month_name, c.quarter;

# 8. PERCENTAGE OF SUCCESSFUL PROJECTS BASED ON GOAL RANGE#
WITH GoalRange AS (
    SELECT 
        ProjectID,
        CASE
            WHEN goal BETWEEN 0 AND 1000 THEN '0-1k'
            WHEN goal BETWEEN 1001 AND 5000 THEN '1k-5k'
            WHEN goal BETWEEN 5001 AND 10000 THEN '5k-10k'
            WHEN goal BETWEEN 10001 AND 50000 THEN '10k-50k'
            WHEN goal BETWEEN 50001 AND 100000 THEN '50k-100k'
            ELSE '100k+'
        END AS goal_range
    FROM projects
)
SELECT 
    gr.goal_range,
    COUNT(CASE WHEN p.state = 'successful' THEN p.ProjectID ELSE NULL END) AS successful_projects,
    COUNT(*) AS total_projects,
    ROUND((COUNT(CASE WHEN p.state = 'successful' THEN p.ProjectID ELSE NULL END) * 100.0) / COUNT(*), 2) AS success_percentage
FROM 
    projects p
JOIN 
    GoalRange gr ON p.ProjectID = gr.ProjectID
GROUP BY 
    gr.goal_range
ORDER BY 
    success_percentage DESC
LIMIT 10;
