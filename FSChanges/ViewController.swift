//
//  ViewController.swift
//  FSChanges
//

import Cocoa


final class ViewController: NSViewController {
	@IBOutlet weak var outlineView: NSOutlineView!
	@IBOutlet var progress: NSProgressIndicator!
	@IBOutlet var progressLabel: NSTextField!
	private let treeController = NSTreeController()
	@objc dynamic var content = [TreeNode]()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		GenerateTree.viewCon = self
		outlineView.delegate = self
		
		treeController.objectClass = TreeNode.self
		treeController.childrenKeyPath = "children"
		treeController.countKeyPath = "count"
		treeController.leafKeyPath = "isLeaf"
		outlineView.autosaveExpandedItems = false
		treeController.bind(NSBindingName(rawValue: "contentArray"), to: self, withKeyPath: "content", options: nil)
		outlineView.bind(NSBindingName(rawValue: "content"), to: treeController, withKeyPath: "arrangedObjects", options: nil)
		resetProgressBar()
	}
	
	func setProgress(value: Double) {
		progress.doubleValue = value
	}
	
	func setProgressMax(max: Double) {
		progress.maxValue = max
	}
	
	func resetProgressBar() {
		progress.maxValue = 10000.0
		progress.doubleValue = 0.0
	}
	
	func completeProgressBar() {
		progress.maxValue = 100.0
		progress.doubleValue = 100.0
		progressLabel.stringValue = "Finished scan."
	}
	
	func displayProgress(value: Double, msg: String) {
		progress.doubleValue = value
		progressLabel.stringValue = msg
	}
	
	func incrementProgress() {
		progress.doubleValue += 1.0
	}
	
	func incrementProgress(msg: String) {
		progress.doubleValue += 1.0
		progressLabel.stringValue = msg
	}
	
	
	
	
	
	override var representedObject: Any? {
		didSet {
			// Update the view, if already loaded.
		}
	}
		
	@IBAction func HandleMainMenu(_ sender: NSMenuItem) {
		if sender.title == "Open…" {
			let openPanel = NSOpenPanel()
			openPanel.canChooseDirectories = true
			openPanel.canChooseFiles = false
			openPanel.allowsMultipleSelection = true
			if openPanel.runModal() == NSApplication.ModalResponse.OK {
				// reset the currently displayed list
				content = [TreeNode]()
				progress.doubleValue = 0.0
				if openPanel.urls.count > 1 {
					self.view.window?.setTitleWithRepresentedFilename(openPanel.urls[0].path)
					self.view.window?.title = "FSChanges: \(openPanel.urls.count) open directories including \(openPanel.urls[0].path)"
					let paths = openPanel.urls
					DispatchQueue.global().async {
						GenerateTree.multiFolderLoader(paths: paths)
					}
				} else {
					//self.view.window?.title = "FSChanges: \(u.path)"
					let u = openPanel.urls[0]
					self.view.window?.setTitleWithRepresentedFilename(u.path)
					
					DispatchQueue.global().async {
						GenerateTree.folderLoader(path: u)
					}
				}
			}
		}
	}
	
	override func viewDidAppear() {
		super.viewDidAppear()
		self.view.window?.title = "FSChanges"
	}
	
}

extension ViewController: NSOutlineViewDelegate {
	public func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
		var cellView: NSTableCellView?
		
		guard let identifier = tableColumn?.identifier else { return cellView }
		
		switch identifier {
		case .init("TreeNode"):
			if let view = outlineView.makeView(withIdentifier: identifier, owner: outlineView.delegate) as? NSTableCellView {
				view.textField?.bind(.value, to: view, withKeyPath: "objectValue.name", options: nil)
				view.imageView?.bind(.image, to: view, withKeyPath: "objectValue.icon", options: nil)
				cellView = view
				//tableColumn?.sortDescriptorPrototype = NSSortDescriptor.init(key: "objectValue.name", ascending: true)
			}
		case .init("size"):
			if let view = outlineView.makeView(withIdentifier: identifier, owner: outlineView.delegate) as? NSTableCellView {
				view.textField?.bind(.value, to: view, withKeyPath: "objectValue.dataSize", options: nil)
				cellView = view
				//tableColumn?.sortDescriptorPrototype = NSSortDescriptor.init(key: "objectValue.dataSize", ascending: false)
			}
		default:
			return cellView
		}
		return cellView
	}
}
