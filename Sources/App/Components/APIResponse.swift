//
//  APIResponse.swift
//  App
//
//  Created by wigothehacker on 1/11/26.
//

import Vapor

struct APIResponse<T: Content>: Content {
    let success: Bool
    let data: T?
    let message: String
}
