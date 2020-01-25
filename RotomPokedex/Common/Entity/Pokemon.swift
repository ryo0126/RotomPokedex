//
//  Pokemon.swift
//  RotomPokédex
//
//  Created by Ryo on 2019/12/29.
//  Copyright © 2019 Ryoga. All rights reserved.
//

import Foundation

public enum PokemonType : String {

    case normal = "ノーマル"
    case fighting = "かくとう"
    case flying = "ひこう"
    case poison = "どく"
    case ground = "じめん"
    case rock = "いわ"
    case bug = "むし"
    case ghost = "ゴースト"
    case steel = "はがね"
    case fire = "ほのお"
    case water = "みず"
    case grass = "くさ"
    case electric = "でんき"
    case psychic = "エスパー"
    case ice = "こおり"
    case dragon = "ドラゴン"
    case dark = "あく"
    case fairy = "フェアリー"
}

public struct BaseStats : Codable {

    public let hp: Int
    public let attack: Int
    public let defence: Int
    public let spAttack: Int
    public let spDefence: Int
    public let speed: Int

    /// 種族値合計
    public var total: Int {
        return hp + attack + defence + spAttack + spDefence + speed
    }
}

public struct Pokemon {

    public typealias Types = (first: PokemonType, second: PokemonType?)

    public let number: Int
    public let name: String
    public let types: Types
    public let abilities: [String]
    public let hiddenAbilities: [String]
    public let baseStats: BaseStats
}

extension Pokemon : Equatable {
    public static func == (lhs: Pokemon, rhs: Pokemon) -> Bool {
        return lhs.number == rhs.number
    }
}
