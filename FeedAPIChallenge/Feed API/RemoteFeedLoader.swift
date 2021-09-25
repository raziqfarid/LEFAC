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
				completion(FeedMapper.mapDataToResult(data: data, response: response))
			case .failure: completion(.failure(Error.connectivity))
			}
		}
	}
}

internal final class FeedMapper {
	private struct Root: Decodable {
		let items: [Item]
		
		var feedImages: [FeedImage] {
			items.map { $0.feedImage }
		}
	}

	private struct Item: Decodable {
		let id: UUID
		let description: String?
		let location: String?
		let url: URL
		
		var feedImage: FeedImage {
			FeedImage(id: id, description: description, location: location, url: url)
		}
		
		private init(id: UUID, description: String?, location: String?, url: URL) {
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
	
	private static var OK_200 = 200
	
	internal static func mapDataToResult(data: Data, response: HTTPURLResponse) -> FeedLoader.Result{
		guard response.statusCode == OK_200, let rootData = try? JSONDecoder().decode(Root.self, from: data) else {
			return .failure(RemoteFeedLoader.Error.invalidData)
		}
			
		return .success(rootData.feedImages)
	}
}

