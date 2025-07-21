
SELECT *
FROM [SQL Portfolio]..CovidVaccinations

order by 3,4

--likelihood of dying if infected in ur area地方感染死亡率
SELECT location, date, total_cases, total_deaths, (CAST(total_deaths AS FLOAT) / NULLIF(CAST(total_cases AS FLOAT), 0)) * 100 AS death_percentage
FROM [SQL Portfolio]..CovidDeaths
WHERE location like '%china%'
order by 1,2

--Infected percentage人群感染率
SELECT location, population, total_cases, population, (CAST(total_cases AS FLOAT) / NULLIF(CAST(population AS FLOAT), 0)) * 100 AS infected_percentage
FROM [SQL Portfolio]..CovidDeaths
WHERE location like '%china%'
order by 1,2

--地区中最高感染率
SELECT location, population , MAX(total_cases)AS highest_infection_count,
	MAX((CAST(total_cases AS FLOAT) / NULLIF(CAST(population AS FLOAT), 0))) * 100 AS highest_infected_percentage
FROM [SQL Portfolio]..CovidDeaths
--WHERE location like '%china%'
GROUP BY location, population
order by highest_infected_percentage desc

--最高死亡人数地区Countries with highest death count
SELECT location, MAX(cast(total_deaths as float))AS total_death_count
FROM [SQL Portfolio]..CovidDeaths
--WHERE location like '%china%'
where continent is not null
GROUP BY location
order by total_death_count desc

--以州为单位查看break down into continent
SELECT continent, MAX(cast(total_deaths as int))AS total_death_count
FROM [SQL Portfolio]..CovidDeaths
--WHERE location like '%china%'
GROUP BY continent
order by total_death_count desc


SELECT SUM(cast(new_cases as int))as total_cases, 
	SUM(cast(new_deaths as int)) as total_deaths,
	SUM(cast(new_deaths as int))*100/SUM(cast(new_cases as int)) as death_percentage
FROM [SQL Portfolio]..CovidDeaths
WHERE continent is not null
--WHERE location like '%china%'
--GROUP BY continent
order by 1,2

--USE CTE
With PopvsVac (continent,location,date, population, new_vaccinations, RollingPeopleVaccinated)
as
(
SELECT dea.location,dea.date,dea.continent,dea.population,vac.new_vaccinations,
	SUM(cast(vac.new_vaccinations as bigint)) OVER (PARTITION BY dea.location order by dea.location,dea.date) AS RollingPeopleVaccinated
FROM [SQL Portfolio]..CovidDeaths dea
JOIN [SQL Portfolio]..CovidVaccinations vac
ON dea.location=vac.location
and dea.date=vac.date
--order by 1,2
)
SELECT *,
       (CAST(RollingPeopleVaccinated AS float) / NULLIF(CAST(population AS float), 0)) * 100 AS vaccination_rate
FROM PopvsVac

--创建临时表USE TEMP TABLE
DROP TABLE if exists #percentpopulationVaccinated;
CREATE TABLE #percentpopulationVaccinated
(
    continent nvarchar(255),
    location nvarchar(255),
    date datetime,
    population numeric,
    new_vaccinations numeric,
    RollingPeopleVaccinated numeric
);
-- 插入处理后的数据
INSERT INTO #percentpopulationVaccinated
SELECT 
    dea.continent,
    dea.location,
    TRY_CAST(dea.date AS datetime) AS date,
    TRY_CAST(dea.population AS numeric) AS population,
    TRY_CAST(vac.new_vaccinations AS numeric) AS new_vaccinations,
    SUM(TRY_CAST(vac.new_vaccinations AS bigint)) 
        OVER (PARTITION BY dea.location ORDER BY dea.location, TRY_CAST(dea.date AS datetime)) AS RollingPeopleVaccinated
FROM [SQL Portfolio]..CovidDeaths dea
JOIN [SQL Portfolio]..CovidVaccinations vac
    ON dea.location = vac.location
   AND TRY_CAST(dea.date AS datetime) = TRY_CAST(vac.date AS datetime);
-- 查询结果并计算接种率
SELECT *,
       (CAST(RollingPeopleVaccinated AS float) / NULLIF(CAST(population AS float), 0)) * 100 AS vaccination_rate
FROM #percentpopulationVaccinated;


--创建视图
USE [SQL Portfolio]; 
GO
Create View percentpopulationVaccinated as 
SELECT dea.location,dea.date,dea.continent,dea.population,vac.new_vaccinations,
	SUM(cast(vac.new_vaccinations as bigint)) OVER (PARTITION BY dea.location order by dea.location,dea.date) AS RollingPeopleVaccinated
FROM [SQL Portfolio]..CovidDeaths dea
JOIN [SQL Portfolio]..CovidVaccinations vac
ON dea.location=vac.location
and dea.date=vac.date
--order by 1,2

SELECT *
FROM percentpopulationVaccinated