# ��erik �retim & AI Konseyi Ba�l�k Hiyerar�isi (H1)

## 1. AI Konseyi Roller (H2)
### 1.1 Roller Listesi (H3)
#### 1.1.1 Content Architect AI (H4)
##### G�rev (H5)
Sayfa iskeleti (H1�H3), ama�, kullan�c� intent ��kar�m�.
##### ��kt� (H5)
JSON blok tasla�� + heading hiyerar�isi.

#### 1.1.2 Value Proposition Optimizer AI (H4)
##### G�rev (H5)
Persona odakl� fayda c�mleleri & KPI uyumu.
##### ��kt� (H5)
Fayda tablosu + �nerilen H2 a��klama paragraf�.

#### 1.1.3 Psychology Layer AI (H4)
##### G�rev (H5)
Paragraflara psikolojik ikna etiketleri atama.
##### Etiket Format� (H5)
`{ "paragraphIndex":0, "techniques":["Authority","RiskReduction"] }`

#### 1.1.4 SEO & Schema AI (H4)
##### G�rev (H5)
Title, MetaDescription, OpenGraph/Twitter, JSON-LD (Service/FAQ/Article).

#### 1.1.5 Fluent UI Layout AI (H4)
##### G�rev (H5)
Blok ? bile�en e�leme (Hero, FAQ, KPI, Testimonial).

#### 1.1.6 Media Planner AI (H4)
##### G�rev (H5)
G�rsel / ikon / video placeholder �retimi.

#### 1.1.7 Compliance & Risk AI (H4)
##### G�rev (H5)
A��r� iddia / yasakl� kelime / eksik kaynak taramas�.

#### 1.1.8 Version & Knowledge Sync AI (H4)
##### G�rev (H5)
#fetch girdilerini s�n�fland�rma, SystemMetadata & TrustedKnowledgeBase senkronu.

## 2. S�re� Pipeline (H2)
### 2.1 Ad�m S�ras� (H3)
1. Skeleton (Content Architect)
2. Value Proposition layer
3. Psychology etiketleri
4. SEO / Schema otomasyonu
5. Fluent UI bile�en e�leme
6. Media placeholder �retimi
7. Risk / Compliance taramas�
8. Persist (SQL + versiyon g�ncelle)

### 2.2 Persist Noktalar� (H3)
- ContentVersions.ContentJson: blok + psikoloji etiketleri
- SeoMetadata: meta alanlar�
- SchemaDefinitions: JSON-LD tip koleksiyonu
- TrustedKnowledgeBase: harici kaynak �zetleri
- SystemMetadata: s�r�m/versiyon anahtarlar�

## 3. Ba�l�k �skeleti Kurallar� (H2)
### 3.1 Hiyerar�i (H3)
- H1: Tekil, sayfan�n ana amac�
- H2: B�l�m (value segment / alt konu)
- H3: Alt detay / task / fayda
- H4: Mikro a��klama veya varyant
- H5: Yap�sal meta / kuralsal not

### 3.2 Zorunluluklar (H3)
#### 3.2.1 H1 (H4)
##### Kurallar (H5)
- 60 karakteri a�maz
- Birincil anahtar kelime + de�er �nerisi
#### 3.2.2 H2 (H4)
##### Kurallar (H5)
- Fayda veya problem ifadesi i�erir
- En az 2, en fazla 8 adet
#### 3.2.3 H3�H5 (H4)
##### Kurallar (H5)
- H3: Destekleyici arg�man
- H4: Teknik veya s�re� alt k�r�l�m�
- H5: Etiket / referans / placeholder

## 4. Psikolojik Teknik Katalo�u (H2)
### 4.1 �ekirdek Teknikler (H3)
#### 4.1.1 Authority (H4)
##### Tan�m (H5) Otorite kan�t� (sertifika, deneyim y�l�).
#### 4.1.2 SocialProof (H4)
##### Tan�m (H5) Referans, vaka, istatistik.
#### 4.1.3 RiskReduction (H4)
##### Tan�m (H5) Garanti, �effaf s�re�, kalite standard�.
#### 4.1.4 LossAversion (H4)
##### Tan�m (H5) Ka��rma senaryosu hafif vurgusu.
#### 4.1.5 CognitiveFluency (H4)
##### Tan�m (H5) Basit, h�zl� okunur a��klama.
#### 4.1.6 Anchoring (H4)
##### Tan�m (H5) �lk referans de�ere g�re alg� �er�evesi.
#### 4.1.7 CommitmentConsistency (H4)
##### Tan�m (H5) K���k ad�m ? daha b�y�k kat�l�m.
#### 4.1.8 Reciprocity (H4)
##### Tan�m (H5) �cretsiz de�er ? g�ven / d�n���m.
#### 4.1.9 Framing (H4)
##### Tan�m (H5) Bilgiyi avantaj penceresinden sunma.
#### 4.1.10 CredibilitySignals (H4)
##### Tan�m (H5) Logo, sertifika, ba��ms�z test.

## 5. SEO & Schema Kurallar� (H2)
### 5.1 Meta (H3)
#### 5.1.1 Title (H4)
##### �l��t (H5) ? 60 karakter, anahtar kelime ba�a yak�n.
#### 5.1.2 MetaDescription (H4)
##### �l��t (H5) 145�155 karakter, bir CTA.

### 5.2 JSON-LD Tipleri (H3)
#### 5.2.1 Service (H4)
##### Alanlar (H5) name, description, provider, areaServed.
#### 5.2.2 FAQ (H4)
##### Alanlar (H5) question, acceptedAnswer (?120 kelime).
#### 5.2.3 Article (H4)
##### Alanlar (H5) headline, datePublished, author, mainEntityOfPage.

### 5.3 Do�rulama (H3)
- Duplicate title ? uyar�
- FAQ answer > 200 kelime ? k�rm�z� bayrak
- Eksik canonical ? ekle

## 6. Fluent UI Bile�en E�leme (H2)
### 6.1 Blok ? Bile�en (H3)
#### 6.1.1 Hero (H4)
##### �neri (H5) `fluent-card` + display token + CTA button.
#### 6.1.2 FAQ (H4)
##### �neri (H5) `fluent-accordion`.
#### 6.1.3 KPI Bar (H4)
##### �neri (H5) Custom badge + semantic token.
#### 6.1.4 Testimonial (H4)
##### �neri (H5) `fluent-card` + quote pattern.

### 6.2 Tema & Token (H3)
#### 6.2.1 Kaydedilecek Anahtarlar (H4)
##### SystemMetadata (H5)
- FluentUI_Version
- AccentColor / NeutralLayer varyant notlar� (iste�e ba�l� geni�leme)

## 7. Media Placeholder Format� (H2)
### 7.1 JSON �ema (H3)
`{ "blockId":"hero_1", "mediaType":"image|video|icon", "status":"missing", "suggestedAlt":"Kurumsal veri kurtarma laboratuvar�" }`
### 7.2 ��erik Enjeksiyon Notasyonu (H3)
`[MEDIA: image � gelecekte eklenecek]`

## 8. 2025 G�ncelleme #fetch Checklist (H2)
### 8.1 Ba�l�klar (H3)
#### 8.1.1 Fluent UI S�r�m (H4)
##### Format (H5)
`#fetch META { "scope":"fluentui","retrievedAt":"2025-..","version":"X.Y.Z" }`
#### 8.1.2 Schema.org S�r�m (H4)
##### Format (H5)
`#fetch META { "scope":"schema","retrievedAt":"2025-..","version":"NN.N" }`
#### 8.1.3 Core Update (H4)
##### Format (H5)
`#fetch META { "scope":"seo","retrievedAt":"2025-..","changeType":"core-update" }`
#### 8.1.4 Core Web Vitals (H4)
##### Format (H5)
`#fetch META { "scope":"webvitals","retrievedAt":"2025-.." }`

## 9. SQL Entegrasyon Noktalar� (H2)
### 9.1 Prosed�rler (H3)
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
### 10.1 Risk S�zl��� (H3)
#### 10.1.1 Flag Anahtar Kelimeler (H4)
##### �rnekler (H5) "%100", "garanti", "s�n�rs�z", "bedelsiz" (kontroll�). 
### 10.2 ContentQuality �nerisi (H3)
#### 10.2.1 Basit Metrikler (H4)
##### Ba�lang�� (H5)
- Ortalama paragraf uzunlu�u
- Etiket da��l�m dengesi (Authority ? %30)
- Internal link say�s�

---
Bu belge otomatik �retim pipeline��nda AI konsey ajanlar�n�n ba�l�k hiyerar�isine g�re nas�l i�erik t�retece�ini standardize eder.
