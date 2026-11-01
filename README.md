# Aile Bütçesi

Telefon, tablet ve bilgisayardan ortak düzenlenen ev bütçesi. Streamlit arayüzü ve Supabase kalıcı veritabanı kullanır.

## Özellikler

- Gelir, gider, kredi ve kart planı; geçmişi değiştirmeyen aylık maaş artışları.
- Kişi ve başlangıç ayına bağlı bileşik maaş artışı; 12–120 ay projeksiyon.
- İki oturumun aynı kaydı değiştirmesinde sürüm kontrolü; farklı kayıtlarda birleştirme.
- Son 100 değişiklik öncesi otomatik yedek, geri yükleme ve JSON içe/dışa aktarma.
- Ortak parola, başarısız girişlere bekleme ve süreli oturum.
- Supabase sunucu anahtarı yalnızca Python sunucusunda kullanılır. Bütçe kayıtları GitHub'a yazılmaz.

## Kurulum

1. Supabase'te ücretsiz bir proje oluşturun ve `setup.sql` dosyasını SQL Editor'da bir kez çalıştırın. Gerçek bütçe bilgisi içermez. Tablolar RLS ile korunur, anonim ve normal oturum rollerine doğrudan erişim verilmez.
2. Streamlit Community Cloud'da bu depoyu, `main` dalını ve `streamlit_app.py` giriş dosyasını seçin. Python 3.12 kullanın.
3. Advanced settings → Secrets alanına aşağıdaki yapıyı girin:

```toml
SUPABASE_URL = "https://PROJE.supabase.co"
SUPABASE_SERVICE_KEY = "sb_secret_..."
APP_PASSWORD = "KENDINIZIN_BELIRLEDIGI_UZUN_PAROLA"
```

 Gerçek Supabase URL, **secret/service role** anahtarı ve sizin belirlediğiniz en az 16 karakterlik ortak parola gerekir. Bu dosyayı GitHub'a yüklemeyin.
4. Yayından sonra ortak parolayla giriş yapın. Eski bütçe JSON'unuzu “İçe aktar” ile yükleyin. Başlangıçta uygulama bilinçli olarak boş açılır.
5. Eşiniz aynı HTTPS adresini ve ortak parolayı kullanır. Görünür sayfada yaklaşık 5 saniyede ortak kayıtlar yenilenir.

Streamlit özel paylaşımı kullanılabiliyorsa ek koruma olarak açılabilir. Uygulamanın kendi parola kontrolü, özel bağlantı olmadan dahi kayıtları göstermeden çalışmayı durdurur.

## Çalıştırma ve doğrulama

```sh
python -m venv .venv
. .venv/bin/activate
pip install -r requirements.txt
streamlit run streamlit_app.py
```

Yerel bağlantı bilgileri `.streamlit/secrets.toml` içinde saklanır ve Git tarafından yok sayılır. Eksik bağlantıyla uygulama kayıt açmaz. Testler için `pip install pytest` ve `python -m pytest -q` kullanın.

## Kullanım notları

Her yıl için ayrı maaş artışı girilir; sonraki artış önceki artışlarla oluşan net maaşa uygulanır. Gider enflasyonu otomatik varsayılmaz. Kredi planının takvimle azalması ödendi kaydı değildir. Kart hesabı girilen aylık faiz ve sabit ödeme tutarıyla yaklaşık plan üretir; yeni alışveriş, vergi ve ücretler ayrıca işlenmelidir. Birikimli net banka bakiyesi değildir. İnternet kesildiğinde kayıt yapılmış gibi gösterilmez.

Gerçek gelirler, borçlar, JSON yedekleri, parolalar ve anahtarlar bu açık kaynak deposuna eklenmemelidir. Ortak parolayı bilen kişi bütçeyi değiştirebilir; parolayı yalnızca hanenizle paylaşın.
