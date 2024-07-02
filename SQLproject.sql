select *
from portfolioproject..covideaths
order by 3,4

--select *
--from portfolioproject..covidvaccinations
--order by 3,4


-- select data that we are goint to using here

select Region, Confirmed_Cases,Active_Cases,Cured_Discharged,Death
from portfolioproject..covideaths
order by 1,2

-- looking at confirmed cases vs deaths
--shows likelyhood of cases if you con tract covid in our states
select Region,date, Confirmed_Cases,Active_Cases ,[Confirmed_Cases]/nullif([Active_Cases],0)*100 as casespercentage
from portfolioproject..covideaths
where Region like 'delhi'
 order by 1,2
  

  --looking at deaths and cured/discharged
  --shows what percentage of population cured or death

select Region,date,Cured_Discharged,Death ,[Cured_Discharged]/nullif([Death],0)*100 as casespercentage
from portfolioproject..covideaths
--where region  like 'delhi'
 order by 1,2

 --looking at states with highest cure rates compared to death
 select Region,date,MAX(Cured_Discharged) as highestcured, max(Cured_Discharged)/nullif([Death],0)*100 as percentcured
from portfolioproject..covideaths
group by region,date,death
order by 1,2


--showing states with highest death count

select Region, MAX(cast(Death as int)) as totaldeathcount
from portfolioproject..covideaths
WHERE region IS NOT NULL
AND region NOT IN ('world', 'india')
group by region 
order by totaldeathcount desc

-- showing the regions/states with highest death count

select Region, MAX(cast(Death as int)) as maxdeathcount
from portfolioproject..covideaths
WHERE region IS NOT NULL
AND region NOT IN ('world', 'india')
group by region 
order by maxdeathcount desc

--cases registed each day

select date,SUM(Active_cases)as totalcases, sum(cast(death as int)) as totaldeath, 
sum(Active_Cases)/sum(death)*100 as deathpercentage
from portfolioproject..covideaths
where REGION is not null
group by date
 order by totalcases DESC

 -------------------------------------------------------------------------
--looking at active and confirmed cases
SELECT 
    dea.Region,
    dea.Date,
    cast(dea.Confirmed_Cases as bigint)+
   cast( vac.Active_Cases as bigint) AS Confirmed_Cases_Plus_activecases ,
    SUM(cast(dea.Confirmed_Cases as bigint)) OVER (PARTITION BY dea.Region order by vac.region, dea.date) as covidcases
	---(covidcases/confirmed_cases)*100
FROM 
    portfolioproject..covideaths dea
JOIN 
    portfolioproject..covidvaccinations vac
ON 
    dea.Region = vac.Region
    AND dea.Date = vac.Date
WHERE 
    dea.Region IS NOT NULL 
	order by 2,3

	--- use cte

	with activevsconfirmed (region,date,Confirmed_Cases,covidcases)
	as(
SELECT 
    dea.Region,
    dea.Date,
    cast(dea.Confirmed_Cases as bigint)+
   cast( vac.Active_Cases as bigint) AS Confirmed_Cases_Plus_activecases ,
    SUM(cast(dea.Confirmed_Cases as bigint)) OVER (PARTITION BY dea.Region order by vac.region, 
	dea.date) as covidcases
	---(covidcases/confirmed_cases)*100
FROM 
    portfolioproject..covideaths dea
JOIN 
    portfolioproject..covidvaccinations vac
ON 
    dea.Region = vac.Region
    AND dea.Date = vac.Date
WHERE 
    dea.Region IS NOT NULL 
--	order by 2,3
	)
select*, (covidcases/region)*100
from activevsconfirmed

	select*
	from portfolioproject..covidvaccinations
WITH activevsconfirmed AS (
    SELECT 
        dea.Region,
        dea.Date,
        CAST(TRY_CAST(dea.Confirmed_Cases AS BIGINT) AS BIGINT) +
        CAST(TRY_CAST(vac.Active_Cases AS BIGINT) AS BIGINT) AS Confirmed_Cases_Plus_activecases,
        SUM(CAST(TRY_CAST(dea.Confirmed_Cases AS BIGINT) AS BIGINT)) OVER (PARTITION BY dea.Region ORDER BY dea.Date) AS covidcases
    FROM 
        portfolioproject..covideaths dea
    JOIN 
        portfolioproject..covidvaccinations vac
    ON 
        dea.Region = vac.Region
        AND dea.Date = vac.Date
    WHERE 
        dea.Region IS NOT NULL
)
SELECT 
    *,
    CASE 
        WHEN Confirmed_Cases_Plus_activecases = 0 THEN 0
        ELSE (covidcases / Confirmed_Cases_Plus_activecases) * 100
    END AS Percentage
FROM 
    activevsconfirmed;
	

	----------------------------
	--temptable


-- Step 1: Drop the table if it exists and create a new temporary table
DROP TABLE IF EXISTS #percentconfirmedcases;

CREATE TABLE #percentconfirmedcases
(
    region NVARCHAR(255),
    date DATETIME,
    covidcases NUMERIC,
    activevsconfirmed NUMERIC
);

-- Step 2: Define the CTE and insert data into the temporary table
WITH activevsconfirmed AS (
    SELECT 
        dea.Region,
        dea.Date,
        SUM(CAST(TRY_CAST(dea.Confirmed_Cases AS BIGINT) AS BIGINT)) OVER (PARTITION BY dea.Region ORDER BY dea.Date) AS covidcases,
        CAST(TRY_CAST(dea.Confirmed_Cases AS BIGINT) AS BIGINT) + CAST(TRY_CAST(vac.Active_Cases AS BIGINT) AS BIGINT) AS Confirmed_Cases_Plus_activecases
    FROM 
        portfolioproject..covideaths dea
    JOIN 
        portfolioproject..covidvaccinations vac
    ON 
        dea.Region = vac.Region
        AND dea.Date = vac.Date
    WHERE 
        dea.Region IS NOT NULL
)

INSERT INTO #percentconfirmedcases (region, date, covidcases, activevsconfirmed)
SELECT 
    Region,
    Date,
    covidcases,
    Confirmed_Cases_Plus_activecases
FROM 
    activevsconfirmed;

-- Step 3: Select from the temporary table and calculate percentage
SELECT 
    *,
    CASE 
        WHEN activevsconfirmed = 0 THEN 0
        ELSE (covidcases / activevsconfirmed) * 100
    END AS Percentage
FROM 
    #percentconfirmedcases;

	--creatring view to store data for visualisation

	create view percentconfirmedcases  as
	 SELECT 
        dea.Region,
        dea.Date,
        SUM(CAST(TRY_CAST(dea.Confirmed_Cases AS BIGINT) AS BIGINT)) OVER (PARTITION BY dea.Region ORDER BY dea.Date) AS covidcases,
        CAST(TRY_CAST(dea.Confirmed_Cases AS BIGINT) AS BIGINT) + CAST(TRY_CAST(vac.Active_Cases AS BIGINT) AS BIGINT) AS Confirmed_Cases_Plus_activecases
    FROM 
        portfolioproject..covideaths dea
    JOIN 
        portfolioproject..covidvaccinations vac
    ON 
        dea.Region = vac.Region
        AND dea.Date = vac.Date
    WHERE 
        dea.Region IS NOT NULL


		select *
		from percentconfirmedcases

		-- view casespercentagedelhi
		create view casespercentagedelhi as
		select Region,date, Confirmed_Cases,Active_Cases ,[Confirmed_Cases]/nullif([Active_Cases],0)*100 as casespercentage
from portfolioproject..covideaths
where Region like 'delhi'
 --order by 1,2

 select*
 from casespercentagedelhi
  
  -- view totaldeath
  create view totaldeath as
  select Region, MAX(cast(Death as int)) as totaldeathcount
from portfolioproject..covideaths
WHERE region IS NOT NULL
AND region NOT IN ('world', 'india')
group by region 

select *
from totaldeath