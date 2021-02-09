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
    
    @Published var dataArray = [TrashBin]()
    @Published var progress = 0.0
    var datasetDownloadedCount = 0
    
    private let datasetDict = ["士林區": "97cc923a-e9ee-4adc-8c3d-335567dc15d3",
                               "大同區": "5fa14e06-018b-4851-8316-1ff324384f79",
                               "大安區": "f40cd66c-afba-4409-9289-e677b6b8d00e",
                               "中山區": "33b2c4c5-9870-4ee9-b280-a3a297c56a22",
                               "中正區": "0b544701-fb47-4fa9-90f1-15b1987da0f5",
                               "內湖區": "37eac6d1-6569-43c9-9fcf-fc676417c2cd",
                               "文山區": "46647394-d47f-4a4d-b0f0-14a60ac2aade",
                               "北投區": "05d67de9-a034-4177-9f53-10d6f79e02cf",
                               "松山區": "179d0fe1-ef31-4775-b9f0-c17b3adf0fbc",
                               "信義區": "8cbb344b-83d2-4176-9abd-d84508e7dc73",
                               "南港區": "7b955414-f460-4472-b1a8-44819f74dc86",
                               "萬華區": "5697d81f-7c9d-43fc-a202-ae8804bbd34b"]
    
    
    // MARK: - Functions
    
    func datasetCount() -> Int {
        return datasetDict.count
    }
    
    func downloadData() {
        print(">> 正在下載資料集...")
        
        dataArray.removeAll()
        datasetDownloadedCount = 0
        
        var tmpArray = [TrashBin]()
        
        for (districtName, datasetID) in datasetDict {
            fetch(datasetID: datasetID, limit: 1000, offset: 0) { json in
                self.datasetDownloadedCount += 1
                self.setProgressValue()
                
                if let json = json,
                   let result = json["result"] as? Dictionary<String,Any>,
                   let results = result["results"] as? Array<Dictionary<String,Any>>
                {
                    print("\(districtName) count: \(results.count)")
                    for info in results {
                        if let item = self.createTrashBinItem(info) {
                            tmpArray.append(item)
                        }
                    }
                }
                
                if self.datasetDownloadedCount >= self.datasetCount() {
                    self.dataArray.append(contentsOf: tmpArray)
                }
            }
        }
    }
    
    
    // MARK: - TrashBin Item
    
    private func createTrashBinItem(_ info: Dictionary<String,Any>) -> TrashBin? {
        let latitude = Double("\(info["緯度"] ?? "")")
        let longitude = Double("\(info["經度"] ?? "")")
        
        if let lat = latitude, let lng = longitude {
            let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lng)
            let address = "\(info["路名"] ?? "")\(info["段、號及其他註明"] ?? "")"
            return TrashBin(coordinate: coordinate, address: address)
        }
        return nil
    }
    
    
    // MARK: - Change Progress Value
    
    private func setProgressValue() {
        progress = Double(datasetDownloadedCount) / Double(datasetDict.count)
    }
    
        
    // MARK: - API URL String
    
    private func urlStringWith(datasetID: String) -> String {
        return "https://data.taipei/api/v1/dataset/\(datasetID)?scope=resourceAquire"
    }
    
    
    // MARK: - Fetch Data
    
    private func fetch(datasetID: String, limit: Int, offset: Int, callback: @escaping (Dictionary<String,Any>?) -> Void) {
        let urlString = urlStringWith(datasetID: datasetID)
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

