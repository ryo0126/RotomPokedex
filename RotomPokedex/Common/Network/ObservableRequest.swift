//
//  ObservableRequest.swift
//  RotomPokedex
//
//  Created by Ryo on 2020/01/11.
//  Copyright © 2020 Ryoga. All rights reserved.
//

import Foundation
import RxSwift

/// `Observable`なネットワーク処理を提供する
public class ObservableRequest {

    /// `Observable`なネットワーク処理を発効する
    /// - Parameter url: リクエスト先のURL
    public static func create(url: String) -> Observable<Data?> {
        return Observable.create { observer in
            guard let url = URL(string: url) else {
                // URLが取れなかった場合はnilを流して終了する
                observer.onNext(nil)
                observer.onCompleted()
                return Disposables.create()
            }

            let urlRequest = URLRequest(url: url)
            let session = URLSession(configuration: .ephemeral)
            // 通信タスク
            let task = session.dataTask(with: urlRequest, completionHandler: { (data, response, error) in
                // エラーがあったらエラーを流して終了
                if let error = error {
                    let error = error as NSError

                    // ユーザーキャンセルエラーの場合はエラーとみなさずnilを流して終了
                    if error.code == NSURLErrorCancelled {
                        observer.onNext(nil)
                        observer.onCompleted()
                        return
                    }

                    observer.onError(error)
                    observer.onCompleted()
                    return
                }
                // レスポンスがエラーでないか調べる
                if let response = response as? HTTPURLResponse {
                    switch response.statusCode {
                    // 404
                    case ErrorStatusCode.notFound.rawValue:
                        observer.onError(ErrorStatusCode.notFound)
                        observer.onCompleted()
                        return
                    // それ以外はエラーとみなさない
                    default:
                        break
                    }
                }
                // エラーがないならデータを流して終了(nilを含む)
                observer.onNext(data)
                observer.onCompleted()
            })
            // 通信を開始
            task.resume()
            return Disposables.create {
                // 購読解除されたらタスクキャンセルする
                task.cancel()
            }
        }
    }
}
