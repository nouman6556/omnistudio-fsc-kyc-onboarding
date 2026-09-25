/**
 * OmniStudio Remote Action class for the KYC onboarding OmniScript and
 * Integration Procedure. Implements System.Callable, which is the interface
 * the standard (non-managed) OmniStudio runtime uses for Apex Remote Actions.
 *
 * Supported methods (Remote Class = KycRemoteActions):
 *   validateIdentity    - format/age checks on applicant data
 *   calculateRiskScore  - KYC/AML risk rating (Low / Medium / High)
 *   screenSanctions     - watch-list screening (mock provider)
 */
public with sharing class KycRemoteActions implements System.Callable {

    public class KycException extends Exception {}

    public Object call(String action, Map<String, Object> args) {
        Map<String, Object> input = args == null ? new Map<String, Object>() : (Map<String, Object>) args.get('input');
        Map<String, Object> output = args == null ? null : (Map<String, Object>) args.get('output');
        if (input == null) { input = new Map<String, Object>(); }
        if (output == null) { output = new Map<String, Object>(); }

        switch on action {
            when 'validateIdentity'   { output.putAll(KycService.validateIdentity(input)); }
            when 'calculateRiskScore' { output.putAll(KycService.calculateRiskScore(input)); }
            when 'screenSanctions'    { output.putAll(KycService.screenSanctions(input)); }
            when else { throw new KycException('Unsupported action: ' + action); }
        }
        return output;
    }
}
