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
        var editedBuy = firstBuy
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
