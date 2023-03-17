import Foundation
import UIKit
import SwiftSignalKit


public final class CurrentDateGetter: ListViewItem, ItemListItem {
    private enum Constants: String {
        case url = "http://worldtimeapi.org/api/timezone/Europe/Moscow"
    }
    
    public enum DataError {
        case url
        case network
    }
    
    public static func convertDataToDate(data: Data) -> Date? {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions.insert(.withFractionalSeconds)

        guard let parsedDateTime = try? JSONDecoder().decode(DateTime.self, from: data),
           let date = dateFormatter.date(from:parsedDateTime.datetime) else {
            return nil
        }
        return date
    }
    
    public static func downloadHTTPData() -> Signal<Data, DataError> {
        guard let url = URL(string: Constants.url.rawValue) else {
            return Signal<nil, .url>
        }
        return Signal { subscriber in
            let completed = Atomic<Bool>(value: false)

            let downloadTask = URLSession.shared.downloadTask(with: url, completionHandler: { location, _, error in
                if let error = error {
                    print(error.localizedDescription)
                    subscriber.putError(.network)
                    return
                }
                let _ = completed.swap(true)
                if let location = location, let data = try? Data(contentsOf: location) {
                    subscriber.putNext(data)
                    subscriber.putCompletion()
                } else {
                    subscriber.putError(.network)
                }
            })
            downloadTask.resume()
            
            return ActionDisposable {
                if !completed.with({ $0 }) {
                    downloadTask.cancel()
                }
            }
        }
    }
}

private struct DateTime: Codable {
    let datetime: String
}
