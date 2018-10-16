//
//  middleware.swift
//  App
//
//  Created by Hiep Vu on 10/11/18.
//

import Vapor


public final class MethodInterceptor: Middleware {

    public func respond(to request: Request, chainingTo next: Responder) throws -> EventLoopFuture<Response> {
        if request.http.method == HTTPMethod.POST {
            let description = request.http.body.description as NSString
            if(description.hasPrefix("data_method")) {
                if let query = description.components(separatedBy: "&").first(where: { $0.contains("data_method") }) {
                    let method = query.components(separatedBy: "=")[1]
                    switch method {
                    case "patch":
                        request.http.method = HTTPMethod.PATCH
                    case "delete":
                        request.http.method = HTTPMethod.DELETE
                    default:
                        print(request.http.method)
                    }
                }
            }
        }
        print(request)
        return try next.respond(to: request)
    }
}
