//
//  OrderSelectorViewController.swift
//  RotomPokedex
//
//  Created by Ryo on 2020/01/13.
//  Copyright © 2020 Ryoga. All rights reserved.
//

import UIKit

/// 並び順
public enum PokemonOrder : String {

    /// 番号昇順
    case pokedexNumber = "番号順"
    /// 五十音昇順
    case syllabary = "五十音順"
    /// 種族値の合計が高い順
    case totalBaseStats = "合計種族値が高い順"

    /// ソート規則
    public var rule: (Pokemon, Pokemon) -> Bool {
        switch self {
        case .pokedexNumber:
            return { (pokemon1, pokemon2) in pokemon1.number < pokemon2.number }
        case .syllabary:
            return { (pokemon1, pokemon2) in pokemon1.name < pokemon2.name }
        case .totalBaseStats:
            return { (pokemon1, pokemon2) in pokemon1.baseStats.total > pokemon2.baseStats.total }
        }
    }
}

protocol OrderSelectorViewControllerDelegate : AnyObject {

    /// 並び替えボタンが押されたとき
    /// - Parameters:
    ///   - orderSelectorViewController: 対象のインスタンス
    ///   - didTouchedButtonOf: 押されたボタンのタイプ
    func orderSelectorViewController(_ orderSelectorViewController: OrderSelectorViewController, didTouchedButtonOf order: PokemonOrder)
}

/// 並び替えをボタンを表示する`ViewController`
class OrderSelectorViewController : BaseViewController {

    var delegate: OrderSelectorViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {

    }

    /// 番号順ボタンが押された
    @IBAction func onOrderByPokedexNumberButtonTapped(_ sender: UIButton) {
        delegate?.orderSelectorViewController(self, didTouchedButtonOf: .pokedexNumber)
    }

    /// 五十音順ボタンが押された
    @IBAction func onOrderBySyllabaryButtonTapped(_ sender: UIButton) {
        delegate?.orderSelectorViewController(self, didTouchedButtonOf: .syllabary)
    }

    /// 合計種族値が高い順ボタンが押された
    @IBAction func onOrderByTotalBaseStatsButtonTapped(_ sender: UIButton) {
        delegate?.orderSelectorViewController(self, didTouchedButtonOf: .totalBaseStats)
    }
}
