-- Based on code here: http://www.sqlservercentral.com/articles/Fuzzy+Match/65702/
-- Modified to be used in SQL Server Database Projects or run on its own, and fixed similarity vs distance confusion

--FUNÇÃO PRINCIPAL
CREATE FUNCTION [dbo].[CalculateJaro](@str1 VARCHAR(MAX), @str2 VARCHAR(MAX)) 
RETURNS FLOAT AS 
BEGIN
    DECLARE	@Common1				VARCHAR(MAX)
    DECLARE	@Common2				VARCHAR(MAX)
    DECLARE @Common1_Len			INT
    DECLARE	@Common2_Len			INT
    DECLARE @s1_len					INT  
    DECLARE @s2_len					INT 
    DECLARE	@transpose_cnt			INT
    DECLARE @match_window			INT
    DECLARE @jaro_distance			FLOAT
    SET		@transpose_cnt			= 0
    SET		@match_window			= 0
    SET		@jaro_distance			= 0
    Set @s1_len = LEN(@str1)
    Set @s2_len = LEN(@str2)
    SET	@match_window = dbo.JaroWinklerCalculateMatchWindow(@s1_len, @s2_len)
    SET	@Common1 = dbo.JaroWinklerGetCommonCharacters(@str1, @str2, @match_window)
    SET @Common1_Len = LEN(@Common1)
    IF @Common1_Len = 0 OR @Common1 IS NULL
    BEGIN
        RETURN 0		
    END
    SET @Common2 = dbo.JaroWinklerGetCommonCharacters(@str2, @str1, @match_window)
    SET @Common2_Len = LEN(@Common2)
    IF @Common1_Len <> @Common2_Len OR @Common2 IS NULL
    BEGIN
        RETURN 0
    END

    SET	@transpose_cnt = dbo.[JaroWinklerCalculateTranspositions](@Common1_Len, @Common1, @Common2)
    SET	@jaro_distance =	@Common1_Len / (3.0 * @s1_len) + 
                            @Common1_Len / (3.0 * @s2_len) +
                            (@Common1_Len - @transpose_cnt) / (3.0 * @Common1_Len);

    RETURN @jaro_distance
END
GO


--FUNÇÕES AUXILIARES
CREATE FUNCTION [dbo].JaroWinklerGetCommonCharacters(@firstWord VARCHAR(MAX), @secondWord VARCHAR(MAX), @matchWindow INT)
RETURNS VARCHAR(MAX) AS
BEGIN
    DECLARE @CommonChars VARCHAR(MAX)
    DECLARE @copy VARCHAR(MAX)
    DECLARE @char CHAR(1)
    DECLARE @foundIT BIT

    DECLARE @f1_len INT
    DECLARE @f2_len INT
    DECLARE @i INT
    DECLARE @j INT
    DECLARE @j_Max INT

    SET	@CommonChars = ''
    IF @firstWord IS NOT NULL AND @secondWord IS NOT NULL 
    BEGIN
        SET @f1_len = LEN(@firstWord)
        SET @f2_len = LEN(@secondWord)
        SET @copy = @secondWord

        SET @i = 1
        WHILE @i < (@f1_len + 1)
        BEGIN
            SET	@char = SUBSTRING(@firstWord, @i, 1)
            SET @foundIT = 0

            -- Set J starting value
            IF @i - @matchWindow > 1
            BEGIN
                SET @j = @i - @matchWindow
            END
            ELSE
            BEGIN
                SET @j = 1
            END
            -- Set J stopping value
            IF @i + @matchWindow <= @f2_len
            BEGIN
                SET @j_Max = @i + @matchWindow
            END
            ELSE
            IF @f2_len < @i + @matchWindow
            BEGIN
                SET @j_Max = @f2_len
            END

            WHILE @j < (@j_Max + 1) AND @foundIT = 0
            BEGIN
                IF SUBSTRING(@copy, @j, 1) = @char
                BEGIN
                    SET	@foundIT = 1
                    SET	@CommonChars = @CommonChars + @char
                    SET @copy = STUFF(@copy, @j, 1, '#')
                END
                SET @j = @j + 1
            END	
            SET @i = @i + 1
        END
    END

    RETURN @CommonChars
END
GO

CREATE FUNCTION [dbo].[JaroWinklerCalculateMatchWindow](@s1_len INT, @s2_len INT) 
RETURNS INT AS 
BEGIN
    DECLARE @matchWindow INT
    SET	@matchWindow =	CASE	WHEN @s1_len >= @s2_len
                                THEN (@s1_len / 2) - 1
                                ELSE (@s2_len / 2) - 1
                        END
    RETURN @matchWindow
END
GO

CREATE FUNCTION [dbo].[JaroWinklerCalculateTranspositions](@s1_len INT, @str1 VARCHAR(MAX), @str2 VARCHAR(MAX)) 
RETURNS INT AS 
BEGIN
    DECLARE @transpositions INT
    DECLARE @i INT

    SET	@transpositions = 0
    SET	@i = 0
    WHILE @i < @s1_len
    BEGIN
        IF SUBSTRING(@str1, @i+1, 1) <> SUBSTRING(@str2, @i+1, 1)
        BEGIN
            SET	@transpositions = @transpositions + 1
        END
        SET @i = @i + 1
    END

    SET	@transpositions = @transpositions / 2
    RETURN @transpositions
END
GO


CREATE FUNCTION [dbo].[JaroWinklerCalculatePrefixLength](@firstWord VARCHAR(MAX), @secondWord VARCHAR(MAX))
RETURNS INT As 
BEGIN
    DECLARE @f1_len INT
    DECLARE @f2_len INT
    DECLARE	@minPrefixTestLength INT
    DECLARE @i INT
    DECLARE @n INT
    DECLARE @foundIT BIT

    SET	@minPrefixTestLength = 4
    IF @firstWord IS NOT NULL AND @secondWord IS NOT NULL 
    BEGIN
        SET @f1_len = LEN(@firstWord)
        SET @f2_len = LEN(@secondWord)
        SET @i = 0
        SET	@foundIT = 0
        SET @n =	CASE	WHEN	@minPrefixTestLength < @f1_len 
                                    AND @minPrefixTestLength < @f2_len 
                            THEN	@minPrefixTestLength
                            WHEN	@f1_len < @f2_len 
                                    AND @f1_len < @minPrefixTestLength 
                            THEN	@f1_len
                            ELSE	@f2_len
                    END
        WHILE @i < @n AND @foundIT = 0
        BEGIN
            IF SUBSTRING(@firstWord, @i+1, 1) <> SUBSTRING(@secondWord, @i+1, 1)
            BEGIN
                SET @minPrefixTestLength = @i
                SET @foundIT = 1
            END
            SET @i = @i + 1
        END
    END
    RETURN @minPrefixTestLength
END
GO

CREATE FUNCTION [dbo].[JaroWinklerStringSimilarity](@str1 VARCHAR(MAX), @str2 VARCHAR(MAX)) 
RETURNS float As 
BEGIN
    DECLARE @jaro_distance			FLOAT
    DECLARE @prefixLength			INT
    DECLARE @prefixScaleFactor		FLOAT

    SET		@prefixScaleFactor	= 0.1 --Constant = .1

    SET		@jaro_distance	= dbo.CalculateJaro(@str1, @str2)	
    SET		@prefixLength	= dbo.JaroWinklerCalculatePrefixLength(@str1, @str2)

    RETURN @jaro_distance + ((@prefixLength * @prefixScaleFactor) * (1.0 - @jaro_distance))
END
GO

CREATE FUNCTION [dbo].[JaroWinklerStringDistance](@str1 VARCHAR(MAX), @str2 VARCHAR(MAX)) 
RETURNS float As 
BEGIN
    RETURN 1.0 - dbo.JaroWinklerStringSimilarity(@str1, @str2);
END
GO



SELECT Procter_Gamble_000_CRM.[dbo].[CalculateJaro]('ZACHARIAS PRADO NETO','ZACARIAS PRADO NETO')


SELECT Peg_001_Base.[dbo].[CalculateJaro]('ZACHARIAS PRADO NETO','ZACARIAS PRADO NETO')
