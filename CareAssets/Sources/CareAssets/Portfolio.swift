import Foundation
import SQLite3

enum PortfolioTransactionKind: String, CaseIterable, Codable {
    case buy
    case sell
    case deposit
    case withdrawal
    case dividend
    case opening

    var title: String {
        switch self {
        case .buy: return "买入"
        case .sell: return "卖出"
        case .deposit: return "入金"
        case .withdrawal: return "出金"
        case .dividend: return "分红"
        case .opening: return "期初持仓"
        }
    }

    var isTrade: Bool {
        self == .buy || self == .sell || self == .opening
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

    var grossAmount: Double {
        kind.isTrade && kind != .opening ? quantity * unitPrice : amount
    }

    var costAmount: Double {
        quantity * unitPrice + fee + tax
    }

    var netProceeds: Double {
        quantity * unitPrice - fee - tax
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
        note: String
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
            note: note
        )
    }
}

struct PortfolioPosition {
    var assetID: String
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

private let careSQLiteTransient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

final class PortfolioStore {
    private let databaseURL: URL
    private var database: OpaquePointer?

    init(databaseURL overrideURL: URL? = nil) {
        let directory = overrideURL?.deletingLastPathComponent() ?? ConfigStore.appSupportURL
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        databaseURL = overrideURL ?? directory.appendingPathComponent("CareAssets.sqlite3")
        do {
            try open()
            try createSchema()
        } catch {
            NSLog("CareAssets portfolio database failed: \(error.localizedDescription)")
        }
    }

    deinit {
        if let database {
            sqlite3_close(database)
        }
    }

    func loadTransactions() -> [PortfolioTransaction] {
        guard let database else { return [] }
        let sql = """
        SELECT id, occurred_at, kind, asset_id, asset_name, symbol, asset_type,
               currency, quantity, unit_price, amount, fee, tax, note
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
                note: text(statement, 13) ?? ""
            )
            transactions.append(transaction)
        }
        return transactions
    }

    func insert(_ transaction: PortfolioTransaction) throws {
        let sql = """
        INSERT INTO transactions
        (id, occurred_at, kind, asset_id, asset_name, symbol, asset_type, currency,
         quantity, unit_price, amount, fee, tax, note, created_at, updated_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
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
            bind(statement, index: 15, value: Date().timeIntervalSince1970)
            bind(statement, index: 16, value: Date().timeIntervalSince1970)
        }
    }

    func update(_ transaction: PortfolioTransaction) throws {
        let sql = """
        UPDATE transactions
        SET occurred_at = ?, kind = ?, asset_id = ?, asset_name = ?, symbol = ?, asset_type = ?,
            currency = ?, quantity = ?, unit_price = ?, amount = ?, fee = ?, tax = ?, note = ?,
            updated_at = ?
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
            bind(statement, index: 14, value: Date().timeIntervalSince1970)
            bind(statement, index: 15, value: transaction.id.uuidString)
        }
    }

    func delete(id: UUID) throws {
        try perform("DELETE FROM transactions WHERE id = ?") { statement in
            bind(statement, index: 1, value: id.uuidString)
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
        SELECT captured_at, currency, invested, proceeds, market_value, cash_balance,
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
                currency: text(statement, 1) ?? currency,
                invested: sqlite3_column_double(statement, 2),
                proceeds: sqlite3_column_double(statement, 3),
                marketValue: sqlite3_column_double(statement, 4),
                cashBalance: number(statement, 5),
                netWorth: number(statement, 6),
                realizedPnl: sqlite3_column_double(statement, 7),
                unrealizedPnl: sqlite3_column_double(statement, 8),
                totalPnl: sqlite3_column_double(statement, 9)
            ))
        }
        return snapshots.reversed()
    }

    func loadSnapshots(limit: Int = 4000) -> [PortfolioSnapshot] {
        guard let database else { return [] }
        let sql = """
        SELECT captured_at, currency, invested, proceeds, market_value, cash_balance,
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
                currency: text(statement, 1) ?? "",
                invested: sqlite3_column_double(statement, 2),
                proceeds: sqlite3_column_double(statement, 3),
                marketValue: sqlite3_column_double(statement, 4),
                cashBalance: number(statement, 5),
                netWorth: number(statement, 6),
                realizedPnl: sqlite3_column_double(statement, 7),
                unrealizedPnl: sqlite3_column_double(statement, 8),
                totalPnl: sqlite3_column_double(statement, 9)
            ))
        }
        return snapshots
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
        try execute("PRAGMA journal_mode = WAL")
    }

    private func createSchema() throws {
        try execute("""
        CREATE TABLE IF NOT EXISTS metadata (
            key TEXT PRIMARY KEY NOT NULL,
            value TEXT NOT NULL
        )
        """)
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
            created_at REAL NOT NULL,
            updated_at REAL NOT NULL
        )
        """)
        try execute("CREATE INDEX IF NOT EXISTS transactions_occurred_at ON transactions(occurred_at)")
        try execute("""
        CREATE TABLE IF NOT EXISTS portfolio_snapshots (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            captured_at REAL NOT NULL,
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
        try execute("CREATE INDEX IF NOT EXISTS snapshots_currency_date ON portfolio_snapshots(currency, captured_at)")
    }

    private func hasMetadata(_ key: String) -> Bool {
        guard let database,
              let statement = prepare("SELECT 1 FROM metadata WHERE key = ? LIMIT 1", database: database) else { return false }
        defer { sqlite3_finalize(statement) }
        bind(statement, index: 1, value: key)
        return sqlite3_step(statement) == SQLITE_ROW
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
        (captured_at, currency, invested, proceeds, market_value, cash_balance,
         net_worth, realized_pnl, unrealized_pnl, total_pnl)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """) { statement in
            bind(statement, index: 1, value: snapshot.capturedAt.timeIntervalSince1970)
            bind(statement, index: 2, value: snapshot.currency.uppercased())
            bind(statement, index: 3, value: snapshot.invested)
            bind(statement, index: 4, value: snapshot.proceeds)
            bind(statement, index: 5, value: snapshot.marketValue)
            bind(statement, index: 6, value: snapshot.cashBalance)
            bind(statement, index: 7, value: snapshot.netWorth)
            bind(statement, index: 8, value: snapshot.realizedPnl)
            bind(statement, index: 9, value: snapshot.unrealizedPnl)
            bind(statement, index: 10, value: snapshot.totalPnl)
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
                var position = working[assetID] ?? WorkingPosition(
                    name: transaction.assetName,
                    symbol: transaction.symbol,
                    currency: currency
                )
                position.quantity += transaction.quantity
                position.costBasis += cost
                position.totalInvested += cost
                working[assetID] = position
                summary.grossInvested += cost
                if transaction.kind == .buy {
                    summary.cashBalance -= cost
                }

            case .sell:
                guard let assetID = transaction.assetID else { continue }
                var position = working[assetID] ?? WorkingPosition(
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
                working[assetID] = position
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

            }
            summaries[currency] = summary
        }

        let quoteByID = Dictionary(uniqueKeysWithValues: assets.map { ($0.id, $0) })
        var positions: [PortfolioPosition] = []
        for (assetID, position) in working {
            let quote = quoteByID[assetID]
            let currentPrice = quote?.currentPrice
            let marketValue = currentPrice.map { max(0, position.quantity) * $0 }
            let currentCurrency = quote?.currency?.uppercased() ?? position.currency
            let unrealized = marketValue.map { $0 - position.costBasis }
            positions.append(PortfolioPosition(
                assetID: assetID,
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
}
