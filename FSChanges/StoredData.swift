//
//  StoredData.swift
//  FSChanges
//

import Foundation
import CoreData
import Cocoa

struct StoredData {
	static var context: NSManagedObjectContext!
	static var AppDel: AppDelegate!
	static var rootNode: SavedFolderInfo {
		var rn: SavedFolderInfo?
		do {
			let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: "SavedFolderInfo")
			fetch.fetchLimit = 1
			fetch.predicate = NSPredicate(format: "name = %@", "/")
			let result = try context.fetch(fetch)
			if result.count == 0 {
				print("No exisiting root node. Creating a new one")
				let rootAdd = SavedFolderInfo(context: context!)
				rootAdd.name = "/"
				AppDel.saveAction(nil)
				rn = rootAdd
			} else {
				rn = (result[0] as! SavedFolderInfo)
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
	}
	
	static func goToFolder(path: URL) -> SavedFolderInfo {
		var currentNode = rootNode
		for i in path.pathComponents {
			if let cn = goToFolderInnerHelper(i: i, currentNode: currentNode) {
				currentNode = cn
			} else {
				let newfolder = SavedFolderInfo.init(context: context!)
				newfolder.name = i
				currentNode.addToChildFolders(newfolder)
				currentNode = newfolder
			}
		}
		
		return currentNode
	}
	
	private static func goToFolderInnerHelper(i: String, currentNode: SavedFolderInfo) -> SavedFolderInfo? {
		if (currentNode.childFolders != nil) {
			for c in currentNode.childFolders! {
				if (c as! SavedFolderInfo).name == i {
					return (c as! SavedFolderInfo)
				}
			}
		}
		return nil
	}
	
}
