//
//  YoutubeVideoExtractor.swift
//  AKPlayer_Example
//
//  Copyright (c) 2020 Amalendu Kar
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import Foundation

func extractVideos(from youtubeId : String, completion: @escaping ((Result<[String: String], Error>) -> Void)) {
    
    let strUrl = "https://www.youtube.com/get_video_info?video_id=\(youtubeId)"//&el=embedded&ps=default&eurl=&gl=US&hl=en"
    let url = URL(string: strUrl)!
    
    URLSession.shared.dataTask(with: url) { (datatmp, response, error) in
        if let error = error {
            DispatchQueue.main.async {
                completion(.failure(error))
            }
            return
        }
        guard (response as? HTTPURLResponse) != nil else {
            DispatchQueue.main.async {
                completion(.failure(NSError()))
            }
            return
        }
        
        if let data = datatmp,
           let string = String(data: data, encoding: .utf8), let response = string.removingPercentEncoding {
            let dic = getDictionnaryFrom(string: response)
            completion(.success(dic))
        }
    }.resume()
}

func getDictionnaryFrom(string: String) -> [String: String] {
    var dic = [String:String]()
    let result = string.replacingOccurrences(of:"\\u0026", with:"&")
    let parts = result.components(separatedBy: ",")
    
    var urlString: String? = nil
    var firstURLString: String? = nil
    
    for part in parts {
        let keyval = part.components(separatedBy: "\":\"")
        if (keyval.count >= 2){
            print("Key Is : ", keyval[0], "Value is : ", keyval[1])
            print("------------------------------")
            if dic["url"] == nil && keyval[0] == "\"url" {
                urlString = keyval[1].replacingOccurrences(of:"\"", with:"")
                if firstURLString == nil {
                    firstURLString = urlString
                }
            }
            
            if keyval[0] == "\"quality" {
                if keyval[1] == "medium\"" {
                    if let string = urlString {
                        if dic["url"] == nil {
                            dic["url"] = string
                        }
                    }
                }
            }
            if keyval[0] == "\"title" {
                dic["title"] = keyval[1].replacingOccurrences(of:"\"", with:"").replacingOccurrences(of: "+", with:" ")
            }
            if keyval[0] == "\"image" {
                dic["image"] = keyval[1].replacingOccurrences(of:"\"", with:"").replacingOccurrences(of: "+", with:" ")
            }
            
        }
    }
    if dic["url"] == nil {
        if let string = firstURLString {
            dic["url"] = string
        }
    }
    return dic
}
