--LISTANDO TODAS AS TABELAS TEMPORARIAS
SELECT IDENTITY(int, 1,1) AS ID_COMANDO    
      ,'DROP TABLE ' + TABLE_NAME AS COMANDO
  INTO #TMP_EXECUTAR_COMANDO
  FROM INFORMATION_SCHEMA.TABLES
 WHERE TABLE_NAME LIKE 'TMP_HASH%'

--VAMOS EXECUTAR OS COMANDOS DA TABELA
DECLARE @ID_COMANDO INT
DECLARE @ID_COMANDO_FIM INT
DECLARE @COMANDO VARCHAR(2000)

SET @ID_COMANDO = (SELECT MIN(ID_COMANDO) FROM #TMP_EXECUTAR_COMANDO)
SET @ID_COMANDO_FIM = (SELECT MAX(ID_COMANDO) FROM #TMP_EXECUTAR_COMANDO)

WHILE @ID_COMANDO <= @ID_COMANDO_FIM
BEGIN
    --POPULADO O COMANDO NA VARIAVEL
	SET @COMANDO = (SELECT COMANDO FROM #TMP_EXECUTAR_COMANDO  WHERE ID_COMANDO = @ID_COMANDO)

	--EXECUTANDO O COMANDO 
	EXEC(@COMANDO)

	--ESVAZIANDO A VARIAVEL
	SET @COMANDO = NULL

	--INDO PARA O PROXIMO COMANDO 
	SET @ID_COMANDO = @ID_COMANDO + 1
END 
