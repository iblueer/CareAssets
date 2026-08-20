import AppKit

private enum PortfolioTheme {
    static let pageBackground = NSColor(calibratedWhite: 0.075, alpha: 1)
    static let sidebarBackground = NSColor(calibratedWhite: 0.055, alpha: 1)
    static let surface = NSColor.white.withAlphaComponent(0.035)
    static let raisedSurface = NSColor.white.withAlphaComponent(0.055)
    static let surfaceBorder = NSColor.white.withAlphaComponent(0.075)
    static let divider = NSColor.white.withAlphaComponent(0.08)
    static let primaryText = NSColor.white
    static let secondaryText = NSColor.white.withAlphaComponent(0.68)
    static let tertiaryText = NSColor.white.withAlphaComponent(0.46)
    static let mutedText = NSColor.white.withAlphaComponent(0.32)
    static let selectedFill = NSColor(calibratedRed: 0.07, green: 0.29, blue: 0.48, alpha: 1)
    static let selectedBorder = NSColor(calibratedRed: 0.18, green: 0.54, blue: 0.86, alpha: 0.45)
    static let primaryActionFill = NSColor(calibratedRed: 0.10, green: 0.43, blue: 0.75, alpha: 1)
    static let secondaryActionFill = NSColor.white.withAlphaComponent(0.08)
    static let actionBorder = NSColor.white.withAlphaComponent(0.12)

    static func leftAlignedParagraph(inset: CGFloat, lineSpacing: CGFloat = 0) -> NSMutableParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.alignment = .left
        style.firstLineHeadIndent = inset
        style.headIndent = inset
        style.tailIndent = -inset
        style.lineSpacing = lineSpacing
        style.lineBreakMode = .byTruncatingTail
        return style
    }
}

struct PortfolioChartPoint {
    var date: Date
    var value: Double
}

final class PortfolioChartView: NSView {
    var points: [PortfolioChartPoint] = [] {
        didSet { refreshChart() }
    }
    var currency = "" {
        didSet { refreshChart() }
    }
    var metric: PortfolioChartMetric = .marketValue {
        didSet { refreshChart() }
    }
    var lineColor = NSColor(calibratedRed: 0.30, green: 0.72, blue: 1.0, alpha: 1) {
        didSet { needsDisplay = true }
    }

    private var trackingArea: NSTrackingArea?
    private var hoverIndex: Int? {
        didSet {
            updateTooltip()
            needsDisplay = true
        }
    }
    private let tooltip = NSTextField(labelWithString: "")

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.cornerRadius = 10
        layer?.backgroundColor = PortfolioTheme.surface.cgColor
        layer?.borderColor = PortfolioTheme.surfaceBorder.cgColor
        layer?.borderWidth = 1
        tooltip.font = appFont(ofSize: 11, weight: .semibold)
        tooltip.textColor = .white
        tooltip.backgroundColor = NSColor(calibratedWhite: 0.08, alpha: 0.96)
        tooltip.drawsBackground = true
        tooltip.isBezeled = false
        tooltip.lineBreakMode = .byTruncatingTail
        tooltip.maximumNumberOfLines = 2
        tooltip.wantsLayer = true
        tooltip.layer?.cornerRadius = 6
        tooltip.isHidden = true
        addSubview(tooltip)
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let trackingArea {
            removeTrackingArea(trackingArea)
        }
        let area = NSTrackingArea(
            rect: bounds,
            options: [.activeInKeyWindow, .mouseMoved, .mouseEnteredAndExited, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(area)
        trackingArea = area
    }

    override func mouseMoved(with event: NSEvent) {
        guard points.count > 1 else { return }
        let plot = plotRect
        guard plot.width > 0 else { return }
        let progress = min(1, max(0, (event.locationInWindow.x - convert(plot.origin, to: nil).x) / plot.width))
        let index = Int((progress * CGFloat(points.count - 1)).rounded())
        hoverIndex = min(points.count - 1, max(0, index))
    }

    override func mouseExited(with event: NSEvent) {
        hoverIndex = nil
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        guard points.count > 1 else {
            drawEmptyState()
            return
        }

        let plot = plotRect
        let values = points.map(\.value)
        guard let minimumValue = values.min(), let maximumValue = values.max() else { return }
        let padding = max(abs(maximumValue - minimumValue) * 0.12, abs(maximumValue) * 0.02, 0.01)
        let minimum = minimumValue - padding
        let maximum = maximumValue + padding
        let range = max(0.0000001, maximum - minimum)

        for index in 0...3 {
            let progress = CGFloat(index) / 3
            let y = plot.minY + progress * plot.height
            let grid = NSBezierPath()
            grid.move(to: NSPoint(x: plot.minX, y: y))
            grid.line(to: NSPoint(x: plot.maxX, y: y))
            grid.lineWidth = 1
            NSColor.white.withAlphaComponent(0.075).setStroke()
            grid.stroke()

            let value = minimum + Double(progress) * range
            let text = chartNumber(value, currency: currency)
            let attributes: [NSAttributedString.Key: Any] = [
                .font: senFont(ofSize: 10),
                .foregroundColor: NSColor.white.withAlphaComponent(0.42)
            ]
            text.draw(at: NSPoint(x: 8, y: y - 6), withAttributes: attributes)
        }

        let pointLocation: (Int) -> NSPoint = { index in
            let x = plot.minX + CGFloat(index) / CGFloat(self.points.count - 1) * plot.width
            let y = plot.minY + CGFloat((self.points[index].value - minimum) / range) * plot.height
            return NSPoint(x: x, y: y)
        }

        if minimum < 0, maximum > 0 {
            let zeroY = plot.minY + CGFloat((0 - minimum) / range) * plot.height
            let zero = NSBezierPath()
            zero.move(to: NSPoint(x: plot.minX, y: zeroY))
            zero.line(to: NSPoint(x: plot.maxX, y: zeroY))
            zero.lineWidth = 1
            zero.setLineDash([4, 3], count: 2, phase: 0)
            NSColor.white.withAlphaComponent(0.24).setStroke()
            zero.stroke()
        }

        let line = NSBezierPath()
        line.lineWidth = 2
        line.lineJoinStyle = .round
        line.lineCapStyle = .round
        for index in points.indices {
            let point = pointLocation(index)
            if index == points.startIndex {
                line.move(to: point)
            } else {
                line.line(to: point)
            }
        }

        let fill = line.copy() as! NSBezierPath
        fill.line(to: NSPoint(x: plot.maxX, y: plot.minY))
        fill.line(to: NSPoint(x: plot.minX, y: plot.minY))
        fill.close()
        lineColor.withAlphaComponent(0.15).setFill()
        fill.fill()
        lineColor.setStroke()
        line.stroke()

        if let hoverIndex {
            let point = pointLocation(hoverIndex)
            let crosshair = NSBezierPath()
            crosshair.move(to: NSPoint(x: point.x, y: plot.minY))
            crosshair.line(to: NSPoint(x: point.x, y: plot.maxY))
            crosshair.lineWidth = 1
            crosshair.setLineDash([3, 3], count: 2, phase: 0)
            NSColor.white.withAlphaComponent(0.45).setStroke()
            crosshair.stroke()
            lineColor.setFill()
            NSBezierPath(ovalIn: NSRect(x: point.x - 4, y: point.y - 4, width: 8, height: 8)).fill()
        }
    }

    private var plotRect: NSRect {
        bounds.insetBy(dx: 12, dy: 16).offsetBy(dx: 28, dy: 0)
    }

    private func refreshChart() {
        hoverIndex = nil
        needsDisplay = true
    }

    private func updateTooltip() {
        guard let hoverIndex, points.indices.contains(hoverIndex) else {
            tooltip.isHidden = true
            return
        }
        let point = points[hoverIndex]
        let date = DateFormatter.portfolioTooltip.string(from: point.date)
        let value = metric == .totalPnl
            ? formatSignedCurrencyWithCode(point.value, currencyCode: currency, compact: false)
            : formatCurrencyWithCode(point.value, currencyCode: currency, compact: false)
        tooltip.stringValue = "\(date)\n\(metric.title)：\(value)"
        tooltip.sizeToFit()
        tooltip.frame.size.width = min(188, max(130, tooltip.frame.width + 18))
        tooltip.frame.size.height = 38
        let plot = plotRect
        let x = plot.minX + CGFloat(hoverIndex) / CGFloat(max(1, points.count - 1)) * plot.width
        let y = plot.maxY - tooltip.frame.height - 8
        tooltip.frame.origin = NSPoint(
            x: min(max(8, x - tooltip.frame.width / 2), bounds.width - tooltip.frame.width - 8),
            y: max(8, y)
        )
        tooltip.isHidden = false
    }

    private func drawEmptyState() {
        let text = NSTextField(labelWithString: "暂无统计数据，数据会在行情刷新后逐步累积")
        text.font = appFont(ofSize: 12, weight: .medium)
        text.textColor = NSColor.white.withAlphaComponent(0.42)
        text.sizeToFit()
        let textRect = NSRect(
            x: max(12, (bounds.width - text.frame.width) / 2),
            y: max(12, (bounds.height - text.frame.height) / 2),
            width: text.frame.width,
            height: text.frame.height
        )
        text.stringValue.draw(in: textRect, withAttributes: [
            .font: text.font ?? appFont(ofSize: 12),
            .foregroundColor: text.textColor ?? NSColor.white.withAlphaComponent(0.42)
        ])
    }
}

private extension DateFormatter {
    static let portfolioTooltip: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter
    }()
    static let portfolioRow: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd HH:mm"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter
    }()
}

private func chartNumber(_ value: Double, currency: String) -> String {
    if abs(value) >= 1_000_000 {
        return "\(currency) \(String(format: "%.1fM", value / 1_000_000))"
    }
    if abs(value) >= 10_000 {
        return "\(currency) \(String(format: "%.1fK", value / 1_000))"
    }
    return formatNumber(value, minFraction: 0, maxFraction: 2)
}

final class PortfolioMainWindowController: NSWindowController {
    let portfolioViewController = PortfolioMainViewController()

    init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1024, height: 720),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "CareAssets"
        window.minSize = NSSize(width: 860, height: 580)
        window.isReleasedWhenClosed = false
        window.appearance = NSAppearance(named: .darkAqua)
        window.contentViewController = portfolioViewController
        super.init(window: window)
    }

    required init?(coder: NSCoder) {
        nil
    }

    func present() {
        let wasVisible = window?.isVisible == true
        showWindow(nil)
        if !wasVisible {
            window?.setContentSize(NSSize(width: 1024, height: 720))
            window?.center()
        }
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

final class PortfolioMainViewController: NSViewController {
    private enum Section: String {
        case overview = "总览"
        case positions = "持仓"
        case transactions = "交易记录"
    }

    var onAddTransaction: ((PortfolioTransaction) -> Void)?
    var onUpdateTransaction: ((PortfolioTransaction) -> Void)?
    var onDeleteTransaction: ((UUID) -> Void)?
    var onRefresh: (() -> Void)?
    var onRequestPositionChart: ((String, StockChartPeriod) -> Void)?

    private var section: Section = .overview
    private var trackedAssets: [TrackedAsset] = []
    private var displayAssets: [DisplayAsset] = []
    private var summary = PortfolioSummary.empty
    private var transactions: [PortfolioTransaction] = []
    private var snapshots: [PortfolioSnapshot] = []
    private var positionChartStates: [String: StockChartState] = [:]
    private var selectedPositionID: String?
    private var positionChartPeriod: StockChartPeriod = .month
    private var requestedPositionChartKey: String?
    private var selectedMetric: PortfolioChartMetric = .marketValue
    private var selectedCurrency = ""
    private var sectionButtons: [Section: NSButton] = [:]
    private weak var contentView: NSView?
    private weak var titleLabel: NSTextField?

    override func loadView() {
        let root = NSView()
        root.wantsLayer = true
        root.layer?.backgroundColor = PortfolioTheme.pageBackground.cgColor
        view = root
        buildShell()
    }

    func update(
        trackedAssets: [TrackedAsset],
        displayAssets: [DisplayAsset],
        summary: PortfolioSummary,
        transactions: [PortfolioTransaction],
        snapshots: [PortfolioSnapshot],
        positionChartStates: [String: StockChartState]
    ) {
        self.trackedAssets = trackedAssets
        self.displayAssets = displayAssets
        self.summary = summary
        self.transactions = transactions
        self.snapshots = snapshots
        self.positionChartStates = positionChartStates
        let visiblePositions = summary.positions.filter { $0.quantity > 0 }
        if let selectedPositionID,
           visiblePositions.contains(where: { $0.assetID == selectedPositionID }) {
            self.selectedPositionID = selectedPositionID
        } else {
            self.selectedPositionID = visiblePositions.first?.assetID
            self.requestedPositionChartKey = nil
        }
        if selectedCurrency.isEmpty || summary.currencies[selectedCurrency] == nil {
            selectedCurrency = summary.primaryCurrency ?? ""
        }
        if isViewLoaded {
            renderContent()
        }
    }

    private func buildShell() {
        let sidebar = NSView()
        sidebar.wantsLayer = true
        sidebar.layer?.backgroundColor = PortfolioTheme.sidebarBackground.cgColor
        sidebar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(sidebar)

        let divider = NSView()
        divider.wantsLayer = true
        divider.layer?.backgroundColor = PortfolioTheme.divider.cgColor
        divider.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(divider)

        let content = NSView()
        content.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(content)
        contentView = content

        NSLayoutConstraint.activate([
            sidebar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            sidebar.topAnchor.constraint(equalTo: view.topAnchor),
            sidebar.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            sidebar.widthAnchor.constraint(equalToConstant: 190),
            divider.leadingAnchor.constraint(equalTo: sidebar.trailingAnchor),
            divider.topAnchor.constraint(equalTo: view.topAnchor),
            divider.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            divider.widthAnchor.constraint(equalToConstant: 1),
            content.leadingAnchor.constraint(equalTo: divider.trailingAnchor),
            content.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            content.topAnchor.constraint(equalTo: view.topAnchor),
            content.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        let brand = NSTextField(labelWithString: "CareAssets")
        brand.font = appFont(ofSize: 20, weight: .bold)
        brand.textColor = .white
        brand.translatesAutoresizingMaskIntoConstraints = false
        sidebar.addSubview(brand)

        let subtitle = NSTextField(labelWithString: "盯盘 · 记账 · 复盘")
        subtitle.font = appFont(ofSize: 11, weight: .medium)
        subtitle.textColor = NSColor.white.withAlphaComponent(0.42)
        subtitle.translatesAutoresizingMaskIntoConstraints = false
        sidebar.addSubview(subtitle)

        let menu = NSStackView()
        menu.orientation = .vertical
        menu.alignment = .width
        menu.spacing = 5
        menu.translatesAutoresizingMaskIntoConstraints = false
        sidebar.addSubview(menu)
        for item in [Section.overview, .positions, .transactions] {
            let button = NSButton(title: item.rawValue, target: self, action: #selector(sectionClicked(_:)))
            button.identifier = NSUserInterfaceItemIdentifier(item.rawValue)
            button.alignment = .left
            button.font = appFont(ofSize: 13, weight: .semibold)
            button.isBordered = false
            button.focusRingType = .none
            button.wantsLayer = true
            button.layer?.cornerRadius = 8
            button.heightAnchor.constraint(equalToConstant: 36).isActive = true
            sectionButtons[item] = button
            menu.addArrangedSubview(button)
            button.widthAnchor.constraint(equalTo: menu.widthAnchor).isActive = true
        }

        let tipDivider = NSView()
        tipDivider.wantsLayer = true
        tipDivider.layer?.backgroundColor = PortfolioTheme.divider.cgColor
        tipDivider.translatesAutoresizingMaskIntoConstraints = false
        sidebar.addSubview(tipDivider)

        let tip = NSTextField(wrappingLabelWithString: "行情价格来自当前数据源。统计曲线从启用记录后开始累积。")
        tip.font = appFont(ofSize: 11, weight: .regular)
        tip.textColor = PortfolioTheme.mutedText
        tip.translatesAutoresizingMaskIntoConstraints = false
        sidebar.addSubview(tip)

        NSLayoutConstraint.activate([
            brand.leadingAnchor.constraint(equalTo: sidebar.leadingAnchor, constant: 24),
            brand.topAnchor.constraint(equalTo: sidebar.topAnchor, constant: 30),
            subtitle.leadingAnchor.constraint(equalTo: brand.leadingAnchor),
            subtitle.topAnchor.constraint(equalTo: brand.bottomAnchor, constant: 4),
            menu.leadingAnchor.constraint(equalTo: sidebar.leadingAnchor, constant: 18),
            menu.trailingAnchor.constraint(equalTo: sidebar.trailingAnchor, constant: -18),
            menu.topAnchor.constraint(equalTo: subtitle.bottomAnchor, constant: 34),
            tipDivider.leadingAnchor.constraint(equalTo: brand.leadingAnchor),
            tipDivider.trailingAnchor.constraint(equalTo: sidebar.trailingAnchor, constant: -24),
            tipDivider.bottomAnchor.constraint(equalTo: tip.topAnchor, constant: -14),
            tipDivider.heightAnchor.constraint(equalToConstant: 1),
            tip.leadingAnchor.constraint(equalTo: brand.leadingAnchor),
            tip.trailingAnchor.constraint(equalTo: sidebar.trailingAnchor, constant: -24),
            tip.bottomAnchor.constraint(equalTo: sidebar.bottomAnchor, constant: -24)
        ])
        updateSectionButtonStyles()
        renderContent()
    }

    private func updateSectionButtonStyles() {
        for (item, button) in sectionButtons {
            let isSelected = item == section
            let textColor = isSelected ? PortfolioTheme.primaryText : PortfolioTheme.secondaryText
            button.contentTintColor = textColor
            button.attributedTitle = NSAttributedString(
                string: item.rawValue,
                attributes: [
                    .font: appFont(ofSize: 13, weight: .semibold),
                    .foregroundColor: textColor,
                    .paragraphStyle: PortfolioTheme.leftAlignedParagraph(inset: 12)
                ]
            )
            button.layer?.backgroundColor = isSelected
                ? PortfolioTheme.selectedFill.cgColor
                : NSColor.clear.cgColor
            button.layer?.borderWidth = isSelected ? 1 : 0
            button.layer?.borderColor = isSelected ? PortfolioTheme.selectedBorder.cgColor : nil
        }
    }

    @objc private func sectionClicked(_ sender: NSButton) {
        switch sender.identifier?.rawValue {
        case Section.positions.rawValue: section = .positions
        case Section.transactions.rawValue: section = .transactions
        default: section = .overview
        }
        updateSectionButtonStyles()
        renderContent()
    }

    private func renderContent() {
        guard let contentView else { return }
        contentView.subviews.forEach { $0.removeFromSuperview() }

        let header = NSView()
        header.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(header)

        let headerStack = NSStackView()
        headerStack.orientation = .horizontal
        headerStack.alignment = .centerY
        headerStack.spacing = 8
        headerStack.translatesAutoresizingMaskIntoConstraints = false
        header.addSubview(headerStack)

        let title = NSTextField(labelWithString: section.rawValue)
        title.font = appFont(ofSize: 24, weight: .bold)
        title.textColor = .white
        title.translatesAutoresizingMaskIntoConstraints = false
        titleLabel = title

        let refresh = NSButton(title: "刷新行情", target: self, action: #selector(refreshClicked(_:)))
        refresh.isBordered = false
        refresh.focusRingType = .none
        refresh.font = appFont(ofSize: 12, weight: .semibold)
        refresh.contentTintColor = PortfolioTheme.secondaryText
        refresh.wantsLayer = true
        refresh.layer?.cornerRadius = 8
        refresh.layer?.backgroundColor = PortfolioTheme.secondaryActionFill.cgColor
        refresh.layer?.borderColor = PortfolioTheme.actionBorder.cgColor
        refresh.layer?.borderWidth = 1
        refresh.translatesAutoresizingMaskIntoConstraints = false
        refresh.widthAnchor.constraint(equalToConstant: 84).isActive = true
        refresh.heightAnchor.constraint(equalToConstant: 30).isActive = true

        let add = NSButton(title: "+ 记录交易", target: self, action: #selector(addTransactionClicked(_:)))
        add.isBordered = false
        add.focusRingType = .none
        add.font = appFont(ofSize: 12, weight: .semibold)
        add.contentTintColor = PortfolioTheme.primaryText
        add.wantsLayer = true
        add.layer?.cornerRadius = 8
        add.layer?.backgroundColor = PortfolioTheme.primaryActionFill.cgColor
        add.keyEquivalent = "n"
        add.keyEquivalentModifierMask = [.command]
        add.translatesAutoresizingMaskIntoConstraints = false
        add.widthAnchor.constraint(equalToConstant: 100).isActive = true
        add.heightAnchor.constraint(equalToConstant: 30).isActive = true

        let spacer = NSView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        spacer.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        headerStack.addArrangedSubview(title)
        headerStack.addArrangedSubview(spacer)
        if section != .transactions {
            headerStack.addArrangedSubview(refresh)
        }
        headerStack.addArrangedSubview(add)

        let body = NSView()
        body.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(body)
        NSLayoutConstraint.activate([
            header.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 30),
            header.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -30),
            header.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 22),
            header.heightAnchor.constraint(equalToConstant: 38),
            headerStack.leadingAnchor.constraint(equalTo: header.leadingAnchor),
            headerStack.trailingAnchor.constraint(equalTo: header.trailingAnchor),
            headerStack.topAnchor.constraint(equalTo: header.topAnchor),
            headerStack.bottomAnchor.constraint(equalTo: header.bottomAnchor),
            body.leadingAnchor.constraint(equalTo: header.leadingAnchor),
            body.trailingAnchor.constraint(equalTo: header.trailingAnchor),
            body.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 18),
            body.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24)
        ])

        switch section {
        case .overview:
            buildOverview(in: body)
        case .positions:
            buildPositions(in: body)
        case .transactions:
            buildTransactions(in: body)
        }
    }

    private func buildOverview(in body: NSView) {
        let scroll = makeScrollView()
        body.addSubview(scroll)
        let stack = verticalStack()
        let document = FlippedDocumentView()
        document.addSubview(stack)
        scroll.documentView = document
        document.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scroll.leadingAnchor.constraint(equalTo: body.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: body.trailingAnchor),
            scroll.topAnchor.constraint(equalTo: body.topAnchor),
            scroll.bottomAnchor.constraint(equalTo: body.bottomAnchor),
            document.widthAnchor.constraint(equalTo: scroll.contentView.widthAnchor),
            stack.leadingAnchor.constraint(equalTo: document.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: document.trailingAnchor),
            stack.topAnchor.constraint(equalTo: document.topAnchor),
            stack.bottomAnchor.constraint(equalTo: document.bottomAnchor)
        ])

        let currency = selectedCurrency.isEmpty ? "--" : selectedCurrency
        let selectedSummary = summary.currencies[selectedCurrency]
        let cards = NSStackView()
        cards.orientation = .horizontal
        cards.spacing = 12
        cards.distribution = .fillEqually
        cards.addArrangedSubview(metricCard("持仓市值", selectedSummary.map { formatCurrencyWithCode($0.marketValue, currencyCode: currency, compact: true) } ?? "--", "当前行情估值", .systemBlue))
        cards.addArrangedSubview(metricCard("累计投入", selectedSummary.map { formatCurrencyWithCode($0.grossInvested, currencyCode: currency, compact: true) } ?? "--", "买入金额与费用", .systemOrange))
        cards.addArrangedSubview(metricCard("累计盈亏", selectedSummary.map { formatSignedCurrencyWithCode($0.totalPnl, currencyCode: currency, compact: true) } ?? "--", "已实现 + 未实现", selectedSummary.map { $0.totalPnl >= 0 ? .systemGreen : .systemRed } ?? .systemGray))
        cards.addArrangedSubview(metricCard("总资产", selectedSummary?.hasFundingRecords == true ? formatCurrencyWithCode(selectedSummary?.netWorth ?? 0, currencyCode: currency, compact: true) : "需记录入金", selectedSummary?.hasFundingRecords == true ? "现金 + 持仓市值" : "仅买卖记录无法还原", .systemPurple))
        cards.heightAnchor.constraint(equalToConstant: 94).isActive = true
        stack.addArrangedSubview(cards)

        let chartHeader = NSStackView()
        chartHeader.orientation = .horizontal
        chartHeader.alignment = .centerY
        chartHeader.spacing = 8
        let chartTitle = NSTextField(labelWithString: "组合历史变化")
        chartTitle.font = appFont(ofSize: 15, weight: .bold)
        chartTitle.textColor = .white
        chartHeader.addArrangedSubview(chartTitle)
        let spacer = NSView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        chartHeader.addArrangedSubview(spacer)

        let metricPopup = NSPopUpButton()
        metricPopup.addItems(withTitles: PortfolioChartMetric.allCases.map(\.title))
        metricPopup.selectItem(withTitle: selectedMetric.title)
        metricPopup.target = self
        metricPopup.action = #selector(chartMetricChanged(_:))
        chartHeader.addArrangedSubview(metricPopup)

        let currencyPopup = NSPopUpButton()
        currencyPopup.addItems(withTitles: summary.currencies.keys.sorted())
        if !selectedCurrency.isEmpty { currencyPopup.selectItem(withTitle: selectedCurrency) }
        currencyPopup.target = self
        currencyPopup.action = #selector(chartCurrencyChanged(_:))
        currencyPopup.isEnabled = !summary.currencies.isEmpty
        chartHeader.addArrangedSubview(currencyPopup)
        stack.addArrangedSubview(chartHeader)

        let chart = PortfolioChartView()
        chart.metric = selectedMetric
        chart.currency = currency
        chart.points = snapshots.filter { $0.currency == currency }.compactMap { snapshot in
            guard let value = snapshot.value(for: selectedMetric) else { return nil }
            return PortfolioChartPoint(date: snapshot.capturedAt, value: value)
        }
        chart.heightAnchor.constraint(equalToConstant: 255).isActive = true
        stack.addArrangedSubview(chart)
    }

    private func buildPositions(in body: NSView) {
        let visiblePositions = summary.positions.filter { $0.quantity > 0 }
        let split = NSSplitView()
        split.isVertical = true
        split.dividerStyle = .thin
        split.translatesAutoresizingMaskIntoConstraints = false
        body.addSubview(split)

        let listPane = makePositionListPane(visiblePositions)
        split.addArrangedSubview(listPane)
        listPane.widthAnchor.constraint(equalToConstant: 240).isActive = true
        listPane.setContentHuggingPriority(.required, for: .horizontal)
        listPane.setContentCompressionResistancePriority(.required, for: .horizontal)
        if let selectedPosition = visiblePositions.first(where: { $0.assetID == selectedPositionID }) ?? visiblePositions.first {
            split.addArrangedSubview(makePositionDetailPane(for: selectedPosition))
        } else {
            split.addArrangedSubview(makeEmptyPositionDetailPane())
        }

        NSLayoutConstraint.activate([
            split.leadingAnchor.constraint(equalTo: body.leadingAnchor),
            split.trailingAnchor.constraint(equalTo: body.trailingAnchor),
            split.topAnchor.constraint(equalTo: body.topAnchor),
            split.bottomAnchor.constraint(equalTo: body.bottomAnchor)
        ])

        DispatchQueue.main.async { [weak self] in
            self?.requestSelectedPositionChartIfNeeded()
        }
    }

    private func makePositionListPane(_ positions: [PortfolioPosition]) -> NSView {
        let pane = NSView()
        pane.wantsLayer = true
        pane.layer?.backgroundColor = PortfolioTheme.sidebarBackground.cgColor

        let header = NSStackView()
        header.orientation = .horizontal
        header.alignment = .centerY
        header.spacing = 8
        header.translatesAutoresizingMaskIntoConstraints = false
        pane.addSubview(header)

        let title = NSTextField(labelWithString: "当前持仓")
        title.font = appFont(ofSize: 14, weight: .bold)
        title.textColor = .white
        header.addArrangedSubview(title)

        let count = NSTextField(labelWithString: "\(positions.count) 只")
        count.font = appFont(ofSize: 11, weight: .medium)
        count.textColor = PortfolioTheme.mutedText
        header.addArrangedSubview(count)

        let scroll = makeScrollView()
        pane.addSubview(scroll)
        let list = verticalStack()
        list.spacing = 7
        let document = FlippedDocumentView()
        document.addSubview(list)
        scroll.documentView = document
        document.translatesAutoresizingMaskIntoConstraints = false

        for position in positions {
            let row = makePositionListRow(position)
            list.addArrangedSubview(row)
            row.widthAnchor.constraint(equalTo: list.widthAnchor).isActive = true
        }
        if positions.isEmpty {
            let empty = NSTextField(wrappingLabelWithString: "暂无持仓\n记录买入后，这里会显示持仓列表。")
            empty.font = appFont(ofSize: 13, weight: .medium)
            empty.textColor = NSColor.white.withAlphaComponent(0.45)
            empty.alignment = .center
            empty.heightAnchor.constraint(equalToConstant: 100).isActive = true
            list.addArrangedSubview(empty)
            empty.widthAnchor.constraint(equalTo: list.widthAnchor).isActive = true
        }

        NSLayoutConstraint.activate([
            header.leadingAnchor.constraint(equalTo: pane.leadingAnchor),
            header.trailingAnchor.constraint(equalTo: pane.trailingAnchor, constant: -14),
            header.topAnchor.constraint(equalTo: pane.topAnchor, constant: 16),
            header.heightAnchor.constraint(equalToConstant: 24),
            scroll.leadingAnchor.constraint(equalTo: pane.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: pane.trailingAnchor, constant: -10),
            scroll.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 10),
            scroll.bottomAnchor.constraint(equalTo: pane.bottomAnchor, constant: -10),
            document.widthAnchor.constraint(equalTo: scroll.contentView.widthAnchor),
            list.leadingAnchor.constraint(equalTo: document.leadingAnchor),
            list.trailingAnchor.constraint(equalTo: document.trailingAnchor),
            list.topAnchor.constraint(equalTo: document.topAnchor),
            list.bottomAnchor.constraint(equalTo: document.bottomAnchor)
        ])
        return pane
    }

    private func makePositionListRow(_ position: PortfolioPosition) -> NSButton {
        let button = NSButton(title: "", target: self, action: #selector(positionListRowClicked(_:)))
        button.identifier = NSUserInterfaceItemIdentifier(position.assetID)
        button.isBordered = false
        button.focusRingType = .none
        button.alignment = .left
        button.contentTintColor = PortfolioTheme.primaryText
        button.wantsLayer = true
        button.layer?.cornerRadius = 8
        button.setContentHuggingPriority(.defaultLow, for: .horizontal)
        button.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        button.layer?.backgroundColor = (position.assetID == selectedPositionID
            ? PortfolioTheme.selectedFill
            : PortfolioTheme.raisedSurface).cgColor
        button.layer?.borderColor = (position.assetID == selectedPositionID
            ? PortfolioTheme.selectedBorder
            : PortfolioTheme.surfaceBorder).cgColor
        button.layer?.borderWidth = 1
        button.heightAnchor.constraint(equalToConstant: 78).isActive = true

        let currentPrice = position.currentPrice.map {
            formatCurrencyWithCode($0, currencyCode: position.currency, compact: true)
        } ?? "--"
        let marketValue = position.marketValue.map {
            formatCurrencyWithCode($0, currencyCode: position.currency, compact: true)
        } ?? "--"
        let pnl = position.unrealizedPnl.map {
            formatSignedCurrencyWithCode($0, currencyCode: position.currency, compact: true)
        } ?? "--"
        let quantity = formatNumber(position.quantity, minFraction: 0, maxFraction: 6)
        let paragraph = PortfolioTheme.leftAlignedParagraph(inset: 12, lineSpacing: 1)
        let title = NSMutableAttributedString(string: "\(position.name)  \(position.symbol)\n", attributes: [
            .font: appFont(ofSize: 13, weight: .semibold),
            .foregroundColor: PortfolioTheme.primaryText,
            .paragraphStyle: paragraph
        ])
        title.append(NSAttributedString(string: "\(quantity) 股 · 现价 \(currentPrice)\n", attributes: [
            .font: appFont(ofSize: 11, weight: .regular),
            .foregroundColor: PortfolioTheme.tertiaryText,
            .paragraphStyle: paragraph
        ]))
        title.append(NSAttributedString(string: "市值 \(marketValue) · \(pnl)", attributes: [
            .font: appFont(ofSize: 11, weight: .medium),
            .foregroundColor: position.unrealizedPnl.map { $0 >= 0 ? NSColor.systemGreen : NSColor.systemRed } ?? PortfolioTheme.tertiaryText,
            .paragraphStyle: paragraph
        ]))
        button.attributedTitle = title
        button.cell?.lineBreakMode = .byWordWrapping
        button.cell?.wraps = true
        return button
    }

    private func makePositionDetailPane(for position: PortfolioPosition) -> NSView {
        let pane = NSView()
        pane.wantsLayer = true
        pane.layer?.backgroundColor = PortfolioTheme.pageBackground.cgColor

        let title = NSTextField(labelWithString: "\(position.name)  \(position.symbol)")
        title.font = appFont(ofSize: 20, weight: .bold)
        title.textColor = .white
        title.translatesAutoresizingMaskIntoConstraints = false
        pane.addSubview(title)

        let subtitle = NSTextField(labelWithString: "\(formatNumber(position.quantity, minFraction: 0, maxFraction: 6)) 股 · 平均成本 \(formatCurrencyWithCode(position.averageCost, currencyCode: position.currency, compact: false))")
        subtitle.font = appFont(ofSize: 12, weight: .medium)
        subtitle.textColor = PortfolioTheme.tertiaryText
        subtitle.translatesAutoresizingMaskIntoConstraints = false
        pane.addSubview(subtitle)

        let periodPopup = NSPopUpButton()
        periodPopup.addItems(withTitles: [StockChartPeriod.day, .week, .month, .year].map(\.title))
        periodPopup.selectItem(withTitle: positionChartPeriod.title)
        periodPopup.target = self
        periodPopup.action = #selector(positionChartPeriodChanged(_:))
        periodPopup.translatesAutoresizingMaskIntoConstraints = false
        periodPopup.widthAnchor.constraint(greaterThanOrEqualToConstant: 78).isActive = true
        pane.addSubview(periodPopup)

        let chart = makePositionChart(for: position)
        chart.translatesAutoresizingMaskIntoConstraints = false
        pane.addSubview(chart)

        let summary = makePositionStats(for: position)
        summary.translatesAutoresizingMaskIntoConstraints = false
        pane.addSubview(summary)

        let note = NSTextField(labelWithString: "折线显示该股票的行情价格；持仓市值和浮盈/浮亏按当前报价计算。")
        note.font = appFont(ofSize: 11, weight: .regular)
        note.textColor = PortfolioTheme.mutedText
        note.translatesAutoresizingMaskIntoConstraints = false
        pane.addSubview(note)

        NSLayoutConstraint.activate([
            title.leadingAnchor.constraint(equalTo: pane.leadingAnchor, constant: 22),
            title.topAnchor.constraint(equalTo: pane.topAnchor, constant: 18),
            subtitle.leadingAnchor.constraint(equalTo: title.leadingAnchor),
            subtitle.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 5),
            periodPopup.trailingAnchor.constraint(equalTo: pane.trailingAnchor, constant: -22),
            periodPopup.centerYAnchor.constraint(equalTo: title.centerYAnchor),
            chart.leadingAnchor.constraint(equalTo: pane.leadingAnchor, constant: 22),
            chart.trailingAnchor.constraint(equalTo: pane.trailingAnchor, constant: -22),
            chart.topAnchor.constraint(equalTo: subtitle.bottomAnchor, constant: 18),
            chart.heightAnchor.constraint(equalToConstant: 300),
            summary.leadingAnchor.constraint(equalTo: chart.leadingAnchor),
            summary.trailingAnchor.constraint(equalTo: chart.trailingAnchor),
            summary.topAnchor.constraint(equalTo: chart.bottomAnchor, constant: 12),
            summary.heightAnchor.constraint(equalToConstant: 62),
            note.leadingAnchor.constraint(equalTo: chart.leadingAnchor),
            note.trailingAnchor.constraint(equalTo: chart.trailingAnchor),
            note.topAnchor.constraint(equalTo: summary.bottomAnchor, constant: 8)
        ])
        return pane
    }

    private func makeEmptyPositionDetailPane() -> NSView {
        let pane = NSView()
        pane.wantsLayer = true
        pane.layer?.backgroundColor = PortfolioTheme.pageBackground.cgColor
        let label = NSTextField(wrappingLabelWithString: "选择左侧持仓，查看行情折线和持仓分析。")
        label.font = appFont(ofSize: 14, weight: .medium)
        label.textColor = PortfolioTheme.tertiaryText
        label.alignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        pane.addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: pane.leadingAnchor, constant: 30),
            label.trailingAnchor.constraint(equalTo: pane.trailingAnchor, constant: -30),
            label.centerXAnchor.constraint(equalTo: pane.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: pane.centerYAnchor)
        ])
        return pane
    }

    private func makePositionChart(for position: PortfolioPosition) -> NSView {
        let container = NSView()
        let state = positionChartStates[chartStateKey(for: position.assetID)]

        if case let .loaded(points) = state, points.count > 1 {
            let chart = StockChartView()
            chart.points = points
            chart.previousClose = displayAssets.first(where: { $0.id == position.assetID })?.previousClose
            chart.colorMode = .redFallGreenRise
            chart.currencyCode = position.currency
            chart.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(chart)
            NSLayoutConstraint.activate([
                chart.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                chart.trailingAnchor.constraint(equalTo: container.trailingAnchor),
                chart.topAnchor.constraint(equalTo: container.topAnchor),
                chart.bottomAnchor.constraint(equalTo: container.bottomAnchor)
            ])
        } else {
            let message: String
            switch state {
            case .loading:
                message = "正在加载行情折线…"
            case .failed:
                message = "行情折线加载失败，请点击“刷新行情”重试。"
            case .unavailable:
                message = "当前行情源暂不提供这个周期的折线数据。"
            default:
                message = "正在准备行情折线…"
            }
            let label = NSTextField(wrappingLabelWithString: message)
            label.font = appFont(ofSize: 13, weight: .medium)
            label.textColor = PortfolioTheme.tertiaryText
            label.alignment = .center
            label.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(label)
            NSLayoutConstraint.activate([
                label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
                label.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),
                label.centerXAnchor.constraint(equalTo: container.centerXAnchor),
                label.centerYAnchor.constraint(equalTo: container.centerYAnchor)
            ])
        }
        return container
    }

    private func makePositionStats(for position: PortfolioPosition) -> NSView {
        let currentPrice = position.currentPrice.map {
            formatCurrencyWithCode($0, currencyCode: position.currency, compact: false)
        } ?? "--"
        let marketValue = position.marketValue.map {
            formatCurrencyWithCode($0, currencyCode: position.currency, compact: false)
        } ?? "--"
        let pnl = position.unrealizedPnl.map {
            formatSignedCurrencyWithCode($0, currencyCode: position.currency, compact: false)
        } ?? "--"

        let stack = NSStackView()
        stack.orientation = .horizontal
        stack.alignment = .centerY
        stack.distribution = .fillEqually
        stack.spacing = 8
        stack.addArrangedSubview(positionStatCard(title: "现价", value: currentPrice, color: PortfolioTheme.primaryText))
        stack.addArrangedSubview(positionStatCard(title: "持仓市值", value: marketValue, color: PortfolioTheme.primaryText))
        stack.addArrangedSubview(positionStatCard(
            title: "浮盈 / 浮亏",
            value: pnl,
            color: position.unrealizedPnl.map { $0 >= 0 ? NSColor.systemGreen : NSColor.systemRed } ?? PortfolioTheme.tertiaryText
        ))
        return stack
    }

    private func positionStatCard(title: String, value: String, color: NSColor) -> NSView {
        let card = NSView()
        card.wantsLayer = true
        card.layer?.cornerRadius = 8
        card.layer?.backgroundColor = PortfolioTheme.surface.cgColor
        card.layer?.borderColor = PortfolioTheme.surfaceBorder.cgColor
        card.layer?.borderWidth = 1

        let titleLabel = NSTextField(labelWithString: title)
        titleLabel.font = appFont(ofSize: 10, weight: .medium)
        titleLabel.textColor = PortfolioTheme.tertiaryText
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(titleLabel)

        let valueLabel = NSTextField(labelWithString: value)
        valueLabel.font = senFont(ofSize: 13)
        valueLabel.textColor = color
        valueLabel.lineBreakMode = .byTruncatingTail
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(valueLabel)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 10),
            titleLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -10),
            titleLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 9),
            valueLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            valueLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            valueLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 5),
            valueLabel.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -9)
        ])
        return card
    }

    private func chartStateKey(for assetID: String) -> String {
        "\(assetID)|\(positionChartPeriod.rawValue)"
    }

    private func requestSelectedPositionChartIfNeeded() {
        guard let selectedPositionID,
              positionChartPeriod != .off else { return }
        let key = chartStateKey(for: selectedPositionID)
        guard positionChartStates[key] == nil,
              requestedPositionChartKey != key else { return }
        requestedPositionChartKey = key
        onRequestPositionChart?(selectedPositionID, positionChartPeriod)
    }

    private func buildTransactions(in body: NSView) {
        let scroll = makeScrollView()
        body.addSubview(scroll)
        let stack = verticalStack()
        stack.spacing = 8
        let document = FlippedDocumentView()
        document.addSubview(stack)
        scroll.documentView = document
        document.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scroll.leadingAnchor.constraint(equalTo: body.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: body.trailingAnchor),
            scroll.topAnchor.constraint(equalTo: body.topAnchor),
            scroll.bottomAnchor.constraint(equalTo: body.bottomAnchor),
            document.widthAnchor.constraint(equalTo: scroll.contentView.widthAnchor),
            stack.leadingAnchor.constraint(equalTo: document.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: document.trailingAnchor),
            stack.topAnchor.constraint(equalTo: document.topAnchor),
            stack.bottomAnchor.constraint(equalTo: document.bottomAnchor)
        ])
        if transactions.isEmpty {
            let empty = NSTextField(wrappingLabelWithString: "还没有交易记录。点击右上角“记录交易”开始。")
            empty.font = appFont(ofSize: 14, weight: .medium)
            empty.textColor = NSColor.white.withAlphaComponent(0.48)
            empty.alignment = .center
            empty.heightAnchor.constraint(equalToConstant: 180).isActive = true
            stack.addArrangedSubview(empty)
            empty.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true
        } else {
            let meta = NSTextField(labelWithString: "按发生时间倒序 · 共 \(transactions.count) 笔记录")
            meta.font = appFont(ofSize: 11, weight: .medium)
            meta.textColor = PortfolioTheme.tertiaryText
            stack.addArrangedSubview(meta)
            meta.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true
            for transaction in transactions.reversed() {
                let row = transactionRow(transaction)
                stack.addArrangedSubview(row)
                row.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true
            }
        }
    }

    private func makePositionTable(compact: Bool) -> NSView {
        let stack = verticalStack()
        stack.spacing = 1
        let header = positionRow(
            name: "资产",
            quantity: "数量",
            price: "现价",
            value: "市值",
            pnl: "浮盈/浮亏",
            isHeader: true
        )
        stack.addArrangedSubview(header)
        let visible = summary.positions.filter { $0.quantity > 0 }
        if visible.isEmpty {
            let empty = NSTextField(labelWithString: "暂无持仓")
            empty.font = appFont(ofSize: 13, weight: .medium)
            empty.textColor = NSColor.white.withAlphaComponent(0.42)
            empty.alignment = .center
            empty.heightAnchor.constraint(equalToConstant: 80).isActive = true
            stack.addArrangedSubview(empty)
        } else {
            for position in visible {
                stack.addArrangedSubview(positionRow(
                    name: "\(position.name)  \(position.symbol)",
                    quantity: formatNumber(position.quantity, minFraction: 0, maxFraction: 6),
                    price: position.currentPrice.map { formatCurrencyWithCode($0, currencyCode: position.currency, compact: true) } ?? "--",
                    value: position.marketValue.map { formatCurrencyWithCode($0, currencyCode: position.currency, compact: true) } ?? "--",
                    pnl: position.unrealizedPnl.map { formatSignedCurrencyWithCode($0, currencyCode: position.currency, compact: true) } ?? "--",
                    isHeader: false
                ))
            }
        }
        if compact { stack.heightAnchor.constraint(greaterThanOrEqualToConstant: 120).isActive = true }
        return stack
    }

    private func positionRow(name: String, quantity: String, price: String, value: String, pnl: String, isHeader: Bool) -> NSView {
        let row = NSStackView()
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 8
        row.edgeInsets = NSEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
        row.heightAnchor.constraint(equalToConstant: isHeader ? 32 : 48).isActive = true
        if !isHeader {
            row.wantsLayer = true
            row.layer?.backgroundColor = NSColor.white.withAlphaComponent(0.035).cgColor
        }
        let color = isHeader ? NSColor.white.withAlphaComponent(0.45) : .white
        let font = appFont(ofSize: isHeader ? 11 : 13, weight: isHeader ? .semibold : .medium)

        let nameLabel = NSTextField(labelWithString: name)
        nameLabel.font = font
        nameLabel.textColor = color
        nameLabel.alignment = .left
        nameLabel.lineBreakMode = .byTruncatingTail
        nameLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        nameLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        row.addArrangedSubview(nameLabel)

        let fixedColumns: [(String, CGFloat, NSColor)] = [
            (quantity, 68, color),
            (price, 100, color),
            (value, 112, color),
            (pnl, 128, isHeader ? color : (pnl.hasPrefix("-") ? .systemRed : .systemGreen))
        ]
        for (text, width, textColor) in fixedColumns {
            let label = NSTextField(labelWithString: text)
            label.font = font
            label.textColor = textColor
            label.alignment = .right
            label.lineBreakMode = .byTruncatingTail
            label.widthAnchor.constraint(equalToConstant: width).isActive = true
            row.addArrangedSubview(label)
        }
        return row
    }

    private func transactionRow(_ transaction: PortfolioTransaction) -> NSView {
        let row = NSStackView()
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 12
        row.edgeInsets = NSEdgeInsets(top: 0, left: 14, bottom: 0, right: 10)
        row.heightAnchor.constraint(equalToConstant: 62).isActive = true
        row.wantsLayer = true
        row.layer?.cornerRadius = 8
        row.layer?.backgroundColor = PortfolioTheme.raisedSurface.cgColor
        row.layer?.borderColor = PortfolioTheme.surfaceBorder.cgColor
        row.layer?.borderWidth = 1

        let accent = NSView()
        accent.wantsLayer = true
        accent.layer?.cornerRadius = 1.5
        accent.layer?.backgroundColor = transactionAccentColor(for: transaction.kind).cgColor
        accent.widthAnchor.constraint(equalToConstant: 3).isActive = true
        accent.heightAnchor.constraint(equalToConstant: 30).isActive = true
        row.addArrangedSubview(accent)

        let left = NSStackView()
        left.orientation = .vertical
        left.spacing = 3
        let title = NSTextField(labelWithString: "\(transaction.kind.title) · \(transaction.assetName.isEmpty ? transaction.currency : transaction.assetName)")
        title.font = appFont(ofSize: 13, weight: .semibold)
        title.textColor = PortfolioTheme.primaryText
        let detail = NSTextField(labelWithString: "\(DateFormatter.portfolioRow.string(from: transaction.occurredAt)) · \(transaction.symbol)")
        detail.font = appFont(ofSize: 11, weight: .regular)
        detail.textColor = PortfolioTheme.tertiaryText
        left.addArrangedSubview(title)
        left.addArrangedSubview(detail)
        left.setContentHuggingPriority(.defaultLow, for: .horizontal)
        row.addArrangedSubview(left)

        let spacer = NSView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        spacer.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        row.addArrangedSubview(spacer)

        let amount: String
        if transaction.kind.isTrade {
            amount = "\(formatNumber(transaction.quantity, minFraction: 0, maxFraction: 6)) × \(formatCurrencyWithCode(transaction.unitPrice, currencyCode: transaction.currency, compact: true))"
        } else {
            amount = formatCurrencyWithCode(transaction.amount, currencyCode: transaction.currency, compact: true)
        }
        let amountLabel = NSTextField(labelWithString: amount)
        amountLabel.font = senFont(ofSize: 12)
        amountLabel.textColor = PortfolioTheme.secondaryText
        amountLabel.alignment = .right
        row.addArrangedSubview(amountLabel)

        let edit = NSButton(title: "编辑", target: self, action: #selector(editTransactionClicked(_:)))
        edit.isBordered = false
        edit.focusRingType = .none
        edit.font = appFont(ofSize: 11, weight: .semibold)
        edit.contentTintColor = PortfolioTheme.secondaryText
        edit.wantsLayer = true
        edit.layer?.cornerRadius = 6
        edit.layer?.backgroundColor = NSColor.white.withAlphaComponent(0.09).cgColor
        edit.identifier = NSUserInterfaceItemIdentifier(transaction.id.uuidString)
        edit.widthAnchor.constraint(equalToConstant: 48).isActive = true
        edit.heightAnchor.constraint(equalToConstant: 26).isActive = true
        row.addArrangedSubview(edit)

        let delete = NSButton(title: "删除", target: self, action: #selector(deleteTransactionClicked(_:)))
        delete.isBordered = false
        delete.focusRingType = .none
        delete.font = appFont(ofSize: 11, weight: .semibold)
        delete.contentTintColor = PortfolioTheme.tertiaryText
        delete.wantsLayer = true
        delete.layer?.cornerRadius = 6
        delete.layer?.backgroundColor = NSColor.white.withAlphaComponent(0.07).cgColor
        delete.identifier = NSUserInterfaceItemIdentifier(transaction.id.uuidString)
        delete.widthAnchor.constraint(equalToConstant: 48).isActive = true
        delete.heightAnchor.constraint(equalToConstant: 26).isActive = true
        row.addArrangedSubview(delete)
        return row
    }

    private func transactionAccentColor(for kind: PortfolioTransactionKind) -> NSColor {
        switch kind {
        case .buy, .opening:
            return .systemGreen
        case .sell:
            return .systemRed
        case .deposit:
            return .systemBlue
        case .withdrawal:
            return .systemOrange
        case .dividend:
            return .systemPurple
        }
    }

    private func metricCard(_ title: String, _ value: String, _ subtitle: String, _ color: NSColor) -> NSView {
        let card = NSView()
        card.wantsLayer = true
        card.layer?.cornerRadius = 10
        card.layer?.masksToBounds = true
        card.layer?.backgroundColor = PortfolioTheme.raisedSurface.cgColor
        card.layer?.borderColor = PortfolioTheme.surfaceBorder.cgColor
        card.layer?.borderWidth = 1
        let accent = NSView()
        accent.wantsLayer = true
        accent.layer?.backgroundColor = color.withAlphaComponent(0.9).cgColor
        accent.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(accent)
        let titleLabel = NSTextField(labelWithString: title)
        titleLabel.font = appFont(ofSize: 11, weight: .semibold)
        titleLabel.textColor = color.withAlphaComponent(0.92)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(titleLabel)
        let valueLabel = NSTextField(labelWithString: value)
        valueLabel.font = senFont(ofSize: 18)
        valueLabel.textColor = .white
        valueLabel.lineBreakMode = .byTruncatingTail
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(valueLabel)
        let subtitleLabel = NSTextField(labelWithString: subtitle)
        subtitleLabel.font = appFont(ofSize: 10, weight: .regular)
        subtitleLabel.textColor = PortfolioTheme.mutedText
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(subtitleLabel)
        NSLayoutConstraint.activate([
            accent.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            accent.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            accent.topAnchor.constraint(equalTo: card.topAnchor),
            accent.heightAnchor.constraint(equalToConstant: 3),
            titleLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14),
            titleLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14),
            titleLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 13),
            valueLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            valueLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            valueLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 5),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            subtitleLabel.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -9)
        ])
        return card
    }

    private func makeScrollView() -> NSScrollView {
        let scroll = NSScrollView()
        scroll.hasVerticalScroller = true
        scroll.drawsBackground = false
        scroll.borderType = .noBorder
        scroll.translatesAutoresizingMaskIntoConstraints = false
        return scroll
    }

    private func verticalStack() -> NSStackView {
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .width
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }

    @objc private func refreshClicked(_ sender: NSButton) {
        onRefresh?()
    }

    @objc private func addTransactionClicked(_ sender: NSButton) {
        guard let transaction = showTransactionEditor() else { return }
        onAddTransaction?(transaction)
    }

    @objc private func editTransactionClicked(_ sender: NSButton) {
        guard let id = sender.identifier.flatMap({ UUID(uuidString: $0.rawValue) }),
              let transaction = transactions.first(where: { $0.id == id }),
              let updatedTransaction = showTransactionEditor(editing: transaction) else { return }
        onUpdateTransaction?(updatedTransaction)
    }

    @objc private func deleteTransactionClicked(_ sender: NSButton) {
        guard let id = sender.identifier.flatMap({ UUID(uuidString: $0.rawValue) }) else { return }
        onDeleteTransaction?(id)
    }

    @objc private func chartMetricChanged(_ sender: NSPopUpButton) {
        guard let title = sender.titleOfSelectedItem,
              let metric = PortfolioChartMetric.allCases.first(where: { $0.title == title }) else { return }
        selectedMetric = metric
        renderContent()
    }

    @objc private func chartCurrencyChanged(_ sender: NSPopUpButton) {
        selectedCurrency = sender.titleOfSelectedItem ?? ""
        renderContent()
    }

    @objc private func positionListRowClicked(_ sender: NSButton) {
        guard let assetID = sender.identifier?.rawValue else { return }
        selectedPositionID = assetID
        requestedPositionChartKey = nil
        renderContent()
    }

    @objc private func positionChartPeriodChanged(_ sender: NSPopUpButton) {
        let periods: [StockChartPeriod] = [.day, .week, .month, .year]
        guard periods.indices.contains(sender.indexOfSelectedItem) else { return }
        positionChartPeriod = periods[sender.indexOfSelectedItem]
        requestedPositionChartKey = nil
        renderContent()
    }

    private func showTransactionEditor(editing: PortfolioTransaction? = nil) -> PortfolioTransaction? {
        let alert = NSAlert()
        alert.messageText = editing == nil ? "记录交易" : "编辑交易"
        alert.informativeText = editing == nil
            ? "买入、卖出和资金流水会立即参与持仓与盈亏计算。"
            : "保存后，持仓和历史统计会按修改后的记录重新计算。"
        alert.addButton(withTitle: "保存")
        alert.addButton(withTitle: "取消")

        var kinds: [PortfolioTransactionKind] = [.buy, .sell, .deposit, .withdrawal, .dividend]
        if editing?.kind == .opening {
            kinds.append(.opening)
        }
        let typePopup = NSPopUpButton()
        typePopup.addItems(withTitles: kinds.map(\.title))

        var editorAssets = trackedAssets
        if let editing,
           editing.kind.isTrade,
           let assetID = editing.assetID,
           !editorAssets.contains(where: { assetIdentity(for: $0) == assetID }),
           let type = editing.assetType,
           !editing.symbol.isEmpty {
            editorAssets.append(TrackedAsset(
                type: type,
                name: editing.assetName.isEmpty ? editing.symbol : editing.assetName,
                symbol: editing.symbol,
                visibleInMenuBar: false
            ))
        }
        let assetPopup = NSPopUpButton()
        assetPopup.addItems(withTitles: editorAssets.map { "\($0.name)（\($0.symbol)）" })
        let dateField = NSTextField(string: DateFormatter.portfolioEditor.string(from: editing?.occurredAt ?? Date()))
        let quantityField = NSTextField(string: "")
        quantityField.placeholderString = "数量"
        let priceField = NSTextField(string: "")
        priceField.placeholderString = "成交单价"
        let amountField = NSTextField(string: "")
        amountField.placeholderString = "金额"
        let feeField = NSTextField(string: editing.map { formatNumber($0.fee, minFraction: 0, maxFraction: 6) } ?? "0")
        let taxField = NSTextField(string: editing.map { formatNumber($0.tax, minFraction: 0, maxFraction: 6) } ?? "0")
        let currencyField = NSTextField(string: editing?.currency ?? "CNY")
        let noteField = NSTextField(string: editing?.note ?? "")
        noteField.placeholderString = "可选"

        if let editing {
            typePopup.selectItem(withTitle: editing.kind.title)
            quantityField.stringValue = editing.kind.isTrade
                ? formatNumber(editing.quantity, minFraction: 0, maxFraction: 6)
                : ""
            priceField.stringValue = editing.kind.isTrade
                ? formatNumber(editing.unitPrice, minFraction: 0, maxFraction: 6)
                : ""
            amountField.stringValue = editing.kind.isTrade
                ? ""
                : formatNumber(editing.amount, minFraction: 0, maxFraction: 6)
            if let assetID = editing.assetID,
               let index = editorAssets.firstIndex(where: { assetIdentity(for: $0) == assetID }) {
                assetPopup.selectItem(at: index)
            }
        }

        for field in [dateField, quantityField, priceField, amountField, feeField, taxField, currencyField, noteField] {
            styleEditorTextField(field)
        }
        for popup in [typePopup, assetPopup] {
            popup.controlSize = .regular
            popup.font = appFont(ofSize: 13, weight: .regular)
            popup.appearance = NSAppearance(named: .darkAqua)
        }

        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 7
        stack.frame = NSRect(x: 0, y: 0, width: 430, height: 350)
        stack.addArrangedSubview(editorRow("类型", typePopup))
        stack.addArrangedSubview(editorRow("资产", assetPopup))
        stack.addArrangedSubview(editorRow("时间", dateField))
        stack.addArrangedSubview(editorRow("数量", quantityField))
        stack.addArrangedSubview(editorRow("成交单价", priceField))
        stack.addArrangedSubview(editorRow("金额", amountField))
        stack.addArrangedSubview(editorRow("手续费", feeField))
        stack.addArrangedSubview(editorRow("税费", taxField))
        stack.addArrangedSubview(editorRow("币种", currencyField))
        stack.addArrangedSubview(editorRow("备注", noteField))
        alert.accessoryView = stack
        alert.window.appearance = NSAppearance(named: .darkAqua)

        guard alert.runModal() == .alertFirstButtonReturn else { return nil }
        let kind = kinds[min(max(0, typePopup.indexOfSelectedItem), kinds.count - 1)]
        guard let occurredAt = DateFormatter.portfolioEditor.date(from: dateField.stringValue),
              let fee = decimal(feeField.stringValue),
              let tax = decimal(taxField.stringValue),
              fee >= 0,
              tax >= 0 else {
            showEditorError("时间、手续费和税费格式不正确")
            return nil
        }
        let currency = currencyField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !currency.isEmpty else {
            showEditorError("请填写币种")
            return nil
        }

        if kind.isTrade {
            guard !editorAssets.isEmpty,
                  editorAssets.indices.contains(assetPopup.indexOfSelectedItem),
                  let quantity = decimal(quantityField.stringValue),
                  let unitPrice = decimal(priceField.stringValue),
                  quantity > 0,
                  unitPrice > 0 else {
                showEditorError("交易类型需要选择资产，并填写大于 0 的数量和成交单价")
                return nil
            }
            let asset = editorAssets[assetPopup.indexOfSelectedItem]
            let display = displayAssets.first(where: { $0.id == assetIdentity(for: asset) })
            var transaction = PortfolioTransaction.trade(
                asset: asset,
                name: asset.name,
                kind: kind,
                occurredAt: occurredAt,
                quantity: quantity,
                unitPrice: unitPrice,
                fee: fee,
                tax: tax,
                note: noteField.stringValue
            )
            transaction.id = editing?.id ?? UUID()
            transaction.currency = display?.currency?.uppercased() ?? currency
            return transaction
        }

        guard let amount = decimal(amountField.stringValue), amount > 0 else {
            showEditorError("资金流水需要填写大于 0 的金额")
            return nil
        }
        return PortfolioTransaction(
            id: editing?.id ?? UUID(),
            occurredAt: occurredAt,
            kind: kind,
            assetID: nil,
            assetName: "",
            symbol: "",
            assetType: nil,
            currency: currency,
            quantity: 0,
            unitPrice: 0,
            amount: amount,
            fee: fee,
            tax: tax,
            note: noteField.stringValue
        )
    }

    private func styleEditorTextField(_ field: NSTextField) {
        field.controlSize = .regular
        field.font = appFont(ofSize: 13, weight: .regular)
        field.textColor = .white
        field.placeholderAttributedString = field.placeholderString.map {
            NSAttributedString(
                string: $0,
                attributes: [
                    .font: appFont(ofSize: 13, weight: .regular),
                    .foregroundColor: NSColor.white.withAlphaComponent(0.38)
                ]
            )
        }
        field.isBezeled = true
        field.bezelStyle = .roundedBezel
        field.drawsBackground = true
        field.backgroundColor = NSColor.white.withAlphaComponent(0.10)
        field.focusRingType = .default
        field.alignment = .left
    }

    private func editorRow(_ title: String, _ field: NSView) -> NSView {
        let row = NSStackView()
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 12
        row.translatesAutoresizingMaskIntoConstraints = false
        row.heightAnchor.constraint(equalToConstant: 28).isActive = true
        let label = NSTextField(labelWithString: title)
        label.font = appFont(ofSize: 12, weight: .medium)
        label.textColor = NSColor.white.withAlphaComponent(0.78)
        label.alignment = .right
        label.widthAnchor.constraint(equalToConstant: 66).isActive = true
        field.widthAnchor.constraint(equalToConstant: 340).isActive = true
        row.addArrangedSubview(label)
        row.addArrangedSubview(field)
        return row
    }

    private func showEditorError(_ message: String) {
        let alert = NSAlert()
        alert.messageText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "知道了")
        alert.runModal()
    }
}

private extension DateFormatter {
    static let portfolioEditor: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter
    }()
}

private func decimal(_ string: String) -> Double? {
    Double(string.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: ",", with: ""))
}
