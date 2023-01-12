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
    
    private let fetchLimit = 1000
    private var fetchOffset = 0
    private var tmpResults : Array<Dictionary<String,Any>>?
    
    private let infoUrlString = "https://wlmaplab.github.io/json/tpc-trash-dataset.json"
    private var datasetUrlString = ""
    
    
    // MARK: - Functions
    
    @MainActor
    func download() async {
        print(">> 正在下載資料集...")
        dataArray = nil
        
        tmpResults = Array<Dictionary<String,Any>>()
        fetchOffset = 0
        
        await downloadInfoJson()
    }
    
    
    // MARK: - Download Data

    private func downloadInfoJson() async {
        if let json = try? await httpGET_withFetchJsonObject(URLString: infoUrlString),
           let urlStr = json["url"] as? String
        {
            datasetUrlString = urlStr
            await downloadData()
        }
    }
    
    @MainActor
    private func downloadData() async {
        var resultsCount = 0
        if let json = try? await fetch(limit: fetchLimit, offset: fetchOffset),
           let result = json["result"] as? Dictionary<String,Any>,
           let results = result["results"] as? Array<Dictionary<String,Any>>
        {
            tmpResults?.append(contentsOf: results)
            resultsCount = results.count

            if resultsCount >= fetchLimit {
                fetchOffset += fetchLimit
                await downloadData()
            } else {
                convertResultsToDataArray()
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
    
    
    // MARK: - Fetch Data
    
    private func fetch(limit: Int, offset: Int) async throws -> [String: Any]? {
        let json = try await httpGET_withFetchJsonObject(URLString: "\(datasetUrlString)&limit=\(limit)&offset=\(offset)")
        return json
    }
    
    
    // MARK: - HTTP GET
    
    private func httpGET_withFetchJsonObject(URLString: String) async throws -> [String: Any]? {
        let json = try await httpRequestWithFetchJsonObject(httpMethod: "GET", URLString: URLString, parameters: nil)
        return json
    }
    
    
    // MARK: - HTTP Request with Method
    
    private func httpRequestWithFetchJsonObject(httpMethod: String,
                                                URLString: String,
                                                parameters: Dictionary<String,Any>?) async throws -> [String: Any]? {
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
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let json = try? JSONSerialization.jsonObject(with: data, options: [])
        if let json = json as? [String: Any] {
            return json
        }
        return nil
    }
}
