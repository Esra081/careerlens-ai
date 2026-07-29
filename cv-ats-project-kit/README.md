# CV-ATS Project Kit — Antigravity Agent Paketi

Bu paket, CV analiz & ATS eşleştirme mobil uygulamasını Antigravity (Gemini agent)
ile verimli şekilde geliştirmek için hazırlanmış **agent yönlendirme dosyalarını**
içerir. Amaç: proje arkadaşının yapıyı hatırlamadığı ve ilan verisini çekemediği
noktadan, net ve önceliklendirilmiş bir geliştirme akışına geçmek.

## İçerik
```
cv-ats-project-kit/
├── README.md                 ← bu dosya
├── MASTER_PLAN.md            ← fazlı yol haritası (önce veri, sonra geliştirme)
├── AGENTS.md                 ← kök standing instructions (Antigravity otomatik okur)
└── .agents/
    ├── skills/               ← görev-spesifik skill'ler (agent otomatik yükler)
    │   ├── job-data-ingestion/SKILL.md   ← FAZ 0: ücretsiz ilan çekme (ÖNCE BU)
    │   ├── cv-parsing/SKILL.md           ← FAZ 1: CV → yapılandırılmış JSON
    │   ├── matching-engine/SKILL.md      ← FAZ 2: gerçek eşleştirme (asıl değer)
    │   └── ats-scoring/SKILL.md          ← FAZ 3: ATS rubriği
    └── workflows/
        └── bootstrap-project.md          ← ilk oturumda çalıştır
```

## Kurulum (Antigravity)
1. Bu klasörün **içeriğini projenin kök dizinine** kopyala (`.agents/` dahil).
   - Antigravity varsayılan olarak `.agents/skills/` yolunu okur. Eski sürüm
     kullanıyorsan `.agent/skills/` olarak da çalışır.
2. `AGENTS.md` kök dizinde olsun — Antigravity her oturumda otomatik okur.
3. Antigravity'de yeni oturum aç, Manager view'da bir agent'a şunu söyle:
   > "bootstrap-project workflow'unu çalıştır: codebase'i haritalandır, teşhisleri
   > doğrula, sonra MASTER_PLAN.md'deki FAZ 0'ı başlat."
4. Agent keşfi bitirince, fazları sırayla onaylayarak ilerlet (review-driven mod önerilir).

## Skill'ler nasıl çalışır
Agent oturum başında skill'lerin **isim + description**'ını görür. Bir görev bir
skill'in description'ıyla eşleşince agent o SKILL.md'yi tam okuyup uygular. Yani
"ilanları çek" dediğinde `job-data-ingestion` otomatik devreye girer.

## Kritik hatırlatmalar
- Sıra önemli: **FAZ 0 (veri) → 1 → 2 → 3 → 4.** Veri gelmeden diğerleri anlamsız.
- Skorlar gerçek ve açıklanabilir olmalı; placeholder yasak.
- LinkedIn/Kariyer.net doğrudan scraping yok; ücretsiz API'ler var.
- Hepsi ücretsiz/açık kaynak; bütçe gerektirmez (JSearch ücretsiz katman yeterli).

## Sonraki adım için not
Proje arkadaşı stack'i (Flutter / React Native / backend) netleştirdiğinde,
`AGENTS.md`'nin "Kod standartları" bölümü ve skill'lerdeki `requires` blokları
o stack'e göre özelleştirilebilir.
