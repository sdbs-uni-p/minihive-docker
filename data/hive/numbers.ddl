create table numbers (number int, letter string)
row format delimited fields terminated by ',';

load data local inpath '/home/minihive/hive/numbers.csv'
overwrite into table numbers;
