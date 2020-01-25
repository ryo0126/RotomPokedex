//
//  RxSwift.swift
//  RotomPokedex
//
//  Created by Ryo on 2020/01/12.
//  Copyright © 2020 Ryoga. All rights reserved.
//

import Foundation
import RxSwift

extension Observable {

    /// 空の`Observable`にフラットマップする
    public func mapToVoid() -> Observable<Void> {
        return map { _ -> Void in () }
    }
}
