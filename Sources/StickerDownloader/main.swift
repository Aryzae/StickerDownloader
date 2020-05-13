//
//  main.swift
//  StickerDownloader
//
//  Created by aryzae on 2018/07/15.
//  Copyright © 2018 aryzae. All rights reserved.
//

import Foundation
import Cocoa

// MARK: - convert image
public extension NSImage {
    func writePNG(fileName: String, path: URL) {
        let filePath = path.appendingPathComponent("/\(fileName).png")
        
        guard let data = tiffRepresentation,
            let rep = NSBitmapImageRep(data: data),
            let imgData = rep.representation(using: .png, properties: [.compressionFactor : NSNumber(floatLiteral: 1.0)]) else {
                print("\(self.self) Error Function '\(#function)' Line: \(#line) No tiff rep found for image writing to \(path)")
                exit(0)
        }
        
        do {
            // file protocol必須 file:///
            try imgData.write(to: filePath, options: .atomicWrite)
        } catch let error {
            print("\(self.self) Error Function '\(#function)' Line: \(#line) \(error.localizedDescription)")
            exit(0)
        }
    }
}

func createDownloadsPath() -> URL {
    let savePath: URL
    let fileManager = FileManager.default

    do {
        // Downloadsフォルダを取得
        let downloadsPath = try fileManager.url(for: .downloadsDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        savePath = downloadsPath.appendingPathComponent(titlePath, isDirectory: true)

        // file:// を除去してからtitlePathをつけないとを%エンコーディングされた文字でdirectory判定が狂う
        var pathWithoutFile = downloadsPath.absoluteString.replacingOccurrences(of: "file://", with: "")
        pathWithoutFile = pathWithoutFile + "\(titlePath)"

        // titlePathのフォルダ作成
        var isDirectory: ObjCBool = true
        let exists = fileManager.fileExists(atPath: pathWithoutFile, isDirectory: &isDirectory)

        if !exists {
            try fileManager.createDirectory(at: savePath, withIntermediateDirectories: false, attributes: nil)
        }
    } catch (let error) {
        print("Error Function '\(#function)' Line: \(#line) \(error.localizedDescription)")
        exit(0)
    }

    return savePath
}

func stickerTitle(from html: String) -> String {
    let tagTitleStart = "<title>"
    let tagTitleEnd = "</title>"
    let gabadgeSuffix = " - LINE スタンプ | LINE STORE"
    let stickerTitleRegularExpression = "\(tagTitleStart).*\(tagTitleEnd)"
    // 正規表現でタイトル部分の抜き出し
    guard let regex = try? NSRegularExpression(pattern: stickerTitleRegularExpression) else { return "" }
    guard let match = regex.matches(in: html, range: NSRange(location: 0, length: html.count)).first else { return "" }
    let titles = html.map { _ in (html as NSString).substring(with: match.range(at: 0)) }
    guard var title = titles.first else { exit(0) }
    // <title> </title>のタグと余分なタイトルを落とす
    title = title.replacingOccurrences(of: tagTitleStart, with: "")
    title = title.replacingOccurrences(of: tagTitleEnd, with: "")
    title = title.replacingOccurrences(of: gabadgeSuffix, with: "")

    return title
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
    let path = createDownloadsPath()
    
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
            image.writePNG(fileName: String(index), path: path)
        }
        task.resume()
        semaphore.wait()
    }
}

// MARK: - property
var titlePath = ""
let semaphore = DispatchSemaphore(value: 0)
let HttpsProtocol = "https"

let urlStrings = CommandLine.arguments.filter { $0.hasPrefix(HttpsProtocol) }

guard let urlString = urlStrings.first, let url = URL(string: urlString) else {
    print(" Not contains URL.")
    exit(0)
}

// MARK: - 1. download
let session = URLSession(configuration: .default)
let task = session.dataTask(with: .init(url: url)) { (data, response, error) in
    defer{
        semaphore.signal()
    }
    guard let data = data else {
        print("Data not found.")
        exit(0)
    }
    guard let html = String.init(data: data, encoding: .utf8) else {
        print("Failed encodeing data to html.")
        exit(0)
    }
    titlePath = stickerTitle(from: html)
    let imageURLs = captureImageURLs(from: html)
    let urls = imageURLs.compactMap { URL(string: $0) }
    // 画像のDL
    downloadImage(from: urls)
    
}
task.resume()
// 非同期処理実行のために待機
semaphore.wait()
print("\n==========================================")
print("Download successful!!.")
print("open ~/Downloads\n")
