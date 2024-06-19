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
		progress.maxValue = 10000.0
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
					for u in openPanel.urls {
						// need to add a false "root" for each directory they picked so all picked directories stay neat in the tree
						DispatchQueue.global().async {
							let selectedRootNode: TreeNode = TreeNode.init(url: u, name: u.lastPathComponent, isDir: true, fileSize: 0, fileAllocatedSize: 0, totalFileAllocatedSize: 0, children: GenerateTree.recursiveGen(path: u))
							DispatchQueue.main.async {
								self.content.append(selectedRootNode)
								self.progress.doubleValue = 0.0
							}
						}
						
					}
				} else {
					//self.view.window?.title = "FSChanges: \(u.path)"
					let u = openPanel.urls[0]
					self.view.window?.setTitleWithRepresentedFilename(u.path)
					
					DispatchQueue.global().async {
						let selectedRootNode: [TreeNode] = GenerateTree.recursiveGen(path: u)
						DispatchQueue.main.async {
							self.content.append(contentsOf: selectedRootNode)
							self.progress.doubleValue = self.progress.maxValue
						}
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
				cellView = view
			}
		case .init("size"):
			if let view = outlineView.makeView(withIdentifier: identifier, owner: outlineView.delegate) as? NSTableCellView {
				view.textField?.bind(.value, to: view, withKeyPath: "objectValue.fileSize", options: nil)
				cellView = view
			}
		default:
			return cellView
		}
		return cellView
	}
}
