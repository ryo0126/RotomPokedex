//
//  TriangleView.swift
//  RotomPokedex
//
//  Created by Ryo on 2019/12/31.
//  Copyright © 2019 Ryoga. All rights reserved.
//

import UIKit

/// 左側の三角形の角度が指定可能な台形
public class Trapezium : UIView {

    /// 左側の三角形の角度
    public var angle: Double = 65
    /// 塗り潰す色
    public var fillColor: UIColor = .black

    override public init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .clear
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func draw(_ rect: CGRect) {
        // 直角が右側の直角三角形を作る
        let triangle = UIBezierPath()
        let radian = Double.pi * (angle / 180)
        let radius = rect.height
        let offset = radius * CGFloat(cos(radian))
        let triangleMaxX = rect.minX + offset
        // 左下の頂点
        triangle.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        // 右上の頂点へ線を引く
        triangle.addLine(to:CGPoint(x: triangleMaxX, y: rect.minY))
        // 右下の頂点へ線を引く
        triangle.addLine(to:CGPoint(x: triangleMaxX, y: rect.maxY))
        // 左下の頂点へ線を引く
        triangle.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        triangle.close()
        // 指定した色で塗り潰す
        fillColor.setFill()
        triangle.fill()

        // 右側の四角形を作る
        // ちょうど三角形にくっつけると切れ目が見えてしまうので少しずらす
        let rectangleOffset: CGFloat = 0.2
        let rectangleX = triangleMaxX - rectangleOffset
        let rectangleWidth = rect.width - triangleMaxX + rectangleOffset
        let rectangle = UIBezierPath(rect: CGRect(x: rectangleX, y: rect.minY, width: rectangleWidth, height: rect.height))
        // 内側の色
        fillColor.setFill()
        // 内側を塗りつぶす
        rectangle.fill()
    }
}
