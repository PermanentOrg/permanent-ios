//
//  ResponseURLProtocol.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 22.07.2021.
//

import Foundation

class ResponseURLProtocol<T>: URLProtocol where T: TestURLs {
  // say we want to handle all types of request
  override class func canInit(with request: URLRequest) -> Bool {
    return true
  }
  // ignore this method; just send back what we were given
  override class func canonicalRequest(for request: URLRequest) -> URLRequest {
    return request
  }
  override func startLoading() {
    // if we have a valid URL…
    if let url = request.url {
      // …and if we have test data for that URL…
      let testURLs = T()
      if let data = testURLs.urls[url] {
        // …load it immediately.
        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
        self.client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .allowed)
        self.client?.urlProtocol(self, didLoad: data)
      }
    }
    // mark that we’ve finished
    self.client?.urlProtocolDidFinishLoading(self)
  }
  // this method is required but doesn’t need to do anything
  override func stopLoading() { }
}
