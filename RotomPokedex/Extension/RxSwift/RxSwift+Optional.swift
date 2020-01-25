//
//  RxSwift+Optional.swift
//  RotomPokédex
//
//  Created by Ryo on 2019/12/29.
//  Copyright © 2019 Ryoga. All rights reserved.
//

import Foundation
import RxSwift

extension Observable where Element : OptionalType {

    /// `nil`をふるい落とす
    /// - Returns: `nil`がふるい落とされる`Observable`
    func takeNonNil() -> Observable<Element> {
        return self.filter { $0.asOptional != nil }
    }

    /// オプショナルをアンラップする。`nil`は流れない
    /// - Returns: アンラップされた値を含む`Observable`
    func unwrap() -> Observable<Element.Wrapped> {
        return self.filter { $0.asOptional != nil }.map { $0.asOptional! }
    }
}
