-- Row-Level Security (RLS) Preparation Script (disabled by default)
-- Version: 0.2 (Add sp_EnableTenantRls toggle procedure)
-- To enable: EXEC dbo.sp_EnableTenantRls @State=1; to disable: EXEC dbo.sp_EnableTenantRls @State=0
USE DiskHastanesiDocs;
GO
SET NOCOUNT ON;
GO
IF OBJECT_ID('dbo.fn_rls_TenantPredicate','IF') IS NULL
    EXEC('CREATE FUNCTION dbo.fn_rls_TenantPredicate(@TenantId INT) RETURNS TABLE WITH SCHEMABINDING AS RETURN SELECT 1 AS fn_result WHERE @TenantId = CAST(SESSION_CONTEXT(N''TenantId'') AS INT)');
GO
CREATE OR ALTER PROCEDURE dbo.sp_EnableTenantRls @State BIT AS
BEGIN
    SET NOCOUNT ON;
    IF @State=1
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM sys.security_policies WHERE name='TenantIsolationPolicy')
        BEGIN
            DECLARE @sql NVARCHAR(MAX) = N'CREATE SECURITY POLICY TenantIsolationPolicy
                ADD FILTER PREDICATE dbo.fn_rls_TenantPredicate(TenantId) ON dbo.CrmCompanies,
                ADD FILTER PREDICATE dbo.fn_rls_TenantPredicate(TenantId) ON dbo.CrmContacts,
                ADD FILTER PREDICATE dbo.fn_rls_TenantPredicate(TenantId) ON dbo.CrmDeals
                WITH (STATE = ON);';
            EXEC(@sql);
            PRINT 'RLS policy TenantIsolationPolicy created & enabled.';
        END ELSE
        BEGIN
            ALTER SECURITY POLICY TenantIsolationPolicy WITH (STATE = ON);
            PRINT 'RLS policy TenantIsolationPolicy enabled.';
        END
    END
    ELSE
    BEGIN
        IF EXISTS (SELECT 1 FROM sys.security_policies WHERE name='TenantIsolationPolicy')
        BEGIN
            ALTER SECURITY POLICY TenantIsolationPolicy WITH (STATE = OFF);
            PRINT 'RLS policy TenantIsolationPolicy disabled.';
        END ELSE PRINT 'RLS policy not present to disable.';
    END
    SELECT name AS PolicyName, is_enabled FROM sys.security_policies WHERE name='TenantIsolationPolicy';
END;
GO
PRINT 'RLS preparation (function + toggle proc) installed. Policy still disabled by default.';
