//
//  TreeData.swift
//  FSChanges
//

import Foundation


@objc public class TreeNode: NSObject {
	@objc let url: URL
	@objc let name: String
	@objc let isDir: Bool
	@objc let fileSize: Int
	@objc let fileAllocatedSize: Int
	@objc let totalFileAllocatedSize: Int
	@objc var children: [TreeNode]
	
	init(url: URL, name: String, isDir: Bool, fileSize: Int, fileAllocatedSize: Int, totalFileAllocatedSize: Int, children: [TreeNode] = []) {
		self.url = url
		self.name = name
		self.isDir = isDir
		self.fileSize = fileSize
		self.fileAllocatedSize = fileAllocatedSize
		self.totalFileAllocatedSize = totalFileAllocatedSize
		self.children = children
	}
	
	@objc var count: Int {
		children.count
	}
	
	@objc var isLeaf: Bool {
		children.isEmpty
	}
}


struct GenerateTree {
	static let resourceKeys: [URLResourceKey] = [.isDirectoryKey, .fileSizeKey, .fileAllocatedSizeKey, .totalFileAllocatedSizeKey]
	
	static func recursiveGen(path: URL) -> [TreeNode] {
		var nodes = [TreeNode]()
		
		if let enumerator = FileManager.default.enumerator(at: path, includingPropertiesForKeys: resourceKeys, errorHandler: { (url, err) -> Bool in
			print("Error recursing into directory: \(err)")
			return true
		}) {
			for case let i as URL in enumerator {
				do {
					let resValues = try i.resourceValues(forKeys: Set(resourceKeys))
					if resValues.isDirectory ?? false {
						nodes.append(TreeNode.init(url: i, name: i.lastPathComponent, isDir: true, fileSize: 	resValues.fileSize ?? 0, fileAllocatedSize: resValues.fileAllocatedSize ?? 0, 	totalFileAllocatedSize: resValues.totalFileAllocatedSize ?? 0, children: recursiveGen(path: i)))
					} else {
						nodes.append(TreeNode.init(url: i, name: i.lastPathComponent, isDir: false, fileSize: 	resValues.fileSize ?? 0, fileAllocatedSize: resValues.fileAllocatedSize ?? 0, 	totalFileAllocatedSize: resValues.totalFileAllocatedSize ?? 0))
					}
				} catch  {
					print("error: \(error)")
				}
			}
			
		}
		return nodes
	}
}
