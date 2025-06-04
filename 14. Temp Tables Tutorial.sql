-- Temporary Tables

CREATE TEMPORARY TABLE temp_table
(first_name varchar(50),
last_name varchar(50),
favourite_movie varchar(100)
);

INSERT INTO temp_table
VALUES('Matthew','Le','Avengers Endgame');

SELECT * 
FROM temp_table;





SELECT *
FROM employee_salary;

CREATE TEMPORARY TABLE salary_over_50k
SELECT * 
FROM employee_salary 
WHERE salary >= 50000;

SELECT *
FROM salary_over_50k;



