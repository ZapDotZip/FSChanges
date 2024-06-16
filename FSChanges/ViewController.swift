//
//  ViewController.swift
//  FSChanges
//

import Cocoa


final class ViewController: NSViewController {
	@IBOutlet weak var outlineView: NSOutlineView!
	private let treeController = NSTreeController()
	@objc dynamic var content = [TreeNode]()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		outlineView.delegate = self
		
		treeController.objectClass = TreeNode.self
		treeController.childrenKeyPath = "children"
		treeController.countKeyPath = "count"
		treeController.leafKeyPath = "isLeaf"
		outlineView.autosaveExpandedItems = false
		treeController.bind(NSBindingName(rawValue: "contentArray"), to: self, withKeyPath: "content", options: nil)
		outlineView.bind(NSBindingName(rawValue: "content"), to: treeController, withKeyPath: "arrangedObjects", options: nil)
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
				for u in openPanel.urls {
					if openPanel.urls.count > 1 {
						// need to add a false "root" for each directory they picked so all picked directories stay neat in the tree
						content.append(TreeNode.init(url: u, name: u.lastPathComponent, isDir: true, fileSize: 0, fileAllocatedSize: 0, totalFileAllocatedSize: 0, children: GenerateTree.recursiveGen(path: u)))
						
					} else {
						// they only chose one directory, so we show them the contents of that directory directly.
						content.append(contentsOf: GenerateTree.recursiveGen(path: u))
					}
				}
			}
			
		}
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
