//
//  TreeNode.swift
//  FSChanges
//

import AppKit

@objc public final class TreeNode: NSObject, Comparable {
	/*
	public static func < (lhs: TreeNode, rhs: TreeNode) -> Bool {
	return lhs.url.absoluteString < rhs.url.absoluteString
	}
	*/
	
	public static func < (lhs: TreeNode, rhs: TreeNode) -> Bool {
		return lhs.netSize > rhs.netSize
	}
	
	public static func > (lhs: TreeNode, rhs: TreeNode) -> Bool {
		return lhs.totalFileAllocatedSize > rhs.totalFileAllocatedSize
	}
	
	@objc let url: URL
	@objc let name: String
	@objc let isDir: Bool
	//@objc let fileSize: Int
	//@objc let fileAllocatedSize: Int
	@objc let totalFileAllocatedSize: Int
	@objc let netSize: Int
	@objc let icon: NSImage
	@objc var children: [TreeNode]
	//  fileSize: Int, fileAllocatedSize: Int,
	init(url: URL, isDir: Bool, totalFileAllocatedSize: Int, netSize: Int, children: [TreeNode] = []) {
		self.url = url
		self.name = url.lastPathComponent
		self.isDir = isDir
		//self.fileSize = fileSize
		//self.fileAllocatedSize = fileAllocatedSize
		self.totalFileAllocatedSize = totalFileAllocatedSize
		self.netSize = netSize
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
			
		}	}
	
	@objc var dataSize: String {
		get {
			return GenerateTree.fmt.string(fromByteCount: Int64(netSize))
		}
	}
}
