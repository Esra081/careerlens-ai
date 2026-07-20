import time
import uuid
import random
import undetected_chromedriver as uc
from selenium.webdriver.common.by import By
from selenium.webdriver.common.keys import Keys
from bs4 import BeautifulSoup

def human_like_scroll(driver):
    """Sayfayı klavyedeki Page Down tuşunu kullanarak, okuyormuş gibi kaydırır."""
    try:
        # Sayfanın ana gövdesine odaklan
        body = driver.find_element(By.TAG_NAME, 'body')
        
        # Sayfanın uzunluğuna göre 6 ile 10 kez aşağı tuşuna bas
        scroll_times = random.randint(6, 10)
        
        for _ in range(scroll_times):
            body.send_keys(Keys.PAGE_DOWN)
            # Bir insan bir ekranı ne kadar sürede tararsa o kadar bekle (0.8 ile 2.5 saniye arası)
            time.sleep(random.uniform(0.8, 2.5))
            
    except Exception as e:
        print(f"[*] Kaydırma sırasında ufak bir hata: {e}")

def fetch_real_jobs():
    print("[*] Gizli tarayıcı başlatılıyor...")
    options = uc.ChromeOptions()
    
    # Ekran boyutunu rastgele seç
    width = random.choice([1920, 1600, 1440, 1366])
    height = random.choice([1080, 900, 768])
    options.add_argument(f"--window-size={width},{height}")
    
    # Chrome sürüm hatasını çözmek için version_main=150 eklendi
    driver = uc.Chrome(options=options, version_main=150)
    
    keywords = [
        "yazılım", "software", "developer", "geliştirici", "mühendis", "engineer",
        "data", "veri", "analist", "analyst", "fullstack", "frontend", "backend",
        "devops", "cloud", "sistem", "system", "cyber", "siber", "yapay zeka", "ai"
    ]
    
    all_jobs = []
    page = 1
    max_pages = 5
    
    # Temel URL yapısı
    base_url = "https://www.kariyer.net/is-ilanlari?cs=001000000,010100000"
    
    try:
        while page <= max_pages:
            print(f"[*] {page}. sayfa taranıyor...")
            
            # HANGİ SAYFAYA GİDECEĞİMİZİ URL İLE BELİRLİYORUZ
            if page == 1:
                target_url = base_url
            else:
                target_url = f"{base_url}&cp={page}"
            
            driver.get(target_url)
            print(f"[*] Gidilen adres: {target_url}")
            
            # Eğer Captcha çıkarsa diye her yeni sayfa yüklemesinde manuel çözüm payı
            print("[*] Sayfa yükleniyor, güvenlik doğrulaması (Captcha) çıkarsa lütfen basılı tutup çözün (10sn bekleniyor)...")
            time.sleep(10)
            
            # --- İNSANSI KAYDIRMA VE OKUMA ---
            print("[*] Sayfa insan gibi aşağı kaydırılıyor...")
            human_like_scroll(driver)
            time.sleep(random.uniform(1.5, 3.0))
            
            # --- KARTLARI ÇEKME ---
            soup = BeautifulSoup(driver.page_source, 'html.parser')
            cards = soup.find_all(class_="job-list-card-item")
            
            print(f"[*] Ekranda {len(cards)} adet ham kart tespit edildi.")
            
            for card in cards:
                title_el = card.find("span", {"data-test": "ad-card-title"})
                company_el = card.find("span", {"data-test": "subtitle"})
                
                if title_el and company_el:
                    title = title_el.text.strip()
                    if any(k.lower() in title.lower() for k in keywords):
                        job_data = {
                            "id": str(uuid.uuid4()),
                            "title": title,
                            "company": company_el.text.strip(),
                            "required_skills": ["Bilişim"]
                        }
                        # Mükerrer kayıtları engelle (Farklı şirketlerin aynı isimdeki ilanlarını engellememesi için geliştirildi)
                        if not any(j['title'] == job_data['title'] and j['company'] == job_data['company'] for j in all_jobs):
                            all_jobs.append(job_data)
            
            print(f"[*] Şu ana kadar toplam {len(all_jobs)} nitelikli ilan toplandı.")
            
            # Sonraki sayfaya geç
            page += 1
            
            # Sayfalar arası çok hızlı atlamamak için bekle
            if page <= max_pages:
                print("[*] Diğer sayfaya geçiş için bekleniyor...")
                time.sleep(random.uniform(3.0, 5.0))
                
    except Exception as e:
        print(f"[!] Scraper Ana Hata: {e}")
    finally:
        driver.quit()
        print("[*] Tarayıcı kapatıldı.")
        
    return all_jobs