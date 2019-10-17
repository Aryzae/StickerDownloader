//
//  main.swift
//  StickerDownloader
//
//  Created by aryzae on 2018/07/15.
//  Copyright © 2018 aryzae. All rights reserved.
//

import Foundation
import Cocoa
//
public extension NSImage {
    func writePNG(fileName: String) {
        let savePath = URL(fileURLWithPath: FileManager.default.currentDirectoryPath + "/\(fileName).png")
        print(savePath)
        
        guard let data = tiffRepresentation,
            let rep = NSBitmapImageRep(data: data),
            let imgData = rep.representation(using: .png, properties: [.compressionFactor : NSNumber(floatLiteral: 1.0)]) else {
                
                print("\(self.self) Error Function '\(#function)' Line: \(#line) No tiff rep found for image writing to \(savePath)")
                exit(0)
        }
        
        do {
            // file protocol必須 file:///
            try imgData.write(to: savePath, options: .atomicWrite)
        } catch let error {
            print("\(self.self) Error Function '\(#function)' Line: \(#line) \(error.localizedDescription)")
            exit(0)
        }
    }
}

/// 正規表現でキャプチャした文字列を抽出する
///
/// - Parameters:
///   - pattern: 正規表現
///   - group: 抽出するグループ番号(>=1)の配列
/// - Returns: 抽出した文字列の配列
func captureImageURLs(from html: String) -> [String] {
    let stickerURLRegularExpression = "http.*?://[\\w/:%#\\$&\\?\\(\\)~\\.=\\+\\-]+sticker.png"
    
    guard let regex = try? NSRegularExpression(pattern: stickerURLRegularExpression) else {
        return []
    }
    
    let matches = regex.matches(in: html, range: NSRange(location: 0, length: html.count))
    
    var imageURLs: [String] = []
    for value in matches {
        guard let imageURL = html.map({ group -> String in
            return (html as NSString).substring(with: value.range(at: 0))
        }).first else {
            exit(0)
        }
        imageURLs.append(imageURL)
    }
    return imageURLs
}

func downloadImage(from urls: [URL]) {
    let semaphore = DispatchSemaphore(value: 0)
    
    for (index, url) in urls.enumerated() {
        let session = URLSession(configuration: .default)
        let task = session.dataTask(with: .init(url: url)) { (data, response, error) in
            defer{
                semaphore.signal()
            }
            guard let data = data else {
                print("No data.")
                exit(0)
            }
            guard let image = NSImage(data: data) else {
                print("Failed encodeing data to html.")
                exit(0)
            }
            image.writePNG(fileName: String(index))
        }
        task.resume()
        semaphore.wait()
    }
}

//
let semaphore = DispatchSemaphore(value: 0)
let HttpsProtocol = "https"

let urlStrings = CommandLine.arguments.filter { $0.hasPrefix(HttpsProtocol) }

guard let urlString = urlStrings.first, let url = URL(string: urlString) else {
    print(" Not contains URL.")
    exit(0)
}

let session = URLSession(configuration: .default)
let task = session.dataTask(with: .init(url: url)) { (data, response, error) in
    defer{
        semaphore.signal()
    }
    guard let data = data else {
        print("No data.")
        exit(0)
    }
    guard let html = String.init(data: data, encoding: .utf8) else {
        print("Failed encodeing data to html.")
        exit(0)
    }
    let imageURLs = captureImageURLs(from: html)
    let urls = imageURLs.map { URL(string: $0)! }
    // 画像のDL
    downloadImage(from: urls)
    
}
task.resume()
// 非同期処理実行のために待機
semaphore.wait()
