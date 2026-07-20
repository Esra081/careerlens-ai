import pdfplumber
import io

def extract_text_from_pdf(file_bytes: bytes) -> str:
    text = ""
    # Gelen byte verisini pdfplumber'ın okuyabileceği formata çeviriyoruz
    with pdfplumber.open(io.BytesIO(file_bytes)) as pdf:
        for page in pdf.pages:
            extracted_page = page.extract_text()
            if extracted_page:
                text += extracted_page + "\n"
    return text