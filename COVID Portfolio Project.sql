/*

COVID 19 Data Exploration

Skills used: Joins, CTE's, Temp Tables, Window Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

SELECT *
FROM [Portfolio Project]..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3, 4;


-- Select the data that we are going to be starting with

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM [Portfolio Project]..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1, 2;


-- Total Cases vs Total Deaths
-- Shows the likelihood of dying if you contract covid in your country

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM [Portfolio Project]..CovidDeaths
WHERE location LIKE 'australia'
AND continent IS NOT NULL
ORDER BY 1, 2;


-- Total Cases vs Population
-- Shows what percentage of the population is infected with covid

SELECT location, date, population, total_cases, (total_cases/population)*100 AS PercentPopulationInfected
FROM [Portfolio Project]..CovidDeaths
WHERE location LIKE 'australia'
ORDER BY 1, 2;


-- Countries with the highest infection rate compared to population

SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population))*100 AS PercentPopulationInfected
FROM [Portfolio Project]..CovidDeaths
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC;


SELECT location, population, date, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population))*100 AS PercentPopulationInfected
FROM [Portfolio Project]..CovidDeaths
GROUP BY location, population, date
ORDER BY PercentPopulationInfected DESC;


-- Countries with the highest death count per population

SELECT location, MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM [Portfolio Project]..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC;



-- BREAKING THINGS DOWN BY CONTINENT

-- Showing continents with the highest death count per population

SELECT continent, MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM [Portfolio Project]..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC;


SELECT location, SUM(CAST(new_deaths AS INT)) AS TotalDeathCount
FROM [Portfolio Project]..CovidDeaths
WHERE continent IS NULL
AND location NOT IN ('World', 'European Union', 'International')
GROUP BY location
ORDER BY TotalDeathCount DESC;


-- GLOBAL NUMBERS

SELECT date, SUM(new_cases) AS Total_Cases, 
SUM(CAST(new_deaths AS INT)) AS Total_Deaths, 
SUM(CAST(new_deaths AS INT))/SUM(new_cases)*100 AS DeathPerentage
FROM [Portfolio Project]..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY  date
ORDER BY 1, 2;


SELECT SUM(new_cases) AS Total_Cases, 
SUM(CAST(new_deaths AS INT)) AS Total_Deaths, 
SUM(CAST(new_deaths AS INT))/SUM(new_cases)*100 AS DeathPerentage
FROM [Portfolio Project]..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY Total_Cases;


-- Total Population vs Vaccinations
-- Shows the percentage of the population that has received at least one covid vaccine

SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations,
SUM(CONVERT(INT, cv.new_vaccinations)) OVER(PARTITION BY cd.location ORDER BY cd.location, cd.date) AS RollingPeopleVaccinated
-- (RollingPeopleVaccinated/population)*100
FROM [Portfolio Project]..CovidDeaths AS cd
INNER JOIN [Portfolio Project]..CovidVaccinations AS cv
	ON cd.location = cv.location
	AND cd.date = cv.date
WHERE cd.continent IS NOT NULL
ORDER BY 2, 3;


-- Using CTE to perform calculation on partition by in previous query

WITH PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
AS
(
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations,
SUM(CONVERT(INT, cv.new_vaccinations)) OVER(PARTITION BY cd.location ORDER BY cd.location, cd.date) AS RollingPeopleVaccinated
-- (RollingPeopleVaccinated/population)*100
FROM [Portfolio Project]..CovidDeaths AS cd
INNER JOIN [Portfolio Project]..CovidVaccinations AS cv
	ON cd.location = cv.location
	AND cd.date = cv.date
WHERE cd.continent IS NOT NULL
--ORDER BY 2, 3
)
SELECT *, (RollingPeopleVaccinated/population)*100
FROM PopvsVac;



-- Using temp table to perform calculation on partition by in previous query

DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)


INSERT INTO #PercentPopulationVaccinated
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations,
SUM(CONVERT(INT, cv.new_vaccinations)) OVER(PARTITION BY cd.location ORDER BY cd.location, cd.date) AS RollingPeopleVaccinated
-- (RollingPeopleVaccinated/population)*100
FROM [Portfolio Project]..CovidDeaths AS cd
INNER JOIN [Portfolio Project]..CovidVaccinations AS cv
	ON cd.location = cv.location
	AND cd.date = cv.date
-- WHERE cd.continent IS NOT NULL
--ORDER BY cd.location, cd.date

SELECT *, (RollingPeopleVaccinated/population)*100
FROM #PercentPopulationVaccinated;




-- Creating view to store data for later visualisations

CREATE VIEW PercentPopulationVaccinated AS
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations,
SUM(CONVERT(INT, cv.new_vaccinations)) OVER(PARTITION BY cd.location ORDER BY cd.location, cd.date) AS RollingPeopleVaccinated
-- (RollingPeopleVaccinated/population)*100
FROM [Portfolio Project]..CovidDeaths AS cd
INNER JOIN [Portfolio Project]..CovidVaccinations AS cv
	ON cd.location = cv.location
	AND cd.date = cv.date
WHERE cd.continent IS NOT NULL;

