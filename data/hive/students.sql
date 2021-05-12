
SELECT DISTINCT course.c_id, course.c_name
FROM students
LATERAL VIEW explode(courses) t1 AS course
WHERE city = 'Passau';

