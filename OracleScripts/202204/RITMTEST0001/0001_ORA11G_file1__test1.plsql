BEGIN
dbms_lock.sleep(60*15);
INSERT INTO test_table_2 ( firstname ) VALUES ( 'MATTEO' );
COMMIT;
END;
/
