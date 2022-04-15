UPDATE utente_test_liquibase
     SET cell_num = (select ''||circle_area(rn) 
                             from (
                                select nome, cognome,
                                      row_number() over (order by nome, cognome) AS RN
                                from utente_test_liquibase
                            ) x
                            where x.nome = utente_test_liquibase.nome AND x.cognome = utente_test_liquibase.cognome)
                            where cell_num is null
