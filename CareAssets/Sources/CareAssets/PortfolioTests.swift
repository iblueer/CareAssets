import Foundation

#if CAREASSETS_PORTFOLIO_TEST
enum PortfolioTestRunner {
    static func run() {
        let asset = TrackedAsset(
            type: .stock,
            name: "测试资产",
            symbol: "TEST",
            canonicalSymbol: "US:TEST",
            visibleInMenuBar: false
        )

        var firstBuy = PortfolioTransaction.trade(
            asset: asset,
            name: asset.name,
            kind: .buy,
            occurredAt: Date(timeIntervalSince1970: 1),
            quantity: 10,
            unitPrice: 100,
            fee: 1,
            tax: 0,
            note: ""
        )
        firstBuy.currency = "USD"

        var secondBuy = PortfolioTransaction.trade(
            asset: asset,
            name: asset.name,
            kind: .buy,
            occurredAt: Date(timeIntervalSince1970: 2),
            quantity: 10,
            unitPrice: 120,
            fee: 1,
            tax: 0,
            note: ""
        )
        secondBuy.currency = "USD"

        var sell = PortfolioTransaction.trade(
            asset: asset,
            name: asset.name,
            kind: .sell,
            occurredAt: Date(timeIntervalSince1970: 3),
            quantity: 5,
            unitPrice: 150,
            fee: 1,
            tax: 0,
            note: ""
        )
        sell.currency = "USD"

        let deposit = PortfolioTransaction(
            id: UUID(),
            occurredAt: Date(timeIntervalSince1970: 0),
            kind: .deposit,
            assetID: nil,
            assetName: "",
            symbol: "",
            assetType: nil,
            currency: "USD",
            quantity: 0,
            unitPrice: 0,
            amount: 3000,
            fee: 0,
            tax: 0,
            note: ""
        )

        var display = DisplayAsset.loading(from: asset)
        display.currentPrice = 160
        display.currency = "USD"

        let summary = PortfolioCalculator.calculate(
            transactions: [deposit, firstBuy, secondBuy, sell],
            assets: [display]
        )
        guard let currency = summary.currencies["USD"],
              let position = summary.positions.first else {
            fatalError("Portfolio summary was not generated")
        }

        assertApproximately(currency.grossInvested, 2202)
        assertApproximately(currency.grossProceeds, 749)
        assertApproximately(currency.marketValue, 2400)
        assertApproximately(currency.realizedPnl, 198.5)
        assertApproximately(currency.unrealizedPnl, 748.5)
        assertApproximately(currency.totalPnl, 947)
        assertApproximately(currency.cashBalance, 1547)
        assertApproximately(currency.netWorth, 3947)
        assertApproximately(position.quantity, 15)
        assertApproximately(position.averageCost, 110.1)
        precondition(abs(currency.totalPnl - (currency.realizedPnl + currency.unrealizedPnl + currency.dividends)) < 0.000001)

        let hongKongAsset = TrackedAsset(
            type: .stock,
            name: "测试港股",
            symbol: "00001",
            canonicalSymbol: "HK:00001",
            visibleInMenuBar: false
        )
        var hongKongBuy = PortfolioTransaction.trade(
            asset: hongKongAsset,
            name: hongKongAsset.name,
            kind: .buy,
            occurredAt: Date(timeIntervalSince1970: 1),
            quantity: 10,
            unitPrice: 80,
            fee: 0,
            tax: 0,
            note: ""
        )
        hongKongBuy.currency = "HKD"
        var hongKongDisplay = DisplayAsset.loading(from: hongKongAsset)
        hongKongDisplay.currentPrice = 90
        hongKongDisplay.currency = "HKD"

        let usOnlySummary = PortfolioCalculator.calculate(
            transactions: [firstBuy, hongKongBuy],
            assets: [display, hongKongDisplay],
            market: .us
        )
        precondition(usOnlySummary.currencies["HKD"] == nil)
        assertApproximately(usOnlySummary.currencies["USD"]?.grossInvested ?? -1, 1001)

        let rates = PortfolioExchangeRates(usdToCurrency: [
            "HKD": [StockChartPoint(date: Date(timeIntervalSince1970: 0), price: 7.8)],
            "CNY": [StockChartPoint(date: Date(timeIntervalSince1970: 0), price: 7.2)]
        ])
        guard let convertedToHKD = rates.convert(summary: usOnlySummary, to: "HKD", at: Date()) else {
            fatalError("USD to HKD conversion failed")
        }
        assertApproximately(convertedToHKD.grossInvested, 7_807.8)

        let temporaryDatabaseURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("CareAssets-portfolio-test-\(UUID().uuidString)")
            .appendingPathExtension("sqlite3")
        defer {
            try? FileManager.default.removeItem(at: temporaryDatabaseURL)
            try? FileManager.default.removeItem(atPath: temporaryDatabaseURL.path + "-shm")
            try? FileManager.default.removeItem(atPath: temporaryDatabaseURL.path + "-wal")
        }
        let store = PortfolioStore(databaseURL: temporaryDatabaseURL)
        try! store.insert(firstBuy)
        store.migrateTransactionsToHSBCHKIfNeeded()
        guard let hsbcAccount = store.loadAccounts().first(where: { $0.name == "HSBC HK" }),
              store.loadTransactions().first?.accountID == hsbcAccount.id else {
            fatalError("Existing transactions were not assigned to HSBC HK")
        }
        var editedBuy = firstBuy
        editedBuy.accountID = hsbcAccount.id
        editedBuy.unitPrice = 125
        editedBuy.amount = 1250
        editedBuy.note = "已编辑"
        try! store.update(editedBuy)
        guard let storedTransaction = store.loadTransactions().first else {
            fatalError("Edited transaction was not loaded")
        }
        assertApproximately(storedTransaction.unitPrice, 125)
        assertApproximately(storedTransaction.amount, 1250)
        precondition(storedTransaction.note == "已编辑")
        precondition(storedTransaction.id == firstBuy.id)
        precondition(storedTransaction.accountID == hsbcAccount.id)

        let ibkrAccount = try! store.createAccount(name: "IBKR")
        let exchange = PortfolioTransaction(
            id: UUID(),
            occurredAt: Date(timeIntervalSince1970: 4),
            kind: .exchange,
            assetID: nil,
            assetName: "",
            symbol: "",
            assetType: nil,
            currency: "HKD",
            quantity: 0,
            unitPrice: 0,
            amount: 9_970,
            fee: 30,
            tax: 0,
            note: "",
            accountID: hsbcAccount.id,
            targetAccountID: hsbcAccount.id,
            targetCurrency: "USD",
            targetAmount: 1_278
        )
        let transfer = PortfolioTransaction(
            id: UUID(),
            occurredAt: Date(timeIntervalSince1970: 5),
            kind: .transfer,
            assetID: nil,
            assetName: "",
            symbol: "",
            assetType: nil,
            currency: "USD",
            quantity: 0,
            unitPrice: 0,
            amount: 1_200,
            fee: 1,
            tax: 0,
            note: "",
            accountID: hsbcAccount.id,
            targetAccountID: ibkrAccount.id,
            targetCurrency: "USD",
            targetAmount: 1_200
        )
        let hkdDeposit = PortfolioTransaction(
            id: UUID(),
            occurredAt: Date(timeIntervalSince1970: 3),
            kind: .deposit,
            assetID: nil,
            assetName: "",
            symbol: "",
            assetType: nil,
            currency: "HKD",
            quantity: 0,
            unitPrice: 0,
            amount: 10_000,
            fee: 0,
            tax: 0,
            note: "",
            accountID: hsbcAccount.id
        )
        let cashSummary = PortfolioCalculator.calculate(
            transactions: [hkdDeposit, exchange, transfer],
            assets: []
        )
        assertApproximately(cashSummary.currencies["HKD"]?.cashBalance ?? -1, 0)
        assertApproximately(cashSummary.currencies["USD"]?.cashBalance ?? -1, 1_277)

        try! store.replaceLedger(
            accounts: [hsbcAccount, ibkrAccount],
            transactions: [editedBuy, hkdDeposit, exchange, transfer]
        )
        let syncedAccounts = store.loadAccounts()
        let syncedTransactions = store.loadTransactions()
        precondition(Set(syncedAccounts.map(\.id)) == Set([hsbcAccount.id, ibkrAccount.id]))
        precondition(syncedTransactions.map(\.id) == [editedBuy.id, hkdDeposit.id, exchange.id, transfer.id])
        precondition(syncedTransactions.first?.accountID == hsbcAccount.id)

        try! store.replaceSnapshots([
            PortfolioSnapshot(
                capturedAt: Date(timeIntervalSince1970: 1),
                market: .hk,
                currency: "USD",
                invested: 100,
                proceeds: 0,
                marketValue: 120,
                cashBalance: nil,
                netWorth: nil,
                realizedPnl: 0,
                unrealizedPnl: 20,
                totalPnl: 20
            )
        ])
        let storedSnapshot = store.loadSnapshots().first
        precondition(storedSnapshot?.market == .hk)
        precondition(storedSnapshot?.currency == "USD")

        let legacyConfiguration = AppConfig(
            refreshIntervalSeconds: 45,
            menuBarMaxItems: 5,
            stockDisplayCurrency: "HKD",
            priceColorMode: .white,
            statusBarBackgroundMode: .purple,
            stockDataSource: .yahooFinance,
            stockChartPeriod: .year,
            showPositionSummary: false,
            iCloudDriveSyncEnabled: true,
            syncFolderPath: "/tmp/CareAssets-sync",
            language: .zhHans,
            assets: [asset, hongKongAsset]
        )
        let migratedConfiguration = store.loadOrCreateConfiguration(legacyConfig: legacyConfiguration)
        precondition(migratedConfiguration.refreshIntervalSeconds == 45)
        precondition(migratedConfiguration.assets.map(assetIdentity(for:)) == legacyConfiguration.assets.map(assetIdentity(for:)))

        var updatedConfiguration = migratedConfiguration
        updatedConfiguration.menuBarMaxItems = 2
        updatedConfiguration.assets = [hongKongAsset]
        try! store.saveConfiguration(updatedConfiguration)
        let storedConfiguration = store.loadConfiguration()
        precondition(storedConfiguration.menuBarMaxItems == 2)
        precondition(storedConfiguration.stockDataSource == .yahooFinance)
        precondition(storedConfiguration.assets.map(assetIdentity(for:)) == [assetIdentity(for: hongKongAsset)])

        let encoded = try! JSONEncoder().encode(asset)
        let encodedText = String(data: encoded, encoding: .utf8) ?? ""
        precondition(!encodedText.contains("holdingQuantity"))
        precondition(!encodedText.contains("averageBuyPrice"))
        print("CareAssets portfolio calculation tests passed")
    }

    private static func assertApproximately(_ actual: Double, _ expected: Double) {
        precondition(abs(actual - expected) < 0.000001, "Expected \(expected), got \(actual)")
    }
}
#endif
