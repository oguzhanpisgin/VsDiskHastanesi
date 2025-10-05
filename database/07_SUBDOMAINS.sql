USE DiskHastanesiDocs;
GO

-- Add additional subdomains
INSERT INTO SystemMetadata (MetadataKey, MetadataValue, LastUpdatedBy) VALUES
(N'CrmBaseUrl', N'https://crm.diskhastanesi.com', 'System'),
(N'CdnBaseUrl', N'https://cdn.diskhastanesi.com', 'System'),
(N'DocsBaseUrl', N'https://docs.diskhastanesi.com', 'System'),
(N'StatusBaseUrl', N'https://status.diskhastanesi.com', 'System');
GO

SELECT * FROM SystemMetadata WHERE MetadataKey LIKE '%Url';
