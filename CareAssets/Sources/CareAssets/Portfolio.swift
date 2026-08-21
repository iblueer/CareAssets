import Foundation
import SQLite3

enum PortfolioTransactionKind: String, CaseIterable, Codable {
    case buy
    case sell
    case deposit
    case withdrawal
    case dividend
    case transfer
    case exchange
    case opening

    var title: String {
        switch self {
        case .buy: return "买入"
        case .sell: return "卖出"
        case .deposit: return "入金"
        case .withdrawal: return "出金"
        case .dividend: return "分红"
        case .transfer: return "账户转账"
        case .exchange: return "换汇"
        case .opening: return "期初持仓"
        }
    }

    var isTrade: Bool {
        self == .buy || self == .sell || self == .opening
    }
}

enum PortfolioSettlementStatus: String, CaseIterable, Codable {
    case notRecorded
    case pending
    case settled
    case notApplicable

    var title: String {
        switch self {
        case .notRecorded: return "未记录"
        case .pending: return "待结算"
        case .settled: return "已结算"
        case .notApplicable: return "不适用"
        }
    }
}

enum PortfolioDate {
    private static let utc = TimeZone(secondsFromGMT: 0)!

    static func string(from date: Date, timeZone: TimeZone = .current) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", components.year ?? 1970, components.month ?? 1, components.day ?? 1)
    }

    static func date(from string: String) -> Date? {
        let parts = string.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = utc
        return calendar.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2], hour: 12))
    }

    static func normalizedDate(from date: Date, timeZone: TimeZone = .current) -> Date {
        self.date(from: string(from: date, timeZone: timeZone)) ?? date
    }
}

func portfolioMarketTimeZone(for asset: TrackedAsset) -> String {
    let symbol = (asset.canonicalSymbol ?? asset.symbol).uppercased()
    if symbol.hasPrefix("US:") { return "America/New_York" }
    if symbol.hasPrefix("HK:") { return "Asia/Hong_Kong" }
    if symbol.hasPrefix("SH:") || symbol.hasPrefix("SZ:") { return "Asia/Shanghai" }
    return ""
}

private func portfolioMarketTimeZone(forAssetID assetID: String?) -> String {
    let identifier = assetID?.uppercased() ?? ""
    if identifier.contains("-US:") { return "America/New_York" }
    if identifier.contains("-HK:") { return "Asia/Hong_Kong" }
    if identifier.contains("-SH:") || identifier.contains("-SZ:") { return "Asia/Shanghai" }
    return ""
}

struct PortfolioAccount: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var createdAt: Date

    init(id: UUID = UUID(), name: String, createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
    }
}

struct PortfolioTransaction: Identifiable, Codable {
    var id: UUID
    var occurredAt: Date
    var kind: PortfolioTransactionKind
    var assetID: String?
    var assetName: String
    var symbol: String
    var assetType: AssetType?
    var currency: String
    var quantity: Double
    var unitPrice: Double
    var amount: Double
    var fee: Double
    var tax: Double
    var note: String
    var accountID: UUID? = nil
    var targetAccountID: UUID? = nil
    var targetCurrency: String = ""
    var targetAmount: Double = 0
    /// Exchange-local calendar date. `occurredAt` remains a normalized noon UTC value for legacy chart code.
    var tradeDate: String = ""
    var marketTimeZone: String = ""
    var executedAt: Date? = nil
    var settlementDate: String? = nil
    var settlementStatus: PortfolioSettlementStatus = .notRecorded
    var transactionLevy: Double = 0
    var tradingFee: Double = 0

    init(
        id: UUID,
        occurredAt: Date,
        kind: PortfolioTransactionKind,
        assetID: String?,
        assetName: String,
        symbol: String,
        assetType: AssetType?,
        currency: String,
        quantity: Double,
        unitPrice: Double,
        amount: Double,
        fee: Double,
        tax: Double,
        note: String,
        accountID: UUID? = nil,
        targetAccountID: UUID? = nil,
        targetCurrency: String = "",
        targetAmount: Double = 0,
        tradeDate: String = "",
        marketTimeZone: String = "",
        executedAt: Date? = nil,
        settlementDate: String? = nil,
        settlementStatus: PortfolioSettlementStatus = .notRecorded,
        transactionLevy: Double = 0,
        tradingFee: Double = 0
    ) {
        self.id = id
        self.occurredAt = occurredAt
        self.kind = kind
        self.assetID = assetID
        self.assetName = assetName
        self.symbol = symbol
        self.assetType = assetType
        self.currency = currency
        self.quantity = quantity
        self.unitPrice = unitPrice
        self.amount = amount
        self.fee = fee
        self.tax = tax
        self.note = note
        self.accountID = accountID
        self.targetAccountID = targetAccountID
        self.targetCurrency = targetCurrency
        self.targetAmount = targetAmount
        self.tradeDate = PortfolioDate.date(from: tradeDate) == nil
            ? PortfolioDate.string(from: occurredAt)
            : tradeDate
        self.marketTimeZone = marketTimeZone
        self.executedAt = executedAt
        self.settlementDate = settlementDate.flatMap { PortfolioDate.date(from: $0) == nil ? nil : $0 }
        self.settlementStatus = settlementStatus
        self.transactionLevy = transactionLevy
        self.tradingFee = tradingFee
    }

    private enum CodingKeys: String, CodingKey {
        case id, occurredAt, kind, assetID, assetName, symbol, assetType, currency, quantity, unitPrice, amount, fee, tax, note
        case accountID, targetAccountID, targetCurrency, targetAmount
        case tradeDate, marketTimeZone, executedAt, settlementDate, settlementStatus, transactionLevy, tradingFee
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let occurredAt = try container.decode(Date.self, forKey: .occurredAt)
        self.init(
            id: try container.decode(UUID.self, forKey: .id),
            occurredAt: occurredAt,
            kind: try container.decode(PortfolioTransactionKind.self, forKey: .kind),
            assetID: try container.decodeIfPresent(String.self, forKey: .assetID),
            assetName: try container.decodeIfPresent(String.self, forKey: .assetName) ?? "",
            symbol: try container.decodeIfPresent(String.self, forKey: .symbol) ?? "",
            assetType: try container.decodeIfPresent(AssetType.self, forKey: .assetType),
            currency: try container.decodeIfPresent(String.self, forKey: .currency) ?? "",
            quantity: try container.decodeIfPresent(Double.self, forKey: .quantity) ?? 0,
            unitPrice: try container.decodeIfPresent(Double.self, forKey: .unitPrice) ?? 0,
            amount: try container.decodeIfPresent(Double.self, forKey: .amount) ?? 0,
            fee: try container.decodeIfPresent(Double.self, forKey: .fee) ?? 0,
            tax: try container.decodeIfPresent(Double.self, forKey: .tax) ?? 0,
            note: try container.decodeIfPresent(String.self, forKey: .note) ?? "",
            accountID: try container.decodeIfPresent(UUID.self, forKey: .accountID),
            targetAccountID: try container.decodeIfPresent(UUID.self, forKey: .targetAccountID),
            targetCurrency: try container.decodeIfPresent(String.self, forKey: .targetCurrency) ?? "",
            targetAmount: try container.decodeIfPresent(Double.self, forKey: .targetAmount) ?? 0,
            tradeDate: try container.decodeIfPresent(String.self, forKey: .tradeDate) ?? PortfolioDate.string(from: occurredAt),
            marketTimeZone: try container.decodeIfPresent(String.self, forKey: .marketTimeZone) ?? "",
            executedAt: try container.decodeIfPresent(Date.self, forKey: .executedAt),
            settlementDate: try container.decodeIfPresent(String.self, forKey: .settlementDate),
            settlementStatus: try container.decodeIfPresent(PortfolioSettlementStatus.self, forKey: .settlementStatus) ?? .notRecorded,
            transactionLevy: try container.decodeIfPresent(Double.self, forKey: .transactionLevy) ?? 0,
            tradingFee: try container.decodeIfPresent(Double.self, forKey: .tradingFee) ?? 0
        )
    }

    var grossAmount: Double {
        kind.isTrade && kind != .opening ? quantity * unitPrice : amount
    }

    var totalCharges: Double {
        fee + transactionLevy + tradingFee + tax
    }

    var costAmount: Double {
        quantity * unitPrice + totalCharges
    }

    var netProceeds: Double {
        quantity * unitPrice - totalCharges
    }

    static func trade(
        asset: TrackedAsset,
        name: String,
        kind: PortfolioTransactionKind,
        occurredAt: Date,
        quantity: Double,
        unitPrice: Double,
        fee: Double,
        tax: Double,
        note: String,
        accountID: UUID? = nil,
        tradeDate: String? = nil,
        marketTimeZone: String = "",
        settlementDate: String? = nil,
        settlementStatus: PortfolioSettlementStatus = .pending,
        transactionLevy: Double = 0,
        tradingFee: Double = 0
    ) -> PortfolioTransaction {
        PortfolioTransaction(
            id: UUID(),
            occurredAt: occurredAt,
            kind: kind,
            assetID: assetIdentity(for: asset),
            assetName: name,
            symbol: asset.symbol,
            assetType: asset.type,
            currency: portfolioCurrency(for: asset),
            quantity: quantity,
            unitPrice: unitPrice,
            amount: quantity * unitPrice,
            fee: fee,
            tax: tax,
            note: note,
            accountID: accountID,
            tradeDate: tradeDate ?? PortfolioDate.string(from: occurredAt),
            marketTimeZone: marketTimeZone,
            settlementDate: settlementDate,
            settlementStatus: settlementStatus,
            transactionLevy: transactionLevy,
            tradingFee: tradingFee
        )
    }
}

struct PortfolioPosition {
    var assetID: String
    var accountID: UUID?
    var name: String
    var symbol: String
    var currency: String
    var quantity: Double
    var costBasis: Double
    var averageCost: Double
    var currentPrice: Double?
    var marketValue: Double?
    var realizedPnl: Double
    var unrealizedPnl: Double?
    var totalInvested: Double
    var totalProceeds: Double

    var returnPercent: Double? {
        guard costBasis > 0, let unrealizedPnl else { return nil }
        return unrealizedPnl / costBasis * 100
    }
}

struct PortfolioCurrencySummary {
    var currency: String
    var grossInvested: Double = 0
    var grossProceeds: Double = 0
    var marketValue: Double = 0
    var cashBalance: Double = 0
    var netWorth: Double = 0
    var realizedPnl: Double = 0
    var unrealizedPnl: Double = 0
    var dividends: Double = 0
    var totalPnl: Double = 0
    var hasFundingRecords = false

    var availableAssetsValue: Double {
        hasFundingRecords ? netWorth : marketValue
    }
}

struct PortfolioSummary {
    var positions: [PortfolioPosition]
    var currencies: [String: PortfolioCurrencySummary]

    static let empty = PortfolioSummary(positions: [], currencies: [:])

    var primaryCurrency: String? {
        currencies.keys.sorted().first
    }
}

enum PortfolioMarket: String, CaseIterable, Codable, Sendable, Hashable {
    case all
    case us
    case hk
    case cn

    var title: String {
        switch self {
        case .all: return "全部"
        case .us: return "美股"
        case .hk: return "港股"
        case .cn: return "大A"
        }
    }

    func includes(assetID: String?) -> Bool {
        guard self != .all, let assetID = assetID?.uppercased() else { return self == .all }
        switch self {
        case .all: return true
        case .us: return assetID.hasPrefix("STOCK-US:")
        case .hk: return assetID.hasPrefix("STOCK-HK:")
        case .cn: return assetID.hasPrefix("STOCK-SH:") || assetID.hasPrefix("STOCK-SZ:")
        }
    }
}

enum PortfolioChartMetric: String, CaseIterable {
    case invested
    case marketValue
    case netWorth
    case totalPnl

    var title: String {
        switch self {
        case .invested: return "累计投入"
        case .marketValue: return "持仓市值"
        case .netWorth: return "总资产"
        case .totalPnl: return "累计盈亏"
        }
    }
}

struct PortfolioSnapshot {
    var capturedAt: Date
    var market: PortfolioMarket
    var currency: String
    var invested: Double
    var proceeds: Double
    var marketValue: Double
    var cashBalance: Double?
    var netWorth: Double?
    var realizedPnl: Double
    var unrealizedPnl: Double
    var totalPnl: Double

    func value(for metric: PortfolioChartMetric) -> Double? {
        switch metric {
        case .invested: return invested
        case .marketValue: return marketValue
        case .netWorth: return netWorth
        case .totalPnl: return totalPnl
        }
    }
}

struct PortfolioExchangeRates: Sendable {
    private var usdToCurrency: [String: [StockChartPoint]]

    init(usdToCurrency: [String: [StockChartPoint]] = [:]) {
        self.usdToCurrency = usdToCurrency
    }

    func convert(_ amount: Double, from source: String, to target: String, at date: Date) -> Double? {
        guard let sourceToUSD = rateToUSD(for: source, at: date),
              let usdToTarget = rateFromUSD(for: target, at: date) else {
            return nil
        }
        return amount * sourceToUSD * usdToTarget
    }

    func convert(summary: PortfolioSummary, to currency: String, at date: Date) -> PortfolioCurrencySummary? {
        let target = normalizedCurrency(currency)
        var converted = PortfolioCurrencySummary(currency: target)
        for native in summary.currencies.values {
            guard let factor = convert(1, from: native.currency, to: target, at: date) else {
                return nil
            }
            converted.grossInvested += native.grossInvested * factor
            converted.grossProceeds += native.grossProceeds * factor
            converted.marketValue += native.marketValue * factor
            converted.cashBalance += native.cashBalance * factor
            converted.netWorth += native.netWorth * factor
            converted.realizedPnl += native.realizedPnl * factor
            converted.unrealizedPnl += native.unrealizedPnl * factor
            converted.dividends += native.dividends * factor
            converted.totalPnl += native.totalPnl * factor
            converted.hasFundingRecords = converted.hasFundingRecords || native.hasFundingRecords
        }
        return converted
    }

    private func rateToUSD(for currency: String, at date: Date) -> Double? {
        let normalized = normalizedCurrency(currency)
        guard normalized != "USD", let rate = rateFromUSD(for: normalized, at: date), rate > 0 else {
            return normalized == "USD" ? 1 : nil
        }
        return 1 / rate
    }

    private func rateFromUSD(for currency: String, at date: Date) -> Double? {
        let normalized = normalizedCurrency(currency)
        guard normalized != "USD" else { return 1 }
        guard let points = usdToCurrency[normalized], !points.isEmpty else { return nil }
        return (points.last(where: { $0.date <= date }) ?? points.first)?.price
    }

    private func normalizedCurrency(_ currency: String) -> String {
        switch currency.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() {
        case "USDT", "USDC": return "USD"
        case "CNH": return "CNY"
        default: return currency.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        }
    }
}

enum PortfolioHistoryBuilder {
    static func rebuild(
        transactions: [PortfolioTransaction],
        assets: [DisplayAsset],
        priceHistories: [String: [StockChartPoint]],
        exchangeRates: PortfolioExchangeRates,
        now: Date = Date()
    ) -> [PortfolioSnapshot] {
        guard let firstTransaction = transactions.map(\.occurredAt).min() else { return [] }
        let calendar = Calendar(identifier: .gregorian)
        let firstDay = calendar.startOfDay(for: firstTransaction)
        var dates = Set<Date>()

        for points in priceHistories.values {
            for point in points where point.date >= firstDay {
                dates.insert(calendar.startOfDay(for: point.date))
            }
        }
        for transaction in transactions where transaction.occurredAt >= firstDay {
            dates.insert(calendar.startOfDay(for: transaction.occurredAt))
        }
        dates.insert(calendar.startOfDay(for: now))

        let liveAssets = Dictionary(uniqueKeysWithValues: assets.map { ($0.id, $0) })
        let sortedDates = dates.sorted()
        var snapshots: [PortfolioSnapshot] = []
        snapshots.reserveCapacity(sortedDates.count * PortfolioMarket.allCases.count * 3)

        for day in sortedDates {
            let dayEnd = calendar.date(byAdding: DateComponents(day: 1, second: -1), to: day) ?? day
            let datedTransactions = transactions.filter { $0.occurredAt <= dayEnd }
            let datedAssets = assets.map { asset -> DisplayAsset in
                var historical = asset
                if let points = priceHistories[asset.id],
                   let price = (points.last(where: { $0.date <= dayEnd }) ?? points.first)?.price {
                    historical.currentPrice = price
                } else if let current = liveAssets[asset.id]?.currentPrice {
                    historical.currentPrice = current
                }
                return historical
            }

            for market in PortfolioMarket.allCases {
                let summary = PortfolioCalculator.calculate(
                    transactions: datedTransactions,
                    assets: datedAssets,
                    market: market
                )
                for currency in ["USD", "HKD", "CNY"] {
                    guard let converted = exchangeRates.convert(summary: summary, to: currency, at: dayEnd) else { continue }
                    snapshots.append(PortfolioSnapshot(
                        capturedAt: dayEnd,
                        market: market,
                        currency: currency,
                        invested: converted.grossInvested,
                        proceeds: converted.grossProceeds,
                        marketValue: converted.marketValue,
                        cashBalance: converted.hasFundingRecords ? converted.cashBalance : nil,
                        netWorth: converted.hasFundingRecords ? converted.netWorth : nil,
                        realizedPnl: converted.realizedPnl,
                        unrealizedPnl: converted.unrealizedPnl,
                        totalPnl: converted.totalPnl
                    ))
                }
            }
        }
        return snapshots
    }
}

private let careSQLiteTransient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

final class PortfolioStore {
    private let databaseURL: URL
    private let journalMode: String
    private var database: OpaquePointer?

    init(databaseURL overrideURL: URL? = nil, journalMode: String = "WAL") {
        let directory = overrideURL?.deletingLastPathComponent() ?? ConfigStore.appSupportURL
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        databaseURL = overrideURL ?? directory.appendingPathComponent("CareAssets.sqlite3")
        self.journalMode = journalMode
        do {
            try open()
            try createSchema()
            try migrateTransactionsToDateOnlyIfNeeded()
        } catch {
            NSLog("CareAssets portfolio database failed: \(error.localizedDescription)")
        }
    }

    deinit {
        close()
    }

    func close() {
        guard let database else { return }
        sqlite3_close(database)
        self.database = nil
    }

    func loadOrCreateConfiguration(legacyConfig: AppConfig?) -> AppConfig {
        guard hasMetadata("sqlite_configuration_v1") else {
            let initial = legacyConfig ?? AppConfig.defaultConfig
            do {
                try saveConfiguration(initial)
            } catch {
                NSLog("CareAssets configuration database migration failed: \(error.localizedDescription)")
            }
            return initial
        }
        return loadConfiguration()
    }

    func loadConfiguration() -> AppConfig {
        var config = AppConfig.defaultConfig
        config.refreshIntervalSeconds = Int(setting("refresh_interval_seconds") ?? "") ?? config.refreshIntervalSeconds
        config.menuBarMaxItems = Int(setting("menu_bar_max_items") ?? "") ?? config.menuBarMaxItems
        config.stockDisplayCurrency = setting("stock_display_currency") ?? config.stockDisplayCurrency
        config.priceColorMode = setting("price_color_mode").flatMap(PriceColorMode.init(rawValue:)) ?? config.priceColorMode
        config.statusBarBackgroundMode = setting("status_bar_background_mode").flatMap(StatusBarBackgroundMode.init(rawValue:)) ?? config.statusBarBackgroundMode
        config.stockDataSource = setting("stock_data_source").flatMap(StockDataSource.init(rawValue:)) ?? config.stockDataSource
        config.stockChartPeriod = setting("stock_chart_period").flatMap(StockChartPeriod.init(rawValue:)) ?? config.stockChartPeriod
        config.showPositionSummary = setting("show_position_summary") == "1"
        config.iCloudDriveSyncEnabled = setting("icloud_drive_sync_enabled") == "1"
        config.syncFolderPath = setting("sync_folder_path")
        config.language = setting("language").flatMap(AppLanguage.init(rawValue:)) ?? config.language
        config.assets = loadTrackedAssets()
        return config
    }

    func saveConfiguration(_ config: AppConfig) throws {
        try execute("BEGIN IMMEDIATE TRANSACTION")
        do {
            try setSetting("refresh_interval_seconds", value: String(config.refreshIntervalSeconds))
            try setSetting("menu_bar_max_items", value: String(config.menuBarMaxItems))
            try setSetting("stock_display_currency", value: config.stockDisplayCurrency)
            try setSetting("price_color_mode", value: config.priceColorMode.rawValue)
            try setSetting("status_bar_background_mode", value: config.statusBarBackgroundMode.rawValue)
            try setSetting("stock_data_source", value: config.stockDataSource.rawValue)
            try setSetting("stock_chart_period", value: config.stockChartPeriod.rawValue)
            try setSetting("show_position_summary", value: config.showPositionSummary ? "1" : "0")
            try setSetting("icloud_drive_sync_enabled", value: config.iCloudDriveSyncEnabled ? "1" : "0")
            try setSetting("sync_folder_path", value: config.syncFolderPath)
            try setSetting("language", value: config.language.rawValue)
            try replaceTrackedAssets(config.assets)
            try setMetadata("sqlite_configuration_v1", value: "1")
            try execute("COMMIT")
        } catch {
            try? execute("ROLLBACK")
            throw error
        }
    }

    func replaceSyncSnapshot(
        assets: [TrackedAsset],
        accounts: [PortfolioAccount],
        transactions: [PortfolioTransaction]
    ) throws {
        var syncConfiguration = AppConfig.defaultConfig
        syncConfiguration.assets = assets
        try saveConfiguration(syncConfiguration)
        try replaceLedger(accounts: accounts, transactions: transactions)
        try setMetadata("sqlite_sync_snapshot_v1", value: "1")
        try setMetadata("sqlite_sync_snapshot_modified_at", value: String(Date().timeIntervalSince1970))
    }

    func loadSyncSnapshot() throws -> (assets: [TrackedAsset], accounts: [PortfolioAccount], transactions: [PortfolioTransaction]) {
        guard hasMetadata("sqlite_sync_snapshot_v1") else {
            throw NSError(domain: "CareAssets.AssetSync", code: 1, userInfo: [NSLocalizedDescriptionKey: "同步数据库格式不正确。"])
        }
        return (loadTrackedAssets(), loadAccounts(), loadTransactions())
    }

    func loadTransactions() -> [PortfolioTransaction] {
        guard let database else { return [] }
        let sql = """
        SELECT id, occurred_at, kind, asset_id, asset_name, symbol, asset_type,
               currency, quantity, unit_price, amount, fee, tax, note,
               account_id, target_account_id, target_currency, target_amount,
               trade_date, market_time_zone, executed_at, settlement_date,
               settlement_status, transaction_levy, trading_fee
        FROM transactions
        ORDER BY occurred_at ASC, created_at ASC
        """
        guard let statement = prepare(sql, database: database) else { return [] }
        defer { sqlite3_finalize(statement) }

        var transactions: [PortfolioTransaction] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            guard let idText = text(statement, 0),
                  let kindText = text(statement, 2),
                  let kind = PortfolioTransactionKind(rawValue: kindText) else { continue }
            let transaction = PortfolioTransaction(
                id: UUID(uuidString: idText) ?? UUID(),
                occurredAt: Date(timeIntervalSince1970: sqlite3_column_double(statement, 1)),
                kind: kind,
                assetID: text(statement, 3),
                assetName: text(statement, 4) ?? "",
                symbol: text(statement, 5) ?? "",
                assetType: text(statement, 6).flatMap(AssetType.init(rawValue:)),
                currency: text(statement, 7) ?? "",
                quantity: sqlite3_column_double(statement, 8),
                unitPrice: sqlite3_column_double(statement, 9),
                amount: sqlite3_column_double(statement, 10),
                fee: sqlite3_column_double(statement, 11),
                tax: sqlite3_column_double(statement, 12),
                note: text(statement, 13) ?? "",
                accountID: text(statement, 14).flatMap(UUID.init(uuidString:)),
                targetAccountID: text(statement, 15).flatMap(UUID.init(uuidString:)),
                targetCurrency: text(statement, 16) ?? "",
                targetAmount: sqlite3_column_double(statement, 17),
                tradeDate: text(statement, 18) ?? "",
                marketTimeZone: text(statement, 19) ?? "",
                executedAt: number(statement, 20).map(Date.init(timeIntervalSince1970:)),
                settlementDate: text(statement, 21),
                settlementStatus: text(statement, 22).flatMap(PortfolioSettlementStatus.init(rawValue:)) ?? .notRecorded,
                transactionLevy: sqlite3_column_double(statement, 23),
                tradingFee: sqlite3_column_double(statement, 24)
            )
            transactions.append(transaction)
        }
        return transactions
    }

    func insert(_ transaction: PortfolioTransaction) throws {
        try insertTransaction(transaction, createdAt: Date(), updatedAt: Date())
    }

    func replaceLedger(accounts: [PortfolioAccount], transactions: [PortfolioTransaction]) throws {
        let accountIDs = Set(accounts.map(\.id))
        guard accountIDs.count == accounts.count else {
            throw NSError(domain: "CareAssets.PortfolioDatabase", code: 5, userInfo: [NSLocalizedDescriptionKey: "同步数据中存在重复账户。"])
        }
        guard transactions.allSatisfy({ transaction in
            (transaction.accountID == nil || accountIDs.contains(transaction.accountID!)) &&
            (transaction.targetAccountID == nil || accountIDs.contains(transaction.targetAccountID!))
        }) else {
            throw NSError(domain: "CareAssets.PortfolioDatabase", code: 6, userInfo: [NSLocalizedDescriptionKey: "同步交易引用了不存在的账户。"])
        }

        try execute("BEGIN IMMEDIATE TRANSACTION")
        do {
            try execute("DELETE FROM transactions")
            try execute("DELETE FROM portfolio_accounts")
            try execute("DELETE FROM portfolio_snapshots")
            for account in accounts {
                try insert(account)
            }
            for transaction in transactions {
                try insertTransaction(
                    transaction,
                    createdAt: transaction.occurredAt,
                    updatedAt: transaction.occurredAt
                )
            }
            try execute("COMMIT")
            try migrateTransactionsToDateOnlyIfNeeded()
        } catch {
            try? execute("ROLLBACK")
            throw error
        }
    }

    private func insertTransaction(
        _ transaction: PortfolioTransaction,
        createdAt: Date,
        updatedAt: Date
    ) throws {
        let sql = """
        INSERT INTO transactions
        (id, occurred_at, kind, asset_id, asset_name, symbol, asset_type, currency,
         quantity, unit_price, amount, fee, tax, note, account_id, target_account_id,
         target_currency, target_amount, trade_date, market_time_zone, executed_at,
         settlement_date, settlement_status, transaction_levy, trading_fee, created_at, updated_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """
        try perform(sql) { statement in
            bind(statement, index: 1, value: transaction.id.uuidString)
            bind(statement, index: 2, value: transaction.occurredAt.timeIntervalSince1970)
            bind(statement, index: 3, value: transaction.kind.rawValue)
            bind(statement, index: 4, value: transaction.assetID)
            bind(statement, index: 5, value: transaction.assetName)
            bind(statement, index: 6, value: transaction.symbol)
            bind(statement, index: 7, value: transaction.assetType?.rawValue)
            bind(statement, index: 8, value: transaction.currency.uppercased())
            bind(statement, index: 9, value: transaction.quantity)
            bind(statement, index: 10, value: transaction.unitPrice)
            bind(statement, index: 11, value: transaction.amount)
            bind(statement, index: 12, value: transaction.fee)
            bind(statement, index: 13, value: transaction.tax)
            bind(statement, index: 14, value: transaction.note)
            bind(statement, index: 15, value: transaction.accountID?.uuidString)
            bind(statement, index: 16, value: transaction.targetAccountID?.uuidString)
            bind(statement, index: 17, value: transaction.targetCurrency.uppercased())
            bind(statement, index: 18, value: transaction.targetAmount)
            bind(statement, index: 19, value: transaction.tradeDate)
            bind(statement, index: 20, value: transaction.marketTimeZone)
            bind(statement, index: 21, value: transaction.executedAt?.timeIntervalSince1970)
            bind(statement, index: 22, value: transaction.settlementDate)
            bind(statement, index: 23, value: transaction.settlementStatus.rawValue)
            bind(statement, index: 24, value: transaction.transactionLevy)
            bind(statement, index: 25, value: transaction.tradingFee)
            bind(statement, index: 26, value: createdAt.timeIntervalSince1970)
            bind(statement, index: 27, value: updatedAt.timeIntervalSince1970)
        }
    }

    func update(_ transaction: PortfolioTransaction) throws {
        let sql = """
        UPDATE transactions
        SET occurred_at = ?, kind = ?, asset_id = ?, asset_name = ?, symbol = ?, asset_type = ?,
            currency = ?, quantity = ?, unit_price = ?, amount = ?, fee = ?, tax = ?, note = ?,
            account_id = ?, target_account_id = ?, target_currency = ?, target_amount = ?,
            trade_date = ?, market_time_zone = ?, executed_at = ?, settlement_date = ?,
            settlement_status = ?, transaction_levy = ?, trading_fee = ?, updated_at = ?
        WHERE id = ?
        """
        try perform(sql) { statement in
            bind(statement, index: 1, value: transaction.occurredAt.timeIntervalSince1970)
            bind(statement, index: 2, value: transaction.kind.rawValue)
            bind(statement, index: 3, value: transaction.assetID)
            bind(statement, index: 4, value: transaction.assetName)
            bind(statement, index: 5, value: transaction.symbol)
            bind(statement, index: 6, value: transaction.assetType?.rawValue)
            bind(statement, index: 7, value: transaction.currency.uppercased())
            bind(statement, index: 8, value: transaction.quantity)
            bind(statement, index: 9, value: transaction.unitPrice)
            bind(statement, index: 10, value: transaction.amount)
            bind(statement, index: 11, value: transaction.fee)
            bind(statement, index: 12, value: transaction.tax)
            bind(statement, index: 13, value: transaction.note)
            bind(statement, index: 14, value: transaction.accountID?.uuidString)
            bind(statement, index: 15, value: transaction.targetAccountID?.uuidString)
            bind(statement, index: 16, value: transaction.targetCurrency.uppercased())
            bind(statement, index: 17, value: transaction.targetAmount)
            bind(statement, index: 18, value: transaction.tradeDate)
            bind(statement, index: 19, value: transaction.marketTimeZone)
            bind(statement, index: 20, value: transaction.executedAt?.timeIntervalSince1970)
            bind(statement, index: 21, value: transaction.settlementDate)
            bind(statement, index: 22, value: transaction.settlementStatus.rawValue)
            bind(statement, index: 23, value: transaction.transactionLevy)
            bind(statement, index: 24, value: transaction.tradingFee)
            bind(statement, index: 25, value: Date().timeIntervalSince1970)
            bind(statement, index: 26, value: transaction.id.uuidString)
        }
    }

    func delete(id: UUID) throws {
        try perform("DELETE FROM transactions WHERE id = ?") { statement in
            bind(statement, index: 1, value: id.uuidString)
        }
    }

    func loadTrackedAssets() -> [TrackedAsset] {
        guard let database,
              let statement = prepare("SELECT type, name, symbol, canonical_symbol, visible_in_menu_bar FROM tracked_assets ORDER BY sort_index ASC", database: database) else { return [] }
        defer { sqlite3_finalize(statement) }

        var assets: [TrackedAsset] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            guard let typeText = text(statement, 0),
                  let type = AssetType(rawValue: typeText),
                  let name = text(statement, 1),
                  let symbol = text(statement, 2) else { continue }
            assets.append(TrackedAsset(
                type: type,
                name: name,
                symbol: symbol,
                canonicalSymbol: text(statement, 3),
                visibleInMenuBar: sqlite3_column_int(statement, 4) != 0
            ))
        }
        return assets
    }

    func loadAccounts() -> [PortfolioAccount] {
        guard let database,
              let statement = prepare("SELECT id, name, created_at FROM portfolio_accounts ORDER BY created_at ASC, name ASC", database: database) else { return [] }
        defer { sqlite3_finalize(statement) }

        var accounts: [PortfolioAccount] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            guard let idText = text(statement, 0), let id = UUID(uuidString: idText) else { continue }
            accounts.append(PortfolioAccount(
                id: id,
                name: text(statement, 1) ?? "未命名账户",
                createdAt: Date(timeIntervalSince1970: sqlite3_column_double(statement, 2))
            ))
        }
        return accounts
    }

    @discardableResult
    func createAccount(name: String) throws -> PortfolioAccount {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            throw NSError(domain: "CareAssets.PortfolioDatabase", code: 2, userInfo: [NSLocalizedDescriptionKey: "账户名称不能为空"])
        }
        let account = PortfolioAccount(name: trimmedName)
        try insert(account)
        return account
    }

    func renameAccount(id: UUID, name: String) throws {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            throw NSError(domain: "CareAssets.PortfolioDatabase", code: 3, userInfo: [NSLocalizedDescriptionKey: "账户名称不能为空"])
        }
        try perform("UPDATE portfolio_accounts SET name = ? WHERE id = ?") { statement in
            bind(statement, index: 1, value: trimmedName)
            bind(statement, index: 2, value: id.uuidString)
        }
    }

    func deleteAccount(id: UUID) throws {
        guard let database,
              let statement = prepare("SELECT COUNT(*) FROM transactions WHERE account_id = ? OR target_account_id = ?", database: database) else {
            throw databaseError()
        }
        defer { sqlite3_finalize(statement) }
        bind(statement, index: 1, value: id.uuidString)
        bind(statement, index: 2, value: id.uuidString)
        guard sqlite3_step(statement) == SQLITE_ROW else { throw databaseError() }
        guard sqlite3_column_int(statement, 0) == 0 else {
            throw NSError(domain: "CareAssets.PortfolioDatabase", code: 4, userInfo: [NSLocalizedDescriptionKey: "该账户已有交易记录，不能删除。请先将交易改到其他账户。"])
        }
        try perform("DELETE FROM portfolio_accounts WHERE id = ?") { statement in
            bind(statement, index: 1, value: id.uuidString)
        }
    }

    func migrateTransactionsToHSBCHKIfNeeded() {
        let metadataKey = "transactions_assigned_hsbc_hk_v1"
        guard !hasMetadata(metadataKey) else { return }
        do {
            let account = try existingOrCreateAccount(named: "HSBC HK")
            try perform("UPDATE transactions SET account_id = ?") { statement in
                bind(statement, index: 1, value: account.id.uuidString)
            }
            try setMetadata(metadataKey, value: "1")
        } catch {
            NSLog("CareAssets account migration failed: \(error.localizedDescription)")
        }
    }

    private func migrateTransactionsToDateOnlyIfNeeded() throws {
        let metadataKey = "transactions_date_only_v1"
        guard !hasMetadata(metadataKey) || hasTransactionsNeedingDateOnlyMigration() else { return }

        let transactions = loadTransactions()
        try execute("BEGIN IMMEDIATE TRANSACTION")
        do {
            for transaction in transactions {
                let tradeDate = PortfolioDate.string(from: transaction.occurredAt)
                let marketTimeZone = transaction.kind.isTrade
                    ? portfolioMarketTimeZone(forAssetID: transaction.assetID)
                    : ""
                let settlementStatus: PortfolioSettlementStatus = transaction.kind.isTrade ? .notRecorded : .notApplicable
                try perform("""
                UPDATE transactions
                SET occurred_at = ?, trade_date = ?, market_time_zone = ?, executed_at = NULL,
                    settlement_date = NULL, settlement_status = ?, transaction_levy = 0, trading_fee = 0
                WHERE id = ?
                """) { statement in
                    bind(statement, index: 1, value: PortfolioDate.date(from: tradeDate)?.timeIntervalSince1970)
                    bind(statement, index: 2, value: tradeDate)
                    bind(statement, index: 3, value: marketTimeZone)
                    bind(statement, index: 4, value: settlementStatus.rawValue)
                    bind(statement, index: 5, value: transaction.id.uuidString)
                }
            }
            try setMetadata(metadataKey, value: "1")
            try execute("COMMIT")
        } catch {
            try? execute("ROLLBACK")
            throw error
        }
    }

    private func hasTransactionsNeedingDateOnlyMigration() -> Bool {
        guard let database,
              let statement = prepare("""
              SELECT COUNT(*)
              FROM transactions
              WHERE trade_date IS NULL OR trade_date = '' OR executed_at IS NOT NULL
                 OR (kind IN ('buy', 'sell', 'opening') AND (market_time_zone IS NULL OR market_time_zone = ''))
              """, database: database) else {
            return false
        }
        defer { sqlite3_finalize(statement) }
        guard sqlite3_step(statement) == SQLITE_ROW else { return false }
        return sqlite3_column_int(statement, 0) > 0
    }

    @discardableResult
    func resetSnapshotsForPortfolioHistoryV2IfNeeded() -> Bool {
        let metadataKey = "portfolio_history_v2"
        guard !hasMetadata(metadataKey) else { return false }
        do {
            try replaceSnapshots([])
            try setMetadata(metadataKey, value: "1")
            return true
        } catch {
            NSLog("CareAssets portfolio snapshot reset failed: \(error.localizedDescription)")
            return false
        }
    }

    func migrateLegacyPositions(from assets: [TrackedAsset]) {
        guard !hasMetadata("legacy_positions_migrated") else { return }
        do {
            for asset in assets {
                guard let quantity = asset.legacyHoldingQuantity,
                      let averagePrice = asset.legacyAverageBuyPrice,
                      quantity > 0,
                      averagePrice > 0 else { continue }
                let transaction = PortfolioTransaction(
                    id: UUID(),
                    occurredAt: Date(),
                    kind: .opening,
                    assetID: assetIdentity(for: asset),
                    assetName: asset.name,
                    symbol: asset.symbol,
                    assetType: asset.type,
                    currency: portfolioCurrency(for: asset),
                    quantity: quantity,
                    unitPrice: averagePrice,
                    amount: quantity * averagePrice,
                    fee: 0,
                    tax: 0,
                    note: "从旧版持仓迁移"
                )
                try insert(transaction)
            }
            try setMetadata("legacy_positions_migrated", value: "1")
        } catch {
            NSLog("CareAssets legacy position migration failed: \(error.localizedDescription)")
        }
    }

    func recordSnapshots(summary: PortfolioSummary, at date: Date = Date(), force: Bool = false) {
        do {
            for currency in summary.currencies.values {
                guard force || shouldRecordSnapshot(currency: currency.currency, at: date) else { continue }
                let snapshot = PortfolioSnapshot(
                    capturedAt: date,
                    market: .all,
                    currency: currency.currency,
                    invested: currency.grossInvested,
                    proceeds: currency.grossProceeds,
                    marketValue: currency.marketValue,
                    cashBalance: currency.hasFundingRecords ? currency.cashBalance : nil,
                    netWorth: currency.hasFundingRecords ? currency.netWorth : nil,
                    realizedPnl: currency.realizedPnl,
                    unrealizedPnl: currency.unrealizedPnl,
                    totalPnl: currency.totalPnl
                )
                try insert(snapshot)
            }
        } catch {
            NSLog("CareAssets portfolio snapshot failed: \(error.localizedDescription)")
        }
    }

    func loadSnapshots(currency: String, limit: Int = 4000) -> [PortfolioSnapshot] {
        guard let database else { return [] }
        let sql = """
        SELECT captured_at, market, currency, invested, proceeds, market_value, cash_balance,
               net_worth, realized_pnl, unrealized_pnl, total_pnl
        FROM portfolio_snapshots
        WHERE currency = ?
        ORDER BY captured_at DESC
        LIMIT ?
        """
        guard let statement = prepare(sql, database: database) else { return [] }
        defer { sqlite3_finalize(statement) }
        bind(statement, index: 1, value: currency.uppercased())
        bind(statement, index: 2, value: Int32(limit))

        var snapshots: [PortfolioSnapshot] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            snapshots.append(PortfolioSnapshot(
                capturedAt: Date(timeIntervalSince1970: sqlite3_column_double(statement, 0)),
                market: PortfolioMarket(rawValue: text(statement, 1) ?? "") ?? .all,
                currency: text(statement, 2) ?? currency,
                invested: sqlite3_column_double(statement, 3),
                proceeds: sqlite3_column_double(statement, 4),
                marketValue: sqlite3_column_double(statement, 5),
                cashBalance: number(statement, 6),
                netWorth: number(statement, 7),
                realizedPnl: sqlite3_column_double(statement, 8),
                unrealizedPnl: sqlite3_column_double(statement, 9),
                totalPnl: sqlite3_column_double(statement, 10)
            ))
        }
        return snapshots.reversed()
    }

    func loadSnapshots(limit: Int = 4000) -> [PortfolioSnapshot] {
        guard let database else { return [] }
        let sql = """
        SELECT captured_at, market, currency, invested, proceeds, market_value, cash_balance,
               net_worth, realized_pnl, unrealized_pnl, total_pnl
        FROM portfolio_snapshots
        ORDER BY captured_at ASC
        LIMIT ?
        """
        guard let statement = prepare(sql, database: database) else { return [] }
        defer { sqlite3_finalize(statement) }
        bind(statement, index: 1, value: Int32(limit))

        var snapshots: [PortfolioSnapshot] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            snapshots.append(PortfolioSnapshot(
                capturedAt: Date(timeIntervalSince1970: sqlite3_column_double(statement, 0)),
                market: PortfolioMarket(rawValue: text(statement, 1) ?? "") ?? .all,
                currency: text(statement, 2) ?? "",
                invested: sqlite3_column_double(statement, 3),
                proceeds: sqlite3_column_double(statement, 4),
                marketValue: sqlite3_column_double(statement, 5),
                cashBalance: number(statement, 6),
                netWorth: number(statement, 7),
                realizedPnl: sqlite3_column_double(statement, 8),
                unrealizedPnl: sqlite3_column_double(statement, 9),
                totalPnl: sqlite3_column_double(statement, 10)
            ))
        }
        return snapshots
    }

    func replaceSnapshots(_ snapshots: [PortfolioSnapshot]) throws {
        try execute("BEGIN IMMEDIATE TRANSACTION")
        do {
            try execute("DELETE FROM portfolio_snapshots")
            for snapshot in snapshots {
                try insert(snapshot)
            }
            try execute("COMMIT")
        } catch {
            try? execute("ROLLBACK")
            throw error
        }
    }

    private func shouldRecordSnapshot(currency: String, at date: Date) -> Bool {
        guard let database,
              let statement = prepare("SELECT captured_at FROM portfolio_snapshots WHERE currency = ? ORDER BY captured_at DESC LIMIT 1", database: database) else { return true }
        defer { sqlite3_finalize(statement) }
        bind(statement, index: 1, value: currency.uppercased())
        guard sqlite3_step(statement) == SQLITE_ROW else { return true }
        let latest = sqlite3_column_double(statement, 0)
        return date.timeIntervalSince1970 - latest >= 900
    }

    private func open() throws {
        let flags = SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE | SQLITE_OPEN_FULLMUTEX
        guard sqlite3_open_v2(databaseURL.path, &database, flags, nil) == SQLITE_OK else {
            throw databaseError()
        }
        try execute("PRAGMA foreign_keys = ON")
        try execute("PRAGMA journal_mode = \(journalMode)")
    }

    private func createSchema() throws {
        try execute("""
        CREATE TABLE IF NOT EXISTS metadata (
            key TEXT PRIMARY KEY NOT NULL,
            value TEXT NOT NULL
        )
        """)
        try execute("""
        CREATE TABLE IF NOT EXISTS app_settings (
            key TEXT PRIMARY KEY NOT NULL,
            value TEXT NOT NULL
        )
        """)
        try execute("""
        CREATE TABLE IF NOT EXISTS tracked_assets (
            id TEXT PRIMARY KEY NOT NULL,
            sort_index INTEGER NOT NULL,
            type TEXT NOT NULL,
            name TEXT NOT NULL,
            symbol TEXT NOT NULL,
            canonical_symbol TEXT,
            visible_in_menu_bar INTEGER NOT NULL DEFAULT 0
        )
        """)
        try execute("CREATE INDEX IF NOT EXISTS tracked_assets_sort_index ON tracked_assets(sort_index)")
        try execute("""
        CREATE TABLE IF NOT EXISTS transactions (
            id TEXT PRIMARY KEY NOT NULL,
            occurred_at REAL NOT NULL,
            kind TEXT NOT NULL,
            asset_id TEXT,
            asset_name TEXT NOT NULL DEFAULT '',
            symbol TEXT NOT NULL DEFAULT '',
            asset_type TEXT,
            currency TEXT NOT NULL DEFAULT '',
            quantity REAL NOT NULL DEFAULT 0,
            unit_price REAL NOT NULL DEFAULT 0,
            amount REAL NOT NULL DEFAULT 0,
            fee REAL NOT NULL DEFAULT 0,
            tax REAL NOT NULL DEFAULT 0,
            note TEXT NOT NULL DEFAULT '',
            trade_date TEXT NOT NULL DEFAULT '',
            market_time_zone TEXT NOT NULL DEFAULT '',
            executed_at REAL,
            settlement_date TEXT,
            settlement_status TEXT NOT NULL DEFAULT 'notRecorded',
            transaction_levy REAL NOT NULL DEFAULT 0,
            trading_fee REAL NOT NULL DEFAULT 0,
            created_at REAL NOT NULL,
            updated_at REAL NOT NULL
        )
        """)
        try execute("CREATE INDEX IF NOT EXISTS transactions_occurred_at ON transactions(occurred_at)")
        try execute("""
        CREATE TABLE IF NOT EXISTS portfolio_accounts (
            id TEXT PRIMARY KEY NOT NULL,
            name TEXT NOT NULL,
            created_at REAL NOT NULL
        )
        """)
        try? execute("ALTER TABLE transactions ADD COLUMN account_id TEXT")
        try? execute("ALTER TABLE transactions ADD COLUMN target_account_id TEXT")
        try? execute("ALTER TABLE transactions ADD COLUMN target_currency TEXT NOT NULL DEFAULT ''")
        try? execute("ALTER TABLE transactions ADD COLUMN target_amount REAL NOT NULL DEFAULT 0")
        try? execute("ALTER TABLE transactions ADD COLUMN trade_date TEXT NOT NULL DEFAULT ''")
        try? execute("ALTER TABLE transactions ADD COLUMN market_time_zone TEXT NOT NULL DEFAULT ''")
        try? execute("ALTER TABLE transactions ADD COLUMN executed_at REAL")
        try? execute("ALTER TABLE transactions ADD COLUMN settlement_date TEXT")
        try? execute("ALTER TABLE transactions ADD COLUMN settlement_status TEXT NOT NULL DEFAULT 'notRecorded'")
        try? execute("ALTER TABLE transactions ADD COLUMN transaction_levy REAL NOT NULL DEFAULT 0")
        try? execute("ALTER TABLE transactions ADD COLUMN trading_fee REAL NOT NULL DEFAULT 0")
        try execute("CREATE INDEX IF NOT EXISTS transactions_account_id ON transactions(account_id)")
        try execute("CREATE INDEX IF NOT EXISTS transactions_trade_date ON transactions(trade_date)")
        try execute("""
        CREATE TABLE IF NOT EXISTS portfolio_snapshots (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            captured_at REAL NOT NULL,
            market TEXT NOT NULL DEFAULT 'all',
            currency TEXT NOT NULL,
            invested REAL NOT NULL,
            proceeds REAL NOT NULL,
            market_value REAL NOT NULL,
            cash_balance REAL,
            net_worth REAL,
            realized_pnl REAL NOT NULL,
            unrealized_pnl REAL NOT NULL,
            total_pnl REAL NOT NULL
        )
        """)
        try? execute("ALTER TABLE portfolio_snapshots ADD COLUMN market TEXT NOT NULL DEFAULT 'all'")
        try execute("CREATE INDEX IF NOT EXISTS snapshots_market_currency_date ON portfolio_snapshots(market, currency, captured_at)")
    }

    private func hasMetadata(_ key: String) -> Bool {
        guard let database,
              let statement = prepare("SELECT 1 FROM metadata WHERE key = ? LIMIT 1", database: database) else { return false }
        defer { sqlite3_finalize(statement) }
        bind(statement, index: 1, value: key)
        return sqlite3_step(statement) == SQLITE_ROW
    }

    private func existingOrCreateAccount(named name: String) throws -> PortfolioAccount {
        if let existing = loadAccounts().first(where: { $0.name.caseInsensitiveCompare(name) == .orderedSame }) {
            return existing
        }
        return try createAccount(name: name)
    }

    private func insert(_ account: PortfolioAccount) throws {
        try perform("INSERT INTO portfolio_accounts(id, name, created_at) VALUES (?, ?, ?)") { statement in
            bind(statement, index: 1, value: account.id.uuidString)
            bind(statement, index: 2, value: account.name)
            bind(statement, index: 3, value: account.createdAt.timeIntervalSince1970)
        }
    }

    private func replaceTrackedAssets(_ assets: [TrackedAsset]) throws {
        var seen = Set<String>()
        let uniqueAssets = assets.filter { asset in
            seen.insert(assetIdentity(for: asset)).inserted
        }
        try execute("DELETE FROM tracked_assets")
        for (index, asset) in uniqueAssets.enumerated() {
            try perform("""
            INSERT INTO tracked_assets
            (id, sort_index, type, name, symbol, canonical_symbol, visible_in_menu_bar)
            VALUES (?, ?, ?, ?, ?, ?, ?)
            """) { statement in
                bind(statement, index: 1, value: assetIdentity(for: asset))
                bind(statement, index: 2, value: Int32(index))
                bind(statement, index: 3, value: asset.type.rawValue)
                bind(statement, index: 4, value: asset.name)
                bind(statement, index: 5, value: asset.symbol)
                bind(statement, index: 6, value: asset.canonicalSymbol)
                bind(statement, index: 7, value: asset.visibleInMenuBar ? Int32(1) : Int32(0))
            }
        }
    }

    private func setting(_ key: String) -> String? {
        guard let database,
              let statement = prepare("SELECT value FROM app_settings WHERE key = ? LIMIT 1", database: database) else { return nil }
        defer { sqlite3_finalize(statement) }
        bind(statement, index: 1, value: key)
        guard sqlite3_step(statement) == SQLITE_ROW else { return nil }
        return text(statement, 0)
    }

    private func setSetting(_ key: String, value: String?) throws {
        guard let value else {
            try perform("DELETE FROM app_settings WHERE key = ?") { statement in
                bind(statement, index: 1, value: key)
            }
            return
        }
        try perform("INSERT OR REPLACE INTO app_settings(key, value) VALUES (?, ?)") { statement in
            bind(statement, index: 1, value: key)
            bind(statement, index: 2, value: value)
        }
    }

    private func setMetadata(_ key: String, value: String) throws {
        try perform("INSERT OR REPLACE INTO metadata(key, value) VALUES (?, ?)") { statement in
            bind(statement, index: 1, value: key)
            bind(statement, index: 2, value: value)
        }
    }

    private func insert(_ snapshot: PortfolioSnapshot) throws {
        try perform("""
        INSERT INTO portfolio_snapshots
        (captured_at, market, currency, invested, proceeds, market_value, cash_balance,
         net_worth, realized_pnl, unrealized_pnl, total_pnl)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """) { statement in
            bind(statement, index: 1, value: snapshot.capturedAt.timeIntervalSince1970)
            bind(statement, index: 2, value: snapshot.market.rawValue)
            bind(statement, index: 3, value: snapshot.currency.uppercased())
            bind(statement, index: 4, value: snapshot.invested)
            bind(statement, index: 5, value: snapshot.proceeds)
            bind(statement, index: 6, value: snapshot.marketValue)
            bind(statement, index: 7, value: snapshot.cashBalance)
            bind(statement, index: 8, value: snapshot.netWorth)
            bind(statement, index: 9, value: snapshot.realizedPnl)
            bind(statement, index: 10, value: snapshot.unrealizedPnl)
            bind(statement, index: 11, value: snapshot.totalPnl)
        }
    }

    private func execute(_ sql: String) throws {
        guard let database else { throw databaseError() }
        var errorMessage: UnsafeMutablePointer<Int8>?
        let result = sqlite3_exec(database, sql, nil, nil, &errorMessage)
        guard result == SQLITE_OK else {
            let message = errorMessage.map { String(cString: $0) } ?? "SQLite error \(result)"
            sqlite3_free(errorMessage)
            throw NSError(domain: "CareAssets.PortfolioDatabase", code: Int(result), userInfo: [NSLocalizedDescriptionKey: message])
        }
    }

    private func perform(_ sql: String, bindValues: (OpaquePointer) -> Void) throws {
        guard let database,
              let statement = prepare(sql, database: database) else { throw databaseError() }
        defer { sqlite3_finalize(statement) }
        bindValues(statement)
        guard sqlite3_step(statement) == SQLITE_DONE else { throw databaseError() }
    }

    private func prepare(_ sql: String, database: OpaquePointer) -> OpaquePointer? {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(database, sql, -1, &statement, nil) == SQLITE_OK else { return nil }
        return statement
    }

    private func databaseError() -> NSError {
        let message = database.flatMap { sqlite3_errmsg($0) }.map { String(cString: $0) } ?? "SQLite database unavailable"
        return NSError(domain: "CareAssets.PortfolioDatabase", code: 1, userInfo: [NSLocalizedDescriptionKey: message])
    }

    private func text(_ statement: OpaquePointer, _ index: Int32) -> String? {
        guard let pointer = sqlite3_column_text(statement, index) else { return nil }
        return String(cString: pointer)
    }

    private func number(_ statement: OpaquePointer, _ index: Int32) -> Double? {
        sqlite3_column_type(statement, index) == SQLITE_NULL ? nil : sqlite3_column_double(statement, index)
    }

    private func bind(_ statement: OpaquePointer, index: Int32, value: String?) {
        guard let value else {
            sqlite3_bind_null(statement, index)
            return
        }
        sqlite3_bind_text(statement, index, value, -1, careSQLiteTransient)
    }

    private func bind(_ statement: OpaquePointer, index: Int32, value: Double?) {
        guard let value else {
            sqlite3_bind_null(statement, index)
            return
        }
        sqlite3_bind_double(statement, index, value)
    }

    private func bind(_ statement: OpaquePointer, index: Int32, value: Int32) {
        sqlite3_bind_int(statement, index, value)
    }
}

private func portfolioCurrency(for asset: TrackedAsset) -> String {
    switch asset.type {
    case .gold:
        return "CNY"
    case .crypto:
        return "USDT"
    case .stock:
        let canonical = (asset.canonicalSymbol ?? "").uppercased()
        if canonical.hasPrefix("HK:") { return "HKD" }
        if canonical.hasPrefix("SH:") || canonical.hasPrefix("SZ:") { return "CNY" }
        return "USD"
    }
}

enum PortfolioCalculator {
    private struct WorkingPosition {
        var accountID: UUID?
        var name: String
        var symbol: String
        var currency: String
        var quantity: Double = 0
        var costBasis: Double = 0
        var realizedPnl: Double = 0
        var totalInvested: Double = 0
        var totalProceeds: Double = 0
    }

    static func calculate(transactions: [PortfolioTransaction], assets: [DisplayAsset]) -> PortfolioSummary {
        var working: [String: WorkingPosition] = [:]
        var summaries: [String: PortfolioCurrencySummary] = [:]
        let sortedTransactions = transactions.sorted { $0.occurredAt < $1.occurredAt }

        for transaction in sortedTransactions {
            let currency = transaction.currency.uppercased().isEmpty ? "UNKNOWN" : transaction.currency.uppercased()
            var summary = summaries[currency] ?? PortfolioCurrencySummary(currency: currency)

            switch transaction.kind {
            case .buy, .opening:
                guard let assetID = transaction.assetID else { continue }
                let cost = transaction.costAmount
                let positionKey = positionKey(assetID: assetID, accountID: transaction.accountID)
                var position = working[positionKey] ?? WorkingPosition(
                    accountID: transaction.accountID,
                    name: transaction.assetName,
                    symbol: transaction.symbol,
                    currency: currency
                )
                position.quantity += transaction.quantity
                position.costBasis += cost
                position.totalInvested += cost
                working[positionKey] = position
                summary.grossInvested += cost
                if transaction.kind == .buy {
                    summary.cashBalance -= cost
                }

            case .sell:
                guard let assetID = transaction.assetID else { continue }
                let positionKey = positionKey(assetID: assetID, accountID: transaction.accountID)
                var position = working[positionKey] ?? WorkingPosition(
                    accountID: transaction.accountID,
                    name: transaction.assetName,
                    symbol: transaction.symbol,
                    currency: currency
                )
                let averageCost = position.quantity > 0 ? position.costBasis / position.quantity : 0
                let soldCost = min(transaction.quantity, max(position.quantity, 0)) * averageCost
                let proceeds = transaction.netProceeds
                position.quantity -= transaction.quantity
                position.costBasis = max(0, position.costBasis - soldCost)
                position.realizedPnl += proceeds - soldCost
                position.totalProceeds += proceeds
                working[positionKey] = position
                summary.grossProceeds += proceeds
                summary.cashBalance += proceeds
                summary.realizedPnl += proceeds - soldCost

            case .deposit:
                summary.cashBalance += transaction.amount
                summary.hasFundingRecords = true

            case .withdrawal:
                summary.cashBalance -= transaction.amount
                summary.hasFundingRecords = true

            case .dividend:
                summary.cashBalance += transaction.amount
                summary.dividends += transaction.amount

            case .transfer:
                summary.cashBalance -= transaction.totalCharges

            case .exchange:
                let receivingCurrency = transaction.targetCurrency.uppercased()
                guard !receivingCurrency.isEmpty,
                      receivingCurrency != currency,
                      transaction.targetAmount > 0 else { continue }
                summary.cashBalance -= transaction.amount + transaction.totalCharges
                summaries[currency] = summary
                var receivingSummary = summaries[receivingCurrency] ?? PortfolioCurrencySummary(currency: receivingCurrency)
                receivingSummary.cashBalance += transaction.targetAmount
                summaries[receivingCurrency] = receivingSummary
                continue

            }
            summaries[currency] = summary
        }

        let quoteByID = Dictionary(uniqueKeysWithValues: assets.map { ($0.id, $0) })
        var positions: [PortfolioPosition] = []
        for (positionKey, position) in working {
            let assetID = assetID(from: positionKey)
            let quote = quoteByID[assetID]
            let currentPrice = quote?.currentPrice
            let marketValue = currentPrice.map { max(0, position.quantity) * $0 }
            let currentCurrency = quote?.currency?.uppercased() ?? position.currency
            let unrealized = marketValue.map { $0 - position.costBasis }
            positions.append(PortfolioPosition(
                assetID: assetID,
                accountID: position.accountID,
                name: quote?.name ?? position.name,
                symbol: quote?.symbol ?? position.symbol,
                currency: currentCurrency,
                quantity: max(0, position.quantity),
                costBasis: max(0, position.costBasis),
                averageCost: position.quantity > 0 ? position.costBasis / position.quantity : 0,
                currentPrice: currentPrice,
                marketValue: marketValue,
                realizedPnl: position.realizedPnl,
                unrealizedPnl: unrealized,
                totalInvested: position.totalInvested,
                totalProceeds: position.totalProceeds
            ))

            var summary = summaries[currentCurrency] ?? PortfolioCurrencySummary(currency: currentCurrency)
            if let marketValue {
                summary.marketValue += marketValue
                summary.unrealizedPnl += marketValue - position.costBasis
            }
            summaries[currentCurrency] = summary
        }

        for currency in summaries.keys {
            guard var summary = summaries[currency] else { continue }
            summary.netWorth = summary.cashBalance + summary.marketValue
            summary.totalPnl = summary.grossProceeds + summary.marketValue - summary.grossInvested + summary.dividends
            summaries[currency] = summary
        }

        return PortfolioSummary(
            positions: positions.sorted { $0.symbol.localizedStandardCompare($1.symbol) == .orderedAscending },
            currencies: summaries
        )
    }

    static func calculate(
        transactions: [PortfolioTransaction],
        assets: [DisplayAsset],
        market: PortfolioMarket
    ) -> PortfolioSummary {
        guard market != .all else {
            return calculate(transactions: transactions, assets: assets)
        }
        return calculate(
            transactions: transactions.filter { market.includes(assetID: $0.assetID) },
            assets: assets.filter { market.includes(assetID: $0.id) }
        )
    }

    private static func positionKey(assetID: String, accountID: UUID?) -> String {
        "\(accountID?.uuidString ?? "unassigned")|\(assetID)"
    }

    private static func assetID(from positionKey: String) -> String {
        String(positionKey.split(separator: "|", maxSplits: 1, omittingEmptySubsequences: false).last ?? "")
    }
}
