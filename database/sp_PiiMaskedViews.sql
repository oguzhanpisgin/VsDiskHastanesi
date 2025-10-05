-- Masked reporting view(s) for PII-safe exposure
USE DiskHastanesiDocs;
GO
SET NOCOUNT ON;
GO
CREATE OR ALTER VIEW dbo.vw_Report_Contacts AS
SELECT 
    c.Id,
    c.CompanyId,
    c.FirstName,
    c.LastName,
    MaskedEmail = CASE WHEN c.Email IS NULL THEN NULL ELSE LEFT(c.Email,3)+'***'+SUBSTRING(c.Email,CHARINDEX('@',c.Email),LEN(c.Email)) END,
    MaskedPhone = CASE WHEN c.Phone IS NULL THEN NULL ELSE LEFT(c.Phone, LEN(c.Phone)-2)+'**' END,
    c.Status,
    c.CreatedAt
FROM CrmContacts c;
GO
PRINT '? vw_Report_Contacts (create/alter)';
GRANT SELECT ON OBJECT::dbo.vw_Report_Contacts TO app_reporting;
GO
