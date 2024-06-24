import Foundation
import SwiftUI

struct UpdateTaskEntry: Codable {
    let id: Int
    let tagName: String
    let name: String
}

struct UpdateView: View {
    @State var entry: UpdateTaskEntry? = nil
    @Environment(\.dismiss) var dismiss
    @ObservedObject var appState: AppState

    var body: some View {
        VStack(alignment: .leading) {
            if let entry = entry {
                Text("\(entry.id)")
                Text(entry.name)
                Text(entry.tagName)
            } else {
                ProgressView()
            }

            Button("Close") {
                dismiss()
            }
        }
        .frame(width: 500, height: 400)
        .onAppear(perform: loadData)
    }

    func loadData() {
        guard let url = URL(string: Config.updateUrl) else {
            print("Invalid URL")
            return
        }
        let request = URLRequest(url: url)

        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                // TODO: Handle data task error
                return
            }

            guard let data = data else {
                // TODO: Handle this
                return
            }

            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase

            do {
                let response = try decoder.decode(UpdateTaskEntry.self, from: data)

                DispatchQueue.main.async {
                    entry = response
                }
            } catch {
                // TODO: Handle decoding error
                print(error)
            }
        }.resume()
    }
}
