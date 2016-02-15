//
//  CGPoint+Utils.swift
//  WrinklesKiller
//
//  Created by Alex on 2/4/16.
//  Copyright © 2016 Alex. All rights reserved.
//

import Foundation
import UIKit

extension CGPoint {
    func distanceToPoint(point: CGPoint) -> CGFloat {
        let deltaX = point.x - self.x
        let deltaY = point.y - self.y
        return sqrt(deltaX * deltaX + deltaY * deltaY)
    }
    
    func pointBetweenPoint(point: CGPoint) -> CGPoint {
        return CGPointMake((self.x + point.x) / 2, (self.y + point.y) / 2)
    }
}