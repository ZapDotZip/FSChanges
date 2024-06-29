//
//  StoredData.swift
//  FSChanges
//

import Foundation
import CoreData
import Cocoa

struct StoredData {
	static let context = (NSApp.delegate as! AppDelegate).persistentContainer.viewContext
	static var rootNode: SavedFolderInfo {
		var rn: SavedFolderInfo?
		do {
			let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: "SavedFolderInfo")
			fetch.fetchLimit = 1
			fetch.predicate = NSPredicate(format: "name = %@", "/")
			let result = try context.fetch(fetch)
			if result.count == 0 {
				print("No exisiting root node. Creating a new one")
				let rootAdd = SavedFolderInfo(context: context)
				rootAdd.name = "/"
				try context.save()
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
	
	static func goToFolder(path: URL) {
		var currentNode = rootNode
		for i in path.pathComponents {
			if (currentNode.childFolders != nil) {
				childLoop: for c in currentNode.childFolders! {
					if (c as! SavedFolderInfo).name == i {
						currentNode = (c as! SavedFolderInfo)
						break childLoop
					}
				}
			}
		}
		
	}
	
}
