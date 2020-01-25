//
//  PokemonDetailUseCase.swift
//  RotomPokedex
//
//  Created by Ryo on 2020/01/04.
//  Copyright © 2020 Ryoga. All rights reserved.
//

import Foundation
import UIKit
import RxSwift

public protocol PokemonDetailUseCaseProtocol {

    /// ポケモンの画像を取得する
    /// - Parameters:
    ///   - byPokedexNumber: 図鑑番号
    /// - Returns: 図鑑番号に対応したポケモンの画像
    func findPokemonImages(byPokedexNumber pokedex: Int) -> Observable<[UIImage]>

    /// ポケモンの画像を取得する
    /// - Parameter byPokedexNumber: 図鑑番号
    /// - Returns: 図鑑番号に対応したポケモンの画像
    func findPokemonSprite(byPokedexNumber pokedex: Int) -> Observable<UIImage?>
}

public class PokemonDetailUseCase : PokemonDetailUseCaseProtocol {

    private let repository: PokemonRepositoryProtocol

    public init<R : PokemonRepositoryProtocol>(repository: R) {
        self.repository = repository
    }

    public func findPokemonImages(byPokedexNumber pokedex: Int) -> Observable<[UIImage]> {
        // 主となる画像
        let primaryImage = repository.findPrimaryPokemonGif(byPokedexNumber: pokedex)
        // その他の画像
        let otherImages = repository.findOtherPokemonGifs(byPokedexNumber: pokedex)
        
        // 両方並列で取得する
        return Observable.zip(primaryImage, otherImages) { (primary, others) in
            // 主となる画像が取れなかったら空の配列を流す
            guard let primary = primary else { return [] }

            return [primary] + others
        }
    }

    public func findPokemonSprite(byPokedexNumber pokedex: Int) -> Observable<UIImage?> {
        return repository.findPokemonSprite(byPokedexNumber: pokedex)
    }
}
