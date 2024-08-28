//
//  StoredData.swift
//  FSChanges
//

import Foundation
import CoreData
import Cocoa

/// A static object which handles the setup for scanning directories.
struct Scanner {
	static var context: NSManagedObjectContext!
	static var appDel: AppDelegate!
	static var viewCon: ViewController!
	static var rootNode: SavedDirectoryInfo = {
		var rn: SavedDirectoryInfo?
		do {
			let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: "SavedDirectoryInfo")
			fetch.fetchLimit = 1
			fetch.predicate = NSPredicate(format: "name = %@", "/")
			let result = try context.fetch(fetch)
			if result.count == 0 {
				NSLog("No exisiting root node. Creating a new one")
				let rootAdd = SavedDirectoryInfo(context: context!)
				rootAdd.name = "/"
				appDel.saveAction(nil)
				rn = rootAdd
			} else {
				rn = (result[0] as! SavedDirectoryInfo)
			}
			
		} catch {
			// TODO: Add option to reset database
			let alert = NSAlert()
			alert.messageText = "An error occurred initalizing the database."
			alert.informativeText = error.localizedDescription
			alert.alertStyle = .critical
			alert.addButton(withTitle: "Quit")
			alert.runModal()
			NSApplication.shared.terminate(nil)
		}
		return rn!
	}()
	
	/// Returns the SavedDirectoryInfo of the folder that the path is pointing to.
	/// - Parameter path: The path of the folder.
	static func goToFolder(path: URL) -> SavedDirectoryInfo {
		var currentNode = rootNode
		for i in path.pathComponents {
			if let cn = goToFolderInnerHelper(i: i, currentNode: currentNode) {
				currentNode = cn
			} else {
				let newfolder = SavedDirectoryInfo.init(context: context!)
				newfolder.name = i
				currentNode.addToSubdirectories(newfolder)
				currentNode = newfolder
			}
		}
		
		return currentNode
	}
	
	private static func goToFolderInnerHelper(i: String, currentNode: SavedDirectoryInfo) -> SavedDirectoryInfo? {
		if (currentNode.subdirectories != nil) {
			for c in currentNode.subdirectories! {
				if (c as! SavedDirectoryInfo).name == i {
					return (c as! SavedDirectoryInfo)
				}
			}
		}
		return nil
	}
	
	private static func innerFolderLoader(_ path: URL) -> TreeNode {
		let root = Scanner.goToFolder(path: path)
		DispatchQueue.main.async {
			if root.count == 0 {
				viewCon.setIndeterminateProgressBar(true)
			} else {
				self.viewCon.resetProgressBar(maxValue: Double(root.count))
			}
		}
		
		let (scannedFolder, childrenTotalSize, childrenNetSize, itemCount) = GenerateTree.recursiveGen(path: path, folder: root)
		root.count = itemCount
		let selectedRootNode = TreeNode.init(url: path, isDir: true, totalFileAllocatedSize: childrenTotalSize, netSize: childrenNetSize, children: scannedFolder)
		return selectedRootNode
	}
	
	
	static var singleChild: TreeNode?
	
	// TODO: re-implement with drag-and-drop support
	static func multiFolderLoader(paths: [URL]) {
		DispatchQueue.global().async {
			for path in paths {
				let tn = innerFolderLoader(path)
				DispatchQueue.main.async {
					self.viewCon.setMessage("Finalizing results...")
					self.viewCon.content.append(tn)
					self.viewCon.completeProgressBar()
				}
			}
			DispatchQueue.main.async {
				self.viewCon.completeProgressBar()
			}
		}
	}
	
	static func folderLoader(path: URL) {
		DispatchQueue.global().async {
			singleChild = innerFolderLoader(path)
			DispatchQueue.main.async {
				self.viewCon.setMessage("Finalizing results...")
				self.viewCon.content.append(contentsOf: singleChild!.children)
				self.viewCon.completeProgressBar()
			}
		}
	}
}
