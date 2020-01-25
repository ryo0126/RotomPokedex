//
//  Urls.swift
//  RotomPokedex
//
//  Created by Ryo on 2020/01/13.
//  Copyright © 2020 Ryoga. All rights reserved.
//

import Foundation

/// URLを表現する文字列を持つことを保証する
public protocol UrlString {

    /// URLを表す文字列
    var urlString: String { get }
}

/// ポケモンの画像のURL
public enum PokemonImageUrl : UrlString {

    /// スプライト画像
    /// - Parameter pokedexNumber: ポケモン図鑑番号
    case sprite(pokedexNumber: Int)

    /// URLの文字列を返す
    public var urlString: String {
        switch self {
        case .sprite(let number):
            return "https://raw.githubusercontent.com/fanzeyi/pokemon.json/master/sprites/\(String(format: "%03d", number))MS.png"
        }
    }
}

/// ポケモンのGIF画像のURL
public enum PokemonGifUrl : UrlString {

    /// 主となる画像
    /// - Parameter pokemonName: 対象のポケモンの名前
    case primary(pokemonName: String)
    /// 他の画像
    /// - Parameters:
    ///   - pokemonName: 対象のポケモンの名前
    ///   - suffixNumber: 末尾の序数。2始まり。対象のポケモンによっては一枚もなかったりする。
    case other(pokemonName: String, suffixNumber: Int)

    /// URLの文字列を返す
    public var urlString: String {
        switch self {
        case .primary(let name):
            return "http://www.pokestadium.com/sprites/xy/\(name).gif"
        case .other(let name, let suffix):
            return "http://www.pokestadium.com/sprites/xy/\(name)-\(String(suffix)).gif"
        }
    }
}
