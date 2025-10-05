# SQL'deki Dokümanlarý Görüntüle

$connectionString = "Server=(localdb)\MSSQLLocalDB;Database=DiskHastanesiDocs;Integrated Security=true;"

function Show-Documents {
    $connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
    $connection.Open()

    $command = $connection.CreateCommand()
    $command.CommandText = "SELECT Id, NormalizedTitle, Category, CharCount, CreatedAt FROM DocumentsStaging ORDER BY Id"
    
    $adapter = New-Object System.Data.SqlClient.SqlDataAdapter($command)
    $dataset = New-Object System.Data.DataSet
    $adapter.Fill($dataset) | Out-Null

    Write-Host "`n=== SQL'DEKÝ DOKÜMANLAR ===" -ForegroundColor Green
    Write-Host ""
    
    $dataset.Tables[0] | Format-Table -AutoSize
    
    $connection.Close()
}

function Show-DocumentDetail {
    param([int]$Id)
    
    $connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
    $connection.Open()

    $command = $connection.CreateCommand()
    $command.CommandText = "SELECT * FROM DocumentsStaging WHERE Id = @Id"
    $command.Parameters.AddWithValue("@Id", $Id) | Out-Null
    
    $reader = $command.ExecuteReader()
    
    if ($reader.Read()) {
        Write-Host "`n=== DOKÜMAN DETAYI (ID: $Id) ===" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Baþlýk       : $($reader['NormalizedTitle'])"
        Write-Host "Kategori     : $($reader['Category'])"
        Write-Host "Slug         : $($reader['Slug'])"
        Write-Host "Karakter     : $($reader['CharCount'])"
        Write-Host "Dosya Boyutu : $([math]::Round($reader['FileSize'] / 1KB, 2)) KB"
        Write-Host "Hash         : $($reader['FileHash'])"
        Write-Host "Tarih        : $($reader['CreatedAt'])"
        Write-Host ""
        Write-Host "--- ÝÇERÝK ÖNÝZLEMESÝ (Ýlk 500 karakter) ---" -ForegroundColor Yellow
        $preview = $reader['PlainText'].ToString().Substring(0, [Math]::Min(500, $reader['PlainText'].ToString().Length))
        Write-Host $preview
        Write-Host "..."
    }
    
    $reader.Close()
    $connection.Close()
}

function Export-DocumentToFile {
    param(
        [int]$Id,
        [string]$OutputPath
    )
    
    $connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
    $connection.Open()

    $command = $connection.CreateCommand()
    $command.CommandText = "SELECT NormalizedTitle, PlainText, HtmlContent FROM DocumentsStaging WHERE Id = @Id"
    $command.Parameters.AddWithValue("@Id", $Id) | Out-Null
    
    $reader = $command.ExecuteReader()
    
    if ($reader.Read()) {
        $title = $reader['NormalizedTitle']
        $plainText = $reader['PlainText']
        $htmlContent = $reader['HtmlContent']
        
        # Plain text dosyasý
        $plainText | Out-File -FilePath "$OutputPath\$Id-$title.txt" -Encoding UTF8
        
        # HTML dosyasý
        $htmlContent | Out-File -FilePath "$OutputPath\$Id-$title.html" -Encoding UTF8
        
        Write-Host "? Dosyalar oluþturuldu:" -ForegroundColor Green
        Write-Host "   $OutputPath\$Id-$title.txt"
        Write-Host "   $OutputPath\$Id-$title.html"
    }
    
    $reader.Close()
    $connection.Close()
}

# Ana Menü
Write-Host @"

?????????????????????????????????????????????????
?   SQL DOKÜMAN GÖRÜNTÜLEYÝCÝ                  ?
?????????????????????????????????????????????????

Komutlar:
  Show-Documents                    ? Tüm dokümanlarý listele
  Show-DocumentDetail -Id X         ? ID'ye göre detay göster
  Export-DocumentToFile -Id X -OutputPath "C:\Temp" ? Dosyaya aktar

Örnek: Show-DocumentDetail -Id 2

"@ -ForegroundColor Cyan

Show-Documents
