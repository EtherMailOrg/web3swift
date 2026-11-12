import Foundation
import XCTest
@testable import Web3Core

final class HTTPCompatibilityTests: XCTestCase {
    func testSuccessfulResponsePreservesPayload() async throws {
        let session = makeSession()
        defer { session.invalidateAndCancel() }
        let payload = try await APIRequest.send(uRLRequest: request(status: 200), with: session)
        XCTAssertEqual(payload, HTTPResponseStub.payload)
    }

    func testClientErrorPreservesStatusCode() async throws {
        let session = makeSession()
        defer { session.invalidateAndCancel() }
        do {
            _ = try await APIRequest.send(uRLRequest: request(status: 401), with: session)
            XCTFail("Expected a client error")
        } catch Web3Error.clientError(let code) {
            XCTAssertEqual(code, 401)
        }
    }

    func testServerErrorPreservesStatusCode() async throws {
        let session = makeSession()
        defer { session.invalidateAndCancel() }
        do {
            _ = try await APIRequest.send(uRLRequest: request(status: 503), with: session)
            XCTFail("Expected a server error")
        } catch Web3Error.serverError(let code) {
            XCTAssertEqual(code, 503)
        }
    }

    func testNonHTTPResponseIsRejected() async throws {
        let session = makeSession()
        defer { session.invalidateAndCancel() }
        var request = try request(status: 200)
        request.setValue("true", forHTTPHeaderField: "X-Test-NonHTTP")
        do {
            _ = try await APIRequest.send(uRLRequest: request, with: session)
            XCTFail("Expected an invalid response error")
        } catch let error as URLError {
            XCTAssertEqual(error.code, .badServerResponse)
        }
    }

    func testTransportErrorIsPreserved() async throws {
        let session = makeSession()
        defer { session.invalidateAndCancel() }
        var request = try request(status: 200)
        request.setValue("true", forHTTPHeaderField: "X-Test-TransportError")
        do {
            _ = try await APIRequest.send(uRLRequest: request, with: session)
            XCTFail("Expected a transport error")
        } catch let error as URLError {
            XCTAssertEqual(error.code, .notConnectedToInternet)
        }
    }

    private func makeSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [HTTPResponseStub.self]
        return URLSession(configuration: config)
    }

    private func request(status: Int) throws -> URLRequest {
        let url = try XCTUnwrap(URL(string: "https://rpc.invalid"))
        var request = URLRequest(url: url)
        request.setValue(String(status), forHTTPHeaderField: "X-Test-Status")
        return request
    }
}

private final class HTTPResponseStub: URLProtocol, @unchecked Sendable {
    static let payload = Data(#"{"jsonrpc":"2.0","id":1,"result":"0x1"}"#.utf8)

    override class func canInit(with request: URLRequest) -> Bool { true }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        if request.value(forHTTPHeaderField: "X-Test-TransportError") != nil {
            client?.urlProtocol(self, didFailWithError: URLError(.notConnectedToInternet))
            return
        }
        guard let response = makeResponse() else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Self.payload)
        client?.urlProtocolDidFinishLoading(self)
    }

    private func makeResponse() -> URLResponse? {
        guard let url = request.url else { return nil }
        if request.value(forHTTPHeaderField: "X-Test-NonHTTP") != nil {
            return URLResponse(url: url, mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
        }
        let status = Int(request.value(forHTTPHeaderField: "X-Test-Status") ?? "200") ?? 200
        return HTTPURLResponse(url: url, statusCode: status, httpVersion: "HTTP/1.1", headerFields: nil)
    }

    override func stopLoading() {}
}
