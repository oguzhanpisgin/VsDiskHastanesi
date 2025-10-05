# Ýçerik Üretim & AI Konseyi Baþlýk Hiyerarþisi (H1)

## 1. AI Konseyi Roller (H2)
### 1.1 Roller Listesi (H3)
#### 1.1.1 Content Architect AI (H4)
##### Görev (H5)
Sayfa iskeleti (H1–H3), amaç, kullanýcý intent çýkarýmý.
##### Çýktý (H5)
JSON blok taslaðý + heading hiyerarþisi.

#### 1.1.2 Value Proposition Optimizer AI (H4)
##### Görev (H5)
Persona odaklý fayda cümleleri & KPI uyumu.
##### Çýktý (H5)
Fayda tablosu + önerilen H2 açýklama paragrafý.

#### 1.1.3 Psychology Layer AI (H4)
##### Görev (H5)
Paragraflara psikolojik ikna etiketleri atama.
##### Etiket Formatý (H5)
`{ "paragraphIndex":0, "techniques":["Authority","RiskReduction"] }`

#### 1.1.4 SEO & Schema AI (H4)
##### Görev (H5)
Title, MetaDescription, OpenGraph/Twitter, JSON-LD (Service/FAQ/Article).

#### 1.1.5 Fluent UI Layout AI (H4)
##### Görev (H5)
Blok ? bileþen eþleme (Hero, FAQ, KPI, Testimonial).

#### 1.1.6 Media Planner AI (H4)
##### Görev (H5)
Görsel / ikon / video placeholder üretimi.

#### 1.1.7 Compliance & Risk AI (H4)
##### Görev (H5)
Aþýrý iddia / yasaklý kelime / eksik kaynak taramasý.

#### 1.1.8 Version & Knowledge Sync AI (H4)
##### Görev (H5)
#fetch girdilerini sýnýflandýrma, SystemMetadata & TrustedKnowledgeBase senkronu.

## 2. Süreç Pipeline (H2)
### 2.1 Adým Sýrasý (H3)
1. Skeleton (Content Architect)
2. Value Proposition layer
3. Psychology etiketleri
4. SEO / Schema otomasyonu
5. Fluent UI bileþen eþleme
6. Media placeholder üretimi
7. Risk / Compliance taramasý
8. Persist (SQL + versiyon güncelle)

### 2.2 Persist Noktalarý (H3)
- ContentVersions.ContentJson: blok + psikoloji etiketleri
- SeoMetadata: meta alanlarý
- SchemaDefinitions: JSON-LD tip koleksiyonu
- TrustedKnowledgeBase: harici kaynak özetleri
- SystemMetadata: sürüm/versiyon anahtarlarý

## 3. Baþlýk Ýskeleti Kurallarý (H2)
### 3.1 Hiyerarþi (H3)
- H1: Tekil, sayfanýn ana amacý
- H2: Bölüm (value segment / alt konu)
- H3: Alt detay / task / fayda
- H4: Mikro açýklama veya varyant
- H5: Yapýsal meta / kuralsal not

### 3.2 Zorunluluklar (H3)
#### 3.2.1 H1 (H4)
##### Kurallar (H5)
- 60 karakteri aþmaz
- Birincil anahtar kelime + deðer önerisi
#### 3.2.2 H2 (H4)
##### Kurallar (H5)
- Fayda veya problem ifadesi içerir
- En az 2, en fazla 8 adet
#### 3.2.3 H3–H5 (H4)
##### Kurallar (H5)
- H3: Destekleyici argüman
- H4: Teknik veya süreç alt kýrýlýmý
- H5: Etiket / referans / placeholder

## 4. Psikolojik Teknik Kataloðu (H2)
### 4.1 Çekirdek Teknikler (H3)
#### 4.1.1 Authority (H4)
##### Taným (H5) Otorite kanýtý (sertifika, deneyim yýlý).
#### 4.1.2 SocialProof (H4)
##### Taným (H5) Referans, vaka, istatistik.
#### 4.1.3 RiskReduction (H4)
##### Taným (H5) Garanti, þeffaf süreç, kalite standardý.
#### 4.1.4 LossAversion (H4)
##### Taným (H5) Kaçýrma senaryosu hafif vurgusu.
#### 4.1.5 CognitiveFluency (H4)
##### Taným (H5) Basit, hýzlý okunur açýklama.
#### 4.1.6 Anchoring (H4)
##### Taným (H5) Ýlk referans deðere göre algý çerçevesi.
#### 4.1.7 CommitmentConsistency (H4)
##### Taným (H5) Küçük adým ? daha büyük katýlým.
#### 4.1.8 Reciprocity (H4)
##### Taným (H5) Ücretsiz deðer ? güven / dönüþüm.
#### 4.1.9 Framing (H4)
##### Taným (H5) Bilgiyi avantaj penceresinden sunma.
#### 4.1.10 CredibilitySignals (H4)
##### Taným (H5) Logo, sertifika, baðýmsýz test.

## 5. SEO & Schema Kurallarý (H2)
### 5.1 Meta (H3)
#### 5.1.1 Title (H4)
##### Ölçüt (H5) ? 60 karakter, anahtar kelime baþa yakýn.
#### 5.1.2 MetaDescription (H4)
##### Ölçüt (H5) 145–155 karakter, bir CTA.

### 5.2 JSON-LD Tipleri (H3)
#### 5.2.1 Service (H4)
##### Alanlar (H5) name, description, provider, areaServed.
#### 5.2.2 FAQ (H4)
##### Alanlar (H5) question, acceptedAnswer (?120 kelime).
#### 5.2.3 Article (H4)
##### Alanlar (H5) headline, datePublished, author, mainEntityOfPage.

### 5.3 Doðrulama (H3)
- Duplicate title ? uyarý
- FAQ answer > 200 kelime ? kýrmýzý bayrak
- Eksik canonical ? ekle

## 6. Fluent UI Bileþen Eþleme (H2)
### 6.1 Blok ? Bileþen (H3)
#### 6.1.1 Hero (H4)
##### Öneri (H5) `fluent-card` + display token + CTA button.
#### 6.1.2 FAQ (H4)
##### Öneri (H5) `fluent-accordion`.
#### 6.1.3 KPI Bar (H4)
##### Öneri (H5) Custom badge + semantic token.
#### 6.1.4 Testimonial (H4)
##### Öneri (H5) `fluent-card` + quote pattern.

### 6.2 Tema & Token (H3)
#### 6.2.1 Kaydedilecek Anahtarlar (H4)
##### SystemMetadata (H5)
- FluentUI_Version
- AccentColor / NeutralLayer varyant notlarý (isteðe baðlý geniþleme)

## 7. Media Placeholder Formatý (H2)
### 7.1 JSON Þema (H3)
`{ "blockId":"hero_1", "mediaType":"image|video|icon", "status":"missing", "suggestedAlt":"Kurumsal veri kurtarma laboratuvarý" }`
### 7.2 Ýçerik Enjeksiyon Notasyonu (H3)
`[MEDIA: image – gelecekte eklenecek]`

## 8. 2025 Güncelleme #fetch Checklist (H2)
### 8.1 Baþlýklar (H3)
#### 8.1.1 Fluent UI Sürüm (H4)
##### Format (H5)
`#fetch META { "scope":"fluentui","retrievedAt":"2025-..","version":"X.Y.Z" }`
#### 8.1.2 Schema.org Sürüm (H4)
##### Format (H5)
`#fetch META { "scope":"schema","retrievedAt":"2025-..","version":"NN.N" }`
#### 8.1.3 Core Update (H4)
##### Format (H5)
`#fetch META { "scope":"seo","retrievedAt":"2025-..","changeType":"core-update" }`
#### 8.1.4 Core Web Vitals (H4)
##### Format (H5)
`#fetch META { "scope":"webvitals","retrievedAt":"2025-.." }`

## 9. SQL Entegrasyon Noktalarý (H2)
### 9.1 Prosedürler (H3)
- sp_AddExternalKnowledge
- sp_GenerateDataDictionary
- sp_UpdateSchemaBaseline
- sp_VersionSummary
### 9.2 Tablolar (H3)
- SystemMetadata
- TrustedKnowledgeBase
- SchemaDefinitions
- SeoMetadata
- ContentVersions

## 10. Kalite ve Risk Kontrolleri (H2)
### 10.1 Risk Sözlüðü (H3)
#### 10.1.1 Flag Anahtar Kelimeler (H4)
##### Örnekler (H5) "%100", "garanti", "sýnýrsýz", "bedelsiz" (kontrollü). 
### 10.2 ContentQuality Önerisi (H3)
#### 10.2.1 Basit Metrikler (H4)
##### Baþlangýç (H5)
- Ortalama paragraf uzunluðu
- Etiket daðýlým dengesi (Authority ? %30)
- Internal link sayýsý

---
Bu belge otomatik üretim pipeline’ýnda AI konsey ajanlarýnýn baþlýk hiyerarþisine göre nasýl içerik türeteceðini standardize eder.
