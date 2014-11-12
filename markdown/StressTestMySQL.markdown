## Install sysbench

	yum install sysbench -y

## Create a "TEST" database

## Prepare and Run

	sysbench --test=oltp --oltp-table-size=10000 --mysql-db=test --mysql-user=root --mysql-password=password --oltp-read-only=off --db-driver=mysql --mysql-socket=/var/run/mysqld/mysqld.sock prepare
	
	sysbench --test=oltp --oltp-table-size=10000 --mysql-db=test --mysql-user=root --mysql-password=password --oltp-read-only=off --db-driver=mysql --mysql-socket=/var/run/mysqld/mysqld.sock run
	
	sysbench --test=oltp --oltp-table-size=10000 --mysql-db=test --mysql-user=root --mysql-password=password --oltp-read-only=off --db-driver=mysql --mysql-socket=/var/run/mysqld/mysqld.sock cleanup

## Output from Single Database Node

	[root@mysql-1 ~]# sysbench --test=oltp --oltp-table-size=10000 --mysql-db=test --mysql-user=root --mysql-password=password --oltp-read-only=off --db-driver=mysql --mysql-socket=/var/run/mysqld/mysqld.sock run
	sysbench 0.4.12:  multi-threaded system evaluation benchmark
	
	Running the test with following options:
	Number of threads: 1
	
	Doing OLTP test.
	Running mixed OLTP test
	Using Special distribution (12 iterations,  1 pct of values are returned in 75 pct cases)
	Using "BEGIN" for starting transactions
	Using auto_inc on the id column
	Maximum number of requests for OLTP test is limited to 10000
	Threads started!
	Done.
	
	OLTP test statistics:
	    queries performed:
	        read:                            140000
	        write:                           50000
	        other:                           20000
	        total:                           210000
	    transactions:                        10000  (344.27 per sec.)
	    deadlocks:                           0      (0.00 per sec.)
	    read/write requests:                 190000 (6541.05 per sec.)
	    other operations:                    20000  (688.53 per sec.)
	
	Test execution summary:
	    total time:                          29.0473s
	    total number of events:              10000
	    total time taken by event execution: 28.9912
	    per-request statistics:
	         min:                                  2.24ms
	         avg:                                  2.90ms
	         max:                                 69.17ms
	         approx.  95 percentile:               3.98ms
	
	Threads fairness:
	    events (avg/stddev):           10000.0000/0.00
	    execution time (avg/stddev):   28.9912/0.00
	
## Output from Dual Database Node

	[root@mysql-1 mysql]# sysbench --test=oltp --oltp-table-size=10000 --mysql-db=test --mysql-user=root --mysql-password=password --oltp-read-only=off --db-driver=mysql --mysql-socket=/var/run/mysqld/mysqld.sock run
	sysbench 0.4.12:  multi-threaded system evaluation benchmark
	
	Running the test with following options:
	Number of threads: 1
	
	Doing OLTP test.
	Running mixed OLTP test
	Using Special distribution (12 iterations,  1 pct of values are returned in 75 pct cases)
	Using "BEGIN" for starting transactions
	Using auto_inc on the id column
	Maximum number of requests for OLTP test is limited to 10000
	Threads started!
	Done.
	
	OLTP test statistics:
	    queries performed:
	        read:                            140000
	        write:                           50000
	        other:                           20000
	        total:                           210000
	    transactions:                        10000  (234.39 per sec.)
	    deadlocks:                           0      (0.00 per sec.)
	    read/write requests:                 190000 (4453.50 per sec.)
	    other operations:                    20000  (468.79 per sec.)
	
	Test execution summary:
	    total time:                          42.6631s
	    total number of events:              10000
	    total time taken by event execution: 42.5865
	    per-request statistics:
	         min:                                  2.55ms
	         avg:                                  4.26ms
	         max:                                 69.28ms
	         approx.  95 percentile:               4.47ms
	
	Threads fairness:
	    events (avg/stddev):           10000.0000/0.00
	    execution time (avg/stddev):   42.5865/0.00

## Output from Three Database Node

	[root@mysql-1 ~]# sysbench --test=oltp --oltp-table-size=10000 --mysql-db=test --mysql-user=root --mysql-password=password --oltp-read-only=off --db-driver=mysql --mysql-socket=/var/run/mysqld/mysqld.sock run
	sysbench 0.4.12:  multi-threaded system evaluation benchmark
	
	Running the test with following options:
	Number of threads: 1
	
	Doing OLTP test.
	Running mixed OLTP test
	Using Special distribution (12 iterations,  1 pct of values are returned in 75 pct cases)
	Using "BEGIN" for starting transactions
	Using auto_inc on the id column
	Maximum number of requests for OLTP test is limited to 10000
	Threads started!
	Done.
	
	OLTP test statistics:
	    queries performed:
	        read:                            140000
	        write:                           50000
	        other:                           20000
	        total:                           210000
	    transactions:                        10000  (223.83 per sec.)
	    deadlocks:                           0      (0.00 per sec.)
	    read/write requests:                 190000 (4252.82 per sec.)
	    other operations:                    20000  (447.67 per sec.)
	
	Test execution summary:
	    total time:                          44.6763s
	    total number of events:              10000
	    total time taken by event execution: 44.5991
	    per-request statistics:
	         min:                                  2.66ms
	         avg:                                  4.46ms
	         max:                                105.07ms
	         approx.  95 percentile:               4.71ms
	
	Threads fairness:
	    events (avg/stddev):           10000.0000/0.00
	    execution time (avg/stddev):   44.5991/0.00


