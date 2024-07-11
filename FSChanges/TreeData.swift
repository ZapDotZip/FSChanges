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
		}
	}
	
	@objc var dataSize: String {
		get {
			return GenerateTree.fmt.string(fromByteCount: Int64(netSize))
		}
	}
}


struct GenerateTree {
	static let resourceKeys: [URLResourceKey] = [.isDirectoryKey, .fileSizeKey, .fileAllocatedSizeKey, .totalFileAllocatedSizeKey]
	static let fmt = ByteCountFormatter()
	static var suppressPermissionErrors: Bool = false
	static var viewCon: ViewController?
	static var context: NSManagedObjectContext?
	
	static func recursiveGen(path: URL, sfi: SavedFolderInfo) -> ([TreeNode], Int) {
		var nodes = [TreeNode]()
		var totalSize: Int = 0
		
		// if true, means that the item was scanned
		// if false, item hasn't been scanned yet or was deleted
		var children: [Bool] = [Bool](repeating: false, count: sfi.children?.count ?? 0)
		var childFolders: [Bool] = [Bool](repeating: false, count: sfi.childFolders?.count ?? 0)
		
		if let enumerator = FileManager.default.enumerator(at: path, includingPropertiesForKeys: resourceKeys, options: [.skipsSubdirectoryDescendants], errorHandler: { (url, err) -> Bool in
			DispatchQueue.main.async {
				print("Error recursing into directory: \(err)")
				if (err as NSError).code == 257 && !suppressPermissionErrors {
					let alert = NSAlert()
					alert.messageText = "Unable to scan item due to permissions"
					alert.informativeText = "The item could not be opened due to a permissions error. Re-run the scan with admin privileges.\n\n\(err.localizedDescription)"
					alert.alertStyle = .warning
					alert.addButton(withTitle: "Ok")
					alert.showsSuppressionButton = true
					alert.suppressionButton?.title = "Silence subsequent permissions errors"
					alert.runModal()
					if let suppressionButton = alert.suppressionButton, suppressionButton.state == .on {
						suppressPermissionErrors = true
					}
				}
			}
			return true
		}) {
			for case let i as URL in enumerator {
				do {
					let resValues = try i.resourceValues(forKeys: Set(resourceKeys))
					let lpc = i.lastPathComponent
					if resValues.isDirectory ?? false {
						// only update the display on directory scans.
						DispatchQueue.main.async {
							viewCon?.progress.doubleValue += 1.0
							viewCon?.progressLabel.stringValue = i.path
						}
						
						var found: SavedFolderInfo?
						if let list = sfi.childFolders {
							for (idx, c) in list.enumerated() {
								if (!childFolders[idx]) && (c as! SavedFolderInfo).name == lpc {
									found = (c as! SavedFolderInfo)
									childFolders[idx] = true
									break
								}
							}
						}
						if found == nil {
							found = SavedFolderInfo.init(context: context!)
							found!.name = lpc
							sfi.addToChildFolders(found!)
							childFolders.append(true)
						}
						
						let (children, childrenTotalSize) = recursiveGen(path: i, sfi: found!)
						let netSize = childrenTotalSize - Int(found?.size ?? 0)
						found!.size = Int64(childrenTotalSize)
						nodes.append(TreeNode.init(url: i, isDir: true, totalFileAllocatedSize: childrenTotalSize, netSize: netSize, children: children))
						totalSize += childrenTotalSize
						
						
					} else {
						
						var found: SavedFileInfo?
						if let list = sfi.children {
							for (idx, c) in list.enumerated() {
								if (c as! SavedFileInfo).name == lpc {
									found = (c as! SavedFileInfo)
									children[idx] = true
									break
								}
							}
						}
						if found == nil {
							found = SavedFileInfo.init(context: context!)
							found!.name = lpc
							sfi.addToChildren(found!)
							//print("new child: \(String(describing: found?.name)), \(children.count)")
						}
						
						let totalFileSize = resValues.totalFileAllocatedSize ?? 0
						let netSize = totalFileSize - Int(found?.totalFileSize ?? 0)
						found!.totalFileSize = Int64(totalFileSize)
						nodes.append(TreeNode.init(url: i, isDir: false, totalFileAllocatedSize: totalFileSize, netSize: netSize))
						
						totalSize += resValues.totalFileAllocatedSize ?? 0
					}
				} catch  {
					DispatchQueue.main.async {
						print("error: \(error)")
						let alert = NSAlert()
						alert.messageText = "Unable to scan item"
						alert.informativeText = "\(i.absoluteString) could not be opened due to an error:\n\n\(error.localizedDescription)"
						alert.alertStyle = .critical
						alert.addButton(withTitle: "Ok")
						alert.runModal()
					}
				}
			}
		}
		nodes.sort()
		return (nodes, totalSize)
	}
	
	
	static func multiFolderLoader(paths: [URL]) {
		for u in paths {
			let (children, totalSize) = GenerateTree.recursiveGen(path: u, sfi: StoredData.goToFolder(path: u))
			let netSize = children.reduce(0) { $0 + $1.netSize }
			let selectedRootNode: TreeNode = TreeNode.init(url: u, isDir: true, totalFileAllocatedSize: totalSize, netSize: netSize, children: children)
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
		let (selectedRootNode, _) = GenerateTree.recursiveGen(path: path, sfi: StoredData.goToFolder(path: path))
		DispatchQueue.main.async {
			self.viewCon!.content.append(contentsOf: selectedRootNode)
			self.viewCon!.progress.doubleValue = self.viewCon!.progress.maxValue
			self.viewCon!.progressLabel.stringValue = "All done."
		}
	}
}
