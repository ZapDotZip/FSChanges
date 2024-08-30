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
	
	@objc let path: String
	@objc let name: String
	@objc let isDir: Bool
	//@objc let fileSize: Int
	//@objc let fileAllocatedSize: Int
	@objc let totalFileAllocatedSize: Int
	@objc let netSize: Int
	@objc lazy var icon: NSImage = {
		return NSWorkspace.shared.icon(forFile: path)
	}()
	@objc var children: [TreeNode]
	//  fileSize: Int, fileAllocatedSize: Int,
	init(url: URL, isDir: Bool, totalFileAllocatedSize: Int, netSize: Int, children: [TreeNode] = []) {
		self.path = url.path
		self.name = url.lastPathComponent
		self.isDir = isDir
		//self.fileSize = fileSize
		//self.fileAllocatedSize = fileAllocatedSize
		self.totalFileAllocatedSize = totalFileAllocatedSize
		self.netSize = netSize
		self.children = children
	}
	
	@objc var count: Int {
		children.count
	}
	
	@objc var isLeaf: Bool {
		children.isEmpty
	}
	
	override public var description: String {
		return "\(path): totalFileAllocatedSize: \(GenerateTree.fmt.string(fromByteCount: Int64(totalFileAllocatedSize)))"
	}
	
	@objc var dataSize: String {
		return GenerateTree.fmt.string(fromByteCount: Int64(netSize))
	}
}
