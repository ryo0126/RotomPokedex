//
//  Optional.swift
//  RotomPokédex
//
//  Created by Ryo on 2019/12/29.
//  Copyright © 2019 Ryoga. All rights reserved.
//

import Foundation

/// オプショナル方であることを示す
protocol OptionalType {
    associatedtype Wrapped
    var asOptional:  Wrapped? { get }
}

/// RxSwiftにアンラップ用のメソッドを生やすためのワークアラウンド
extension Optional: OptionalType {
    var asOptional: Wrapped? { return self }
}
