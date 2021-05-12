set hive.exec.dynamic.partition.mode = nonstrict;
set hive.cli.print.header=true;
set hive.exec.mode.local.auto = true;

drop table students;
create table students (
    sid int,
    s_name string,
    street string,
    city string,
    age int,
    courses array< struct<c_id: int, c_name: string, prof_name: string, credits: int> >
)
row format delimited
fields terminated by ','
collection items terminated by '|'
map keys terminated by '\;' ;

load data local inpath '/home/minihive/hive/students.csv' overwrite into table students;

