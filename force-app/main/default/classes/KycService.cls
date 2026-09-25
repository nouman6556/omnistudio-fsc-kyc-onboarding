/**
 * Business rules for Financial Services Cloud customer onboarding (KYC / AML).
 * Stateless and map-based so it can be called from OmniStudio, Flow or Apex.
 */
public with sharing class KycService {

    @TestVisible
    private static final Set<String> HIGH_RISK_COUNTRIES = new Set<String>{ 'IR', 'KP', 'SY', 'CU', 'MM' };
    private static final Set<String> HIGH_RISK_OCCUPATIONS = new Set<String>{ 'Money Services Business', 'Casino / Gaming', 'Arms Dealer', 'Politically Exposed Person' };
    private static final Pattern SSN_PATTERN = Pattern.compile('^(?!000|666|9\\d{2})\\d{3}-?(?!00)\\d{2}-?(?!0000)\\d{4}$');
    private static final Pattern EMAIL_PATTERN = Pattern.compile('^[\\w.+-]+@[\\w-]+\\.[\\w.-]+$');

    public static Map<String, Object> validateIdentity(Map<String, Object> input) {
        List<String> errors = new List<String>();
        String firstName = str(input.get('FirstName'));
        String lastName = str(input.get('LastName'));
        String ssn = str(input.get('SSN'));
        String email = str(input.get('Email'));
        Date dob = input.get('BirthDate') == null ? null : Date.valueOf(String.valueOf(input.get('BirthDate')).left(10));

        if (String.isBlank(firstName) || String.isBlank(lastName)) { errors.add('First and last name are required.'); }
        if (dob == null) {
            errors.add('Date of birth is required.');
        } else if (dob.addYears(18) > Date.today()) {
            errors.add('Applicant must be at least 18 years old.');
        }
        if (String.isBlank(ssn) || !SSN_PATTERN.matcher(ssn).matches()) { errors.add('A valid SSN is required.'); }
        if (String.isNotBlank(email) && !EMAIL_PATTERN.matcher(email).matches()) { errors.add('Email format is invalid.'); }

        return new Map<String, Object>{
            'isValid' => errors.isEmpty(),
            'errors' => errors,
            'maskedSSN' => String.isBlank(ssn) ? null : '***-**-' + ssn.right(4)
        };
    }

    public static Map<String, Object> calculateRiskScore(Map<String, Object> input) {
        Integer score = 0;
        List<String> factors = new List<String>();

        String country = str(input.get('CountryOfResidence'));
        String citizenship = str(input.get('Citizenship'));
        if (HIGH_RISK_COUNTRIES.contains(country) || HIGH_RISK_COUNTRIES.contains(citizenship)) {
            score += 40; factors.add('High-risk jurisdiction');
        }
        if (HIGH_RISK_OCCUPATIONS.contains(str(input.get('Occupation')))) {
            score += 30; factors.add('High-risk occupation');
        }
        if (input.get('IsPEP') == true) { score += 30; factors.add('Politically exposed person'); }

        Decimal deposit = input.get('ExpectedMonthlyDeposit') == null ? 0 : Decimal.valueOf(String.valueOf(input.get('ExpectedMonthlyDeposit')));
        if (deposit >= 50000) { score += 20; factors.add('High expected deposit volume'); }
        else if (deposit >= 10000) { score += 10; factors.add('Deposits above CTR threshold'); }

        if (str(input.get('SourceOfFunds')) == 'Cash') { score += 15; factors.add('Cash source of funds'); }
        if (input.get('SanctionsHit') == true) { score = 100; factors.add('Sanctions screening match'); }

        score = Math.min(score, 100);
        String rating = score >= 60 ? 'High' : (score >= 30 ? 'Medium' : 'Low');
        return new Map<String, Object>{
            'riskScore' => score,
            'riskRating' => rating,
            'riskFactors' => factors,
            'requiresEDD' => rating == 'High',       // Enhanced Due Diligence
            'reviewQueue' => rating == 'High' ? 'KYC_Compliance_Review' : null
        };
    }

    /** Mock watch-list screen. Replace with an Integration Procedure HTTP action to your provider. */
    public static Map<String, Object> screenSanctions(Map<String, Object> input) {
        String fullName = (str(input.get('FirstName')) + ' ' + str(input.get('LastName'))).trim().toUpperCase();
        Set<String> demoWatchList = new Set<String>{ 'JOHN BLOCKED', 'JANE SANCTIONED' };
        Boolean hit = demoWatchList.contains(fullName);
        return new Map<String, Object>{
            'SanctionsHit' => hit,
            'screeningStatus' => hit ? 'Potential Match' : 'Clear',
            'screenedOn' => Datetime.now().formatGmt('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'')
        };
    }

    private static String str(Object o) {
        return o == null ? '' : String.valueOf(o).trim();
    }
}
