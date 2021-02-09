//
//  PlaceSearchView.swift
//  TpcTrashMap
//
//  Created by Wei-Cheng Ling on 2021/2/5.
//

import SwiftUI
import MapKit

struct PlaceSearchView: View {
    
    @ObservedObject var placesSearcher = PlacesSearcher()
    @Environment(\.colorScheme) var colorScheme
    
    @Binding var isShowPlaceSearchView : Bool
    @Binding var mapItem : MKMapItem?
    @State private var isEditing = false
    
    var body: some View {
        VStack {
            Spacer()
                .frame(height: 15)
            
            HStack {
                TextField("搜尋地點或地址", text: $placesSearcher.searchQuery)
                    .padding(7)
                    .padding(.horizontal, 24)
                    .background(Color(colorScheme == .dark ? .systemGray2 : .systemGray6))
                    .cornerRadius(8)
                    .padding(.leading, 15)
                    .overlay(
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                                .padding(.leading, 23)
                            
                            if isEditing {
                                Button(action: {
                                    placesSearcher.searchQuery = ""
                                }) {
                                    Image(systemName: "multiply.circle.fill")
                                        .foregroundColor(.gray)
                                        .padding(.trailing, 6)
                                }
                            }
                        }
                    )
                    .onTapGesture {
                        isEditing = true
                    }
                
                Button(action: {
                    self.mapItem = nil
                    isShowPlaceSearchView = false
                }) {
                    Text("取消")
                }
                .padding(.leading, 5)
                .padding(.trailing, 15)
            }
            
            List(placesSearcher.results) { place in
                Button(action: {
                    let request = MKLocalSearch.Request(completion: place)
                    let search = MKLocalSearch(request: request)
                    search.start { (response, error) in
                        if let response = response, let mapItem = response.mapItems.first {
                            self.mapItem = mapItem
                            isShowPlaceSearchView = false
                        }
                    }
                }) {
                    VStack(alignment: .leading) {
                        Text(place.title)
                        Text(place.subtitle)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
            }
        }
    }
}

struct PlaceSearchView_Previews: PreviewProvider {
    static var previews: some View {
        PlaceSearchView(isShowPlaceSearchView: .constant(false), mapItem: .constant(nil))
    }
}
