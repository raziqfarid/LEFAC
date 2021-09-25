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
		client.get(from: url) { (result) in
			switch result {
			case let .success((data, response)):
				if response.statusCode == 200, let rootData = try? JSONDecoder().decode(Root.self, from: data) {
					completion(.success(
						rootData.items.map({ (apiFeed) -> FeedImage in
							FeedImage(id: apiFeed.id, description: apiFeed.description, location: apiFeed.location, url: apiFeed.url)
						})
					))
				} else {
					completion(.failure(Error.invalidData))
				}
			default: completion(.failure(Error.connectivity))
			}
			
		}
	}
}

fileprivate struct Root: Decodable {
	fileprivate let items: [APIFeedImage]
}

fileprivate struct APIFeedImage: Decodable {
	fileprivate let id: UUID
	fileprivate let description: String?
	fileprivate let location: String?
	fileprivate let url: URL
	
	
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
