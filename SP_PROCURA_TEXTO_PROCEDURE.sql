CREATE PROCEDURE SP_PROCURA_TEXTO_PROCEDURE 
@DATA_BASE VARCHAR(100), 
@PALAVRA VARCHAR(MAX)
AS

DECLARE @COUNT_DATABASE INT
DECLARE @SQL VARCHAR(MAX)

IF OBJECT_ID(N'tempdb..#TABELA_RESULTADO', N'U') IS NOT NULL   
DROP TABLE #TABELA_RESULTADO;  

CREATE TABLE #TABELA_RESULTADO
(
    DATA_BASE VARCHAR(100)
   ,OBJECT_ID VARCHAR(100)
   ,NAME VARCHAR(100)
   ,TYPE VARCHAR(100)
   ,DEFINITION VARCHAR(MAX)
)

SET @COUNT_DATABASE = 1

IF (@DATA_BASE IS NOT NULL OR @DATA_BASE <> '')
BEGIN
         SET @SQL = N'USE '+ @DATA_BASE +' INSERT INTO #TABELA_RESULTADO (DATA_BASE,OBJECT_ID,NAME,TYPE,DEFINITION) SELECT '''+@DATA_BASE+''' AS DATA_BASE, A.OBJECT_ID, A.name, A.type, B.definition FROM SYS.procedures AS A INNER JOIN sys.all_sql_modules AS B ON A.object_id = B.object_id WHERE type = ''P'' AND definition LIKE ''%'+@PALAVRA+'%''' 
         EXECUTE (@SQL)
END 
ELSE 
      BEGIN
      WHILE @COUNT_DATABASE <= (SELECT MAX(database_id) FROM sys.databases)
      BEGIN

      SET @DATA_BASE = (SELECT name FROM sys.databases WHERE database_id = @COUNT_DATABASE)
         IF @DATA_BASE IS NOT NULL
         BEGIN
               SET @SQL = N'USE '+ @DATA_BASE +' INSERT INTO #TABELA_RESULTADO (DATA_BASE,OBJECT_ID,NAME,TYPE,DEFINITION) SELECT '''+@DATA_BASE+''' AS DATA_BASE, A.OBJECT_ID, A.name, A.type, B.definition FROM SYS.procedures AS A INNER JOIN sys.all_sql_modules AS B ON A.object_id = B.object_id WHERE type = ''P'' AND definition LIKE ''%'+@PALAVRA+'%''' 
               EXECUTE (@SQL)
         END
      SET @COUNT_DATABASE = @COUNT_DATABASE + 1
      END 
END 
SELECT * FROM #TABELA_RESULTADO
