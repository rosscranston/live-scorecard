from __future__ import annotations

from pathlib import Path
from typing import Iterable, Sequence

from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_LEFT
from reportlab.lib.pagesizes import letter
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import inch
from reportlab.pdfbase.pdfmetrics import stringWidth
from reportlab.pdfgen import canvas
from reportlab.platypus import Paragraph


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "Demo User Identities"
IND = OUT / "01_Avery_Morgan_Individual_1040"
BUS = OUT / "02_Business_Return_Source_Packets"
PAGE_W, PAGE_H = letter

NAVY = colors.HexColor("#17324D")
BLUE = colors.HexColor("#DDEAF4")
LIGHT = colors.HexColor("#F4F6F8")
MID = colors.HexColor("#8A99A8")
RED = colors.HexColor("#B42318")
GREEN = colors.HexColor("#087A55")
INK = colors.HexColor("#18212B")

PERSON = {
    "name": "Avery Morgan",
    "ssn": "000-00-2025",
    "address": "245 Demo Street, Apt 12, San Francisco, CA 94107",
    "dob": "05/14/1993",
    "occupation": "Startup product consultant and founder",
}


def money(v: float) -> str:
    sign = "-" if v < 0 else ""
    return f"{sign}${abs(v):,.2f}"


def make_canvas(path: Path, title: str) -> canvas.Canvas:
    path.parent.mkdir(parents=True, exist_ok=True)
    c = canvas.Canvas(str(path), pagesize=letter, pageCompression=1)
    c.setTitle(title)
    c.setAuthor("Synthetic Demo Data Generator")
    c.setSubject("Fictional 2025 tax source document for software testing")
    c.setKeywords("synthetic, demo, not for filing, tax software test")
    return c


def watermark(c: canvas.Canvas) -> None:
    c.saveState()
    c.setFillColor(colors.Color(0.75, 0.05, 0.05, alpha=0.10))
    c.setFont("Helvetica-Bold", 45)
    c.translate(PAGE_W / 2, PAGE_H / 2)
    c.rotate(35)
    c.drawCentredString(0, 0, "SYNTHETIC DEMO - NOT FOR FILING")
    c.restoreState()


def page_chrome(c: canvas.Canvas, title: str, subtitle: str = "Tax year 2025") -> None:
    c.setFillColor(RED)
    c.rect(0, PAGE_H - 24, PAGE_W, 24, fill=1, stroke=0)
    c.setFillColor(colors.white)
    c.setFont("Helvetica-Bold", 9)
    c.drawCentredString(PAGE_W / 2, PAGE_H - 16, "SYNTHETIC DEMO DATA - INVALID TINS - NOT FOR FILING OR IDENTITY USE")
    c.setFillColor(INK)
    title_size = 17.0
    subtitle_width = stringWidth(subtitle, "Helvetica", 9)
    max_title_width = PAGE_W - 72 - subtitle_width - 20
    while title_size > 10 and stringWidth(title, "Helvetica-Bold", title_size) > max_title_width:
        title_size -= 0.5
    c.setFont("Helvetica-Bold", title_size)
    c.drawString(36, PAGE_H - 54, title)
    c.setFont("Helvetica", 9)
    c.setFillColor(MID)
    c.drawRightString(PAGE_W - 36, PAGE_H - 50, subtitle)
    c.setStrokeColor(NAVY)
    c.setLineWidth(1.6)
    c.line(36, PAGE_H - 64, PAGE_W - 36, PAGE_H - 64)
    watermark(c)


def footer(c: canvas.Canvas, page_no: int = 1) -> None:
    c.setStrokeColor(colors.HexColor("#D3D8DE"))
    c.line(36, 30, PAGE_W - 36, 30)
    c.setFillColor(MID)
    c.setFont("Helvetica", 7.5)
    c.drawString(36, 18, "Fictional names, addresses, account numbers, and deliberately invalid TINs.")
    c.drawRightString(PAGE_W - 36, 18, f"Demo packet | Page {page_no}")


def finish_page(c: canvas.Canvas, page_no: int = 1) -> None:
    footer(c, page_no)
    c.showPage()


def draw_box(c: canvas.Canvas, x: float, y: float, w: float, h: float, label: str, value: str = "", fill=colors.white, value_size: float = 10) -> None:
    c.setStrokeColor(colors.HexColor("#687785"))
    c.setFillColor(fill)
    c.rect(x, y, w, h, fill=1, stroke=1)
    c.setFillColor(colors.HexColor("#495864"))
    c.setFont("Helvetica", 6.6)
    label_lines = split_text(label, "Helvetica", 6.6, w - 8)
    ly = y + h - 9
    for line in label_lines[:2]:
        c.drawString(x + 4, ly, line)
        ly -= 7
    if value:
        c.setFillColor(INK)
        c.setFont("Helvetica-Bold", value_size)
        value_lines = split_text(value, "Helvetica-Bold", value_size, w - 8)
        vy = y + 7 + (len(value_lines[:3]) - 1) * 10
        for line in value_lines[:3]:
            c.drawString(x + 4, vy, line)
            vy -= 10


def split_text(text: str, font: str, size: float, max_width: float) -> list[str]:
    words = str(text).split()
    if not words:
        return [""]
    lines, current = [], words[0]
    for word in words[1:]:
        trial = f"{current} {word}"
        if stringWidth(trial, font, size) <= max_width:
            current = trial
        else:
            lines.append(current)
            current = word
    lines.append(current)
    return lines


def text_block(c: canvas.Canvas, x: float, y: float, w: float, text: str, size: float = 9, leading: float = 12, bold: bool = False, color=INK) -> float:
    style = ParagraphStyle(
        "demo",
        fontName="Helvetica-Bold" if bold else "Helvetica",
        fontSize=size,
        leading=leading,
        textColor=color,
        alignment=TA_LEFT,
        spaceAfter=0,
    )
    p = Paragraph(text, style)
    _, h = p.wrap(w, PAGE_H)
    p.drawOn(c, x, y - h)
    return y - h


def section(c: canvas.Canvas, y: float, title: str) -> float:
    c.setFillColor(NAVY)
    c.rect(36, y - 18, PAGE_W - 72, 18, fill=1, stroke=0)
    c.setFillColor(colors.white)
    c.setFont("Helvetica-Bold", 9)
    c.drawString(42, y - 13, title.upper())
    return y - 24


def table(c: canvas.Canvas, x: float, y: float, widths: Sequence[float], headers: Sequence[str], rows: Iterable[Sequence[str]], row_h: float = 20, font_size: float = 8) -> float:
    total = sum(widths)
    c.setFillColor(BLUE)
    c.setStrokeColor(colors.HexColor("#AAB5BF"))
    c.rect(x, y - row_h, total, row_h, fill=1, stroke=1)
    cx = x
    for i, (w, head) in enumerate(zip(widths, headers)):
        if i:
            c.line(cx, y - row_h, cx, y)
        c.setFillColor(NAVY)
        c.setFont("Helvetica-Bold", 7.5)
        c.drawString(cx + 4, y - 13, str(head))
        cx += w
    cy = y - row_h
    for ridx, row in enumerate(rows):
        cy -= row_h
        c.setFillColor(colors.white if ridx % 2 == 0 else LIGHT)
        c.rect(x, cy, total, row_h, fill=1, stroke=1)
        cx = x
        for i, (w, val) in enumerate(zip(widths, row)):
            if i:
                c.line(cx, cy, cx, cy + row_h)
            c.setFillColor(INK)
            c.setFont("Helvetica", font_size)
            lines = split_text(str(val), "Helvetica", font_size, w - 8)
            ty = cy + row_h - 11
            for line in lines[:2]:
                c.drawString(cx + 4, ty, line)
                ty -= font_size + 1
            cx += w
    return cy


def add_filing_warning(c: canvas.Canvas, y: float) -> None:
    c.setFillColor(colors.HexColor("#FDE7E7"))
    c.setStrokeColor(RED)
    c.roundRect(36, y - 32, PAGE_W - 72, 28, 4, fill=1, stroke=1)
    c.setFillColor(RED)
    c.setFont("Helvetica-Bold", 8)
    c.drawString(44, y - 16, "TEST ARTIFACT ONLY")
    c.setFont("Helvetica", 7.5)
    c.drawString(134, y - 16, "All entities and identifiers are fictional; do not submit to any agency or financial institution.")


def form_header(c: canvas.Canvas, form_no: str, form_name: str, issuer: str, recipient: str = PERSON["name"]) -> float:
    page_chrome(c, f"Form {form_no} - {form_name}", "Recipient copy | 2025")
    y = PAGE_H - 80
    draw_box(c, 36, y - 68, 264, 62, "PAYER / ISSUER name, address, and telephone", issuer, LIGHT, 9)
    draw_box(c, 300, y - 68, 126, 62, "PAYER'S TIN (invalid demo)", "00-0002025", LIGHT, 10)
    draw_box(c, 426, y - 68, 150, 62, "RECIPIENT'S TIN (invalid demo)", PERSON["ssn"], LIGHT, 10)
    draw_box(c, 36, y - 126, 390, 58, "RECIPIENT'S name and address", f"{recipient} | {PERSON['address']}", colors.white, 9)
    draw_box(c, 426, y - 126, 150, 58, "Account number", "DEMO-2025-0001", colors.white, 9)
    return y - 138


def create_profile() -> Path:
    path = IND / "00_Client_Organizer_and_Profile.pdf"
    c = make_canvas(path, "Avery Morgan 2025 Client Organizer")
    page_chrome(c, "2025 Client Organizer and Demo Identity Profile", "Form 1040 source packet")
    y = PAGE_H - 82
    y = section(c, y, "Taxpayer profile")
    rows = [
        ("Taxpayer", PERSON["name"]), ("Invalid demo SSN", PERSON["ssn"]),
        ("Date of birth", PERSON["dob"]), ("Filing status", "Single"),
        ("Primary residence", PERSON["address"]), ("Occupation", PERSON["occupation"]),
        ("Dependents", "None"), ("Residency", "Full-year California resident"),
    ]
    y = table(c, 36, y, [140, 400], ["Field", "Synthetic value"], rows, 24)
    y -= 14
    y = section(c, y, "Scenario design and reconciliation")
    facts = [
        ("C corporation", "50% shareholder of Northstar Labs, Inc.; $1,000,000 revenue; $800,000 pre-tax profit; $400,000 total dividend; Avery receives $200,000 Form 1099-DIV."),
        ("S corporation", "100% shareholder of Morgan Product Studio, Inc.; $100,000 salary; $60,000 Schedule K-1 ordinary income; $60,000 cash distribution."),
        ("Partnerships", "10% interest in Mission Seed Partners, LP and 10% interest in Bay Bridge Real Estate Ventures, LLC; two Schedule K-1s."),
        ("Residence and property", "Rents primary residence in San Francisco; owns a mortgaged Sacramento condo operated as a rental property."),
        ("Digital assets", "Received a $5,000 ETH gift; exchanged $4,000 of ETH into XRP, ADA, NEAR, and DOT; retained $1,000 of ETH."),
    ]
    y = table(c, 36, y, [110, 430], ["Topic", "Treatment in packet"], facts, 38, 7.2)
    add_filing_warning(c, y - 10)
    finish_page(c)

    page_chrome(c, "2025 Source Document Checklist", "Avery Morgan | Demo")
    y = PAGE_H - 82
    y = section(c, y, "Included forms and statements")
    docs = [
        ("Income", "W-2; three Forms 1099-NEC; bank Form 1099-INT"),
        ("Ownership", "Schedule K-1 (1120-S); two Schedule K-1s (1065); C-corp Form 1099-DIV"),
        ("Investments", "Consolidated brokerage 1099; Form 1099-DA; crypto detail and gift letter"),
        ("Property", "Form 1098; rental property annual statement; SF rent ledger"),
        ("Adjustments / credits", "Form 1098-E; Forms 5498-SA and 1099-SA; Form 1095-C"),
        ("Itemized / payments", "Charitable receipts; federal and California estimated tax confirmations"),
        ("Business return tests", "Separate synthetic source packets for Forms 1120, 1120-S, and 1065"),
    ]
    y = table(c, 36, y, [150, 390], ["Category", "Included documents"], docs, 34, 8)
    y -= 18
    y = section(c, y, "High-level income amounts - not a prepared return")
    amounts = [
        ("W-2 box 1 wages", money(76500)), ("C-corp qualified dividend", money(200000)),
        ("S-corp ordinary income", money(60000)), ("1099-NEC gross receipts", money(87900)),
        ("Bank and brokerage interest", money(2254.33)), ("Brokerage ordinary dividends", money(7260)),
        ("Brokerage capital gain", money(2250)), ("Mission Seed K-1 ordinary loss", money(-12400)),
        ("Bay Bridge K-1 rental income", money(9800)), ("Crypto gain from documented exchanges", money(0)),
    ]
    table(c, 36, y, [350, 190], ["Source", "Amount"], amounts, 24)
    finish_page(c, 2)
    c.save()
    return path


def create_w2() -> Path:
    path = IND / "01_W2_Morgan_Product_Studio.pdf"
    c = make_canvas(path, "2025 Form W-2 - Avery Morgan")
    page_chrome(c, "Form W-2 - Wage and Tax Statement", "Copy B | 2025")
    y = PAGE_H - 82
    draw_box(c, 36, y - 56, 270, 50, "a Employee's invalid demo SSN", PERSON["ssn"], LIGHT, 12)
    draw_box(c, 306, y - 56, 270, 50, "b Employer identification number (invalid demo)", "00-0002026", LIGHT, 12)
    draw_box(c, 36, y - 116, 540, 60, "c Employer name and address", "Morgan Product Studio, Inc. | 100 Demo Market Street, San Francisco, CA 94105", colors.white, 10)
    draw_box(c, 36, y - 176, 540, 60, "e Employee name and address", f"{PERSON['name']} | {PERSON['address']}", colors.white, 10)
    grid_y = y - 196
    vals = [
        ("1 Wages, tips, other compensation", "76,500.00"), ("2 Federal income tax withheld", "18,500.00"),
        ("3 Social security wages", "100,000.00"), ("4 Social security tax withheld", "6,200.00"),
        ("5 Medicare wages and tips", "100,000.00"), ("6 Medicare tax withheld", "1,450.00"),
        ("12a Code D - elective deferral", "23,500.00"), ("14 CASDI", "1,100.00"),
        ("15 State / employer state ID", "CA / DEMO-CA-2025"), ("16 State wages", "100,000.00"),
        ("17 State income tax", "6,500.00"), ("18 Local wages", "0.00"),
    ]
    for i, (label, value) in enumerate(vals):
        col = i % 2
        row = i // 2
        draw_box(c, 36 + col * 270, grid_y - (row + 1) * 53, 270, 53, label, value, colors.white, 11)
    add_filing_warning(c, 102)
    finish_page(c)
    c.save()
    return path


def create_k1_1120s() -> Path:
    path = IND / "02_K1_1120S_Morgan_Product_Studio.pdf"
    c = make_canvas(path, "2025 Schedule K-1 Form 1120-S")
    page_chrome(c, "Schedule K-1 (Form 1120-S)", "Shareholder's share | 2025")
    y = PAGE_H - 82
    y = section(c, y, "Part I - Information about the corporation")
    y = table(c, 36, y, [150, 390], ["Field", "Value"], [
        ("A Corporation EIN", "00-0002026 (invalid demo)"),
        ("B Corporation", "Morgan Product Studio, Inc., 100 Demo Market Street, San Francisco, CA 94105"),
        ("C Filing center", "Demo Service Center"),
        ("D Shares", "100 beginning / 100 ending"),
    ], 24)
    y -= 12
    y = section(c, y, "Part II - Information about the shareholder")
    y = table(c, 36, y, [150, 390], ["Field", "Value"], [
        ("E Shareholder TIN", PERSON["ssn"] + " (invalid demo)"),
        ("F Shareholder", PERSON["name"] + ", " + PERSON["address"]),
        ("Entity type", "Individual"),
        ("Allocation", "100.000000% beginning / 100.000000% ending"),
        ("Loans from shareholder", "$0.00 beginning / $0.00 ending"),
    ], 24)
    y -= 12
    y = section(c, y, "Part III - Shareholder's share")
    y = table(c, 36, y, [80, 300, 160], ["Box", "Item", "Amount / code"], [
        ("1", "Ordinary business income", money(60000)),
        ("16D", "Property distributions", money(60000)),
        ("17V", "Section 199A information", "See attached demo statement"),
    ], 29)
    add_filing_warning(c, y - 12)
    finish_page(c)
    c.save()
    return path


def create_k1_1065(filename: str, partnership: str, ein: str, lines: list[tuple[str, str, str]], capital: list[tuple[str, str]], ownership: str) -> Path:
    path = IND / filename
    c = make_canvas(path, f"2025 Schedule K-1 Form 1065 - {partnership}")
    page_chrome(c, "Schedule K-1 (Form 1065)", "Partner's share | 2025")
    y = PAGE_H - 82
    y = section(c, y, "Part I - Partnership")
    y = table(c, 36, y, [150, 390], ["Field", "Value"], [
        ("A Partnership EIN", f"{ein} (invalid demo)"),
        ("B Partnership", partnership + ", 500 Demo Embarcadero, San Francisco, CA 94111"),
        ("C Filing center", "Demo Service Center"),
        ("D Publicly traded", "No"),
    ], 24)
    y -= 12
    y = section(c, y, "Part II - Partner")
    y = table(c, 36, y, [150, 390], ["Field", "Value"], [
        ("E Partner TIN", PERSON["ssn"] + " (invalid demo)"),
        ("F Partner", PERSON["name"] + ", " + PERSON["address"]),
        ("Partner type", "Individual, limited partner"),
        ("Profit / loss / capital", ownership),
        ("Liabilities", "$0.00 recourse / $0.00 nonrecourse / $0.00 qualified nonrecourse"),
    ], 24)
    y -= 12
    y = section(c, y, "Part III - Partner's share")
    y = table(c, 36, y, [80, 300, 160], ["Box", "Item", "Amount / code"], lines, 22)
    y -= 12
    y = section(c, y, "Partner capital account analysis")
    y = table(c, 36, y, [350, 190], ["Capital item", "Amount"], capital, 19)
    add_filing_warning(c, y - 8)
    finish_page(c)
    c.save()
    return path


def create_simple_1099(filename: str, number: str, name: str, issuer: str, boxes: list[tuple[str, str]]) -> Path:
    path = IND / filename
    c = make_canvas(path, f"2025 Form {number} - {name}")
    y = form_header(c, number, name, issuer)
    box_h = 52
    for i, (label, value) in enumerate(boxes):
        col, row = i % 2, i // 2
        draw_box(c, 36 + col * 270, y - (row + 1) * box_h, 270, box_h, label, value, colors.white, 11)
    low_y = y - ((len(boxes) + 1) // 2) * box_h
    add_filing_warning(c, low_y - 12)
    finish_page(c)
    c.save()
    return path


def create_brokerage() -> Path:
    path = IND / "10_Consolidated_1099_Pacific_Crest_Brokerage.pdf"
    c = make_canvas(path, "2025 Consolidated Brokerage Form 1099")
    page_chrome(c, "2025 Consolidated Tax Reporting Statement", "Pacific Crest Brokerage | Account DEMO-PCB-8842")
    y = PAGE_H - 82
    y = section(c, y, "Recipient and account")
    y = table(c, 36, y, [150, 390], ["Field", "Value"], [
        ("Recipient", PERSON["name"] + ", " + PERSON["address"]),
        ("Invalid demo TIN", PERSON["ssn"]),
        ("Payer", "Pacific Crest Brokerage, 1 Demo Plaza, San Francisco, CA 94104 | EIN 00-0002035"),
        ("Account", "DEMO-PCB-8842"),
    ], 28)
    y -= 12
    y = section(c, y, "Form 1099-DIV summary")
    y = table(c, 36, y, [90, 300, 150], ["Box", "Description", "Amount"], [
        ("1a", "Total ordinary dividends", money(7260)),
        ("1b", "Qualified dividends", money(6880)),
        ("3", "Nondividend distributions", money(0)),
        ("7", "Foreign tax paid", money(84)),
    ], 25)
    y -= 12
    y = section(c, y, "Form 1099-INT summary")
    y = table(c, 36, y, [90, 300, 150], ["Box", "Description", "Amount"], [("1", "Interest income", money(412))], 25)
    finish_page(c)

    page_chrome(c, "Form 1099-B Transaction Detail", "Pacific Crest Brokerage | 2025")
    y = PAGE_H - 82
    y = table(c, 36, y, [130, 75, 75, 95, 95, 70], ["Security", "Acquired", "Sold", "Proceeds", "Basis", "Gain"], [
        ("Vanguard Total Stock ETF", "03/10/2022", "06/12/2025", money(5850), money(4600), money(1250)),
        ("Alphabet Class A", "08/18/2023", "09/05/2025", money(4100), money(3600), money(500)),
        ("NVIDIA", "01/22/2024", "11/17/2025", money(2900), money(2400), money(500)),
        ("TOTALS", "", "", money(12850), money(10600), money(2250)),
    ], 30, 6.8)
    y -= 16
    y = text_block(c, 36, y, PAGE_W - 72, "Basis is reported to the IRS for all three covered transactions. No wash-sale adjustments are included. This is synthetic brokerage data for software ingestion testing.", 9, 13)
    add_filing_warning(c, y - 18)
    finish_page(c, 2)
    c.save()
    return path


def create_crypto_detail() -> Path:
    path = IND / "12_Crypto_Transaction_Detail_and_Gift_Letter.pdf"
    c = make_canvas(path, "2025 Crypto Transaction Detail and Gift Letter")
    page_chrome(c, "Digital Asset Transaction Detail", "BlockHarbor Demo Exchange | 2025")
    y = PAGE_H - 82
    y = table(c, 36, y, [72, 98, 98, 88, 88, 96], ["Date", "Disposed", "Received", "Proceeds", "Basis", "Gain/loss"], [
        ("04/10/25", "0.25 ETH", "2,000 XRP", money(1000), money(1000), money(0)),
        ("06/02/25", "0.25 ETH", "1,800 ADA", money(1000), money(1000), money(0)),
        ("08/14/25", "0.25 ETH", "200 NEAR", money(1000), money(1000), money(0)),
        ("10/21/25", "0.25 ETH", "150 DOT", money(1000), money(1000), money(0)),
        ("TOTAL", "1.00 ETH", "Four tokens", money(4000), money(4000), money(0)),
    ], 32, 6.8)
    y -= 18
    y = section(c, y, "Year-end holdings at 12/31/2025")
    y = table(c, 36, y, [170, 185, 185], ["Asset", "Quantity (demo)", "Fair market value"], [
        ("Ethereum (ETH)", "0.25", money(1000)), ("XRP", "2,000", money(1000)),
        ("Cardano (ADA)", "1,800", money(1000)), ("NEAR", "200", money(1000)),
        ("Polkadot (DOT)", "150", money(1000)), ("TOTAL", "", money(5000)),
    ], 26)
    add_filing_warning(c, y - 12)
    finish_page(c)

    page_chrome(c, "Synthetic Digital Asset Gift Letter", "Gift received 02/03/2025")
    y = PAGE_H - 92
    y = text_block(c, 54, y, PAGE_W - 108, "To whom it may concern:", 10, 14, True)
    y -= 16
    body = (
        "I, Jordan Morgan (a fictional demo person), state that on February 3, 2025, I made a completed gift of "
        "1.25 ETH to Avery Morgan. The fair market value on the gift date was $5,000.00. My adjusted basis in the "
        "gifted property immediately before the gift was $5,000.00, and no gift tax was paid. No services or other "
        "consideration were received in exchange. The wallet references below are synthetic and cannot be used on a blockchain."
    )
    y = text_block(c, 54, y, PAGE_W - 108, body, 10, 15)
    y -= 26
    y = table(c, 54, y, [190, 296], ["Gift fact", "Synthetic value"], [
        ("Donor", "Jordan Morgan | INVALID-TIN 000-00-2024"),
        ("Recipient", PERSON["name"] + " | INVALID-TIN " + PERSON["ssn"]),
        ("Asset and quantity", "1.25 ETH"),
        ("Donor adjusted basis", money(5000)),
        ("Fair market value at gift", money(5000)),
        ("Demo transaction reference", "DEMO-ETH-GIFT-2025-NOT-A-HASH"),
    ], 30)
    y -= 42
    c.setStrokeColor(INK)
    c.line(54, y, 285, y)
    c.line(330, y, 558, y)
    c.setFont("Helvetica", 8)
    c.drawString(54, y - 12, "Jordan Morgan - synthetic donor")
    c.drawString(330, y - 12, "Date: 02/03/2025")
    add_filing_warning(c, y - 42)
    finish_page(c, 2)
    c.save()
    return path


def create_rental_statement() -> Path:
    path = IND / "14_Rental_Property_Annual_Statement.pdf"
    c = make_canvas(path, "2025 Rental Property Annual Statement")
    page_chrome(c, "Rental Property Annual Owner Statement", "Capital City Property Management | 2025")
    y = PAGE_H - 82
    y = table(c, 36, y, [170, 370], ["Property / owner field", "Synthetic value"], [
        ("Owner", PERSON["name"] + " | " + PERSON["address"]),
        ("Rental property", "820 Demo Oak Avenue, Unit 4, Sacramento, CA 95814"),
        ("Tenant occupancy", "12 months; unrelated third-party tenant"),
        ("Management account", "DEMO-RENTAL-2025-44"),
    ], 29)
    y -= 12
    y = section(c, y, "Income and expense summary")
    rows = [
        ("Gross rents collected", money(30000)), ("Property management fees", money(-2400)),
        ("Repairs and maintenance", money(-2300)), ("Insurance", money(-1800)),
        ("HOA dues", money(-4200)), ("Property tax", money(-7800)),
        ("Mortgage interest (see Form 1098)", money(-21480)), ("Net before depreciation", money(-9980)),
    ]
    y = table(c, 36, y, [380, 160], ["Category", "Amount"], rows, 28)
    y -= 14
    y = text_block(c, 36, y, 540, "Depreciation is intentionally omitted from this source statement so the tax platform can calculate it from the separate asset facts: building basis $510,000; land allocation $90,000; placed in service 01/01/2025; residential rental property.", 8.5, 12)
    add_filing_warning(c, y - 18)
    finish_page(c)
    c.save()
    return path


def create_charity() -> Path:
    path = IND / "15_Charitable_Contribution_Receipts.pdf"
    c = make_canvas(path, "2025 Charitable Contribution Receipts")
    page_chrome(c, "Charitable Contribution Acknowledgments", "2025 consolidated demo receipts")
    y = PAGE_H - 82
    receipts = [
        ("Grace Harbor Church", "00-0002041", "Cash contributions paid throughout 2025", money(12000), "No goods or services were provided."),
        ("Bay Area Food Network", "00-0002042", "Cash contribution dated 11/24/2025", money(1500), "No goods or services were provided."),
        ("Code Access Foundation", "00-0002043", "Used laptop and monitor donated 12/12/2025; donor-stated value", money(650), "No goods or services were provided."),
    ]
    for idx, (org, ein, desc, amount, statement) in enumerate(receipts, 1):
        c.setFillColor(LIGHT)
        c.setStrokeColor(colors.HexColor("#AAB5BF"))
        c.roundRect(36, y - 150, 540, 138, 5, fill=1, stroke=1)
        c.setFillColor(NAVY)
        c.setFont("Helvetica-Bold", 12)
        c.drawString(48, y - 33, f"Receipt {idx}: {org}")
        c.setFont("Helvetica", 8)
        c.setFillColor(INK)
        c.drawString(48, y - 50, f"Invalid demo EIN: {ein} | 1 Demo Charity Way, San Francisco, CA 94103")
        c.drawString(48, y - 72, f"Donor: {PERSON['name']} | {PERSON['address']}")
        c.drawString(48, y - 92, desc)
        c.setFont("Helvetica-Bold", 13)
        c.drawRightString(558, y - 92, amount)
        c.setFont("Helvetica-Oblique", 8)
        c.drawString(48, y - 118, statement)
        y -= 158
    add_filing_warning(c, y)
    finish_page(c)
    c.save()
    return path


def create_hsa() -> Path:
    path = IND / "17_HSA_5498SA_and_1099SA.pdf"
    c = make_canvas(path, "2025 Forms 5498-SA and 1099-SA")
    y = form_header(c, "5498-SA", "HSA, Archer MSA, or Medicare Advantage MSA Information", "Sequoia Health Bank | 1 Demo Health Plaza, San Mateo, CA 94401")
    fields = [
        ("1 Employee or self-employed contributions", "4,300.00"), ("2 Total contributions in 2025", "4,300.00"),
        ("5 Fair market value of HSA at 12/31/2025", "18,420.00"), ("6 HSA checkbox", "CHECKED"),
    ]
    for i, (label, value) in enumerate(fields):
        draw_box(c, 36 + (i % 2) * 270, y - (i // 2 + 1) * 58, 270, 58, label, value, colors.white, 11)
    add_filing_warning(c, y - 138)
    finish_page(c)

    y = form_header(c, "1099-SA", "Distributions From an HSA, Archer MSA, or Medicare Advantage MSA", "Sequoia Health Bank | 1 Demo Health Plaza, San Mateo, CA 94401")
    fields = [
        ("1 Gross distribution", "1,280.00"), ("2 Earnings on excess contributions", "0.00"),
        ("3 Distribution code", "1 - Normal distribution"), ("5 HSA checkbox", "CHECKED"),
    ]
    for i, (label, value) in enumerate(fields):
        draw_box(c, 36 + (i % 2) * 270, y - (i // 2 + 1) * 58, 270, 58, label, value, colors.white, 11)
    add_filing_warning(c, y - 138)
    finish_page(c, 2)
    c.save()
    return path


def create_1095c() -> Path:
    path = IND / "18_1095C_Health_Coverage.pdf"
    c = make_canvas(path, "2025 Form 1095-C")
    page_chrome(c, "Form 1095-C - Employer-Provided Health Insurance Offer and Coverage", "2025")
    y = PAGE_H - 82
    y = section(c, y, "Part I - Employee and employer")
    y = table(c, 36, y, [170, 370], ["Field", "Value"], [
        ("Employee", PERSON["name"] + " | " + PERSON["ssn"] + " (invalid demo)"),
        ("Employee address", PERSON["address"]),
        ("Employer", "Morgan Product Studio, Inc. | EIN 00-0002026 (invalid demo)"),
        ("Employer contact", "100 Demo Market Street, San Francisco, CA 94105 | 555-0100"),
    ], 29)
    y -= 12
    y = section(c, y, "Part II - Offer and coverage")
    y = table(c, 36, y, [210] + [27.5] * 12, ["Line"] + [m for m in "JFMAMJJASOND"], [
        ["14 Offer of coverage"] + ["1E"] * 12,
        ["15 Employee required contribution"] + ["0"] * 12,
        ["16 Safe harbor / other relief"] + ["2C"] * 12,
    ], 31, 6.5)
    y -= 16
    y = text_block(c, 36, y, 540, "Avery was enrolled in minimum essential coverage for all twelve months. Codes are included as synthetic test data and are not a representation of an actual insurance plan.", 9, 13)
    add_filing_warning(c, y - 18)
    finish_page(c)
    c.save()
    return path


def create_estimated_payments() -> Path:
    path = IND / "19_2025_Estimated_Tax_Payments.pdf"
    c = make_canvas(path, "2025 Estimated Tax Payment Confirmations")
    page_chrome(c, "Estimated Tax Payment Confirmations", "Federal and California | 2025")
    y = PAGE_H - 82
    y = section(c, y, "Federal Form 1040-ES electronic payments")
    federal = [("04/15/2025", "DEMO-EFTPS-Q1", money(35000)), ("06/16/2025", "DEMO-EFTPS-Q2", money(35000)), ("09/15/2025", "DEMO-EFTPS-Q3", money(35000)), ("01/15/2026", "DEMO-EFTPS-Q4", money(35000)), ("TOTAL", "", money(140000))]
    y = table(c, 36, y, [160, 220, 160], ["Payment date", "Synthetic confirmation", "Amount"], federal, 29)
    y -= 16
    y = section(c, y, "California Form 540-ES electronic payments")
    ca = [("04/15/2025", "DEMO-FTB-Q1", money(9000)), ("06/16/2025", "DEMO-FTB-Q2", money(9000)), ("09/15/2025", "DEMO-FTB-Q3", money(9000)), ("01/15/2026", "DEMO-FTB-Q4", money(9000)), ("TOTAL", "", money(36000))]
    y = table(c, 36, y, [160, 220, 160], ["Payment date", "Synthetic confirmation", "Amount"], ca, 29)
    add_filing_warning(c, y - 14)
    finish_page(c)
    c.save()
    return path


def create_rent_ledger() -> Path:
    path = IND / "20_San_Francisco_Rent_Ledger.pdf"
    c = make_canvas(path, "2025 San Francisco Rent Ledger")
    page_chrome(c, "Residential Rent Ledger", "Demo Street Apartments | 2025")
    y = PAGE_H - 82
    y = table(c, 36, y, [170, 370], ["Tenant field", "Synthetic value"], [
        ("Tenant", PERSON["name"]), ("Premises", PERSON["address"]),
        ("Lease term", "01/01/2025 through 12/31/2025"), ("Monthly rent", money(4000)),
        ("Landlord", "Demo Street Apartments LLC | invalid EIN 00-0002050"),
    ], 28)
    y -= 14
    rows = [(f"2025-{m:02d}-01", f"DEMO-RENT-{m:02d}", money(4000)) for m in range(1, 13)] + [("TOTAL", "", money(48000))]
    y = table(c, 36, y, [160, 220, 160], ["Date paid", "Synthetic receipt", "Amount"], rows, 24)
    add_filing_warning(c, y - 10)
    finish_page(c)
    c.save()
    return path


def packet_cover(c: canvas.Canvas, title: str, form_type: str, entity: str, ein: str, description: str, page_no: int) -> None:
    page_chrome(c, title, f"{form_type} test identity | 2025")
    y = PAGE_H - 100
    c.setFillColor(NAVY)
    c.setFont("Helvetica-Bold", 25)
    c.drawString(48, y, entity)
    c.setFont("Helvetica", 12)
    c.setFillColor(MID)
    c.drawString(48, y - 24, f"Invalid demo EIN: {ein}")
    y -= 62
    y = text_block(c, 48, y, PAGE_W - 96, description, 11, 17)
    y -= 28
    y = section(c, y, "Packet contents")
    table(c, 48, y, [180, 336], ["Source record", "Purpose"], [
        ("Year-end trial balance / P&L", "Income and deductions for entity return testing"),
        ("Balance sheet", "Beginning/end balance and Schedule L testing"),
        ("Payroll / contractor detail", "Officer compensation, wages, payroll tax, and 1099 reconciliation"),
        ("Owner / partner activity", "Capital, distributions, ownership, and K-1 or dividend reconciliation"),
        ("Fixed asset schedule", "Depreciation inputs and book/tax convention testing"),
    ], 38, 7.5)
    add_filing_warning(c, 120)
    finish_page(c, page_no)


def create_business_packet_1120() -> Path:
    path = BUS / "21_Northstar_Labs_1120_Source_Packet.pdf"
    c = make_canvas(path, "Northstar Labs 2025 Form 1120 Source Packet")
    packet_cover(c, "Business Return Source Packet", "Form 1120", "Northstar Labs, Inc.", "00-0002030", "A fictional Delaware C corporation with two equal shareholders. It earns $1,000,000 of revenue, $800,000 of pre-tax book income, records $168,000 of current federal tax expense, and pays $400,000 of cash dividends split evenly between the two owners.", 1)

    page_chrome(c, "Income Statement and Trial Balance", "Northstar Labs, Inc. | 2025")
    y = PAGE_H - 82
    rows = [
        ("SaaS subscription revenue", money(850000)), ("Implementation revenue", money(150000)),
        ("TOTAL REVENUE", money(1000000)), ("Officer and employee compensation", money(-80000)),
        ("Independent contractors", money(-40000)), ("Cloud hosting", money(-30000)),
        ("Legal and professional", money(-18000)), ("Office rent", money(-12000)),
        ("Advertising", money(-15000)), ("Insurance and other", money(-5000)),
        ("TOTAL OPERATING EXPENSE", money(-200000)), ("PRE-TAX BOOK INCOME", money(800000)),
        ("Federal income tax provision", money(-168000)), ("NET INCOME AFTER TAX", money(632000)),
    ]
    y = table(c, 36, y, [380, 160], ["Account", "2025 amount"], rows, 26)
    y -= 14
    y = text_block(c, 36, y, 540, "Bank interest of $4,800 is included in subscription revenue for the raw book data and is separately flagged for tax mapping. No state tax provision is included in this simplified demo trial balance.", 8.5, 12)
    finish_page(c, 2)

    page_chrome(c, "Balance Sheet and Shareholder Activity", "Northstar Labs, Inc. | 12/31/2025")
    y = PAGE_H - 82
    y = section(c, y, "Ending balance sheet")
    y = table(c, 36, y, [270, 135, 135], ["Account", "Beginning", "Ending"], [
        ("Cash", money(250000), money(570000)), ("Accounts receivable", money(120000), money(200000)),
        ("Equipment, net", money(40000), money(50000)), ("Total assets", money(410000), money(820000)),
        ("Accounts payable", money(25000), money(35000)), ("Federal tax payable", money(0), money(168000)),
        ("Common stock", money(2000), money(2000)), ("Retained earnings", money(383000), money(615000)),
        ("Total liabilities and equity", money(410000), money(820000)),
    ], 28)
    y -= 14
    y = section(c, y, "Dividend reconciliation")
    y = table(c, 36, y, [220, 160, 160], ["Shareholder", "Ownership", "2025 dividend"], [
        (PERSON["name"], "50%", money(200000)), ("Riley Chen (synthetic)", "50%", money(200000)),
        ("TOTAL", "100%", money(400000)),
    ], 30)
    add_filing_warning(c, y - 12)
    finish_page(c, 3)

    page_chrome(c, "Payroll, Contractors, and Fixed Assets", "Northstar Labs, Inc. | 2025")
    y = PAGE_H - 82
    y = section(c, y, "Payroll register summary")
    y = table(c, 36, y, [230, 150, 160], ["Employee", "Role", "Gross wages"], [
        ("Riley Chen (synthetic)", "Chief executive officer", money(50000)),
        ("Taylor Brooks (synthetic)", "Engineer", money(30000)),
        ("TOTAL", "", money(80000)),
    ], 30)
    y -= 12
    y = section(c, y, "Contractor ledger")
    y = table(c, 36, y, [250, 130, 160], ["Vendor", "1099 status", "Amount"], [
        ("Demo DevOps LLC", "1099-NEC issued", money(25000)),
        ("Demo Design Collective", "1099-NEC issued", money(15000)),
        ("TOTAL", "", money(40000)),
    ], 30)
    y -= 12
    y = section(c, y, "Fixed asset schedule")
    y = table(c, 36, y, [190, 95, 90, 80, 85], ["Asset", "In service", "Cost", "Method", "2025 dep."], [
        ("Server equipment", "03/15/25", money(60000), "5-year MACRS", money(12000)),
        ("Office furniture", "07/01/25", money(10000), "7-year MACRS", money(1429)),
    ], 31, 7)
    add_filing_warning(c, y - 12)
    finish_page(c, 4)
    c.save()
    return path


def create_business_packet_1120s() -> Path:
    path = BUS / "22_Morgan_Product_Studio_1120S_Source_Packet.pdf"
    c = make_canvas(path, "Morgan Product Studio 2025 Form 1120-S Source Packet")
    packet_cover(c, "Business Return Source Packet", "Form 1120-S", "Morgan Product Studio, Inc.", "00-0002026", "A fictional California S corporation wholly owned by Avery Morgan. It pays a $100,000 shareholder-employee salary, reports $60,000 of ordinary business income, and makes a $60,000 shareholder distribution.", 1)

    page_chrome(c, "Income Statement and Trial Balance", "Morgan Product Studio, Inc. | 2025")
    y = PAGE_H - 82
    rows = [
        ("Consulting and design revenue", money(310000)), ("Officer compensation", money(-100000)),
        ("Payroll taxes", money(-8000)), ("Independent contractors", money(-45000)),
        ("Software subscriptions", money(-18000)), ("Advertising", money(-20000)),
        ("Coworking rent", money(-12000)), ("Travel and meals", money(-10000)),
        ("Insurance", money(-6000)), ("Legal and accounting", money(-7000)),
        ("Other operating expense", money(-24000)), ("ORDINARY BUSINESS INCOME", money(60000)),
    ]
    y = table(c, 36, y, [380, 160], ["Account", "2025 amount"], rows, 27)
    add_filing_warning(c, y - 12)
    finish_page(c, 2)

    page_chrome(c, "Balance Sheet, Payroll, and Shareholder Activity", "Morgan Product Studio, Inc. | 2025")
    y = PAGE_H - 82
    y = section(c, y, "Balance sheet")
    y = table(c, 36, y, [270, 135, 135], ["Account", "Beginning", "Ending"], [
        ("Cash", money(60000), money(95000)), ("Accounts receivable", money(20000), money(30000)),
        ("Equipment, net", money(18000), money(15000)), ("Total assets", money(98000), money(140000)),
        ("Accounts payable", money(7000), money(10000)), ("Payroll liabilities", money(3000), money(5000)),
        ("Common stock", money(1000), money(1000)), ("Additional paid-in capital", money(0), money(37000)),
        ("AAA / retained earnings", money(87000), money(87000)),
        ("Total liabilities and equity", money(98000), money(140000)),
    ], 27)
    y -= 12
    y = section(c, y, "Shareholder and payroll reconciliation")
    y = table(c, 36, y, [260, 140, 140], ["Item", "Book / payroll", "Tax reporting"], [
        ("Avery Morgan gross salary", money(100000), "W-2 boxes 3 and 5"),
        ("401(k) elective deferral", money(23500), "W-2 box 12 code D"),
        ("W-2 box 1 taxable wages", money(76500), money(76500)),
        ("Ordinary business income", money(60000), "K-1 box 1"),
        ("Cash distribution", money(60000), "K-1 box 16 code D"),
    ], 32, 7.2)
    add_filing_warning(c, y - 10)
    finish_page(c, 3)

    page_chrome(c, "Contractor and Fixed Asset Detail", "Morgan Product Studio, Inc. | 2025")
    y = PAGE_H - 82
    y = section(c, y, "Contractor ledger")
    y = table(c, 36, y, [250, 130, 160], ["Vendor", "1099 status", "Amount"], [
        ("Demo UX Research LLC", "1099-NEC issued", money(25000)),
        ("Demo Engineering Co.", "1099-NEC issued", money(20000)),
        ("TOTAL", "", money(45000)),
    ], 30)
    y -= 14
    y = section(c, y, "Fixed assets and accountable plan")
    y = table(c, 36, y, [200, 90, 90, 80, 80], ["Item", "Date", "Cost", "Treatment", "Amount"], [
        ("Laptop and display", "02/01/25", money(6000), "5-year MACRS", money(1200)),
        ("Camera equipment", "05/10/25", money(4000), "5-year MACRS", money(800)),
        ("Home internet reimbursement", "Monthly", "", "Accountable plan", money(1200)),
        ("Business mileage reimbursement", "2025", "1,800 mi", "Accountable plan", money(1260)),
    ], 32, 6.8)
    add_filing_warning(c, y - 12)
    finish_page(c, 4)
    c.save()
    return path


def create_business_packet_1065() -> Path:
    path = BUS / "23_Mission_Seed_Partners_1065_Source_Packet.pdf"
    c = make_canvas(path, "Mission Seed Partners 2025 Form 1065 Source Packet")
    packet_cover(c, "Business Return Source Packet", "Form 1065", "Mission Seed Partners, LP", "00-0002031", "A fictional early-stage investment partnership with ten equal limited partners. The packet is designed to exercise partnership balance sheet, capital account, portfolio activity, and K-1 allocation intake.", 1)

    page_chrome(c, "Income Statement and Portfolio Activity", "Mission Seed Partners, LP | 2025")
    y = PAGE_H - 82
    y = section(c, y, "Tax-basis income statement")
    y = table(c, 36, y, [380, 160], ["Account", "2025 amount"], [
        ("Interest income", money(3200)), ("Net long-term capital gain", money(48000)),
        ("Management fees", money(-60000)), ("Legal and accounting", money(-32000)),
        ("Due diligence and other deductible expense", money(-32000)),
        ("ORDINARY BUSINESS LOSS", money(-124000)),
    ], 30)
    y -= 14
    y = section(c, y, "Realized portfolio transactions")
    y = table(c, 36, y, [190, 90, 90, 90, 80], ["Investment", "Proceeds", "Basis", "LT gain", "Holding"], [
        ("Demo Robotics, Inc.", money(180000), money(140000), money(40000), "> 1 year"),
        ("Demo Climate Labs", money(58000), money(50000), money(8000), "> 1 year"),
        ("TOTAL", money(238000), money(190000), money(48000), ""),
    ], 31, 7)
    add_filing_warning(c, y - 10)
    finish_page(c, 2)

    page_chrome(c, "Balance Sheet and Capital Accounts", "Mission Seed Partners, LP | 2025")
    y = PAGE_H - 82
    y = section(c, y, "Balance sheet")
    y = table(c, 36, y, [270, 135, 135], ["Account", "Beginning", "Ending"], [
        ("Cash", money(420000), money(305200)), ("Portfolio investments, tax basis", money(1080000), money(1250000)),
        ("Other assets", money(0), money(12000)), ("Total assets", money(1500000), money(1567200)),
        ("Accounts payable", money(0), money(0)), ("Partners' capital", money(1500000), money(1567200)),
    ], 30)
    y -= 14
    y = section(c, y, "Avery Morgan capital reconciliation")
    y = table(c, 36, y, [350, 190], ["Capital item", "Amount"], [
        ("Beginning tax-basis capital", money(150000)), ("Cash contribution", money(20000)),
        ("Ordinary business loss", money(-12400)), ("Interest income", money(320)),
        ("Long-term capital gain", money(4800)), ("Distributions", money(0)),
        ("Ending tax-basis capital", money(162720)),
    ], 28)
    add_filing_warning(c, y - 10)
    finish_page(c, 3)

    page_chrome(c, "Partner Roster and Allocation Summary", "Mission Seed Partners, LP | 2025")
    y = PAGE_H - 82
    partners = [(PERSON["name"], "10%", money(-12400), money(320), money(4800))]
    for i in range(2, 11):
        partners.append((f"Synthetic Partner {i}", "10%", money(-12400), money(320), money(4800)))
    y = table(c, 36, y, [180, 70, 100, 90, 100], ["Partner", "Ownership", "Ordinary", "Interest", "LT gain"], partners, 30, 7)
    y -= 14
    y = text_block(c, 36, y, 540, "All partners are fictional and the equal allocation is intentionally simplified. Total allocations reconcile to ordinary loss of $124,000, interest income of $3,200, and long-term capital gain of $48,000.", 8.5, 12)
    add_filing_warning(c, y - 16)
    finish_page(c, 4)
    c.save()
    return path


def generate_all() -> list[Path]:
    paths: list[Path] = []
    paths.append(create_profile())
    paths.append(create_w2())
    paths.append(create_k1_1120s())
    paths.append(create_k1_1065(
        "03_K1_1065_Mission_Seed_Partners.pdf", "Mission Seed Partners, LP", "00-0002031",
        [("1", "Ordinary business income (loss)", money(-12400)), ("5", "Interest income", money(320)), ("9a", "Net long-term capital gain", money(4800)), ("20Z", "Section 199A information", "See demo statement")],
        [("Beginning capital", money(150000)), ("Capital contributed", money(20000)), ("Current year net increase (decrease)", money(-7280)), ("Withdrawals and distributions", money(0)), ("Ending capital", money(162720))],
        "10.000000% beginning / 10.000000% ending",
    ))
    paths.append(create_k1_1065(
        "04_K1_1065_Bay_Bridge_Real_Estate.pdf", "Bay Bridge Real Estate Ventures, LLC", "00-0002032",
        [("2", "Net rental real estate income", money(9800)), ("5", "Interest income", money(150)), ("19A", "Cash and marketable securities distributions", money(6000)), ("20Z", "Section 199A rental information", "See demo statement")],
        [("Beginning capital", money(75000)), ("Capital contributed", money(0)), ("Current year net increase", money(9950)), ("Withdrawals and distributions", money(-6000)), ("Ending capital", money(78950))],
        "10.000000% beginning / 10.000000% ending",
    ))
    paths.append(create_simple_1099(
        "05_1099DIV_Northstar_Labs.pdf", "1099-DIV", "Dividends and Distributions",
        "Northstar Labs, Inc. | 300 Demo Startup Way, San Francisco, CA 94107",
        [("1a Total ordinary dividends", "200,000.00"), ("1b Qualified dividends", "200,000.00"), ("2a Total capital gain distributions", "0.00"), ("3 Nondividend distributions", "0.00"), ("4 Federal income tax withheld", "0.00"), ("14 State tax withheld", "0.00")],
    ))
    nec_data = [
        ("06_1099NEC_Arc_Analytics.pdf", "Arc Analytics, Inc. | 10 Demo Mission Street, San Francisco, CA 94105", 42000),
        ("07_1099NEC_Nimbus_Health.pdf", "Nimbus Health Systems, Inc. | 22 Demo Howard Street, San Francisco, CA 94103", 27500),
        ("08_1099NEC_Helix_Mobility.pdf", "Helix Mobility, Inc. | 80 Demo Brannan Street, San Francisco, CA 94107", 18400),
    ]
    for filename, issuer, amount in nec_data:
        paths.append(create_simple_1099(filename, "1099-NEC", "Nonemployee Compensation", issuer, [("1 Nonemployee compensation", f"{amount:,.2f}"), ("4 Federal income tax withheld", "0.00"), ("5 State tax withheld", "0.00"), ("6 State / payer's state no.", "CA / DEMO-2025")]))
    paths.append(create_simple_1099(
        "09_1099INT_Golden_Gate_Bank.pdf", "1099-INT", "Interest Income",
        "Golden Gate Bank | 1 Demo Financial Center, San Francisco, CA 94104",
        [("1 Interest income", "1,842.33"), ("3 Interest on U.S. Savings Bonds and Treasury obligations", "0.00"), ("4 Federal income tax withheld", "0.00"), ("8 Tax-exempt interest", "0.00")],
    ))
    paths.append(create_brokerage())
    paths.append(create_simple_1099(
        "11_1099DA_BlockHarbor_Crypto.pdf", "1099-DA", "Digital Asset Proceeds From Broker Transactions",
        "BlockHarbor Demo Exchange | 9 Demo Blockchain Lane, San Francisco, CA 94105",
        [("1a Digital asset name", "Ethereum (ETH)"), ("1b Number of units", "1.00 ETH"), ("1c Date acquired", "02/03/2025"), ("1d Date sold or disposed", "Various"), ("1f Proceeds", "4,000.00"), ("1g Cost or other basis", "NOT REPORTED TO IRS"), ("6 Gross proceeds indicator", "CHECKED"), ("7 Federal income tax withheld", "0.00")],
    ))
    paths.append(create_crypto_detail())
    paths.append(create_simple_1099(
        "13_1098_Mortgage_Sacramento_Condo.pdf", "1098", "Mortgage Interest Statement",
        "Sierra Demo Mortgage Company | 700 Demo Capitol Mall, Sacramento, CA 95814",
        [("1 Mortgage interest received", "21,480.00"), ("2 Outstanding mortgage principal", "510,000.00"), ("3 Mortgage origination date", "06/15/2021"), ("5 Mortgage insurance premiums", "0.00"), ("6 Points paid", "0.00"), ("Property address", "820 Demo Oak Avenue, Unit 4, Sacramento, CA 95814")],
    ))
    paths.append(create_rental_statement())
    paths.append(create_charity())
    paths.append(create_simple_1099(
        "16_1098E_Student_Loan_Interest.pdf", "1098-E", "Student Loan Interest Statement",
        "Demo Education Loan Servicing | 44 Demo Campus Drive, Oakland, CA 94612",
        [("1 Student loan interest received", "2,410.00"), ("Account number", "DEMO-STUDENT-2025-17"), ("Borrower", PERSON["name"]), ("Tax year", "2025")],
    ))
    paths.append(create_hsa())
    paths.append(create_1095c())
    paths.append(create_estimated_payments())
    paths.append(create_rent_ledger())
    paths.append(create_business_packet_1120())
    paths.append(create_business_packet_1120s())
    paths.append(create_business_packet_1065())
    if len(paths) != 24:
        raise RuntimeError(f"Expected 24 PDFs, generated {len(paths)}")
    return paths


if __name__ == "__main__":
    generated = generate_all()
    for p in generated:
        print(p.relative_to(ROOT))
