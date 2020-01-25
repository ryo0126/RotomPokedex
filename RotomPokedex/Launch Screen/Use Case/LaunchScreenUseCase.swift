//
//  LaunchScreenUseCase.swift
//  RotomPokédex
//
//  Created by Ryo on 2019/12/29.
//  Copyright © 2019 Ryoga. All rights reserved.
//

import Foundation
import RxSwift

public protocol LaunchScreenUseCaseProtocol {

    /// ポケモンのデータのキャッシュを作成する
    /// - Returns: 完了を通知する`Observable`
    func fetchAllPokemonData() -> Observable<Void>
}

final public class LaunchScreenUseCase : LaunchScreenUseCaseProtocol {

    private let repository: PokemonRepositoryProtocol

    public init<R : PokemonRepositoryProtocol>(repository: R) {
        self.repository = repository
    }

    public func fetchAllPokemonData() -> Observable<Void> {
        return repository.fetchAllPokemonData()
    }
}
