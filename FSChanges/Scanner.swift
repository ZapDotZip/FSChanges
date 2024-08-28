//
//  StoredData.swift
//  FSChanges
//

import Foundation
import CoreData
import Cocoa

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
	
	
	// TODO: re-implement with drag-and-drop support
	static func multiFolderLoader(paths: [URL]) {
		for u in paths {
			let root = Scanner.goToFolder(path: u)
			DispatchQueue.main.async {
				self.viewCon.resetProgressBar()
				self.viewCon.setProgressMax(max: Double(root.count))
			}
			
			let (scannedFolder, _, _, itemCount) = GenerateTree.recursiveGen(path: u, parent: root)
			
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
		let root = Scanner.goToFolder(path: path)
		DispatchQueue.main.async {
			self.viewCon.resetProgressBar()
			self.viewCon.setProgressMax(max: Double(root.count))
		}
		
		let (scannedFolder, _, _, itemCount) = GenerateTree.recursiveGen(path: path, parent: root)
		
		DispatchQueue.main.async {
			self.viewCon.setMessage("Finalizing results...")
			self.viewCon.content.append(contentsOf: scannedFolder)
			self.viewCon.progress.maxValue = Double(itemCount)
			self.viewCon.completeProgressBar()
		}
	}
	
}
