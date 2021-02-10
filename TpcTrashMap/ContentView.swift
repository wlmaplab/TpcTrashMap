//
//  ContentView.swift
//  TpcTrashMap
//
//  Created by Wei-Cheng Ling on 2021/2/1.
//

import SwiftUI
import MapKit
import Combine

struct ContentView: View {
    
    @ObservedObject var dataFetcher = DataFetcher()
    @Environment(\.colorScheme) var colorScheme
    
    @State private var isShowPlaceSearchView = false
    @State private var mapItem : MKMapItem?
    
    private let mapView = MapView()
    
    var body: some View {
        VStack {
            if dataFetcher.dataArray.count == 0 {
                Text("正在下載垃圾桶資料，請稍等...")
                ProgressView(value: dataFetcher.progress)
                    .padding(40)
            } else {
                mapView
                    .edgesIgnoringSafeArea(.all)
                    .overlay(
                        VStack(spacing: 0) {
                            Button(action: {
                                isShowPlaceSearchView.toggle()
                            }) {
                                Image(systemName: "magnifyingglass")
                                    .frame(width: 45, height: 45, alignment: .center)
                                    .font(.system(size: 20, weight: .medium, design: .default))
                                    .foregroundColor(colorScheme == .dark ? .white : .blue)
                            }
                            .sheet(isPresented: $isShowPlaceSearchView){
                                PlaceSearchView(isShowPlaceSearchView: $isShowPlaceSearchView, mapItem: $mapItem)
                            }
                            
                            if mapItem != nil {
                                Divider()
                                    .frame(width: 45)
                                    .background(colorScheme == .dark ? Color.white : Color(UIColor(white: 0.9, alpha: 1.0)))
                                
                                Button(action: {
                                    mapView.moveToPlace()
                                }) {
                                    Image(systemName: "mappin")
                                        .frame(width: 45, height: 45, alignment: .center)
                                        .font(.system(size: 20, weight: .medium, design: .default))
                                        .foregroundColor(colorScheme == .dark ? .white : .blue)
                                }
                            }
                            
                            Divider()
                                .frame(width: 45)
                                .background(colorScheme == .dark ? Color.white : Color(UIColor(white: 0.9, alpha: 1.0)))
                            
                            Button(action: {
                                mapView.moveToUserLocation()
                            }) {
                                Image(systemName: "figure.stand")
                                    .frame(width: 45, height: 45, alignment: .center)
                                    .font(.system(size: 20, weight: .bold, design: .default))
                                    .foregroundColor(colorScheme == .dark ? .white : .blue)
                            }
                        }
                        .background(Color(colorScheme == .dark ? .systemGray4 : .white))
                        .cornerRadius(10)
                        .padding(8)
                        .shadow(color: Color(colorScheme == .dark ? .systemGray6 : UIColor(white: 0.8, alpha: 1.0)),
                                radius: 3, x: 0, y: 0),
                        alignment: .topTrailing
                    )
                    .onAppear {
                        mapView.addData(dataFetcher.dataArray)
                    }
                    .onChange(of: mapItem) { newMapItem in
                        mapView.addPlace(newMapItem)
                    }
            }
        }
        .onAppear {
            dataFetcher.download()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
