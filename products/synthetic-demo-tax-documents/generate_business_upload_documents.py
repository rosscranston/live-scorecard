from __future__ import annotations

from pathlib import Path
from typing import Iterable, Sequence

from reportlab.lib import colors

from generate_demo_tax_documents import (
    IND,
    INK,
    LIGHT,
    NAVY,
    PAGE_H,
    PAGE_W,
    PERSON,
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
OUT = ROOT / "Demo User Identities" / "03_Business_Return_Upload_Files"
C_CORP = OUT / "01_Northstar_Labs_Form_1120"
S_CORP = OUT / "02_Morgan_Product_Studio_Form_1120S"
PARTNERSHIP = OUT / "03_Mission_Seed_Partners_Form_1065"


def create_table_doc(
    path: Path,
    title: str,
    subtitle: str,
    sections: Sequence[tuple[str, Sequence[float], Sequence[str], Iterable[Sequence[str]], float, float]],
    note: str | None = None,
) -> Path:
    c = make_canvas(path, title)
    page_chrome(c, title, subtitle)
    y = PAGE_H - 82
    for section_title, widths, headers, rows, row_h, font_size in sections:
        y = section(c, y, section_title)
        y = table(c, 36, y, widths, headers, rows, row_h, font_size)
        y -= 14
    if note:
        y = text_block(c, 36, y, PAGE_W - 72, note, 8.5, 12)
        y -= 12
    add_filing_warning(c, max(y - 6, 58))
    finish_page(c)
    c.save()
    return path


def create_organizer(
    path: Path,
    entity: str,
    form: str,
    ein: str,
    address: str,
    ownership_rows: Sequence[Sequence[str]],
    uploads: Sequence[Sequence[str]],
    open_items: Sequence[Sequence[str]],
) -> Path:
    c = make_canvas(path, f"{entity} 2025 Preparer Upload Index")
    page_chrome(c, "2025 Preparer Upload Index and Entity Organizer", f"{entity} | {form}")
    y = PAGE_H - 82
    y = section(c, y, "Entity information")
    y = table(c, 36, y, [170, 370], ["Field", "Synthetic value"], [
        ("Legal name", entity),
        ("Invalid demo EIN", ein),
        ("Business address", address),
        ("Return type", form),
        ("Tax year", "Calendar year ending 12/31/2025"),
        ("Accounting method", "Accrual" if form == "Form 1120" else "Cash"),
        ("Books and records", "Maintained in U.S. dollars; synthetic test ledger"),
    ], 24, 7.5)
    y -= 12
    y = section(c, y, "Ownership / partner information")
    y = table(c, 36, y, [210, 100, 230], ["Owner / partner", "Interest", "Tax reporting"], ownership_rows, 26, 7.5)
    y -= 12
    y = section(c, y, "Included upload files")
    y = table(c, 36, y, [210, 330], ["Document", "What the preparer uses it for"], uploads, 25, 7)
    finish_page(c)

    page_chrome(c, "Preparer Questions and Assumptions", f"{entity} | 2025")
    y = PAGE_H - 82
    y = section(c, y, "Confirmed synthetic facts")
    y = table(c, 36, y, [220, 320], ["Question", "Demo answer"], open_items, 31, 7.2)
    y -= 16
    y = text_block(
        c,
        36,
        y,
        PAGE_W - 72,
        "No prior-year filed return is included because this is a synthetic test identity. Beginning balances and carryforward facts are supplied in the balance sheet, trial balance, fixed-asset schedule, and ownership schedules.",
        9,
        13,
    )
    add_filing_warning(c, y - 22)
    finish_page(c, 2)
    c.save()
    return path


def create_financial_statements(
    path: Path,
    entity: str,
    form: str,
    pnl_rows: Sequence[Sequence[str]],
    balance_rows: Sequence[Sequence[str]],
    equity_rows: Sequence[Sequence[str]],
    cash_rows: Sequence[Sequence[str]],
) -> Path:
    c = make_canvas(path, f"{entity} 2025 Financial Statements")
    page_chrome(c, "Unaudited Financial Statements", f"{entity} | Year ended 12/31/2025")
    y = PAGE_H - 82
    y = section(c, y, "Statement of income")
    y = table(c, 36, y, [390, 150], ["Account", "2025"], pnl_rows, 24, 7.2)
    y -= 16
    y = text_block(c, 36, y, 540, "Management-prepared, unaudited synthetic financial statements for tax-return software testing. Amounts are rounded to the nearest dollar in source ledgers and shown to cents here.", 8.5, 12)
    add_filing_warning(c, y - 18)
    finish_page(c, 1)

    page_chrome(c, "Unaudited Financial Statements", f"{entity} | 12/31/2025")
    y = PAGE_H - 82
    y = section(c, y, "Comparative balance sheet")
    y = table(c, 36, y, [270, 135, 135], ["Account", "12/31/2024", "12/31/2025"], balance_rows, 26, 7.2)
    y -= 14
    y = section(c, y, "Statement of equity / capital")
    y = table(c, 36, y, [350, 190], ["Activity", "Amount"], equity_rows, 24, 7.2)
    add_filing_warning(c, y - 12)
    finish_page(c, 2)

    page_chrome(c, "Unaudited Financial Statements", f"{entity} | Cash flow support")
    y = PAGE_H - 82
    y = section(c, y, "Cash flow reconciliation")
    y = table(c, 36, y, [390, 150], ["Cash-flow item", "Amount"], cash_rows, 27, 7.5)
    y -= 16
    y = text_block(c, 36, y, 540, f"This cash reconciliation is supplied as workpaper support. The tax return requested is {form}; the preparer should map financial-statement accounts to tax-return lines and evaluate any book-tax adjustments.", 9, 13)
    add_filing_warning(c, y - 20)
    finish_page(c, 3)
    c.save()
    return path


def create_flowthrough_target(
    path: Path,
    entity: str,
    form_title: str,
    ein: str,
    ownership: str,
    rows: Sequence[Sequence[str]],
    basis_rows: Sequence[Sequence[str]],
    note: str,
) -> Path:
    c = make_canvas(path, f"Expected {form_title} - {PERSON['name']}")
    page_chrome(c, f"Expected {form_title} - Avery Morgan", f"{entity} | 2025")
    y = PAGE_H - 82
    y = section(c, y, "Entity and recipient")
    y = table(c, 36, y, [180, 360], ["Field", "Synthetic value"], [
        ("Entity", entity),
        ("Invalid demo EIN", ein),
        ("Recipient", f"{PERSON['name']} | {PERSON['ssn']} (invalid demo)"),
        ("Recipient address", PERSON["address"]),
        ("Ownership / allocation", ownership),
    ], 27, 7.2)
    y -= 12
    y = section(c, y, "Expected tax items")
    y = table(c, 36, y, [90, 290, 160], ["Box / code", "Item", "Amount"], rows, 26, 7.5)
    y -= 12
    y = section(c, y, "Basis / capital support")
    y = table(c, 36, y, [360, 180], ["Activity", "Amount"], basis_rows, 23, 7.2)
    y -= 12
    y = text_block(c, 36, y, 540, note, 8.5, 12)
    add_filing_warning(c, y - 18)
    finish_page(c)
    c.save()
    return path


def northstar_docs() -> list[Path]:
    entity = "Northstar Labs, Inc."
    form = "Form 1120"
    ein = "00-0002030"
    address = "300 Demo Startup Way, San Francisco, CA 94107"
    pnl = [
        ("SaaS subscription revenue", money(850000)),
        ("Implementation revenue", money(150000)),
        ("Interest income", money(4800)),
        ("TOTAL INCOME", money(1004800)),
        ("Officer and employee compensation", money(-80000)),
        ("Independent contractors", money(-40000)),
        ("Cloud hosting", money(-30000)),
        ("Legal and professional", money(-18000)),
        ("Office rent", money(-12000)),
        ("Advertising", money(-10000)),
        ("Insurance and other", money(-4800)),
        ("Depreciation", money(-10000)),
        ("TOTAL OPERATING EXPENSE", money(-204800)),
        ("PRE-TAX BOOK INCOME", money(800000)),
        ("Federal income tax provision", money(-168000)),
        ("NET INCOME", money(632000)),
    ]
    balance = [
        ("Cash", money(250000), money(444000)),
        ("Accounts receivable", money(120000), money(200000)),
        ("Equipment, gross", money(50000), money(70000)),
        ("Accumulated depreciation", money(-10000), money(-20000)),
        ("TOTAL ASSETS", money(410000), money(694000)),
        ("Accounts payable", money(25000), money(35000)),
        ("Federal income tax payable", money(0), money(42000)),
        ("Common stock", money(2000), money(2000)),
        ("Retained earnings", money(383000), money(615000)),
        ("TOTAL LIABILITIES AND EQUITY", money(410000), money(694000)),
    ]
    equity = [
        ("Beginning retained earnings", money(383000)),
        ("Net income", money(632000)),
        ("Cash dividends", money(-400000)),
        ("Ending retained earnings", money(615000)),
    ]
    cash = [
        ("Beginning cash", money(250000)),
        ("Net income", money(632000)),
        ("Depreciation", money(10000)),
        ("Increase in accounts receivable", money(-80000)),
        ("Increase in accounts payable", money(10000)),
        ("Increase in federal tax payable", money(42000)),
        ("Equipment purchases", money(-20000)),
        ("Dividends paid", money(-400000)),
        ("Ending cash", money(444000)),
    ]
    tb = [
        ("1000", "Cash", money(444000), ""),
        ("1100", "Accounts receivable", money(200000), ""),
        ("1500", "Equipment", money(70000), ""),
        ("1590", "Accumulated depreciation", "", money(20000)),
        ("2000", "Accounts payable", "", money(35000)),
        ("2100", "Federal income tax payable", "", money(42000)),
        ("3000", "Common stock", "", money(2000)),
        ("3100", "Beginning retained earnings", "", money(383000)),
        ("4000", "SaaS subscription revenue", "", money(850000)),
        ("4010", "Implementation revenue", "", money(150000)),
        ("4100", "Interest income", "", money(4800)),
        ("5000-5900", "Operating expenses", money(194800), ""),
        ("5950", "Depreciation expense", money(10000), ""),
        ("6000", "Federal income tax expense", money(168000), ""),
        ("3200", "Dividends declared", money(400000), ""),
        ("TOTAL", "Adjusted trial balance", money(1486800), money(1486800)),
    ]
    paths = []
    uploads = [
        ("Financial statements", "P&L, comparative balance sheet, equity, and cash support"),
        ("Standalone P&L and balance sheet", "Direct platform upload and account mapping"),
        ("Adjusted trial balance", "Return-line mapping and reconciliation"),
        ("General ledger summary", "Material account detail and year-end entries"),
        ("Fixed assets", "Depreciation and Form 4562 inputs"),
        ("Payroll / contractor summary", "Compensation and information-return support"),
        ("Shareholder / dividend schedule", "Ownership and 1099-DIV reconciliation"),
        ("Tax documents and payments", "1099-INT and federal payment support"),
    ]
    paths.append(create_organizer(
        C_CORP / "00_Preparer_Upload_Index_and_Entity_Organizer.pdf", entity, form, ein, address,
        [(PERSON["name"], "50%", "Receives Form 1099-DIV, not Schedule K-1"), ("Riley Chen (synthetic)", "50%", "Receives Form 1099-DIV")],
        uploads,
        [
            ("Entity classification", "Domestic Delaware C corporation; calendar year"),
            ("Ownership changes", "None during 2025; two equal individual shareholders"),
            ("Related-party transactions", "Cash dividends only; no shareholder loans"),
            ("Foreign activity", "None"),
            ("State filings", "California filing expected; state provision intentionally omitted"),
            ("Prior-year carryforwards", "None supplied other than beginning balance-sheet amounts"),
        ],
    ))
    paths.append(create_financial_statements(C_CORP / "01_Unaudited_Financial_Statements.pdf", entity, form, pnl, balance, equity, cash))
    paths.append(create_table_doc(C_CORP / "02_Profit_and_Loss_Statement.pdf", "2025 Profit and Loss Statement", f"{entity} | {form}", [("Income and expense accounts", [390, 150], ["Account", "2025 amount"], pnl, 24, 7.2)], "Pre-tax book income is $800,000. Federal tax expense is shown below pre-tax income and is not included in deductible operating expenses."))
    paths.append(create_table_doc(C_CORP / "03_Comparative_Balance_Sheet.pdf", "Comparative Balance Sheet", f"{entity} | 12/31/2025", [("Assets, liabilities, and equity", [270, 135, 135], ["Account", "12/31/2024", "12/31/2025"], balance, 26, 7.2)], "Ending retained earnings reconciles: $383,000 beginning + $632,000 net income - $400,000 dividends = $615,000 ending."))
    paths.append(create_table_doc(C_CORP / "04_Adjusted_Trial_Balance.pdf", "Adjusted Trial Balance", f"{entity} | 12/31/2025", [("Post-closing tax workpaper trial balance", [65, 255, 110, 110], ["Acct", "Account", "Debit", "Credit"], tb, 25, 7)], "Debits and credits each total $1,486,800. The retained-earnings and dividend accounts are shown separately to support the equity rollforward."))
    gl_rows = [
        ("Cash", "1,248 receipts / 1,012 disbursements", money(444000), "Bank reconciled"),
        ("Accounts receivable", "18 customer balances", money(200000), "Aging supplied in summary"),
        ("Revenue", "Subscription + implementation", money(1000000), "Gross receipts"),
        ("Interest income", "Golden Gate Bank", money(4800), "See synthetic 1099-INT"),
        ("Payroll", "2 employees", money(80000), "W-2/W-3 reconciled"),
        ("Contractors", "2 reportable vendors", money(40000), "1099-NEC reconciled"),
        ("Dividends", "Two 50% shareholders", money(400000), "Two Forms 1099-DIV"),
        ("Federal tax", "Current provision less estimates", money(42000), "Ending payable"),
    ]
    paths.append(create_table_doc(C_CORP / "05_General_Ledger_and_Year_End_Entries.pdf", "General Ledger Summary and Year-End Entries", f"{entity} | 2025", [("Material account ledger summary", [150, 195, 105, 90], ["Account", "Activity", "Ending / total", "Support"], gl_rows, 31, 6.8), ("Year-end journal entries", [120, 270, 150], ["Entry", "Description", "Amount"], [("AJE-01", "Record annual depreciation", money(10000)), ("AJE-02", "Record current federal tax provision", money(168000)), ("AJE-03", "Apply federal estimated payments", money(126000)), ("AJE-04", "Close $400,000 dividends to retained earnings", money(400000))], 28, 7)], "The general ledger is intentionally summarized; material balances reconcile to the adjusted trial balance."))
    asset_rows = [
        ("Server equipment - existing", "01/15/2024", money(50000), "5-year MACRS", money(10000), money(10000), money(30000)),
        ("Additional server equipment", "03/15/2025", money(20000), "5-year MACRS", money(0), money(0), money(20000)),
        ("TOTAL", "", money(70000), "", money(10000), money(10000), money(50000)),
    ]
    paths.append(create_table_doc(C_CORP / "06_Fixed_Asset_and_Depreciation_Schedule.pdf", "Fixed Asset and Depreciation Schedule", f"{entity} | 2025", [("Book and tax source facts", [125, 70, 70, 80, 65, 65, 65], ["Asset", "In service", "Cost", "Method", "Prior dep.", "2025 dep.", "Ending basis"], asset_rows, 34, 6.3)], "The return preparer should calculate allowable tax depreciation. The $10,000 annual amount is the book depreciation recorded in the trial balance."))
    payroll_rows = [
        ("Riley Chen", "Chief executive officer", money(50000), money(3100), money(725), "W-2 issued"),
        ("Taylor Brooks", "Engineer", money(30000), money(1860), money(435), "W-2 issued"),
        ("TOTAL", "", money(80000), money(4960), money(1160), "W-3 reconciled"),
    ]
    contractor_rows = [("Demo DevOps LLC", "00-0002060", money(25000), "1099-NEC issued"), ("Demo Design Collective", "00-0002061", money(15000), "1099-NEC issued"), ("TOTAL", "", money(40000), "")]
    paths.append(create_table_doc(C_CORP / "07_Payroll_and_Contractor_Summary.pdf", "Payroll and Contractor Summary", f"{entity} | 2025", [("Payroll register", [130, 130, 75, 60, 60, 85], ["Employee", "Role", "Gross", "SS tax", "Medicare", "Status"], payroll_rows, 31, 6.3), ("Reportable contractors", [190, 110, 110, 130], ["Vendor", "Invalid EIN", "Paid", "Status"], contractor_rows, 29, 7)], "Payroll-tax liabilities are included in operating expenses and were paid timely. Vendor identifiers are deliberately invalid demo values."))
    shareholder_rows = [(PERSON["name"], PERSON["ssn"], "50%", money(200000), "1099-DIV box 1a / 1b"), ("Riley Chen", "000-00-2026", "50%", money(200000), "1099-DIV box 1a / 1b"), ("TOTAL", "", "100%", money(400000), "")]
    paths.append(create_table_doc(C_CORP / "08_Shareholder_and_Dividend_Schedule.pdf", "Shareholder Ownership and Dividend Schedule", f"{entity} | 2025", [("Shareholder reporting", [135, 100, 65, 110, 130], ["Shareholder", "Invalid TIN", "Owned", "Dividend", "Reporting"], shareholder_rows, 31, 6.8), ("Avery expected flow-through target", [180, 210, 150], ["Form", "Item", "Amount"], [("1099-DIV", "Ordinary dividends", money(200000)), ("1099-DIV", "Qualified dividends", money(200000)), ("Schedule K-1", "Not applicable to C corporation", money(0))], 28, 7)], "Northstar is a C corporation. It does not issue a Schedule K-1; Avery's shareholder-level source document is Form 1099-DIV."))
    tax_rows = [("Bank interest statement", "Synthetic Form 1099-INT", money(4800), "Interest income"), ("Federal estimate Q1", "DEMO-1120-Q1", money(31500), "Paid 04/15/2025"), ("Federal estimate Q2", "DEMO-1120-Q2", money(31500), "Paid 06/16/2025"), ("Federal estimate Q3", "DEMO-1120-Q3", money(31500), "Paid 09/15/2025"), ("Federal estimate Q4", "DEMO-1120-Q4", money(31500), "Paid 12/15/2025"), ("Total federal estimates", "", money(126000), "Provision $168,000; payable $42,000")]
    paths.append(create_table_doc(C_CORP / "09_Tax_Documents_and_Estimated_Payments.pdf", "Tax Documents and Estimated Payments", f"{entity} | 2025", [("Income statements and payment confirmations", [180, 145, 100, 115], ["Item", "Reference", "Amount", "Treatment"], tax_rows, 30, 6.8)], "California tax payments and return data are intentionally excluded from this federal demo packet."))
    return paths


def morgan_studio_docs() -> list[Path]:
    entity = "Morgan Product Studio, Inc."
    form = "Form 1120-S"
    ein = "00-0002026"
    address = "100 Demo Market Street, San Francisco, CA 94105"
    pnl = [
        ("Consulting and design revenue", money(310000)),
        ("Officer compensation - Avery Morgan", money(-100000)),
        ("Payroll taxes", money(-8000)),
        ("Independent contractors", money(-45000)),
        ("Software subscriptions", money(-18000)),
        ("Advertising", money(-20000)),
        ("Coworking rent", money(-12000)),
        ("Travel and meals", money(-10000)),
        ("Insurance", money(-6000)),
        ("Legal and accounting", money(-7000)),
        ("Other operating expense, including depreciation", money(-24000)),
        ("TOTAL EXPENSE", money(-250000)),
        ("ORDINARY BUSINESS INCOME", money(60000)),
    ]
    balance = [
        ("Cash", money(60000), money(95000)),
        ("Accounts receivable", money(20000), money(30000)),
        ("Equipment, gross", money(25000), money(25000)),
        ("Accumulated depreciation", money(-7000), money(-10000)),
        ("TOTAL ASSETS", money(98000), money(140000)),
        ("Accounts payable", money(7000), money(10000)),
        ("Payroll liabilities", money(3000), money(5000)),
        ("Common stock", money(1000), money(1000)),
        ("Additional paid-in capital", money(0), money(37000)),
        ("AAA / retained earnings", money(87000), money(87000)),
        ("TOTAL LIABILITIES AND EQUITY", money(98000), money(140000)),
    ]
    equity = [("Beginning shareholder equity / basis", money(88000)), ("Capital contribution", money(37000)), ("Ordinary business income", money(60000)), ("Cash distribution", money(-60000)), ("Ending shareholder equity / basis", money(125000))]
    cash = [("Beginning cash", money(60000)), ("Ordinary business income", money(60000)), ("Depreciation", money(3000)), ("Increase in accounts receivable", money(-10000)), ("Increase in accounts payable", money(3000)), ("Increase in payroll liabilities", money(2000)), ("Shareholder contribution", money(37000)), ("Shareholder distribution", money(-60000)), ("Ending cash", money(95000))]
    tb = [
        ("1000", "Cash", money(95000), ""), ("1100", "Accounts receivable", money(30000), ""),
        ("1500", "Equipment", money(25000), ""), ("1590", "Accumulated depreciation", "", money(10000)),
        ("2000", "Accounts payable", "", money(10000)), ("2100", "Payroll liabilities", "", money(5000)),
        ("3000", "Common stock", "", money(1000)), ("3050", "Additional paid-in capital", "", money(37000)),
        ("3100", "Beginning AAA / retained earnings", "", money(87000)), ("4000", "Consulting revenue", "", money(310000)),
        ("5000-5900", "Operating expenses", money(250000), ""), ("3200", "Shareholder distributions", money(60000), ""),
        ("TOTAL", "Adjusted trial balance", money(460000), money(460000)),
    ]
    paths = []
    uploads = [("Financial statements", "P&L, comparative balance sheet, equity, and cash support"), ("Standalone P&L and balance sheet", "Direct platform upload and account mapping"), ("Adjusted trial balance", "Return-line mapping and reconciliation"), ("General ledger summary", "Material account detail and year-end entries"), ("Fixed assets", "Depreciation inputs"), ("Payroll / contractors", "Avery W-2 and vendor reconciliation"), ("Shareholder basis / distributions", "Stock basis, AAA, and contribution support"), ("Expected Avery K-1", "1040 flow-through target and reconciliation")]
    paths.append(create_organizer(S_CORP / "00_Preparer_Upload_Index_and_Entity_Organizer.pdf", entity, form, ein, address, [(PERSON["name"], "100%", "Shareholder-employee; receives Schedule K-1")], uploads, [("S election", "Effective before 2025; no termination event"), ("Ownership changes", "None; Avery owned 100% all year"), ("Reasonable compensation", "$100,000 gross officer salary"), ("Shareholder health insurance", "None in this simplified demo"), ("Related-party activity", "$37,000 capital contribution and $60,000 cash distribution"), ("Foreign activity", "None")]))
    paths.append(create_financial_statements(S_CORP / "01_Unaudited_Financial_Statements.pdf", entity, form, pnl, balance, equity, cash))
    paths.append(create_table_doc(S_CORP / "02_Profit_and_Loss_Statement.pdf", "2025 Profit and Loss Statement", f"{entity} | {form}", [("Income and expense accounts", [390, 150], ["Account", "2025 amount"], pnl, 26, 7.2)], "Ordinary business income of $60,000 reconciles to expected Schedule K-1 box 1."))
    paths.append(create_table_doc(S_CORP / "03_Comparative_Balance_Sheet.pdf", "Comparative Balance Sheet", f"{entity} | 12/31/2025", [("Assets, liabilities, and equity", [270, 135, 135], ["Account", "12/31/2024", "12/31/2025"], balance, 25, 7.2)], "Ending equity of $125,000 equals common stock $1,000, additional paid-in capital $37,000, and AAA / retained earnings $87,000."))
    paths.append(create_table_doc(S_CORP / "04_Adjusted_Trial_Balance.pdf", "Adjusted Trial Balance", f"{entity} | 12/31/2025", [("Post-closing tax workpaper trial balance", [65, 255, 110, 110], ["Acct", "Account", "Debit", "Credit"], tb, 27, 7)], "Debits and credits each total $460,000. Shareholder distributions remain separately identified for Schedule K and basis reporting."))
    gl_rows = [("Cash", "Client receipts, payroll, and operating payments", money(95000), "Bank reconciled"), ("Accounts receivable", "6 customer invoices", money(30000), "Year-end aging"), ("Revenue", "Consulting and product design", money(310000), "Gross receipts"), ("Officer compensation", "Avery Morgan", money(100000), "W-2 reconciled"), ("Contractors", "Two reportable vendors", money(45000), "1099-NEC reconciled"), ("Capital contribution", "Avery Morgan", money(37000), "Stock-basis increase"), ("Distribution", "Avery Morgan", money(60000), "K-1 box 16 code D")]
    paths.append(create_table_doc(S_CORP / "05_General_Ledger_and_Year_End_Entries.pdf", "General Ledger Summary and Year-End Entries", f"{entity} | 2025", [("Material account ledger summary", [150, 220, 100, 70], ["Account", "Activity", "Ending / total", "Support"], gl_rows, 34, 6.8), ("Year-end journal entries", [120, 270, 150], ["Entry", "Description", "Amount"], [("AJE-01", "Record annual book depreciation", money(3000)), ("AJE-02", "Record shareholder capital contribution", money(37000)), ("AJE-03", "Close $60,000 shareholder distribution to equity", money(60000))], 28, 7)], "The general ledger summary reconciles to the adjusted trial balance and shareholder basis schedule."))
    asset_rows = [("Laptop and display", "02/01/2023", money(15000), "5-year MACRS", money(5000), money(2000), money(8000)), ("Camera equipment", "05/10/2024", money(10000), "5-year MACRS", money(2000), money(1000), money(7000)), ("TOTAL", "", money(25000), "", money(7000), money(3000), money(15000))]
    paths.append(create_table_doc(S_CORP / "06_Fixed_Asset_and_Depreciation_Schedule.pdf", "Fixed Asset and Depreciation Schedule", f"{entity} | 2025", [("Book and tax source facts", [125, 70, 70, 80, 65, 65, 65], ["Asset", "In service", "Cost", "Method", "Prior dep.", "2025 dep.", "Ending basis"], asset_rows, 34, 6.3)], "The $3,000 book depreciation is included within the $24,000 other operating expense account."))
    payroll_rows = [(PERSON["name"], "President / product consultant", money(100000), money(76500), money(23500), money(18500), money(6500))]
    contractor_rows = [("Demo UX Research LLC", "00-0002070", money(25000), "1099-NEC issued"), ("Demo Engineering Co.", "00-0002071", money(20000), "1099-NEC issued"), ("TOTAL", "", money(45000), "")]
    paths.append(create_table_doc(S_CORP / "07_Payroll_W2_and_Contractor_Summary.pdf", "Payroll, W-2, and Contractor Summary", f"{entity} | 2025", [("Shareholder-employee payroll", [105, 120, 63, 63, 63, 63, 63], ["Employee", "Role", "Gross", "W-2 box 1", "401(k)", "Fed WH", "CA WH"], payroll_rows, 35, 5.8), ("Reportable contractors", [190, 110, 110, 130], ["Vendor", "Invalid EIN", "Paid", "Status"], contractor_rows, 29, 7)], "Avery's Social Security and Medicare wages are $100,000; W-2 box 1 is $76,500 after the $23,500 elective deferral."))
    basis_rows = [("Beginning stock basis", money(88000)), ("Capital contribution", money(37000)), ("Increase: ordinary business income", money(60000)), ("Decrease: cash distribution", money(-60000)), ("Ending stock basis", money(125000)), ("Ending shareholder debt basis", money(0))]
    paths.append(create_table_doc(S_CORP / "08_Shareholder_Basis_AAA_and_Distribution_Schedule.pdf", "Shareholder Basis, AAA, and Distribution Schedule", f"{entity} | Avery Morgan | 2025", [("Stock basis rollforward", [360, 180], ["Activity", "Amount"], basis_rows, 28, 7.5), ("AAA reconciliation", [360, 180], ["Activity", "Amount"], [("Beginning AAA", money(87000)), ("Ordinary income", money(60000)), ("Distribution", money(-60000)), ("Ending AAA", money(87000))], 27, 7.5)], "The $60,000 distribution does not exceed Avery's stock basis in this synthetic scenario."))
    paths.append(create_flowthrough_target(S_CORP / "09_Expected_Avery_Morgan_Schedule_K1_1120S.pdf", entity, "Schedule K-1 (Form 1120-S)", ein, "100.000000% all year", [("1", "Ordinary business income", money(60000)), ("16D", "Property distributions", money(60000)), ("17V", "Section 199A information", "See statement")], basis_rows, "This is the expected shareholder flow-through target for Avery's Form 1040 test packet. The filed S-corporation return should generate a K-1 that reconciles to these source records."))
    return paths


def mission_seed_docs() -> list[Path]:
    entity = "Mission Seed Partners, LP"
    form = "Form 1065"
    ein = "00-0002031"
    address = "500 Demo Embarcadero, San Francisco, CA 94111"
    pnl = [("Interest income", money(3200)), ("Net long-term capital gain", money(48000)), ("Management fees", money(-60000)), ("Legal and accounting", money(-32000)), ("Due diligence and other deductible expense", money(-32000)), ("ORDINARY BUSINESS LOSS", money(-124000)), ("NET CHANGE FROM CURRENT-YEAR TAX ITEMS", money(-72800))]
    balance = [("Cash", money(420000), money(305200)), ("Portfolio investments, tax basis", money(1080000), money(1250000)), ("Other assets", money(0), money(12000)), ("TOTAL ASSETS", money(1500000), money(1567200)), ("Liabilities", money(0), money(0)), ("Partners' tax-basis capital", money(1500000), money(1567200)), ("TOTAL LIABILITIES AND CAPITAL", money(1500000), money(1567200))]
    equity = [("Beginning partners' capital", money(1500000)), ("Capital contributions", money(140000)), ("Ordinary business loss", money(-124000)), ("Interest income", money(3200)), ("Long-term capital gain", money(48000)), ("Distributions", money(0)), ("Ending partners' capital", money(1567200))]
    cash = [("Beginning cash", money(420000)), ("Capital contributions", money(140000)), ("Interest receipts", money(3200)), ("Portfolio sale proceeds", money(238000)), ("Operating expenses paid", money(-124000)), ("Portfolio purchases", money(-360000)), ("Other asset purchases / deposits", money(-12000)), ("Ending cash", money(305200))]
    tb = [("1000", "Cash", money(305200), ""), ("1200", "Portfolio investments, tax basis", money(1250000), ""), ("1300", "Other assets", money(12000), ""), ("3000", "Beginning partners' capital", "", money(1500000)), ("3010", "Partner contributions", "", money(140000)), ("4000", "Interest income", "", money(3200)), ("4100", "Long-term capital gain", "", money(48000)), ("5000", "Management, legal, and diligence expense", money(124000), ""), ("TOTAL", "Adjusted trial balance", money(1691200), money(1691200))]
    partner_names = [PERSON["name"]] + [f"Synthetic Partner {i}" for i in range(2, 11)]
    partner_rows = []
    for i, name in enumerate(partner_names, 1):
        tin = PERSON["ssn"] if i == 1 else f"000-00-20{i:02d}"
        contribution = money(20000 if i <= 7 else 0)
        partner_rows.append((name, tin, "10%", contribution, "Limited partner"))
    paths = []
    uploads = [("Financial statements", "P&L, comparative balance sheet, capital, and cash support"), ("Standalone P&L and balance sheet", "Direct platform upload and account mapping"), ("Adjusted trial balance", "Return-line mapping and reconciliation"), ("General ledger summary", "Cash, investments, and expense support"), ("Portfolio activity", "Sale proceeds, basis, and long-term gains"), ("Capital account schedule", "Tax-basis capital rollforward by partner"), ("Partner roster / allocation", "Ownership, invalid demo TINs, and pro-rata items"), ("Expected Avery K-1", "1040 flow-through target and reconciliation")]
    paths.append(create_organizer(PARTNERSHIP / "00_Preparer_Upload_Index_and_Entity_Organizer.pdf", entity, form, ein, address, [(PERSON["name"], "10%", "Limited partner; receives Schedule K-1"), ("Nine synthetic limited partners", "90%", "Each owns 10%; allocation roster included")], uploads, [("Partnership classification", "Domestic limited partnership; calendar year"), ("Ownership changes", "None; ten equal limited partners all year"), ("Special allocations", "None; all tax items allocated 10% to each partner"), ("Liabilities", "No recourse, nonrecourse, or qualified nonrecourse debt"), ("Foreign activity", "None"), ("Section 754 election", "No election in effect")]))
    paths.append(create_financial_statements(PARTNERSHIP / "01_Unaudited_Financial_Statements.pdf", entity, form, pnl, balance, equity, cash))
    paths.append(create_table_doc(PARTNERSHIP / "02_Profit_and_Loss_and_Separately_Stated_Income.pdf", "Profit and Loss and Separately Stated Income", f"{entity} | {form}", [("2025 tax-basis activity", [390, 150], ["Account / tax item", "2025 amount"], pnl, 32, 7.5)], "Ordinary business loss, interest income, and long-term capital gain must be separately stated to partners."))
    paths.append(create_table_doc(PARTNERSHIP / "03_Comparative_Balance_Sheet.pdf", "Comparative Balance Sheet", f"{entity} | 12/31/2025", [("Assets, liabilities, and partners' capital", [270, 135, 135], ["Account", "12/31/2024", "12/31/2025"], balance, 31, 7.2)], "Ending capital reconciles to beginning capital, $140,000 contributions, and current-year net tax items of negative $72,800."))
    paths.append(create_table_doc(PARTNERSHIP / "04_Adjusted_Trial_Balance.pdf", "Adjusted Trial Balance", f"{entity} | 12/31/2025", [("Tax workpaper trial balance", [65, 255, 110, 110], ["Acct", "Account", "Debit", "Credit"], tb, 30, 7)], "Debits and credits each total $1,691,200. The long-term gain is separately identified from ordinary partnership expenses."))
    gl_rows = [("Cash", "Contributions, portfolio purchases, expenses", money(305200), "Bank reconciled"), ("Portfolio investments", "Beginning basis + purchases - disposed basis", money(1250000), "Investment schedule"), ("Other assets", "Deposits and prepaid legal", money(12000), "No depreciation"), ("Interest income", "Deposit and sweep accounts", money(3200), "Bank statement"), ("Portfolio dispositions", "Two long-term investments", money(48000), "Net long-term gain"), ("Operating expenses", "Management, legal, and diligence", money(124000), "Ordinary loss")]
    paths.append(create_table_doc(PARTNERSHIP / "05_General_Ledger_and_Bank_Reconciliation_Summary.pdf", "General Ledger and Bank Reconciliation Summary", f"{entity} | 2025", [("Material account ledger summary", [150, 230, 100, 60], ["Account", "Activity", "Ending / total", "Support"], gl_rows, 35, 6.6), ("Cash reconciliation", [370, 170], ["Item", "Amount"], cash, 25, 7)], "The ending book cash balance of $305,200 agrees to the synthetic year-end bank reconciliation with no outstanding reconciling items."))
    portfolio_rows = [("Demo Robotics, Inc.", "01/20/2023", "05/15/2025", money(180000), money(140000), money(40000)), ("Demo Climate Labs", "07/08/2023", "10/02/2025", money(58000), money(50000), money(8000)), ("TOTAL DISPOSITIONS", "", "", money(238000), money(190000), money(48000))]
    purchases = [("Beginning portfolio basis", money(1080000)), ("2025 portfolio purchases", money(360000)), ("Basis of investments disposed", money(-190000)), ("Ending portfolio tax basis", money(1250000))]
    paths.append(create_table_doc(PARTNERSHIP / "06_Portfolio_Investment_and_Capital_Gain_Schedule.pdf", "Portfolio Investment and Capital-Gain Schedule", f"{entity} | 2025", [("Realized long-term transactions", [150, 75, 75, 85, 80, 75], ["Investment", "Acquired", "Sold", "Proceeds", "Basis", "LT gain"], portfolio_rows, 34, 6.3), ("Portfolio basis reconciliation", [370, 170], ["Activity", "Tax basis"], purchases, 27, 7.2)], "Both dispositions were held more than one year. No wash sales, installment sales, or foreign investments are included."))
    capital_rows = []
    for i, name in enumerate(partner_names, 1):
        beginning = 150000
        contribution = 20000 if i <= 7 else 0
        ending = beginning + contribution - 12400 + 320 + 4800
        capital_rows.append((name, money(beginning), money(contribution), money(-12400), money(320), money(4800), money(ending)))
    paths.append(create_table_doc(PARTNERSHIP / "07_Partner_Tax_Basis_Capital_Accounts.pdf", "Partner Tax-Basis Capital Accounts", f"{entity} | 2025", [("Partner-by-partner rollforward", [115, 80, 75, 75, 60, 65, 70], ["Partner", "Beginning", "Contrib.", "Ordinary", "Interest", "LT gain", "Ending"], capital_rows, 30, 5.7)], "Total ending tax-basis capital is $1,567,200. Avery's ending tax-basis capital is $162,720."))
    allocation_rows = [(name, tin, owned, contrib, ptype) for name, tin, owned, contrib, ptype in partner_rows]
    paths.append(create_table_doc(PARTNERSHIP / "08_Partner_Roster_and_Allocation_Schedule.pdf", "Partner Roster and Allocation Schedule", f"{entity} | 2025", [("Partner identification and ownership", [130, 95, 55, 90, 170], ["Partner", "Invalid TIN", "Share", "Contrib.", "Type"], allocation_rows, 29, 6.3), ("Per-partner current-year allocation", [100, 150, 145, 145], ["Share", "Ordinary loss", "Interest income", "Long-term gain"], [("10%", money(-12400), money(320), money(4800)), ("Total - 10 partners", money(-124000), money(3200), money(48000))], 28, 7)], "All current-year tax items are allocated pro rata. The partner TINs are deliberately invalid synthetic values."))
    avery_basis = [("Beginning tax-basis capital", money(150000)), ("Capital contribution", money(20000)), ("Ordinary business loss", money(-12400)), ("Interest income", money(320)), ("Long-term capital gain", money(4800)), ("Distributions", money(0)), ("Ending tax-basis capital", money(162720))]
    paths.append(create_flowthrough_target(PARTNERSHIP / "09_Expected_Avery_Morgan_Schedule_K1_1065.pdf", entity, "Schedule K-1 (Form 1065)", ein, "10.000000% profit, loss, and capital all year", [("1", "Ordinary business income (loss)", money(-12400)), ("5", "Interest income", money(320)), ("9a", "Net long-term capital gain", money(4800)), ("20Z", "Section 199A information", "See statement")], avery_basis, "This is the expected partner flow-through target for Avery's Form 1040 test packet. The filed partnership return should generate a K-1 that reconciles to the partner roster and tax-basis capital schedule."))
    return paths


def generate_all() -> list[Path]:
    paths = northstar_docs() + morgan_studio_docs() + mission_seed_docs()
    if len(paths) != 30:
        raise RuntimeError(f"Expected 30 PDFs, generated {len(paths)}")
    return paths


if __name__ == "__main__":
    files = generate_all()
    for path in files:
        print(path.relative_to(ROOT))
