//
//  AuthenticationEndpointTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 11.05.2026.
//

import XCTest
@testable import Permanent

class AuthenticationEndpointTests: XCTestCase {

    // MARK: - Helpers

    private func dict(_ params: RequestParameters?) -> [String: Any]? {
        return params as? [String: Any]
    }

    private func requestVO(from params: RequestParameters?) -> [String: Any]? {
        let root = dict(params)
        return root?["RequestVO"] as? [String: Any]
    }

    private func dataArray(from params: RequestParameters?) -> [[String: Any]]? {
        let vo = requestVO(from: params)
        return vo?["data"] as? [[String: Any]]
    }

    // MARK: - Path Tests

    func testVerifyAuthPath() {
        let endpoint = AuthenticationEndpoint.verifyAuth
        XCTAssertEqual(endpoint.path, "/auth/loggedin")
    }

    func testLoginPath() {
        let endpoint = AuthenticationEndpoint.login(credentials: ("test@example.com", "password123"))
        XCTAssertEqual(endpoint.path, "/auth/login")
    }

    func testVerifyPath() {
        let endpoint = AuthenticationEndpoint.verify(credentials: ("test@example.com", "123456", .phone))
        XCTAssertEqual(endpoint.path, "/auth/verify")
    }

    func testForgotPasswordPath() {
        let endpoint = AuthenticationEndpoint.forgotPassword(email: "test@example.com")
        XCTAssertEqual(endpoint.path, "/auth/sendEmailForgotPassword")
    }

    func testCreateCredentialsPath() {
        let endpoint = AuthenticationEndpoint.createCredentials(credentials: ("Test User", "pass123", "test@example.com", nil))
        XCTAssertEqual(endpoint.path, "/auth/createCredentials")
    }

    func testLogoutPath() {
        let endpoint = AuthenticationEndpoint.logout
        XCTAssertEqual(endpoint.path, "/auth/logout")
    }

    func testGetIDPUserPath() {
        let endpoint = AuthenticationEndpoint.getIDPUser
        XCTAssertEqual(endpoint.path, "")
    }

    func testSend2FAEnableCodePath() {
        let endpoint = AuthenticationEndpoint.send2FAEnableCode(parameters: ("sms", "+1234567890"))
        XCTAssertEqual(endpoint.path, "")
    }

    func testEnable2FAPath() {
        let endpoint = AuthenticationEndpoint.enable2FA(parameters: ("sms", "+1234567890", "123456"))
        XCTAssertEqual(endpoint.path, "")
    }

    func testSend2FADisableCodePath() {
        let endpoint = AuthenticationEndpoint.send2FADisableCode(parameters: ("sms", nil))
        XCTAssertEqual(endpoint.path, "")
    }

    func testDisable2FAPath() {
        let endpoint = AuthenticationEndpoint.disable2FA(parameters: ("sms", "654321"))
        XCTAssertEqual(endpoint.path, "")
    }

    // MARK: - HTTP Method Tests

    func testGetIDPUserMethodIsGet() {
        let endpoint = AuthenticationEndpoint.getIDPUser
        XCTAssertEqual(endpoint.method, .get)
    }

    func testLoginMethodIsPost() {
        let endpoint = AuthenticationEndpoint.login(credentials: ("a@b.com", "pw"))
        XCTAssertEqual(endpoint.method, .post)
    }

    func testVerifyAuthMethodIsPost() {
        let endpoint = AuthenticationEndpoint.verifyAuth
        XCTAssertEqual(endpoint.method, .post)
    }

    func testVerifyMethodIsPost() {
        let endpoint = AuthenticationEndpoint.verify(credentials: ("a@b.com", "1234", .mfa))
        XCTAssertEqual(endpoint.method, .post)
    }

    func testForgotPasswordMethodIsPost() {
        let endpoint = AuthenticationEndpoint.forgotPassword(email: "a@b.com")
        XCTAssertEqual(endpoint.method, .post)
    }

    func testCreateCredentialsMethodIsPost() {
        let endpoint = AuthenticationEndpoint.createCredentials(credentials: ("Name", "pw", "a@b.com", nil))
        XCTAssertEqual(endpoint.method, .post)
    }

    func testLogoutMethodIsPost() {
        let endpoint = AuthenticationEndpoint.logout
        XCTAssertEqual(endpoint.method, .post)
    }

    func testSend2FAEnableCodeMethodIsPost() {
        let endpoint = AuthenticationEndpoint.send2FAEnableCode(parameters: ("sms", "+1234567890"))
        XCTAssertEqual(endpoint.method, .post)
    }

    func testEnable2FAMethodIsPost() {
        let endpoint = AuthenticationEndpoint.enable2FA(parameters: ("sms", "+1234567890", "000000"))
        XCTAssertEqual(endpoint.method, .post)
    }

    func testSend2FADisableCodeMethodIsPost() {
        let endpoint = AuthenticationEndpoint.send2FADisableCode(parameters: ("sms", nil))
        XCTAssertEqual(endpoint.method, .post)
    }

    func testDisable2FAMethodIsPost() {
        let endpoint = AuthenticationEndpoint.disable2FA(parameters: ("sms", "999999"))
        XCTAssertEqual(endpoint.method, .post)
    }

    // MARK: - Request/Response Type Tests

    func testRequestTypeIsAlwaysData() {
        let endpoints: [AuthenticationEndpoint] = [
            .verifyAuth,
            .login(credentials: ("a@b.com", "pw")),
            .verify(credentials: ("a@b.com", "1234", .phone)),
            .forgotPassword(email: "a@b.com"),
            .createCredentials(credentials: ("Name", "pw", "a@b.com", nil)),
            .logout,
            .getIDPUser,
            .send2FAEnableCode(parameters: ("sms", "+1234567890")),
            .enable2FA(parameters: ("sms", "+1234567890", "123456")),
            .send2FADisableCode(parameters: ("sms", nil)),
            .disable2FA(parameters: ("sms", "654321"))
        ]

        for endpoint in endpoints {
            XCTAssertEqual(endpoint.requestType, .data, "requestType should be .data for \(endpoint)")
        }
    }

    func testResponseTypeIsAlwaysJson() {
        let endpoints: [AuthenticationEndpoint] = [
            .verifyAuth,
            .login(credentials: ("a@b.com", "pw")),
            .verify(credentials: ("a@b.com", "1234", .phone)),
            .forgotPassword(email: "a@b.com"),
            .createCredentials(credentials: ("Name", "pw", "a@b.com", nil)),
            .logout,
            .getIDPUser,
            .send2FAEnableCode(parameters: ("sms", "+1234567890")),
            .enable2FA(parameters: ("sms", "+1234567890", "123456")),
            .send2FADisableCode(parameters: ("sms", nil)),
            .disable2FA(parameters: ("sms", "654321"))
        ]

        for endpoint in endpoints {
            XCTAssertEqual(endpoint.responseType, .json, "responseType should be .json for \(endpoint)")
        }
    }

    // MARK: - Progress Handler Tests

    func testProgressHandlerIsAlwaysNil() {
        let endpoints: [AuthenticationEndpoint] = [
            .verifyAuth,
            .login(credentials: ("a@b.com", "pw")),
            .logout,
            .getIDPUser,
            .send2FAEnableCode(parameters: ("sms", "+1234567890"))
        ]

        for endpoint in endpoints {
            XCTAssertNil(endpoint.progressHandler, "progressHandler should be nil for \(endpoint)")
        }
    }

    // MARK: - Headers Tests

    func testLoginHeadersContainContentType() {
        let endpoint = AuthenticationEndpoint.login(credentials: ("a@b.com", "pw"))
        let headers = endpoint.headers
        XCTAssertNotNil(headers)
        XCTAssertEqual(headers?["content-type"], "application/json; charset=utf-8")
    }

    func testLoginHeadersDoNotContainRequestVersion() {
        let endpoint = AuthenticationEndpoint.login(credentials: ("a@b.com", "pw"))
        XCTAssertNil(endpoint.headers?["Request-Version"])
    }

    func testCreateCredentialsHeadersContainContentType() {
        let endpoint = AuthenticationEndpoint.createCredentials(credentials: ("Name", "pw", "a@b.com", nil))
        XCTAssertEqual(endpoint.headers?["content-type"], "application/json; charset=utf-8")
    }

    func testCreateCredentialsHeadersContainRequestVersion() {
        let endpoint = AuthenticationEndpoint.createCredentials(credentials: ("Name", "pw", "a@b.com", nil))
        XCTAssertEqual(endpoint.headers?["Request-Version"], "2")
    }

    func testGetIDPUserHeadersContainContentTypeAndRequestVersion() {
        let endpoint = AuthenticationEndpoint.getIDPUser
        let headers = endpoint.headers
        XCTAssertNotNil(headers)
        XCTAssertEqual(headers?["content-type"], "application/json; charset=utf-8")
        XCTAssertEqual(headers?["Request-Version"], "2")
    }

    func testVerifyAuthHeadersContainContentType() {
        let endpoint = AuthenticationEndpoint.verifyAuth
        let headers = endpoint.headers
        XCTAssertNotNil(headers)
        XCTAssertEqual(headers?["content-type"], "application/json; charset=utf-8")
    }

    func testLogoutHeadersContainContentType() {
        let endpoint = AuthenticationEndpoint.logout
        let headers = endpoint.headers
        XCTAssertNotNil(headers)
        XCTAssertEqual(headers?["content-type"], "application/json; charset=utf-8")
    }

    func testForgotPasswordHeadersContainContentType() {
        let endpoint = AuthenticationEndpoint.forgotPassword(email: "a@b.com")
        XCTAssertEqual(endpoint.headers?["content-type"], "application/json; charset=utf-8")
    }

    // MARK: - Custom URL Tests

    func testGetIDPUserCustomURLContainsApiV2Idpuser() {
        let endpoint = AuthenticationEndpoint.getIDPUser
        let customURL = endpoint.customURL
        XCTAssertNotNil(customURL)
        XCTAssertTrue(customURL!.contains("api/v2/idpuser"))
        XCTAssertFalse(customURL!.contains("api/v2/idpuser/"))
    }

    func testSend2FAEnableCodeCustomURL() {
        let endpoint = AuthenticationEndpoint.send2FAEnableCode(parameters: ("sms", "+1234567890"))
        let customURL = endpoint.customURL
        XCTAssertNotNil(customURL)
        XCTAssertTrue(customURL!.hasSuffix("api/v2/idpuser/send-enable-code"))
    }

    func testEnable2FACustomURL() {
        let endpoint = AuthenticationEndpoint.enable2FA(parameters: ("sms", "+1234567890", "123456"))
        let customURL = endpoint.customURL
        XCTAssertNotNil(customURL)
        XCTAssertTrue(customURL!.hasSuffix("api/v2/idpuser/enable-two-factor"))
    }

    func testSend2FADisableCodeCustomURL() {
        let endpoint = AuthenticationEndpoint.send2FADisableCode(parameters: ("sms", nil))
        let customURL = endpoint.customURL
        XCTAssertNotNil(customURL)
        XCTAssertTrue(customURL!.hasSuffix("api/v2/idpuser/send-disable-code"))
    }

    func testDisable2FACustomURL() {
        let endpoint = AuthenticationEndpoint.disable2FA(parameters: ("sms", "654321"))
        let customURL = endpoint.customURL
        XCTAssertNotNil(customURL)
        XCTAssertTrue(customURL!.hasSuffix("api/v2/idpuser/disable-two-factor"))
    }

    func testLoginCustomURLIsNil() {
        let endpoint = AuthenticationEndpoint.login(credentials: ("a@b.com", "pw"))
        XCTAssertNil(endpoint.customURL)
    }

    func testVerifyAuthCustomURLIsNil() {
        let endpoint = AuthenticationEndpoint.verifyAuth
        XCTAssertNil(endpoint.customURL)
    }

    func testVerifyCustomURLIsNil() {
        let endpoint = AuthenticationEndpoint.verify(credentials: ("a@b.com", "1234", .phone))
        XCTAssertNil(endpoint.customURL)
    }

    func testForgotPasswordCustomURLIsNil() {
        let endpoint = AuthenticationEndpoint.forgotPassword(email: "a@b.com")
        XCTAssertNil(endpoint.customURL)
    }

    func testLogoutCustomURLIsNil() {
        let endpoint = AuthenticationEndpoint.logout
        XCTAssertNil(endpoint.customURL)
    }

    func testCreateCredentialsCustomURLIsNil() {
        let endpoint = AuthenticationEndpoint.createCredentials(credentials: ("Name", "pw", "a@b.com", nil))
        XCTAssertNil(endpoint.customURL)
    }

    // MARK: - Body Data Tests

    func testSend2FAEnableCodeBodyDataContainsMethodAndValue() throws {
        let endpoint = AuthenticationEndpoint.send2FAEnableCode(parameters: ("sms", "+1234567890"))
        let bodyData = try XCTUnwrap(endpoint.bodyData)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: bodyData) as? [String: String])
        XCTAssertEqual(json["method"], "sms")
        XCTAssertEqual(json["value"], "+1234567890")
    }

    func testEnable2FABodyDataContainsMethodValueAndCode() throws {
        let endpoint = AuthenticationEndpoint.enable2FA(parameters: ("sms", "+1234567890", "123456"))
        let bodyData = try XCTUnwrap(endpoint.bodyData)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: bodyData) as? [String: String])
        XCTAssertEqual(json["method"], "sms")
        XCTAssertEqual(json["value"], "+1234567890")
        XCTAssertEqual(json["code"], "123456")
    }

    func testSend2FADisableCodeBodyDataContainsMethodId() throws {
        let endpoint = AuthenticationEndpoint.send2FADisableCode(parameters: ("sms-method-id", nil))
        let bodyData = try XCTUnwrap(endpoint.bodyData)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: bodyData) as? [String: String])
        XCTAssertEqual(json["methodId"], "sms-method-id")
    }

    func testDisable2FABodyDataContainsMethodIdAndCode() throws {
        let endpoint = AuthenticationEndpoint.disable2FA(parameters: ("sms-method-id", "654321"))
        let bodyData = try XCTUnwrap(endpoint.bodyData)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: bodyData) as? [String: String])
        XCTAssertEqual(json["methodId"], "sms-method-id")
        XCTAssertEqual(json["code"], "654321")
    }

    func testDisable2FABodyDataIsNilWhenCodeIsNil() {
        let endpoint = AuthenticationEndpoint.disable2FA(parameters: ("sms-method-id", nil))
        XCTAssertNil(endpoint.bodyData)
    }

    func testLoginBodyDataIsNil() {
        let endpoint = AuthenticationEndpoint.login(credentials: ("a@b.com", "pw"))
        XCTAssertNil(endpoint.bodyData)
    }

    func testVerifyAuthBodyDataIsNil() {
        let endpoint = AuthenticationEndpoint.verifyAuth
        XCTAssertNil(endpoint.bodyData)
    }

    func testLogoutBodyDataIsNil() {
        let endpoint = AuthenticationEndpoint.logout
        XCTAssertNil(endpoint.bodyData)
    }

    func testGetIDPUserBodyDataIsNil() {
        let endpoint = AuthenticationEndpoint.getIDPUser
        XCTAssertNil(endpoint.bodyData)
    }

    // MARK: - Parameters Tests

    func testLoginParametersContainEmailAndPassword() {
        let email = "user@example.com"
        let password = "securePassword"
        let endpoint = AuthenticationEndpoint.login(credentials: (email, password))

        let data = dataArray(from: endpoint.parameters)
        XCTAssertNotNil(data)
        XCTAssertEqual(data?.count, 1)

        let firstEntry = data?.first
        let accountVO = firstEntry?["AccountVO"] as? [String: String]
        XCTAssertEqual(accountVO?["primaryEmail"], email)

        let passwordVO = firstEntry?["AccountPasswordVO"] as? [String: String]
        XCTAssertEqual(passwordVO?["password"], password)
    }

    func testVerifyParametersContainEmailAndCodeAndTypePhone() {
        let email = "user@example.com"
        let code = "987654"
        let endpoint = AuthenticationEndpoint.verify(credentials: (email, code, .phone))

        let data = dataArray(from: endpoint.parameters)
        XCTAssertNotNil(data)

        let firstEntry = data?.first
        let accountVO = firstEntry?["AccountVO"] as? [String: String]
        XCTAssertEqual(accountVO?["primaryEmail"], email)

        let authVO = firstEntry?["AuthVO"] as? [String: String]
        XCTAssertEqual(authVO?["type"], CodeVerificationType.phone.rawValue)
        XCTAssertEqual(authVO?["token"], code)
    }

    func testVerifyParametersWithMFAType() {
        let email = "user@example.com"
        let code = "112233"
        let endpoint = AuthenticationEndpoint.verify(credentials: (email, code, .mfa))

        let data = dataArray(from: endpoint.parameters)
        let authVO = data?.first?["AuthVO"] as? [String: String]
        XCTAssertEqual(authVO?["type"], "type.auth.mfaValidation")
    }

    func testForgotPasswordParametersContainEmail() {
        let email = "forgot@example.com"
        let endpoint = AuthenticationEndpoint.forgotPassword(email: email)

        let data = dataArray(from: endpoint.parameters)
        XCTAssertNotNil(data)

        let accountVO = data?.first?["AccountVO"] as? [String: String]
        XCTAssertEqual(accountVO?["primaryEmail"], email)
    }

    func testCreateCredentialsParametersAreFlatDictWithPhone() {
        let name = "John Doe"
        let password = "strongPW"
        let email = "john@example.com"
        let phone = "+1555000111"
        let endpoint = AuthenticationEndpoint.createCredentials(credentials: (name, password, email, phone))

        let params = dict(endpoint.parameters)
        XCTAssertNotNil(params)
        XCTAssertEqual(params?["fullName"] as? String, name)
        XCTAssertEqual(params?["password"] as? String, password)
        XCTAssertEqual(params?["passwordVerify"] as? String, password)
        XCTAssertEqual(params?["primaryEmail"] as? String, email)
        XCTAssertEqual(params?["primaryPhone"] as? String, phone)
    }

    func testCreateCredentialsParametersWithNilPhone() {
        let endpoint = AuthenticationEndpoint.createCredentials(credentials: ("Name", "pw", "a@b.com", nil))
        let params = dict(endpoint.parameters)
        XCTAssertNotNil(params)
        XCTAssertTrue(params?["primaryPhone"] is NSNull)
    }

    func testVerifyAuthParametersContainEmptyDataDict() {
        let endpoint = AuthenticationEndpoint.verifyAuth
        let data = dataArray(from: endpoint.parameters)
        XCTAssertNotNil(data)
        XCTAssertEqual(data?.count, 1)
        XCTAssertTrue(data?.first?.isEmpty == true)
    }

    func testLogoutParametersAreNil() {
        let endpoint = AuthenticationEndpoint.logout
        XCTAssertNil(endpoint.parameters)
    }

    func testGetIDPUserParametersAreNil() {
        let endpoint = AuthenticationEndpoint.getIDPUser
        XCTAssertNil(endpoint.parameters)
    }

    func testSend2FAEnableCodeParametersAreNil() {
        let endpoint = AuthenticationEndpoint.send2FAEnableCode(parameters: ("sms", "+1234567890"))
        XCTAssertNil(endpoint.parameters)
    }

    func testEnable2FAParametersAreNil() {
        let endpoint = AuthenticationEndpoint.enable2FA(parameters: ("sms", "+1234567890", "123456"))
        XCTAssertNil(endpoint.parameters)
    }

    func testSend2FADisableCodeParametersAreNil() {
        let endpoint = AuthenticationEndpoint.send2FADisableCode(parameters: ("sms", nil))
        XCTAssertNil(endpoint.parameters)
    }

    func testDisable2FAParametersAreNil() {
        let endpoint = AuthenticationEndpoint.disable2FA(parameters: ("sms", "654321"))
        XCTAssertNil(endpoint.parameters)
    }

    // MARK: - CodeVerificationType Raw Values

    func testCodeVerificationTypePhoneRawValue() {
        XCTAssertEqual(CodeVerificationType.phone.rawValue, "type.auth.phone")
    }

    func testCodeVerificationTypeMFARawValue() {
        XCTAssertEqual(CodeVerificationType.mfa.rawValue, "type.auth.mfaValidation")
    }

    // MARK: - Login Payload Nested Structure

    func testLoginPayloadHasCorrectNestedStructure() {
        let endpoint = AuthenticationEndpoint.login(credentials: ("deep@test.com", "pw123"))
        let params = dict(endpoint.parameters)
        XCTAssertNotNil(params?["RequestVO"])

        let requestVO = params?["RequestVO"] as? [String: Any]
        XCTAssertNotNil(requestVO?["data"])

        let data = requestVO?["data"] as? [[String: Any]]
        XCTAssertEqual(data?.count, 1)
        XCTAssertNotNil(data?.first?["AccountVO"])
        XCTAssertNotNil(data?.first?["AccountPasswordVO"])
    }

    // MARK: - Verify Payload Nested Structure

    func testVerifyPayloadHasCorrectNestedStructure() {
        let endpoint = AuthenticationEndpoint.verify(credentials: ("test@test.com", "abc", .phone))
        let params = dict(endpoint.parameters)

        let requestVO = params?["RequestVO"] as? [String: Any]
        let data = requestVO?["data"] as? [[String: Any]]
        XCTAssertEqual(data?.count, 1)
        XCTAssertNotNil(data?.first?["AccountVO"])
        XCTAssertNotNil(data?.first?["AuthVO"])
    }

    // MARK: - Forgot Password Payload Nested Structure

    func testForgotPasswordPayloadHasCorrectNestedStructure() {
        let endpoint = AuthenticationEndpoint.forgotPassword(email: "forgot@test.com")
        let params = dict(endpoint.parameters)

        let requestVO = params?["RequestVO"] as? [String: Any]
        let data = requestVO?["data"] as? [[String: Any]]
        XCTAssertEqual(data?.count, 1)

        let accountVO = data?.first?["AccountVO"] as? [String: String]
        XCTAssertNotNil(accountVO)
        XCTAssertEqual(accountVO?.count, 1)
    }

    // MARK: - Custom URL Prefix Tests

    func testCustomURLsStartWithAPIServer() {
        let apiServer = APIEnvironment.defaultEnv.apiServer
        let endpointsWithCustomURLs: [AuthenticationEndpoint] = [
            .getIDPUser,
            .send2FAEnableCode(parameters: ("sms", "+1")),
            .enable2FA(parameters: ("sms", "+1", "000")),
            .send2FADisableCode(parameters: ("sms", nil)),
            .disable2FA(parameters: ("sms", "123"))
        ]

        for endpoint in endpointsWithCustomURLs {
            let customURL = endpoint.customURL
            XCTAssertNotNil(customURL, "customURL should not be nil for \(endpoint)")
            XCTAssertTrue(customURL!.hasPrefix(apiServer), "customURL should start with apiServer for \(endpoint)")
        }
    }

    // MARK: - Create Credentials Password Verify Matches Password

    func testCreateCredentialsPasswordVerifyMatchesPassword() {
        let password = "myUniquePw!"
        let endpoint = AuthenticationEndpoint.createCredentials(credentials: ("User", password, "u@e.com", nil))
        let params = dict(endpoint.parameters)
        XCTAssertEqual(params?["password"] as? String, params?["passwordVerify"] as? String)
    }

    // MARK: - Enable 2FA Body Data Key Count

    func testEnable2FABodyDataHasThreeKeys() throws {
        let endpoint = AuthenticationEndpoint.enable2FA(parameters: ("email", "test@e.com", "999999"))
        let bodyData = try XCTUnwrap(endpoint.bodyData)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: bodyData) as? [String: String])
        XCTAssertEqual(json.count, 3)
    }

    func testSend2FAEnableCodeBodyDataHasTwoKeys() throws {
        let endpoint = AuthenticationEndpoint.send2FAEnableCode(parameters: ("email", "test@e.com"))
        let bodyData = try XCTUnwrap(endpoint.bodyData)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: bodyData) as? [String: String])
        XCTAssertEqual(json.count, 2)
    }

    func testSend2FADisableCodeBodyDataHasOneKey() throws {
        let endpoint = AuthenticationEndpoint.send2FADisableCode(parameters: ("method-id-123", nil))
        let bodyData = try XCTUnwrap(endpoint.bodyData)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: bodyData) as? [String: String])
        XCTAssertEqual(json.count, 1)
    }

    func testDisable2FABodyDataWithCodeHasTwoKeys() throws {
        let endpoint = AuthenticationEndpoint.disable2FA(parameters: ("method-id-123", "111222"))
        let bodyData = try XCTUnwrap(endpoint.bodyData)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: bodyData) as? [String: String])
        XCTAssertEqual(json.count, 2)
    }
}