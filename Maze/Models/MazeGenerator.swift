//
//  MazeGenerator.swift
//  Maze
//
//  Created by Roy Geagea on 7/14/20.
//  Copyright © 2020 Roy Geagea. All rights reserved.
//

import Foundation

enum NodeType {
    case space, wall
}

class Node: Hashable {
    
    var cellType: NodeType
    var x, y: Int
    
    init(cellType: NodeType, x: Int, y: Int) {
        self.cellType = cellType
        self.x = x
        self.y = y
    }
    
    func hash(into hasher: inout Hasher) {
        return hasher.combine("\(x)\(y)")
    }
    
    static func == (lhs: Node, rhs: Node) -> Bool {
        return lhs.x == rhs.x && lhs.y == rhs.y
    }
}

class MazeGenerator {

    var mazeWidth: Int
    var mazeHeight: Int

    var data: [[Node]] = []
    var visitedMap: [[Bool]] = []
    var mazeStack = Stack<[Int]>()
    
    // Generate a random maze.
    init(width: Int = 15, height: Int = 15) {
        mazeWidth = width
        mazeHeight = height

        for _ in 0..<height {
            visitedMap.append([Bool](repeating: false, count: width))
        }

        // create blank map
        for y in 0..<height {
            var subArray = [Node]()
            for x in 0..<width {
                subArray.append(Node(cellType: .wall, x: x, y: y))
            }
            data.append(subArray)
        }

        // mark all outer walls visited
        for index in 0..<width {
            visitedMap[0][index] = true
            visitedMap[height - 1][index] = true
        }
        for index in 0..<height {
            visitedMap[index][0] = true
            visitedMap[index][width - 1] = true
        }

        // start carving position
        let startX = 1
        let startY = 1

        // change the starting position to a space
        data[startX][startY].cellType = NodeType.space
        // push the starting
        mazeStack.push([startX, startY])
        markVisited(x: startX, y: startY)
        carve(x: startX, y: startY)
        for i in height-4...height-1 { // for the bone
            for j in 0...3 {
                data[i][j].cellType = NodeType.space
            }
        }
        
        for i in 0...3 { // for the dog
            for j in width-4...width-1 { // for the bone
                data[i][j].cellType = NodeType.space
            }
        }
    }

    func markVisited(x: Int, y: Int) {
        // mark center
        visitedMap[x][y] = true
        // mark top
        if x > 1 {
            visitedMap[x - 1][y] = true
        }
        // mark top left
        if x > 1 && y > 1 {
            visitedMap[x - 1][y - 1] = true
        }
        // mark top right
        if x > 1 && y < mazeWidth - 2 {
            visitedMap[x - 1][y + 1] = true
        }
        // mark left
        if y > 1 {
            visitedMap[x][y - 1] = true
        }
        // mark right
        if y < mazeWidth - 1 {
            visitedMap[x][y + 1] = true
        }
        // mark bottom
        if x < mazeHeight - 2 {
            visitedMap[x + 1][y] = true
        }
        // mark bottom left
        if x < mazeHeight - 2 && y > 1 {
            visitedMap[x + 1][y - 1] = true
        }
        // mark bottom right
        if x < mazeHeight - 2 && y < mazeWidth - 2 {
            visitedMap[x + 1][y + 1] = true
        }
    }

    // check if the maze is fully iterated
    func checkVisited() -> Bool {
        for index1 in 0..<visitedMap.count {
            for index2 in 0..<visitedMap[index1].count {
                if visitedMap[index1][index2] == false {
                    return false
                }
            }
        }
        return true
    }

    func carve(x: Int, y: Int) {
        while checkVisited() != true {
            /* Create list of neighbours */
            var neighbors: [Int] = []
            // south neighbor
            if mazeStack.peek()!.first! < mazeHeight - 3 && visitedMap[mazeStack.peek()!.first! + 2][mazeStack.peek()![1]] == false {
                neighbors.append(0)
            }
            // east neighbor
            if mazeStack.peek()!.last! < mazeWidth - 3 && visitedMap[mazeStack.peek()!.first!][mazeStack.peek()![1] + 2] == false {
                neighbors.append(1)
            }
            // north neighbor
            if mazeStack.peek()!.first! > 2 && visitedMap[mazeStack.peek()!.first! - 2][mazeStack.peek()![1]] == false {
                neighbors.append(2)
            }
            // west neighbor
            if mazeStack.peek()!.last! > 2 && visitedMap[mazeStack.peek()!.first!][mazeStack.peek()![1] - 2] == false {
                neighbors.append(3)
            }

            if neighbors.isEmpty == false {
                let next_Direction = neighbors[Int.random(in: 0..<neighbors.count)]
                let current_Coordinates: [Int] = mazeStack.peek()!

                // 0: South
                // 1: East
                // 2: North
                // 3: West
                var firstTile: Node!
                var secondTile: Node!
                switch next_Direction {
                case 0:
                    // push neighbor cell into stack
                    mazeStack.push([current_Coordinates[0] + 2, current_Coordinates[1]])
                    // mark the cell and all surrounding cell visited
                    markVisited(x: current_Coordinates[0] + 2, y: current_Coordinates[1])
                    // change wall into space for both the cell and the path
                    firstTile = data[current_Coordinates[0] + 1][current_Coordinates[1]]
                    secondTile = data[current_Coordinates[0] + 2][current_Coordinates[1]]
                case 1:
                    mazeStack.push([current_Coordinates[0], current_Coordinates[1] + 2])
                    markVisited(x: current_Coordinates[0], y: current_Coordinates[1] + 2)
                    firstTile = data[current_Coordinates[0]][current_Coordinates[1] + 1]
                    secondTile = data[current_Coordinates[0]][current_Coordinates[1] + 2]
                case 2:
                    mazeStack.push([current_Coordinates[0] - 2, current_Coordinates[1]])
                    markVisited(x: current_Coordinates[0] - 2, y: current_Coordinates[1])
                    firstTile = data[current_Coordinates[0] - 1][current_Coordinates[1]]
                    secondTile = data[current_Coordinates[0] - 2][current_Coordinates[1]]
                case 3:
                    mazeStack.push([current_Coordinates[0], current_Coordinates[1] - 2])
                    markVisited(x: current_Coordinates[0], y: current_Coordinates[1] - 2)
                    firstTile = data[current_Coordinates[0]][current_Coordinates[1] - 1]
                    secondTile = data[current_Coordinates[0]][current_Coordinates[1] - 2]
                default:
                    print("")
                }

                firstTile.cellType = NodeType.space
                secondTile.cellType = NodeType.space

            }
            else {
                mazeStack.pop()
            }
        }
    }
    
    func outputMaze() {
        for y in 0..<data.count {
            var line = ""
            for x in 0..<data[y].count {
                if data[y][x].cellType == .space {
                    line.append("  ")
                }else if data[y][x].cellType == .wall {
                    line.append("[]")
                }
            }
            print(line)
        }
    }

}
