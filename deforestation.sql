/*
CREATE VIEW
*/
CREATE OR REPLACE VIEW deforest AS
SELECT r.country_name country, r.country_code code, f.year, f.forest_area_sqkm forest_area,
l.total_area_sq_mi total_area, r.region, r.income_group,
(f.forest_area_sqkm/(l.total_area_sq_mi*2.59))*100::NUMERIC AS percent_forest_area
FROM forest_area f
JOIN land_area l
ON f.country_code = l.country_code
JOIN regions r
ON l.country_code = r.country_code
WHERE f.year = l.year AND l.country_code = r.country_code AND f.country_code = l.country_code
GROUP BY 1, 2, 3, 4, 5, 6, 7

/*
GLOBAL
*/
1.* What was the total forest area (in sq km) of the world in 1990?
SELECT *
FROM forest_area
WHERE country_name = 'World' AND year = 1990;

2.* What was the total forest area (in sq km) of the world in 2016?
SELECT *
FROM forest_area
WHERE country_name = 'World' AND year = 2016;

3.* What was the change (in sq km) in the forest area of the world from 1990 to 2016?
WITH f2016 AS (
	SELECT country_name, forest_area_sqkm
	FROM forest_area
	WHERE country_name = 'World' AND year = 2016),

	f1990 AS (
	SELECT country_name, forest_area_sqkm
	FROM forest_area
	WHERE country_name = 'World' AND year = 1990)
SELECT (f1990.forest_area_sqkm - f2016.forest_area_sqkm) AS forest_change
FROM f2016
JOIN f1990
ON f1990.country_name = f2016.country_name;

4.* What was the percent change in forest area of the world between 1990 and 2016?
WITH f2016 AS (
	SELECT country_name, forest_area_sqkm
	FROM forest_area
	WHERE country_name = 'World' AND year = 2016),

	f1990 AS (
	SELECT country_name, forest_area_sqkm
	FROM forest_area
	WHERE country_name = 'World' AND year = 1990)
SELECT ((f1990.forest_area_sqkm - f2016.forest_area_sqkm)/(f1990.forest_area_sqkm))*100 AS percent_change
FROM f2016
JOIN f1990
ON f1990.country_name = f2016.country_name;

5.* If you compare the amount of forest area lost between 1990 and 2016, to which countrys total area in 2016 is it closest to?
SELECT land.country_name, land.total_area_sq_mi*2.59 AS land_area_sqkm,
ABS((land.total_area_sq_mi*2.59)- (SELECT f1990.forest_area_sqkm - f2016.forest_area_sqkm AS forest_change
                                   FROM (SELECT f.country_code, f.forest_area_sqkm
      	                                 FROM forest_area f
                                         WHERE f.country_name = 'World'
              	                         AND f.year = 1990) AS f1990
                                   JOIN (SELECT f.country_code, f.forest_area_sqkm
      		                             FROM forest_area f
                                         WHERE f.country_name = 'World'
              	                          AND f.year = 2016) AS f2016
                                   ON f1990.country_code = f2016.country_code)) AS forest_change_land_area_diff
    FROM land_area land
    WHERE land.year = 2016
    ORDER BY 3
    LIMIT 1;

/*
REGIONAL
*/
1.* Create a table that shows the Regions and their percent forest area in 1990 and 2016.
DROP VIEW IF EXISTS regionals;
CREATE OR REPLACE VIEW regionals AS
SELECT r.region, l.year, SUM(l.total_area_sq_mi*2.59) land_area_sqkm,
SUM(f.forest_area_sqkm) forest_area, ROUND(100*(SUM(f.forest_area_sqkm)/SUM(l.total_area_sq_mi*2.59))::NUMERIC, 2) AS percent_forest
FROM land_area l
JOIN forest_area f
ON l.country_code = f.country_code AND l.year = f.year
JOIN regions r
ON r.country_code = f.country_code
GROUP BY 1, 2
ORDER BY 1;

2.* What was the percent forest of the entire world in 2016?
SELECT *
FROM regionals
WHERE region = 'World' AND year = 2016;

3.* Which region had the HIGHEST percent forest in 2016, and which had the LOWEST, to 2 decimal places?
SELECT region, MAX(percent_forest) AS max
FROM regionals
WHERE year = 2016
GROUP BY 1
ORDER BY 2 DESC;

4.* What was the percent forest of the entire world in 1990?
SELECT region, forest_area, percent_forest
FROM regionals
WHERE region = 'World' AND year = 1990;

5.* Which region had the HIGHEST percent forest in 1990, and which had the LOWEST, to 2 decimal places?
SELECT region, MAX(percent_forest) AS max
FROM regionals
WHERE year = 1990
GROUP BY 1
ORDER BY 2 DESC;

6.* Based on the table you created, which regions of the world DECREASED in forest area from 1990 to 2016?
WITH pf1990 AS (
	SELECT region, percent_forest pf
	FROM regionals
	WHERE year = 1990),
	pf2016 AS (
	SELECT region, percent_forest pf
	FROM regionals
	WHERE year = 2016)
SELECT pf1990.region, pf1990.pf percent1990, pf2016.pf percent2016
FROM pf1990
JOIN pf2016
ON pf1990.region = pf2016.region
WHERE pf2016.pf < pf1990.pf;

/*
COUNTRY
*/
1.* Which 5 countries saw the largest amount decrease in forest area from 1990 to 2016?
	What was the difference in forest area for each?
WITH ctr1990 AS (
	SELECT country, forest_area
	FROM deforest
	WHERE year = 1990),
	ctr2016 AS (
	SELECT country, forest_area
	FROM deforest
	WHERE year = 2016)
SELECT ctr1990.country, ROUND((ctr1990.forest_area - ctr2016.forest_area), 2) AS area_change
FROM ctr1990
JOIN ctr2016
ON ctr1990.country = ctr2016.country
WHERE ctr2016.forest_area < ctr1990.forest_area AND ctr1990.country != 'World'
ORDER BY 2 DESC
LIMIT 5;

2.* Which 5 countries saw the largest percent decrease in forest area from 1990 to 2016?
	What was the percent change to 2 decimal places for each?
WITH pf1990 AS (
	SELECT country_name, forest_area_sqkm forest_area
	FROM forest_area
	WHERE year = 1990),
	pf2016 AS (
	SELECT country_name, forest_area_sqkm forest_area
	FROM forest_area
	WHERE year = 2016)
SELECT pf1990.country_name,
ROUND((100*(pf1990.forest_area - pf2016.forest_area)/pf1990.forest_area)::NUMERIC, 2) AS percent_change
FROM pf1990
JOIN pf2016
ON pf1990.country_name = pf2016.country_name
WHERE pf1990.forest_area IS NOT NULL
AND pf2016.forest_area IS NOT NULL
AND pf2016.forest_area < pf1990.forest_area
AND pf1990.country_name != 'World'
ORDER BY 2 DESC
LIMIT 5;

3.* If countries were grouped by percent forestation in quartiles, which group had the most countries in it in 2016?
SELECT DISTINCT (quartiles), COUNT(country) OVER(PARTITION BY quartiles) AS countries
FROM (
	SELECT country,
	CASE WHEN percent_forest_area <= 25 THEN '1st Quartile'
		 WHEN percent_forest_area > 25 AND percent_forest_area <= 50 THEN '2nd Quartile'
		 WHEN percent_forest_area > 50 AND percent_forest_area <= 75 THEN '3rd Quartile'
		 ELSE '4th Quartile'
	END AS quartiles
	FROM deforest
	WHERE year = 2016 AND percent_forest_area IS NOT NULL) ntiles
ORDER BY 2 DESC;

4.* List all of the countries that were in the 4th quartile (percent forest > 75%) in 2016.
SELECT country, percent_forest_area
FROM deforest
WHERE year = 2016 AND percent_forest_area > 75 AND percent_forest_area <= 100;

5.* How many countries had a percent forestation higher than the United States in 2016?
SELECT COUNT(*)
FROM deforest
WHERE percent_forest_area > (
	SELECT percent_forest_area
	FROM deforest
	WHERE year = 2016 AND code ='USA')
AND year = 2016;
