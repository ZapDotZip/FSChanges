//
//  TreeData.swift
//  FSChanges
//

import Foundation
import Cocoa


@objc public class TreeNode: NSObject, Comparable {
	/*
	public static func < (lhs: TreeNode, rhs: TreeNode) -> Bool {
	return lhs.url.absoluteString < rhs.url.absoluteString
	}
	*/
	
	public static func < (lhs: TreeNode, rhs: TreeNode) -> Bool {
		return lhs.totalFileAllocatedSize > rhs.totalFileAllocatedSize
	}
	
	@objc let url: URL
	@objc let name: String
	@objc let isDir: Bool
	//@objc let fileSize: Int
	//@objc let fileAllocatedSize: Int
	@objc let totalFileAllocatedSize: Int
	@objc let icon: NSImage
	@objc var children: [TreeNode]
	//  fileSize: Int, fileAllocatedSize: Int,
	init(url: URL, isDir: Bool, totalFileAllocatedSize: Int, children: [TreeNode] = []) {
		self.url = url
		self.name = url.lastPathComponent
		self.isDir = isDir
		//self.fileSize = fileSize
		//self.fileAllocatedSize = fileAllocatedSize
		self.totalFileAllocatedSize = totalFileAllocatedSize
		self.children = children
		self.icon = NSWorkspace.shared.icon(forFile: url.path)
	}
	
	@objc var count: Int {
		children.count
	}
	
	@objc var isLeaf: Bool {
		children.isEmpty
	}
	
	override public var description: String {
		get {
			//return "\(url): fileSize: \(GenerateTree.fmt.string(fromByteCount: Int64(fileSize))), fileAllocatedSize: \(GenerateTree.fmt.string(fromByteCount: Int64(fileAllocatedSize))), totalFileAllocatedSize: \(GenerateTree.fmt.string(fromByteCount: Int64(totalFileAllocatedSize)))"
			return "\(url): totalFileAllocatedSize: \(GenerateTree.fmt.string(fromByteCount: Int64(totalFileAllocatedSize)))"
		}
	}
	
	@objc var dataSize: String {
		get {
			return GenerateTree.fmt.string(fromByteCount: Int64(totalFileAllocatedSize))
		}
	}
}


struct GenerateTree {
	static let resourceKeys: [URLResourceKey] = [.isDirectoryKey, .fileSizeKey, .fileAllocatedSizeKey, .totalFileAllocatedSizeKey]
	static var viewCon: ViewController?
	static let fmt = ByteCountFormatter()
	
	static func recursiveGen(path: URL) -> ([TreeNode], Int) {
		var nodes = [TreeNode]()
		var totalSize: Int = 0
		
		if let enumerator = FileManager.default.enumerator(at: path, includingPropertiesForKeys: resourceKeys, options: [.skipsSubdirectoryDescendants], errorHandler: { (url, err) -> Bool in
			print("Error recursing into directory: \(err)")
			return true
		}) {
			for case let i as URL in enumerator {
				do {
					let resValues = try i.resourceValues(forKeys: Set(resourceKeys))
					if resValues.isDirectory ?? false {
						let (children, childrenTotalSize) = recursiveGen(path: i)
						nodes.append(TreeNode.init(url: i, isDir: true, totalFileAllocatedSize: childrenTotalSize, children: children))
						totalSize += childrenTotalSize
					} else {
						nodes.append(TreeNode.init(url: i, isDir: false, totalFileAllocatedSize: resValues.totalFileAllocatedSize ?? 0))
						totalSize += resValues.totalFileAllocatedSize ?? 0
						DispatchQueue.main.async {
							viewCon?.progress.doubleValue += 1.0
							viewCon?.progressLabel.stringValue = i.path
						}
						
					}
				} catch  {
					DispatchQueue.main.async {
						print("error: \(error)")
					}
				}
			}
		}
		nodes.sort()
		return (nodes, totalSize)
	}
	
	
	static func multiFolderLoader(paths: [URL]) {
		for u in paths {
			let (children, totalSize) = GenerateTree.recursiveGen(path: u)
			let selectedRootNode: TreeNode = TreeNode.init(url: u, isDir: true, totalFileAllocatedSize: totalSize, children: children)
			DispatchQueue.main.async {
				self.viewCon!.content.append(selectedRootNode)
				self.viewCon!.progress.doubleValue = 0.0
			}
		}
		DispatchQueue.main.async {
			self.viewCon!.progress.doubleValue = self.viewCon!.progress.maxValue
			self.viewCon!.progressLabel.stringValue = "All done."
		}
	}
	
	static func folderLoader(path: URL) {
		let (selectedRootNode, _) = GenerateTree.recursiveGen(path: path)
		DispatchQueue.main.async {
			self.viewCon!.content.append(contentsOf: selectedRootNode)
			self.viewCon!.progress.doubleValue = self.viewCon!.progress.maxValue
			self.viewCon!.progressLabel.stringValue = "All done."
		}
	}
}
