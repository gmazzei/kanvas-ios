import Foundation

protocol MultiEditorComposerDelegate: class {
    func didFinishExporting(media: [Result<(UIImage?, URL?, MediaInfo), Error>])
    func addButtonWasPressed(clips: [MediaClip])
    func editor(segment: CameraSegment) -> EditorViewController
}

class MultiEditorViewController: UIViewController {
    private lazy var clipsController: MediaClipsEditorViewController = {
        let clipsEditor = MediaClipsEditorViewController(showsAddButton: true)
        clipsEditor.delegate = self
        clipsEditor.view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        return clipsEditor
    }()
    
    private let clipsContainer = IgnoreTouchesView()
    private let editorContainer = IgnoreTouchesView()
    
    private let exportHandler: MultiEditorExportHandler
    
    private weak var delegate: MultiEditorComposerDelegate?

    private var segments: [CameraSegment]

    var selected: Int? {
        willSet {
            if let new = newValue {
                loadEditor(for: new)
            }
        }
    }

    func addSegment(_ segment: CameraSegment) {

        segments.append(segment)

        let clip = MediaClip(representativeFrame: segment.lastFrame,
                                                        overlayText: nil,
                                                        lastFrame: segment.lastFrame)
        
        clipsController.addNewClip(clip)
        
        selected = clipsController.getClips().indices.last
    }

    private var exportingEditors: [EditorViewController]?

    private weak var currentEditor: EditorViewController?

    init(segments: [CameraSegment],
         delegate: MultiEditorComposerDelegate,
         selected: Array<CameraSegment>.Index?) {
        
        self.segments = segments
        self.delegate = delegate

        exportHandler = MultiEditorExportHandler({ [weak delegate] result in
            delegate?.didFinishExporting(media: result)
        })
        self.selected = selected
        super.init(nibName: nil, bundle: nil)
        let clips = segments.map { segment in
            return MediaClip(representativeFrame: segment.lastFrame,
                                                            overlayText: nil,
                                                            lastFrame: segment.lastFrame)
        }
        clipsController.replace(clips: clips)
    }
        
    @available(*, unavailable, message: "use init() instead")
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.black
        
        setupContainers()
        load(childViewController: clipsController, into: clipsContainer)
        if let selectedIndex = selected {
            loadEditor(for: selectedIndex)
//            load(childViewController: editors[selectedIndex], into: editorContainer)
        }
    }

    func loadEditor(for index: Int) {
        if let editor = delegate?.editor(segment: segments[index]) {
            currentEditor?.stopPlayback()
            currentEditor?.unloadFromParentViewController()
            editor.additionalSafeAreaInsets = UIEdgeInsets(top: 0, left: 0, bottom: MediaClipsCollectionView.height + 10, right: 0)
            editor.delegate = self
            load(childViewController: editor, into: editorContainer)
            currentEditor = editor
        }
    }
        
    func setupContainers() {
        clipsContainer.backgroundColor = .clear
        clipsContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(clipsContainer)

        NSLayoutConstraint.activate([
            clipsContainer.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            clipsContainer.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            clipsContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            clipsContainer.heightAnchor.constraint(equalToConstant: MediaClipsEditorView.height)
        ])

        editorContainer.translatesAutoresizingMaskIntoConstraints = false
        view.insertSubview(editorContainer, belowSubview: clipsContainer)
        
        NSLayoutConstraint.activate([
            editorContainer.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            editorContainer.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            editorContainer.topAnchor.constraint(equalTo: view.topAnchor),
            editorContainer.bottomAnchor.constraint(equalTo: clipsContainer.bottomAnchor),
        ])
    }
    
    func deleteAllSegments() {
        clipsController.replace(clips: [])
    }
}

extension MultiEditorViewController: MediaPlayerController {
    func onPostingOptionsDismissed() {
        
    }

    func onQuickPostButtonSubmitted() {

    }

    func onQuickPostOptionsShown(visible: Bool, hintText: String?, view: UIView) {

    }

    func onQuickPostOptionsSelected(selected: Bool, hintText: String?, view: UIView) {
        
    }

    func getQuickPostButton(enableLongPress: Bool) -> UIView {
        return UIView()
    }

    func getBlogSwitcher() -> UIView {
        return UIView()
    }
}

extension MultiEditorViewController: MediaClipsEditorDelegate {
    func mediaClipWasDeleted(at index: Int) {
        segments.remove(at: index)
        var newIndex = index - 1
        if newIndex <= 0 {
            newIndex = index + 1
        }
        if segments.indices.contains(newIndex) {
            selected = newIndex
        } else {
            dismiss(animated: true, completion: nil)
        }
    }
    
    func mediaClipWasAdded(at index: Int) {
        
    }
    
    func mediaClipStartedMoving() {
    }
    
    func mediaClipFinishedMoving() {
        
    }
    
    func mediaClipWasMoved(from originIndex: Int, to destinationIndex: Int) {
        segments.move(from: originIndex, to: destinationIndex)
    }
    
    func mediaClipWasSelected(at: Int) {
        selected = at
    }
    
    @objc func nextButtonWasPressed() {
    }
    
    func addButtonWasPressed(clips: [MediaClip]) {
        delegate?.addButtonWasPressed(clips: clips)
    }
}

extension MultiEditorViewController: EditorControllerDelegate {
    func didFinishExportingVideo(url: URL?, info: MediaInfo?, action: KanvasExportAction, mediaChanged: Bool) {
    }
    
    func didFinishExportingImage(image: UIImage?, info: MediaInfo?, action: KanvasExportAction, mediaChanged: Bool) {
//        if let image = image {
//            var clips = clipsController.getClips()
//            if let selected = selected {
//                let selectedClip = editors.distance(from: editors.startIndex, to: selected)
//                clips[selectedClip] = MediaClip(representativeFrame: image, overlayText: nil, lastFrame: image)
//            }
//            clipsController.replace(clips: clips)
//        }
    }
    
    func didFinishExportingFrames(url: URL?, size: CGSize?, info: MediaInfo?, action: KanvasExportAction, mediaChanged: Bool) {
    }
    
    func dismissButtonPressed() {
        dismiss(animated: true, completion: nil)
    }
    
    func didDismissColorSelectorTooltip() {
        
    }
    
    func editorShouldShowColorSelectorTooltip() -> Bool {
        return true
    }
    
    func didEndStrokeSelectorAnimation() {
        
    }
    
    func editorShouldShowStrokeSelectorAnimation() -> Bool {
        return true
    }
    
    func tagButtonPressed() {
        
    }

    // This overrides the export behavior of the EditorViewControllers.
    func shouldExport() -> Bool {
        exportHandler.startWaiting(for: segments.count)
        exportingEditors = segments.enumerated().compactMap { (idx, segment) in
            return delegate?.editor(segment: segment)
        }
        exportingEditors?.enumerated().forEach { (idx, editor) in
            editor.export { [weak self] result in
                self?.exportHandler.handleExport(result, for: idx)
            }
        }
        return false
    }

    func archive(editor: EditorViewController) {
        
    }
    
    func addButtonPressed() {
        dismiss(animated: true, completion: nil)
    }
}
