//
//  MazeGenerator.swift
//  Maze
//
//  Created by Roy Geagea on 7/14/20.
//  Copyright © 2020 Roy Geagea. All rights reserved.
//

import Foundation

struct Stack<Element> {
    
    var isEmpty: Bool {
        return array.isEmpty
    }

    var count: Int {
        return array.count
    }

    fileprivate var array: [Element] = []

    mutating func push(_ element: Element) {
        array.append(element)
    }

    @discardableResult mutating func pop() -> Element? {
        return array.popLast()
    }

    func peek() -> Element? {
        return array.last
    }
}
