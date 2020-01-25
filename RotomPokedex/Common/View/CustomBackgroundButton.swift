//
//  CustomBackgroundButton.swift
//  RotomPokedex
//
//  Created by Ryo on 2020/01/13.
//  Copyright © 2020 Ryoga. All rights reserved.
//

import Foundation
import UIKit

public class CustomBackgroundButton : UIButton {

    override public var isHighlighted: Bool {
        didSet {
            if self.isHighlighted {
                if let currentPoint = titleLabel?.font.pointSize {
                    titleLabel?.font = .boldSystemFont(ofSize: currentPoint)
                }
                backgroundView.backgroundColor = highlightedBackgroundColor
            } else {
                UIView.animate(withDuration: 0.16, animations: { [unowned self] in
                    if let currentPoint = self.titleLabel?.font.pointSize {
                        self.titleLabel?.font = .systemFont(ofSize: currentPoint)
                    }
                    self.backgroundView.backgroundColor = self.isEnabled ? self.normalBackgroundColor : self.disabledBackgroundColor
                })
            }
        }
    }

    override public var isEnabled: Bool {
        didSet {
            setTitleColor(self.isEnabled ? normalTitleColor : disabledTitleColor, for: .normal)
            backgroundView.backgroundColor = self.isEnabled ? normalBackgroundColor : disabledBackgroundColor
        }
    }

    // MARK: - Title Colors -

    public var normalTitleColor: UIColor = .black {
        didSet {
            setTitleColor(self.normalTitleColor, for: .normal)
        }
    }
    public var highlightedTitleColor: UIColor = .white {
        didSet {
            setTitleColor(self.highlightedTitleColor, for: .highlighted)
        }
    }
    public var disabledTitleColor: UIColor = .gray {
        didSet {
            setTitleColor(self.disabledTitleColor, for: .disabled)
        }
    }

    // MARK: - Background Colors -

    public var normalBackgroundColor: UIColor = .clear {
        didSet {
            backgroundView.backgroundColor = self.normalBackgroundColor
        }
    }
    public var highlightedBackgroundColor: UIColor = .black
    public var disabledBackgroundColor: UIColor = .clear

    private var backgroundView: UIView!

    public init() {
        super.init(frame: .zero)
        setupUI()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        let backgroundView = UIView()
        backgroundView.layer.masksToBounds = true
        self.backgroundView = backgroundView

        setTitleColor(normalTitleColor, for: .normal)
        setTitleColor(highlightedTitleColor, for: .highlighted)
        setTitleColor(disabledTitleColor, for: .disabled)
        backgroundView.backgroundColor = normalBackgroundColor
    }



    // MARK: - Lifecycle Methods -

    override public func didMoveToSuperview() {
        guard let superview = self.superview else { return }
        superview.insertSubview(backgroundView, at: 0)
        backgroundView.fit(toView: self)
    }

    override public func removeFromSuperview() {
        backgroundView.snp.removeConstraints()
        backgroundView.removeFromSuperview()
        super.removeFromSuperview()
    }

    override public func layoutSubviews() {
        let currentHeight = self.bounds.height
        let cornerRadius: CGFloat = currentHeight / 2
        backgroundView.layer.cornerRadius = cornerRadius
        super.layoutSubviews()
    }
}
