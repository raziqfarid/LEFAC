//
//  Copyright © 2018 Essential Developer. All rights reserved.
//

import Foundation

public final class RemoteFeedLoader: FeedLoader {
	private let url: URL
	private let client: HTTPClient
	
	public enum Error: Swift.Error {
		case connectivity
		case invalidData
	}
	
	public init(url: URL, client: HTTPClient) {
		self.url = url
		self.client = client
	}
	
	public func load(completion: @escaping (FeedLoader.Result) -> Void) {
		client.get(from: url) { [weak self] (result) in
			guard let _ = self else { return }
			switch result {
			case let .success((data, response)):
				completion(RemoteFeedLoader.mapDataToResult(data: data, response: response))
			case .failure: completion(.failure(Error.connectivity))
			}
		}
	}
	
	private static func mapDataToResult(data: Data, response: HTTPURLResponse) -> FeedLoader.Result{
		if response.statusCode == 200, let rootData = try? JSONDecoder().decode(Root.self, from: data) {
			return .success(rootData.feedImages)
		} else {
			return .failure(Error.invalidData)
		}
	}
}

fileprivate struct Root: Decodable {
	fileprivate let items: [APIFeedImage]
	
	fileprivate var feedImages: [FeedImage] {
		items.map { $0.feedImage }
	}
}

fileprivate struct APIFeedImage: Decodable {
	fileprivate let id: UUID
	fileprivate let description: String?
	fileprivate let location: String?
	fileprivate let url: URL
	
	fileprivate var feedImage: FeedImage {
		FeedImage(id: id, description: description, location: location, url: url)
	}
	
	fileprivate init(id: UUID, description: String?, location: String?, url: URL) {
		self.id = id
		self.description = description
		self.location = location
		self.url = url
	}
	
	private enum CodingKeys: String, CodingKey {
		case id = "image_id"
		case description = "image_desc"
		case location = "image_loc"
		case url = "image_url"
	}
}
