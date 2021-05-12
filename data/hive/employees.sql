-- List all names that have at least one subordinate (do not use a nested query):
SELECT name
FROM employees WHERE size(subordinates) >= 1;

-- List all names that have a boss:
SELECT name
from employees
WHERE employees.name IN (SELECT explode(subordinates) as sub FROM employees);

-- List the names of all employees with all their subordinates. The result
-- should be flat, no nested structure should be contained in the result.
SELECT name, sub
FROM employees LATERAL VIEW explode(subordinates) subTable AS sub;

-- List the rounded net salary of each employee. (net salary = salary -
-- deductions). Remember: Deductions contain a percentage value and not an
-- absolute value.
SELECT name, round(salary * sum(value))
FROM employees LATERAL VIEW explode(deductions) dedTable as key, value
GROUP BY name, salary;

-- List the state, zip-code and the name of the city for all cities starting
-- with ’C’. The result should not contain duplicates.
SELECT DISTINCT address.state, address.zip, address.city
FROM employees
WHERE address.city LIKE "C%";
