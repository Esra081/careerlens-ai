import io
import pdfplumber
from app.core.config import settings

# PDF dosya başlığı magic byte'ları (%PDF-)
PDF_MAGIC_BYTES = b"%PDF-"


def validate_pdf_bytes(file_bytes: bytes) -> None:
    """PDF baytlarını güvenlik ve boyut açısından doğrular."""
    if not file_bytes:
        raise ValueError("Yüklenen dosya boş.")

    if len(file_bytes) > settings.MAX_FILE_SIZE_BYTES:
        max_mb = settings.MAX_FILE_SIZE_BYTES / (1024 * 1024)
        raise ValueError(f"Dosya boyutu sınırı aşıldı. Maksimum izin verilen boyut: {max_mb:.0f} MB")

    # Magic byte doğrulaması: İlk 1024 byte içinde '%PDF-' araması
    if not file_bytes.startswith(PDF_MAGIC_BYTES) and PDF_MAGIC_BYTES not in file_bytes[:1024]:
        raise ValueError("Geçersiz dosya formatı: Dosya içeriği geçerli bir PDF formatında değil.")


def extract_text_from_pdf(file_bytes: bytes) -> str:
    """Doğrulanmış PDF dosyasından metin ayıklar."""
    validate_pdf_bytes(file_bytes)
    
    text = ""
    with pdfplumber.open(io.BytesIO(file_bytes)) as pdf:
        for page in pdf.pages:
            extracted_page = page.extract_text()
            if extracted_page:
                text += extracted_page + "\n"
                
    if not text.strip():
        raise ValueError("PDF dosyasından metin okunamadı. Taranmış resim (OCR) yerine metin tabanlı bir PDF yükleyin.")
        
    return text