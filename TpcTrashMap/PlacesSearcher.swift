//
//  PlacesSearcher.swift
//  TpcTrashMap
//
//  Created by Wei-Cheng Ling on 2021/2/6.
//

import Foundation
import MapKit
import Combine

class PlacesSearcher: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    
    @Published var searchQuery = ""
    @Published var results = [MKLocalSearchCompletion]()
    
    private let completer : MKLocalSearchCompleter
    private var cancellable: AnyCancellable?
    
    
    // MARK: - Init
    
    override init() {
        completer = MKLocalSearchCompleter()
        super.init()
        
        cancellable = $searchQuery.assign(to: \.queryFragment, on: self.completer)
        completer.delegate = self
    }
    
    
    // MARK: - Functions
    
    func search(_ text: String) {
        completer.queryFragment = text
    }
    
    
    // MARK: - MKLocalSearchCompleterDelegate
    
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        results = completer.results
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        if let error = error as NSError? {
            print("MKLocalSearchCompleter encountered an error: \(error.localizedDescription). The query fragment is: \"\(completer.queryFragment)\"")
        }
        results = []
    }
    
}

extension MKLocalSearchCompletion: Identifiable {}

