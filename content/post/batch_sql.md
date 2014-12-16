+++
date = "2014-12-17T12:18:43+01:00"
tags = ["sql", "batch"]
title = "Batch and SQL (1)""
+++

#### Computing large data

Sometimes, you must make a consolidation from existing datas. You will run your processes during many hours and finally insert / updates them into memory. But some people, maybe you, want to access thoses data even if you are computing them. Some tricks are available to reduce the lock / down time of your data in a significant way.

##### Work with temporary table

To avoid locks on your final table, simply create a **_WRK** (or any suffixes you want) with the same structure of your final table. Populate you data inside it with no harm for the other users, and you won't be a problem for the users.

##### Use **LOAD DATA LOCAL INFILE** 

Write your data into a local file, in a CSV format and order MySQL to populate the table with the content of this one. MySQL will you binary insertion and the insert will be faster than any bulk insert.

Example :

```SQL
LOAD DATA LOCAL INFILE '/tmp/myfile.csv' INTO TABLE TABLE_WRK
```

You will be surprised by the speed, even if your file is in GB.