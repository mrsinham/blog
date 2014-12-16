+++
date = "2014-12-16T12:18:43+01:00"
tags = ["sql", "batch"]
title = "Batch and SQL (1)"
+++

### Computing large data consolidations

Sometimes, you must make a consolidation from existing datas. You will run your processes during many hours and finally insert / updates them into database. But some people, maybe you, want to access thoses data even if you are working on them. Some tricks are available to reduce the lock / down time that will result of each new consolidation in a significant way.

#### Work with temporary table

To avoid locks on your final table, simply create a **_WRK** (or any suffixes you want) table with the same structure of your final table. Populate you data inside it with no harm for the other users, and you won't be a problem for the users.

#### Use **LOAD DATA LOCAL INFILE** 

Write your data into a local file (CSV format) and order the MySQL driver to populate the table with the content of this one. MySQL will you binary insertion and the insert will be faster than any bulk insert.

Example :

```SQL
LOAD DATA LOCAL INFILE '/tmp/myfile.csv' INTO TABLE TABLE_WRK
```

[LOAD DATA INFILE Documentation](http://dev.mysql.com/doc/refman/5.0/en/load-data.html MySQL Documentation)

You will be surprised by the speed, even if your file is in GB. Be careful, some SQL engine doesn't support LOCAL if the file is not on the MySQL server (ie : [TokuDB](http://www.tokutek.com/tokudb-for-mysql/ TokuDB)).

#### Switch the tables atomically

If you dont need to keep the previous data, you can use the double **RENAME** sql command. It will be an atomic command that will give a 0 down time switch :

```SQL
RENAME TABLE TABLE_FINAL TO TABLE_BACKUP, TABLE_WRK TO TABLE_FINAL;
```

[RENAME TABLE Documentation](http://dev.mysql.com/doc/refman/5.0/en/rename-table.html MySQL Documentation)

This command will switch tables without any down : any fail and it wont be applied.

#### You want to keed the data from the previous run

The previous command is great, but if you want to keep previous data and simply enrich data, it will be a problem. In this case, you can use the **INSERT ON DUPLICATE KEYS UPDATE command**.

Imagine you have a table (and the working table, btw) that have FIELD_1, FIELD_2 that are unique :

```SQL
INSERT INTO TABLE_NAME SELECT * FROM TABLE_WRK ON DUPLICATE KEY UPDATE FIELD_3 = VALUES(FIELD_3)
```

It will insert new values that are based on the unique index and update the old ones. This operation costs more than the previous one but is my favorite. It will lock line by line and quite effective.