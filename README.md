# OmniStudio KYC Customer Onboarding (Financial Services Cloud)

A guided **customer onboarding and KYC/AML** flow for **Financial Services Cloud**, built with **OmniStudio**: an OmniScript, an Integration Procedure, DataRaptors and a FlexCard, backed by testable **Apex Remote Actions**.

> Portfolio / reference project. The Apex in `force-app/` deploys to any org and has full unit tests. The OmniStudio components are in `omnistudio/` as readable design definitions, so you can see the whole flow without an OmniStudio license.

## Flow

```
OmniScript  KYC / CustomerOnboarding
 ├─ Step: Applicant details (masked SSN)
 ├─ Remote Action ─▶ KycRemoteActions.validateIdentity
 ├─ Step: Financial profile (occupation, source of funds, PEP)
 ├─ Integration Procedure KYC_RiskAssessment
 │    ├─ screenSanctions   (watch-list; swap for provider HTTP action)
 │    ├─ calculateRiskScore (jurisdiction, occupation, PEP, deposits, cash)
 │    └─ status = Approved | Pending Compliance Review
 ├─ Step: Product selection ◀─ DataRaptor Turbo Extract (risk-filtered products)
 ├─ Step: Disclosures + e-signature
 └─ DataRaptor Load ─▶ Person Account + Financial Account + EDD Case (if High risk)

FlexCard KYC_ApplicantStatus on the Person Account page
```

## Apex

| Class | Purpose |
|---|---|
| `KycRemoteActions` | Implements `System.Callable`, the entry point OmniStudio uses for Remote Actions. Routes `validateIdentity`, `calculateRiskScore` and `screenSanctions`. |
| `KycService` | Stateless KYC rules: age and SSN checks, SSN masking, 0–100 risk score with explained factors, Enhanced Due Diligence flag. |
| `KycServiceTest` | Covers valid and invalid applicants, low and high risk, sanctions hits and unknown actions. |

Keeping the rules in Apex (not formula steps inside the OmniScript) means they are version-controlled, unit-tested, and reusable from Flow, Agentforce or APIs.

## Deploy

```bash
sf org create scratch -f config/project-scratch-def.json -a kyc -d
sf project deploy start -d force-app
sf apex run test -l RunLocalTests -w 10 -c
```

In an OmniStudio-enabled org, build the components from the definitions in `omnistudio/`, set **Remote Class** = `KycRemoteActions` and choose the matching **Remote Method**, then activate.

## Tech

OmniStudio (OmniScripts · FlexCards · DataRaptors · Integration Procedures) · Financial Services Cloud · Apex · KYC/AML · SFDX · GitHub Actions
