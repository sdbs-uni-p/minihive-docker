-- We have to enable dynamic partitions
SET hive.exec.dynamic.partition.mode=nonstrict;

-- Create partitioned table.
CREATE TABLE numbersLetters (number INT)
PARTITIONED BY (letter STRING);

-- Fill with data
INSERT OVERWRITE TABLE numbersLetters
PARTITION(letter)
SELECT number,letter FROM numbers ;

-- Partitioning
EXPLAIN SELECT * FROM numbers WHERE letter='a';
EXPLAIN SELECT * FROM numbersLetters WHERE letter='a';

SELECT letter, COUNT(*)
FROM numbersLetters
GROUP BY letter;

-- Create partitioned table.
CREATE TABLE numbersMod10 (
	number INT ,
	letter STRING
)
PARTITIONED BY (mod INT) ;

-- Fill with data
INSERT OVERWRITE TABLE numbersMod10 PARTITION(mod)
SELECT number, letter, number % 10 FROM numbers;

SELECT * FROM numbersMod10 WHERE mod = 0 AND number % 100 = 0 ;

-- force buckets
SET hive.enforce.bucketing=true;

CREATE TABLE numbersLettersBuckets (number int)
PARTITIONED BY (letter STRING)
CLUSTERED BY (number) INTO 3 BUCKETS;

INSERT OVERWRITE
TABLE numbersLettersBuckets
PARTITION(letter)
SELECT number, letter FROM numbers;

-- sample data
SELECT * FROM numbersLettersBuckets
TABLESAMPLE(BUCKET 2 OUT OF 3 ON number) sample
WHERE letter = "a";

