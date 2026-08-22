from __future__ import annotations

from pathlib import Path
from typing import Sequence

from generate_demo_tax_documents import (
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
OUT = ROOT / "Demo User Identities" / "04_Prior_Year_2024_Returns"


def cover_page(c, entity: str, form: str, ein: str, address: str, summary_rows: Sequence[Sequence[str]]) -> None:
    page_chrome(c, f"2024 {form} - Client Copy", f"{entity} | Prior-year return")
    y = PAGE_H - 96
    y = section(c, y, "Return identification")
    y = table(c, 36, y, [180, 360], ["Field", "Synthetic return value"], [
        ("Taxpayer", entity),
        ("Invalid demo EIN", ein),
        ("Address", address),
        ("Tax year", "Calendar year beginning 01/01/2024 and ending 12/31/2024"),
        ("Return", form),
        ("Accounting method", "Accrual" if form == "Form 1120" else "Cash"),
        ("Electronic filing status", "DEMO ACCEPTED - confirmation DEMO-EFILE-2024"),
        ("Synthetic filing date", "03/15/2025"),
    ], 27, 7.4)
    y -= 14
    y = section(c, y, "Return summary")
    y = table(c, 36, y, [360, 180], ["Item", "Amount / status"], summary_rows, 27, 7.5)
    y -= 16
    y = text_block(c, 36, y, PAGE_W - 72, "This is a synthetic prior-year client copy created for tax-software testing. It is not an IRS transcript, not an official government form, and cannot be filed or used as proof of filing.", 9, 13)
    add_filing_warning(c, y - 20)
    finish_page(c, 1)


def return_page(c, entity: str, form: str, title: str, sections, page_no: int) -> None:
    page_chrome(c, f"{form} - {title}", f"{entity} | 2024")
    y = PAGE_H - 82
    for section_title, widths, headers, rows, row_h, font_size in sections:
        y = section(c, y, section_title)
        y = table(c, 36, y, widths, headers, rows, row_h, font_size)
        y -= 14
    add_filing_warning(c, max(y - 8, 58))
    finish_page(c, page_no)


def create_1120() -> Path:
    path = OUT / "Northstar_Labs_2024_Form_1120_Client_Copy.pdf"
    c = make_canvas(path, "Northstar Labs 2024 Form 1120 Client Copy")
    entity = "Northstar Labs, Inc."
    cover_page(c, entity, "Form 1120", "00-0002030", "300 Demo Startup Way, San Francisco, CA 94107", [
        ("Gross receipts", money(600000)),
        ("Taxable income", money(450000)),
        ("Total federal income tax", money(94500)),
        ("Payments and credits", money(94500)),
        ("Balance due", money(0)),
        ("Total cash dividends", money(222500)),
    ])

    return_page(c, entity, "Form 1120", "U.S. Corporation Income Tax Return", [
        ("Income", [60, 340, 140], ["Line", "Description", "Amount"], [
            ("1a", "Gross receipts or sales", money(600000)),
            ("5", "Interest income", money(2400)),
            ("11", "Total income", money(602400)),
        ], 30, 7.5),
        ("Deductions", [60, 340, 140], ["Line", "Description", "Amount"], [
            ("12", "Compensation of officers and employees", money(60000)),
            ("13", "Salaries and wages / contractors", money(30000)),
            ("16", "Rents", money(9000)),
            ("20", "Depreciation", money(10000)),
            ("26", "Other deductions - cloud, legal, advertising, insurance", money(43400)),
            ("27", "Total deductions", money(152400)),
            ("28", "Taxable income before special deductions", money(450000)),
            ("30", "Taxable income", money(450000)),
        ], 29, 7.2),
    ], 2)

    return_page(c, entity, "Form 1120", "Schedule J - Tax Computation and Payments", [
        ("Tax computation", [70, 330, 140], ["Line", "Tax item", "Amount"], [
            ("1", "Income tax at 21%", money(94500)),
            ("11", "Total tax", money(94500)),
        ], 32, 7.5),
        ("Payments and refundable credits", [70, 330, 140], ["Line", "Payment item", "Amount"], [
            ("14", "Estimated tax payments", money(90000)),
            ("15", "Extension payment", money(4500)),
            ("33", "Total payments and credits", money(94500)),
            ("35", "Amount owed", money(0)),
            ("36", "Overpayment", money(0)),
        ], 31, 7.5),
        ("Filing information", [220, 320], ["Field", "Synthetic response"], [
            ("Consolidated return", "No"),
            ("Personal holding company", "No"),
            ("Foreign financial accounts", "No"),
            ("Electronic confirmation", "DEMO-EFILE-1120-2024"),
        ], 28, 7.2),
    ], 3)

    return_page(c, entity, "Form 1120", "Schedule L and Retained Earnings", [
        ("Schedule L - balance sheets per books", [270, 135, 135], ["Account", "12/31/2023", "12/31/2024"], [
            ("Cash", money(160000), money(250000)),
            ("Accounts receivable", money(80000), money(120000)),
            ("Equipment, gross", money(40000), money(50000)),
            ("Accumulated depreciation", money(-5000), money(-10000)),
            ("Total assets", money(275000), money(410000)),
            ("Accounts payable", money(23000), money(25000)),
            ("Common stock", money(2000), money(2000)),
            ("Retained earnings", money(250000), money(383000)),
            ("Total liabilities and equity", money(275000), money(410000)),
        ], 27, 7.2),
        ("Schedules M-1 and M-2", [360, 180], ["Reconciliation item", "Amount"], [
            ("Book income after federal tax", money(355500)),
            ("Add: federal income tax expense", money(94500)),
            ("Taxable income", money(450000)),
            ("Beginning retained earnings", money(250000)),
            ("Add: book net income", money(355500)),
            ("Less: cash dividends", money(-222500)),
            ("Ending retained earnings", money(383000)),
        ], 25, 7.2),
    ], 4)

    return_page(c, entity, "Form 1120", "Shareholder and Dividend Appendix", [
        ("Shareholder ownership and dividend reporting", [135, 100, 65, 110, 130], ["Shareholder", "Invalid TIN", "Owned", "2024 dividend", "Reporting"], [
            (PERSON["name"], PERSON["ssn"], "50%", money(111250), "1099-DIV box 1a / 1b"),
            ("Riley Chen", "000-00-2026", "50%", money(111250), "1099-DIV box 1a / 1b"),
            ("TOTAL", "", "100%", money(222500), ""),
        ], 32, 6.8),
        ("Avery Morgan 2024 recipient copy summary", [180, 210, 150], ["Form", "Item", "Amount"], [
            ("1099-DIV", "Ordinary dividends", money(111250)),
            ("1099-DIV", "Qualified dividends", money(111250)),
            ("Schedule K-1", "Not applicable to a C corporation", money(0)),
        ], 30, 7.2),
    ], 5)
    c.save()
    return path


def create_1120s() -> Path:
    path = OUT / "Morgan_Product_Studio_2024_Form_1120S_Client_Copy.pdf"
    c = make_canvas(path, "Morgan Product Studio 2024 Form 1120-S Client Copy")
    entity = "Morgan Product Studio, Inc."
    cover_page(c, entity, "Form 1120-S", "00-0002026", "100 Demo Market Street, San Francisco, CA 94105", [
        ("Gross receipts", money(250000)),
        ("Ordinary business income", money(45000)),
        ("Officer compensation", money(90000)),
        ("Shareholder distributions", money(20000)),
        ("Entity-level federal tax", money(0)),
        ("Avery ending stock basis", money(88000)),
    ])

    return_page(c, entity, "Form 1120-S", "U.S. Income Tax Return for an S Corporation", [
        ("Income and deductions", [60, 340, 140], ["Line", "Description", "Amount"], [
            ("1a", "Gross receipts or sales", money(250000)),
            ("7", "Compensation of officers", money(90000)),
            ("8", "Salaries and wages / contractors", money(38000)),
            ("11", "Rents", money(10000)),
            ("14", "Depreciation", money(3000)),
            ("19", "Other deductions", money(64000)),
            ("20", "Total deductions", money(205000)),
            ("21", "Ordinary business income", money(45000)),
        ], 29, 7.2),
        ("Return facts", [220, 320], ["Field", "Synthetic response"], [
            ("S election in effect", "Yes"),
            ("Number of shareholders", "1"),
            ("Foreign activity", "None"),
            ("Entity-level tax", money(0)),
        ], 28, 7.2),
    ], 2)

    return_page(c, entity, "Form 1120-S", "Schedule K - Shareholders' Pro Rata Share Items", [
        ("Schedule K", [80, 310, 150], ["Line / code", "Item", "Total"], [
            ("1", "Ordinary business income", money(45000)),
            ("16D", "Property distributions", money(20000)),
            ("17V", "Section 199A information", "See statement"),
        ], 33, 7.5),
        ("Payroll reconciliation", [250, 145, 145], ["Payroll item", "Book / payroll", "W-2 reporting"], [
            ("Avery Morgan gross salary", money(90000), "Boxes 3 and 5"),
            ("401(k) elective deferral", money(22500), "Box 12 code D"),
            ("Federal taxable wages", money(67500), "W-2 box 1"),
            ("Federal withholding", money(15000), "W-2 box 2"),
        ], 30, 7.2),
    ], 3)

    return_page(c, entity, "Form 1120-S", "Schedule L, M-1, and M-2", [
        ("Schedule L - balance sheets per books", [270, 135, 135], ["Account", "12/31/2023", "12/31/2024"], [
            ("Cash", money(40000), money(60000)),
            ("Accounts receivable", money(15000), money(20000)),
            ("Equipment, gross", money(20000), money(25000)),
            ("Accumulated depreciation", money(-5000), money(-7000)),
            ("Total assets", money(70000), money(98000)),
            ("Accounts payable", money(5000), money(7000)),
            ("Payroll liabilities", money(2000), money(3000)),
            ("Common stock", money(1000), money(1000)),
            ("AAA / retained earnings", money(62000), money(87000)),
            ("Total liabilities and equity", money(70000), money(98000)),
        ], 25, 7.0),
        ("AAA and stock-basis reconciliation", [360, 180], ["Activity", "Amount"], [
            ("Beginning AAA / retained earnings", money(62000)),
            ("Ordinary business income", money(45000)),
            ("Shareholder distribution", money(-20000)),
            ("Ending AAA / retained earnings", money(87000)),
            ("Ending Avery stock basis", money(88000)),
        ], 24, 7.2),
    ], 4)

    return_page(c, entity, "Schedule K-1 (Form 1120-S)", "Avery Morgan - Shareholder Copy", [
        ("Shareholder information", [180, 360], ["Field", "Synthetic value"], [
            ("Corporation", entity + " | invalid EIN 00-0002026"),
            ("Shareholder", PERSON["name"] + " | invalid TIN " + PERSON["ssn"]),
            ("Address", PERSON["address"]),
            ("Allocation percentage", "100.000000% all year"),
        ], 29, 7.2),
        ("Shareholder's share", [90, 290, 160], ["Box / code", "Item", "Amount"], [
            ("1", "Ordinary business income", money(45000)),
            ("16D", "Property distributions", money(20000)),
            ("17V", "Section 199A information", "See statement"),
        ], 30, 7.5),
        ("Stock basis support", [360, 180], ["Activity", "Amount"], [
            ("Beginning stock basis", money(63000)),
            ("Increase: ordinary business income", money(45000)),
            ("Decrease: distribution", money(-20000)),
            ("Ending stock basis", money(88000)),
        ], 27, 7.2),
    ], 5)
    c.save()
    return path


def create_1065() -> Path:
    path = OUT / "Mission_Seed_Partners_2024_Form_1065_Client_Copy.pdf"
    c = make_canvas(path, "Mission Seed Partners 2024 Form 1065 Client Copy")
    entity = "Mission Seed Partners, LP"
    cover_page(c, entity, "Form 1065", "00-0002031", "500 Demo Embarcadero, San Francisco, CA 94111", [
        ("Ordinary business loss", money(-80000)),
        ("Interest income", money(10000)),
        ("Net long-term capital gain", money(20000)),
        ("Net current-year tax items", money(-50000)),
        ("Capital contributions", money(350000)),
        ("Ending partners' capital", money(1500000)),
    ])

    return_page(c, entity, "Form 1065", "U.S. Return of Partnership Income", [
        ("Income and deductions", [60, 340, 140], ["Line", "Description", "Amount"], [
            ("1a", "Gross receipts or sales", money(0)),
            ("15", "Interest income - separately stated", money(10000)),
            ("22", "Ordinary business income (loss)", money(-80000)),
            ("9a", "Net long-term capital gain - separately stated", money(20000)),
        ], 33, 7.5),
        ("Ordinary deductions", [70, 330, 140], ["Line", "Deduction", "Amount"], [
            ("10", "Guaranteed payments", money(0)),
            ("20", "Management, legal, and diligence expense", money(80000)),
            ("21", "Total deductions", money(80000)),
        ], 31, 7.5),
        ("Return facts", [220, 320], ["Field", "Synthetic response"], [
            ("Number of Schedules K-1", "10"),
            ("Publicly traded partnership", "No"),
            ("Foreign activity", "None"),
            ("Section 754 election", "No"),
        ], 28, 7.2),
    ], 2)

    return_page(c, entity, "Form 1065", "Schedule K - Partners' Distributive Share Items", [
        ("Schedule K", [80, 310, 150], ["Line / code", "Item", "Total"], [
            ("1", "Ordinary business income (loss)", money(-80000)),
            ("5", "Interest income", money(10000)),
            ("9a", "Net long-term capital gain", money(20000)),
            ("20Z", "Section 199A information", "See statement"),
        ], 32, 7.5),
        ("Per-partner pro rata allocation", [170, 185, 185], ["Partner share", "Per partner", "Total - 10 partners"], [
            ("Ordinary loss", money(-8000), money(-80000)),
            ("Interest income", money(1000), money(10000)),
            ("Long-term capital gain", money(2000), money(20000)),
        ], 31, 7.2),
    ], 3)

    return_page(c, entity, "Form 1065", "Schedule L and Partners' Capital", [
        ("Schedule L - balance sheets per books", [270, 135, 135], ["Account", "12/31/2023", "12/31/2024"], [
            ("Cash", money(300000), money(420000)),
            ("Portfolio investments, tax basis", money(900000), money(1080000)),
            ("Total assets", money(1200000), money(1500000)),
            ("Liabilities", money(0), money(0)),
            ("Partners' capital", money(1200000), money(1500000)),
            ("Total liabilities and capital", money(1200000), money(1500000)),
        ], 29, 7.2),
        ("Schedule M-2 - partners' capital accounts", [360, 180], ["Activity", "Amount"], [
            ("Beginning partners' capital", money(1200000)),
            ("Capital contributions", money(350000)),
            ("Ordinary business loss", money(-80000)),
            ("Interest income", money(10000)),
            ("Long-term capital gain", money(20000)),
            ("Distributions", money(0)),
            ("Ending partners' capital", money(1500000)),
        ], 27, 7.2),
    ], 4)

    return_page(c, entity, "Schedule K-1 (Form 1065)", "Avery Morgan - Partner Copy", [
        ("Partner information", [180, 360], ["Field", "Synthetic value"], [
            ("Partnership", entity + " | invalid EIN 00-0002031"),
            ("Partner", PERSON["name"] + " | invalid TIN " + PERSON["ssn"]),
            ("Address", PERSON["address"]),
            ("Partner type", "Individual, limited partner"),
            ("Profit, loss, and capital", "10.000000% all year"),
            ("Share of liabilities", "$0 recourse / $0 nonrecourse / $0 qualified nonrecourse"),
        ], 27, 7.2),
        ("Partner's share", [90, 290, 160], ["Box / code", "Item", "Amount"], [
            ("1", "Ordinary business income (loss)", money(-8000)),
            ("5", "Interest income", money(1000)),
            ("9a", "Net long-term capital gain", money(2000)),
            ("20Z", "Section 199A information", "See statement"),
        ], 28, 7.2),
        ("Tax-basis capital", [360, 180], ["Activity", "Amount"], [
            ("Beginning capital", money(120000)),
            ("Capital contributed", money(35000)),
            ("Current-year net decrease", money(-5000)),
            ("Withdrawals and distributions", money(0)),
            ("Ending capital", money(150000)),
        ], 25, 7.2),
    ], 5)
    c.save()
    return path


def generate_all() -> list[Path]:
    OUT.mkdir(parents=True, exist_ok=True)
    paths = [create_1120(), create_1120s(), create_1065()]
    if len(paths) != 3:
        raise RuntimeError("Expected three prior-year returns")
    return paths


if __name__ == "__main__":
    for file in generate_all():
        print(file.relative_to(ROOT))
