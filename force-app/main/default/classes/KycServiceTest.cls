@IsTest
private class KycServiceTest {

    private static Map<String, Object> applicant() {
        return new Map<String, Object>{
            'FirstName' => 'Alex', 'LastName' => 'Rivera', 'SSN' => '123-45-6789',
            'Email' => 'alex@example.com', 'BirthDate' => '1985-06-15',
            'CountryOfResidence' => 'US', 'Citizenship' => 'US', 'Occupation' => 'Engineer',
            'ExpectedMonthlyDeposit' => 5000, 'SourceOfFunds' => 'Salary', 'IsPEP' => false
        };
    }

    private static Map<String, Object> callAction(String action, Map<String, Object> input) {
        return (Map<String, Object>) new KycRemoteActions().call(action,
            new Map<String, Object>{ 'input' => input, 'output' => new Map<String, Object>(), 'options' => new Map<String, Object>() });
    }

    @IsTest
    static void validApplicantPasses() {
        Map<String, Object> out = callAction('validateIdentity', applicant());
        Assert.areEqual(true, out.get('isValid'));
        Assert.areEqual('***-**-6789', out.get('maskedSSN'));
    }

    @IsTest
    static void invalidApplicantCollectsErrors() {
        Map<String, Object> input = applicant();
        input.put('SSN', '000-12-3456');
        input.put('BirthDate', String.valueOf(Date.today().addYears(-16)));
        input.put('Email', 'not-an-email');
        Map<String, Object> out = callAction('validateIdentity', input);
        Assert.areEqual(false, out.get('isValid'));
        Assert.areEqual(3, ((List<String>) out.get('errors')).size());
    }

    @IsTest
    static void lowRiskApplicant() {
        Map<String, Object> out = callAction('calculateRiskScore', applicant());
        Assert.areEqual('Low', out.get('riskRating'));
        Assert.areEqual(false, out.get('requiresEDD'));
    }

    @IsTest
    static void highRiskApplicantNeedsEdd() {
        Map<String, Object> input = applicant();
        input.put('IsPEP', true);
        input.put('ExpectedMonthlyDeposit', 75000);
        input.put('SourceOfFunds', 'Cash');
        Map<String, Object> out = callAction('calculateRiskScore', input);
        Assert.areEqual('High', out.get('riskRating'));
        Assert.areEqual('KYC_Compliance_Review', out.get('reviewQueue'));
    }

    @IsTest
    static void sanctionsHitForcesMaxScore() {
        Map<String, Object> input = applicant();
        input.put('FirstName', 'Jane');
        input.put('LastName', 'Sanctioned');
        Map<String, Object> screen = callAction('screenSanctions', input);
        Assert.areEqual(true, screen.get('SanctionsHit'));
        input.putAll(screen);
        Assert.areEqual(100, callAction('calculateRiskScore', input).get('riskScore'));
        Assert.areEqual('Clear', callAction('screenSanctions', applicant()).get('screeningStatus'));
    }

    @IsTest
    static void unknownActionThrows() {
        try {
            callAction('doSomethingElse', applicant());
            Assert.fail('Expected KycException');
        } catch (KycRemoteActions.KycException e) {
            Assert.isTrue(e.getMessage().contains('Unsupported'));
        }
    }
}
