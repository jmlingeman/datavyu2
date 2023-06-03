//
//  VideoView.swift
//  sheettest
//
//  Created by Jesse Lingeman on 6/2/23.
//

import SwiftUI
import AVKit
import CoreImage
import CoreImage.CIFilterBuiltins

struct VideoView: View {
    @State private var currentFilter = 0
    var filters : [CIFilter?] = [nil, CIFilter.sepiaTone(), CIFilter.pixellate(), CIFilter.comicEffect()]
    let player = AVPlayer(url: Bundle.main.url(forResource: "IMG_1234", withExtension: "MOV")!)
    
    var body: some View {
        
        VStack{
            
            VideoPlayer(player: player)
                .onAppear{
                    player.currentItem!.videoComposition = AVVideoComposition(asset: player.currentItem!.asset,  applyingCIFiltersWithHandler: { request in
                        
                        if let filter = self.filters[currentFilter]{
                            
                            let source = request.sourceImage.clampedToExtent()
                            filter.setValue(source, forKey: kCIInputImageKey)
                            
                            if filter.inputKeys.contains(kCIInputScaleKey){
                                filter.setValue(30, forKey: kCIInputScaleKey)
                            }
                            
                            let output = filter.outputImage!.cropped(to: request.sourceImage.extent)
                            request.finish(with: output, context: nil)
                        }
                        else{
                            request.finish(with: request.sourceImage, context: nil)
                        }
                    })
                }
            
            Picker(selection: $currentFilter, label: Text("Select Filter")) {
                ForEach(0..<filters.count) { index in
                    Text(self.filters[index]?.name ?? "None").tag(index)
                }
            }.pickerStyle(SegmentedPickerStyle())
            
            Text("Value: \(self.filters[currentFilter]?.name ?? "None")")
        }
    }
}

struct VideoView_Previews: PreviewProvider {
    static var previews: some View {
        VideoView()
    }
}
