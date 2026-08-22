# Approval: John and David creation plus Cindy owner transfer

- **Approved by:** Ross Gates
- **Date:** 2026-08-20
- **Approval source:** Current Codex instruction: “Change Cindy to be my deal, not Max's And write John and David to Attio.”
- **John target:** `adairadvisorygroup.com`; create or confidently upsert the Company, John Adair Person, one existing-schema Deal, and one evidence-backed Company note.
- **David target:** `bartolmecpa.com`; create or confidently upsert the Company, David Bartolme Person, one existing-schema Deal, and one evidence-backed Company note.
- **Cindy target:** existing deal `0cbe37b8-21ca-468c-b99a-8d99797b8574`; change only Deal owner from Max Minsker to Ross Gates.
- **Permitted stage for new deals:** Prove Value, because both first calls scheduled a specific hands-on trial during the call.
- **Owner:** Ross Gates (`fd286374-d5c3-4417-87dc-e62c596da0fc`).
- **Opportunity values:** John: 100 annual returns × $40 = $4,000. David: 250 annual returns × $40 = $10,000.
- **Duplicate controls:** Match Company by business domain, Person by email, and Deal by company plus canonical name immediately before each create.
- **Verification:** Read every changed or created record and both notes after writing; require exactly one match per identity.
- **Not approved:** Any other owner or stage change, Contracting, Won, Lost, backward movement, deletion, merge, or general scheduled Attio activation.
- **Rollback:** Cindy’s prior owner is Max Minsker (`3887ef2d-7368-4e57-b4e4-3b712665a6e5`). Newly created records require manual review before any archive or deletion.

## Completion

- **Completed:** 2026-08-20 17:31 Pacific.
- **Cindy deal:** `0cbe37b8-21ca-468c-b99a-8d99797b8574`; owner verified as Ross. Stage, value, company, and people associations remained unchanged.
- **John:** Company `eeed0db3-5672-4f5d-8ff3-af020d38ca0b`; Person `104cad00-845b-4675-bb05-6dbf1b7d6211`; Deal `b85d18e2-de7d-4b16-85ae-4656ba56a687`; Note `7f66d475-9dab-4a0f-85d8-25fc6ac4954a`.
- **David:** Company `2df38907-e680-4964-beda-7bd914b6e1ca`; Person `658837ea-2866-4318-84e7-879c971c4d37`; Deal `5710cc8e-c06a-45e5-b113-3ca9a3e8d354`; Note `8753504f-3b5e-4606-a64d-f53c742ae12c`.
- **Verification:** Exact-domain, exact-email, and canonical-deal searches returned one match for John and one for David. Both notes were verified against their Company and meeting IDs.
