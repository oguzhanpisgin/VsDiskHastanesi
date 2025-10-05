# Dağıtım Rehberi (Deployment Guide)

**Kaynak:** diskhastanesi.com projesi - Microsoft Stack'e taşıma için hazırlanmıştır

Bu dosya, Azure kaynaklarını provisioning, IaC (Infrastructure as Code), CI/CD pipeline, blue-green deployment ve disaster recovery stratejilerini içerir.

---

## 1. Azure Infrastructure Overview

### 1.1 Resource Topology

```
┌─────────────────────────────────────────────────────────────┐
│                      Azure Subscription                      │
└──────────────────────┬──────────────────────────────────────┘
                       │
       ┌───────────────┴───────────────┐
       │   Resource Group (Production)  │
       │   rg-diskhastanesi-prod       │
       └───────────────┬───────────────┘
                       │
       ┌───────────────┼───────────────┐
       │               │               │
┌──────▼──────┐ ┌─────▼──────┐ ┌─────▼──────┐
│  App Service │ │  SQL Server │ │ Key Vault  │
│ app-disk-prod│ │ sql-disk-pr│ │ kv-disk-pr │
└──────┬──────┘ └─────┬──────┘ └─────┬──────┘
       │              │              │
┌──────▼──────┐ ┌─────▼──────┐ ┌─────▼──────┐
│   Storage   │ │ SQL Database│ │   Secrets  │
│ stdiskprod  │ │db-disk-prod│ │            │
└──────┬──────┘ └────────────┘ └────────────┘
       │
┌──────▼──────┐
│ App Insights│
│appi-disk-pr │
└─────────────┘

┌──────────────────────────────────────────┐
│   Azure Front Door (CDN)                 │
│   fd-diskhastanesi                       │
└──────────────────────────────────────────┘
```

### 1.2 Environment Strategy

**Environments**
- **Development**: Local + Azure dev resources
- **Staging**: Pre-production environment
- **Production**: Live customer-facing environment

**Naming Convention**
```
{resource-type}-{project}-{environment}

Examples:
- app-diskhastanesi-prod
- sql-diskhastanesi-staging
- kv-diskhastanesi-dev
```

---

## 2. Infrastructure as Code (IaC)

### 2.1 Bicep Templates

**main.bicep**
```bicep
@description('Location for all resources')
param location string = resourceGroup().location

@description('Environment name')
@allowed([
  'dev'
  'staging'
  'prod'
])
param environment string

@description('Application name')
param appName string = 'diskhastanesi'

@description('SQL Administrator username')
@secure()
param sqlAdminUsername string

@description('SQL Administrator password')
@secure()
param sqlAdminPassword string

var appServicePlanName = 'asp-${appName}-${environment}'
var webAppName = 'app-${appName}-${environment}'
var sqlServerName = 'sql-${appName}-${environment}'
var sqlDatabaseName = 'db-${appName}-${environment}'
var storageAccountName = 'st${appName}${environment}'
var keyVaultName = 'kv-${appName}-${environment}'
var appInsightsName = 'appi-${appName}-${environment}'

// App Service Plan
resource appServicePlan 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: appServicePlanName
  location: location
  sku: {
    name: environment == 'prod' ? 'P1v3' : 'B1'
    tier: environment == 'prod' ? 'PremiumV3' : 'Basic'
    capacity: environment == 'prod' ? 2 : 1
  }
  kind: 'linux'
  properties: {
    reserved: true
  }
}

// Web App
resource webApp 'Microsoft.Web/sites@2022-09-01' = {
  name: webAppName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      linuxFxVersion: 'DOTNETCORE|8.0'
      alwaysOn: environment == 'prod'
      http20Enabled: true
      minTlsVersion: '1.2'
      ftpsState: 'Disabled'
      appSettings: [
        {
          name: 'ASPNETCORE_ENVIRONMENT'
          value: environment == 'prod' ? 'Production' : 'Staging'
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsights.properties.ConnectionString
        }
        {
          name: 'KeyVault__Name'
          value: keyVaultName
        }
      ]
      connectionStrings: [
        {
          name: 'DefaultConnection'
          connectionString: 'Server=${sqlServer.properties.fullyQualifiedDomainName};Database=${sqlDatabaseName};'
          type: 'SQLAzure'
        }
      ]
    }
    httpsOnly: true
  }
}

// SQL Server
resource sqlServer 'Microsoft.Sql/servers@2022-05-01-preview' = {
  name: sqlServerName
  location: location
  properties: {
    administratorLogin: sqlAdminUsername
    administratorLoginPassword: sqlAdminPassword
    version: '12.0'
    minimalTlsVersion: '1.2'
  }
}

// SQL Database
resource sqlDatabase 'Microsoft.Sql/servers/databases@2022-05-01-preview' = {
  parent: sqlServer
  name: sqlDatabaseName
  location: location
  sku: {
    name: environment == 'prod' ? 'S1' : 'Basic'
    tier: environment == 'prod' ? 'Standard' : 'Basic'
  }
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    maxSizeBytes: environment == 'prod' ? 268435456000 : 2147483648 // 250GB : 2GB
    catalogCollation: 'SQL_Latin1_General_CP1_CI_AS'
    zoneRedundant: environment == 'prod'
  }
}

// SQL Firewall Rule - Allow Azure Services
resource sqlFirewallRule 'Microsoft.Sql/servers/firewallRules@2022-05-01-preview' = {
  parent: sqlServer
  name: 'AllowAzureServices'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

// Storage Account
resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: environment == 'prod' ? 'Standard_GRS' : 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
  }
}

// Key Vault
resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: keyVaultName
  location: location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    enableRbacAuthorization: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
  }
}

// Grant Web App access to Key Vault
resource keyVaultAccessPolicy 'Microsoft.KeyVault/vaults/accessPolicies@2022-07-01' = {
  parent: keyVault
  name: 'add'
  properties: {
    accessPolicies: [
      {
        tenantId: subscription().tenantId
        objectId: webApp.identity.principalId
        permissions: {
          secrets: [
            'get'
            'list'
          ]
        }
      }
    ]
  }
}

// Application Insights
resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    RetentionInDays: environment == 'prod' ? 90 : 30
  }
}

// Outputs
output webAppName string = webApp.name
output webAppUrl string = 'https://${webApp.properties.defaultHostName}'
output sqlServerFqdn string = sqlServer.properties.fullyQualifiedDomainName
output keyVaultUri string = keyVault.properties.vaultUri
```

**parameters.prod.json**
```json
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "environment": {
      "value": "prod"
    },
    "location": {
      "value": "westeurope"
    },
    "sqlAdminUsername": {
      "reference": {
        "keyVault": {
          "id": "/subscriptions/{subscription-id}/resourceGroups/rg-shared/providers/Microsoft.KeyVault/vaults/kv-shared"
        },
        "secretName": "sql-admin-username"
      }
    },
    "sqlAdminPassword": {
      "reference": {
        "keyVault": {
          "id": "/subscriptions/{subscription-id}/resourceGroups/rg-shared/providers/Microsoft.KeyVault/vaults/kv-shared"
        },
        "secretName": "sql-admin-password"
      }
    }
  }
}
```

### 2.2 Deploy Infrastructure

**Using Azure CLI**
```bash
# Login to Azure
az login

# Set subscription
az account set --subscription "Your Subscription Name"

# Create resource group
az group create \
  --name rg-diskhastanesi-prod \
  --location westeurope

# Deploy infrastructure
az deployment group create \
  --resource-group rg-diskhastanesi-prod \
  --template-file main.bicep \
  --parameters parameters.prod.json

# Get outputs
az deployment group show \
  --resource-group rg-diskhastanesi-prod \
  --name main \
  --query properties.outputs
```

**Using PowerShell**
```powershell
# Login
Connect-AzAccount

# Set subscription
Set-AzContext -Subscription "Your Subscription Name"

# Deploy
New-AzResourceGroupDeployment `
  -ResourceGroupName rg-diskhastanesi-prod `
  -TemplateFile main.bicep `
  -TemplateParameterFile parameters.prod.json
```

---

## 3. CI/CD Pipeline

### 3.1 Azure DevOps Pipeline

**azure-pipelines.yml**
```yaml
trigger:
  branches:
    include:
      - main
      - develop
  paths:
    exclude:
      - docs/**
      - README.md

variables:
  buildConfiguration: 'Release'
  dotnetSdkVersion: '8.0.x'
  azureSubscription: 'Azure-Subscription-ServiceConnection'
  
stages:
- stage: Build
  displayName: 'Build Application'
  jobs:
  - job: Build
    displayName: 'Build Job'
    pool:
      vmImage: 'ubuntu-latest'
    
    steps:
    - task: UseDotNet@2
      displayName: 'Install .NET SDK'
      inputs:
        packageType: 'sdk'
        version: $(dotnetSdkVersion)
    
    - task: DotNetCoreCLI@2
      displayName: 'Restore dependencies'
      inputs:
        command: 'restore'
        projects: '**/*.csproj'
    
    - task: DotNetCoreCLI@2
      displayName: 'Build application'
      inputs:
        command: 'build'
        projects: '**/*.csproj'
        arguments: '--configuration $(buildConfiguration) --no-restore'
    
    - task: DotNetCoreCLI@2
      displayName: 'Run unit tests'
      inputs:
        command: 'test'
        projects: '**/*Tests.csproj'
        arguments: '--configuration $(buildConfiguration) --no-build --collect:"XPlat Code Coverage"'
    
    - task: PublishCodeCoverageResults@1
      displayName: 'Publish code coverage'
      inputs:
        codeCoverageTool: 'Cobertura'
        summaryFileLocation: '$(Agent.TempDirectory)/**/*coverage.cobertura.xml'
    
    - task: DotNetCoreCLI@2
      displayName: 'Publish application'
      inputs:
        command: 'publish'
        publishWebProjects: true
        arguments: '--configuration $(buildConfiguration) --output $(Build.ArtifactStagingDirectory)'
        zipAfterPublish: true
    
    - task: PublishBuildArtifacts@1
      displayName: 'Publish artifacts'
      inputs:
        PathtoPublish: '$(Build.ArtifactStagingDirectory)'
        ArtifactName: 'drop'
        publishLocation: 'Container'

- stage: DeployStaging
  displayName: 'Deploy to Staging'
  dependsOn: Build
  condition: and(succeeded(), eq(variables['Build.SourceBranch'], 'refs/heads/develop'))
  jobs:
  - deployment: DeployStaging
    displayName: 'Deploy to Staging'
    environment: 'staging'
    pool:
      vmImage: 'ubuntu-latest'
    strategy:
      runOnce:
        deploy:
          steps:
          - task: AzureWebApp@1
            displayName: 'Deploy to Azure App Service'
            inputs:
              azureSubscription: $(azureSubscription)
              appType: 'webAppLinux'
              appName: 'app-diskhastanesi-staging'
              package: '$(Pipeline.Workspace)/drop/**/*.zip'
              runtimeStack: 'DOTNETCORE|8.0'

- stage: DeployProduction
  displayName: 'Deploy to Production'
  dependsOn: Build
  condition: and(succeeded(), eq(variables['Build.SourceBranch'], 'refs/heads/main'))
  jobs:
  - deployment: DeployProduction
    displayName: 'Deploy to Production'
    environment: 'production'
    pool:
      vmImage: 'ubuntu-latest'
    strategy:
      runOnce:
        deploy:
          steps:
          - task: AzureWebApp@1
            displayName: 'Deploy to Blue Slot'
            inputs:
              azureSubscription: $(azureSubscription)
              appType: 'webAppLinux'
              appName: 'app-diskhastanesi-prod'
              package: '$(Pipeline.Workspace)/drop/**/*.zip'
              deployToSlotOrASE: true
              resourceGroupName: 'rg-diskhastanesi-prod'
              slotName: 'blue'
          
          - task: AzureAppServiceManage@0
            displayName: 'Swap Blue to Production'
            inputs:
              azureSubscription: $(azureSubscription)
              WebAppName: 'app-diskhastanesi-prod'
              ResourceGroupName: 'rg-diskhastanesi-prod'
              SourceSlot: 'blue'
              SwapWithProduction: true
```

### 3.2 GitHub Actions Alternative

**.github/workflows/deploy.yml**
```yaml
name: Deploy to Azure

on:
  push:
    branches:
      - main
      - develop

env:
  DOTNET_VERSION: '8.0.x'
  AZURE_WEBAPP_NAME: 'app-diskhastanesi-prod'

jobs:
  build:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v4
    
    - name: Setup .NET
      uses: actions/setup-dotnet@v3
      with:
        dotnet-version: ${{ env.DOTNET_VERSION }}
    
    - name: Restore dependencies
      run: dotnet restore
    
    - name: Build
      run: dotnet build --configuration Release --no-restore
    
    - name: Test
      run: dotnet test --no-build --verbosity normal
    
    - name: Publish
      run: dotnet publish -c Release -o ./publish
    
    - name: Upload artifact
      uses: actions/upload-artifact@v3
      with:
        name: webapp
        path: ./publish
  
  deploy-staging:
    needs: build
    if: github.ref == 'refs/heads/develop'
    runs-on: ubuntu-latest
    environment: staging
    
    steps:
    - name: Download artifact
      uses: actions/download-artifact@v3
      with:
        name: webapp
        path: ./webapp
    
    - name: Deploy to Azure Web App
      uses: azure/webapps-deploy@v2
      with:
        app-name: 'app-diskhastanesi-staging'
        publish-profile: ${{ secrets.AZURE_WEBAPP_PUBLISH_PROFILE_STAGING }}
        package: ./webapp
  
  deploy-production:
    needs: build
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    environment: production
    
    steps:
    - name: Download artifact
      uses: actions/download-artifact@v3
      with:
        name: webapp
        path: ./webapp
    
    - name: Deploy to Blue Slot
      uses: azure/webapps-deploy@v2
      with:
        app-name: ${{ env.AZURE_WEBAPP_NAME }}
        publish-profile: ${{ secrets.AZURE_WEBAPP_PUBLISH_PROFILE_BLUE }}
        slot-name: blue
        package: ./webapp
    
    - name: Swap slots
      uses: azure/cli@v1
      with:
        inlineScript: |
          az webapp deployment slot swap \
            --name ${{ env.AZURE_WEBAPP_NAME }} \
            --resource-group rg-diskhastanesi-prod \
            --slot blue \
            --target-slot production
```

---

## 4. Blue-Green Deployment

### 4.1 Deployment Slots

**Create Blue Slot**
```bash
# Create deployment slot
az webapp deployment slot create \
  --name app-diskhastanesi-prod \
  --resource-group rg-diskhastanesi-prod \
  --slot blue

# Configure slot settings
az webapp config appsettings set \
  --name app-diskhastanesi-prod \
  --resource-group rg-diskhastanesi-prod \
  --slot blue \
  --settings ASPNETCORE_ENVIRONMENT=Staging
```

### 4.2 Deployment Process

**Step-by-Step**
```bash
# 1. Deploy to Blue slot
az webapp deployment source config-zip \
  --name app-diskhastanesi-prod \
  --resource-group rg-diskhastanesi-prod \
  --slot blue \
  --src ./publish.zip

# 2. Warm up Blue slot
curl https://app-diskhastanesi-prod-blue.azurewebsites.net/health

# 3. Run smoke tests on Blue
npm run test:smoke -- --baseUrl=https://app-diskhastanesi-prod-blue.azurewebsites.net

# 4. Swap Blue → Production
az webapp deployment slot swap \
  --name app-diskhastanesi-prod \
  --resource-group rg-diskhastanesi-prod \
  --slot blue \
  --target-slot production

# 5. Monitor production for errors
# (If errors, rollback immediately)

# 6. If successful, Blue slot now has old version (instant rollback available)
```

### 4.3 Rollback Procedure

**Instant Rollback**
```bash
# Swap back (Green → Blue)
az webapp deployment slot swap \
  --name app-diskhastanesi-prod \
  --resource-group rg-diskhastanesi-prod \
  --slot production \
  --target-slot blue

# Rollback is instant (no redeploy needed)
```

---

## 5. Database Migrations

### 5.1 Migration Strategy

**Deployment Steps**
1. Deploy application with migration scripts
2. Run migrations automatically on startup (dev/staging)
3. Run migrations manually in production (safety)

**Entity Framework Core Migrations**
```csharp
// Program.cs
var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();

// Auto-migrate in non-production
if (!app.Environment.IsProduction())
{
    using var scope = app.Services.CreateScope();
    var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
    await db.Database.MigrateAsync();
}

app.Run();
```

### 5.2 Manual Migration (Production)

**Generate SQL Script**
```bash
# Generate migration script
dotnet ef migrations script \
  --idempotent \
  --output migration.sql \
  --project Web.csproj

# Review script manually
cat migration.sql

# Apply to production database
sqlcmd -S sql-diskhastanesi-prod.database.windows.net \
  -d db-diskhastanesi-prod \
  -U sqladmin \
  -i migration.sql
```

**Azure DevOps Database Deployment Task**
```yaml
- task: SqlAzureDacpacDeployment@1
  displayName: 'Run Database Migrations'
  inputs:
    azureSubscription: $(azureSubscription)
    ServerName: 'sql-diskhastanesi-prod.database.windows.net'
    DatabaseName: 'db-diskhastanesi-prod'
    SqlUsername: $(sqlAdminUsername)
    SqlPassword: $(sqlAdminPassword)
    deployType: 'SqlTask'
    SqlFile: '$(Pipeline.Workspace)/drop/migration.sql'
```

---

## 6. Monitoring & Health Checks

### 6.1 Application Health Endpoint

**Implementation**
```csharp
// Program.cs
app.MapHealthChecks("/health", new HealthCheckOptions
{
    ResponseWriter = async (context, report) =>
    {
        context.Response.ContentType = "application/json";
        
        var result = JsonSerializer.Serialize(new
        {
            status = report.Status.ToString(),
            checks = report.Entries.Select(e => new
            {
                name = e.Key,
                status = e.Value.Status.ToString(),
                description = e.Value.Description,
                duration = e.Value.Duration.TotalMilliseconds
            }),
            totalDuration = report.TotalDuration.TotalMilliseconds
        });
        
        await context.Response.WriteAsync(result);
    }
});

// Add health checks
builder.Services.AddHealthChecks()
    .AddDbContextCheck<AppDbContext>()
    .AddAzureBlobStorage(
        builder.Configuration["Storage:ConnectionString"],
        name: "blob-storage")
    .AddApplicationInsightsPublisher();
```

### 6.2 Azure Monitor Alerts

**Create Alert Rules**
```bash
# HTTP 5xx errors
az monitor metrics alert create \
  --name "HTTP 5xx Errors" \
  --resource-group rg-diskhastanesi-prod \
  --scopes /subscriptions/{sub-id}/resourceGroups/rg-diskhastanesi-prod/providers/Microsoft.Web/sites/app-diskhastanesi-prod \
  --condition "avg Http5xx > 10" \
  --window-size 5m \
  --evaluation-frequency 1m \
  --action /subscriptions/{sub-id}/resourceGroups/rg-diskhastanesi-prod/providers/microsoft.insights/actionGroups/ag-oncall

# Response time
az monitor metrics alert create \
  --name "High Response Time" \
  --resource-group rg-diskhastanesi-prod \
  --scopes /subscriptions/{sub-id}/resourceGroups/rg-diskhastanesi-prod/providers/Microsoft.Web/sites/app-diskhastanesi-prod \
  --condition "avg ResponseTime > 2000" \
  --window-size 5m \
  --evaluation-frequency 1m \
  --action /subscriptions/{sub-id}/resourceGroups/rg-diskhastanesi-prod/providers/microsoft.insights/actionGroups/ag-oncall
```

---

## 7. Backup & Disaster Recovery

### 7.1 Database Backup

**Automated Backups (Azure SQL)**
- Full backup: Weekly
- Differential backup: Every 12 hours
- Transaction log backup: Every 5-10 minutes
- Retention: 7 days (configurable up to 35 days)

**Long-Term Retention**
```bash
# Configure LTR policy
az sql db ltr-policy set \
  --resource-group rg-diskhastanesi-prod \
  --server sql-diskhastanesi-prod \
  --database db-diskhastanesi-prod \
  --weekly-retention P4W \
  --monthly-retention P12M \
  --yearly-retention P7Y \
  --week-of-year 1
```

### 7.2 Point-in-Time Restore

**Restore Database**
```bash
# Restore to specific point in time
az sql db restore \
  --resource-group rg-diskhastanesi-prod \
  --server sql-diskhastanesi-prod \
  --name db-diskhastanesi-prod-restored \
  --source-database db-diskhastanesi-prod \
  --time "2025-10-04T12:00:00Z"
```

### 7.3 Disaster Recovery Plan

**RPO (Recovery Point Objective): 5 minutes**
- Transaction log backups every 5-10 minutes

**RTO (Recovery Time Objective): 1 hour**
- Automated restore procedures
- Failover to secondary region (if geo-replication enabled)

**DR Procedures**
```bash
# 1. Detect outage
# 2. Assess impact
# 3. Notify stakeholders

# 4. Failover to secondary region (if configured)
az sql failover-group set-primary \
  --resource-group rg-diskhastanesi-prod \
  --server sql-diskhastanesi-secondary \
  --name fg-diskhastanesi

# 5. Update DNS/Front Door to point to secondary App Service
az network front-door backend-pool backend update \
  --front-door-name fd-diskhastanesi \
  --pool-name DefaultBackendPool \
  --resource-group rg-diskhastanesi-prod \
  --address app-diskhastanesi-secondary.azurewebsites.net

# 6. Verify service restored
curl https://diskhastanesi.com/health

# 7. Monitor for stability
# 8. Post-mortem analysis
```

---

## 8. Scaling Strategy

### 8.1 Auto-Scaling Rules

**Create Auto-Scale Profile**
```bash
# Create auto-scale settings
az monitor autoscale create \
  --resource-group rg-diskhastanesi-prod \
  --resource /subscriptions/{sub-id}/resourceGroups/rg-diskhastanesi-prod/providers/Microsoft.Web/serverfarms/asp-diskhastanesi-prod \
  --name autoscale-diskhastanesi \
  --min-count 2 \
  --max-count 10 \
  --count 2

# Scale out rule (CPU > 70%)
az monitor autoscale rule create \
  --resource-group rg-diskhastanesi-prod \
  --autoscale-name autoscale-diskhastanesi \
  --condition "Percentage CPU > 70 avg 5m" \
  --scale out 1

# Scale in rule (CPU < 30%)
az monitor autoscale rule create \
  --resource-group rg-diskhastanesi-prod \
  --autoscale-name autoscale-diskhastanesi \
  --condition "Percentage CPU < 30 avg 10m" \
  --scale in 1
```

### 8.2 Database Scaling

**Vertical Scaling**
```bash
# Scale up database tier
az sql db update \
  --resource-group rg-diskhastanesi-prod \
  --server sql-diskhastanesi-prod \
  --name db-diskhastanesi-prod \
  --service-objective S2 # S1 → S2
```

**Horizontal Scaling (Read Replicas)**
```bash
# Enable read-scale out (Business Critical tier only)
az sql db update \
  --resource-group rg-diskhastanesi-prod \
  --server sql-diskhastanesi-prod \
  --name db-diskhastanesi-prod \
  --read-scale Enabled
```

---

## 9. Security Hardening

### 9.1 Network Security

**Restrict App Service Access**
```bash
# Add IP restrictions
az webapp config access-restriction add \
  --resource-group rg-diskhastanesi-prod \
  --name app-diskhastanesi-prod \
  --rule-name "Office IP" \
  --action Allow \
  --ip-address 203.0.113.0/24 \
  --priority 100

# Add VNet integration
az webapp vnet-integration add \
  --resource-group rg-diskhastanesi-prod \
  --name app-diskhastanesi-prod \
  --vnet /subscriptions/{sub-id}/resourceGroups/rg-network/providers/Microsoft.Network/virtualNetworks/vnet-diskhastanesi \
  --subnet /subscriptions/{sub-id}/resourceGroups/rg-network/providers/Microsoft.Network/virtualNetworks/vnet-diskhastanesi/subnets/subnet-app
```

### 9.2 SQL Server Firewall

**Configure Firewall Rules**
```bash
# Remove "Allow Azure Services" rule (too permissive)
az sql server firewall-rule delete \
  --resource-group rg-diskhastanesi-prod \
  --server sql-diskhastanesi-prod \
  --name AllowAzureServices

# Add specific App Service outbound IPs
az webapp show \
  --resource-group rg-diskhastanesi-prod \
  --name app-diskhastanesi-prod \
  --query possibleOutboundIpAddresses -o tsv | \
  tr ',' '\n' | while read ip; do
    az sql server firewall-rule create \
      --resource-group rg-diskhastanesi-prod \
      --server sql-diskhastanesi-prod \
      --name "AppService-$ip" \
      --start-ip-address $ip \
      --end-ip-address $ip
  done
```

---

## 10. Cost Optimization

### 10.1 Resource Sizing

**Right-Sizing Recommendations**
```bash
# Get resource utilization metrics
az monitor metrics list \
  --resource /subscriptions/{sub-id}/resourceGroups/rg-diskhastanesi-prod/providers/Microsoft.Web/sites/app-diskhastanesi-prod \
  --metric "CpuPercentage" \
  --start-time 2025-09-01T00:00:00Z \
  --end-time 2025-10-01T00:00:00Z \
  --interval PT1H \
  --aggregation Average

# If average CPU < 20%, consider downgrading tier
```

### 10.2 Reserved Instances

**Purchase Reserved Capacity**
```bash
# 1-year or 3-year commitment for 30-60% discount
az reservation catalog show \
  --reserved-resource-type VirtualMachines \
  --location westeurope

# Purchase through Azure Portal (Reservations)
```

### 10.3 Dev/Test Pricing

**Enable Dev/Test Subscription**
- Visual Studio subscribers get discounted rates
- No production workloads allowed
- Save up to 50% on compute

---

**Son Güncelleme:** 2025-10-04
