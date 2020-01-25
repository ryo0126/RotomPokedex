//
//  CacheManager.swift
//  RotomPokedex
//
//  Created by Ryo on 2020/01/12.
//  Copyright © 2020 Ryoga. All rights reserved.
//

import Foundation

/// キャッシュマネージャ
public protocol CacheManager {

    /// 取り扱うデータ型
    associatedtype DataType

    /// キャッシュディレクトリへのURL
    static var urlForCachesDirectory: URL { get }

    /// キャッシュディレクトリ以下の対象ディレクトリへのURL
    var urlForDestinationDirectory: URL { get }



    /// データをキャッシュディレクトリに保存する
    /// - Parameters:
    ///   - data: 保存するデータ
    ///   - asName: 保存名
    func save(data: DataType, asName name: String)

    /// 保存したデータキャッシュを取り出す
    /// - Parameter ofDataNamed: 取り出したいデータキャッシュの保存名
    /// - Returns: キャッシュデータ。取得できなかった場合は`nil`
    func findCache(ofDataNamed name: String) -> DataType?
}

/// デフォルトの実装
extension CacheManager {

    /// キャッシュディレクトリへのURL
    public static var urlForCachesDirectory: URL {
        return FileManager.default
        .urls(
            for: .cachesDirectory,
            in: .userDomainMask
        )[0]
    }
}

extension CacheManager where Self.DataType == Data {

    public func save(data: Data, asName name: String) {
        let url = urlForDestinationDirectory
        try! data.write(to: url.appendingPathComponent(name))
    }

    public func findCache(ofDataNamed name: String) -> Data? {
        let path = urlForDestinationDirectory.appendingPathComponent(name).path
        let data = FileManager.default.contents(atPath: path)
        return data
    }
}

/// ポケモンのスプライト画像のキャッシュデータを管理する
public class PokemonSpriteCaches : CacheManager {

    /// 唯一のインスタンス
    public static let shared = PokemonSpriteCaches(destinationDirectory: "Pokemon Sprites")

    /// キャッシュディレクトリ以下の対象ディレクトリへのURL
    public let urlForDestinationDirectory: URL

    private init(destinationDirectory: String) {
        /// 対象ディレクトリへのURL
        let url = PokemonSpriteCaches.urlForCachesDirectory.appendingPathComponent(destinationDirectory)
        self.urlForDestinationDirectory = url
        // キャッシュディレクトリがなければ作る
        let path = url.path
        if !FileManager.default.fileExists(atPath: path) {
            try! FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
        }
    }
}



/// ポケモンの主なGIF画像のキャッシュデータを管理する
public class PrimaryPokemonGifCaches : CacheManager {

    /// 唯一のインスタンス
    public static let shared = PrimaryPokemonGifCaches(destinationDirectory: "Primary Pokemon GIFs")

    /// キャッシュディレクトリ以下の対象ディレクトリへのURL
    public let urlForDestinationDirectory: URL

    private init(destinationDirectory: String) {
        /// 対象ディレクトリへのURL
        let url = PrimaryPokemonGifCaches.urlForCachesDirectory.appendingPathComponent(destinationDirectory)
        self.urlForDestinationDirectory = url
        // キャッシュディレクトリがなければ作る
        let path = url.path
        if !FileManager.default.fileExists(atPath: path) {
            try! FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
        }
    }
}

/// ポケモンのその他のGIF画像のキャッシュデータを管理する
public class OtherPokemonGifCaches : CacheManager {

    /// 唯一のインスタンス
    public static let shared = OtherPokemonGifCaches(destinationDirectory: "Other Pokemon GIFs")

    /// キャッシュディレクトリ以下の対象ディレクトリへのURL
    public let urlForDestinationDirectory: URL

    private init(destinationDirectory: String) {
        /// 対象ディレクトリへのURL
        let url = PrimaryPokemonGifCaches.urlForCachesDirectory.appendingPathComponent(destinationDirectory)
        self.urlForDestinationDirectory = url
        // キャッシュディレクトリがなければ作る
        let path = url.path
        if !FileManager.default.fileExists(atPath: path) {
            try! FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
        }
    }



    /// データをキャッシュディレクトリに保存する
    /// - Parameters:
    ///   - data: 保存するデータ
    ///   - asName: 保存名
    public func save(data: [Data], asName name: String) {
        // Other Pokemon GIFs/nameのディレクトリが対象
        let url = urlForDestinationDirectory.appendingPathComponent(name)
        let path = url.path
        // ディレクトリがなければ作る
        if !FileManager.default.fileExists(atPath: path) {
            try! FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
        }

        // 各画像をname以下に番号名で保存する
        for (index, gifData) in data.enumerated() {
            try! gifData.write(to: url.appendingPathComponent(String(index)))
        }
    }

    /// 保存したデータキャッシュを取り出す
    /// - Parameter ofDataNamed: 取り出したいデータキャッシュの保存名
    /// - Returns: キャッシュデータ。取得できなかった場合は`nil`
    public func findCache(ofDataNamed name: String) -> [Data]? {
        let url = urlForDestinationDirectory.appendingPathComponent(name)
        let path = url.path
        do {
            let fileNames = try FileManager.default.contentsOfDirectory(atPath: path)
            let data: [Data] = fileNames
                .map { fileName -> Data? in
                    let filePath = url.appendingPathComponent(fileName).path
                    return FileManager.default.contents(atPath: filePath)
                }
                // nilは除外
                .compactMap { $0 }
            return data
        } catch CocoaError.fileReadNoSuchFile {
            return nil
        } catch {
            fatalError("Could not read contents of directory \"\(path).\"")
        }
    }
}
