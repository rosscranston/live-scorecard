from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

from generate_demo_tax_documents import (
    PAGE_H,
    PAGE_W,
    add_filing_warning,
    finish_page,
    make_canvas,
    money,
    page_chrome,
    section,
    table,
    text_block,
)


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "Demo User Identities" / "03_Business_Return_Upload_Files" / "03_Mission_Seed_Partners_Form_1065"
ENTITY = "Mission Seed Partners, LP"
ENTITY_EIN = "00-0002031"
ENTITY_ADDRESS = "500 Demo Embarcadero, San Francisco, CA 94111"


@dataclass(frozen=True)
class Expense:
    date: str
    payee: str
    ein: str
    invoice: str
    category: str
    amount: float
    paid: str
    payment_ref: str
    services: str
    purpose: str
    document_type: str = "Invoice"


EXPENSES = [
    Expense("01/05/2025", "Mission Seed Management LLC", "00-0002080", "MSM-2025-Q1", "Management fees", 15000, "01/10/2025", "DEMO-ACH-1001", "Q1 fund administration, portfolio monitoring, quarterly investor reporting, and capital-call administration.", "Operate and administer the partnership and monitor existing portfolio investments."),
    Expense("02/18/2025", "Demo Fund Counsel LLP", "00-0002081", "DFC-25018", "Legal and accounting", 8000, "02/25/2025", "DEMO-ACH-1014", "Review partnership agreement amendments, investor side letters, and 2025 governance consents.", "Maintain the partnership's legal governance and compliance records."),
    Expense("03/12/2025", "Signal Deal Diligence LLC", "00-0002083", "SDD-2517", "Diligence and other", 12000, "03/20/2025", "DEMO-WIRE-1028", "Commercial, customer-reference, and revenue-quality diligence for Project Redwood.", "Investigate a potential portfolio investment. Project Redwood did not close; no success fee was paid."),
    Expense("04/05/2025", "Mission Seed Management LLC", "00-0002080", "MSM-2025-Q2", "Management fees", 15000, "04/10/2025", "DEMO-ACH-1041", "Q2 fund administration, portfolio monitoring, quarterly investor reporting, and cash planning.", "Operate and administer the partnership and monitor existing portfolio investments."),
    Expense("05/09/2025", "MarketScope Research, Inc.", "00-0002084", "MSR-250509", "Diligence and other", 8500, "05/16/2025", "DEMO-ACH-1056", "Market sizing, competitor landscape, and customer segmentation report for Project Harbor.", "Evaluate the commercial attractiveness of a potential investment. Project Harbor did not close."),
    Expense("06/03/2025", "Demo Fund Counsel LLP", "00-0002081", "DFC-25041", "Legal and accounting", 7000, "06/10/2025", "DEMO-ACH-1068", "Legal review of Demo Robotics exit documents and partnership distribution provisions.", "Protect the partnership's rights and complete the disposition of an existing portfolio investment."),
    Expense("06/28/2025", "Secure Data Room Co.", "00-0002086", "SDR-2025-884", "Diligence and other", 3000, "07/03/2025", "DEMO-CARD-1077", "Annual secure virtual data-room subscription used for portfolio company and diligence files.", "Securely exchange confidential partnership and investment-review materials."),
    Expense("07/05/2025", "Mission Seed Management LLC", "00-0002080", "MSM-2025-Q3", "Management fees", 15000, "07/10/2025", "DEMO-ACH-1082", "Q3 fund administration, portfolio monitoring, valuation support, and quarterly investor reporting.", "Operate and administer the partnership and monitor existing portfolio investments."),
    Expense("08/14/2025", "Technical Review Partners LLC", "00-0002085", "TRP-25209", "Diligence and other", 6500, "08/22/2025", "DEMO-WIRE-1098", "Software architecture, security posture, and technical-debt review for Project Harbor.", "Evaluate technical risks of a potential investment. Project Harbor did not close."),
    Expense("09/17/2025", "California Secretary Demo Office", "00-0002087", "CA-REG-2025", "Diligence and other", 1200, "09/17/2025", "DEMO-EFT-1105", "Annual partnership registration, statement, and certified-copy charges.", "Maintain the partnership's authority to operate and its entity records.", "Government fee receipt"),
    Expense("10/05/2025", "Mission Seed Management LLC", "00-0002080", "MSM-2025-Q4", "Management fees", 15000, "10/10/2025", "DEMO-ACH-1112", "Q4 fund administration, year-end valuation coordination, investor reporting, and capital-account support.", "Operate and administer the partnership and prepare year-end partner information."),
    Expense("11/07/2025", "Demo Fund Counsel LLP", "00-0002081", "DFC-25079", "Legal and accounting", 6000, "11/14/2025", "DEMO-ACH-1126", "Year-end partnership compliance review, annual consents, and records-retention review.", "Maintain legal compliance and complete year-end governance actions."),
    Expense("12/04/2025", "Demo CPA Advisors LLP", "00-0002082", "DCPA-25118", "Legal and accounting", 11000, "12/12/2025", "DEMO-ACH-1139", "2025 bookkeeping cleanup, tax-basis capital reconciliation, and Form 1065 preparation support.", "Prepare accurate books, partner capital schedules, and federal partnership return workpapers."),
    Expense("12/31/2025", "Golden Gate Demo Bank", "00-0002088", "BANK-FEE-2025", "Diligence and other", 800, "12/31/2025", "DEMO-BANK-1150", "Annual wire, account-maintenance, and treasury-service charges.", "Maintain partnership operating and investment accounts.", "Annual fee statement"),
]


def validate() -> None:
    assert len(EXPENSES) == 14
    assert sum(x.amount for x in EXPENSES) == 124000
    assert sum(x.amount for x in EXPENSES if x.category == "Management fees") == 60000
    assert sum(x.amount for x in EXPENSES if x.category == "Legal and accounting") == 32000
    assert sum(x.amount for x in EXPENSES if x.category == "Diligence and other") == 32000


def create_payee_ledger() -> Path:
    path = OUT / "10_2025_Expense_Payee_Ledger.pdf"
    c = make_canvas(path, "Mission Seed Partners 2025 Expense Payee Ledger")
    for page_idx, subset in enumerate((EXPENSES[:7], EXPENSES[7:]), 1):
        page_chrome(c, "2025 Expense Payee Ledger", f"{ENTITY} | Page {page_idx} of 2")
        y = PAGE_H - 82
        y = section(c, y, "Entity and ledger control")
        y = table(c, 36, y, [165, 375], ["Field", "Synthetic value"], [
            ("Entity", ENTITY),
            ("Invalid demo EIN", ENTITY_EIN),
            ("Tax year", "Calendar year ended 12/31/2025"),
            ("Ledger scope", "$124,000 operating-expense population"),
        ], 25, 7.3)
        y -= 12
        y = section(c, y, f"Transaction detail - records {1 if page_idx == 1 else 8} through {7 if page_idx == 1 else 14}")
        rows = [(x.date, x.payee, x.invoice, x.category, money(x.amount), x.paid, x.payment_ref) for x in subset]
        row_height = 43 if page_idx == 1 else 36
        y = table(c, 36, y, [62, 115, 83, 95, 62, 62, 61], ["Date", "Payee", "Invoice", "Category", "Amount", "Paid", "Payment ref."], rows, row_height, 5.7)
        y -= 12
        if page_idx == 2:
            y = section(c, y, "Category reconciliation")
            y = table(c, 36, y, [360, 180], ["Expense category", "Ledger total"], [
                ("Management fees", money(60000)),
                ("Legal and accounting", money(32000)),
                ("Diligence and other", money(32000)),
                ("TOTAL EXPENSE LEDGER", money(124000)),
            ], 22, 7.5)
        add_filing_warning(c, max(y - 10, 58))
        finish_page(c, page_idx)
    c.save()
    return path


def create_business_purpose_schedule() -> Path:
    path = OUT / "11_2025_Expense_Business_Purpose_Schedule.pdf"
    c = make_canvas(path, "Mission Seed Partners 2025 Expense Business Purpose Schedule")
    groups = (EXPENSES[:5], EXPENSES[5:10], EXPENSES[10:])
    for page_idx, subset in enumerate(groups, 1):
        page_chrome(c, "2025 Expense Business-Purpose Schedule", f"{ENTITY} | Page {page_idx} of 3")
        y = PAGE_H - 82
        y = section(c, y, "Transaction-level substantiation")
        rows = [(x.invoice, x.payee, money(x.amount), x.services, x.purpose) for x in subset]
        y = table(c, 36, y, [82, 105, 65, 145, 143], ["Invoice", "Payee", "Amount", "Services / deliverable", "Partnership business purpose"], rows, 68, 5.8)
        y -= 14
        if page_idx == 1:
            y = text_block(c, 36, y, PAGE_W - 72, "Project Redwood and Project Harbor were investigatory reviews of potential portfolio investments. In this synthetic fact pattern neither transaction closed and none of the vendors received a success-based fee.", 8.5, 12)
        elif page_idx == 3:
            y = section(c, y, "Preparer classification controls")
            y = table(c, 36, y, [190, 350], ["Control", "Synthetic fact"], [
                ("Personal or partner benefit", "None identified; all invoices are billed to and paid by the partnership."),
                ("Related-party payees", "Mission Seed Management LLC is the affiliated manager; quarterly fees follow the partnership agreement."),
                ("Capitalization review", "Preparer should review investigatory and transaction-cost rules; no acquisition closed in this scenario."),
                ("Information-return review", "Vendor TINs are invalid demo values; contractor reporting status is included only for software testing."),
            ], 32, 7.0)
        add_filing_warning(c, max(y - 12, 58))
        finish_page(c, page_idx)
    c.save()
    return path


def draw_invoice(c, expense: Expense, page_no: int) -> None:
    page_chrome(c, expense.document_type, f"{expense.payee} | {expense.invoice}")
    y = PAGE_H - 92
    y = section(c, y, "Vendor and billing information")
    y = table(c, 36, y, [180, 360], ["Field", "Synthetic value"], [
        ("Vendor / issuer", expense.payee),
        ("Invalid demo EIN", expense.ein),
        ("Invoice / receipt number", expense.invoice),
        ("Invoice date", expense.date),
        ("Bill to", f"{ENTITY} | {ENTITY_ADDRESS} | invalid EIN {ENTITY_EIN}"),
    ], 23, 7.1)
    y -= 14
    y = section(c, y, "Charges")
    y = table(c, 36, y, [390, 150], ["Description", "Amount"], [
        (expense.services, money(expense.amount)),
        ("Subtotal", money(expense.amount)),
        ("Sales tax", money(0)),
        ("TOTAL DUE", money(expense.amount)),
    ], 30, 7.0)
    y -= 14
    y = section(c, y, "Payment and business-purpose record")
    y = table(c, 36, y, [180, 360], ["Field", "Synthetic value"], [
        ("Payment status", "PAID"),
        ("Paid date", expense.paid),
        ("Synthetic payment reference", expense.payment_ref),
        ("Expense category", expense.category),
        ("Business purpose", expense.purpose),
    ], 25, 6.9)
    y -= 16
    y = text_block(c, 36, y, PAGE_W - 72, "This invoice or receipt is a synthetic test artifact. Vendor, TIN, address, payment reference, and services are fictional and cannot be used for any real payment, filing, credit, or identity purpose.", 8.5, 12)
    add_filing_warning(c, y - 20)
    finish_page(c, page_no)


def create_invoice_packet() -> Path:
    path = OUT / "12_2025_Paid_Invoice_and_Receipt_Packet.pdf"
    c = make_canvas(path, "Mission Seed Partners 2025 Paid Invoice and Receipt Packet")
    page_chrome(c, "2025 Paid Invoice and Receipt Packet", f"{ENTITY} | 14 source records")
    y = PAGE_H - 92
    y = section(c, y, "Packet control summary")
    y = table(c, 36, y, [300, 120, 120], ["Document group", "Count", "Amount"], [
        ("Management fee invoices", "4", money(60000)),
        ("Legal and accounting invoices", "4", money(32000)),
        ("Diligence, filing, data-room, and bank records", "6", money(32000)),
        ("TOTAL", "14", money(124000)),
    ], 31, 7.4)
    y -= 18
    y = section(c, y, "Source-document index")
    rows = [(str(i), x.date, x.payee, x.invoice, money(x.amount)) for i, x in enumerate(EXPENSES, 1)]
    y = table(c, 36, y, [35, 70, 185, 145, 105], ["Page", "Date", "Payee", "Invoice / receipt", "Amount"], rows, 27, 6.7)
    add_filing_warning(c, max(y - 10, 58))
    finish_page(c, 1)
    for i, expense in enumerate(EXPENSES, 2):
        draw_invoice(c, expense, i)
    c.save()
    return path


def generate_all() -> list[Path]:
    validate()
    OUT.mkdir(parents=True, exist_ok=True)
    paths = [create_payee_ledger(), create_business_purpose_schedule(), create_invoice_packet()]
    assert len(paths) == 3
    return paths


if __name__ == "__main__":
    for file in generate_all():
        print(file.relative_to(ROOT))
