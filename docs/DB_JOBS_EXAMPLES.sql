-- =============================================================
-- DB_JOBS_EXAMPLES.sql
-- Purpose: Example SQL Agent job creation scripts for governance & ops
-- Note: Adjust @schedule, operator names, and categories per environment.
-- =============================================================
USE msdb;
GO

PRINT '== EXAMPLE JOBS CREATION (DRY TEMPLATE) ==';

/* 1. Daily Data Dictionary Refresh (07:00) */
-- EXEC sp_add_job @job_name = N'DB-Dictionary-Refresh';
-- EXEC sp_add_jobstep @job_name=N'DB-Dictionary-Refresh', @step_name=N'Refresh',
--     @database_name=N'DiskHastanesiDocs', @subsystem=N'TSQL',
--     @command=N'EXEC dbo.sp_GenerateDataDictionary @PurgePrevious=1;';
-- EXEC sp_add_schedule @schedule_name=N'Daily-0700', @freq_type=4, @freq_interval=1, @active_start_time=070000;
-- EXEC sp_attach_schedule @job_name=N'DB-Dictionary-Refresh', @schedule_name=N'Daily-0700';
-- EXEC sp_add_jobserver  @job_name=N'DB-Dictionary-Refresh';

/* 2. Hourly Schema Drift Check (log hash) */
-- EXEC sp_add_job @job_name = N'DB-Schema-Drift-Check';
-- EXEC sp_add_jobstep @job_name=N'DB-Schema-Drift-Check', @step_name=N'Check',
--     @database_name=N'DiskHastanesiDocs', @subsystem=N'TSQL',
--     @command=N'EXEC dbo.sp_SchemaDriftCheck;';
-- EXEC sp_add_schedule @schedule_name=N'Hourly', @freq_type=4, @freq_interval=1, @freq_subday_type=8, @freq_subday_interval=1; -- every hour
-- EXEC sp_attach_schedule @job_name=N'DB-Schema-Drift-Check', @schedule_name=N'Hourly';
-- EXEC sp_add_jobserver  @job_name=N'DB-Schema-Drift-Check';

/* 3. Nightly Ops Metrics Capture (01:10) */
-- EXEC sp_add_job @job_name = N'DB-Ops-Metrics-Capture';
-- EXEC sp_add_jobstep @job_name=N'DB-Ops-Metrics-Capture', @step_name=N'Capture',
--     @database_name=N'DiskHastanesiDocs', @subsystem=N'TSQL',
--     @command=N'EXEC dbo.sp_CaptureOpsMetrics;';
-- EXEC sp_add_schedule @schedule_name=N'Daily-0110', @freq_type=4, @freq_interval=1, @active_start_time=011000;
-- EXEC sp_attach_schedule @job_name=N'DB-Ops-Metrics-Capture', @schedule_name=N'Daily-0110';
-- EXEC sp_add_jobserver  @job_name=N'DB-Ops-Metrics-Capture';

/* 4. Weekly Retention Processor (Sunday 02:00) */
-- EXEC sp_add_job @job_name = N'DB-Retention-Processor';
-- EXEC sp_add_jobstep @job_name=N'DB-Retention-Processor', @step_name=N'Purge',
--     @database_name=N'DiskHastanesiDocs', @subsystem=N'TSQL',
--     @command=N'EXEC dbo.sp_ProcessRetention @BatchSize=2000;';
-- EXEC sp_add_schedule @schedule_name=N'Weekly-Sun-0200', @freq_type=8, @freq_interval=1, @active_start_time=020000; -- weekly
-- EXEC sp_attach_schedule @job_name=N'DB-Retention-Processor', @schedule_name=N'Weekly-Sun-0200';
-- EXEC sp_add_jobserver  @job_name=N'DB-Retention-Processor';

/* 5. Security Baseline Audit (Every 6 hours) */
-- EXEC sp_add_job @job_name = N'DB-Security-Baseline-Audit';
-- EXEC sp_add_jobstep @job_name=N'DB-Security-Baseline-Audit', @step_name=N'Audit',
--     @database_name=N'DiskHastanesiDocs', @subsystem=N'TSQL',
--     @command=N'EXEC dbo.sp_RunSecurityBaselineAudit;';
-- EXEC sp_add_schedule @schedule_name=N'Every-6h', @freq_type=4, @freq_interval=1, @freq_subday_type=8, @freq_subday_interval=6;
-- EXEC sp_attach_schedule @job_name=N'DB-Security-Baseline-Audit', @schedule_name=N'Every-6h';
-- EXEC sp_add_jobserver  @job_name=N'DB-Security-Baseline-Audit';

/* 6. Daily Governance Deployment Log Extract (Optional) */
-- EXEC sp_add_job @job_name = N'DB-Deployment-Log-Extract';
-- EXEC sp_add_jobstep @job_name=N'DB-Deployment-Log-Extract', @step_name=N'Export',
--     @database_name=N'DiskHastanesiDocs', @subsystem=N'TSQL',
--     @command=N'SELECT * FROM DeployMetadata WHERE AppliedAt >= DATEADD(DAY,-1,GETDATE());';
-- EXEC sp_add_schedule @schedule_name=N'Daily-0600', @freq_type=4, @freq_interval=1, @active_start_time=060000;
-- EXEC sp_attach_schedule @job_name=N'DB-Deployment-Log-Extract', @schedule_name=N'Daily-0600';
-- EXEC sp_add_jobserver  @job_name=N'DB-Deployment-Log-Extract';

PRINT '== TEMPLATE COMPLETE (Uncomment to create jobs) ==';
