
////
////  CanvasView.swift
////  GlowArt
////
////  Created by Long Nguyễn on 16/4/25.
import Foundation
import UIKit
import AVFoundation

//protocol SymmetryCanvasDelegate: NSObjectProtocol {
//    func drawView(willBeginDrawUsingTool tool: AnyObject)
//    func finishDraw()
//    func drawing()
//    func beginDraw()
//    func stateUndo(canundo: Bool)
//    func stateRedo(canRedo: Bool)
//}

//class SymmetryCanvasView: UIView {
//    // MARK: - Data Structures
//    struct Line {
//        var color: UIColor
//        var width: CGFloat
//        var points: [CGPoint]
//        var toolType: ToolType
//        var image: UIImage?
//        var symmetryCount: Int?
//        var enableMirror: Bool?
//    }
//    
//    enum ToolType {
//        case brush
//        case image
//        case gradient
//        case eraser
//    }
//    
//    // MARK: - Properties
//    private var currentLines: [Line] = []
//    var allLines: [Line] = []
//    private var undoStack: [[Line]] = []
//    private var redoStack: [[Line]] = []
//    private var lineGroupSizes: [Int] = []
//    private var erasedLines: [Line] = [] // Lưu nét bị xóa trong touchesMoved
//    private var moveCount: Int = 0
//    private let updateCacheFrequency: Int = 5 // Cập nhật cachedCanvas mỗi 5 lần
//    
//    var toolMode: ToolType = .brush
//    var symmetryCount: Int = 6
//    var enableMirror: Bool = true
//    var brushColor: UIColor = .green
//    var brushWidth: CGFloat = 2.0
//    var brushName: String?
//    var brushImage: UIImage? {
//        didSet {
//            if let image = brushImage {
//                brushImage = image.withRenderingMode(.alwaysTemplate)
//            }
//        }
//    }
//    var distanceThreshold: CGFloat = 15.0
//    var gradientColors: [UIColor]?
//    weak var symmetryCanvaDelegate: SymmetryCanvasDelegate?
//    
//    var symmetryCenter: CGPoint {
//        return CGPoint(x: bounds.midX, y: bounds.midY)
//    }
//    
//    let colorArray: [UIColor] = [
//        .orange, .yellow, .green, .cyan, .blue, .purple, .magenta, .red
//    ]
//    
//    private var shuffledColors: [UIColor] = []
//    private var lastColor: UIColor?
//    var isRandomColor: Bool = true
//    
//    // Preview properties
//    var previewTimer: Timer?
//    var previewIndex: Int = 0
//    var previewSubIndex: Int = 0
//    var previewSpeed: Double = 1.0
//    var shouldLoopPreview: Bool = false
//    var drawingCompleted: Bool = false
//    var isPreviewing: Bool = false
//    var previewLineIndex: Int = 0
//    var previewPointIndex: Int = 0
//    var previewDisplayLink: CADisplayLink?
//    private var allLinesBackup: [Line] = []
//    var previewGroupIndex: Int = 0
//    private var previewProgress: CGFloat = 0.0
//    
//    // Layers for incremental rendering
//    private var staticLayer: CALayer = CALayer()
//    private var tempLayer: CALayer = CALayer()
//    private var cachedCanvas: UIImage?
//    
//    // MARK: - Initialization
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//        setupLayers()
//        backgroundColor = .white
//    }
//    
//    required init?(coder: NSCoder) {
//        super.init(coder: coder)
//        setupLayers()
//        backgroundColor = .white
//    }
//    
//    private func setupLayers() {
//        staticLayer.frame = bounds
//        tempLayer.frame = bounds
//        layer.addSublayer(staticLayer)
//        layer.addSublayer(tempLayer)
//    }
//    
//    // MARK: - Layout
//    override func layoutSubviews() {
//        super.layoutSubviews()
//        staticLayer.frame = bounds
//        tempLayer.frame = bounds
//        updateCachedCanvas()
//    }
//    
//    // MARK: - Drawing
//    private func drawLines(_ lines: [Line], on layer: CALayer, clear: Bool = false, includeBackground: Bool = false, isStaticLayer: Bool = false) {
//        let startTime = Date()
//        
//        let renderer = UIGraphicsImageRenderer(bounds: bounds)
//        let image = renderer.image { ctx in
//            if !clear && includeBackground {
//                cachedCanvas?.draw(in: bounds)
//            }
//            
//            guard let cgContext = UIGraphicsGetCurrentContext() else { return }
//            
//            cgContext.setAlpha(1.0)
//            
//            for line in lines {
//                let isErasing = line.color == .clear || line.toolType == .eraser
//                
//                switch line.toolType {
//                case .image:
//                    if let image = line.image {
//                        var lastDrawnPoint: CGPoint?
//                        for point in line.points {
//                            if let last = lastDrawnPoint {
//                                let dx = point.x - last.x
//                                let dy = point.y - last.y
//                                let distance = sqrt(dx*dx + dy*dy)
//                                if distance < distanceThreshold { continue }
//                            }
//                            
//                            let size = CGSize(
//                                width: brushName == "brush_2" ? line.width : line.width * 2,
//                                height: line.width * 2
//                            )
//                            let origin = CGPoint(x: point.x - size.width / 2, y: point.y - size.height / 2)
//                            let rect = CGRect(origin: origin, size: size)
//                            
//                            if isErasing {
//                                image.draw(in: rect, blendMode: .clear, alpha: 1.0)
//                            } else {
//                                line.color.setFill()
//                                image.draw(in: rect, blendMode: .normal, alpha: 1.0)
//                            }
//                            
//                            lastDrawnPoint = point
//                        }
//                    }
//                    
//                case .gradient:
//                    if let colors = gradientColors, colors.count >= 2, !isErasing {
//                        cgContext.setLineCap(.round)
//                        cgContext.setLineJoin(.round)
//                        
//                        let cgColors = colors.map { $0.cgColor } as CFArray
//                        let locations: [CGFloat] = (0..<colors.count).map { CGFloat($0) / CGFloat(colors.count - 1) }
//                        
//                        if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: cgColors, locations: locations) {
//                            let path = CGMutablePath()
//                            for (j, point) in line.points.enumerated() {
//                                j == 0 ? path.move(to: point) : path.addLine(to: point)
//                            }
//                            
//                            cgContext.setLineWidth(line.width)
//                            cgContext.addPath(path)
//                            cgContext.replacePathWithStrokedPath()
//                            cgContext.clip()
//                            cgContext.drawLinearGradient(gradient, start: line.points.first ?? .zero, end: line.points.last ?? .zero, options: [])
//                        }
//                    }
//                    
//                case .brush, .eraser:
//                    cgContext.setLineCap(.round)
//                    cgContext.setLineJoin(.round)
//                    cgContext.setLineWidth(line.width)
//                    
//                    if isErasing {
//                        cgContext.setBlendMode(.clear)
//                        cgContext.setStrokeColor(UIColor.black.cgColor)
//                    } else {
//                        cgContext.setStrokeColor(line.color.cgColor)
//                    }
//                    
//                    let path = CGMutablePath()
//                    for (i, point) in line.points.enumerated() {
//                        i == 0 ? path.move(to: point) : path.addLine(to: point)
//                    }
//                    
//                    cgContext.addPath(path)
//                    cgContext.strokePath()
//                    cgContext.setBlendMode(.normal)
//                }
//            }
//        }
//        
//        CATransaction.begin()
//        CATransaction.setDisableActions(true)
//        layer.contents = image.cgImage
//        CATransaction.commit()
//        
//        let drawTime = Date().timeIntervalSince(startTime)
//        print("Draw time: \(drawTime) seconds, lines: \(lines.count), layer: \(isStaticLayer ? "static" : "temp"), includeBackground: \(includeBackground)")
//    }
//    
//    private func updateCachedCanvas() {
//        print("Updating cachedCanvas, allLines: \(allLines.count)")
//        CATransaction.begin()
//        CATransaction.setDisableActions(true)
//        drawLines(allLines, on: staticLayer, clear: true, isStaticLayer: true)
//        cachedCanvas = staticLayer.contents.map { UIImage(cgImage: $0 as! CGImage) }
//        CATransaction.commit()
//        print("cachedCanvas updated: \(cachedCanvas != nil ? "valid" : "nil")")
//    }
//    
//    // MARK: - Erase Logic
//    private func eraseLines(at points: [CGPoint], width: CGFloat) -> [Line] {
//        var erased: [Line] = []
//        var newAllLines: [Line] = []
//        let eraseRadius = width * 1.5 // Bán kính tẩy
//        
//        for line in allLines {
//            var newPoints: [CGPoint] = []
//            var erasedPoints: [CGPoint] = []
//            var lastWasErased = false
//            
//            for (i, point) in line.points.enumerated() {
//                var pointErased = false
//                for erasePoint in points {
//                    let dx = point.x - erasePoint.x
//                    let dy = point.y - erasePoint.y
//                    let distance = sqrt(dx*dx + dy*dy)
//                    if distance < eraseRadius {
//                        pointErased = true
//                        erasedPoints.append(point)
//                        break
//                    }
//                }
//                
//                if pointErased {
//                    if !newPoints.isEmpty && !lastWasErased {
//                        // Kết thúc nét hiện tại
//                        if newPoints.count > 1 {
//                            var newLine = line
//                            newLine.points = newPoints
//                            newAllLines.append(newLine)
//                        }
//                        newPoints = []
//                    }
//                    lastWasErased = true
//                } else {
//                    if lastWasErased && !newPoints.isEmpty {
//                        // Kết thúc nét trước khi thêm điểm mới
//                        if newPoints.count > 1 {
//                            var newLine = line
//                            newLine.points = newPoints
//                            newAllLines.append(newLine)
//                        }
//                        newPoints = []
//                    }
//                    newPoints.append(point)
//                    lastWasErased = false
//                }
//            }
//            
//            // Thêm nét cuối nếu còn điểm
//            if newPoints.count > 1 {
//                var newLine = line
//                newLine.points = newPoints
//                newAllLines.append(newLine)
//            }
//            
//            // Lưu các điểm bị xóa thành một nét
//            if !erasedPoints.isEmpty {
//                var erasedLine = line
//                erasedLine.points = erasedPoints
//                erased.append(erasedLine)
//            }
//        }
//        
//        allLines = newAllLines
//        return erased
//    }
//    
//    // MARK: - Touch Handling
//    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//        guard !isPreviewing else { return }
//        guard let point = touches.first?.location(in: self) else { return }
//        symmetryCanvaDelegate?.beginDraw()
//        let symPoints = generateSymmetricPoints(from: point)
//        let color: UIColor = (toolMode == .eraser) ? .clear : brushColor
//        let toolType: ToolType = toolMode == .eraser ? .eraser : (brushImage != nil ? .image : (gradientColors != nil ? .gradient : .brush))
//        
//        currentLines = symPoints.map { pt in
//            Line(
//                color: color,
//                width: brushWidth,
//                points: [pt],
//                toolType: toolType,
//                image: toolType == .image ? brushImage : nil,
//                symmetryCount: symmetryCount,
//                enableMirror: enableMirror
//            )
//        }
//        
//        if toolMode == .eraser {
//            print("Eraser began, points: \(currentLines.first?.points.count ?? 0)")
//            drawLines(currentLines, on: tempLayer, includeBackground: true)
//        } else {
//            print("Brush began, tool: \(toolMode), points: \(currentLines.first?.points.count ?? 0)")
//            drawLines(currentLines, on: tempLayer)
//        }
//    }
//    
//    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
//        guard !isPreviewing else { return }
//        guard let point = touches.first?.location(in: self) else { return }
//        
//        if let lastPoint = currentLines.first?.points.last {
//            let dx = point.x - lastPoint.x
//            let dy = point.y - lastPoint.y
//            let distance = sqrt(dx*dx + dy*dy)
//            if distance < distanceThreshold { return }
//        }
//        
//        let symPoints = generateSymmetricPoints(from: point)
//        for i in 0..<currentLines.count {
//            currentLines[i].points.append(symPoints[i])
//        }
//        
//        if toolMode == .eraser {
//            print("Eraser moved, points: \(currentLines.first?.points.count ?? 0)")
//            
//            // Xóa các phần nét trong allLines
//            let erased = eraseLines(at: symPoints, width: brushWidth)
//            if !erased.isEmpty {
//                erasedLines.append(contentsOf: erased)
//                print("Erased \(erased.count) segments, allLines: \(allLines.count)")
//            }
//            
//            // Cập nhật cachedCanvas theo tần suất
//            moveCount += 1
//            if moveCount >= updateCacheFrequency {
//                updateCachedCanvas()
//                moveCount = 0
//            }
//            
//            // Vẽ nét tẩy trên tempLayer
//            drawLines(currentLines, on: tempLayer, includeBackground: true)
//        } else {
//            print("Brush moved, tool: \(toolMode), points: \(currentLines.first?.points.count ?? 0)")
//            drawLines(currentLines, on: tempLayer)
//        }
//    }
//    
//    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
//        guard !isPreviewing else { return }
//        
//        print("Touches ended, tool: \(toolMode), allLines: \(allLines.count), currentLines: \(currentLines.count)")
//        
//        if toolMode == .eraser {
//            // Cập nhật cachedCanvas lần cuối
//            updateCachedCanvas()
//            
//            // Lưu nét bị xóa vào undoStack
//            if !erasedLines.isEmpty {
//                if undoStack.count >= 50 {
//                    undoStack.removeFirst()
//                }
//                undoStack.append(erasedLines)
//                redoStack.removeAll()
//                lineGroupSizes.append(erasedLines.count)
//                erasedLines.removeAll()
//            }
//        } else {
//            // Xử lý các công cụ khác
//            let groupSize = currentLines.count
//            allLines.append(contentsOf: currentLines)
//            
//            if undoStack.count >= 50 {
//                undoStack.removeFirst()
//            }
//            undoStack.append(currentLines)
//            redoStack.removeAll()
//            lineGroupSizes.append(groupSize)
//            
//            updateCachedCanvas()
//        }
//        
//        currentLines.removeAll()
//        tempLayer.contents = nil
//        
//        if isRandomColor {
//            pickRandomColor()
//        }
//        symmetryCanvaDelegate?.stateUndo(canundo: !undoStack.isEmpty)
//        symmetryCanvaDelegate?.stateRedo(canRedo: !redoStack.isEmpty)
//    }
//    
//    // MARK: - Actions
//    func pickRandomColor() {
//        if shuffledColors.isEmpty {
//            shuffledColors = colorArray.shuffled()
//            if let last = lastColor, shuffledColors.first == last {
//                shuffledColors.shuffle()
//            }
//        }
//        let color = shuffledColors.removeFirst()
//        brushColor = color
//        lastColor = color
//    }
//    
//    func clearCanvas() {
//        redoStack.removeAll()
//        undoStack.removeAll()
//        allLines.removeAll()
//        lineGroupSizes.removeAll()
//        currentLines.removeAll()
//        allLinesBackup.removeAll()
//        erasedLines.removeAll()
//        staticLayer.contents = nil
//        tempLayer.contents = nil
//        cachedCanvas = nil
//        symmetryCanvaDelegate?.stateUndo(canundo: !undoStack.isEmpty)
//        symmetryCanvaDelegate?.stateRedo(canRedo: !redoStack.isEmpty)
//    }
//    
//    func undo() {
//        guard let last = undoStack.popLast() else { return }
//        redoStack.append(last)
//        for line in last {
//            if let index = allLines.lastIndex(where: { $0.points == line.points && $0.color == line.color }) {
//                allLines.remove(at: index)
//            } else {
//                allLines.append(line) // Khôi phục đoạn nét bị xóa
//            }
//        }
//        if !last.isEmpty {
//            lineGroupSizes.removeLast()
//        }
//        
//        updateCachedCanvas()
//        allLinesBackup = allLines
//        symmetryCanvaDelegate?.stateUndo(canundo: !undoStack.isEmpty)
//        symmetryCanvaDelegate?.stateRedo(canRedo: !redoStack.isEmpty)
//    }
//    
//    func redo() {
//        guard let last = redoStack.popLast() else { return }
//        undoStack.append(last)
//        for line in last {
//            if let index = allLines.lastIndex(where: { $0.points == line.points && $0.color == line.color }) {
//                allLines.remove(at: index)
//            } else {
//                allLines.append(line)
//            }
//        }
//        if !last.isEmpty {
//            lineGroupSizes.append(last.count)
//        }
//        
//        updateCachedCanvas()
//        allLinesBackup = allLines
//        symmetryCanvaDelegate?.stateUndo(canundo: !undoStack.isEmpty)
//        symmetryCanvaDelegate?.stateRedo(canRedo: !redoStack.isEmpty)
//    }
//    
//    func setEraserMode(_ enabled: Bool) {
//        toolMode = enabled ? .eraser : .brush
//        print("Tool mode set to: \(toolMode)")
//    }
//    
//    // MARK: - Symmetry Logic
//    private func generateSymmetricPoints(from point: CGPoint) -> [CGPoint] {
//        let dx = point.x - symmetryCenter.x
//        let dy = point.y - symmetryCenter.y
//        let r = hypot(dx, dy)
//        let baseAngle = atan2(dy, dx)
//        var result: [CGPoint] = []
//        
//        for i in 0..<symmetryCount {
//            let angle = baseAngle + CGFloat(i) * (2 * .pi / CGFloat(symmetryCount))
//            let x = symmetryCenter.x + r * cos(angle)
//            let y = symmetryCenter.y + r * sin(angle)
//            result.append(CGPoint(x: x, y: y))
//            
//            if enableMirror {
//                let mirroredX = symmetryCenter.x - (x - symmetryCenter.x)
//                result.append(CGPoint(x: mirroredX, y: y))
//            }
//        }
//        return result
//    }
//    
//    // MARK: - Preview
//    func preparePreview() {
//        allLinesBackup = allLines
//        print("📦 allLinesBackup loaded with \(allLinesBackup.count) lines")
//    }
//    
//    func startPreviewPlayback(speed: Double = 1.0, loop: Bool = false) {
//        staticLayer.isHidden = true
//        tempLayer.isHidden = false
//        isPreviewing = true
//        previewGroupIndex = 0
//        previewPointIndex = 0
//        previewProgress = 0.0
//        previewSpeed = max(0.05, min(speed, 5.0)) // Mở rộng phạm vi từ 1.0 lên 5.0
//        shouldLoopPreview = loop
//        currentLines = []
//        allLines = []
//        CATransaction.begin()
//        CATransaction.setDisableActions(true)
//        tempLayer.contents = nil
//        CATransaction.commit()
//        previewDisplayLink?.invalidate()
//        previewDisplayLink = CADisplayLink(target: self, selector: #selector(updatePreviewFrame))
//        previewDisplayLink?.preferredFramesPerSecond = 16
//        previewDisplayLink?.add(to: .main, forMode: .common)
//        print("▶️ Starting preview with speed: \(previewSpeed), loop: \(shouldLoopPreview)")
//    }
//    
//    @objc func updatePreviewFrame() {
//        guard previewGroupIndex < lineGroupSizes.count else {
//            if shouldLoopPreview {
//                previewGroupIndex = 0
//                previewPointIndex = 0
//                previewProgress = 0.0
//                currentLines = []
//                allLines = []
//                CATransaction.begin()
//                CATransaction.setDisableActions(true)
//                tempLayer.contents = nil
//                CATransaction.commit()
//                print("🔄 Looping preview, tempLayer cleared")
//            } else {
//                stopPreviewPlayback()
//            }
//            return
//        }
//
//        let groupSize = lineGroupSizes[previewGroupIndex]
//        let startIndex = lineGroupSizes.prefix(previewGroupIndex).reduce(0, +)
//        let endIndex = min(startIndex + groupSize, allLinesBackup.count) // Prevent out-of-range
//        guard endIndex > startIndex else {
//            previewGroupIndex += 1
//            return
//        }
//
//        let linesInGroup = Array(allLinesBackup[startIndex..<endIndex])
//        
//        var finished: Bool = true
//        var updatedLines: [Line] = []
//        
//        let baseSpeed: CGFloat = 0.02
//        previewProgress += baseSpeed * CGFloat(previewSpeed)
//        if previewProgress > 1.0 {
//            previewProgress = 1.0
//        }
//        
//        for (i, line) in linesInGroup.enumerated() {
//            let pointCount = line.points.count
//            let targetPointIndex = Int(CGFloat(pointCount) * min(previewProgress, 1.0))
//            let fraction = CGFloat(pointCount) * previewProgress - CGFloat(targetPointIndex)
//            
//            var partialPoints = Array(line.points.prefix(targetPointIndex))
//            
//            if fraction > 0 && targetPointIndex < pointCount {
//                if let lastPoint = partialPoints.last, targetPointIndex + 1 < pointCount {
//                    let nextPoint = line.points[targetPointIndex]
//                    let interpolatedPoint = CGPoint(
//                        x: lastPoint.x + (nextPoint.x - lastPoint.x) * fraction,
//                        y: lastPoint.y + (nextPoint.y - lastPoint.y) * fraction
//                    )
//                    partialPoints.append(interpolatedPoint)
//                }
//            }
//            
//            if targetPointIndex < pointCount {
//                finished = false
//            }
//            
//            var partial = line
//            partial.points = partialPoints
//            updatedLines.append(partial)
//        }
//        
//        currentLines = updatedLines
//        let linesToDraw = allLines + currentLines
//        
//        CATransaction.begin()
//        CATransaction.setDisableActions(true)
//        drawLines(linesToDraw, on: tempLayer, clear: true)
//        CATransaction.commit()
//        
//        previewPointIndex = Int(CGFloat(linesInGroup.first?.points.count ?? 0) * previewProgress)
//        
//        if finished {
//            allLines.append(contentsOf: linesInGroup)
//            currentLines.removeAll()
//            previewPointIndex = 0
//            previewProgress = 0.0
//            previewGroupIndex += 1
//            print("✅ Finished group \(previewGroupIndex), allLines count: \(allLines.count)")
//        }
//    }
//    
//    func stopPreviewPlayback() {
//        isPreviewing = false
//        previewDisplayLink?.invalidate()
//        previewDisplayLink = nil
//        currentLines.removeAll()
//        allLines = allLinesBackup
//        updateCachedCanvas()
//        
//        CATransaction.begin()
//        CATransaction.setDisableActions(true)
//        tempLayer.contents = nil
//        staticLayer.isHidden = false
//        tempLayer.isHidden = false
//        CATransaction.commit()
//        
//        print("⏹️ Preview stopped")
//    }
//    
//    // MARK: - Export
//    func exportAsImage() -> UIImage? {
//        let renderer = UIGraphicsImageRenderer(bounds: bounds)
//        let image = renderer.image { ctx in
//            layer.render(in: ctx.cgContext)
//        }
//        print("Exported image size: \(image.size)")
//        return image
//    }
//    
//    func checkLineIsEmpty() -> Bool {
//        return allLines.isEmpty
//    }
//}
//class SymmetryCanvasView: UIView {
//    // MARK: - Data Structures
//    struct Line {
//        var color: UIColor
//        var width: CGFloat
//        var points: [CGPoint]
//        var toolType: ToolType
//        var image: UIImage?
//        var symmetryCount: Int?
//        var enableMirror: Bool?
//    }
//    
//    enum ToolType {
//        case brush
//        case image
//        case gradient
//        case eraser
//    }
//    
//    // MARK: - Properties
//    private var currentLines: [Line] = []
//    var allLines: [Line] = []
//    private var undoStack: [[Line]] = []
//    private var redoStack: [[Line]] = []
//    private var lineGroupSizes: [Int] = []
//    private var moveCount: Int = 0
//    private let updateCacheFrequency: Int = 5 // Cập nhật cachedCanvas mỗi 5 lần
//    private var originalColor: UIColor = .green // Lưu màu gốc trước khi tẩy
//    private var isErasing: Bool = false // Theo dõi trạng thái tẩy
//    
//    var toolMode: ToolType = .brush
//    var symmetryCount: Int = 6
//    var enableMirror: Bool = true
//    var brushColor: UIColor = .green
//    var brushWidth: CGFloat = 2.0
//    var brushName: String?
//    var brushImage: UIImage? {
//        didSet {
//            if let image = brushImage {
//                brushImage = image.withRenderingMode(.alwaysTemplate)
//            }
//        }
//    }
//    var distanceThreshold: CGFloat = 15.0
//    var gradientColors: [UIColor]?
//    weak var symmetryCanvaDelegate: SymmetryCanvasDelegate?
//    
//    var symmetryCenter: CGPoint {
//        return CGPoint(x: bounds.midX, y: bounds.midY)
//    }
//    
//    let colorArray: [UIColor] = [
//        .orange, .yellow, .green, .cyan, .blue, .purple, .magenta, .red
//    ]
//    
//    private var shuffledColors: [UIColor] = []
//    private var lastColor: UIColor?
//    var isRandomColor: Bool = true
//    
//    // Preview properties
//    var previewTimer: Timer?
//    var previewIndex: Int = 0
//    var previewSubIndex: Int = 0
//    var previewSpeed: Double = 1.0
//    var shouldLoopPreview: Bool = false
//    var drawingCompleted: Bool = false
//    var isPreviewing: Bool = false
//    var previewLineIndex: Int = 0
//    var previewPointIndex: Int = 0
//    var previewDisplayLink: CADisplayLink?
//    private var allLinesBackup: [Line] = []
//    var previewGroupIndex: Int = 0
//    private var previewProgress: CGFloat = 0.0
//    
//    // Layers for incremental rendering
//    private var staticLayer: CALayer = CALayer()
//    private var tempLayer: CALayer = CALayer()
//    private var cachedCanvas: UIImage?
//    
//    // MARK: - Initialization
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//        setupLayers()
//        backgroundColor = .white
//    }
//    
//    required init?(coder: NSCoder) {
//        super.init(coder: coder)
//        setupLayers()
//        backgroundColor = .white
//    }
//    
//    private func setupLayers() {
//        staticLayer.frame = bounds
//        tempLayer.frame = bounds
//        layer.addSublayer(staticLayer)
//        layer.addSublayer(tempLayer)
//    }
//    
//    // MARK: - Layout
//    override func layoutSubviews() {
//        super.layoutSubviews()
//        staticLayer.frame = bounds
//        tempLayer.frame = bounds
//        staticLayer.isHidden = false // Đảm bảo staticLayer không bị ẩn
//        tempLayer.isHidden = false
//        print("layoutSubviews: staticLayer.hidden = \(staticLayer.isHidden), tempLayer.hidden = \(tempLayer.isHidden)")
//        updateCachedCanvas()
//    }
//    
//    // MARK: - Drawing
//    private func drawLines(_ lines: [Line], on layer: CALayer, clear: Bool = false, includeBackground: Bool = false, isStaticLayer: Bool = false) {
//        print("Drawing \(lines.count) lines on \(isStaticLayer ? "staticLayer" : "tempLayer"), clear: \(clear), includeBackground: \(includeBackground)")
//        
//        let startTime = Date()
//        
//        let renderer = UIGraphicsImageRenderer(bounds: bounds)
//        let image = renderer.image { ctx in
//            if !clear && includeBackground {
//                if let cachedCanvas = cachedCanvas {
//                    cachedCanvas.draw(in: bounds)
//                } else {
//                    UIColor.white.setFill()
//                    ctx.fill(bounds)
//                }
//            }
//            
//            guard let cgContext = UIGraphicsGetCurrentContext() else { return }
//            
//            cgContext.setAlpha(1.0)
//            
//            for (index, line) in lines.enumerated() {
//                guard !line.points.isEmpty else { continue }
//                print("Drawing line \(index): \(line.points.count) points, toolType: \(line.toolType)")
//                let isErasing = line.color == .clear || line.toolType == .eraser
//                
//                switch line.toolType {
//                case .image:
//                    if let image = line.image {
//                        var lastDrawnPoint: CGPoint?
//                        for point in line.points {
//                            if let last = lastDrawnPoint {
//                                let dx = point.x - last.x
//                                let dy = point.y - last.y
//                                let distance = sqrt(dx*dx + dy*dy)
//                                if distance < distanceThreshold { continue }
//                            }
//                            
//                            let size = CGSize(
//                                width: brushName == "brush_2" ? line.width : line.width * 2,
//                                height: line.width * 2
//                            )
//                            let origin = CGPoint(x: point.x - size.width / 2, y: point.y - size.height / 2)
//                            let rect = CGRect(origin: origin, size: size)
//                            
//                            if isErasing {
//                                image.draw(in: rect, blendMode: .clear, alpha: 1.0)
//                            } else {
//                                line.color.setFill()
//                                image.draw(in: rect, blendMode: .normal, alpha: 1.0)
//                            }
//                            
//                            lastDrawnPoint = point
//                        }
//                    }
//                    
//                case .gradient:
//                    if let colors = gradientColors, colors.count >= 2, !isErasing {
//                        cgContext.setLineCap(.round)
//                        cgContext.setLineJoin(.round)
//                        
//                        let cgColors = colors.map { $0.cgColor } as CFArray
//                        let locations: [CGFloat] = (0..<colors.count).map { CGFloat($0) / CGFloat(colors.count - 1) }
//                        
//                        if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: cgColors, locations: locations) {
//                            let path = CGMutablePath()
//                            if line.points.count == 1 {
//                                let point = line.points[0]
//                                path.move(to: point)
//                                path.addLine(to: CGPoint(x: point.x + 0.01, y: point.y))
//                            } else {
//                                for (j, point) in line.points.enumerated() {
//                                    j == 0 ? path.move(to: point) : path.addLine(to: point)
//                                }
//                            }
//                            
//                            cgContext.setLineWidth(line.width)
//                            cgContext.addPath(path)
//                            cgContext.replacePathWithStrokedPath()
//                            cgContext.clip()
//                            cgContext.drawLinearGradient(gradient, start: line.points.first ?? .zero, end: line.points.last ?? .zero, options: [])
//                        }
//                    }
//                    
//                case .brush, .eraser:
//                    cgContext.setLineCap(.round)
//                    cgContext.setLineJoin(.round)
//                    cgContext.setLineWidth(line.width)
//                    
//                    if isErasing {
//                        cgContext.setBlendMode(.clear)
//                        cgContext.setStrokeColor(UIColor.black.cgColor)
//                    } else {
//                        cgContext.setStrokeColor(line.color.cgColor)
//                    }
//                    
//                    let path = CGMutablePath()
//                    if line.points.count == 1 {
//                        let point = line.points[0]
//                        path.move(to: point)
//                        path.addLine(to: CGPoint(x: point.x + 0.01, y: point.y)) // Vẽ đoạn ngắn cho nét 1 điểm
//                    } else {
//                        for (i, point) in line.points.enumerated() {
//                            i == 0 ? path.move(to: point) : path.addLine(to: point)
//                        }
//                    }
//                    
//                    cgContext.addPath(path)
//                    cgContext.strokePath()
//                    cgContext.setBlendMode(.normal)
//                }
//            }
//        }
//        
//        CATransaction.begin()
//        CATransaction.setDisableActions(true)
//        layer.contents = image.cgImage
//        CATransaction.commit()
//        
//        let drawTime = Date().timeIntervalSince(startTime)
//        print("Draw time: \(drawTime) seconds, lines: \(lines.count), layer: \(isStaticLayer ? "static" : "temp"), includeBackground: \(includeBackground)")
//    }
//    
//    private func updateCachedCanvas() {
//        print("updateCachedCanvas: allLines.count = \(allLines.count), enableMirror: \(enableMirror)")
//        CATransaction.begin()
//        CATransaction.setDisableActions(true)
//        if allLines.isEmpty {
//            // Nếu allLines rỗng, vẽ nền trắng
//            let renderer = UIGraphicsImageRenderer(bounds: bounds)
//            let image = renderer.image { ctx in
//                UIColor.white.setFill()
//                ctx.fill(bounds)
//            }
//            staticLayer.contents = image.cgImage
//            cachedCanvas = image
//        } else {
//            drawLines(allLines, on: staticLayer, clear: true, isStaticLayer: true)
//            cachedCanvas = staticLayer.contents.map { UIImage(cgImage: $0 as! CGImage) }
//        }
//        CATransaction.commit()
//        print("updateCachedCanvas: completed, staticLayer.contents = \(staticLayer.contents != nil)")
//    }
//
//    
//    // MARK: - Touch Handling
//    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//        guard !isPreviewing else { return }
//        symmetryCanvaDelegate?.beginDraw()
//        guard let point = touches.first?.location(in: self) else { return }
//
//        let symPoints = generateSymmetricPoints(from: point)
//        let toolType: ToolType = brushImage != nil ? .image : (gradientColors != nil ? .gradient : .brush)
//
//        currentLines = symPoints.map { pt in
//            Line(
//                color: brushColor,
//                width: brushWidth,
//                points: [pt],
//                toolType: toolType,
//                image: toolType == .image ? brushImage : nil,
//                symmetryCount: symmetryCount,
//                enableMirror: enableMirror
//            )
//        }
//
//        print("touchesBegan: currentLines.count = \(currentLines.count), allLines.count = \(allLines.count), enableMirror: \(enableMirror)")
//        // Vẽ currentLines lên tempLayer, sử dụng cachedCanvas làm nền
//        drawLines(currentLines, on: tempLayer, clear: true, includeBackground: true)
//    }
//
//    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
//        guard !isPreviewing else { return }
//        guard let point = touches.first?.location(in: self) else { return }
//
//        if let lastPoint = currentLines.first?.points.last {
//            let dx = point.x - lastPoint.x
//            let dy = point.y - lastPoint.y
//            let distance = sqrt(dx*dx + dy*dy)
//            if distance < distanceThreshold { return }
//        }
//
//        let symPoints = generateSymmetricPoints(from: point)
//        for i in 0..<currentLines.count {
//            currentLines[i].points.append(symPoints[i])
//        }
//
//        print("touchesMoved: currentLines.count = \(currentLines.count), points per line = \(currentLines.first?.points.count ?? 0), allLines.count = \(allLines.count), enableMirror: \(enableMirror)")
//        // Vẽ currentLines lên tempLayer, sử dụng cachedCanvas làm nền
//        drawLines(currentLines, on: tempLayer, clear: true, includeBackground: true)
//
//        // Cập nhật cachedCanvas ngay lập tức
//        updateCachedCanvas()
//    }
//
//    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
//        guard !isPreviewing else { return }
//
//        print("touchesEnded: allLines.count = \(allLines.count), currentLines.count = \(currentLines.count), enableMirror: \(enableMirror)")
//        
//        // Kiểm tra currentLines không rỗng
//        guard !currentLines.isEmpty else {
//            print("touchesEnded: currentLines is empty, skipping")
//            return
//        }
//
//        // Lưu trạng thái hiện tại vào undoStack
//        if undoStack.count >= 50 {
//            undoStack.removeFirst()
//        }
//        undoStack.append(allLines)
//
//        // Thêm currentLines vào allLines
//        let groupSize = currentLines.count
//        allLines.append(contentsOf: currentLines)
//        lineGroupSizes.append(groupSize)
//        print("touchesEnded: after adding, allLines.count = \(allLines.count), lineGroupSizes = \(lineGroupSizes)")
//
//        // Cập nhật cachedCanvas
//        updateCachedCanvas()
//
//        // Xóa tempLayer
//        CATransaction.begin()
//        CATransaction.setDisableActions(true)
//        tempLayer.contents = nil
//        CATransaction.commit()
//
//        redoStack.removeAll()
//        currentLines.removeAll()
//
//        symmetryCanvaDelegate?.stateUndo(canundo: !undoStack.isEmpty)
//        symmetryCanvaDelegate?.stateRedo(canRedo: !redoStack.isEmpty)
//        print("touchesEnded: completed, staticLayer.contents = \(staticLayer.contents != nil), tempLayer.contents = \(tempLayer.contents != nil)")
//    }
//    
//    // MARK: - Actions
//    func pickRandomColor() {
//        if shuffledColors.isEmpty {
//            shuffledColors = colorArray.shuffled()
//            if let last = lastColor, shuffledColors.first == last {
//                shuffledColors.shuffle()
//            }
//        }
//        let color = shuffledColors.removeFirst()
//        brushColor = color
//        lastColor = color
//        originalColor = color // Cập nhật màu gốc
//    }
//    
//    func clearCanvas() {
//        redoStack.removeAll()
//        undoStack.removeAll()
//        allLines.removeAll()
//        lineGroupSizes.removeAll()
//        currentLines.removeAll()
//        allLinesBackup.removeAll()
//        staticLayer.contents = nil
//        tempLayer.contents = nil
//        cachedCanvas = nil
//        symmetryCanvaDelegate?.stateUndo(canundo: !undoStack.isEmpty)
//        symmetryCanvaDelegate?.stateRedo(canRedo: !redoStack.isEmpty)
//    }
//    
//    func undo() {
//        guard let lastState = undoStack.popLast() else {
//            print("Undo: no state to undo")
//            return
//        }
//        
//        redoStack.append(allLines)
//        allLines = lastState
//        
//        if !lastState.isEmpty {
//            lineGroupSizes.removeLast()
//        }
//        
//        brushColor = isErasing ? .black : originalColor // Khôi phục màu
//        updateCachedCanvas()
//        tempLayer.contents = nil
//        allLinesBackup = allLines
//        symmetryCanvaDelegate?.stateUndo(canundo: !undoStack.isEmpty)
//        symmetryCanvaDelegate?.stateRedo(canRedo: !redoStack.isEmpty)
//        print("Undo: restored state with \(allLines.count) lines, lineGroupSizes: \(lineGroupSizes), color: \(brushColor), isErasing: \(isErasing)")
//    }
//    
//    func redo() {
//        guard let nextState = redoStack.popLast() else {
//            print("Redo: no state to redo")
//            return
//        }
//        
//        undoStack.append(allLines)
//        allLines = nextState
//        
//        lineGroupSizes.append(nextState.count)
//        
//        brushColor = isErasing ? .black : originalColor // Khôi phục màu
//        updateCachedCanvas()
//        tempLayer.contents = nil
//        allLinesBackup = allLines
//        symmetryCanvaDelegate?.stateUndo(canundo: !undoStack.isEmpty)
//        symmetryCanvaDelegate?.stateRedo(canRedo: !redoStack.isEmpty)
//        print("Redo: restored state with \(allLines.count) lines, lineGroupSizes: \(lineGroupSizes), color: \(brushColor), isErasing: \(isErasing)")
//    }
//    
//    func setEraserMode(_ enabled: Bool) {
//        isErasing = enabled
//        if enabled {
//            originalColor = brushColor
//            brushColor = .black
//        } else {
//            brushColor = originalColor
//        }
//        toolMode = .brush
//        print("Tool mode set to: \(toolMode), color: \(brushColor), isErasing: \(isErasing)")
//    }
//    
//    // MARK: - Symmetry Logic
//    private func generateSymmetricPoints(from point: CGPoint) -> [CGPoint] {
//        let dx = point.x - symmetryCenter.x
//        let dy = point.y - symmetryCenter.y
//        let r = hypot(dx, dy)
//        let baseAngle = atan2(dy, dx)
//        var result: [CGPoint] = []
//        
//        for i in 0..<symmetryCount {
//            let angle = baseAngle + CGFloat(i) * (2 * .pi / CGFloat(symmetryCount))
//            let x = symmetryCenter.x + r * cos(angle)
//            let y = symmetryCenter.y + r * sin(angle)
//            result.append(CGPoint(x: x, y: y))
//            
//            if enableMirror {
//                let mirroredX = symmetryCenter.x - (x - symmetryCenter.x)
//                result.append(CGPoint(x: mirroredX, y: y))
//            }
//        }
//        
//        print("generateSymmetricPoints: created \(result.count) points, enableMirror: \(enableMirror), symmetryCount: \(symmetryCount)")
//        return result
//    }
//    
//    // MARK: - Preview
//    func preparePreview() {
//        allLinesBackup = allLines
//        print("📦 allLinesBackup loaded with \(allLinesBackup.count) lines")
//    }
//    
//    func startPreviewPlayback(speed: Double = 1.0, loop: Bool = false) {
//        staticLayer.isHidden = true
//        tempLayer.isHidden = false
//        isPreviewing = true
//        previewGroupIndex = 0
//        previewPointIndex = 0
//        previewProgress = 0.0
//        previewSpeed = max(0.1, min(speed, 2.0))
//        shouldLoopPreview = loop
//        currentLines = []
//        allLines = []
//        CATransaction.begin()
//        CATransaction.setDisableActions(true)
//        tempLayer.contents = nil
//        CATransaction.commit()
//        previewDisplayLink?.invalidate()
//        previewDisplayLink = CADisplayLink(target: self, selector: #selector(updatePreviewFrame))
//        previewDisplayLink?.preferredFramesPerSecond = 30
//        previewDisplayLink?.add(to: .main, forMode: .common)
//        print("▶️ Starting preview with speed: \(previewSpeed), loop: \(shouldLoopPreview)")
//    }
//    
//    @objc func updatePreviewFrame() {
//        guard previewGroupIndex < lineGroupSizes.count else {
//            if shouldLoopPreview {
//                previewGroupIndex = 0
//                previewPointIndex = 0
//                previewProgress = 0.0
//                currentLines = []
//                allLines = []
//                CATransaction.begin()
//                CATransaction.setDisableActions(true)
//                tempLayer.contents = nil
//                CATransaction.commit()
//                print("🔄 Looping preview, tempLayer cleared")
//            } else {
//                stopPreviewPlayback()
//            }
//            return
//        }
//        
//        let groupSize = lineGroupSizes[previewGroupIndex]
//        let startIndex = lineGroupSizes.prefix(previewGroupIndex).reduce(0, +)
//        let linesInGroup = Array(allLinesBackup[startIndex..<startIndex+groupSize])
//        
//        var finished: Bool = true
//        var updatedLines: [Line] = []
//        
//        let baseSpeed: CGFloat = 0.05
//        previewProgress += baseSpeed * CGFloat(previewSpeed)
//        if previewProgress > 1.0 {
//            previewProgress = 1.0
//        }
//        
//        for (i, line) in linesInGroup.enumerated() {
//            let pointCount = line.points.count
//            let targetPointIndex = Int(CGFloat(pointCount) * min(previewProgress, 1.0))
//            let fraction = CGFloat(pointCount) * previewProgress - CGFloat(targetPointIndex)
//            
//            var partialPoints = Array(line.points.prefix(targetPointIndex))
//            
//            if fraction > 0 && targetPointIndex < pointCount {
//                if let lastPoint = partialPoints.last, targetPointIndex + 1 < pointCount {
//                    let nextPoint = line.points[targetPointIndex]
//                    let interpolatedPoint = CGPoint(
//                        x: lastPoint.x + (nextPoint.x - lastPoint.x) * fraction,
//                        y: lastPoint.y + (nextPoint.y - lastPoint.y) * fraction
//                    )
//                    partialPoints.append(interpolatedPoint)
//                }
//            }
//            
//            if targetPointIndex < pointCount {
//                finished = false
//            }
//            
//            var partial = line
//            partial.points = partialPoints
//            updatedLines.append(partial)
//        }
//        
//        currentLines = updatedLines
//        let linesToDraw = allLines + currentLines
//        
//        CATransaction.begin()
//        CATransaction.setDisableActions(true)
//        drawLines(linesToDraw, on: tempLayer, clear: true)
//        CATransaction.commit()
//        
//        previewPointIndex = Int(CGFloat(linesInGroup.first?.points.count ?? 0) * previewProgress)
//        
//        if finished {
//            allLines.append(contentsOf: linesInGroup)
//            currentLines.removeAll()
//            previewPointIndex = 0
//            previewProgress = 0.0
//            previewGroupIndex += 1
//            print("✅ Finished group \(previewGroupIndex), allLines count: \(allLines.count)")
//        }
//    }
//    
//    func stopPreviewPlayback() {
//        isPreviewing = false
//        previewDisplayLink?.invalidate()
//        previewDisplayLink = nil
//        currentLines.removeAll()
//        allLines = allLinesBackup
//        updateCachedCanvas()
//        
//        CATransaction.begin()
//        CATransaction.setDisableActions(true)
//        tempLayer.contents = nil
//        staticLayer.isHidden = false
//        tempLayer.isHidden = false
//        CATransaction.commit()
//        
//        print("⏹️ Preview stopped")
//    }
//    
//    // MARK: - Export
//    func exportAsImage() -> UIImage? {
//        let renderer = UIGraphicsImageRenderer(bounds: bounds)
//        let image = renderer.image { ctx in
//            layer.render(in: ctx.cgContext)
//        }
//        print("Exported image size: \(image.size)")
//        return image
//    }
//    
//    func checkLineIsEmpty() -> Bool {
//        return allLines.isEmpty
//    }
//}

//extension SymmetryCanvasView {
//    func createVideoFromDrawing(aspectRatio: RatioSize, speed: Double = 0.5, completion: @escaping (URL?) -> Void) {
//        let outputURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("output_video.mov")
//        if FileManager.default.fileExists(atPath: outputURL.path) {
//            try? FileManager.default.removeItem(at: outputURL)
//        }
//        
//        let size: CGSize
//        switch aspectRatio {
//        case ._1_1:
//            size = CGSize(width: 640, height: 640)
//        case ._9_16:
//            size = CGSize(width: 640, height: 1136)
//        case ._4_5:
//            size = CGSize(width: 640, height: 800)
//        }
//        
//        do {
//            let writer = try AVAssetWriter(outputURL: outputURL, fileType: .mov)
//            
//            let settings: [String: Any] = [
//                AVVideoCodecKey: AVVideoCodecType.h264,
//                AVVideoWidthKey: size.width,
//                AVVideoHeightKey: size.height,
//                AVVideoCompressionPropertiesKey: [
//                    AVVideoAverageBitRateKey: 6000000, // Bitrate 6Mbps, tăng chất lượng
//                    AVVideoProfileLevelKey: AVVideoProfileLevelH264High40 // Profile cao hơn
//                ] as [String: Any]
//            ]
//            
//            let writerInput = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
//            let pixelBufferAdapter = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: writerInput, sourcePixelBufferAttributes: nil)
//            
//            writer.add(writerInput)
//            writer.startWriting()
//            writer.startSession(atSourceTime: .zero)
//            
//            DispatchQueue.global(qos: .userInitiated).async {
//                var frameIndex: Int64 = 0
//                let basePointsPerFrame = 3 // Số điểm cơ bản mỗi khung hình
//                let timescale: Int32 = 30 // FPS cơ bản
//                // Điều chỉnh pointsPerFrame dựa trên speed (speed nhỏ hơn -> chậm hơn)
//                let pointsPerFrame = max(1, Int(Double(basePointsPerFrame) * speed))
//                // Điều chỉnh timescale dựa trên speed
//                let adjustedTimescale = Int32(Double(timescale) * speed)
//                
//                var currentLineIndex = 0
//                var currentPointIndex = 0
//                
//                while currentLineIndex < self.allLines.count {
//                    guard let pixelBuffer = self.createPixelBufferFromLines(
//                        lineIndex: &currentLineIndex,
//                        pointIndex: &currentPointIndex,
//                        pointsPerFrame: pointsPerFrame,
//                        size: size
//                    ) else { continue }
//                    
//                    let presentationTime = CMTimeMake(value: frameIndex, timescale: adjustedTimescale)
//                    while !writerInput.isReadyForMoreMediaData {
//                        Thread.sleep(forTimeInterval: 0.02)
//                    }
//                    
//                    if !pixelBufferAdapter.append(pixelBuffer, withPresentationTime: presentationTime) {
//                        print("Error appending pixel buffer at frame \(frameIndex)")
//                    }
//                    frameIndex += 1
//                }
//                
//                writerInput.markAsFinished()
//                writer.finishWriting {
//                    DispatchQueue.main.async {
//                        print("Video finished writing.")
//                        completion(outputURL)
//                    }
//                }
//            }
//        } catch {
//            print("Error creating AVAssetWriter: \(error)")
//            DispatchQueue.main.async {
//                completion(nil)
//            }
//        }
//    }
//    
//    func createPixelBufferFromLines(lineIndex: inout Int, pointIndex: inout Int, pointsPerFrame: Int, size: CGSize) -> CVPixelBuffer? {
//        // Tính toán giới hạn của bản vẽ để căn giữa và scale
//        var allX: [CGFloat] = []
//        var allY: [CGFloat] = []
//        for line in allLines {
//            allX.append(contentsOf: line.points.map { $0.x })
//            allY.append(contentsOf: line.points.map { $0.y })
//        }
//        
//        // Kiểm tra nếu không có điểm
//        guard !allX.isEmpty, !allY.isEmpty else {
//            print("No points to draw")
//            return nil
//        }
//        
//        let minX = allX.min() ?? 0
//        let maxX = allX.max() ?? 0
//        let minY = allY.min() ?? 0
//        let maxY = allY.max() ?? 0
//        let drawnWidth = maxX - minX
//        let drawnHeight = maxY - minY
//        
//        // Tránh chia cho 0
//        guard drawnWidth > 0, drawnHeight > 0 else {
//            print("Invalid drawn dimensions: width=\(drawnWidth), height=\(drawnHeight)")
//            return nil
//        }
//        
//        // Thêm padding để tránh cắt nét vẽ gần biên
//        let padding: CGFloat = 20
//        let scale = min(
//            (size.width - padding) / drawnWidth,
//            (size.height - padding) / drawnHeight
//        )
//        
//        // Tính offset để căn giữa
//        let offsetX = (size.width - drawnWidth * scale) / 2 - minX * scale
//        let offsetY = (size.height - drawnHeight * scale) / 2 - minY * scale
//        
//        // Tạo pixel buffer
//        var pixelBuffer: CVPixelBuffer?
//        let attrs: [String: Any] = [
//            kCVPixelBufferCGImageCompatibilityKey as String: true,
//            kCVPixelBufferCGBitmapContextCompatibilityKey as String: true
//        ]
//        let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(size.width), Int(size.height), kCVPixelFormatType_32BGRA, attrs as CFDictionary, &pixelBuffer)
//        guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
//            print("Failed to create pixel buffer")
//            return nil
//        }
//        
//        CVPixelBufferLockBaseAddress(buffer, [])
//        guard let context = CGContext(
//            data: CVPixelBufferGetBaseAddress(buffer),
//            width: Int(size.width),
//            height: Int(size.height),
//            bitsPerComponent: 8,
//            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
//            space: CGColorSpaceCreateDeviceRGB(),
//            bitmapInfo: CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue
//        ) else {
//            CVPixelBufferUnlockBaseAddress(buffer, [])
//            print("Failed to create CGContext")
//            return nil
//        }
//        
//        // Đặt nền đen
//        context.setFillColor(UIColor.black.cgColor)
//        context.fill(CGRect(origin: .zero, size: size))
//        
//        // Lật trục Y và áp dụng scale
//        context.translateBy(x: 0, y: size.height)
//        context.scaleBy(x: scale, y: -scale)
//        
//        context.setLineCap(.round)
//        context.setLineJoin(.round)
//        
//        // Tính toán nhóm hiện tại
//        var groupStartIndex = 0
//        var groupIndex = 0
//        for size in lineGroupSizes {
//            if groupStartIndex + size > lineIndex {
//                break
//            }
//            groupStartIndex += size
//            groupIndex += 1
//        }
//        
//        // Vẽ các đường lên đến nhóm hiện tại
//        var currentLineIdx = 0
//        for (index, line) in allLines.enumerated() {
//            if currentLineIdx < groupStartIndex {
//                // Vẽ toàn bộ dòng nếu thuộc nhóm đã hoàn thành
//                drawLine(context: context, line: line, offsetX: offsetX / scale, offsetY: offsetY / scale)
//                currentLineIdx += 1
//                continue
//            }
//            
//            // Vẽ tất cả các Line trong nhóm hiện tại
//            let groupSize = lineGroupSizes[groupIndex]
//            if currentLineIdx >= groupStartIndex && currentLineIdx < groupStartIndex + groupSize {
//                let pointsToDraw = min(line.points.count, pointIndex + pointsPerFrame)
//                if pointsToDraw > 0 {
//                    let partialPoints = Array(line.points.prefix(pointsToDraw))
//                    var partialLine = line
//                    partialLine.points = partialPoints
//                    drawLine(context: context, line: partialLine, offsetX: offsetX / scale, offsetY: offsetY / scale)
//                }
//            }
//            
//            currentLineIdx += 1
//        }
//        
//        // Cập nhật pointIndex và lineIndex
//        pointIndex += pointsPerFrame
//        if groupIndex < lineGroupSizes.count {
//            let groupSize = lineGroupSizes[groupIndex]
//            if pointIndex >= allLines[groupStartIndex].points.count {
//                lineIndex = groupStartIndex + groupSize
//                pointIndex = 0
//                groupIndex += 1
//            }
//        }
//        
//        CVPixelBufferUnlockBaseAddress(buffer, [])
//        return buffer
//    }
//    
//    private func drawLine(context: CGContext, line: Line, offsetX: CGFloat, offsetY: CGFloat) {
//        context.saveGState()
//        
//        // Dịch chuyển các điểm theo offset
//        let translatedPoints = line.points.map { CGPoint(x: $0.x + offsetX, y: $0.y + offsetY) }
//        
//        let isErasing = line.toolType == .eraser
//        
//        switch line.toolType {
//        case .image:
//            if let image = line.image, let cgImage = image.cgImage {
//                var lastDrawnPoint: CGPoint?
//                let distanceThreshold: CGFloat = 10.0
//                
//                for point in translatedPoints {
//                    if let last = lastDrawnPoint {
//                        let dx = point.x - last.x
//                        let dy = point.y - last.y
//                        let distance = sqrt(dx*dx + dy*dy)
//                        if distance < distanceThreshold { continue }
//                    }
//                    
//                    let size = CGSize(width: line.width * 2, height: line.width * 2)
//                    let origin = CGPoint(x: point.x - size.width / 2, y: point.y - size.height / 2)
//                    let rect = CGRect(origin: origin, size: size)
//                    
//                    context.saveGState()
//                    if isErasing {
//                        context.setFillColor(UIColor.black.cgColor) // Phù hợp với nền đen
//                        context.fill(rect)
//                    } else {
//                        // Vẽ hình ảnh với màu tint
//                        if let tintedImage = image.tinted(with: line.color) {
//                            context.draw(tintedImage.cgImage!, in: rect)
//                        } else {
//                            context.draw(cgImage, in: rect)
//                        }
//                    }
//                    context.restoreGState()
//                    
//                    lastDrawnPoint = point
//                }
//            }
//            
//        case .gradient:
//            if let colors = gradientColors, colors.count >= 2, !isErasing {
//                context.setLineCap(.round)
//                context.setLineJoin(.round)
//                
//                let cgColors = colors.map { $0.cgColor } as CFArray
//                let locations: [CGFloat] = (0..<colors.count).map { CGFloat($0) / CGFloat(colors.count - 1) }
//                
//                if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: cgColors, locations: locations) {
//                    let path = CGMutablePath()
//                    for (j, point) in translatedPoints.enumerated() {
//                        j == 0 ? path.move(to: point) : path.addLine(to: point)
//                    }
//                    
//                    context.setLineWidth(line.width)
//                    context.addPath(path)
//                    context.replacePathWithStrokedPath()
//                    context.clip()
//                    context.drawLinearGradient(gradient, start: translatedPoints.first ?? .zero, end: translatedPoints.last ?? .zero, options: [])
//                }
//            }
//            
//        case .brush:
//            context.setLineCap(.round)
//            context.setLineJoin(.round)
//            context.setLineWidth(line.width)
//            context.setStrokeColor(line.color.cgColor)
//            
//            let path = CGMutablePath()
//            for (i, point) in translatedPoints.enumerated() {
//                i == 0 ? path.move(to: point) : path.addLine(to: point)
//            }
//            
//            context.addPath(path)
//            context.strokePath()
//            
//        case .eraser:
//            context.setLineCap(.round)
//            context.setLineJoin(.round)
//            context.setLineWidth(line.width)
//            context.setStrokeColor(UIColor.black.cgColor) // Phù hợp với nền đen
//            
//            let path = CGMutablePath()
//            for (i, point) in translatedPoints.enumerated() {
//                i == 0 ? path.move(to: point) : path.addLine(to: point)
//            }
//            
//            context.addPath(path)
//            context.strokePath()
//        }
//        
//        context.restoreGState()
//    }
//}
//
//extension UIImage {
//    func tinted(with color: UIColor) -> UIImage? {
//        UIGraphicsBeginImageContextWithOptions(size, false, scale)
//        guard let context = UIGraphicsGetCurrentContext() else { return nil }
//        
//        color.setFill()
//        context.translateBy(x: 0, y: size.height)
//        context.scaleBy(x: 1.0, y: -1.0)
//        
//        let rect = CGRect(origin: .zero, size: size)
//        context.clip(to: rect, mask: cgImage!)
//        context.fill(rect)
//        
//        let tintedImage = UIGraphicsGetImageFromCurrentImageContext()
//        UIGraphicsEndImageContext()
//        return tintedImage?.withRenderingMode(.alwaysOriginal)
//    }
//}








import Foundation
import UIKit
import AVFoundation

protocol SymmetryCanvasDelegate: NSObjectProtocol {
    func drawView(willBeginDrawUsingTool tool: AnyObject)
    func finishDraw()
    func drawing()
    func beginDraw()
    func stateUndo(canundo: Bool)
    func stateRedo(canRedo: Bool)
}

import UIKit

class SymmetryCanvasView: UIView {
    // MARK: - Data Structures
    struct Line {
        var color: UIColor
        var width: CGFloat
        var points: [CGPoint]
        var toolType: ToolType
        var image: UIImage?
        var symmetryCount: Int?
        var enableMirror: Bool?
    }
    
    enum ToolType {
        case brush
        case image
        case gradient
        case eraser
    }
    
    // MARK: - Properties
    private var currentLines: [Line] = []
    var allLines: [Line] = []
    private var undoStack: [[Line]] = []
    private var redoStack: [[Line]] = []
    private var lineGroupSizes: [Int] = []
    private var erasedLines: [Line] = []
    private var moveCount: Int = 0
    private let updateCacheFrequency: Int = 5
    var toolMode: ToolType = .brush
    var symmetryCount: Int = 6
    var enableMirror: Bool = true
    var brushColor: UIColor = .green
    var brushWidth: CGFloat = 2.0
    var brushName: String?
    var brushImage: UIImage? {
        didSet {
            if let image = brushImage {
                brushImage = image.withRenderingMode(.alwaysTemplate)
            }
        }
    }
    var distanceThreshold: CGFloat = 15.0
    var gradientColors: [UIColor]?
    weak var symmetryCanvaDelegate: SymmetryCanvasDelegate?
    var symmetryCenter: CGPoint {
        return CGPoint(x: bounds.midX, y: bounds.midY)
    }
    let colorArray: [UIColor] = [.orange, .yellow, .green, .cyan, .blue, .purple, .magenta, .red]
    private var shuffledColors: [UIColor] = []
    private var lastColor: UIColor?
    var isRandomColor: Bool = true
    var previewTimer: Timer?
    var previewIndex: Int = 0
    var previewSubIndex: Int = 0
    var previewSpeed: Double = 1.0
    var shouldLoopPreview: Bool = false
    var drawingCompleted: Bool = false
    var isPreviewing: Bool = false
    var previewLineIndex: Int = 0
    var previewPointIndex: Int = 0
    var previewDisplayLink: CADisplayLink?
    private var allLinesBackup: [Line] = []
    var previewGroupIndex: Int = 0
    private var previewProgress: CGFloat = 0.0
    private var staticLayer: CALayer = CALayer()
    private var tempLayer: CALayer = CALayer()
    private var cachedCanvas: UIImage?
    
    // MARK: - Glow Properties
    private let glowLayers: [(radius: CGFloat, alpha: CGFloat)] = [
        (12.0, 0.08), // Lớp ngoài cùng, lan tỏa rộng và mờ
        (8.0, 0.15),
        (4.0, 0.25),
        (2.0, 0.4)   // Lớp trong cùng, sáng hơn
    ]
    private let enableGlowBlur: Bool = true
    private var glowAnimationProgress: CGFloat = 0.0 // Biến cho hiệu ứng glow động
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayers()
        backgroundColor = .white
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayers()
        backgroundColor = .white
    }
    
    private func setupLayers() {
        staticLayer.frame = bounds
        tempLayer.frame = bounds
        layer.addSublayer(staticLayer)
        layer.addSublayer(tempLayer)
    }
    
    // MARK: - Layout
    override func layoutSubviews() {
        super.layoutSubviews()
        staticLayer.frame = bounds
        tempLayer.frame = bounds
        updateCachedCanvas()
    }
    
    // MARK: - Drawing
    private func drawLines(_ lines: [Line], on layer: CALayer, clear: Bool = false, includeBackground: Bool = false, isStaticLayer: Bool = false) {
        let startTime = Date()
        
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        let image = renderer.image { ctx in
            if !clear && includeBackground {
                cachedCanvas?.draw(in: bounds)
            }
            
            guard let cgContext = UIGraphicsGetCurrentContext() else { return }
            cgContext.setAlpha(1.0)
            
            // Vẽ glow cho tất cả các dòng trước
            if enableGlowBlur && (!isPreviewing || isStaticLayer) {
                let glowRenderer = UIGraphicsImageRenderer(bounds: bounds)
                let glowImage = glowRenderer.image { glowCtx in
                    guard let glowCgContext = UIGraphicsGetCurrentContext() else { return }
                    glowCgContext.setAlpha(1.0)
                    drawGlowLayers(lines: lines, in: glowCgContext)
                }
                if let blurredGlow = applyBlur(to: glowImage) {
                    blurredGlow.draw(in: bounds, blendMode: .normal, alpha: 1.0)
                }
            } else {
                drawGlowLayers(lines: lines, in: cgContext)
            }
            
            // Vẽ các nét vẽ chính
            for line in lines {
                let isErasing = line.color == .clear || line.toolType == .eraser
                
                switch line.toolType {
                case .image:
                    if let image = line.image {
                        var lastDrawnPoint: CGPoint?
                        for point in line.points {
                            if let last = lastDrawnPoint {
                                let dx = point.x - last.x
                                let dy = point.y - last.y
                                let distance = sqrt(dx*dx + dy*dy)
                                if distance < distanceThreshold { continue }
                            }
                            
                            let size = CGSize(
                                width: brushName == "brush_2" ? line.width : line.width * 2,
                                height: line.width * 2
                            )
                            let origin = CGPoint(x: point.x - size.width / 2, y: point.y - size.height / 2)
                            let rect = CGRect(origin: origin, size: size)
                            
                            if isErasing {
                                image.draw(in: rect, blendMode: .clear, alpha: 1.0)
                            } else {
                                line.color.setFill()
                                image.draw(in: rect, blendMode: .normal, alpha: 1.0)
                            }
                            
                            lastDrawnPoint = point
                        }
                    }
                    
                case .gradient:
                    if let colors = gradientColors, colors.count >= 2, !isErasing {
                        cgContext.setLineCap(.round)
                        cgContext.setLineJoin(.round)
                        
                        let cgColors = colors.map { $0.cgColor } as CFArray
                        let locations: [CGFloat] = (0..<colors.count).map { CGFloat($0) / CGFloat(colors.count - 1) }
                        
                        if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: cgColors, locations: locations) {
                            let path = CGMutablePath()
                            for (j, point) in line.points.enumerated() {
                                j == 0 ? path.move(to: point) : path.addLine(to: point)
                            }
                            
                            cgContext.setLineWidth(line.width)
                            cgContext.addPath(path)
                            cgContext.replacePathWithStrokedPath()
                            cgContext.clip()
                            cgContext.drawLinearGradient(gradient, start: line.points.first ?? .zero, end: line.points.last ?? .zero, options: [])
                        }
                    }
                    
                case .brush, .eraser:
                    cgContext.setLineCap(.round)
                    cgContext.setLineJoin(.round)
                    
                    if !isErasing {
                        cgContext.setLineWidth(line.width)
                        cgContext.setStrokeColor(line.color.cgColor)
                        let path = CGMutablePath()
                        for (i, point) in line.points.enumerated() {
                            i == 0 ? path.move(to: point) : path.addLine(to: point)
                        }
                        cgContext.addPath(path)
                        cgContext.strokePath()
                    } else {
                        cgContext.setBlendMode(.clear)
                        cgContext.setLineWidth(line.width)
                        cgContext.setStrokeColor(UIColor.black.cgColor)
                        let path = CGMutablePath()
                        for (i, point) in line.points.enumerated() {
                            i == 0 ? path.move(to: point) : path.addLine(to: point)
                        }
                        cgContext.addPath(path)
                        cgContext.strokePath()
                        cgContext.setBlendMode(.normal)
                    }
                }
            }
        }
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        layer.contents = image.cgImage
        CATransaction.commit()
        
        let drawTime = Date().timeIntervalSince(startTime)
        print("Draw time: \(drawTime) seconds, lines: \(lines.count), layer: \(isStaticLayer ? "static" : "temp"), includeBackground: \(includeBackground)")
    }
    
    // MARK: - Glow Drawing
    private func drawGlowLayers(lines: [Line], in cgContext: CGContext) {
        // Tạo hiệu ứng glow động
        glowAnimationProgress += isPreviewing ? 0.05 * CGFloat(previewSpeed) : 0.0
        let glowAlphaModifier = isPreviewing ? (0.8 + 0.2 * sin(glowAnimationProgress)) : 1.0
        
        for line in lines where line.toolType == .brush || line.toolType == .gradient {
            let isErasing = line.color == .clear || line.toolType == .eraser
            if isErasing { continue }
            
            let path = CGMutablePath()
            for (i, point) in line.points.enumerated() {
                i == 0 ? path.move(to: point) : path.addLine(to: point)
            }
            
            let glowColor = getGlowColor(for: line.color)
            
            for (radius, alpha) in glowLayers {
                cgContext.saveGState()
                cgContext.setLineWidth(line.width + radius)
                cgContext.setAlpha(alpha * glowAlphaModifier)
                cgContext.setStrokeColor(glowColor.cgColor)
                cgContext.setLineCap(.round)
                cgContext.setLineJoin(.round)
                cgContext.addPath(path)
                cgContext.strokePath()
                cgContext.restoreGState()
            }
        }
    }
    
    // MARK: - Glow Color
    private func getGlowColor(for color: UIColor) -> UIColor {
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        color.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        
        // Tạo màu glow sáng hơn và ít bão hòa hơn
        return UIColor(hue: hue, saturation: max(saturation * 0.5, 0.2), brightness: min(brightness * 1.2, 1.0), alpha: alpha)
    }
    
    // MARK: - Blur Effect
    private func applyBlur(to image: UIImage?) -> UIImage? {
        guard let inputImage = image, let cgImage = inputImage.cgImage else { return nil }
        
        let context = CIContext(options: nil)
        let ciImage = CIImage(cgImage: cgImage)
        
        guard let filter = CIFilter(name: "CIGaussianBlur") else { return nil }
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(15.0, forKey: kCIInputRadiusKey) // Tăng radius để glow lan tỏa hơn
        
        guard let outputImage = filter.outputImage,
              let cgOutput = context.createCGImage(outputImage, from: outputImage.extent) else { return nil }
        
        return UIImage(cgImage: cgOutput)
    }
    
    // MARK: - Update Cached Canvas
    private func updateCachedCanvas() {
        print("Updating cachedCanvas, allLines: \(allLines.count)")
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        drawLines(allLines, on: staticLayer, clear: true, isStaticLayer: true)
        cachedCanvas = staticLayer.contents.map { UIImage(cgImage: $0 as! CGImage) }
        CATransaction.commit()
        print("cachedCanvas updated: \(cachedCanvas != nil ? "valid" : "nil")")
    }
    
    // MARK: - Touch Handling
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !isPreviewing else { return }
        guard let point = touches.first?.location(in: self) else { return }
        symmetryCanvaDelegate?.beginDraw()
        let symPoints = generateSymmetricPoints(from: point)
        let color: UIColor = (toolMode == .eraser) ? .clear : brushColor
        let toolType: ToolType = toolMode == .eraser ? .eraser : (brushImage != nil ? .image : (gradientColors != nil ? .gradient : .brush))
        
        currentLines = symPoints.map { pt in
            Line(
                color: color,
                width: brushWidth,
                points: [pt],
                toolType: toolType,
                image: toolType == .image ? brushImage : nil,
                symmetryCount: symmetryCount,
                enableMirror: enableMirror
            )
        }
        
        if toolMode == .eraser {
            print("Eraser began, points: \(currentLines.first?.points.count ?? 0)")
            drawLines(currentLines, on: tempLayer, includeBackground: true)
        } else {
            print("Brush began, tool: \(toolMode), points: \(currentLines.first?.points.count ?? 0)")
            drawLines(currentLines, on: tempLayer)
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !isPreviewing else { return }
        guard let point = touches.first?.location(in: self) else { return }
        
        if let lastPoint = currentLines.first?.points.last {
            let dx = point.x - lastPoint.x
            let dy = point.y - lastPoint.y
            let distance = sqrt(dx*dx + dy*dy)
            if distance < distanceThreshold { return }
        }
        
        let symPoints = generateSymmetricPoints(from: point)
        for i in 0..<currentLines.count {
            currentLines[i].points.append(symPoints[i])
        }
        
        if toolMode == .eraser {
            print("Eraser moved, points: \(currentLines.first?.points.count ?? 0)")
            let erased = eraseLines(at: symPoints, width: brushWidth)
            if !erased.isEmpty {
                erasedLines.append(contentsOf: erased)
                print("Erased \(erased.count) segments, allLines: \(allLines.count)")
            }
            
            moveCount += 1
            if moveCount >= updateCacheFrequency {
                updateCachedCanvas()
                moveCount = 0
            }
            
            drawLines(currentLines, on: tempLayer, includeBackground: true)
        } else {
            print("Brush moved, tool: \(toolMode), points: \(currentLines.first?.points.count ?? 0)")
            drawLines(currentLines, on: tempLayer)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !isPreviewing else { return }
        
        print("Touches ended, tool: \(toolMode), allLines: \(allLines.count), currentLines: \(currentLines.count)")
        
        if toolMode == .eraser {
            updateCachedCanvas()
            if !erasedLines.isEmpty {
                if undoStack.count >= 50 {
                    undoStack.removeFirst()
                }
                undoStack.append(erasedLines)
                redoStack.removeAll()
                lineGroupSizes.append(erasedLines.count)
                erasedLines.removeAll()
            }
        } else {
            let groupSize = currentLines.count
            allLines.append(contentsOf: currentLines)
            
            if undoStack.count >= 50 {
                undoStack.removeFirst()
            }
            undoStack.append(currentLines)
            redoStack.removeAll()
            lineGroupSizes.append(groupSize)
            
            updateCachedCanvas()
        }
        
        currentLines.removeAll()
        tempLayer.contents = nil
        
        if isRandomColor {
            pickRandomColor()
        }
        symmetryCanvaDelegate?.stateUndo(canundo: !undoStack.isEmpty)
        symmetryCanvaDelegate?.stateRedo(canRedo: !redoStack.isEmpty)
    }
    
    // MARK: - Erase Logic
    private func eraseLines(at points: [CGPoint], width: CGFloat) -> [Line] {
        var erased: [Line] = []
        var newAllLines: [Line] = []
        let eraseRadius = width * 1.5
        
        for line in allLines {
            var newPoints: [CGPoint] = []
            var erasedPoints: [CGPoint] = []
            var lastWasErased = false
            
            for (i, point) in line.points.enumerated() {
                var pointErased = false
                for erasePoint in points {
                    let dx = point.x - erasePoint.x
                    let dy = point.y - erasePoint.y
                    let distance = sqrt(dx*dx + dy*dy)
                    if distance < eraseRadius {
                        pointErased = true
                        erasedPoints.append(point)
                        break
                    }
                }
                
                if pointErased {
                    if !newPoints.isEmpty && !lastWasErased {
                        if newPoints.count > 1 {
                            var newLine = line
                            newLine.points = newPoints
                            newAllLines.append(newLine)
                        }
                        newPoints = []
                    }
                    lastWasErased = true
                } else {
                    if lastWasErased && !newPoints.isEmpty {
                        if newPoints.count > 1 {
                            var newLine = line
                            newLine.points = newPoints
                            newAllLines.append(newLine)
                        }
                        newPoints = []
                    }
                    newPoints.append(point)
                    lastWasErased = false
                }
            }
            
            if newPoints.count > 1 {
                var newLine = line
                newLine.points = newPoints
                newAllLines.append(newLine)
            }
            
            if !erasedPoints.isEmpty {
                var erasedLine = line
                erasedLine.points = erasedPoints
                erased.append(erasedLine)
            }
        }
        
        allLines = newAllLines
        return erased
    }
    
    // MARK: - Actions
    func pickRandomColor() {
        if shuffledColors.isEmpty {
            shuffledColors = colorArray.shuffled()
            if let last = lastColor, shuffledColors.first == last {
                shuffledColors.shuffle()
            }
        }
        let color = shuffledColors.removeFirst()
        brushColor = color
        lastColor = color
    }
    
    func clearCanvas() {
        redoStack.removeAll()
        undoStack.removeAll()
        allLines.removeAll()
        lineGroupSizes.removeAll()
        currentLines.removeAll()
        allLinesBackup.removeAll()
        erasedLines.removeAll()
        staticLayer.contents = nil
        tempLayer.contents = nil
        cachedCanvas = nil
        symmetryCanvaDelegate?.stateUndo(canundo: !undoStack.isEmpty)
        symmetryCanvaDelegate?.stateRedo(canRedo: !redoStack.isEmpty)
    }
    
    func undo() {
        guard let last = undoStack.popLast() else { return }
        redoStack.append(last)
        for line in last {
            if let index = allLines.lastIndex(where: { $0.points == line.points && $0.color == line.color }) {
                allLines.remove(at: index)
            } else {
                allLines.append(line)
            }
        }
        if !last.isEmpty {
            lineGroupSizes.removeLast()
        }
        
        updateCachedCanvas()
        allLinesBackup = allLines
        symmetryCanvaDelegate?.stateUndo(canundo: !undoStack.isEmpty)
        symmetryCanvaDelegate?.stateRedo(canRedo: !redoStack.isEmpty)
    }
    
    func redo() {
        guard let last = redoStack.popLast() else { return }
        undoStack.append(last)
        for line in last {
            if let index = allLines.lastIndex(where: { $0.points == line.points && $0.color == line.color }) {
                allLines.remove(at: index)
            } else {
                allLines.append(line)
            }
        }
        if !last.isEmpty {
            lineGroupSizes.append(last.count)
        }
        
        updateCachedCanvas()
        allLinesBackup = allLines
        symmetryCanvaDelegate?.stateUndo(canundo: !undoStack.isEmpty)
        symmetryCanvaDelegate?.stateRedo(canRedo: !redoStack.isEmpty)
    }
    
    func setEraserMode(_ enabled: Bool) {
        toolMode = enabled ? .eraser : .brush
        print("Tool mode set to: \(toolMode)")
    }
    
    // MARK: - Symmetry Logic
    private func generateSymmetricPoints(from point: CGPoint) -> [CGPoint] {
        let dx = point.x - symmetryCenter.x
        let dy = point.y - symmetryCenter.y
        let r = hypot(dx, dy)
        let baseAngle = atan2(dy, dx)
        var result: [CGPoint] = []
        
        for i in 0..<symmetryCount {
            let angle = baseAngle + CGFloat(i) * (2 * .pi / CGFloat(symmetryCount))
            let x = symmetryCenter.x + r * cos(angle)
            let y = symmetryCenter.y + r * sin(angle)
            result.append(CGPoint(x: x, y: y))
            
            if enableMirror {
                let mirroredX = symmetryCenter.x - (x - symmetryCenter.x)
                result.append(CGPoint(x: mirroredX, y: y))
            }
        }
        return result
    }
    
    // MARK: - Preview
    func preparePreview() {
        allLinesBackup = allLines
        print("📦 allLinesBackup loaded with \(allLinesBackup.count) lines")
    }
    
    func startPreviewPlayback(speed: Double = 1.0, loop: Bool = false) {
        staticLayer.isHidden = true
        tempLayer.isHidden = false
        isPreviewing = true
        previewGroupIndex = 0
        previewPointIndex = 0
        previewProgress = 0.0
        previewSpeed = max(0.05, min(speed, 5.0))
        shouldLoopPreview = loop
        currentLines = []
        allLines = []
        glowAnimationProgress = 0.0
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        tempLayer.contents = nil
        CATransaction.commit()
        previewDisplayLink?.invalidate()
        previewDisplayLink = CADisplayLink(target: self, selector: #selector(updatePreviewFrame))
        previewDisplayLink?.preferredFramesPerSecond = 16
        previewDisplayLink?.add(to: .main, forMode: .common)
        print("▶️ Starting preview with speed: \(previewSpeed), loop: \(shouldLoopPreview)")
    }
    
    @objc func updatePreviewFrame() {
        guard previewGroupIndex < lineGroupSizes.count else {
            if shouldLoopPreview {
                previewGroupIndex = 0
                previewPointIndex = 0
                previewProgress = 0.0
                currentLines = []
                allLines = []
                glowAnimationProgress = 0.0
                CATransaction.begin()
                CATransaction.setDisableActions(true)
                tempLayer.contents = nil
                CATransaction.commit()
                print("🔄 Looping preview, tempLayer cleared")
            } else {
                stopPreviewPlayback()
            }
            return
        }

        let groupSize = lineGroupSizes[previewGroupIndex]
        let startIndex = lineGroupSizes.prefix(previewGroupIndex).reduce(0, +)
        let endIndex = min(startIndex + groupSize, allLinesBackup.count)
        guard endIndex > startIndex else {
            previewGroupIndex += 1
            return
        }

        let linesInGroup = Array(allLinesBackup[startIndex..<endIndex])
        
        var finished: Bool = true
        var updatedLines: [Line] = []
        
        let baseSpeed: CGFloat = 0.02
        previewProgress += baseSpeed * CGFloat(previewSpeed)
        if previewProgress > 1.0 {
            previewProgress = 1.0
        }
        
        for (i, line) in linesInGroup.enumerated() {
            let pointCount = line.points.count
            let targetPointIndex = Int(CGFloat(pointCount) * min(previewProgress, 1.0))
            let fraction = CGFloat(pointCount) * previewProgress - CGFloat(targetPointIndex)
            
            var partialPoints = Array(line.points.prefix(targetPointIndex))
            
            if fraction > 0 && targetPointIndex < pointCount {
                if let lastPoint = partialPoints.last, targetPointIndex + 1 < pointCount {
                    let nextPoint = line.points[targetPointIndex]
                    let interpolatedPoint = CGPoint(
                        x: lastPoint.x + (nextPoint.x - lastPoint.x) * fraction,
                        y: lastPoint.y + (nextPoint.y - lastPoint.y) * fraction
                    )
                    partialPoints.append(interpolatedPoint)
                }
            }
            
            if targetPointIndex < pointCount {
                finished = false
            }
            
            var partial = line
            partial.points = partialPoints
            updatedLines.append(partial)
        }
        
        currentLines = updatedLines
        let linesToDraw = allLines + currentLines
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        drawLines(linesToDraw, on: tempLayer, clear: true)
        CATransaction.commit()
        
        previewPointIndex = Int(CGFloat(linesInGroup.first?.points.count ?? 0) * previewProgress)
        
        if finished {
            allLines.append(contentsOf: linesInGroup)
            currentLines.removeAll()
            previewPointIndex = 0
            previewProgress = 0.0
            previewGroupIndex += 1
            print("✅ Finished group \(previewGroupIndex), allLines count: \(allLines.count)")
        }
    }
    
    func stopPreviewPlayback() {
        isPreviewing = false
        previewDisplayLink?.invalidate()
        previewDisplayLink = nil
        currentLines.removeAll()
        allLines = allLinesBackup
        glowAnimationProgress = 0.0
        updateCachedCanvas()
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        tempLayer.contents = nil
        staticLayer.isHidden = false
        tempLayer.isHidden = false
        CATransaction.commit()
        
        print("⏹️ Preview stopped")
    }
    
    // MARK: - Export
    func exportAsImage() -> UIImage? {
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        let image = renderer.image { ctx in
            layer.render(in: ctx.cgContext)
        }
        print("Exported image size: \(image.size)")
        return image
    }
    
    func checkLineIsEmpty() -> Bool {
        return allLines.isEmpty
    }
}

extension SymmetryCanvasView {
    func createVideoFromDrawing(aspectRatio: RatioSize, speed: Double = 0.5, completion: @escaping (URL?) -> Void) {
        let outputURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("output_video.mov")
        if FileManager.default.fileExists(atPath: outputURL.path) {
            try? FileManager.default.removeItem(at: outputURL)
        }
        
        let size: CGSize
        switch aspectRatio {
        case ._1_1:
            size = CGSize(width: 640, height: 640)
        case ._9_16:
            size = CGSize(width: 640, height: 1136)
        case ._4_5:
            size = CGSize(width: 640, height: 800)
        }
        
        do {
            let writer = try AVAssetWriter(outputURL: outputURL, fileType: .mov)
            
            let settings: [String: Any] = [
                AVVideoCodecKey: AVVideoCodecType.h264,
                AVVideoWidthKey: size.width,
                AVVideoHeightKey: size.height,
                AVVideoCompressionPropertiesKey: [
                    AVVideoAverageBitRateKey: 6000000, // Bitrate 6Mbps, tăng chất lượng
                    AVVideoProfileLevelKey: AVVideoProfileLevelH264High40 // Profile cao hơn
                ] as [String: Any]
            ]
            
            let writerInput = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
            let pixelBufferAdapter = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: writerInput, sourcePixelBufferAttributes: nil)
            
            writer.add(writerInput)
            writer.startWriting()
            writer.startSession(atSourceTime: .zero)
            
            DispatchQueue.global(qos: .userInitiated).async {
                var frameIndex: Int64 = 0
                let basePointsPerFrame = 3 // Số điểm cơ bản mỗi khung hình
                let timescale: Int32 = 30 // FPS cơ bản
                // Điều chỉnh pointsPerFrame dựa trên speed (speed nhỏ hơn -> chậm hơn)
                let pointsPerFrame = max(1, Int(Double(basePointsPerFrame) * speed))
                // Điều chỉnh timescale dựa trên speed
                let adjustedTimescale = Int32(Double(timescale) * speed)
                
                var currentLineIndex = 0
                var currentPointIndex = 0
                
                while currentLineIndex < self.allLines.count {
                    guard let pixelBuffer = self.createPixelBufferFromLines(
                        lineIndex: &currentLineIndex,
                        pointIndex: &currentPointIndex,
                        pointsPerFrame: pointsPerFrame,
                        size: size
                    ) else { continue }
                    
                    let presentationTime = CMTimeMake(value: frameIndex, timescale: adjustedTimescale)
                    while !writerInput.isReadyForMoreMediaData {
                        Thread.sleep(forTimeInterval: 0.02)
                    }
                    
                    if !pixelBufferAdapter.append(pixelBuffer, withPresentationTime: presentationTime) {
                        print("Error appending pixel buffer at frame \(frameIndex)")
                    }
                    frameIndex += 1
                }
                
                writerInput.markAsFinished()
                writer.finishWriting {
                    DispatchQueue.main.async {
                        print("Video finished writing.")
                        completion(outputURL)
                    }
                }
            }
        } catch {
            print("Error creating AVAssetWriter: \(error)")
            DispatchQueue.main.async {
                completion(nil)
            }
        }
    }
    
    func createPixelBufferFromLines(lineIndex: inout Int, pointIndex: inout Int, pointsPerFrame: Int, size: CGSize) -> CVPixelBuffer? {
        // Tính toán giới hạn của bản vẽ để căn giữa và scale
        var allX: [CGFloat] = []
        var allY: [CGFloat] = []
        for line in allLines {
            allX.append(contentsOf: line.points.map { $0.x })
            allY.append(contentsOf: line.points.map { $0.y })
        }
        
        // Kiểm tra nếu không có điểm
        guard !allX.isEmpty, !allY.isEmpty else {
            print("No points to draw")
            return nil
        }
        
        let minX = allX.min() ?? 0
        let maxX = allX.max() ?? 0
        let minY = allY.min() ?? 0
        let maxY = allY.max() ?? 0
        let drawnWidth = maxX - minX
        let drawnHeight = maxY - minY
        
        // Tránh chia cho 0
        guard drawnWidth > 0, drawnHeight > 0 else {
            print("Invalid drawn dimensions: width=\(drawnWidth), height=\(drawnHeight)")
            return nil
        }
        
        // Thêm padding để tránh cắt nét vẽ gần biên
        let padding: CGFloat = 20
        let scale = min(
            (size.width - padding) / drawnWidth,
            (size.height - padding) / drawnHeight
        )
        
        // Tính offset để căn giữa
        let offsetX = (size.width - drawnWidth * scale) / 2 - minX * scale
        let offsetY = (size.height - drawnHeight * scale) / 2 - minY * scale
        
        // Tạo pixel buffer
        var pixelBuffer: CVPixelBuffer?
        let attrs: [String: Any] = [
            kCVPixelBufferCGImageCompatibilityKey as String: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey as String: true
        ]
        let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(size.width), Int(size.height), kCVPixelFormatType_32BGRA, attrs as CFDictionary, &pixelBuffer)
        guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
            print("Failed to create pixel buffer")
            return nil
        }
        
        CVPixelBufferLockBaseAddress(buffer, [])
        guard let context = CGContext(
            data: CVPixelBufferGetBaseAddress(buffer),
            width: Int(size.width),
            height: Int(size.height),
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue
        ) else {
            CVPixelBufferUnlockBaseAddress(buffer, [])
            print("Failed to create CGContext")
            return nil
        }
        
        // Đặt nền đen
        context.setFillColor(UIColor.black.cgColor)
        context.fill(CGRect(origin: .zero, size: size))
        
        // Lật trục Y và áp dụng scale
        context.translateBy(x: 0, y: size.height)
        context.scaleBy(x: scale, y: -scale)
        
        context.setLineCap(.round)
        context.setLineJoin(.round)
        
        // Tính toán nhóm hiện tại
        var groupStartIndex = 0
        var groupIndex = 0
        for size in lineGroupSizes {
            if groupStartIndex + size > lineIndex {
                break
            }
            groupStartIndex += size
            groupIndex += 1
        }
        
        // Vẽ các đường lên đến nhóm hiện tại
        var currentLineIdx = 0
        for (index, line) in allLines.enumerated() {
            if currentLineIdx < groupStartIndex {
                // Vẽ toàn bộ dòng nếu thuộc nhóm đã hoàn thành
                drawLine(context: context, line: line, offsetX: offsetX / scale, offsetY: offsetY / scale)
                currentLineIdx += 1
                continue
            }
            
            // Vẽ tất cả các Line trong nhóm hiện tại
            let groupSize = lineGroupSizes[groupIndex]
            if currentLineIdx >= groupStartIndex && currentLineIdx < groupStartIndex + groupSize {
                let pointsToDraw = min(line.points.count, pointIndex + pointsPerFrame)
                if pointsToDraw > 0 {
                    let partialPoints = Array(line.points.prefix(pointsToDraw))
                    var partialLine = line
                    partialLine.points = partialPoints
                    drawLine(context: context, line: partialLine, offsetX: offsetX / scale, offsetY: offsetY / scale)
                }
            }
            
            currentLineIdx += 1
        }
        
        // Cập nhật pointIndex và lineIndex
        pointIndex += pointsPerFrame
        if groupIndex < lineGroupSizes.count {
            let groupSize = lineGroupSizes[groupIndex]
            if pointIndex >= allLines[groupStartIndex].points.count {
                lineIndex = groupStartIndex + groupSize
                pointIndex = 0
                groupIndex += 1
            }
        }
        
        CVPixelBufferUnlockBaseAddress(buffer, [])
        return buffer
    }
    
    private func drawLine(context: CGContext, line: Line, offsetX: CGFloat, offsetY: CGFloat) {
        context.saveGState()
        
        // Dịch chuyển các điểm theo offset
        let translatedPoints = line.points.map { CGPoint(x: $0.x + offsetX, y: $0.y + offsetY) }
        
        let isErasing = line.toolType == .eraser
        
        switch line.toolType {
        case .image:
            if let image = line.image, let cgImage = image.cgImage {
                var lastDrawnPoint: CGPoint?
                let distanceThreshold: CGFloat = 10.0
                
                for point in translatedPoints {
                    if let last = lastDrawnPoint {
                        let dx = point.x - last.x
                        let dy = point.y - last.y
                        let distance = sqrt(dx*dx + dy*dy)
                        if distance < distanceThreshold { continue }
                    }
                    
                    let size = CGSize(width: line.width * 2, height: line.width * 2)
                    let origin = CGPoint(x: point.x - size.width / 2, y: point.y - size.height / 2)
                    let rect = CGRect(origin: origin, size: size)
                    
                    context.saveGState()
                    if isErasing {
                        context.setFillColor(UIColor.black.cgColor) // Phù hợp với nền đen
                        context.fill(rect)
                    } else {
                        // Vẽ hình ảnh với màu tint
                        if let tintedImage = image.tinted(with: line.color) {
                            context.draw(tintedImage.cgImage!, in: rect)
                        } else {
                            context.draw(cgImage, in: rect)
                        }
                    }
                    context.restoreGState()
                    
                    lastDrawnPoint = point
                }
            }
            
        case .gradient:
            if let colors = gradientColors, colors.count >= 2, !isErasing {
                context.setLineCap(.round)
                context.setLineJoin(.round)
                
                let cgColors = colors.map { $0.cgColor } as CFArray
                let locations: [CGFloat] = (0..<colors.count).map { CGFloat($0) / CGFloat(colors.count - 1) }
                
                if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: cgColors, locations: locations) {
                    let path = CGMutablePath()
                    for (j, point) in translatedPoints.enumerated() {
                        j == 0 ? path.move(to: point) : path.addLine(to: point)
                    }
                    
                    context.setLineWidth(line.width)
                    context.addPath(path)
                    context.replacePathWithStrokedPath()
                    context.clip()
                    context.drawLinearGradient(gradient, start: translatedPoints.first ?? .zero, end: translatedPoints.last ?? .zero, options: [])
                }
            }
            
        case .brush:
            context.setLineCap(.round)
            context.setLineJoin(.round)
            context.setLineWidth(line.width)
            context.setStrokeColor(line.color.cgColor)
            
            let path = CGMutablePath()
            for (i, point) in translatedPoints.enumerated() {
                i == 0 ? path.move(to: point) : path.addLine(to: point)
            }
            
            context.addPath(path)
            context.strokePath()
            
        case .eraser:
            context.setLineCap(.round)
            context.setLineJoin(.round)
            context.setLineWidth(line.width)
            context.setStrokeColor(UIColor.black.cgColor) // Phù hợp với nền đen
            
            let path = CGMutablePath()
            for (i, point) in translatedPoints.enumerated() {
                i == 0 ? path.move(to: point) : path.addLine(to: point)
            }
            
            context.addPath(path)
            context.strokePath()
        }
        
        context.restoreGState()
    }
}

extension UIImage {
    func tinted(with color: UIColor) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        
        color.setFill()
        context.translateBy(x: 0, y: size.height)
        context.scaleBy(x: 1.0, y: -1.0)
        
        let rect = CGRect(origin: .zero, size: size)
        context.clip(to: rect, mask: cgImage!)
        context.fill(rect)
        
        let tintedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return tintedImage?.withRenderingMode(.alwaysOriginal)
    }
}
