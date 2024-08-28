//
//  TreeData.swift
//  FSChanges
//

import Foundation
import Cocoa


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


struct GenerateTree {
	static let resourceKeys: [URLResourceKey] = [.isDirectoryKey, .fileSizeKey, .fileAllocatedSizeKey, .totalFileAllocatedSizeKey]
	static let fmt = ByteCountFormatter()
	static var suppressPermissionErrors: Bool = false
	static var viewCon: ViewController!
	static var context: NSManagedObjectContext!
	static let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: "SavedFileInfo")
	static let SPIfetch = NSFetchRequest<NSFetchRequestResult>(entityName: "SelectedPathInfo")
	
	/// Recursively scans path.
	/// - Parameters:
	///   - path: The path to scan
	///   - parent: The path's directory.
	/// - Returns:
	///   - [TreeNode]: the tree of children
	///   - Int: childrenTotalSize
	///   - Int: childrenNetSize
	///   - Int: childCount
	static func recursiveGen(path: URL, sfi: SavedFolderInfo) -> ([TreeNode], Int, Int, Int) {
		var nodes = [TreeNode]()
		var totalSize: Int = 0
		var netSize: Int = 0
		var count: Int = 0
		
		// Skip over string comparisons of files we've already seen.
		// May be used as a list to remove deleted items after the loop.
		var children: [Bool] = [Bool](repeating: false, count: sfi.children?.count ?? 0)
		var childFolders: [Bool] = [Bool](repeating: false, count: sfi.childFolders?.count ?? 0)

		if let enumerator = FileManager.default.enumerator(at: path, includingPropertiesForKeys: resourceKeys, options: [.skipsSubdirectoryDescendants], errorHandler: { (url, err) -> Bool in
			DispatchQueue.main.async {
				NSLog("Error recursing into directory: \(err)")
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
					let lpc = i.lastPathComponent
					let resValues = try i.resourceValues(forKeys: Set(resourceKeys))
					if resValues.isDirectory ?? false {
						
						DispatchQueue.main.async {
							viewCon.incrementProgress(msg: i.path)
						}
						
						let found: SavedFolderInfo = {
							if let list = sfi.childFolders {
								for (idx, c) in list.enumerated() {
									if (!childFolders[idx]) && (c as! SavedFolderInfo).name == lpc {
										childFolders[idx] = true
										return (c as! SavedFolderInfo)
									}
								}
							}
							let found = SavedFolderInfo.init(context: context!)
							found.name = lpc
							sfi.addToChildFolders(found)
							childFolders.append(true)
							return found
						}()
						
						let (children, childrenTotalSize, childrenNetSize, childCount) = recursiveGen(path: i, sfi: found)
						nodes.append(TreeNode.init(url: i, isDir: true, totalFileAllocatedSize: childrenTotalSize, netSize: childrenNetSize, children: children))
						totalSize += childrenTotalSize
						netSize += childrenNetSize
						count += childCount + 1
					} else {
						
						DispatchQueue.main.async {
							viewCon.incrementProgress()
						}
						
						let sfi: SavedFileInfo = {
							if let list = sfi.children {
								for (idx, c) in list.enumerated() {
									if (c as! SavedFileInfo).name == lpc {
										children[idx] = true
										return (c as! SavedFileInfo)
									}
								}
							}
							let found = SavedFileInfo.init(context: context!)
							found.name = lpc
							sfi.addToChildren(found)
							return found
						}()
						
						let totalFileSize = resValues.totalFileAllocatedSize ?? 0
						let netFileSize = totalFileSize - Int(sfi.totalFileSize)
						if netFileSize != 0 {
							sfi.totalFileSize = Int64(totalFileSize)
						}
						nodes.append(TreeNode.init(url: i, isDir: false, totalFileAllocatedSize: totalFileSize, netSize: netFileSize))
						
						totalSize += totalFileSize
						netSize += netFileSize
						count += 1
					}
				} catch  {
					DispatchQueue.main.async {
						NSLog("error: \(error)")
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
		return (nodes, totalSize, netSize, count)
	}
	
	// TODO: re-implement with drag-and-drop support
	static func multiFolderLoader(paths: [URL]) {
		for u in paths {
			let root = StoredData.goToFolder(path: u)
			DispatchQueue.main.async {
				self.viewCon.resetProgressBar()
				self.viewCon.setProgressMax(max: Double(root.size))
			}
			
			let (scannedFolder, _, _, itemCount) = GenerateTree.recursiveGen(path: u, sfi: root)
			
			DispatchQueue.main.async {
				self.viewCon.setMessage("Finalizing results...")
				self.viewCon.content.append(contentsOf: scannedFolder)
				self.viewCon.progress.maxValue = Double(itemCount)
				self.viewCon.completeProgressBar()
			}
		}
		DispatchQueue.main.async {
			self.viewCon.completeProgressBar()
		}
	}
	
	static func folderLoader(path: URL) {
		let root = StoredData.goToFolder(path: path)
		DispatchQueue.main.async {
			self.viewCon.resetProgressBar()
			self.viewCon.setProgressMax(max: Double(root.size))
		}
		
		let (scannedFolder, _, _, itemCount) = GenerateTree.recursiveGen(path: path, sfi: root)
		
		DispatchQueue.main.async {
			self.viewCon.setMessage("Finalizing results...")
			self.viewCon.content.append(contentsOf: scannedFolder)
			self.viewCon.progress.maxValue = Double(itemCount)
			self.viewCon.completeProgressBar()
		}
	}
}
