-- Portofolio- Project 01- Covid Data Exploration using SQL -MSSQL SERVER
-------------------------------------------------------------------------------------------------
SELECT *
FROM MyPortfolioProjects.dbo.CovidDeaths;

SELECT *
FROM MyPortfolioProjects.dbo.CovidVaccinations;

SELECT *
FROM MyPortfolioProjects..CovidDeaths
WHERE continent IS NOT NULL -- as it includes continent info in the location when continent = NULL
ORDER BY continent,location, date;

--SELECT *
--FROM MyPortfolioProjects..CovidVaccinations
--ORDER BY location,date

SELECT location, date, total_cases,new_cases,total_deaths,population
FROM MyPortfolioProjects..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY location,date;

--SELECT DISTINCT location
--FROM  MyPortfolioProjects..CovidDeaths
--ORDER BY location;

--First let's check the datatypes of each column
SELECT 
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'CovidDeaths'

--Since the new deaths & total deaths are 'nvarchar' we need to convert into 'integer' 

--Checking  after conversion if any values becomes null 
--if it returns any rows, alternation in this way is not possible
SELECT *
FROM CovidDeaths
WHERE CAST(total_deaths AS int) IS NULL and total_deaths IS NOT NULL

--since no values becomes null, let's go with that.
ALTER TABLE MyPortfolioProjects.dbo.CovidDeaths
ALTER COLUMN total_deaths int

-- Applying for new_deaths column as well
--verify the column
SELECT *
FROM CovidDeaths
WHERE CAST(new_deaths AS int) IS NULL and new_deaths IS NOT NULL;

--Alter data type
ALTER TABLE MyPortfolioProjects.dbo.CovidDeaths
ALTER COLUMN new_deaths int;

---------------------------------------------------------------------------------------------------------------------------------
-- Total Deaths vs Total Cases
-- Check likelihood of dying if you contract COVID in your country

SELECT location, continent, date, total_cases,new_cases,total_deaths, (total_deaths/NULLIF(total_cases,0))*100 AS 'death_precentage'
FROM MyPortfolioProjects..CovidDeaths
WHERE location like '%states%' AND continent IS NOT NULL
ORDER BY location,date;

------------------------------------------------------------------------------------------------------------------------------------
-- Total Cases vs Population
-- Shows  what precentage of population was infected with COVID

SELECT location, date, population,total_cases, (total_cases/NULLIF(population,0))*100 AS 'infected_precentage'
FROM MyPortfolioProjects..CovidDeaths
WHERE location like '%states' AND continent IS NOT NULL
ORDER BY location,date;

------------------------------------------------------------------------------------------------------------------------------------
--Shows highest infection rate compared to population

SELECT location, population, MAX(total_cases) AS 'highest_total_cases', (MAX(total_cases)/NULLIF(population,0))*100 AS 'higest_infection_rate_of_country'
FROM MyPortfolioProjects..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location,population
ORDER BY higest_infection_rate_of_country DESC;

------------------------------------------------------------------------------------------------------------------------------------
-- Shows countries of  higest death count compared to population

SELECT DISTINCT *
FROM MyPortfolioProjects..CovidDeaths
WHERE location IN (
					SELECT DISTINCT continent
					FROM CovidDeaths
					WHERE continent IS NOT NULL
					)
ORDER BY location;


-- In location column, continent info is also included. so we need to remove that
SELECT location,MAX(total_deaths) AS 'Highest_Death_Count'
FROM  MyPortfolioProjects..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY Highest_Death_Count DESC; 

-- Show the highest death count based on continent

SELECT continent,MAX(total_deaths) AS 'Highest_Death_Count'
FROM  MyPortfolioProjects..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY Highest_Death_Count DESC;  -- this doesn't give correct info (according to the dataset we have)

-- this way give correct info
SELECT location, MAX(total_deaths) AS 'Highest_Death_Count'
FROM MyPortfolioProjects..CovidDeaths
WHERE continent IS NULL
GROUP BY location
ORDER BY Highest_Death_Count DESC;

------------------------------------------------------------------------------------------------------------------------------------
--Global Numbers

SELECT  *
FROM MyPortfolioProjects..CovidDeaths
WHERE  continent IS NOT NULL
ORDER BY continent,location,date;

-- Showing daily death precentage for all continents
SELECT  date, SUM(new_cases) as 'Total_Cases',SUM(new_deaths)as 'Total_Deaths', (SUM(new_deaths)/NULLIF(SUM(new_cases),0)) * 100 AS 'Daily Death_Precentage'
FROM MyPortfolioProjects..CovidDeaths
WHERE  continent IS NOT NULL
Group by date
ORDER BY date;

-- Showing death precentage for all continents 
SELECT  SUM(new_cases) as 'Total_Cases',SUM(new_deaths)as 'Total_Deaths', (SUM(new_deaths)/NULLIF(SUM(new_cases),0)) * 100 AS 'Death_Precentage'
FROM MyPortfolioProjects..CovidDeaths
WHERE  continent IS NOT NULL;


SELECT *
FROM MyPortfolioProjects..CovidDeaths
ORDER BY continent,location,date;

SELECT *
FROM MyPortfolioProjects..CovidVaccinations
--WHERE continent = 'North America' AND location = 'United States'
ORDER BY continent,location,date;

------------------------------------------------------------------------------------------------------------------------------------
-- Vaccinations vs Total Population (using new_vaccinations instead of total_vaccination)


-- Before casting, we should check the if there is any values are changes after casting
SELECT *
FROM CovidVaccinations vac
WHERE CAST(vac.new_vaccinations AS int) IS NULL and vac.new_vaccinations IS NOT NULL  

---Showing Rolling People Vaccinated  based on location daily
SELECT dea.continent,dea.location,dea.date, dea.population,vac.new_vaccinations,  
	SUM(CAST(vac.new_vaccinations AS INT) ) OVER(PARTITION BY dea.location ORDER BY dea.location,dea.date) AS 'rolling_people_vaccinated '	
FROM MyPortfolioProjects..CovidDeaths dea
INNER JOIN MyPortfolioProjects..CovidVaccinations vac
	ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY dea.continent, dea.location, dea.date;

   
---with CTE, calculating Daily Rolling Vaccinated Precentage based on location
WITH CTE_VacVsPop (continent, location,date, population,new_vaccination,rolling_people_vaccinated)
AS(
	SELECT dea.continent,dea.location,dea.date, dea.population,vac.new_vaccinations, 
			SUM(CONVERT(int,vac.new_vaccinations )) OVER(PARTITION BY dea.location ORDER BY dea.location,dea.date) AS 'rolling_people_vaccinated '	
	FROM MyPortfolioProjects..CovidDeaths dea
	INNER JOIN MyPortfolioProjects..CovidVaccinations vac
		ON dea.location = vac.location AND dea.date = vac.date
	WHERE dea.continent IS NOT NULL
)

SELECT *, (rolling_people_vaccinated/ population) * 100 AS 'rolling_vaccination_precentage'
FROM CTE_VacVsPop;


----with CTE, calculating Total New_Vaccinated_Precentage based on location
WITH CTE_VacVsPop (continent, location, population,Total_new_vaccinations)
AS(
	SELECT dea.continent,dea.location, dea.population,SUM(CAST(vac.new_vaccinations AS int)) as 'Total_new_vaccinations' 	
	FROM MyPortfolioProjects..CovidDeaths dea
	INNER JOIN MyPortfolioProjects..CovidVaccinations vac
		ON dea.location = vac.location AND dea.date = vac.date
	WHERE dea.continent IS NOT NULL
	GROUP BY dea.continent,dea.location,dea.population
)

SELECT  *, (Total_new_vaccinations/ population) * 100 AS 'new_vaccination_precentage'
FROM CTE_VacVsPop
ORDER BY new_vaccination_precentage desc; 

------------------------------------------------------------------------------------------------------------------------------------


--TEMP TABLES

DROP TABLE IF EXISTS #PercentPeopleVaccinated
CREATE TABLE #PercentPeopleVaccinated(
	continent nvarchar(100),
	location nvarchar(100),
	date date,
	population float,
	new_vaccinations int,
	rolling_people_vaccinated int

);

INSERT INTO #PercentPeopleVaccinated
SELECT dea.continent,dea.location,dea.date, dea.population,vac.new_vaccinations, 
	SUM(CAST(vac.new_vaccinations AS INT)) OVER(PARTITION BY dea.location ORDER BY dea.location,dea.date) AS 'rolling_people_vaccinated '	
FROM MyPortfolioProjects..CovidDeaths dea
INNER JOIN MyPortfolioProjects..CovidVaccinations vac
	ON dea.location = vac.location 
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY dea.continent, dea.location, dea.date;

SELECT *
FROM #PercentPeopleVaccinated;

SELECT * , (rolling_people_vaccinated / population) * 100 AS 'rolling_vaccinated_precentage'
FROM #PercentPeopleVaccinated
WHERE location like '%states%'
ORDER BY rolling_vaccinated_precentage DESC;

------------------------------------------------------------------------------------------------------------------------------------
-- VIEWS

CREATE VIEW PercentPeopleVaccinated AS
SELECT dea.continent,dea.location,dea.date, dea.population,vac.new_vaccinations, 
	SUM(CAST(vac.new_vaccinations AS INT)) OVER(PARTITION BY dea.location ORDER BY dea.location,dea.date) AS 'rolling_people_vaccinated '	
FROM MyPortfolioProjects..CovidDeaths dea
INNER JOIN MyPortfolioProjects..CovidVaccinations vac
	ON dea.location = vac.location 
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;

-- access view
SELECT *
FROM PercentPeopleVaccinated;

SELECT *, ([rolling_people_vaccinated ]/population)* 100 AS 'rolling_vaccinated_precentage'
FROM PercentPeopleVaccinated
--WHERE continent = 'Europe'
ORDER BY continent,location;

--END

