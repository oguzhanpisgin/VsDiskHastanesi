-- Minimal test seed (non-destructive). Use only in test env.
USE DiskHastanesiDocs;
GO
SET NOCOUNT ON;
GO
PRINT '== TEST SEED START ==';

IF NOT EXISTS (SELECT 1 FROM CrmCompanies WHERE Name='TestCo')
BEGIN
    INSERT INTO CrmCompanies(Name,Status,CreatedAt) VALUES('TestCo','Active',GETDATE());
END
DECLARE @CompanyId INT = (SELECT Id FROM CrmCompanies WHERE Name='TestCo');

IF NOT EXISTS (SELECT 1 FROM CrmContacts WHERE FirstName='Test' AND LastName='User')
BEGIN
    INSERT INTO CrmContacts(CompanyId,FirstName,LastName,Status,CreatedAt) VALUES(@CompanyId,'Test','User','Active',GETDATE());
END
DECLARE @ContactId INT = (SELECT TOP 1 Id FROM CrmContacts WHERE CompanyId=@CompanyId);

IF NOT EXISTS (SELECT 1 FROM ProjectTasks WHERE TaskName='Sample Task')
BEGIN
    INSERT INTO ProjectTasks(TaskName,Description,Status,CreatedAt) VALUES('Sample Task','Demo task for integration tests','Pending',GETDATE());
END

PRINT '== TEST SEED COMPLETE ==';
GO
