+++
date = "2014-12-17T12:18:43+01:00"
tags = ["sql", "batch"]
title = "Batch and SQL (1)""
+++

#### Computing large data

Sometimes, you must make a consolidation from existing datas. You will run your processes during many hours and finally insert / updates them into database. But some people, maybe you, want to access thoses data even if you are working on them. Some tricks are available to reduce the lock / down time of your data in a significant way.

##### Work with temporary table

To avoid locks on your final table, simply create a **_WRK** (or any suffixes you want) with the same structure of your final table. Populate you data inside it with no harm for the other users, and you won't be a problem for the users.

##### Use **LOAD DATA LOCAL INFILE** 

Write your data into a local file, in a CSV format and order MySQL to populate the table with the content of this one. MySQL will you binary insertion and the insert will be faster than any bulk insert.

Example :

```SQL
LOAD DATA LOCAL INFILE '/tmp/myfile.csv' INTO TABLE TABLE_WRK
```

You will be surprised by the speed, even if your file is in GB. Be careful, some SQL engine doesn't support LOCAL if the file is not on the MySQL server (ie : TokuDB).

##### Switch the table atomically

If you dont need to keep the previous data, you can use the double **RENAME** sql command. It will be an atomic command that will give a 0 down time switch :

```SQL
RENAME TABLE_FINAL TO TABLE_BACKUP, TABLE_WRK TO TABLE FINAL;
```

This command will switch tables without any down, any fail and it wont be applied.

##### You want to keed the data from the previous run

The previous command is great, but if you want to keep previous data and simply enrich data, it will be a problem. In this case, you can use the 