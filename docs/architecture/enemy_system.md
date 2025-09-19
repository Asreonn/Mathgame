# Düşman Sistemi Dokümantasyonu (v2.0)

## Genel Felsefe

Mathgame'deki düşman sistemi, oyuncunun combo performansına dinamik olarak adapte olacak şekilde yeniden tasarlandı. Temel amaç, yüksek combo'sunu koruyan yetenekli bir oyuncuyu hızlı ve akıcı bir oyun deneyimiyle ödüllendirmek, ancak combo'su bozulan oyuncuya artan bir zorluk sunmaktır.

Can değerleri (`base_hp`), yüksek combo'larda (örn. 100+) düşmanların 1-2 vuruşta yenileceği, düşük combo'larda ise daha fazla vuruş gerektireceği şekilde dengelenmiştir.

## Katman ve Seviye Sistemi

Oyun, 10 katmandan oluşur. Her katmanın düşman havuzu, o katmanın seviyesine göre belirlenir.

- **Normal Düşman Seviyesi:** Karşılaşılan katman numarasına eşittir. (Örn: Katman 7'de Seviye 7 normal düşmanlar bulunur).
- **Boss Düşman Seviyesi:** Karşılaşılan katman numarasından **2 seviye** yüksektir. (Örn: Katman 7'de Seviye 9 boss'lar bulunur).

Bu sistem, 12 farklı düşman seviyesi oluşturur.

## Katman Başına Düşman Dağılımı

Her katmanda oyuncu toplam 10 düşmanla karşılaşır. Bu düşmanların dağılımı, oyuncuya çeşitlilik sunmak için havuzdan rastgele seçilir:

- **8 Normal Düşman**
- **2 Boss Düşman**

## Zorluk Seviyeleri ve Değer Aralıkları

Düşmanların `base_hp` değeri türüne (Normal/Boss) göre belirlenirken, `base_damage_multiplier` doğrudan seviyeye bağlıdır.

### Can (HP) Değerleri

- **Normal Düşman `base_hp` Aralığı:** 120 - 180
- **Boss Düşman `base_hp` Aralığı:** Seviyeye göre 350'den başlayıp 2000'e kadar yükselir.

### Hasar Çarpanı (Seviyeye Göre)

| Seviye | Tür    | `base_damage_multiplier` Aralığı | Notlar                               |
|--------|--------|----------------------------------|--------------------------------------|
| 1      | Normal | 0.8 - 1.0                        | Katman 1 Normal                      |
| 2      | Normal | 1.0 - 1.3                        | Katman 2 Normal                      |
| 3      | Normal | 1.3 - 1.6                        | Katman 3 Normal / Katman 1 Boss      |
| 4      | Normal | 1.6 - 2.0                        | Katman 4 Normal / Katman 2 Boss      |
| 5      | Normal | 2.0 - 2.5                        | Katman 5 Normal / Katman 3 Boss      |
| 6      | Normal | 2.5 - 3.1                        | Katman 6 Normal / Katman 4 Boss      |
| 7      | Normal | 3.1 - 3.8                        | Katman 7 Normal / Katman 5 Boss      |
| 8      | Normal | 3.8 - 4.6                        | Katman 8 Normal / Katman 6 Boss      |
| 9      | Normal | 4.6 - 5.5                        | Katman 9 Normal / Katman 7 Boss      |
| 10     | Normal | 5.5 - 6.5                        | Katman 10 Normal / Katman 8 Boss     |
| 11     | Boss   | 6.5 - 7.8                        | Katman 9 Boss                        |
| 12     | Boss   | 7.8 - 9.5                        | Katman 10 Boss                       |

## Katman Bazlı HP ve Hasar Artışı (Scaling)

CSV dosyasındaki `base` değerleri, oyun içi formüllerle her katman için artırılır. Bu, oyunun ilerledikçe zorlaşmasını sağlar.

- **`Final HP = base_hp * (1 + (katman - 1) * 0.15)`**
- **`Final Damage Multiplier = base_damage_multiplier * (1 + (katman - 1) * 0.1)`**

**Örnek:** 150 `base_hp`'ye sahip bir düşman;
- **Katman 1'de:** 150 HP'ye sahiptir. (100 combo ile ~1 vuruş)
- **Katman 10'da:** `150 * (1 + 9 * 0.15)` = `352.5` HP'ye sahiptir. (100 combo ile ~3 vuruş)

## CSV Veri Yapısı

Veri yapısı değişmemiştir.

| Sütun | Açıklama |
|-------|----------|
| enemy_id | Benzersiz düşman kimliği |
| enemy_name | Düşman adı |
| enemy_emoji | Düşman emojisi |
| base_hp | Temel can değeri (Dengeleme bu değer üzerinden yapılır) |
| base_damage_multiplier | Temel hasar çarpanı (Seviyeye göre belirlenir) |
| difficulty_level | Zorluk seviyesi (1-12) |
| enemy_type | "normal" veya "boss" |
| special_ability_id | Özel yetenek kimliği (opsiyonel) |
| special_ability_description | Özel yetenek açıklaması (opsiyonel) |

## Yeni Özel Yetenekler (Örnekler)

- **combo_drain:** Oyuncunun combo'sunun bir kısmını çalar.
- **hp_regen:** Zamanla canını yeniler.
- **damage_reflect:** Aldığı hasarın bir kısmını oyuncuya yansıtır.
- **evasion:** Belirli bir şansla saldırılardan kaçar.
- **stun_chance:** Saldırdığında oyuncuyu sersemletme (bir sonraki soruyu atlama) şansı vardır.
