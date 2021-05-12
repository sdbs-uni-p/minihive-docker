create table employees (
    name string,
    salary float,
    subordinates
    array <string>,
    deductions map<string, float>,
    address struct<street: string,city: string,state: string,zip: int>
);

load data local inpath '/home/minihive/hive/employees.dat'
overwrite into table employees;
