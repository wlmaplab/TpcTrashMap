//
//  DataFetcher.swift
//  TpcTrashMap
//
//  Created by Wei-Cheng Ling on 2021/2/1.
//

import Foundation
import MapKit


struct TrashBin: Identifiable {
    let id = UUID()
    let coordinate : CLLocationCoordinate2D
    let address : String
}


class DataFetcher: ObservableObject {
    
    @Published var dataArray : [TrashBin]?
    @Published var progress = 0.0
    
    private var datasetDownloadedCount = 0
    private var datasetMaxCount = 0
    private let fetchLimit = 1000
    private var fetchOffset = 0
    private var tmpResults : Array<Dictionary<String,Any>>?
    
    
    private let urlString = "https://data.taipei/api/v1/dataset/807317ce-fb7b-4a85-b28e-2bfccaf59a91?scope=resourceAquire"
    
    
    
    // MARK: - Functions
    
    func download() {
        print(">> 正在下載資料集...")
        dataArray = nil
        
        tmpResults = Array<Dictionary<String,Any>>()
        fetchOffset = 0
        datasetDownloadedCount = 0
        datasetMaxCount = 5
        
        downloadData()
    }
    
    
    // MARK: - Download Data
    
    private func downloadData() {
        fetch(limit: fetchLimit, offset: fetchOffset) { json in
            var resultsCount = 0
            if let json = json,
               let result = json["result"] as? Dictionary<String,Any>,
               let results = result["results"] as? Array<Dictionary<String,Any>>
            {
                if let dataCount = result["count"] as? Int, self.datasetDownloadedCount == 0 {
                    let (quotient, remainder) = dataCount.quotientAndRemainder(dividingBy: self.fetchLimit)
                    self.datasetMaxCount = quotient + (remainder > 0 ? 1 : 0)
                }
                self.tmpResults?.append(contentsOf: results)
                resultsCount = results.count
            }
            
            self.datasetDownloadedCount += 1
            self.setProgressValue()
            
            if resultsCount >= self.fetchLimit {
                self.fetchOffset += self.fetchLimit
                self.downloadData()
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.convertResultsToDataArray()
                }
            }
        }
    }
    
    private func convertResultsToDataArray() {
        guard let results = tmpResults else { return }
        
        var tmpArray = [TrashBin]()
        
        for info in results {
            if let item = createTrashBinItem(info) {
                tmpArray.append(item)
            }
        }
        
        dataArray = tmpArray
        print(">> dataArray count: \(tmpArray.count)")
    }
    
    
    // MARK: - TrashBin Item
    
    private func createTrashBinItem(_ info: Dictionary<String,Any>) -> TrashBin? {
        let latitude = Double("\(info["緯度"] ?? "")")
        let longitude = Double("\(info["經度"] ?? "")")
        
        if let lat = latitude, let lng = longitude {
            let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lng)
            let address = "\(info["路名"] ?? "")\(info["段號及其他註明"] ?? "")"
            return TrashBin(coordinate: coordinate, address: address)
        }
        return nil
    }
    
    
    // MARK: - Change Progress Value
    
    private func setProgressValue() {
        progress = Double(datasetDownloadedCount) / Double(datasetMaxCount)
    }
    
    
    // MARK: - Fetch Data
    
    private func fetch(limit: Int, offset: Int, callback: @escaping (Dictionary<String,Any>?) -> Void) {
        httpGET_withFetchJsonObject(URLString: "\(urlString)&limit=\(limit)&offset=\(offset)", callback: callback)
    }
    
    
    // MARK: - HTTP GET
    
    private func httpGET_withFetchJsonObject(URLString: String, callback: @escaping (Dictionary<String,Any>?) -> Void) {
        httpRequestWithFetchJsonObject(httpMethod: "GET", URLString: URLString, parameters: nil, callback: callback)
    }
    
    
    // MARK: - HTTP Request with Method
    
    private func httpRequestWithFetchJsonObject(httpMethod: String,
                                                URLString: String,
                                                parameters: Dictionary<String,Any>?,
                                                callback: @escaping (Dictionary<String,Any>?) -> Void)
    {
        // Create request
        let url = URL(string: URLString)!
        var request = URLRequest(url: url)
        request.httpMethod = httpMethod
        
        // Header
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "accept")
        
        // Body
        if let parameterDict = parameters {
            // parameter dict to json data
            let jsonData = try? JSONSerialization.data(withJSONObject: parameterDict)
            // insert json data to the request
            request.httpBody = jsonData
        }
        
        // Task
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                guard let data = data, error == nil else {
                    print(error?.localizedDescription ?? "No data")
                    callback(nil)
                    return
                }
                
                let responseJSON = try? JSONSerialization.jsonObject(with: data, options: [])
                if let responseJSON = responseJSON as? [String: Any] {
                    callback(responseJSON)
                } else {
                    callback(nil)
                }
            }
        }
        task.resume()
    }
}

