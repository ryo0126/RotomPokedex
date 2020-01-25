//
//  ErrorStatusCode.swift
//  RotomPokedex
//
//  Created by Ryo on 2020/01/13.
//  Copyright © 2020 Ryoga. All rights reserved.
//

import Foundation

/// 400番台のHTTPステータスエラーを示す
public enum ErrorStatusCode : Int, Error {

    case unauthorized = 401
    case forbidden = 403
    case notFound = 404
}
