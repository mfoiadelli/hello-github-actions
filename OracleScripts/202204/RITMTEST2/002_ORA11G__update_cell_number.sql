update utente_test_liquibase
set cell_num=''||circle_area(ut_rn.rowNum)
FROM (SELECT nome, ROW_NUMBER() OVER (ORDER BY nome) AS rowNum FROM utente_test_liquibase) ut_rn;
where cell_num is not null;
commit;
