//
//  TreeData.swift
//  FSChanges
//

import Foundation
import Cocoa


struct GenerateTree {
	static let resourceKeys: [URLResourceKey] = [.isDirectoryKey, .fileSizeKey, .fileAllocatedSizeKey, .totalFileAllocatedSizeKey]
	static let fmt = ByteCountFormatter()
	static var suppressPermissionErrors: Bool = false
	static var viewCon: ViewController!
	static var context: NSManagedObjectContext!
	static let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: "SavedFileInfo")
	
	/// Recursively scans path.
	/// - Parameters:
	///   - path: The path to scan
	///   - parent: The path's directory.
	/// - Returns:
	///   - [TreeNode]: the tree of children
	///   - Int: childrenTotalSize
	///   - Int: childrenNetSize
	///   - Int: childCount
	static func recursiveGen(path: URL, parent: SavedDirectoryInfo) -> ([TreeNode], Int, Int, Int64) {
		var nodes = [TreeNode]()
		var totalSize: Int = 0
		var netSize: Int = 0
		var count: Int64 = 0
		
		// Skip over string comparisons of files we've already seen.
		// May be used as a list to remove deleted items after the loop.
		var files: [Bool] = [Bool](repeating: false, count: parent.files?.count ?? 0)
		var subdirectories: [Bool] = [Bool](repeating: false, count: parent.subdirectories?.count ?? 0)

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
						
						let sdi: SavedDirectoryInfo = {
							if let list = parent.subdirectories {
								for (idx, c) in list.enumerated() {
									if (!subdirectories[idx]) && (c as! SavedDirectoryInfo).name == lpc {
										subdirectories[idx] = true
										return (c as! SavedDirectoryInfo)
									}
								}
							}
							let sdi = SavedDirectoryInfo.init(context: context!)
							sdi.name = lpc
							parent.addToSubdirectories(sdi)
							subdirectories.append(true)
							return sdi
						}()
						
						let (children, childrenTotalSize, childrenNetSize, childCount) = recursiveGen(path: i, parent: sdi)
						nodes.append(TreeNode.init(url: i, isDir: true, totalFileAllocatedSize: childrenTotalSize, netSize: childrenNetSize, children: children))
						sdi.count = childCount
						totalSize += childrenTotalSize
						netSize += childrenNetSize
						count += childCount + 1
					} else {
						
						DispatchQueue.main.async {
							viewCon.incrementProgress()
						}
						
						let sfi: SavedFileInfo = {
							if let list = parent.files {
								for (idx, c) in list.enumerated() {
									if (c as! SavedFileInfo).name == lpc {
										files[idx] = true
										return (c as! SavedFileInfo)
									}
								}
							}
							let sfi = SavedFileInfo.init(context: context!)
							sfi.name = lpc
							parent.addToFiles(sfi)
							return sfi
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
}
