using DocumentFormat.OpenXml.Packaging;
using DocumentFormat.OpenXml.Wordprocessing;
using System.Text;
using System.Data.SqlClient;
using System.Security.Cryptography;

class Program
{
    static string connString = @"Server=(localdb)\MSSQLLocalDB;Database=DiskHastanesiDocs;Integrated Security=true;";
    
    static void Main(string[] args)
    {
        string folderPath = @"C:\Projeler\DiskHastanesi\ProjeDosyaları";
        var docxFiles = Directory.GetFiles(folderPath, "*.docx");

        Console.WriteLine("=== DOCX → SQL AKTARIMI BAŞLIYOR ===\n");
        Console.WriteLine($"Toplam {docxFiles.Length} dosya bulundu.\n");

        int successCount = 0;

        foreach (var file in docxFiles)
        {
            try
            {
                Console.WriteLine($"İşleniyor: {Path.GetFileName(file)}");
                
                var doc = ProcessDocument(file);
                InsertToDatabase(doc);
                
                Console.WriteLine($"✅ Başarılı: {doc.NormalizedTitle}");
                Console.WriteLine($"   Kategori: {doc.Category}");
                Console.WriteLine($"   Karakter: {doc.CharCount:N0}");
                Console.WriteLine($"   Boyut: {doc.FileSize / 1024:N0} KB\n");
                
                successCount++;
            }
            catch (Exception ex)
            {
                Console.WriteLine($"❌ HATA: {ex.Message}\n");
            }
        }

        Console.WriteLine($"\n=== ÖZET ===");
        Console.WriteLine($"Başarılı: {successCount}/{docxFiles.Length}");
        Console.WriteLine($"\nSQL'de görüntülemek için:");
        Console.WriteLine($"sqlcmd -S \"(localdb)\\MSSQLLocalDB\" -d DiskHastanesiDocs -Q \"SELECT Id, NormalizedTitle, Category, CharCount FROM DocumentsStaging\"");
    }

    static DocumentInfo ProcessDocument(string filePath)
    {
        var doc = new DocumentInfo
        {
            OriginalFileName = Path.GetFileName(filePath),
            FileSize = new FileInfo(filePath).Length
        };

        // Başlık normalize et
        doc.NormalizedTitle = NormalizeTitle(doc.OriginalFileName);
        doc.Slug = CreateSlug(doc.NormalizedTitle);
        doc.Category = DetermineCategory(doc.OriginalFileName);

        // İçerik çıkar
        var plainText = new StringBuilder();
        var htmlContent = new StringBuilder();
        htmlContent.AppendLine("<div class='document-content'>");

        using (WordprocessingDocument wordDoc = WordprocessingDocument.Open(filePath, false))
        {
            var body = wordDoc.MainDocumentPart?.Document?.Body;
            if (body != null)
            {
                foreach (var paragraph in body.Descendants<Paragraph>())
                {
                    var text = paragraph.InnerText.Trim();
                    if (!string.IsNullOrWhiteSpace(text))
                    {
                        plainText.AppendLine(text);
                        
                        // Basit HTML formatı
                        var isBold = paragraph.Descendants<Bold>().Any();
                        if (isBold)
                            htmlContent.AppendLine($"<p><strong>{System.Web.HttpUtility.HtmlEncode(text)}</strong></p>");
                        else
                            htmlContent.AppendLine($"<p>{System.Web.HttpUtility.HtmlEncode(text)}</p>");
                    }
                }
            }
        }

        htmlContent.AppendLine("</div>");

        doc.PlainText = plainText.ToString();
        doc.HtmlContent = htmlContent.ToString();
        doc.CharCount = doc.PlainText.Length;
        doc.FileHash = ComputeHash(doc.PlainText);

        return doc;
    }

    static void InsertToDatabase(DocumentInfo doc)
    {
        using (var conn = new SqlConnection(connString))
        {
            conn.Open();
            var cmd = new SqlCommand(@"
                INSERT INTO DocumentsStaging 
                (OriginalFileName, NormalizedTitle, Slug, Category, HtmlContent, PlainText, CharCount, FileHash, FileSize)
                VALUES 
                (@OriginalFileName, @NormalizedTitle, @Slug, @Category, @HtmlContent, @PlainText, @CharCount, @FileHash, @FileSize)",
                conn);

            cmd.Parameters.AddWithValue("@OriginalFileName", doc.OriginalFileName);
            cmd.Parameters.AddWithValue("@NormalizedTitle", doc.NormalizedTitle);
            cmd.Parameters.AddWithValue("@Slug", doc.Slug);
            cmd.Parameters.AddWithValue("@Category", doc.Category);
            cmd.Parameters.AddWithValue("@HtmlContent", doc.HtmlContent);
            cmd.Parameters.AddWithValue("@PlainText", doc.PlainText);
            cmd.Parameters.AddWithValue("@CharCount", doc.CharCount);
            cmd.Parameters.AddWithValue("@FileHash", doc.FileHash);
            cmd.Parameters.AddWithValue("@FileSize", doc.FileSize);

            cmd.ExecuteNonQuery();
        }
    }

    static string NormalizeTitle(string fileName)
    {
        var title = Path.GetFileNameWithoutExtension(fileName);
        
        // "0-0-0-" gibi ön ekleri kaldır
        if (title.StartsWith("0-0-0-"))
            title = title.Substring(6);
        
        // " - ChatGPT" veya " - GeminiPro" gibi son ekleri kaldır
        title = System.Text.RegularExpressions.Regex.Replace(title, @"\s*-\s*(ChatGPT|GeminiPro)\s*$", "");
        
        return title.Trim();
    }

    static string CreateSlug(string title)
    {
        var slug = title.ToLowerInvariant();
        
        // Türkçe karakterleri değiştir
        slug = slug.Replace("ı", "i").Replace("ğ", "g").Replace("ü", "u")
                   .Replace("ş", "s").Replace("ö", "o").Replace("ç", "c");
        
        // Özel karakterleri kaldır
        slug = System.Text.RegularExpressions.Regex.Replace(slug, @"[^a-z0-9\s-]", "");
        slug = System.Text.RegularExpressions.Regex.Replace(slug, @"\s+", "-");
        
        return slug;
    }

    static string DetermineCategory(string fileName)
    {
        if (fileName.Contains("CMS Admin"))
            return "Teknik Dokümantasyon / CMS";
        else if (fileName.Contains("Ürün ve Hizmet"))
            return "Ürün Katalog / Güncel";
        else if (fileName.Contains("CRM Gereksinim"))
            return "Teknik Dokümantasyon / CRM";
        else if (fileName.Contains("Stratejik Yol"))
            return "Strateji ve Planlama";
        else if (fileName.Contains("Web Siesi") || fileName.Contains("Web Sitesi"))
            return "Web Sitesi / Yapı";
        else if (fileName.Contains("Hakkımızda") || fileName.Contains("Hakkimizda"))
            return "Web Sitesi / Kurumsal İçerik";
        else if (fileName.Contains("Talep") || fileName.Contains("Form"))
            return "Web Sitesi / Formlar";
        else
            return "Genel";
    }

    static string ComputeHash(string text)
    {
        using (var sha256 = SHA256.Create())
        {
            var bytes = Encoding.UTF8.GetBytes(text);
            var hash = sha256.ComputeHash(bytes);
            return BitConverter.ToString(hash).Replace("-", "").ToLowerInvariant();
        }
    }
}

class DocumentInfo
{
    public string OriginalFileName { get; set; }
    public string NormalizedTitle { get; set; }
    public string Slug { get; set; }
    public string Category { get; set; }
    public string HtmlContent { get; set; }
    public string PlainText { get; set; }
    public int CharCount { get; set; }
    public string FileHash { get; set; }
    public long FileSize { get; set; }
}
