from __future__ import annotations

from pathlib import Path

from generate_demo_tax_documents import (
    PAGE_H,
    PAGE_W,
    add_filing_warning,
    finish_page,
    make_canvas,
    page_chrome,
    section,
    table,
    text_block,
)


ROOT = Path(__file__).resolve().parents[1]
OUT = (
    ROOT
    / "Demo User Identities"
    / "03_Business_Return_Upload_Files"
    / "03_Mission_Seed_Partners_Form_1065"
)

ENTITY = "Mission Seed Partners, LP"
ENTITY_EIN = "00-0002031"
ENTITY_ADDRESS = "500 Demo Embarcadero, San Francisco, CA 94111"
PARTNER = "Avery Morgan"
PARTNER_TIN = "000-00-2025"


def create_section_199a_statement() -> Path:
    path = OUT / "13_2025_Section_199A_Statement_Avery_Morgan.pdf"
    c = make_canvas(path, "Mission Seed Partners 2025 Section 199A Statement - Avery Morgan")
    page_chrome(
        c,
        "Section 199A Information Statement",
        "Schedule K-1 (Form 1065), Box 20, Code Z | 2025",
    )
    y = PAGE_H - 86
    y = section(c, y, "Partnership and partner")
    y = table(
        c,
        36,
        y,
        [180, 360],
        ["Field", "Synthetic value"],
        [
            ("Partnership", ENTITY),
            ("Invalid demo EIN", ENTITY_EIN),
            ("Partner", PARTNER),
            ("Invalid demo TIN", PARTNER_TIN),
            ("Partner allocation", "10.000000% for the full 2025 calendar year"),
        ],
        24,
        7.2,
    )
    y -= 13
    y = section(c, y, "Trade or business detail")
    y = table(
        c,
        36,
        y,
        [180, 360],
        ["Field", "Statement detail"],
        [
            ("Activity", "Early-stage venture portfolio investment and related partnership operations"),
            ("Principal location", ENTITY_ADDRESS),
            ("Section 162 treatment", "Treated as one domestic trade or business for this synthetic test dataset"),
            ("SSTB", "No - the partnership invests its own capital and does not provide investment-management or advisory services to customers for a fee"),
            ("Aggregation", "Not aggregated with another trade or business"),
            ("Publicly traded partnership", "No"),
        ],
        30,
        6.9,
    )
    y -= 13
    y = section(c, y, "Avery Morgan - Section 199A amounts")
    y = table(
        c,
        36,
        y,
        [360, 180],
        ["Reportable item", "Partner amount"],
        [
            ("Qualified business income (loss)", "-$12,400.00"),
            ("W-2 wages", "$0.00"),
            ("UBIA of qualified property", "$0.00"),
            ("Qualified REIT dividends", "$0.00"),
            ("Qualified PTP income (loss)", "$0.00"),
        ],
        23,
        7.3,
    )
    y -= 13
    y = text_block(
        c,
        36,
        y,
        PAGE_W - 72,
        "Reconciliation: Avery's $4,800 long-term capital gain and $320 portfolio interest income are separately stated on the K-1 and excluded from QBI. The $12,400 QBI loss equals Avery's 10% share of the partnership's $124,000 ordinary business loss. The partner determines any allowable deduction and loss carryforward at the partner level.",
        8.2,
        11.2,
    )
    add_filing_warning(c, max(y - 14, 58))
    finish_page(c, 1)
    c.save()
    return path


def create_capital_gain_confirmation() -> Path:
    path = OUT / "14_2025_Capital_Gain_Reporting_and_1099B_Confirmation.pdf"
    c = make_canvas(path, "Mission Seed Partners 2025 Capital Gain and 1099-B Confirmation")
    page_chrome(
        c,
        "Capital Gain Reporting and Form 1099-B Confirmation",
        f"{ENTITY} | 2025",
    )
    y = PAGE_H - 86
    y = section(c, y, "Direct response to preparer")
    y = table(
        c,
        36,
        y,
        [205, 335],
        ["Question", "Confirmed synthetic fact"],
        [
            ("Brokerage statement available?", "No. The two dispositions were direct sales of privately held portfolio-company shares, not sales through a retail brokerage account."),
            ("Reported on Form 1099-B?", "No. No broker or other payer issued Form 1099-B for either disposition."),
            ("Cost basis reported to IRS?", "No. Neither proceeds nor cost basis was reported to the IRS by a broker."),
            ("Partnership reporting source", "Purchase records, partnership investment ledger, stock records, and closing or settlement statements."),
            ("Expected Form 8949 category", "Long-term transactions not reported on Form 1099-B (Box F), subject to preparer review."),
        ],
        38,
        6.8,
    )
    y -= 15
    y = section(c, y, "2025 realized long-term transactions")
    y = table(
        c,
        36,
        y,
        [142, 77, 77, 83, 83, 78],
        ["Investment", "Acquired", "Sold", "Proceeds", "Basis", "LT gain"],
        [
            ("Demo Robotics, Inc.", "01/20/2023", "05/15/2025", "$180,000.00", "$140,000.00", "$40,000.00"),
            ("Demo Climate Labs", "07/08/2023", "10/02/2025", "$58,000.00", "$50,000.00", "$8,000.00"),
            ("TOTAL", "", "", "$238,000.00", "$190,000.00", "$48,000.00"),
        ],
        32,
        6.6,
    )
    y -= 15
    y = section(c, y, "K-1 reconciliation")
    y = table(
        c,
        36,
        y,
        [360, 180],
        ["Item", "Amount"],
        [
            ("Partnership net long-term capital gain", "$48,000.00"),
            ("Avery Morgan ownership allocation", "10.000000%"),
            ("Avery Morgan Schedule K-1, Box 9a", "$4,800.00"),
        ],
        25,
        7.2,
    )
    y -= 13
    y = text_block(
        c,
        36,
        y,
        PAGE_W - 72,
        "There were no wash sales, installment sales, foreign securities, collectibles, or unrecaptured Section 1250 gain in this synthetic fact pattern. The transaction schedule is the substitute supporting record because no brokerage statement exists.",
        8.2,
        11.2,
    )
    add_filing_warning(c, max(y - 14, 58))
    finish_page(c, 1)
    c.save()
    return path


def create_california_confirmation() -> Path:
    path = OUT / "15_2025_California_Activity_and_Filing_Confirmation.pdf"
    c = make_canvas(path, "Mission Seed Partners 2025 California Activity and Filing Confirmation")
    page_chrome(
        c,
        "California Activity and Filing Confirmation",
        f"{ENTITY} | 2025",
    )
    y = PAGE_H - 86
    y = section(c, y, "Entity facts requested by preparer")
    y = table(
        c,
        36,
        y,
        [155, 55, 330],
        ["Question", "Answer", "Confirmed synthetic detail"],
        [
            ("Operated in California?", "YES", "Administrative and investment activities were conducted from the partnership's San Francisco business office throughout 2025."),
            ("Earned income?", "YES", "$3,200 interest income and $48,000 net long-term capital gain; the partnership also incurred a $124,000 ordinary business loss."),
            ("Owned property?", "YES", "At 12/31/2025: $305,200 cash, $1,250,000 tax basis in portfolio investments, and $12,000 of other assets. No real property was owned."),
            ("Had employees?", "NO", "No employees, payroll, Forms W-2, or California payroll accounts. Operations were performed by an outside manager and vendors."),
            ("Registered in California?", "YES", "The limited partnership was registered with the California Secretary of State for 2025. Invalid demo file number: DEMO-LP-2025-031."),
        ],
        43,
        6.5,
    )
    y -= 14
    y = section(c, y, "California filing conclusion for this demo return")
    y = table(
        c,
        36,
        y,
        [215, 325],
        ["Filing item", "Conclusion"],
        [
            ("2025 California partnership return", "Required - prepare California Form 565 and partner Schedule K-1 (565)."),
            ("Basis for filing", "Registered California limited partnership, California business activity, and a California business address."),
            ("California annual tax", "$800 annual tax applies to the limited partnership; it is separate from the $1,200 registration and certified-copy charges in the expense ledger."),
            ("Federal-only draft status", "Remove the federal-only hold and add the California filing to the 2025 return set."),
            ("Avery Morgan", "California resident partner at 245 Demo Street, Apt 12, San Francisco, CA 94107; issue Schedule K-1 (565)."),
        ],
        36,
        6.8,
    )
    y -= 14
    y = text_block(
        c,
        36,
        y,
        PAGE_W - 72,
        "Technical reference used for the synthetic conclusion: California 2025 Form 565 instructions state that a limited partnership registered or doing business in California must file Form 565 and is generally subject to the $800 annual tax. Final filing treatment remains the return preparer's responsibility.",
        8.1,
        11,
    )
    add_filing_warning(c, max(y - 14, 58))
    finish_page(c, 1)
    c.save()
    return path


def generate_all() -> list[Path]:
    OUT.mkdir(parents=True, exist_ok=True)
    paths = [
        create_section_199a_statement(),
        create_capital_gain_confirmation(),
        create_california_confirmation(),
    ]
    assert len(paths) == 3
    return paths


if __name__ == "__main__":
    for file in generate_all():
        print(file.relative_to(ROOT))
