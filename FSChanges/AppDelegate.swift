//
//  AppDelegate.swift
//  FSChanges
//

import Cocoa
import OSLog

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
	private var bgContext: NSManagedObjectContext?
	private var quitDoNotPassGo: Bool = false
	
	func applicationDidFinishLaunching(_ aNotification: Notification) {
		bgContext = (NSApp.delegate as! AppDelegate).persistentContainer.newBackgroundContext()
		
		_ = GenerateTree.init()
		GenerateTree.context = bgContext
		Scanner.context = bgContext
		Scanner.appDel = self
		GenerateTree.fetch.fetchLimit = 1
	}

	func applicationWillTerminate(_ aNotification: Notification) {
		// Insert code here to tear down your application
	}
	
	// MARK: - Core Data stack
	
	lazy var persistentContainer: NSPersistentContainer = {
		/*
		 The persistent container for the application. This implementation
		 creates and returns a container, having loaded the store for the
		 application to it. This property is optional since there are legitimate
		 error conditions that could cause the creation of the store to fail.
		*/
		let container = NSPersistentContainer(name: "FSChanges")
		container.loadPersistentStores(completionHandler: { (storeDescription, error) in
			if let error = error {
				// Replace this implementation with code to handle the error appropriately.
				// fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
				 
				/*
				 Typical reasons for an error here include:
				 * The parent directory does not exist, cannot be created, or disallows writing.
				 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
				 * The device is out of space.
				 * The store could not be migrated to the current model version.
				 Check the error message to determine what the actual problem was.
				 */
				if (error as NSError).code == 134110 {
					NSLog("Error: failed to migrate database: \(error)")
					let alert = NSAlert()
					alert.messageText = "Error: Failed to migrate database!"
					alert.informativeText = "Sorry. Your database needs to be reset. This may be caused by an update that isn't set up to migrate your database, or your database has been corrupted.\n\n\(error.localizedDescription)"
					alert.alertStyle = .critical
					alert.addButton(withTitle: "Reset Database")
					alert.addButton(withTitle: "Quit")
					if alert.runModal() == .alertFirstButtonReturn {
						if let url = storeDescription.url {
							NSLog("Deleting file(s) at: \(url)")
							try? FileManager.default.removeItem(at: url)
						}
					}
					self.quitDoNotPassGo = true
					NSApplication.shared.terminate(nil)
				} else {
					let alert = NSAlert()
					alert.messageText = "Error loading database"
					alert.informativeText = "This error hasn't been handled by the developer.\n\n\(error.localizedDescription)"
					alert.alertStyle = .critical
					alert.addButton(withTitle: "Exit")
					alert.runModal()
					fatalError("Unresolvable error \(error)")
				}
				
			}
		})
		return container
	}()
	
	// MARK: - Core Data Saving and Undo support
	
	@IBAction func saveAction(_ sender: AnyObject?) {
		// Performs the save action for the application, which is to send the save: message to the application's managed object context. Any encountered errors are presented to the user.
		//let context = persistentContainer.viewContext
		
		if !bgContext!.commitEditing() {
			NSLog("\(NSStringFromClass(type(of: self))) unable to commit editing before saving")
		}
		if bgContext!.hasChanges {
			do {
				try bgContext!.save()
				NSLog("Saved Core Data")
			} catch {
				// Customize this code block to include application-specific recovery steps.
				let nserror = error as NSError
				NSApplication.shared.presentError(nserror)
			}
		}
	}
	
	func windowWillReturnUndoManager(window: NSWindow) -> UndoManager? {
		// Returns the NSUndoManager for the application. In this case, the manager returned is that of the managed object context for the application.
		return persistentContainer.viewContext.undoManager
	}
	
	func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
		return !(bgContext?.hasChanges ?? false)
	}
	
	func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
		if quitDoNotPassGo { return .terminateNow }
		
		if !bgContext!.commitEditing() {
			NSLog("\(NSStringFromClass(type(of: self))) unable to commit editing to terminate")
			return .terminateCancel
		}
		
		if !bgContext!.hasChanges {
			return .terminateNow
		}
		
		
		
		let alert = NSAlert()
		alert.messageText = "Are you sure you want to quit?"
		alert.informativeText = "Do you want to save the updated sizes? If you don't save, the next scan will reference the sizes from your last save. If you do save, the next scan will be compared against the most recent scan you did."
		alert.alertStyle = .informational
		alert.addButton(withTitle: "Save & Quit")
		alert.addButton(withTitle: "Quit without saving")
		alert.addButton(withTitle: "Cancel")
		let res = alert.runModal()
		if res == .alertFirstButtonReturn {
			do {
				try bgContext!.save()
			} catch {
				let nserror = error as NSError
				
				// Customize this code block to include application-specific recovery steps.
				let result = sender.presentError(nserror)
				if (result) {
					return .terminateCancel
				}
				
				let question = NSLocalizedString("Could not save changes while quitting. Quit anyway?", comment: "Quit without saves error question message")
				let info = NSLocalizedString("Quitting now will lose any changes you have made since the last successful save", comment: "Quit without saves error question info");
				let quitButton = NSLocalizedString("Quit anyway", comment: "Quit anyway button title")
				let cancelButton = NSLocalizedString("Cancel", comment: "Cancel button title")
				let alert = NSAlert()
				alert.messageText = question
				alert.informativeText = info
				alert.addButton(withTitle: quitButton)
				alert.addButton(withTitle: cancelButton)
				
				let answer = alert.runModal()
				if answer == .alertSecondButtonReturn {
					return .terminateCancel
				}
			}
		} else if res == .alertThirdButtonReturn {
			return .terminateCancel
		}
		return .terminateNow
	}
}
