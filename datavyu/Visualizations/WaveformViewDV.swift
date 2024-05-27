import DSWaveformImage
import SwiftUI

@available(iOS 14.0, *)
/// Renders and displays a waveform for the audio at `audioURL`.
public struct WaveformViewDV: View {
    public static let defaultConfiguration = Waveform.Configuration(damping: .init(percentage: 0.125, sides: .both))

    private let audioURL: URL
    private let configuration: Waveform.Configuration
    private let renderer: WaveformRenderer
    private let priority: TaskPriority
    @State private var size: CGSize = CGSize()

    @StateObject private var waveformDrawer = WaveformImageDrawer()
    @State private var waveformImage: DSImage = .init()
    
    @ObservedObject var fileModel: FileModel
    @ObservedObject var videoModel: VideoModel
    var geometryReader: GeometryProxy

    /**
     Creates a new WaveformView which displays a waveform for the audio at `audioURL`.

     - Parameters:
     - audioURL: The `URL` of the audio asset to be rendered.
     - configuration: The `Waveform.Configuration` to be used for rendering.
     - renderer: The `WaveformRenderer` implementation to be used. Defaults to `LinearWaveformRenderer`. Also comes with `CircularWaveformRenderer`.
     - priority: The `TaskPriority` used during analyzing. Defaults to `.userInitiated`.
     */
    public init(
        audioURL: URL,
        videoModel: VideoModel,
        fileModel: FileModel,
        geometryReader: GeometryProxy,
        configuration: Waveform.Configuration = defaultConfiguration,
        renderer: WaveformRenderer = LinearWaveformRenderer(),
        priority: TaskPriority = .userInitiated
    ) {
        
        self.audioURL = audioURL
        self.configuration = configuration
        self.renderer = renderer
        self.priority = priority
        self.geometryReader = geometryReader
        self.fileModel = fileModel
        self.videoModel = videoModel
        
        let width = geometryReader.size.width * (fileModel.longestDuration > 0 ? (videoModel.duration / fileModel.longestDuration) : 1) + 1
        let height = geometryReader.size.height
        
        self.size = CGSize(width: width, height: height)
    }

    public var body: some View {
        GeometryReader { geometry in
            image
                .onAppear {
                    guard waveformImage.size == .zero else { return }
                    updateSize()
                    update(size: self.size, url: audioURL, configuration: configuration)
                }
                .onChange(of: geometry.size) { updateSize() }
                .onChange(of: audioURL) { update(size: self.size, url: $0, configuration: configuration) }
                .onChange(of: configuration) {
                    update(size: self.size, url: audioURL, configuration: $0)
                }
                .onChange(of: fileModel.longestDuration) {
                    updateSize()
                    update(size: self.size, url: audioURL, configuration: configuration)
                }
                .onChange(of: geometryReader.size) { oldValue, newValue in
                    updateSize()
                    update(size: self.size, url: audioURL, configuration: configuration)
                }
        }
    }
    
    func updateSize() {
        let width = geometryReader.size.width * (fileModel.longestDuration > 0 ? (videoModel.duration / fileModel.longestDuration) : 1) + 1
        let height = geometryReader.size.height
        
        self.size = CGSize(width: width, height: height)
    }

    private var image: some View {
        #if os(macOS)
            Image(nsImage: waveformImage).resizable()
        #else
            Image(uiImage: waveformImage).resizable()
        #endif
    }

    private func update(size: CGSize, url: URL, configuration: Waveform.Configuration) {
        Task(priority: priority) {
            do {
                let image = try await waveformDrawer.waveformImage(fromAudioAt: url, with: configuration.with(size: self.size), renderer: renderer)
                await MainActor.run { waveformImage = image }
            } catch {
//                assertionFailure(error.localizedDescription)
            }
        }
    }
}

extension DSImage: @unchecked Sendable {}
