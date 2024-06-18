//
//  SnapshotType.swift
//  SnapshotTestUtils
//
//  Created by Samarenko Andrey on 18.06.2024.
//

import Foundation

enum SnapshotType {
    /// Типы изобаржений при прохождении теста / записи снепшотов
    case reference          // записанное изображение
    
    /// Типы изображений при падении теста
    case failedReference    // изображение, с которым производится сравнение в тесте
    case failedTest         // изображение, полученное в результате теста
    case failedDiff         // разница между изображениями
}
