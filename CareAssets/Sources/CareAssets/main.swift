import AppKit
import CoreText
import Foundation

enum AssetType: String, Codable, Sendable {
    case gold
    case crypto
    case stock
}

enum AppLanguage: String, Codable, Sendable, CaseIterable {
    case system
    case zhHans
    case en
    case zhHant
    case ja
    case ar
    case de
    case fr
    case ko
    case ptPT
    case es

    var title: String {
        switch self {
        case .system:
            return L10n.text(
                "系统",
                "System",
                zhHant: "系統",
                ja: "システム",
                ar: "النظام",
                de: "System",
                fr: "Système",
                ko: "시스템",
                ptPT: "Sistema",
                es: "Sistema"
            )
        case .zhHans:
            return "简体中文"
        case .en:
            return "English"
        case .zhHant:
            return "繁體中文"
        case .ja:
            return "日本語"
        case .ar:
            return "العربية"
        case .de:
            return "Deutsch"
        case .fr:
            return "Français"
        case .ko:
            return "한국어"
        case .ptPT:
            return "Português"
        case .es:
            return "Español"
        }
    }
}

enum L10n {
    static var appLanguage: AppLanguage = .system

    private static var resolvedLanguage: AppLanguage {
        switch appLanguage {
        case .system:
            let preferred = Locale.preferredLanguages.first?.lowercased() ?? ""
            if preferred.hasPrefix("zh-hant") || preferred.contains("hant") || preferred.hasPrefix("zh-tw") || preferred.hasPrefix("zh-hk") {
                return .zhHant
            }
            if preferred.hasPrefix("zh") { return .zhHans }
            if preferred.hasPrefix("ja") { return .ja }
            if preferred.hasPrefix("ar") { return .ar }
            if preferred.hasPrefix("de") { return .de }
            if preferred.hasPrefix("fr") { return .fr }
            if preferred.hasPrefix("ko") { return .ko }
            if preferred.hasPrefix("pt") { return .ptPT }
            if preferred.hasPrefix("es") { return .es }
            return .en
        default:
            return appLanguage
        }
    }

    static var usesChineseMarketUnits: Bool {
        switch appLanguage {
        case .system:
            return Locale.autoupdatingCurrent.regionCode?.uppercased() == "CN"
        case .zhHans:
            return true
        default:
            return false
        }
    }

    static var isRightToLeft: Bool {
        resolvedLanguage == .ar
    }

    static func text(
        _ zh: String,
        _ en: String,
        zhHant: String? = nil,
        ja: String? = nil,
        ar: String? = nil,
        de: String? = nil,
        fr: String? = nil,
        ko: String? = nil,
        ptPT: String? = nil,
        es: String? = nil
    ) -> String {
        switch resolvedLanguage {
        case .system:
            return en
        case .zhHans:
            return zh
        case .en:
            return en
        case .zhHant:
            return zhHant ?? zh
        case .ja:
            return ja ?? en
        case .ar:
            return ar ?? en
        case .de:
            return de ?? en
        case .fr:
            return fr ?? en
        case .ko:
            return ko ?? en
        case .ptPT:
            return ptPT ?? en
        case .es:
            return es ?? en
        }
    }

    static var white: String { text("白", "White", zhHant: "白", ja: "白", ar: "أبيض", de: "Weiß", fr: "Blanc", ko: "흰색", ptPT: "Branco", es: "Blanco") }
    static var redRiseGreenFall: String { text("红升绿降", "Red up, green down", zhHant: "紅升綠降", ja: "赤上げ緑下げ", ar: "الأحمر صعود، الأخضر هبوط", de: "Rot steigt, Grün fällt", fr: "Rouge hausse, vert baisse", ko: "빨강 상승, 초록 하락", ptPT: "Vermelho sobe, verde desce", es: "Rojo sube, verde baja") }
    static var redFallGreenRise: String { text("红降绿升", "Red down, green up", zhHant: "紅降綠升", ja: "赤下げ緑上げ", ar: "الأحمر هبوط، الأخضر صعود", de: "Rot fällt, Grün steigt", fr: "Rouge baisse, vert hausse", ko: "빨강 하락, 초록 상승", ptPT: "Vermelho desce, verde sobe", es: "Rojo baja, verde sube") }
    static var gold: String { text("黄金", "Gold", zhHant: "黃金", ja: "金", ar: "الذهب", de: "Gold", fr: "Or", ko: "금", ptPT: "Ouro", es: "Oro") }
    static var goldShort: String { text("金", "Gold", zhHant: "金", ja: "金", ar: "ذهب", de: "Gold", fr: "Or", ko: "금", ptPT: "Ouro", es: "Oro") }
    static var loading: String { text("正在刷新", "Refreshing", zhHant: "正在重新整理", ja: "更新中", ar: "جارٍ التحديث", de: "Aktualisiert", fr: "Actualisation", ko: "새로고침 중", ptPT: "A atualizar", es: "Actualizando") }
    static var loadingAssets: String { text("正在加载资产价格", "Loading asset prices", zhHant: "正在載入資產價格", ja: "資産価格を読み込み中", ar: "جارٍ تحميل أسعار الأصول", de: "Preise werden geladen", fr: "Chargement des prix", ko: "자산 가격 로드 중", ptPT: "A carregar preços", es: "Cargando precios") }
    static var close: String { text("收盘", "Close", zhHant: "收盤", ja: "終値", ar: "إغلاق", de: "Schluss", fr: "Clôture", ko: "종가", ptPT: "Fecho", es: "Cierre") }
    static var cnyPerGram: String { text("人民币/克", "CNY/g", zhHant: "人民幣/克", ja: "人民元/g", ar: "يوان/غ", de: "CNY/g", fr: "CNY/g", ko: "CNY/g", ptPT: "CNY/g", es: "CNY/g") }
    static var gramSuffix: String { text("/克", "/g", zhHant: "/克", ja: "/g", ar: "/غ", de: "/g", fr: "/g", ko: "/g", ptPT: "/g", es: "/g") }
    static var usdPerOunce: String { text("美元/盎司", "USD/oz", zhHant: "美元/盎司", ja: "USD/oz", ar: "دولار/أونصة", de: "USD/oz", fr: "USD/oz", ko: "USD/oz", ptPT: "USD/oz", es: "USD/oz") }
    static var ounceSuffix: String { text("/盎司", "/oz", zhHant: "/盎司", ja: "/oz", ar: "/أونصة", de: "/oz", fr: "/oz", ko: "/oz", ptPT: "/oz", es: "/oz") }
    static var add: String { text("添加", "Add", zhHant: "新增", ja: "追加", ar: "إضافة", de: "Hinzufügen", fr: "Ajouter", ko: "추가", ptPT: "Adicionar", es: "Añadir") }
    static var search: String { text("搜索", "Search", zhHant: "搜尋", ja: "検索", ar: "بحث", de: "Suchen", fr: "Rechercher", ko: "검색", ptPT: "Pesquisar", es: "Buscar") }
    static var searching: String { text("搜索中", "Searching", zhHant: "搜尋中", ja: "検索中", ar: "جارٍ البحث", de: "Sucht", fr: "Recherche", ko: "검색 중", ptPT: "A pesquisar", es: "Buscando") }
    static var cancel: String { text("取消", "Cancel", zhHant: "取消", ja: "取消", ar: "إلغاء", de: "Abbrechen", fr: "Annuler", ko: "취소", ptPT: "Cancelar", es: "Cancelar") }
    static var quit: String { text("退出", "Quit", zhHant: "結束", ja: "終了", ar: "إنهاء", de: "Beenden", fr: "Quitter", ko: "종료", ptPT: "Sair", es: "Salir") }
    static var searchPlaceholder: String { text("搜索股票代码或者币的名称", "Search stock code or coin name", zhHant: "搜尋股票代碼或幣種名稱", ja: "株式コードまたはコイン名を検索", ar: "ابحث عن رمز سهم أو اسم عملة", de: "Aktiencode oder Coin suchen", fr: "Code action ou crypto", ko: "주식 코드 또는 코인명 검색", ptPT: "Código de ação ou moeda", es: "Código de acción o moneda") }
    static var emptySearchPrompt: String { text("请点击上方搜索框输入", "Click the search field above", zhHant: "請點擊上方搜尋框輸入", ja: "上の検索欄に入力してください", ar: "انقر حقل البحث أعلاه", de: "Oben ins Suchfeld klicken", fr: "Cliquez le champ ci-dessus", ko: "위 검색창을 클릭하세요", ptPT: "Clique no campo acima", es: "Haz clic en el campo superior") }
    static var noSearchResults: String { text("暂无结果，请换个关键词试试", "No results. Try another keyword.", zhHant: "暫無結果，請換個關鍵字試試", ja: "結果なし。別のキーワードを試してください", ar: "لا نتائج. جرّب كلمة أخرى.", de: "Keine Ergebnisse. Anderes Stichwort.", fr: "Aucun résultat. Essayez un autre mot.", ko: "결과 없음. 다른 키워드를 시도하세요.", ptPT: "Sem resultados. Tente outra palavra.", es: "Sin resultados. Prueba otra palabra.") }
    static var searchInProgress: String { text("搜索中...", "Searching...", zhHant: "搜尋中...", ja: "検索中...", ar: "جارٍ البحث...", de: "Suche...", fr: "Recherche...", ko: "검색 중...", ptPT: "A pesquisar...", es: "Buscando...") }
    static var visibleInMenuBar: String { text("显示在顶部", "Show in menu bar", zhHant: "顯示在頂部", ja: "メニューバーに表示", ar: "إظهار في شريط القائمة", de: "In Menüleiste anzeigen", fr: "Afficher dans la barre", ko: "메뉴 막대에 표시", ptPT: "Mostrar na barra", es: "Mostrar en la barra") }
    static var remove: String { text("移出", "Remove", zhHant: "移除", ja: "削除", ar: "إزالة", de: "Entfernen", fr: "Retirer", ko: "제거", ptPT: "Remover", es: "Quitar") }
    static var added: String { text("已添加", "Added", zhHant: "已新增", ja: "追加済み", ar: "مُضاف", de: "Hinzugefügt", fr: "Ajouté", ko: "추가됨", ptPT: "Adicionado", es: "Añadido") }
    static var settings: String { text("设置", "Settings", zhHant: "設定", ja: "設定", ar: "الإعدادات", de: "Einstellungen", fr: "Réglages", ko: "설정", ptPT: "Definições", es: "Ajustes") }
    static var launchAtLogin: String { text("开机启动", "Launch at login", zhHant: "開機啟動", ja: "ログイン時に起動", ar: "التشغيل عند تسجيل الدخول", de: "Beim Anmelden starten", fr: "Lancer à l'ouverture", ko: "로그인 시 실행", ptPT: "Abrir ao iniciar sessão", es: "Abrir al iniciar sesión") }
    static var launchAtLoginFailed: String { text("开机启动设置失败。", "Failed to update launch at login.", zhHant: "開機啟動設定失敗。") }
    static var edit: String { text("编辑", "Edit", zhHant: "編輯", ja: "編集", ar: "تحرير", de: "Bearbeiten", fr: "Modifier", ko: "편집", ptPT: "Editar", es: "Editar") }
    static var doneEditing: String { text("完成编辑", "Done editing", zhHant: "完成編輯", ja: "編集完了", ar: "إنهاء التحرير", de: "Fertig", fr: "Terminer", ko: "편집 완료", ptPT: "Concluir edição", es: "Terminar edición") }
    static var reorder: String { text("拖动排序", "Drag to reorder", zhHant: "拖曳排序", ja: "ドラッグして並べ替え", ar: "اسحب لإعادة الترتيب", de: "Zum Sortieren ziehen", fr: "Faire glisser pour réorganiser", ko: "드래그하여 순서 변경", ptPT: "Arrastar para reordenar", es: "Arrastrar para reordenar") }
    static var position: String { text("持仓", "Position", zhHant: "持倉", ja: "保有", ar: "المركز", de: "Position", fr: "Position", ko: "보유", ptPT: "Posição", es: "Posición") }
    static var quantity: String { text("持仓数量", "Quantity", zhHant: "持倉數量", ja: "数量", ar: "الكمية", de: "Menge", fr: "Quantité", ko: "수량", ptPT: "Quantidade", es: "Cantidad") }
    static var averageBuyPrice: String { text("平均买入价", "Average buy price", zhHant: "平均買入價", ja: "平均取得単価", ar: "متوسط سعر الشراء", de: "Durchschnittskaufpreis", fr: "Prix moyen", ko: "평균 매수가", ptPT: "Preço médio", es: "Precio medio") }
    static var save: String { text("保存", "Save", zhHant: "儲存", ja: "保存", ar: "حفظ", de: "Speichern", fr: "Enregistrer", ko: "저장", ptPT: "Guardar", es: "Guardar") }
    static var clear: String { text("清空", "Clear", zhHant: "清空", ja: "クリア", ar: "مسح", de: "Leeren", fr: "Effacer", ko: "비우기", ptPT: "Limpar", es: "Limpiar") }
    static var unrealizedProfit: String { text("浮盈", "Unrealized gain", zhHant: "浮盈", ja: "含み益", ar: "ربح غير محقق", de: "Buchgewinn", fr: "Gain latent", ko: "평가이익", ptPT: "Ganho não realizado", es: "Ganancia no realizada") }
    static var unrealizedLoss: String { text("浮亏", "Unrealized loss", zhHant: "浮虧", ja: "含み損", ar: "خسارة غير محققة", de: "Buchverlust", fr: "Perte latente", ko: "평가손실", ptPT: "Perda não realizada", es: "Pérdida no realizada") }
    static var profitLoss: String { text("盈亏", "P/L", zhHant: "盈虧", ja: "損益", ar: "الربح/الخسارة", de: "G/V", fr: "P/L", ko: "손익", ptPT: "G/P", es: "G/P") }
    static var cost: String { text("成本", "Cost", zhHant: "成本", ja: "取得額", ar: "التكلفة", de: "Kosten", fr: "Coût", ko: "원가", ptPT: "Custo", es: "Coste") }
    static var marketValue: String { text("市值", "Value", zhHant: "市值", ja: "評価額", ar: "القيمة", de: "Wert", fr: "Valeur", ko: "평가액", ptPT: "Valor", es: "Valor") }
    static var colorSetting: String { text("价格颜色", "Price color", zhHant: "價格顏色", ja: "価格色", ar: "لون السعر", de: "Preisfarbe", fr: "Couleur prix", ko: "가격 색상", ptPT: "Cor preço", es: "Color precio") }
    static var languageSetting: String { text("语言", "Language", zhHant: "語言", ja: "言語", ar: "اللغة", de: "Sprache", fr: "Langue", ko: "언어", ptPT: "Idioma", es: "Idioma") }
    static var stockDataSourceSetting: String { text("股票数据源", "Stock data source", zhHant: "股票資料源", ja: "株価データ元", ar: "مصدر بيانات الأسهم", de: "Aktien-Datenquelle", fr: "Source actions", ko: "주식 데이터 소스", ptPT: "Fonte de ações", es: "Fuente acciones") }
    static var stockChartSetting: String { text("股价折线", "Price chart", zhHant: "股價折線", ja: "株価チャート", ar: "مخطط السعر", de: "Kursdiagramm", fr: "Courbe du cours", ko: "주가 차트", ptPT: "Gráfico de preço", es: "Gráfico de precio") }
    static var stockChartOff: String { text("关闭", "Off", zhHant: "關閉", ja: "オフ", ar: "إيقاف", de: "Aus", fr: "Désactivé", ko: "끔", ptPT: "Desligado", es: "Desactivado") }
    static var stockChartDay: String { text("日动态", "Day", zhHant: "日動態", ja: "1日", ar: "يوم", de: "Tag", fr: "Jour", ko: "일간", ptPT: "Dia", es: "Día") }
    static var stockChartWeek: String { text("周动态", "Week", zhHant: "週動態", ja: "1週間", ar: "أسبوع", de: "Woche", fr: "Semaine", ko: "주간", ptPT: "Semana", es: "Semana") }
    static var stockChartMonth: String { text("月动态", "Month", zhHant: "月動態", ja: "1か月", ar: "شهر", de: "Monat", fr: "Mois", ko: "월간", ptPT: "Mês", es: "Mes") }
    static var stockChartYear: String { text("年动态", "Year", zhHant: "年動態", ja: "1年", ar: "سنة", de: "Jahr", fr: "Année", ko: "연간", ptPT: "Ano", es: "Año") }
    static var stockChartLoading: String { text("正在加载折线数据", "Loading chart data", zhHant: "正在載入折線資料", ja: "チャートを読み込み中", ar: "جارٍ تحميل بيانات المخطط", de: "Diagrammdaten werden geladen", fr: "Chargement du graphique", ko: "차트 데이터 로드 중", ptPT: "A carregar dados do gráfico", es: "Cargando datos del gráfico") }
    static var stockChartNoData: String { text("当前数据源无折线数据", "No chart data from the current source", zhHant: "目前資料源無折線資料", ja: "現在のデータ元にはチャートデータがありません", ar: "لا توجد بيانات مخطط من المصدر الحالي", de: "Keine Diagrammdaten aus der aktuellen Quelle", fr: "Aucune donnée graphique pour cette source", ko: "현재 데이터 소스에 차트 데이터가 없습니다", ptPT: "Sem dados de gráfico nesta fonte", es: "Esta fuente no tiene datos de gráfico") }
    static var stockChartLoadFailed: String { text("折线数据加载失败", "Failed to load chart data", zhHant: "折線資料載入失敗", ja: "チャートの読み込みに失敗しました", ar: "فشل تحميل بيانات المخطط", de: "Diagrammdaten konnten nicht geladen werden", fr: "Échec du chargement du graphique", ko: "차트 데이터를 불러오지 못했습니다", ptPT: "Falha ao carregar o gráfico", es: "No se pudo cargar el gráfico") }
    static var chineseStockDataSource: String { text("中文源（东方财富/腾讯）", "Chinese source (Eastmoney/Tencent)", zhHant: "中文源（東方財富/騰訊）", ja: "中国語ソース", ar: "مصدر صيني", de: "Chinesische Quelle", fr: "Source chinoise", ko: "중국어 소스", ptPT: "Fonte chinesa", es: "Fuente china") }
    static var eastMoneyStockDataSource: String { text("东方财富", "Eastmoney", zhHant: "東方財富", ja: "Eastmoney", ar: "Eastmoney", de: "Eastmoney", fr: "Eastmoney", ko: "Eastmoney", ptPT: "Eastmoney", es: "Eastmoney") }
    static var tencentStockDataSource: String { text("腾讯", "Tencent", zhHant: "騰訊", ja: "Tencent", ar: "Tencent", de: "Tencent", fr: "Tencent", ko: "Tencent", ptPT: "Tencent", es: "Tencent") }
    static var yahooStockDataSource: String { "Yahoo Finance" }
    static var statusBarBackgroundSetting: String { text("标题颜色", "Title color", zhHant: "標題顏色", ja: "タイトル色", ar: "لون العنوان", de: "Titelfarbe", fr: "Couleur titre", ko: "제목 색상", ptPT: "Cor título", es: "Color título") }
    static var darkStatusBarBackground: String { text("资产标题-白", "Asset title - white", zhHant: "資產標題-白", ja: "資産名 - 白", ar: "عنوان الأصل - أبيض", de: "Titel - Weiß", fr: "Titre - blanc", ko: "자산 제목 - 흰색", ptPT: "Título - branco", es: "Título - blanco") }
    static var lightStatusBarBackground: String { text("资产标题-黑", "Asset title - black", zhHant: "資產標題-黑", ja: "資産名 - 黒", ar: "عنوان الأصل - أسود", de: "Titel - Schwarz", fr: "Titre - noir", ko: "자산 제목 - 검정", ptPT: "Título - preto", es: "Título - negro") }
    static var titleBlue: String { text("资产标题-蓝", "Asset title - blue", zhHant: "資產標題-藍", ja: "資産名 - 青", ar: "عنوان الأصل - أزرق", de: "Titel - Blau", fr: "Titre - bleu", ko: "자산 제목 - 파랑", ptPT: "Título - azul", es: "Título - azul") }
    static var titleYellow: String { text("资产标题-黄", "Asset title - yellow", zhHant: "資產標題-黃", ja: "資産名 - 黄", ar: "عنوان الأصل - أصفر", de: "Titel - Gelb", fr: "Titre - jaune", ko: "자산 제목 - 노랑", ptPT: "Título - amarelo", es: "Título - amarillo") }
    static var titlePurple: String { text("资产标题-紫", "Asset title - purple", zhHant: "資產標題-紫", ja: "資産名 - 紫", ar: "عنوان الأصل - أرجواني", de: "Titel - Lila", fr: "Titre - violet", ko: "자산 제목 - 보라", ptPT: "Título - roxo", es: "Título - morado") }
    static var appTooltip: String { "CareAssets" }

    static func assetAddedToast(_ name: String) -> String {
        text("已添加 \(name)", "Added \(name)", zhHant: "已新增 \(name)", ja: "\(name) を追加しました", ar: "تمت إضافة \(name)", de: "\(name) hinzugefügt", fr: "\(name) ajouté", ko: "\(name) 추가됨", ptPT: "\(name) adicionado", es: "\(name) añadido")
    }

    static func assetRemovedToast(_ name: String) -> String {
        text("已移除 \(name)", "Removed \(name)", zhHant: "已移除 \(name)", ja: "\(name) を削除しました", ar: "تمت إزالة \(name)", de: "\(name) entfernt", fr: "\(name) retiré", ko: "\(name) 제거됨", ptPT: "\(name) removido", es: "\(name) eliminado")
    }

    static func refreshState(isRefreshing: Bool, countdown: Int) -> String {
        if isRefreshing {
            return text("刷新中", "Refreshing", zhHant: "重新整理中", ja: "更新中", ar: "جارٍ التحديث", de: "Aktualisiert", fr: "Actualisation", ko: "새로고침 중", ptPT: "A atualizar", es: "Actualizando")
        }
        return text("刷新：\(countdown)s", "Refresh: \(countdown)s", zhHant: "重新整理：\(countdown)s", ja: "更新：\(countdown)s", ar: "تحديث: \(countdown)s", de: "Aktual.: \(countdown)s", fr: "Actu. : \(countdown)s", ko: "새로고침: \(countdown)s", ptPT: "Atual.: \(countdown)s", es: "Act.: \(countdown)s")
    }

    static func searchFailed(_ message: String) -> String {
        text("搜索失败：\(message)", "Search failed: \(message)", zhHant: "搜尋失敗：\(message)", ja: "検索失敗：\(message)", ar: "فشل البحث: \(message)", de: "Suche fehlgeschlagen: \(message)", fr: "Recherche échouée : \(message)", ko: "검색 실패: \(message)", ptPT: "Pesquisa falhou: \(message)", es: "Error de búsqueda: \(message)")
    }

    static func editPositionTitle(_ name: String) -> String {
        text("\(name) 持仓", "\(name) position", zhHant: "\(name) 持倉", ja: "\(name) 保有", ar: "مركز \(name)", de: "\(name) Position", fr: "Position \(name)", ko: "\(name) 보유", ptPT: "Posição \(name)", es: "Posición \(name)")
    }

    static func invalidPositionInput() -> String {
        text("持仓数量和平均买入价需要是大于 0 的数字。", "Quantity and average buy price must be numbers greater than 0.", zhHant: "持倉數量和平均買入價需要是大於 0 的數字。")
    }
}

enum PriceColorMode: String, Codable, Sendable, CaseIterable {
    case white
    case redRiseGreenFall
    case redFallGreenRise

    var title: String {
        switch self {
        case .white:
            return "⚪"
        case .redRiseGreenFall:
            return "🔴↑ 🟢↓"
        case .redFallGreenRise:
            return "🔴↓ 🟢↑"
        }
    }
}

enum StatusBarBackgroundMode: String, Codable, Sendable, CaseIterable {
    case dark
    case light
    case blue
    case yellow
    case purple

    var title: String {
        switch self {
        case .dark:
            return L10n.darkStatusBarBackground
        case .light:
            return L10n.lightStatusBarBackground
        case .blue:
            return L10n.titleBlue
        case .yellow:
            return L10n.titleYellow
        case .purple:
            return L10n.titlePurple
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = (try? container.decode(String.self)) ?? Self.dark.rawValue
        switch rawValue {
        case Self.dark.rawValue:
            self = .dark
        case Self.light.rawValue:
            self = .light
        case Self.blue.rawValue:
            self = .blue
        case Self.yellow.rawValue:
            self = .yellow
        case Self.purple.rawValue, "red":
            self = .purple
        case "green":
            self = .yellow
        default:
            self = .dark
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

enum StockDataSource: String, Codable, Sendable, CaseIterable {
    case eastMoney
    case tencent
    case yahooFinance

    var title: String {
        switch self {
        case .eastMoney:
            return L10n.eastMoneyStockDataSource
        case .tencent:
            return L10n.tencentStockDataSource
        case .yahooFinance:
            return L10n.yahooStockDataSource
        }
    }

    var sourceTitle: String {
        switch self {
        case .eastMoney:
            return "东方财富行情"
        case .tencent:
            return "腾讯行情"
        case .yahooFinance:
            return "Yahoo Finance"
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = (try? container.decode(String.self)) ?? Self.tencent.rawValue
        switch rawValue {
        case Self.eastMoney.rawValue:
            self = .eastMoney
        case Self.tencent.rawValue, "chinesePublic":
            self = .tencent
        case Self.yahooFinance.rawValue:
            self = .yahooFinance
        default:
            self = .tencent
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

enum StockChartPeriod: String, Codable, Sendable, CaseIterable {
    case off
    case day
    case week
    case month
    case year

    var title: String {
        switch self {
        case .off:
            return L10n.stockChartOff
        case .day:
            return L10n.stockChartDay
        case .week:
            return L10n.stockChartWeek
        case .month:
            return L10n.stockChartMonth
        case .year:
            return L10n.stockChartYear
        }
    }

    var yahooRangeAndInterval: (range: String, interval: String)? {
        switch self {
        case .off:
            return nil
        case .day:
            return ("1d", "5m")
        case .week:
            return ("5d", "30m")
        case .month:
            return ("1mo", "1d")
        case .year:
            return ("1y", "1d")
        }
    }

    var eastMoneyLookbackDays: Int? {
        switch self {
        case .off, .day:
            return nil
        case .week:
            return 10
        case .month:
            return 45
        case .year:
            return 400
        }
    }

    var eastMoneyPointLimit: Int? {
        switch self {
        case .off, .day:
            return nil
        case .week:
            return 5
        case .month:
            return 22
        case .year:
            return 252
        }
    }
}

struct TrackedAsset: Codable, Sendable {
    var type: AssetType
    var name: String
    var symbol: String
    var canonicalSymbol: String?
    var holdingQuantity: Double?
    var averageBuyPrice: Double?
    var visibleInMenuBar: Bool
}

struct AppConfig: Codable, Sendable {
    var refreshIntervalSeconds: Int
    var menuBarMaxItems: Int
    var stockDisplayCurrency: String
    var priceColorMode: PriceColorMode
    var statusBarBackgroundMode: StatusBarBackgroundMode
    var stockDataSource: StockDataSource
    var stockChartPeriod: StockChartPeriod
    var language: AppLanguage
    var assets: [TrackedAsset]

    static let defaultConfig = AppConfig(
        refreshIntervalSeconds: 60,
        menuBarMaxItems: 3,
        stockDisplayCurrency: "CNY",
        priceColorMode: .redFallGreenRise,
        statusBarBackgroundMode: .dark,
        stockDataSource: .tencent,
        stockChartPeriod: .day,
        language: .system,
        assets: [
            TrackedAsset(type: .gold, name: L10n.gold, symbol: "JD_GOLD", canonicalSymbol: "GOLD:JD_GOLD", holdingQuantity: nil, averageBuyPrice: nil, visibleInMenuBar: true),
            TrackedAsset(type: .crypto, name: "BTC", symbol: "BTCUSDT", canonicalSymbol: "CRYPTO:BTC", holdingQuantity: nil, averageBuyPrice: nil, visibleInMenuBar: true),
            TrackedAsset(type: .crypto, name: "ETH", symbol: "ETHUSDT", canonicalSymbol: "CRYPTO:ETH", holdingQuantity: nil, averageBuyPrice: nil, visibleInMenuBar: true),
        ]
    )

    init(
        refreshIntervalSeconds: Int,
        menuBarMaxItems: Int,
        stockDisplayCurrency: String,
        priceColorMode: PriceColorMode = .redFallGreenRise,
        statusBarBackgroundMode: StatusBarBackgroundMode = .dark,
        stockDataSource: StockDataSource = .tencent,
        stockChartPeriod: StockChartPeriod = .day,
        language: AppLanguage = .system,
        assets: [TrackedAsset]
    ) {
        self.refreshIntervalSeconds = refreshIntervalSeconds
        self.menuBarMaxItems = menuBarMaxItems
        self.stockDisplayCurrency = stockDisplayCurrency
        self.priceColorMode = priceColorMode
        self.statusBarBackgroundMode = statusBarBackgroundMode
        self.stockDataSource = stockDataSource
        self.stockChartPeriod = stockChartPeriod
        self.language = language
        self.assets = assets
    }

    private enum CodingKeys: String, CodingKey {
        case refreshIntervalSeconds
        case menuBarMaxItems
        case stockDisplayCurrency
        case priceColorMode
        case statusBarBackgroundMode
        case stockDataSource
        case stockChartPeriod
        case language
        case assets
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        refreshIntervalSeconds = try container.decode(Int.self, forKey: .refreshIntervalSeconds)
        menuBarMaxItems = try container.decode(Int.self, forKey: .menuBarMaxItems)
        stockDisplayCurrency = try container.decode(String.self, forKey: .stockDisplayCurrency)
        priceColorMode = try container.decodeIfPresent(PriceColorMode.self, forKey: .priceColorMode) ?? .redFallGreenRise
        statusBarBackgroundMode = try container.decodeIfPresent(StatusBarBackgroundMode.self, forKey: .statusBarBackgroundMode) ?? .dark
        stockDataSource = try container.decodeIfPresent(StockDataSource.self, forKey: .stockDataSource) ?? .tencent
        stockChartPeriod = try container.decodeIfPresent(StockChartPeriod.self, forKey: .stockChartPeriod) ?? .day
        language = try container.decodeIfPresent(AppLanguage.self, forKey: .language) ?? .system
        assets = try container.decode([TrackedAsset].self, forKey: .assets)
    }
}

struct DisplayAsset: Sendable {
    var id: String
    var type: AssetType
    var name: String
    var symbol: String
    var canonicalSymbol: String?
    var source: String
    var currentPrice: Double?
    var currency: String?
    var menuPriceText: String
    var priceText: String
    var detailText: String
    var changeText: String
    var changePercent: Double?
    var updatedAt: Date?
    var holdingQuantity: Double?
    var averageBuyPrice: Double?
    var visibleInMenuBar: Bool
    var errorMessage: String?

    var positionProfitAmount: Double? {
        guard let currentPrice, let holdingQuantity, let averageBuyPrice,
              holdingQuantity > 0, averageBuyPrice > 0 else { return nil }
        return (currentPrice - averageBuyPrice) * holdingQuantity
    }

    var positionProfitPercent: Double? {
        guard let currentPrice, let averageBuyPrice, averageBuyPrice > 0 else { return nil }
        return (currentPrice - averageBuyPrice) / averageBuyPrice * 100.0
    }

    var positionMarketValue: Double? {
        guard let currentPrice, let holdingQuantity, holdingQuantity > 0 else { return nil }
        return currentPrice * holdingQuantity
    }

    var positionCost: Double? {
        guard let holdingQuantity, let averageBuyPrice,
              holdingQuantity > 0, averageBuyPrice > 0 else { return nil }
        return holdingQuantity * averageBuyPrice
    }

    var hasPosition: Bool {
        positionProfitAmount != nil && positionProfitPercent != nil
    }

    static func loading(from asset: TrackedAsset) -> DisplayAsset {
        DisplayAsset(
            id: assetIdentity(for: asset),
            type: asset.type,
            name: asset.name,
            symbol: asset.symbol,
            canonicalSymbol: asset.canonicalSymbol,
            source: "Loading",
            currentPrice: nil,
            currency: nil,
            menuPriceText: "--",
            priceText: "--",
            detailText: L10n.loading,
            changeText: "--",
            changePercent: nil,
            updatedAt: nil,
            holdingQuantity: asset.holdingQuantity,
            averageBuyPrice: asset.averageBuyPrice,
            visibleInMenuBar: asset.visibleInMenuBar,
            errorMessage: nil
        )
    }
}

struct AssetSearchResult: Sendable, Equatable {
    var type: AssetType
    var name: String
    var symbol: String
    var canonicalSymbol: String?
    var source: String

    var id: String {
        assetIdentity(type: type, symbol: symbol, canonicalSymbol: canonicalSymbol)
    }

    var trackedAsset: TrackedAsset {
        TrackedAsset(type: type, name: name, symbol: symbol.uppercased(), canonicalSymbol: canonicalSymbol ?? canonicalAssetSymbol(type: type, symbol: symbol), holdingQuantity: nil, averageBuyPrice: nil, visibleInMenuBar: false)
    }
}

private func assetIdentity(for asset: TrackedAsset) -> String {
    assetIdentity(type: asset.type, symbol: asset.symbol, canonicalSymbol: asset.canonicalSymbol)
}

private func assetIdentity(type: AssetType, symbol: String, canonicalSymbol: String?) -> String {
    "\(type.rawValue)-\((canonicalSymbol ?? canonicalAssetSymbol(type: type, symbol: symbol)).uppercased())"
}

private func canonicalAssetSymbol(type: AssetType, symbol: String) -> String {
    let uppercased = symbol.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    switch type {
    case .gold:
        return "GOLD:\(uppercased)"
    case .crypto:
        return "CRYPTO:\(cryptoBaseSymbol(from: uppercased))"
    case .stock:
        return canonicalStockSymbol(from: uppercased)
    }
}

private func canonicalStockSymbol(from symbol: String) -> String {
    let uppercased = symbol.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    if uppercased.hasSuffix(".HK") {
        let code = uppercased.replacingOccurrences(of: ".HK", with: "")
        return "HK:\(paddedHongKongCode(code))"
    }
    if uppercased.hasSuffix(".KS") || uppercased.hasSuffix(".KQ") {
        return "KR:\(String(uppercased.dropLast(3)))"
    }
    if uppercased.hasSuffix(".SS") {
        return "SH:\(uppercased.replacingOccurrences(of: ".SS", with: ""))"
    }
    if uppercased.hasSuffix(".SZ") {
        return "SZ:\(uppercased.replacingOccurrences(of: ".SZ", with: ""))"
    }
    if uppercased.range(of: #"^\d{5}$"#, options: .regularExpression) != nil {
        return "HK:\(uppercased)"
    }
    if uppercased.range(of: #"^\d{6}$"#, options: .regularExpression) != nil {
        if uppercased.hasPrefix("6") {
            return "SH:\(uppercased)"
        }
        return "SZ:\(uppercased)"
    }
    return "US:\(uppercased)"
}

private func paddedHongKongCode(_ code: String) -> String {
    guard let number = Int(code) else { return code.uppercased() }
    return String(format: "%05d", number)
}

final class ConfigStore {
    static let appSupportURL: URL = {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent("CareAssets", isDirectory: true)
    }()

    static let configURL = appSupportURL.appendingPathComponent("config.json")

    static func loadOrCreate() -> AppConfig {
        let fileManager = FileManager.default
        try? fileManager.createDirectory(at: appSupportURL, withIntermediateDirectories: true)

        guard fileManager.fileExists(atPath: configURL.path) else {
            write(AppConfig.defaultConfig)
            return AppConfig.defaultConfig
        }

        do {
            let data = try Data(contentsOf: configURL)
            var config = try JSONDecoder().decode(AppConfig.self, from: data)
            if migrate(&config) {
                write(config)
            }
            return config
        } catch {
            return AppConfig.defaultConfig
        }
    }

    private static func migrate(_ config: inout AppConfig) -> Bool {
        var changed = false
        for index in config.assets.indices {
            if config.assets[index].symbol == "2015.HK", config.assets[index].name == "理想" {
                config.assets[index].name = "理想汽车"
                changed = true
            }
            let canonical = canonicalAssetSymbol(type: config.assets[index].type, symbol: config.assets[index].symbol)
            if config.assets[index].canonicalSymbol?.isEmpty != false {
                config.assets[index].canonicalSymbol = canonical
                changed = true
            }
        }
        let legacyDefaultSymbols = ["JD_GOLD", "BTCUSDT", "ETHUSDT", "1810.HK", "2015.HK"]
        let currentSymbols = config.assets.map(\.symbol)
        if currentSymbols == legacyDefaultSymbols {
            config.assets.removeAll { ["1810.HK", "2015.HK"].contains($0.symbol) }
            changed = true
        }
        return changed
    }

    static func write(_ config: AppConfig) {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(config)
            try data.write(to: configURL, options: .atomic)
        } catch {
            NSLog("CareAssets config write failed: \(error.localizedDescription)")
        }
    }
}

enum LoginLaunchAgent {
    private static var label: String {
        let bundleID = Bundle.main.bundleIdentifier ?? "com.highway.CareAssets.StatusBar"
        return "\(bundleID).LaunchAtLogin"
    }

    private static var launchAgentURL: URL {
        let directory = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library", isDirectory: true)
            .appendingPathComponent("LaunchAgents", isDirectory: true)
        return directory.appendingPathComponent("\(label).plist")
    }

    static var isEnabled: Bool {
        guard let plist = NSDictionary(contentsOf: launchAgentURL),
              let arguments = plist["ProgramArguments"] as? [String] else {
            return false
        }
        return arguments.contains(Bundle.main.bundleURL.path)
    }

    static func setEnabled(_ enabled: Bool) throws {
        let fileManager = FileManager.default
        let url = launchAgentURL

        if enabled {
            try fileManager.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            let plist: [String: Any] = [
                "Label": label,
                "ProgramArguments": [
                    "/usr/bin/open",
                    "-g",
                    Bundle.main.bundleURL.path
                ],
                "RunAtLoad": true
            ]
            let data = try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
            try data.write(to: url, options: .atomic)
        } else if fileManager.fileExists(atPath: url.path) {
            try fileManager.removeItem(at: url)
        }
    }
}

enum FontRegistrar {
    static func registerBundledFonts() {
        guard let url = Bundle.main.url(forResource: "Sen-Medium", withExtension: "ttf", subdirectory: "Fonts") else {
            return
        }
        CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
    }
}

final class AssetService {
    private let session: URLSession

    init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 12
        configuration.timeoutIntervalForResource = 18
        configuration.httpAdditionalHeaders = [
            "User-Agent": "CareAssets/1.0 macOS"
        ]
        session = URLSession(configuration: configuration)
    }

    func fetchAssets(config: AppConfig) async -> [DisplayAsset] {
        var results: [String: DisplayAsset] = [:]

        for asset in config.assets where asset.type == .gold {
            results[key(for: asset)] = await fetchGold(asset)
        }

        let cryptoAssets = config.assets.filter { $0.type == .crypto }
        if !cryptoAssets.isEmpty {
            let fetched = await fetchCryptoAssets(cryptoAssets)
            for (key, value) in fetched {
                results[key] = value
            }
        }

        let stockAssets = config.assets.filter { $0.type == .stock }
        if !stockAssets.isEmpty {
            let fetched = await fetchStockAssets(stockAssets, dataSource: config.stockDataSource)
            for (key, value) in fetched {
                results[key] = value
            }
        }

        return config.assets.map { asset in
            results[key(for: asset)] ?? DisplayAsset.loading(from: asset)
        }
    }

    private func key(for asset: TrackedAsset) -> String {
        assetIdentity(for: asset)
    }

    private func requestData(from url: URL, timeoutInterval: TimeInterval? = nil) async throws -> Data {
        var request = URLRequest(url: url)
        request.setValue("CareAssets/1.0 macOS", forHTTPHeaderField: "User-Agent")
        request.cachePolicy = .reloadIgnoringLocalCacheData
        if let timeoutInterval {
            request.timeoutInterval = timeoutInterval
        }

        let (data, response) = try await session.data(for: request)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw NSError(domain: "CareAssets.HTTP", code: http.statusCode)
        }
        return data
    }
}

// MARK: - Gold

private struct JDGoldResponse: Decodable {
    var resultData: JDGoldResultData?
    var success: Bool?
}

private struct JDGoldResultData: Decodable {
    var datas: JDGoldData?
}

private struct JDGoldData: Decodable {
    var price: String?
    var yesterdayPrice: String?
    var upAndDownAmt: String?
    var upAndDownRate: String?
    var time: String?
}

private struct K780GoldResponse: Decodable {
    var success: String?
    var result: K780GoldResult?
    var msgid: String?
    var msg: String?
}

private struct K780GoldResult: Decodable {
    var dtList: [String: K780GoldQuote]?
}

private struct K780GoldQuote: Decodable {
    var varietynm: String?
    var lastPrice: String?
    var buyPrice: String?
    var sellPrice: String?
    var yesyPrice: String?
    var changePrice: String?
    var changeMargin: String?
    var uptime: String?

    enum CodingKeys: String, CodingKey {
        case varietynm
        case lastPrice = "last_price"
        case buyPrice = "buy_price"
        case sellPrice = "sell_price"
        case yesyPrice = "yesy_price"
        case changePrice = "change_price"
        case changeMargin = "change_margin"
        case uptime
    }
}

private struct CMBGoldRateResponse: Decodable {
    var body: CMBGoldRateBody?
}

private struct CMBGoldRateBody: Decodable {
    var data: [CMBGoldRateItem]?
    var time: String?
}

private struct CMBGoldRateItem: Decodable {
    var variety: String?
    var curPrice: String?
    var preClose: String?
    var time: String?
    var goldNo: String?
}

private struct ChineseGoldCloseReference {
    var close: Double
    var updatedAt: Date?
}

extension AssetService {
    private func fetchGold(_ asset: TrackedAsset) async -> DisplayAsset {
        if L10n.usesChineseMarketUnits {
            if let quote = await fetchK780ChineseGold(asset) {
                return quote
            }
            return await fetchDerivedChineseGold(asset)
        }

        return await fetchInternationalGold(asset)
    }

    private func fetchK780ChineseGold(_ asset: TrackedAsset) async -> DisplayAsset? {
        let url = URL(string: "https://sapi.k780.com/?app=finance.gold_price&goldid=1011&appkey=10003&sign=b59bc3ef6191eb9f747dd4e83c99f2a4&format=json")!

        do {
            let data = try await requestData(from: url)
            let response = try JSONDecoder().decode(K780GoldResponse.self, from: data)
            guard response.success == "1",
                  let quote = response.result?.dtList?["1011"] ?? response.result?.dtList?.values.first,
                  let priceText = quote.lastPrice ?? quote.sellPrice ?? quote.buyPrice,
                  let price = Double(priceText),
                  price > 0 else {
                return nil
            }

            let directPrevious = positiveDouble(quote.yesyPrice)
            var changeAmount = meaningfulChange(quote.changePrice)
            var previous = directPrevious ?? changeAmount.map { price - $0 }.flatMap { $0 > 0 ? $0 : nil }
            var percent = meaningfulPercent(quote.changeMargin) ?? previous.flatMap { previousPrice -> Double? in
                guard previousPrice != 0 else { return nil }
                return (price - previousPrice) / previousPrice * 100.0
            }
            if previous == nil || percent == nil {
                if let closeReference = try? await fetchChineseGoldCloseReference() {
                    previous = previous ?? closeReference.close
                }
            }
            if changeAmount == nil, let previous {
                changeAmount = price - previous
            }
            if percent == nil, let previous, previous != 0 {
                percent = (price - previous) / previous * 100.0
            }
            let detail: String
            if let previous {
                detail = "\(L10n.close) \(formatCNY(previous, compact: false))\(L10n.gramSuffix)"
            } else {
                detail = quote.varietynm ?? L10n.cnyPerGram
            }

            return DisplayAsset(
                id: key(for: asset),
                type: .gold,
                name: asset.name,
                symbol: asset.symbol,
                canonicalSymbol: asset.canonicalSymbol,
                source: "K780",
                currentPrice: price,
                currency: "CNY",
                menuPriceText: formatStatusNumber(price, minFraction: 0, maxFraction: 0),
                priceText: "\(formatCNY(price, compact: false))\(L10n.gramSuffix)",
                detailText: detail,
                changeText: formatChange(amount: changeAmount, percent: percent, currencyPrefix: "¥"),
                changePercent: percent,
                updatedAt: parseLocalDateTime(quote.uptime),
                holdingQuantity: asset.holdingQuantity,
                averageBuyPrice: asset.averageBuyPrice,
                visibleInMenuBar: asset.visibleInMenuBar,
                errorMessage: nil
            )
        } catch {
            return nil
        }
    }

    private func fetchChineseGoldCloseReference() async throws -> ChineseGoldCloseReference? {
        let url = URL(string: "https://m.cmbchina.com/api/rate/gold?no=AUTD")!
        let data = try await requestData(from: url)
        let response = try JSONDecoder().decode(CMBGoldRateResponse.self, from: data)
        guard let body = response.body, let items = body.data else { return nil }
        let item = items.first { $0.goldNo?.uppercased() == "AUTD" } ?? items.first
        guard let item, let close = positiveDouble(item.curPrice) else { return nil }

        let datePrefix = body.time?.split(separator: " ").first.map(String.init)
        let updatedAt = datePrefix.flatMap { date in
            item.time.flatMap { parseLocalDateTime("\(date) \($0)") }
        } ?? parseLocalDateTime(body.time)
        return ChineseGoldCloseReference(close: close, updatedAt: updatedAt)
    }

    private func fetchDerivedChineseGold(_ asset: TrackedAsset) async -> DisplayAsset {
        let encodedSymbol = "GC=F".addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? "GC=F"
        let url = URL(string: "https://query1.finance.yahoo.com/v8/finance/chart/\(encodedSymbol)?range=5d&interval=1d")!

        do {
            async let goldData = requestData(from: url)
            async let usdCnyQuote = fetchFXQuote(from: "USD", to: "CNY")

            let data = try await goldData
            let usdCny = try await usdCnyQuote
            let response = try JSONDecoder().decode(YahooChartResponse.self, from: data)
            guard let meta = response.chart.result?.first?.meta,
                  let ouncePrice = meta.regularMarketPrice else {
                throw NSError(domain: "CareAssets.Gold", code: 2)
            }

            let gramsPerTroyOunce = 31.1034768
            let price = ouncePrice * usdCny.rate / gramsPerTroyOunce
            let previous = meta.chartPreviousClose.map { ouncePreviousClose in
                ouncePreviousClose * (usdCny.previousClose ?? usdCny.rate) / gramsPerTroyOunce
            }
            let change = previous.map { price - $0 }
            let percent = previous.flatMap { previousPrice -> Double? in
                guard previousPrice != 0 else { return nil }
                return (price - previousPrice) / previousPrice * 100.0
            }
            let goldUpdatedAt = meta.regularMarketTime.map { Date(timeIntervalSince1970: TimeInterval($0)) }
            let updatedAt = latestDate(goldUpdatedAt, usdCny.updatedAt)

            return DisplayAsset(
                id: key(for: asset),
                type: .gold,
                name: asset.name,
                symbol: asset.symbol,
                canonicalSymbol: asset.canonicalSymbol,
                source: "Yahoo Finance",
                currentPrice: price,
                currency: "CNY",
                menuPriceText: formatStatusNumber(price, minFraction: 0, maxFraction: 0),
                priceText: "\(formatCNY(price, compact: false))\(L10n.gramSuffix)",
                detailText: previous.map { "\(L10n.close) \(formatCNY($0, compact: false))\(L10n.gramSuffix)" } ?? L10n.cnyPerGram,
                changeText: formatChange(amount: change, percent: percent, currencyPrefix: "¥"),
                changePercent: percent,
                updatedAt: updatedAt,
                holdingQuantity: asset.holdingQuantity,
                averageBuyPrice: asset.averageBuyPrice,
                visibleInMenuBar: asset.visibleInMenuBar,
                errorMessage: nil
            )
        } catch {
            return errorAsset(asset, source: "Yahoo Finance", message: error.localizedDescription)
        }
    }

    private func fetchInternationalGold(_ asset: TrackedAsset) async -> DisplayAsset {
        let encodedSymbol = "GC=F".addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? "GC=F"
        let url = URL(string: "https://query1.finance.yahoo.com/v8/finance/chart/\(encodedSymbol)?range=5d&interval=1d")!

        do {
            let data = try await requestData(from: url)
            let response = try JSONDecoder().decode(YahooChartResponse.self, from: data)
            guard let meta = response.chart.result?.first?.meta,
                  let price = meta.regularMarketPrice else {
                throw NSError(domain: "CareAssets.Gold", code: 2)
            }

            let previous = meta.chartPreviousClose
            let change = previous.map { price - $0 }
            let percent = previous.flatMap { previousPrice -> Double? in
                guard previousPrice != 0 else { return nil }
                return (price - previousPrice) / previousPrice * 100.0
            }
            let currency = meta.currency ?? "USD"
            let updatedAt = meta.regularMarketTime.map { Date(timeIntervalSince1970: TimeInterval($0)) }

            return DisplayAsset(
                id: key(for: asset),
                type: .gold,
                name: asset.name,
                symbol: asset.symbol,
                canonicalSymbol: asset.canonicalSymbol,
                source: "Yahoo Finance",
                currentPrice: price,
                currency: currency,
                menuPriceText: formatStatusNumber(price, minFraction: 0, maxFraction: 0),
                priceText: "\(formatCurrency(price, currencyCode: currency, compact: false))\(L10n.ounceSuffix)",
                detailText: previous.map { "\(L10n.close) \(formatCurrency($0, currencyCode: currency, compact: false))\(L10n.ounceSuffix)" } ?? L10n.usdPerOunce,
                changeText: formatChange(amount: change, percent: percent, currencyPrefix: currencySymbol(for: currency)),
                changePercent: percent,
                updatedAt: updatedAt,
                holdingQuantity: asset.holdingQuantity,
                averageBuyPrice: asset.averageBuyPrice,
                visibleInMenuBar: asset.visibleInMenuBar,
                errorMessage: nil
            )
        } catch {
            return errorAsset(asset, source: "Yahoo Finance", message: error.localizedDescription)
        }
    }
}

// MARK: - Crypto

private struct CoinbaseTicker: Decodable {
    var price: String?
    var time: String?
}

private struct CoinbaseStats: Decodable {
    var open: String?
}

private struct CoinbaseProduct: Decodable {
    var id: String
    var baseCurrency: String
    var quoteCurrency: String
    var displayName: String?

    enum CodingKeys: String, CodingKey {
        case id
        case baseCurrency = "base_currency"
        case quoteCurrency = "quote_currency"
        case displayName = "display_name"
    }
}

extension AssetService {
    private func fetchCryptoAssets(_ assets: [TrackedAsset]) async -> [String: DisplayAsset] {
        var output: [String: DisplayAsset] = [:]
        for asset in assets {
            output[key(for: asset)] = await fetchCoinbaseCryptoAsset(asset)
        }
        return output
    }

    private func fetchCoinbaseCryptoAsset(_ asset: TrackedAsset) async -> DisplayAsset {
        let productID = coinbaseProductID(for: asset.symbol)
        let encodedProductID = productID.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? productID
        let tickerURL = URL(string: "https://api.exchange.coinbase.com/products/\(encodedProductID)/ticker")!
        let statsURL = URL(string: "https://api.exchange.coinbase.com/products/\(encodedProductID)/stats")!

        do {
            async let tickerData = requestData(from: tickerURL)
            async let statsData = requestData(from: statsURL)

            let ticker = try await JSONDecoder().decode(CoinbaseTicker.self, from: tickerData)
            let stats = try await JSONDecoder().decode(CoinbaseStats.self, from: statsData)

            guard let priceText = ticker.price, let price = Double(priceText) else {
                throw NSError(domain: "CareAssets.Coinbase", code: 1)
            }

            let open = stats.open.flatMap(Double.init)
            let change = open.map { price - $0 }
            let percent = open.flatMap { openPrice -> Double? in
                guard openPrice != 0 else { return nil }
                return (price - openPrice) / openPrice * 100.0
            }
            let quoteCurrency = productID.split(separator: "-").last.map(String.init) ?? "USDT"

            return DisplayAsset(
                id: key(for: asset),
                type: .crypto,
                name: asset.name,
                symbol: asset.symbol,
                canonicalSymbol: asset.canonicalSymbol,
                source: "Coinbase",
                currentPrice: price,
                currency: quoteCurrency,
                menuPriceText: formatStatusNumber(price, minFraction: 0, maxFraction: 0),
                priceText: "\(formatNumber(price, minFraction: 2, maxFraction: 2)) \(quoteCurrency)",
                detailText: productID,
                changeText: formatChange(amount: change, percent: percent, currencyPrefix: ""),
                changePercent: percent,
                updatedAt: parseISO8601Date(ticker.time),
                holdingQuantity: asset.holdingQuantity,
                averageBuyPrice: asset.averageBuyPrice,
                visibleInMenuBar: asset.visibleInMenuBar,
                errorMessage: nil
            )
        } catch {
            return errorAsset(asset, source: "Coinbase", message: error.localizedDescription)
        }
    }

    private func coinbaseProductID(for symbol: String) -> String {
        let uppercased = symbol.uppercased()
        if uppercased.contains("-") {
            return uppercased
        }

        for quote in ["USDT", "USDC", "USD"] {
            if uppercased.hasSuffix(quote) {
                let base = uppercased.dropLast(quote.count)
                return "\(base)-\(quote)"
            }
        }

        return "\(uppercased)-USDT"
    }
}

// MARK: - Stocks and FX

private struct YahooChartResponse: Decodable {
    var chart: YahooChart
}

private struct YahooChart: Decodable {
    var result: [YahooResult]?
}

private struct YahooResult: Decodable {
    var meta: YahooMeta
    var timestamp: [Int]?
    var indicators: YahooIndicators?
}

private struct YahooIndicators: Decodable {
    var quote: [YahooQuoteSeries]?
}

private struct YahooQuoteSeries: Decodable {
    var close: [Double?]?
}

private struct YahooMeta: Decodable {
    var currency: String?
    var symbol: String?
    var regularMarketTime: Int?
    var regularMarketPrice: Double?
    var chartPreviousClose: Double?
    var shortName: String?
    var longName: String?
}

private struct YahooSearchResponse: Decodable {
    var quotes: [YahooSearchQuote]?
}

private struct YahooSearchQuote: Decodable {
    var symbol: String?
    var shortname: String?
    var longname: String?
    var quoteType: String?
    var exchDisp: String?
    var exchange: String?
}

private struct AlphaVantageSearchResponse: Decodable {
    var bestMatches: [AlphaVantageMatch]?
}

private struct AlphaVantageMatch: Decodable {
    var symbol: String?
    var name: String?
    var type: String?
    var region: String?

    enum CodingKeys: String, CodingKey {
        case symbol = "1. symbol"
        case name = "2. name"
        case type = "3. type"
        case region = "4. region"
    }
}

private struct EastMoneySearchResponse: Decodable {
    var quotationCodeTable: EastMoneyQuotationCodeTable?

    enum CodingKeys: String, CodingKey {
        case quotationCodeTable = "QuotationCodeTable"
    }
}

private struct EastMoneyQuotationCodeTable: Decodable {
    var data: [EastMoneySearchItem]?

    enum CodingKeys: String, CodingKey {
        case data = "Data"
    }
}

private struct EastMoneySearchItem: Decodable {
    var code: String?
    var name: String?
    var pinyin: String?
    var exchange: String?
    var classify: String?
    var securityTypeName: String?
    var quoteID: String?

    enum CodingKeys: String, CodingKey {
        case code = "Code"
        case name = "Name"
        case pinyin = "PinYin"
        case exchange = "JYS"
        case classify = "Classify"
        case securityTypeName = "SecurityTypeName"
        case quoteID = "QuoteID"
    }
}

private struct EastMoneyQuoteResponse: Decodable {
    var data: EastMoneyQuoteData?
}

private struct EastMoneyQuoteData: Decodable {
    var diff: [EastMoneyQuoteItem]?
}

private struct EastMoneyQuoteItem: Decodable {
    var code: String?
    var market: Int?
    var name: String?
    var price: Double?
    var previousClose: Double?
    var updatedAt: Int?
    var scale: Int?

    enum CodingKeys: String, CodingKey {
        case code = "f12"
        case market = "f13"
        case name = "f14"
        case price = "f2"
        case previousClose = "f18"
        case updatedAt = "f124"
        case scale = "f152"
    }
}

private struct EastMoneyChartResponse: Decodable {
    var data: EastMoneyChartData?
}

private struct EastMoneyChartData: Decodable {
    var trends: [String]?
    var klines: [String]?
}

struct StockChartPoint: Sendable {
    var date: Date
    var price: Double
}

enum StockChartState: Sendable {
    case loading
    case loaded([StockChartPoint])
    case unavailable
    case failed
}

private struct RawStockQuote {
    var asset: TrackedAsset
    var price: Double
    var previousClose: Double?
    var currency: String
    var displayName: String
    var source: String
    var updatedAt: Date?
}

private struct FXQuote {
    var rate: Double
    var previousClose: Double?
    var updatedAt: Date?
}

extension AssetService {
    func searchAssets(query: String, stockDataSource: StockDataSource) async throws -> [AssetSearchResult] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        var stockResults: [AssetSearchResult] = []
        var cryptoResults: [AssetSearchResult] = []
        var firstError: Error?

        switch stockDataSource {
        case .eastMoney:
            do {
                stockResults.append(contentsOf: try await searchEastMoneyStocks(query: trimmed))
            } catch {
                firstError = error
            }
        case .tencent:
            do {
                stockResults.append(contentsOf: try await searchTencentStocks(query: trimmed))
            } catch {
                firstError = error
            }
        case .yahooFinance:
            do {
                stockResults.append(contentsOf: try await searchYahooStocks(query: trimmed))
            } catch {
                firstError = error
            }

            if stockResults.isEmpty {
                if let fallback = try? await searchAlphaVantageStocks(query: trimmed) {
                    stockResults.append(contentsOf: fallback)
                }
            }
        }

        do {
            cryptoResults.append(contentsOf: try await searchCoinbaseCryptoAssets(query: trimmed))
        } catch {
            if firstError == nil {
                firstError = error
            }
        }

        let uniqueResults = rankAssetSearchResults(uniqueAssetSearchResults(cryptoResults + stockResults), query: trimmed)
        if uniqueResults.isEmpty, let firstError {
            throw firstError
        }
        return Array(uniqueResults.prefix(12))
    }

    private func fetchStockAssets(_ assets: [TrackedAsset], dataSource: StockDataSource) async -> [String: DisplayAsset] {
        var rawQuotes: [RawStockQuote] = []
        var output: [String: DisplayAsset] = [:]

        for asset in assets {
            do {
                rawQuotes.append(try await fetchStockQuote(asset, dataSource: dataSource))
            } catch {
                output[key(for: asset)] = errorAsset(asset, source: dataSource.sourceTitle, message: error.localizedDescription)
            }
        }

        for quote in rawQuotes {
            let change = quote.previousClose.map { quote.price - $0 }
            let percent = quote.previousClose.flatMap { previous -> Double? in
                guard previous != 0 else { return nil }
                return (quote.price - previous) / previous * 100.0
            }

            output[key(for: quote.asset)] = DisplayAsset(
                id: key(for: quote.asset),
                type: .stock,
                name: quote.displayName,
                symbol: quote.asset.symbol,
                canonicalSymbol: quote.asset.canonicalSymbol,
                source: quote.source,
                currentPrice: quote.price,
                currency: quote.currency,
                menuPriceText: formatStatusNumber(quote.price, minFraction: 2, maxFraction: 2),
                priceText: "\(formatNumber(quote.price, minFraction: 2, maxFraction: 2)) \(quote.currency)",
                detailText: quote.asset.symbol,
                changeText: formatChange(amount: change, percent: percent, currencyPrefix: currencySymbol(for: quote.currency)),
                changePercent: percent,
                updatedAt: quote.updatedAt,
                holdingQuantity: quote.asset.holdingQuantity,
                averageBuyPrice: quote.asset.averageBuyPrice,
                visibleInMenuBar: quote.asset.visibleInMenuBar,
                errorMessage: nil
            )
        }

        return output
    }

    private func searchEastMoneyStocks(query: String) async throws -> [AssetSearchResult] {
        var components = URLComponents(string: "https://searchapi.eastmoney.com/api/suggest/get")!
        components.queryItems = [
            URLQueryItem(name: "input", value: query),
            URLQueryItem(name: "type", value: "14"),
            URLQueryItem(name: "token", value: "D43BF722C8E33BDC906FB84D85E326E8"),
            URLQueryItem(name: "count", value: "12")
        ]

        guard let url = components.url else { return [] }
        let data = try await requestData(from: url)
        let response = try JSONDecoder().decode(EastMoneySearchResponse.self, from: data)

        return (response.quotationCodeTable?.data ?? []).compactMap { item in
            guard let code = item.code?.trimmingCharacters(in: .whitespacesAndNewlines),
                  let name = item.name?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !code.isEmpty,
                  !name.isEmpty,
                  let canonical = eastMoneyCanonicalSymbol(for: item) else {
                return nil
            }

            let source = item.securityTypeName ?? item.exchange ?? "东方财富"
            return AssetSearchResult(type: .stock, name: name, symbol: code.uppercased(), canonicalSymbol: canonical, source: source)
        }
    }

    private func searchTencentStocks(query: String) async throws -> [AssetSearchResult] {
        var components = URLComponents(string: "https://smartbox.gtimg.cn/s3/")!
        components.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "t", value: "all")
        ]

        guard let url = components.url else { return [] }
        let data = try await requestData(from: url)
        let responseText = String(data: data, encoding: .utf8) ?? ""
        let hint = try decodeTencentSearchHint(responseText)

        return hint
            .split(separator: "^")
            .compactMap { entry -> AssetSearchResult? in
                let parts = entry.split(separator: "~", omittingEmptySubsequences: false).map(String.init)
                guard parts.count >= 5 else { return nil }

                let market = parts[0].uppercased()
                let rawCode = parts[1].uppercased()
                let name = parts[2].trimmingCharacters(in: .whitespacesAndNewlines)
                let type = parts[4].uppercased()
                guard type.hasPrefix("GP"), !name.isEmpty else { return nil }

                let symbol: String
                let canonical: String
                switch market {
                case "HK":
                    symbol = paddedHongKongCode(rawCode)
                    canonical = "HK:\(symbol)"
                case "SH":
                    symbol = rawCode
                    canonical = "SH:\(symbol)"
                case "SZ":
                    symbol = rawCode
                    canonical = "SZ:\(symbol)"
                case "US":
                    symbol = rawCode.split(separator: ".").first.map(String.init) ?? rawCode
                    canonical = "US:\(symbol)"
                default:
                    return nil
                }

                return AssetSearchResult(type: .stock, name: name, symbol: symbol, canonicalSymbol: canonical, source: "腾讯")
            }
    }

    private func decodeTencentSearchHint(_ text: String) throws -> String {
        guard let firstQuote = text.firstIndex(of: "\""),
              let lastQuote = text.lastIndex(of: "\""),
              firstQuote < lastQuote else {
            throw NSError(domain: "CareAssets.TencentSearch", code: 1)
        }

        let rawHint = String(text[text.index(after: firstQuote)..<lastQuote])
        let jsonString = "\"\(rawHint)\""
        return try JSONDecoder().decode(String.self, from: Data(jsonString.utf8))
    }

    private func searchYahooStocks(query: String) async throws -> [AssetSearchResult] {
        var output: [AssetSearchResult] = []
        var firstError: Error?

        for searchQuery in stockSearchQueries(for: query) {
            var components = URLComponents(string: "https://query1.finance.yahoo.com/v1/finance/search")!
            components.queryItems = [
                URLQueryItem(name: "q", value: searchQuery),
                URLQueryItem(name: "quotesCount", value: "12"),
                URLQueryItem(name: "newsCount", value: "0")
            ]

            guard let url = components.url else { continue }

            do {
                let data = try await requestData(from: url)
                let response = try JSONDecoder().decode(YahooSearchResponse.self, from: data)
                output.append(contentsOf: yahooStockResults(from: response))
            } catch {
                if firstError == nil {
                    firstError = error
                }
            }
        }

        let unique = uniqueAssetSearchResults(output)
        if unique.isEmpty, let firstError {
            throw firstError
        }
        return unique
    }

    private func stockSearchQueries(for query: String) -> [String] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        var queries = [trimmed]
        let uppercased = trimmed.uppercased()

        if uppercased.range(of: #"^\d{4,5}$"#, options: .regularExpression) != nil {
            queries.append("\(uppercased).HK")
            if let number = Int(uppercased) {
                queries.append("\(number).HK")
            }
        }

        var seen: Set<String> = []
        return queries.filter { query in
            let key = query.uppercased()
            guard !seen.contains(key) else { return false }
            seen.insert(key)
            return true
        }
    }

    private func yahooStockResults(from response: YahooSearchResponse) -> [AssetSearchResult] {
        (response.quotes ?? []).compactMap { quote in
            guard let symbol = quote.symbol?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !symbol.isEmpty else { return nil }

            let type = quote.quoteType?.uppercased() ?? ""
            if !type.isEmpty, !["EQUITY", "ETF"].contains(type) {
                return nil
            }

            let name = quote.shortname ?? quote.longname ?? symbol
            let exchange = quote.exchDisp ?? quote.exchange ?? "Yahoo"
            return AssetSearchResult(type: .stock, name: name, symbol: symbol.uppercased(), canonicalSymbol: canonicalAssetSymbol(type: .stock, symbol: symbol), source: exchange)
        }
    }

    private func searchAlphaVantageStocks(query: String) async throws -> [AssetSearchResult] {
        var components = URLComponents(string: "https://www.alphavantage.co/query")!
        components.queryItems = [
            URLQueryItem(name: "function", value: "SYMBOL_SEARCH"),
            URLQueryItem(name: "keywords", value: query),
            URLQueryItem(name: "apikey", value: "demo")
        ]

        guard let url = components.url else { return [] }
        let data = try await requestData(from: url)
        let response = try JSONDecoder().decode(AlphaVantageSearchResponse.self, from: data)

        return (response.bestMatches ?? []).compactMap { match in
            guard let symbol = match.symbol?.trimmingCharacters(in: .whitespacesAndNewlines),
                  let name = match.name?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !symbol.isEmpty,
                  !name.isEmpty else { return nil }

            let type = match.type?.uppercased() ?? ""
            if !type.isEmpty, !["EQUITY", "ETF"].contains(type) {
                return nil
            }

            return AssetSearchResult(type: .stock, name: name, symbol: symbol.uppercased(), canonicalSymbol: canonicalAssetSymbol(type: .stock, symbol: symbol), source: match.region ?? "Alpha Vantage")
        }
    }

    private func searchCoinbaseCryptoAssets(query: String) async throws -> [AssetSearchResult] {
        let normalizedQuery = normalizedSearchText(query)
        guard !normalizedQuery.isEmpty else { return [] }

        let url = URL(string: "https://api.exchange.coinbase.com/products")!
        let data = try await requestData(from: url)
        let products = try JSONDecoder().decode([CoinbaseProduct].self, from: data)
        let quotePriority = ["USDT": 0, "USD": 1, "USDC": 2]

        let matches = products.compactMap { product -> (AssetSearchResult, Int)? in
            let base = product.baseCurrency.uppercased()
            let quote = product.quoteCurrency.uppercased()
            guard let priority = quotePriority[quote], !base.isEmpty else { return nil }

            let aliases = cryptoAliases(for: base)
            let searchFields = [product.id, base, product.displayName ?? ""] + aliases
            let isMatch = searchFields
                .map(normalizedSearchText)
                .contains { searchFieldMatches($0, query: normalizedQuery) }
            guard isMatch else { return nil }

            let symbol = "\(base)\(quote)"
            let result = AssetSearchResult(
                type: .crypto,
                name: cryptoDisplayName(for: base),
                symbol: symbol,
                canonicalSymbol: "CRYPTO:\(base)",
                source: "Coinbase"
            )
            return (result, priority)
        }
        .sorted { lhs, rhs in
            if lhs.1 != rhs.1 {
                return lhs.1 < rhs.1
            }
            return lhs.0.symbol < rhs.0.symbol
        }

        var seenBases: Set<String> = []
        var output: [AssetSearchResult] = []
        for match in matches {
            let base = cryptoBaseSymbol(from: match.0.symbol)
            guard !seenBases.contains(base) else { continue }
            seenBases.insert(base)
            output.append(match.0)
        }
        return output
    }

    private func uniqueAssetSearchResults(_ results: [AssetSearchResult]) -> [AssetSearchResult] {
        var seen: Set<String> = []
        var output: [AssetSearchResult] = []
        for result in results {
            let id = result.id.uppercased()
            guard !seen.contains(id) else { continue }
            seen.insert(id)
            output.append(result)
        }
        return output
    }

    private func rankAssetSearchResults(_ results: [AssetSearchResult], query: String) -> [AssetSearchResult] {
        let normalizedQuery = normalizedSearchText(query)
        return results.sorted { lhs, rhs in
            let leftScore = searchScore(for: lhs, query: normalizedQuery)
            let rightScore = searchScore(for: rhs, query: normalizedQuery)
            if leftScore != rightScore {
                return leftScore < rightScore
            }
            if lhs.type != rhs.type {
                return lhs.type == .crypto
            }
            return lhs.symbol < rhs.symbol
        }
    }

    private func normalizedSearchText(_ text: String) -> String {
        text
            .folding(options: [.diacriticInsensitive, .caseInsensitive, .widthInsensitive], locale: .current)
            .lowercased()
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "_", with: "")
            .replacingOccurrences(of: "/", with: "")
            .replacingOccurrences(of: ".", with: "")
    }

    private func searchFieldMatches(_ field: String, query: String) -> Bool {
        guard !field.isEmpty, !query.isEmpty else { return false }
        if field == query || field.hasPrefix(query) {
            return true
        }
        if query.count >= 2, field.contains(query) {
            return true
        }
        if query.count >= 3, query.contains(field) {
            return true
        }
        return false
    }

    private func searchScore(for result: AssetSearchResult, query: String) -> Int {
        let fields = searchFields(for: result).map(normalizedSearchText)
        if fields.contains(query) {
            return 0
        }
        if fields.contains(where: { $0.hasPrefix(query) }) {
            return 10
        }
        if fields.contains(where: { $0.contains(query) }) {
            return 20
        }
        return 100
    }

    private func searchFields(for result: AssetSearchResult) -> [String] {
        var fields = [result.symbol, result.name, result.source]
        if result.type == .crypto {
            fields += cryptoAliases(for: cryptoBaseSymbol(from: result.symbol))
        }
        return fields
    }

    private func cryptoAliases(for base: String) -> [String] {
        [
            "BTC": ["Bitcoin", "比特币", "bitebi"],
            "ETH": ["Ethereum", "以太坊", "yitaifang"],
            "SOL": ["Solana"],
            "DOGE": ["Dogecoin", "狗狗币", "gougoubi"],
            "XRP": ["Ripple", "ruibo"],
            "ADA": ["Cardano"],
            "AVAX": ["Avalanche"],
            "DOT": ["Polkadot", "bodian"],
            "LINK": ["Chainlink"],
            "LTC": ["Litecoin", "莱特币", "laitebi"],
            "BCH": ["Bitcoin Cash", "bitekexianjin"],
            "UNI": ["Uniswap"],
            "AAVE": ["Aave"],
            "MATIC": ["Polygon"],
            "SHIB": ["Shiba Inu", "shib"],
        ][base.uppercased()] ?? []
    }

    private func cryptoDisplayName(for base: String) -> String {
        base.uppercased()
    }

    private func cryptoBaseSymbol(from symbol: String) -> String {
        let uppercased = symbol.uppercased()
        for quote in ["USDT", "USDC", "USD"] {
            if uppercased.hasSuffix(quote) {
                return String(uppercased.dropLast(quote.count))
            }
        }
        return uppercased
    }

    func fetchStockChart(_ asset: TrackedAsset, dataSource: StockDataSource, period: StockChartPeriod) async throws -> [StockChartPoint] {
        guard asset.type == .stock, period != .off else { return [] }
        switch dataSource {
        case .eastMoney:
            return try await fetchEastMoneyStockChart(asset, period: period)
        case .yahooFinance:
            return try await fetchYahooStockChart(asset, period: period)
        case .tencent:
            throw NSError(domain: "CareAssets.TencentChart", code: 1)
        }
    }

    private func fetchEastMoneyStockChart(_ asset: TrackedAsset, period: StockChartPeriod) async throws -> [StockChartPoint] {
        guard let secID = eastMoneySecID(for: asset) else {
            throw NSError(domain: "CareAssets.EastMoneyChart", code: 1)
        }

        if period == .day {
            var components = URLComponents(string: "https://push2his.eastmoney.com/api/qt/stock/trends2/get")!
            components.queryItems = [
                URLQueryItem(name: "secid", value: secID),
                URLQueryItem(name: "fields1", value: "f1,f2,f3,f4,f5,f6,f7,f8"),
                URLQueryItem(name: "fields2", value: "f51,f52,f53,f54,f55,f56,f57,f58"),
                URLQueryItem(name: "ndays", value: "1"),
                URLQueryItem(name: "iscr", value: "0")
            ]
            guard let url = components.url else { throw NSError(domain: "CareAssets.EastMoneyChart", code: 2) }
            let data = try await requestData(from: url)
            let response = try JSONDecoder().decode(EastMoneyChartResponse.self, from: data)
            let points = (response.data?.trends ?? []).compactMap(parseEastMoneyChartPoint)
            guard points.count > 1 else { throw NSError(domain: "CareAssets.EastMoneyChart", code: 3) }
            return points
        }

        let end = Date()
        let start = Calendar(identifier: .gregorian).date(byAdding: .day, value: -(period.eastMoneyLookbackDays ?? 400), to: end) ?? end
        var components = URLComponents(string: "https://push2his.eastmoney.com/api/qt/stock/kline/get")!
        components.queryItems = [
            URLQueryItem(name: "secid", value: secID),
            URLQueryItem(name: "fields1", value: "f1,f2,f3,f4,f5,f6"),
            URLQueryItem(name: "fields2", value: "f51,f52,f53,f54,f55,f56"),
            URLQueryItem(name: "klt", value: "101"),
            URLQueryItem(name: "fqt", value: "1"),
            URLQueryItem(name: "beg", value: eastMoneyDateString(start)),
            URLQueryItem(name: "end", value: eastMoneyDateString(end)),
            URLQueryItem(name: "lmt", value: "500")
        ]
        guard let url = components.url else { throw NSError(domain: "CareAssets.EastMoneyChart", code: 4) }
        let data = try await requestData(from: url)
        let response = try JSONDecoder().decode(EastMoneyChartResponse.self, from: data)
        let decodedPoints = (response.data?.klines ?? []).compactMap(parseEastMoneyChartPoint)
        let points = period.eastMoneyPointLimit.map { Array(decodedPoints.suffix($0)) } ?? decodedPoints
        guard points.count > 1 else { throw NSError(domain: "CareAssets.EastMoneyChart", code: 5) }
        return points
    }

    private func fetchYahooStockChart(_ asset: TrackedAsset, period: StockChartPeriod) async throws -> [StockChartPoint] {
        guard let rangeAndInterval = period.yahooRangeAndInterval else { return [] }
        let symbol = yahooStockSymbol(for: asset)
        let encodedSymbol = symbol.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? symbol
        let paths = [
            "https://query2.finance.yahoo.com/v8/finance/chart/\(encodedSymbol)?range=\(rangeAndInterval.range)&interval=\(rangeAndInterval.interval)",
            "https://query1.finance.yahoo.com/v8/finance/chart/\(encodedSymbol)?range=\(rangeAndInterval.range)&interval=\(rangeAndInterval.interval)"
        ]
        var lastError: Error?
        for path in paths {
            do {
                let data = try await requestData(from: URL(string: path)!)
                let response = try JSONDecoder().decode(YahooChartResponse.self, from: data)
                guard let result = response.chart.result?.first,
                      let timestamps = result.timestamp,
                      let closes = result.indicators?.quote?.first?.close else {
                    throw NSError(domain: "CareAssets.YahooChart", code: 1)
                }
                let points: [StockChartPoint] = zip(timestamps, closes).compactMap { pair in
                    let (timestamp, close) = pair
                    guard let close, close.isFinite, close > 0 else { return nil }
                    return StockChartPoint(date: Date(timeIntervalSince1970: TimeInterval(timestamp)), price: close)
                }
                guard points.count > 1 else { throw NSError(domain: "CareAssets.YahooChart", code: 2) }
                return points
            } catch {
                lastError = error
            }
        }
        throw lastError ?? NSError(domain: "CareAssets.YahooChart", code: 3)
    }

    private func parseEastMoneyChartPoint(_ raw: String) -> StockChartPoint? {
        let fields = raw.split(separator: ",", omittingEmptySubsequences: false).map(String.init)
        guard fields.count >= 3,
              let date = parseChartDate(fields[0]),
              let price = Double(fields[2]),
              price.isFinite, price > 0 else { return nil }
        return StockChartPoint(date: date, price: price)
    }

    private func fetchStockQuote(_ asset: TrackedAsset, dataSource: StockDataSource) async throws -> RawStockQuote {
        switch dataSource {
        case .eastMoney:
            return try await fetchEastMoneyStockQuote(asset)
        case .tencent:
            return try await fetchTencentStockQuote(asset)
        case .yahooFinance:
            return try await fetchYahooStockQuote(asset)
        }
    }

    private func fetchEastMoneyStockQuote(_ asset: TrackedAsset) async throws -> RawStockQuote {
        guard let secID = eastMoneySecID(for: asset) else {
            throw NSError(domain: "CareAssets.EastMoney", code: 1)
        }

        let quoteHosts: [(host: String, timeoutInterval: TimeInterval)] = [
            ("push2.eastmoney.com", 3),
            ("push2delay.eastmoney.com", 12)
        ]
        var firstError: Error?

        for quoteHost in quoteHosts {
            do {
                var components = URLComponents(string: "https://\(quoteHost.host)/api/qt/ulist.np/get")!
                components.queryItems = [
                    URLQueryItem(name: "secids", value: secID),
                    URLQueryItem(name: "fields", value: "f12,f13,f14,f2,f18,f124,f152")
                ]
                guard let url = components.url else {
                    throw NSError(domain: "CareAssets.EastMoney", code: 2)
                }

                let data = try await requestData(from: url, timeoutInterval: quoteHost.timeoutInterval)
                let response = try JSONDecoder().decode(EastMoneyQuoteResponse.self, from: data)
                guard let item = response.data?.diff?.first,
                      let rawPrice = item.price,
                      let rawPreviousClose = item.previousClose,
                      rawPrice > 0 else {
                    throw NSError(domain: "CareAssets.EastMoney", code: 3)
                }

                let scale = eastMoneyPriceScale(for: item)
                let price = rawPrice / scale
                let previousClose = rawPreviousClose / scale
                let currency = stockCurrency(for: asset)

                return RawStockQuote(
                    asset: asset,
                    price: price,
                    previousClose: previousClose,
                    currency: currency,
                    displayName: item.name?.isEmpty == false ? item.name! : asset.name,
                    source: "东方财富行情",
                    updatedAt: item.updatedAt.map { Date(timeIntervalSince1970: TimeInterval($0)) }
                )
            } catch {
                if firstError == nil {
                    firstError = error
                }
            }
        }

        throw firstError ?? NSError(domain: "CareAssets.EastMoney", code: 4)
    }

    private func fetchYahooStockQuote(_ asset: TrackedAsset) async throws -> RawStockQuote {
        let yahooSymbol = yahooStockSymbol(for: asset)
        let encodedSymbol = yahooSymbol.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? yahooSymbol
        let url = URL(string: "https://query1.finance.yahoo.com/v8/finance/chart/\(encodedSymbol)?range=5d&interval=1d")!
        let data = try await requestData(from: url)
        let response = try JSONDecoder().decode(YahooChartResponse.self, from: data)

        guard let meta = response.chart.result?.first?.meta,
              let price = meta.regularMarketPrice,
              let currency = meta.currency else {
            throw NSError(domain: "CareAssets.Stock", code: 1)
        }

        return RawStockQuote(
            asset: asset,
            price: price,
            previousClose: meta.chartPreviousClose,
            currency: currency.uppercased(),
            displayName: meta.shortName ?? meta.longName ?? asset.name,
            source: "Yahoo Finance",
            updatedAt: meta.regularMarketTime.map { Date(timeIntervalSince1970: TimeInterval($0)) }
        )
    }

    private func fetchTencentStockQuote(_ asset: TrackedAsset) async throws -> RawStockQuote {
        guard let symbol = tencentStockSymbol(for: asset) else {
            throw NSError(domain: "CareAssets.Tencent", code: 1)
        }

        let url = URL(string: "https://qt.gtimg.cn/q=\(symbol)")!
        let data = try await requestData(from: url)
        let responseText = try decodeGB18030(data)
        let fields = try parseTencentQuoteFields(responseText)

        guard fields.count > 32,
              let price = Double(fields[3]),
              price > 0 else {
            throw NSError(domain: "CareAssets.Tencent", code: 2)
        }

        let previousClose = Double(fields[4])
        let currency = stockCurrency(for: asset)

        return RawStockQuote(
            asset: asset,
            price: price,
            previousClose: previousClose,
            currency: currency,
            displayName: fields[safe: 1]?.isEmpty == false ? fields[1] : asset.name,
            source: "腾讯行情",
            updatedAt: parseTencentDate(fields[safe: 30])
        )
    }

    private func parseTencentQuoteFields(_ text: String) throws -> [String] {
        guard let firstQuote = text.firstIndex(of: "\""),
              let lastQuote = text.lastIndex(of: "\""),
              firstQuote < lastQuote else {
            throw NSError(domain: "CareAssets.Tencent", code: 3)
        }
        return String(text[text.index(after: firstQuote)..<lastQuote]).components(separatedBy: "~")
    }

    private func decodeGB18030(_ data: Data) throws -> String {
        let encoding = String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(CFStringEncodings.GB_18030_2000.rawValue)))
        if let text = String(data: data, encoding: encoding) {
            return text
        }
        if let text = String(data: data, encoding: .utf8) {
            return text
        }
        throw NSError(domain: "CareAssets.Encoding", code: 1)
    }

    private func fetchFXRate(from sourceCurrency: String, to targetCurrency: String) async throws -> Double {
        try await fetchFXQuote(from: sourceCurrency, to: targetCurrency).rate
    }

    private func fetchFXQuote(from sourceCurrency: String, to targetCurrency: String) async throws -> FXQuote {
        let symbol = "\(sourceCurrency.uppercased())\(targetCurrency.uppercased())=X"
        let encodedSymbol = symbol.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? symbol
        let url = URL(string: "https://query1.finance.yahoo.com/v8/finance/chart/\(encodedSymbol)?range=5d&interval=1d")!
        let data = try await requestData(from: url)
        let response = try JSONDecoder().decode(YahooChartResponse.self, from: data)

        guard let meta = response.chart.result?.first?.meta,
              let price = meta.regularMarketPrice else {
            throw NSError(domain: "CareAssets.FX", code: 1)
        }
        return FXQuote(
            rate: price,
            previousClose: meta.chartPreviousClose,
            updatedAt: meta.regularMarketTime.map { Date(timeIntervalSince1970: TimeInterval($0)) }
        )
    }
}

// MARK: - UI

final class StatusTickerView: NSView {
    var items: [DisplayAsset] = [] {
        didSet {
            needsDisplay = true
        }
    }

    var colorMode: PriceColorMode = .white {
        didSet {
            needsDisplay = true
        }
    }

    var backgroundMode: StatusBarBackgroundMode = .dark {
        didSet {
            needsDisplay = true
        }
    }

    var onClick: (() -> Void)?
    var loadingFrame = 0 {
        didSet {
            needsDisplay = true
        }
    }
    private let cellWidth: CGFloat = 48

    var preferredWidth: CGFloat {
        max(28, CGFloat(items.count) * cellWidth)
    }

    override var intrinsicContentSize: NSSize {
        NSSize(width: preferredWidth, height: NSStatusBar.system.thickness)
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        drawTicker(in: bounds)
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        needsDisplay = true
    }

    func renderedImage() -> NSImage {
        let size = NSSize(width: preferredWidth, height: NSStatusBar.system.thickness)
        let image = NSImage(size: size)
        image.lockFocus()
        NSGraphicsContext.current?.imageInterpolation = .high
        drawTicker(in: NSRect(origin: .zero, size: size))
        image.unlockFocus()
        image.isTemplate = false
        return image
    }

    private func drawTicker(in bounds: NSRect) {
        guard !items.isEmpty else {
            drawEmptyTicker(in: bounds)
            return
        }

        let center = NSMutableParagraphStyle()
        center.alignment = .center

        let titleHeight: CGFloat = 10
        let valueHeight: CGFloat = 13
        let titleY = max(0, bounds.height - titleHeight - 0.5)
        let valueY = max(0, titleY - valueHeight + 2)

        for (index, item) in items.enumerated() {
            let cellX = CGFloat(index) * cellWidth
            let rect = NSRect(x: cellX - 2, y: 0, width: cellWidth + 4, height: bounds.height)

            drawStatusText(
                titleText(for: item),
                baseFont: appFont(ofSize: 7, weight: .regular),
                asciiFont: senFont(ofSize: 7),
                color: statusTitleColor(alpha: 0.86),
                paragraphStyle: center,
                in: NSRect(x: rect.minX, y: titleY, width: rect.width, height: titleHeight)
            )
            drawStatusText(
                valueText(for: item),
                baseFont: appFont(ofSize: 11.5, weight: .regular),
                asciiFont: senFont(ofSize: 11.5),
                color: valueColor(for: item),
                paragraphStyle: center,
                in: NSRect(x: rect.minX, y: valueY, width: rect.width, height: valueHeight)
            )
        }
    }

    private func drawEmptyTicker(in bounds: NSRect) {
        let center = NSMutableParagraphStyle()
        center.alignment = .center

        drawStatusText(
            "CA",
            baseFont: appFont(ofSize: 11.5, weight: .semibold),
            asciiFont: senFont(ofSize: 11.5),
            color: NSColor(calibratedRed: 0.22, green: 0.55, blue: 1.0, alpha: 0.95),
            paragraphStyle: center,
            in: NSRect(x: 0, y: max(0, (bounds.height - 13) / 2), width: bounds.width, height: 13)
        )
    }

    override func mouseDown(with event: NSEvent) {
        onClick?()
    }

    private func valueText(for item: DisplayAsset) -> String {
        if item.menuPriceText == "--" {
            return loadingTickerText()
        }
        guard let arrow = directionArrow(for: item) else {
            return item.menuPriceText
        }
        return "\(arrow)\(item.menuPriceText)"
    }

    private func loadingTickerText() -> String {
        "load" + String(repeating: ".", count: loadingFrame % 3 + 1)
    }

    private func titleText(for item: DisplayAsset) -> String {
        if item.type == .gold, item.symbol == "JD_GOLD" {
            return L10n.gold
        }
        return item.name
    }

    private func valueColor(for item: DisplayAsset) -> NSColor {
        if item.errorMessage != nil {
            return statusTextColor(alpha: 0.58)
        }

        guard let percent = item.changePercent, percent != 0 else {
            return statusTextColor(alpha: 0.94)
        }

        switch colorMode {
        case .white:
            return statusTextColor(alpha: 0.94)
        case .redRiseGreenFall:
            return percent > 0 ? statusRed : statusGreen
        case .redFallGreenRise:
            return percent > 0 ? statusGreen : statusRed
        }
    }

    private func directionArrow(for item: DisplayAsset) -> String? {
        guard item.errorMessage == nil, let percent = item.changePercent else {
            return nil
        }
        if percent > 0 {
            return "↑"
        }
        if percent < 0 {
            return "↓"
        }
        return nil
    }

    private var statusGreen: NSColor {
        if backgroundMode == .light {
            return NSColor(calibratedRed: 0.00, green: 0.58, blue: 0.22, alpha: 1)
        }
        return NSColor(calibratedRed: 0.28, green: 0.88, blue: 0.45, alpha: 1)
    }

    private var statusRed: NSColor {
        if backgroundMode == .light {
            return NSColor(calibratedRed: 0.84, green: 0.06, blue: 0.10, alpha: 1)
        }
        return NSColor(calibratedRed: 1.0, green: 0.27, blue: 0.32, alpha: 1)
    }

    private func statusTitleColor(alpha: CGFloat) -> NSColor {
        switch backgroundMode {
        case .dark:
            return NSColor.white.withAlphaComponent(alpha)
        case .light:
            return NSColor.black.withAlphaComponent(alpha)
        case .blue:
            return NSColor(calibratedRed: 0.22, green: 0.55, blue: 1.0, alpha: alpha)
        case .yellow:
            return NSColor(calibratedRed: 1.0, green: 0.78, blue: 0.18, alpha: alpha)
        case .purple:
            return NSColor(calibratedRed: 0.72, green: 0.44, blue: 1.0, alpha: alpha)
        }
    }

    private func statusTextColor(alpha: CGFloat) -> NSColor {
        if backgroundMode == .light {
            return NSColor.black.withAlphaComponent(alpha)
        }
        return NSColor.white.withAlphaComponent(alpha)
    }

    private func statusTextShadow(for color: NSColor) -> NSShadow {
        let shadow = NSShadow()
        let darkFill = perceivedLuminance(of: color) < 0.45
        shadow.shadowBlurRadius = darkFill ? 1.5 : 2
        shadow.shadowOffset = NSSize(width: 0, height: -0.5)
        shadow.shadowColor = darkFill
            ? NSColor.white.withAlphaComponent(0.55)
            : NSColor.black.withAlphaComponent(0.45)
        return shadow
    }

    private func perceivedLuminance(of color: NSColor) -> CGFloat {
        let converted = color.usingColorSpace(.sRGB) ?? color
        return converted.redComponent * 0.299 + converted.greenComponent * 0.587 + converted.blueComponent * 0.114
    }

    private func drawStatusText(
        _ text: String,
        baseFont: NSFont,
        asciiFont: NSFont,
        color: NSColor,
        paragraphStyle: NSParagraphStyle,
        in rect: NSRect
    ) {
        let attributed = NSMutableAttributedString(attributedString: mixedAttributedString(
            text,
            baseFont: baseFont,
            asciiFont: asciiFont,
            color: color,
            paragraphStyle: paragraphStyle
        ))
        attributed.addAttribute(.shadow, value: statusTextShadow(for: color), range: NSRange(location: 0, length: attributed.length))
        attributed.draw(in: rect)
    }
}

final class FlippedDocumentView: NSView {
    override var isFlipped: Bool {
        true
    }
}

extension NSPasteboard.PasteboardType {
    static let careAssetsAssetID = NSPasteboard.PasteboardType("com.careassets.asset-id")
}

final class ReorderHandleView: NSView {
    override var intrinsicContentSize: NSSize { NSSize(width: 12, height: 18) }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        NSColor.white.withAlphaComponent(0.62).setFill()
        let diameter: CGFloat = 2.5
        for xOffset in [-2.5, 2.5] as [CGFloat] {
            for yOffset in [-4, 0, 4] as [CGFloat] {
                let rect = NSRect(x: bounds.midX + xOffset - diameter / 2, y: bounds.midY + yOffset - diameter / 2, width: diameter, height: diameter)
                NSBezierPath(ovalIn: rect).fill()
            }
        }
    }

    override func resetCursorRects() { addCursorRect(bounds, cursor: .openHand) }
}

final class AssetReorderRowView: NSStackView, NSDraggingSource {
    let assetID: String
    var onClick: (() -> Void)?
    var allowsReordering = true {
        didSet {
            if !allowsReordering {
                mouseDownEvent = nil
                didBeginDrag = false
                clearDropIndicator()
            }
        }
    }
    var onMoveAsset: ((String, String, Bool) -> Void)?

    private enum DropIndicatorPosition {
        case top
        case bottom
    }

    private var mouseDownEvent: NSEvent?
    private var didBeginDrag = false
    private var dropIndicatorPosition: DropIndicatorPosition? {
        didSet {
            needsDisplay = true
        }
    }

    init(assetID: String) {
        self.assetID = assetID
        super.init(frame: .zero)
        registerForDraggedTypes([.careAssetsAssetID])
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        guard let dropIndicatorPosition else { return }

        let lineHeight: CGFloat = 2
        let y = dropIndicatorPosition == .top ? bounds.maxY - lineHeight : bounds.minY
        let rect = NSRect(x: 0, y: y, width: bounds.width, height: lineHeight)
        NSColor(calibratedRed: 0.45, green: 0.63, blue: 1.0, alpha: 0.95).setFill()
        NSBezierPath(roundedRect: rect, xRadius: 1, yRadius: 1).fill()
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        guard let hit = super.hitTest(point) else { return nil }
        return isButtonHit(hit) ? hit : self
    }

    override func mouseDown(with event: NSEvent) {
        mouseDownEvent = event
        didBeginDrag = false
    }

    override func mouseDragged(with event: NSEvent) {
        guard !didBeginDrag else { return }
        guard let mouseDownEvent else { return }

        let dx = event.locationInWindow.x - mouseDownEvent.locationInWindow.x
        let dy = event.locationInWindow.y - mouseDownEvent.locationInWindow.y
        guard hypot(dx, dy) > 4 else { return }

        guard allowsReordering else {
            didBeginDrag = true
            return
        }

        didBeginDrag = true
        let pasteboardItem = NSPasteboardItem()
        pasteboardItem.setString(assetID, forType: .careAssetsAssetID)

        let draggingItem = NSDraggingItem(pasteboardWriter: pasteboardItem)
        draggingItem.setDraggingFrame(bounds, contents: draggingImage())
        beginDraggingSession(with: [draggingItem], event: mouseDownEvent, source: self)
    }

    override func mouseUp(with event: NSEvent) {
        if !allowsReordering, !didBeginDrag {
            onClick?()
        }
        mouseDownEvent = nil
        didBeginDrag = false
    }

    override func resetCursorRects() {
        if !allowsReordering, onClick != nil {
            addCursorRect(bounds, cursor: .pointingHand)
        }
    }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        guard allowsReordering else { return [] }
        guard draggingSourceID(from: sender) != nil else { return [] }
        updateDropIndicator(sender)
        return .move
    }

    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        guard allowsReordering else {
            clearDropIndicator()
            return []
        }
        guard draggingSourceID(from: sender) != nil else {
            clearDropIndicator()
            return []
        }
        updateDropIndicator(sender)
        return .move
    }

    override func draggingExited(_ sender: NSDraggingInfo?) {
        clearDropIndicator()
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        defer { clearDropIndicator() }
        guard allowsReordering else { return false }
        guard let sourceID = draggingSourceID(from: sender), sourceID != assetID else {
            return false
        }

        let location = convert(sender.draggingLocation, from: nil)
        let placeAfterTarget = location.y < bounds.midY
        onMoveAsset?(sourceID, assetID, placeAfterTarget)
        return true
    }

    func draggingSession(_ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation {
        .move
    }

    func ignoreModifierKeys(for session: NSDraggingSession) -> Bool {
        true
    }

    private func isButtonHit(_ hit: NSView) -> Bool {
        var node: NSView? = hit
        while let current = node, current !== self {
            if current is NSButton {
                return true
            }
            node = current.superview
        }
        return false
    }

    private func draggingSourceID(from sender: NSDraggingInfo) -> String? {
        sender.draggingPasteboard.string(forType: .careAssetsAssetID)
    }

    private func draggingImage() -> NSImage {
        let image = NSImage(size: bounds.size)
        guard let representation = bitmapImageRepForCachingDisplay(in: bounds) else {
            return image
        }
        cacheDisplay(in: bounds, to: representation)
        image.addRepresentation(representation)
        return image
    }

    private func updateDropIndicator(_ sender: NSDraggingInfo) {
        let location = convert(sender.draggingLocation, from: nil)
        dropIndicatorPosition = location.y < bounds.midY ? .bottom : .top
    }

    private func clearDropIndicator() {
        dropIndicatorPosition = nil
    }
}

final class ClickableSearchResultRowView: NSStackView {
    var onClick: (() -> Void)?
    private var mouseDownEvent: NSEvent?
    private var didDrag = false

    override func hitTest(_ point: NSPoint) -> NSView? {
        super.hitTest(point) == nil ? nil : self
    }

    override func mouseDown(with event: NSEvent) {
        mouseDownEvent = event
        didDrag = false
    }

    override func mouseDragged(with event: NSEvent) {
        guard let mouseDownEvent else { return }
        let dx = event.locationInWindow.x - mouseDownEvent.locationInWindow.x
        let dy = event.locationInWindow.y - mouseDownEvent.locationInWindow.y
        if hypot(dx, dy) > 4 {
            didDrag = true
        }
    }

    override func mouseUp(with event: NSEvent) {
        if !didDrag {
            onClick?()
        }
        mouseDownEvent = nil
        didDrag = false
    }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .pointingHand)
    }
}

final class StockChartView: NSView {
    var points: [StockChartPoint] = [] {
        didSet { needsDisplay = true }
    }
    var colorMode: PriceColorMode = .redFallGreenRise {
        didSet { needsDisplay = true }
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        let background = NSBezierPath(roundedRect: bounds, xRadius: 8, yRadius: 8)
        NSColor.white.withAlphaComponent(0.035).setFill()
        background.fill()

        guard points.count > 1 else { return }
        let prices = points.map(\.price)
        guard let minimum = prices.min(), let maximum = prices.max() else { return }

        let insetBounds = bounds.insetBy(dx: 10, dy: 10)
        let priceRange = maximum - minimum
        let path = NSBezierPath()
        path.lineWidth = 1.6
        path.lineJoinStyle = .round
        path.lineCapStyle = .round

        for (index, point) in points.enumerated() {
            let progress = CGFloat(index) / CGFloat(points.count - 1)
            let normalizedPrice = priceRange > 0
                ? CGFloat((point.price - minimum) / priceRange)
                : 0.5
            let location = NSPoint(
                x: insetBounds.minX + progress * insetBounds.width,
                y: insetBounds.minY + normalizedPrice * insetBounds.height
            )
            if index == 0 {
                path.move(to: location)
            } else {
                path.line(to: location)
            }
        }

        chartColor.setStroke()
        path.stroke()
    }

    private var chartColor: NSColor {
        guard let first = points.first?.price, let last = points.last?.price else {
            return NSColor.white.withAlphaComponent(0.75)
        }
        let change = last - first
        switch colorMode {
        case .white:
            return NSColor.white.withAlphaComponent(0.88)
        case .redRiseGreenFall:
            return change >= 0
                ? NSColor(calibratedRed: 1.0, green: 0.34, blue: 0.40, alpha: 0.95)
                : NSColor(calibratedRed: 0.25, green: 0.88, blue: 0.56, alpha: 0.95)
        case .redFallGreenRise:
            return change >= 0
                ? NSColor(calibratedRed: 0.25, green: 0.88, blue: 0.56, alpha: 0.95)
                : NSColor(calibratedRed: 1.0, green: 0.34, blue: 0.40, alpha: 0.95)
        }
    }
}

final class SearchResultActionButton: NSButton {
    var isTracked = false {
        didSet {
            needsDisplay = true
        }
    }

    override var intrinsicContentSize: NSSize {
        NSSize(width: 18, height: 18)
    }

    override func draw(_ dirtyRect: NSRect) {
        let rect = bounds.insetBy(dx: 1, dy: 1)
        let path = NSBezierPath(roundedRect: rect, xRadius: 3, yRadius: 3)

        if isTracked {
            NSColor(calibratedRed: 0.09, green: 0.86, blue: 0.36, alpha: 1).setFill()
            path.fill()
        } else {
            NSColor.white.withAlphaComponent(0.14).setFill()
            path.fill()
            NSColor.white.withAlphaComponent(0.28).setStroke()
            path.lineWidth = 1
            path.stroke()
        }

        let title = isTracked ? "✓" : "+"
        let color = isTracked ? NSColor.white : NSColor.white.withAlphaComponent(0.88)
        let font = senFont(ofSize: isTracked ? 12 : 11)
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: paragraph
        ]
        let size = title.size(withAttributes: attributes)
        let textRect = NSRect(
            x: bounds.midX - size.width / 2,
            y: bounds.midY - size.height / 2 - 0.5,
            width: size.width,
            height: size.height
        )
        title.draw(in: textRect, withAttributes: attributes)
    }
}

final class AssetPanelViewController: NSViewController, NSTextFieldDelegate {
    private struct ScrollPosition {
        var y: CGFloat = 0
        var pinnedToBottom = false
    }

    private enum SearchListItem {
        case group(title: String, count: Int, accentColor: NSColor)
        case result(AssetSearchResult)
    }

    var onSearchStocks: ((String) -> Void)?
    var onAddStock: ((AssetSearchResult) -> Void)?
    var onToggleVisible: ((String, Bool) -> Void)?
    var onRemoveAsset: ((String) -> Void)?
    var onMoveAsset: ((String, String, Bool) -> Void)?
    var onEditPosition: ((String) -> Void)?
    var onColorModeChange: ((PriceColorMode) -> Void)?
    var onStatusBarBackgroundModeChange: ((StatusBarBackgroundMode) -> Void)?
    var onStockDataSourceChange: ((StockDataSource) -> Void)?
    var onStockChartPeriodChange: ((StockChartPeriod) -> Void)?
    var onRequestStockChart: ((String) -> Void)?
    var onLanguageChange: ((AppLanguage) -> Void)?
    var onPreferredContentSizeChange: ((NSSize) -> Void)?
    var onQuit: (() -> Void)?

    private var assets: [DisplayAsset] = []
    private var countdown: Int = 0
    private var isRefreshing = false
    private var colorMode: PriceColorMode = .white
    private var statusBarBackgroundMode: StatusBarBackgroundMode = .dark
    private var stockDataSource: StockDataSource = .tencent
    private var stockChartPeriod: StockChartPeriod = .day
    private var expandedAssetID: String?
    private var stockChartStates: [String: StockChartState] = [:]
    private var language: AppLanguage = .system
    private var isSearchOpen = false
    private var isEditingAssets = false
    private var isSearching = false
    private var searchQuery = ""
    private var searchResults: [AssetSearchResult] = []
    private var searchMessage: String?
    private weak var searchField: NSTextField?
    private weak var refreshStateLabel: NSTextField?
    private weak var toastView: NSView?
    private weak var assetScrollView: NSScrollView?
    private weak var searchScrollView: NSScrollView?
    private var assetScrollPosition = ScrollPosition()
    private var searchScrollPosition = ScrollPosition()
    private var toastWorkItem: DispatchWorkItem?
    private var shouldFocusSearchField = false
    private var searchModeListHeight: CGFloat?
    private let panelWidth: CGFloat = 430
    private var contentWidth: CGFloat { panelWidth - 36 }
    private var scrollWidth: CGFloat { isRTL ? contentWidth : contentWidth + horizontalInset }
    private let assetRowHeight: CGFloat = 52
    private let stockChartHeight: CGFloat = 104
    private let searchResultRowHeight: CGFloat = 52
    private let searchGroupHeaderHeight: CGFloat = 30
    private let searchGroupGap: CGFloat = 16
    private let searchExpandedMinListHeight: CGFloat = 260
    private let searchExpandedMaxListHeight: CGFloat = 420
    private let listRowGap: CGFloat = 8
    private let headerHeight: CGFloat = 30
    private let headerActionButtonWidth: CGFloat = 58
    private let footerHeight: CGFloat = 30
    private let horizontalInset: CGFloat = 18
    private let topInset: CGFloat = 16
    private let bottomInset: CGFloat = 14
    private let stackSpacing: CGFloat = 10
    private let footerExtraTopSpacing: CGFloat = 6
    private let rtlScrollerGutterWidth: CGFloat = 10
    private let percentTagWidth: CGFloat = 46
    private var rightColumnWidth: CGFloat { isEditingAssets ? 206 : 220 }
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale.autoupdatingCurrent
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter
    }()

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: panelWidth, height: 360))
        view.appearance = NSAppearance(named: .darkAqua)
        view.userInterfaceLayoutDirection = L10n.isRightToLeft ? .rightToLeft : .leftToRight
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor(calibratedRed: 0.10, green: 0.11, blue: 0.13, alpha: 0.98).cgColor
        render()
    }

    func update(assets: [DisplayAsset], countdown: Int, isRefreshing: Bool, colorMode: PriceColorMode, statusBarBackgroundMode: StatusBarBackgroundMode, stockDataSource: StockDataSource, stockChartPeriod: StockChartPeriod, language: AppLanguage) {
        let chartContextChanged = self.stockDataSource != stockDataSource || self.stockChartPeriod != stockChartPeriod
        self.assets = assets
        self.countdown = countdown
        self.isRefreshing = isRefreshing
        self.colorMode = colorMode
        self.statusBarBackgroundMode = statusBarBackgroundMode
        self.stockDataSource = stockDataSource
        self.stockChartPeriod = stockChartPeriod
        self.language = language
        if let expandedAssetID,
           !assets.contains(where: { $0.id == expandedAssetID && $0.type == .stock }) {
            self.expandedAssetID = nil
            stockChartStates.removeValue(forKey: expandedAssetID)
        }
        if stockChartPeriod == .off {
            expandedAssetID = nil
            stockChartStates.removeAll()
        } else if chartContextChanged {
            stockChartStates.removeAll()
            if let expandedAssetID {
                stockChartStates[expandedAssetID] = stockDataSource == .tencent ? .unavailable : .loading
                if stockDataSource != .tencent {
                    DispatchQueue.main.async { [weak self] in
                        self?.onRequestStockChart?(expandedAssetID)
                    }
                }
            }
        }
        if isSearchOpen {
            return
        }
        render()
    }

    func updateStockChart(assetID: String, dataSource: StockDataSource, period: StockChartPeriod, state: StockChartState) {
        guard self.stockDataSource == dataSource, stockChartPeriod == period else { return }
        stockChartStates[assetID] = state
        if expandedAssetID == assetID, !isSearchOpen {
            render()
        }
    }

    func updateSearch(results: [AssetSearchResult], isSearching: Bool, message: String?) {
        self.searchResults = results
        self.isSearching = isSearching
        self.searchMessage = message
        render()
    }

    func updateRefreshState(countdown: Int, isRefreshing: Bool) {
        self.countdown = countdown
        self.isRefreshing = isRefreshing
        updateRefreshStateLabel()
    }

    private func render() {
        guard isViewLoaded else { return }
        captureScrollPositions()
        view.subviews.forEach { $0.removeFromSuperview() }
        view.userInterfaceLayoutDirection = isRTL ? .rightToLeft : .leftToRight

        let preferredSize = NSSize(width: panelWidth, height: preferredPanelHeight)
        preferredContentSize = preferredSize
        view.setFrameSize(preferredSize)
        onPreferredContentSizeChange?(preferredSize)

        let root = NSStackView()
        root.orientation = .vertical
        root.alignment = contentAlignment
        root.spacing = stackSpacing
        root.edgeInsets = NSEdgeInsets(top: topInset, left: horizontalInset, bottom: bottomInset, right: horizontalInset)
        root.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(root)

        NSLayoutConstraint.activate([
            root.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            root.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            root.topAnchor.constraint(equalTo: view.topAnchor),
            root.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        root.addArrangedSubview(makeHeader())

        let listView = isSearchOpen ? makeSearchList() : makeAssetList()
        root.addArrangedSubview(listView)

        if shouldFocusSearchField {
            shouldFocusSearchField = false
            focusSearchFieldIfNeeded()
        }
    }

    private var assetListVisibleRowCount: Int {
        max(1, min(assets.count, 8))
    }

    private var assetListHeight: CGFloat {
        let rows = assetListVisibleRowCount
        let expandedHeight: CGFloat = expandedAssetID == nil ? 0 : stockChartHeight
        return CGFloat(rows) * assetRowHeight + CGFloat(max(rows - 1, 0)) * listRowGap + expandedHeight
    }

    private var currentListHeight: CGFloat {
        if isSearchOpen {
            if hasSearchResults {
                return min(max(searchDocumentHeight, searchExpandedMinListHeight), searchExpandedMaxListHeight)
            }
            return searchModeListHeight ?? assetListHeight
        }
        return assetListHeight
    }

    private var preferredPanelHeight: CGFloat {
        return topInset + headerHeight + stackSpacing + currentListHeight + bottomInset
    }

    private var searchResultRowCount: Int {
        if isSearching || searchMessage != nil || searchResults.isEmpty {
            return 1
        }
        return searchListItems.count
    }

    private var hasSearchResults: Bool {
        !isSearching && searchMessage == nil && !searchResults.isEmpty
    }

    private var searchListItems: [SearchListItem] {
        var groups: [(title: String, accentColor: NSColor, results: [AssetSearchResult])] = []

        for result in searchResults {
            let title = searchGroupTitle(for: result)
            if let index = groups.firstIndex(where: { $0.title == title }) {
                groups[index].results.append(result)
            } else {
                groups.append((title, searchGroupAccentColor(for: result), [result]))
            }
        }

        return groups.flatMap { group in
            [SearchListItem.group(title: group.title, count: group.results.count, accentColor: group.accentColor)]
                + group.results.map(SearchListItem.result)
        }
    }

    private var searchDocumentHeight: CGFloat {
        let items = searchListItems
        guard !items.isEmpty else { return 0 }

        let itemHeight = items.reduce(CGFloat(0)) { total, item in
            total + searchListItemHeight(item)
        }
        let groupBreakCount = items.dropFirst().reduce(0) { count, item in
            if case .group = item {
                return count + 1
            }
            return count
        }
        let defaultGapHeight = CGFloat(max(items.count - 1, 0)) * listRowGap
        let extraGroupGapHeight = CGFloat(groupBreakCount) * (searchGroupGap - listRowGap)
        return itemHeight + defaultGapHeight + extraGroupGapHeight
    }

    private var isRTL: Bool {
        L10n.isRightToLeft
    }

    private var contentAlignment: NSLayoutConstraint.Attribute {
        isRTL ? .centerX : .leading
    }

    private var leadingColumnAlignment: NSLayoutConstraint.Attribute {
        isRTL ? .trailing : .leading
    }

    private var leadingTextAlignment: NSTextAlignment {
        isRTL ? .right : .left
    }

    private var trailingTextAlignment: NSTextAlignment {
        isRTL ? .left : .right
    }

    private func addArrangedSubviews(_ views: [NSView], to stack: NSStackView) {
        for view in isRTL ? views.reversed() : views {
            stack.addArrangedSubview(view)
        }
    }

    private func captureScrollPositions() {
        if let assetScrollView {
            assetScrollPosition = captureScrollPosition(from: assetScrollView)
        }
        if let searchScrollView {
            searchScrollPosition = captureScrollPosition(from: searchScrollView)
        }
    }

    private func captureScrollPosition(from scrollView: NSScrollView) -> ScrollPosition {
        guard let documentView = scrollView.documentView else {
            return ScrollPosition()
        }

        let viewportHeight = scrollView.contentView.bounds.height
        let maxY = max(0, documentView.bounds.height - viewportHeight)
        let currentY = scrollView.contentView.bounds.origin.y
        return ScrollPosition(y: currentY, pinnedToBottom: maxY - currentY <= 2)
    }

    private func restoreScrollPosition(_ position: ScrollPosition, in scrollView: NSScrollView, viewportHeight: CGFloat) {
        applyScrollPosition(position, in: scrollView, viewportHeight: viewportHeight)
        DispatchQueue.main.async { [weak self, weak scrollView] in
            guard let self, let scrollView else { return }
            self.applyScrollPosition(position, in: scrollView, viewportHeight: viewportHeight)
        }
    }

    private func applyScrollPosition(_ position: ScrollPosition, in scrollView: NSScrollView, viewportHeight: CGFloat) {
        guard let documentView = scrollView.documentView else { return }
        scrollView.layoutSubtreeIfNeeded()
        let actualViewportHeight = max(scrollView.contentView.bounds.height, viewportHeight)
        let maxY = max(0, documentView.bounds.height - actualViewportHeight)
        let restoredY = position.pinnedToBottom ? maxY : min(max(position.y, 0), maxY)
        scrollView.contentView.scroll(to: NSPoint(x: 0, y: restoredY))
        scrollView.reflectScrolledClipView(scrollView.contentView)
    }

    private func makeHeader() -> NSView {
        if isSearchOpen {
            return makeSearchHeader()
        }

        let row = NSStackView()
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 8
        row.widthAnchor.constraint(equalToConstant: contentWidth).isActive = true
        row.heightAnchor.constraint(equalToConstant: headerHeight).isActive = true

        let title = makeLabel("CareAssets", font: appFont(ofSize: 18, weight: .bold), color: .white)
        let brand = NSStackView()
        brand.orientation = .horizontal
        brand.alignment = .centerY
        brand.spacing = 7
        brand.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        if let logo = appLogoImage() {
            let logoView = NSImageView(image: logo)
            logoView.imageScaling = .scaleProportionallyUpOrDown
            logoView.wantsLayer = true
            logoView.layer?.cornerRadius = 5
            logoView.layer?.masksToBounds = true
            logoView.widthAnchor.constraint(equalToConstant: 22).isActive = true
            logoView.heightAnchor.constraint(equalToConstant: 22).isActive = true
            addArrangedSubviews([logoView, title], to: brand)
        } else {
            brand.addArrangedSubview(title)
        }
        let spacer = NSView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)

        let refresh = makeLabel(
            L10n.refreshState(isRefreshing: isRefreshing, countdown: countdown),
            font: appFont(ofSize: 11, weight: .semibold),
            color: NSColor.white.withAlphaComponent(0.56),
            alignment: .right
        )
        refresh.widthAnchor.constraint(equalToConstant: 62).isActive = true
        refreshStateLabel = refresh

        let settings = NSButton(title: L10n.settings, target: self, action: #selector(settingsClicked(_:)))
        settings.bezelStyle = .rounded
        settings.controlSize = .small
        settings.font = appFont(ofSize: 12, weight: .semibold)
        settings.widthAnchor.constraint(equalToConstant: headerActionButtonWidth).isActive = true

        let edit = NSButton(title: isEditingAssets ? L10n.doneEditing : L10n.edit, target: self, action: #selector(toggleAssetEditingClicked(_:)))
        edit.bezelStyle = .rounded
        edit.controlSize = .small
        edit.font = appFont(ofSize: 12, weight: .semibold)
        if !isEditingAssets {
            edit.widthAnchor.constraint(equalToConstant: headerActionButtonWidth).isActive = true
        }

        let add = NSButton(title: L10n.add, target: self, action: #selector(toggleSearchClicked(_:)))
        add.bezelStyle = .rounded
        add.controlSize = .small
        add.font = appFont(ofSize: 12, weight: .semibold)
        add.widthAnchor.constraint(equalToConstant: headerActionButtonWidth).isActive = true

        let headerViews = isEditingAssets
            ? [brand, spacer, refresh, edit]
            : [brand, spacer, refresh, settings, edit, add]
        addArrangedSubviews(headerViews, to: row)
        return row
    }

    private func makeAssetList() -> NSView {
        let rowCount = max(assets.count, 1)
        let expandedHeight: CGFloat = expandedAssetID == nil ? 0 : stockChartHeight
        let documentHeight = CGFloat(rowCount) * assetRowHeight + CGFloat(max(rowCount - 1, 0)) * listRowGap + expandedHeight
        let visibleRows = max(1, min(assets.count, 8))
        let listHeight = CGFloat(visibleRows) * assetRowHeight + CGFloat(max(visibleRows - 1, 0)) * listRowGap + expandedHeight

        let scroll = NSScrollView()
        scroll.borderType = .noBorder
        scroll.drawsBackground = false
        scroll.hasVerticalScroller = assets.count > 8
        scroll.autohidesScrollers = true
        scroll.verticalScrollElasticity = .allowed
        scroll.widthAnchor.constraint(equalToConstant: scrollWidth).isActive = true
        scroll.heightAnchor.constraint(equalToConstant: listHeight).isActive = true

        let document = FlippedDocumentView(frame: NSRect(x: 0, y: 0, width: scrollWidth, height: documentHeight))
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = contentAlignment
        stack.spacing = listRowGap
        stack.translatesAutoresizingMaskIntoConstraints = false
        document.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: document.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: document.trailingAnchor),
            stack.topAnchor.constraint(equalTo: document.topAnchor),
            stack.bottomAnchor.constraint(equalTo: document.bottomAnchor)
        ])

        if assets.isEmpty {
            let label = makeMutedLabel(L10n.loadingAssets)
            label.widthAnchor.constraint(equalToConstant: contentWidth).isActive = true
            label.heightAnchor.constraint(equalToConstant: assetRowHeight).isActive = true
            stack.addArrangedSubview(label)
        } else {
            for asset in assets {
                stack.addArrangedSubview(makeAssetItem(asset))
            }
        }

        scroll.documentView = document
        assetScrollView = scroll
        restoreScrollPosition(assetScrollPosition, in: scroll, viewportHeight: listHeight)
        return scroll
    }

    private func makeAssetItem(_ asset: DisplayAsset) -> NSView {
        let item = NSStackView()
        item.orientation = .vertical
        item.alignment = contentAlignment
        item.spacing = 0
        item.widthAnchor.constraint(equalToConstant: contentWidth).isActive = true
        item.addArrangedSubview(makeAssetRow(asset))

        if expandedAssetID == asset.id {
            item.addArrangedSubview(makeStockChartArea(asset))
        }
        return item
    }

    private func makeAssetRow(_ asset: DisplayAsset) -> NSView {
        if !isEditingAssets {
            return makeNormalAssetRow(asset)
        }

        let row = AssetReorderRowView(assetID: asset.id)
        row.allowsReordering = isEditingAssets
        row.onMoveAsset = { [weak self] sourceID, targetID, placeAfterTarget in
            self?.onMoveAsset?(sourceID, targetID, placeAfterTarget)
        }
        if !isEditingAssets, asset.type == .stock, stockChartPeriod != .off {
            row.onClick = { [weak self] in
                self?.toggleStockChart(assetID: asset.id)
            }
        }
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 8
        row.widthAnchor.constraint(equalToConstant: contentWidth).isActive = true
        row.heightAnchor.constraint(equalToConstant: assetRowHeight).isActive = true

        let visible = NSButton(title: "", target: self, action: #selector(toggleVisibleClicked(_:)))
        visible.setButtonType(.switch)
        visible.state = asset.visibleInMenuBar ? .on : .off
        visible.identifier = NSUserInterfaceItemIdentifier(asset.id)
        visible.toolTip = L10n.visibleInMenuBar
        visible.widthAnchor.constraint(equalToConstant: 18).isActive = true

        let left = NSStackView()
        left.orientation = .vertical
        left.alignment = leadingColumnAlignment
        left.spacing = 3
        left.addArrangedSubview(makeLabel(displayName(for: asset), font: appFont(ofSize: 14, weight: .bold), color: .white, alignment: leadingTextAlignment))
        left.addArrangedSubview(makeAssetCodeLine(asset))
        left.widthAnchor.constraint(greaterThanOrEqualToConstant: 88).isActive = true

        let spacer = NSView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)

        let right = NSStackView()
        right.orientation = .vertical
        right.alignment = isRTL ? .leading : .trailing
        right.spacing = 3
        right.widthAnchor.constraint(equalToConstant: rightColumnWidth).isActive = true
        right.addArrangedSubview(makeAssetPriceLine(asset))

        if let message = asset.errorMessage {
            right.addArrangedSubview(makeAssetDetailLabel(asset, percentText: message, dateText: nil, isError: true))
        } else if asset.hasPosition {
            right.addArrangedSubview(makePositionDetailLabel(asset))
        }

        let remove = NSButton(title: "-", target: self, action: #selector(removeAssetClicked(_:)))
        remove.bezelStyle = .smallSquare
        remove.controlSize = .small
        remove.font = senFont(ofSize: 11)
        remove.identifier = NSUserInterfaceItemIdentifier(asset.id)
        remove.toolTip = L10n.remove
        remove.widthAnchor.constraint(equalToConstant: 18).isActive = true

        let position = NSButton(title: "持", target: self, action: #selector(editPositionClicked(_:)))
        position.bezelStyle = .smallSquare
        position.controlSize = .small
        position.font = appFont(ofSize: 10, weight: .semibold)
        position.identifier = NSUserInterfaceItemIdentifier(asset.id)
        position.toolTip = L10n.position
        position.widthAnchor.constraint(equalToConstant: 22).isActive = true
        position.isHidden = asset.type != .stock

        var rowViews: [NSView]
        if isEditingAssets {
            let reorderHandle = makeReorderHandle()
            rowViews = isRTL
                ? [reorderHandle, makeRTLScrollerGutter(), visible, left, spacer, right]
                : [reorderHandle, visible, left, spacer, right]
            if asset.type == .stock {
                rowViews.append(position)
            }
            rowViews.append(remove)
        } else {
            rowViews = isRTL
                ? [makeRTLScrollerGutter(), left, spacer, right]
                : [left, spacer, right]
        }
        addArrangedSubviews(rowViews, to: row)

        return row
    }

    private func makeReorderHandle() -> ReorderHandleView {
        let handle = ReorderHandleView()
        handle.toolTip = L10n.reorder
        handle.setAccessibilityElement(true)
        handle.setAccessibilityRole(.image)
        handle.setAccessibilityLabel(L10n.reorder)
        handle.widthAnchor.constraint(equalToConstant: 12).isActive = true
        handle.heightAnchor.constraint(equalToConstant: 18).isActive = true
        return handle
    }

    private func makeNormalAssetRow(_ asset: DisplayAsset) -> NSView {
        let row = AssetReorderRowView(assetID: asset.id)
        row.allowsReordering = false
        if asset.type == .stock, stockChartPeriod != .off {
            row.onClick = { [weak self] in
                self?.toggleStockChart(assetID: asset.id)
            }
        }
        row.orientation = .vertical
        row.alignment = contentAlignment
        row.spacing = 2
        row.widthAnchor.constraint(equalToConstant: contentWidth).isActive = true
        row.heightAnchor.constraint(equalToConstant: assetRowHeight).isActive = true

        let top = NSStackView()
        top.orientation = .horizontal
        top.alignment = .centerY
        top.spacing = 6
        top.widthAnchor.constraint(equalToConstant: contentWidth).isActive = true

        let name = makeLabel(displayName(for: asset), font: appFont(ofSize: 14, weight: .bold), color: .white, alignment: leadingTextAlignment)
        name.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        let spacer = NSView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        let warning = makeQuoteTimeWarning(asset)
        warning.widthAnchor.constraint(equalToConstant: 12).isActive = true
        let price = makeLabel(asset.priceText, font: appFont(ofSize: 15, weight: .bold), color: valueColor(for: asset), alignment: .right)
        price.setContentCompressionResistancePriority(.required, for: .horizontal)
        let priceTag = makeChangePercentTag(asset)
        addArrangedSubviews([name, spacer, warning, price, priceTag], to: top)

        let bottom = NSStackView()
        bottom.orientation = .horizontal
        bottom.alignment = .centerY
        bottom.spacing = 6
        bottom.widthAnchor.constraint(equalToConstant: contentWidth).isActive = true
        let code = makeAssetCodeLine(asset)
        code.setContentCompressionResistancePriority(.required, for: .horizontal)
        let bottomSpacer = NSView()
        bottomSpacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        var bottomViews: [NSView] = [code, bottomSpacer]

        if asset.errorMessage != nil {
            bottomViews.append(makeAssetDetailLabel(asset, percentText: asset.errorMessage ?? "", dateText: nil, isError: true))
        } else if asset.hasPosition {
            let summary = makePositionSummaryLabel(asset)
            summary.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            bottomViews.append(summary)
            bottomViews.append(makePositionPercentTag(asset))
        }
        addArrangedSubviews(bottomViews, to: bottom)

        row.addArrangedSubview(top)
        row.addArrangedSubview(bottom)
        return row
    }

    private func makeStockChartArea(_ asset: DisplayAsset) -> NSView {
        let container = NSView()
        container.widthAnchor.constraint(equalToConstant: contentWidth).isActive = true
        container.heightAnchor.constraint(equalToConstant: stockChartHeight).isActive = true

        let state = stockChartStates[asset.id] ?? (stockDataSource == .tencent ? .unavailable : .loading)
        let chartContent = NSStackView()
        chartContent.orientation = .vertical
        chartContent.alignment = contentAlignment
        chartContent.spacing = 2
        chartContent.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(chartContent)
        NSLayoutConstraint.activate([
            chartContent.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 8),
            chartContent.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -8),
            chartContent.topAnchor.constraint(equalTo: container.topAnchor),
            chartContent.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -4)
        ])

        if let formula = makePositionFormulaLabel(asset) {
            chartContent.addArrangedSubview(formula)
        }

        switch state {
        case let .loaded(points):
            let chart = StockChartView()
            chart.points = points
            chart.colorMode = colorMode
            chart.widthAnchor.constraint(equalToConstant: contentWidth - 16).isActive = true
            chart.heightAnchor.constraint(greaterThanOrEqualToConstant: asset.hasPosition ? 78 : 96).isActive = true
            chartContent.addArrangedSubview(chart)
        case .loading:
            addCenteredChartMessage(L10n.stockChartLoading, to: chartContent)
        case .unavailable:
            addCenteredChartMessage(L10n.stockChartNoData, to: chartContent)
        case .failed:
            addCenteredChartMessage(L10n.stockChartLoadFailed, to: chartContent)
        }
        return container
    }

    private func addCenteredChartMessage(_ text: String, to container: NSView) {
        let label = makeLabel(
            text,
            font: appFont(ofSize: 11, weight: .medium),
            color: NSColor.white.withAlphaComponent(0.50),
            alignment: .center
        )
        label.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            label.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])
    }

    private func toggleStockChart(assetID: String) {
        guard stockChartPeriod != .off,
              assets.contains(where: { $0.id == assetID && $0.type == .stock }) else { return }
        if expandedAssetID == assetID {
            expandedAssetID = nil
            render()
            return
        }

        expandedAssetID = assetID
        if stockDataSource == .tencent {
            stockChartStates[assetID] = .unavailable
        } else {
            stockChartStates[assetID] = .loading
            onRequestStockChart?(assetID)
        }
        render()
    }

    private func makeSearchHeader() -> NSView {
        let inputRow = NSStackView()
        inputRow.orientation = .horizontal
        inputRow.alignment = .centerY
        inputRow.spacing = 8
        inputRow.widthAnchor.constraint(equalToConstant: contentWidth).isActive = true
        inputRow.heightAnchor.constraint(equalToConstant: headerHeight).isActive = true

        let field = NSTextField(string: searchQuery)
        field.placeholderString = L10n.searchPlaceholder
        field.delegate = self
        field.font = senFont(ofSize: 13)
        field.setContentHuggingPriority(.defaultLow, for: .horizontal)
        searchField = field

        let button = NSButton(title: isSearching ? L10n.searching : L10n.search, target: self, action: #selector(searchClicked(_:)))
        button.bezelStyle = .rounded
        button.controlSize = .small
        button.font = appFont(ofSize: 12, weight: .semibold)
        button.isEnabled = !isSearching
        button.widthAnchor.constraint(equalToConstant: headerActionButtonWidth).isActive = true

        let cancel = NSButton(title: L10n.cancel, target: self, action: #selector(cancelSearchClicked(_:)))
        cancel.bezelStyle = .rounded
        cancel.controlSize = .small
        cancel.font = appFont(ofSize: 12, weight: .semibold)
        cancel.widthAnchor.constraint(equalToConstant: headerActionButtonWidth).isActive = true
        addArrangedSubviews([field, button, cancel], to: inputRow)

        return inputRow
    }

    private func makeSearchList() -> NSView {
        let rowCount = searchResultRowCount
        let rowDocumentHeight = hasSearchResults
            ? searchDocumentHeight
            : CGFloat(rowCount) * searchResultRowHeight + CGFloat(max(rowCount - 1, 0)) * listRowGap
        let listHeight = currentListHeight
        let documentHeight = max(rowDocumentHeight, listHeight)

        let scroll = NSScrollView()
        scroll.borderType = .noBorder
        scroll.drawsBackground = false
        scroll.hasVerticalScroller = rowCount > 8
        scroll.autohidesScrollers = true
        scroll.verticalScrollElasticity = .allowed
        scroll.widthAnchor.constraint(equalToConstant: scrollWidth).isActive = true
        scroll.heightAnchor.constraint(equalToConstant: listHeight).isActive = true

        let document = FlippedDocumentView(frame: NSRect(x: 0, y: 0, width: scrollWidth, height: documentHeight))
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = contentAlignment
        stack.spacing = listRowGap
        stack.translatesAutoresizingMaskIntoConstraints = false
        document.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: document.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: document.trailingAnchor),
            stack.topAnchor.constraint(equalTo: document.topAnchor),
            stack.bottomAnchor.constraint(equalTo: document.bottomAnchor)
        ])

        if isSearching {
            stack.addArrangedSubview(makeSearchMessageRow(L10n.searchInProgress))
        } else if let searchMessage {
            stack.addArrangedSubview(makeSearchMessageRow(searchMessage))
        } else if searchResults.isEmpty {
            stack.addArrangedSubview(makeSearchMessageRow(L10n.emptySearchPrompt))
        } else {
            var previousView: NSView?
            for item in searchListItems {
                if case .group = item, let previousView {
                    stack.setCustomSpacing(searchGroupGap, after: previousView)
                }

                let itemView: NSView
                switch item {
                case let .group(title, count, accentColor):
                    itemView = makeSearchGroupHeader(title, count: count, accentColor: accentColor)
                case let .result(result):
                    itemView = makeSearchResultRow(result)
                }
                stack.addArrangedSubview(itemView)
                previousView = itemView
            }
        }

        scroll.documentView = document
        searchScrollView = scroll
        restoreScrollPosition(searchScrollPosition, in: scroll, viewportHeight: listHeight)
        return scroll
    }

    private func makeSearchMessageRow(_ text: String) -> NSView {
        let container = NSView()
        container.widthAnchor.constraint(equalToConstant: contentWidth).isActive = true
        container.heightAnchor.constraint(equalToConstant: currentListHeight).isActive = true

        let label = makeLabel(text, font: appFont(ofSize: 11, weight: .medium), color: NSColor.white.withAlphaComponent(0.50), alignment: .center)
        label.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(label)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            label.leadingAnchor.constraint(greaterThanOrEqualTo: container.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor, constant: -16)
        ])

        return container
    }

    private func makeSearchGroupHeader(_ title: String, count: Int, accentColor: NSColor) -> NSView {
        let container = NSView()
        container.wantsLayer = true
        container.layer?.backgroundColor = NSColor.white.withAlphaComponent(0.055).cgColor
        container.layer?.cornerRadius = 4
        container.widthAnchor.constraint(equalToConstant: contentWidth).isActive = true
        container.heightAnchor.constraint(equalToConstant: searchGroupHeaderHeight).isActive = true

        let accent = NSView()
        accent.wantsLayer = true
        accent.layer?.backgroundColor = accentColor.cgColor
        accent.layer?.cornerRadius = 1.5
        accent.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(accent)

        let label = makeLabel(title, font: appFont(ofSize: 12, weight: .semibold), color: NSColor.white.withAlphaComponent(0.88), alignment: leadingTextAlignment)
        label.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(label)

        let countLabel = makeLabel("\(count)", font: appFont(ofSize: 10, weight: .semibold), color: NSColor.white.withAlphaComponent(0.46), alignment: trailingTextAlignment)
        countLabel.translatesAutoresizingMaskIntoConstraints = false
        countLabel.widthAnchor.constraint(equalToConstant: 24).isActive = true
        container.addSubview(countLabel)

        NSLayoutConstraint.activate([
            accent.widthAnchor.constraint(equalToConstant: 3),
            accent.heightAnchor.constraint(equalToConstant: 14),
            accent.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            label.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            countLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])

        if isRTL {
            NSLayoutConstraint.activate([
                accent.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -18),
                label.trailingAnchor.constraint(equalTo: accent.leadingAnchor, constant: -8),
                label.leadingAnchor.constraint(greaterThanOrEqualTo: countLabel.trailingAnchor, constant: 8),
                countLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12)
            ])
        } else {
            NSLayoutConstraint.activate([
                accent.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 18),
                label.leadingAnchor.constraint(equalTo: accent.trailingAnchor, constant: 8),
                label.trailingAnchor.constraint(lessThanOrEqualTo: countLabel.leadingAnchor, constant: -8),
                countLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12)
            ])
        }

        return container
    }

    private func makeSearchResultRow(_ result: AssetSearchResult) -> NSView {
        let row = ClickableSearchResultRowView()
        row.onClick = { [weak self] in
            self?.toggleSearchResult(result)
        }
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 8
        row.widthAnchor.constraint(equalToConstant: contentWidth).isActive = true
        row.heightAnchor.constraint(equalToConstant: searchResultRowHeight).isActive = true

        let checkSpace = NSView()
        checkSpace.widthAnchor.constraint(equalToConstant: 18).isActive = true

        let left = NSStackView()
        left.orientation = .vertical
        left.alignment = leadingColumnAlignment
        left.spacing = 3
        left.addArrangedSubview(makeLabel(result.name, font: appFont(ofSize: 14, weight: .bold), color: .white, alignment: leadingTextAlignment))
        left.addArrangedSubview(makeMutedLabel(result.symbol, alignment: leadingTextAlignment))
        left.setContentHuggingPriority(.defaultLow, for: .horizontal)

        let spacer = NSView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)

        let detail = makeLabel(result.source, font: appFont(ofSize: 11, weight: .medium), color: NSColor.white.withAlphaComponent(0.50), alignment: trailingTextAlignment)
        detail.widthAnchor.constraint(equalToConstant: 82).isActive = true

        let exists = assets.contains { $0.id == result.id }
        let add = SearchResultActionButton(title: "", target: self, action: #selector(addSearchResultClicked(_:)))
        add.isTracked = exists
        add.isBordered = false
        add.identifier = NSUserInterfaceItemIdentifier(result.id)
        add.toolTip = exists ? L10n.remove : L10n.add
        add.widthAnchor.constraint(equalToConstant: 18).isActive = true
        add.heightAnchor.constraint(equalToConstant: 18).isActive = true
        addArrangedSubviews([checkSpace, left, spacer, detail, add], to: row)

        return row
    }

    private func searchListItemHeight(_ item: SearchListItem) -> CGFloat {
        switch item {
        case .group:
            return searchGroupHeaderHeight
        case .result:
            return searchResultRowHeight
        }
    }

    private func searchGroupTitle(for result: AssetSearchResult) -> String {
        switch result.type {
        case .crypto:
            return L10n.text("币", "Crypto", zhHant: "幣", ja: "暗号資産", ar: "عملات", de: "Krypto", fr: "Crypto", ko: "코인", ptPT: "Cripto", es: "Cripto")
        case .gold:
            return L10n.gold
        case .stock:
            let canonical = (result.canonicalSymbol ?? canonicalAssetSymbol(type: result.type, symbol: result.symbol)).uppercased()
            if canonical.hasPrefix("HK:") {
                return L10n.text("港股", "Hong Kong", zhHant: "港股", ja: "香港株", ar: "هونغ كونغ", de: "Hongkong", fr: "Hong Kong", ko: "홍콩", ptPT: "Hong Kong", es: "Hong Kong")
            }
            if canonical.hasPrefix("US:") {
                return L10n.text("美股", "US", zhHant: "美股", ja: "米国株", ar: "الولايات المتحدة", de: "USA", fr: "États-Unis", ko: "미국", ptPT: "EUA", es: "EE. UU.")
            }
            if canonical.hasPrefix("KR:") {
                return L10n.text("韩股", "Korea", zhHant: "韓股", ja: "韓国株", ar: "كوريا الجنوبية", de: "Südkorea", fr: "Corée du Sud", ko: "한국", ptPT: "Coreia do Sul", es: "Corea del Sur")
            }
            if canonical.hasPrefix("SH:") || canonical.hasPrefix("SZ:") {
                return L10n.text("A 股", "A-shares", zhHant: "A 股", ja: "A株", ar: "أسهم A", de: "A-Aktien", fr: "Actions A", ko: "A주", ptPT: "A-shares", es: "Acciones A")
            }
            return result.source
        }
    }

    private func searchGroupAccentColor(for result: AssetSearchResult) -> NSColor {
        switch result.type {
        case .crypto:
            return NSColor(calibratedRed: 0.60, green: 0.50, blue: 0.96, alpha: 1)
        case .gold:
            return NSColor(calibratedRed: 0.96, green: 0.72, blue: 0.25, alpha: 1)
        case .stock:
            let canonical = (result.canonicalSymbol ?? canonicalAssetSymbol(type: result.type, symbol: result.symbol)).uppercased()
            if canonical.hasPrefix("HK:") {
                return NSColor(calibratedRed: 0.96, green: 0.38, blue: 0.48, alpha: 1)
            }
            if canonical.hasPrefix("US:") {
                return NSColor(calibratedRed: 0.38, green: 0.62, blue: 0.98, alpha: 1)
            }
            if canonical.hasPrefix("KR:") {
                return NSColor(calibratedRed: 0.28, green: 0.76, blue: 0.82, alpha: 1)
            }
            if canonical.hasPrefix("SH:") || canonical.hasPrefix("SZ:") {
                return NSColor(calibratedRed: 0.98, green: 0.56, blue: 0.28, alpha: 1)
            }
            return NSColor.white.withAlphaComponent(0.48)
        }
    }

    private func makeSettingsMenu() -> NSMenu {
        let menu = NSMenu()
        menu.appearance = NSAppearance(named: .darkAqua)
        menu.addItem(makeParentMenuItem(title: L10n.colorSetting, submenu: makeColorModeMenu()))
        menu.addItem(makeParentMenuItem(title: L10n.statusBarBackgroundSetting, submenu: makeStatusBarBackgroundMenu()))
        menu.addItem(makeParentMenuItem(title: L10n.stockChartSetting, submenu: makeStockChartPeriodMenu()))
        menu.addItem(makeParentMenuItem(title: L10n.stockDataSourceSetting, submenu: makeStockDataSourceMenu()))
        menu.addItem(makeParentMenuItem(title: L10n.languageSetting, submenu: makeLanguageMenu()))
        menu.addItem(.separator())

        let launchAtLogin = NSMenuItem(title: L10n.launchAtLogin, action: #selector(launchAtLoginMenuItemClicked(_:)), keyEquivalent: "")
        launchAtLogin.target = self
        launchAtLogin.state = LoginLaunchAgent.isEnabled ? .on : .off
        menu.addItem(launchAtLogin)
        menu.addItem(.separator())

        let quit = NSMenuItem(title: L10n.quit, action: #selector(quitClicked), keyEquivalent: "")
        quit.target = self
        menu.addItem(quit)
        return menu
    }

    private func makeParentMenuItem(title: String, submenu: NSMenu) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.submenu = submenu
        return item
    }

    private func makeColorModeMenu() -> NSMenu {
        let menu = NSMenu()
        menu.appearance = NSAppearance(named: .darkAqua)
        for mode in PriceColorMode.allCases {
            let item = NSMenuItem(title: mode.title, action: #selector(colorModeMenuItemClicked(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = mode.rawValue
            item.state = mode == colorMode ? .on : .off
            menu.addItem(item)
        }
        return menu
    }

    private func makeStatusBarBackgroundMenu() -> NSMenu {
        let menu = NSMenu()
        menu.appearance = NSAppearance(named: .darkAqua)
        for mode in StatusBarBackgroundMode.allCases {
            let item = NSMenuItem(title: mode.title, action: #selector(statusBarBackgroundMenuItemClicked(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = mode.rawValue
            item.state = mode == statusBarBackgroundMode ? .on : .off
            menu.addItem(item)
        }
        return menu
    }

    private func makeStockDataSourceMenu() -> NSMenu {
        let menu = NSMenu()
        menu.appearance = NSAppearance(named: .darkAqua)
        for source in StockDataSource.allCases {
            let item = NSMenuItem(title: source.title, action: #selector(stockDataSourceMenuItemClicked(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = source.rawValue
            item.state = source == stockDataSource ? .on : .off
            menu.addItem(item)
        }
        return menu
    }

    private func makeStockChartPeriodMenu() -> NSMenu {
        let menu = NSMenu()
        menu.appearance = NSAppearance(named: .darkAqua)
        for period in StockChartPeriod.allCases {
            let item = NSMenuItem(title: period.title, action: #selector(stockChartPeriodMenuItemClicked(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = period.rawValue
            item.state = period == stockChartPeriod ? .on : .off
            menu.addItem(item)
        }
        return menu
    }

    private func makeLanguageMenu() -> NSMenu {
        let menu = NSMenu()
        menu.appearance = NSAppearance(named: .darkAqua)
        for language in AppLanguage.allCases {
            let item = NSMenuItem(title: language.title, action: #selector(languageMenuItemClicked(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = language.rawValue
            item.state = language == self.language ? .on : .off
            menu.addItem(item)
        }
        return menu
    }

    private func makeButtonRow() -> NSView {
        let row = NSStackView()
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 8
        row.widthAnchor.constraint(equalToConstant: contentWidth).isActive = true

        let state = L10n.refreshState(isRefreshing: isRefreshing, countdown: countdown)
        let refresh = makeLabel(state, font: appFont(ofSize: 11, weight: .semibold), color: NSColor.white.withAlphaComponent(0.56), alignment: leadingTextAlignment)
        refreshStateLabel = refresh

        let spacer = NSView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)

        addArrangedSubviews([refresh, spacer], to: row)

        return row
    }

    @objc private func toggleSearchClicked(_ sender: NSButton) {
        openSearchMode()
        render()
    }

    @objc private func cancelSearchClicked(_ sender: NSButton) {
        closeSearchMode()
        render()
    }

    @objc private func toggleAssetEditingClicked(_ sender: NSButton) {
        isEditingAssets.toggle()
        if isEditingAssets {
            expandedAssetID = nil
        }
        render()
    }

    @objc private func settingsClicked(_ sender: NSButton) {
        let menu = makeSettingsMenu()
        if let event = NSApp.currentEvent {
            NSMenu.popUpContextMenu(menu, with: event, for: sender)
        } else {
            menu.popUp(positioning: nil, at: NSPoint(x: 0, y: sender.bounds.height + 4), in: sender)
        }
    }

    @objc private func colorModeMenuItemClicked(_ sender: NSMenuItem) {
        guard let rawValue = sender.representedObject as? String,
              let mode = PriceColorMode(rawValue: rawValue) else { return }
        colorMode = mode
        onColorModeChange?(mode)
        render()
    }

    @objc private func statusBarBackgroundMenuItemClicked(_ sender: NSMenuItem) {
        guard let rawValue = sender.representedObject as? String,
              let mode = StatusBarBackgroundMode(rawValue: rawValue) else { return }
        statusBarBackgroundMode = mode
        onStatusBarBackgroundModeChange?(mode)
        render()
    }

    @objc private func stockDataSourceMenuItemClicked(_ sender: NSMenuItem) {
        guard let rawValue = sender.representedObject as? String,
              let source = StockDataSource(rawValue: rawValue) else { return }
        onStockDataSourceChange?(source)
        render()
    }

    @objc private func stockChartPeriodMenuItemClicked(_ sender: NSMenuItem) {
        guard let rawValue = sender.representedObject as? String,
              let period = StockChartPeriod(rawValue: rawValue) else { return }
        onStockChartPeriodChange?(period)
        render()
    }

    @objc private func languageMenuItemClicked(_ sender: NSMenuItem) {
        guard let rawValue = sender.representedObject as? String,
              let language = AppLanguage(rawValue: rawValue) else { return }
        self.language = language
        L10n.appLanguage = language
        onLanguageChange?(language)
        render()
    }

    @objc private func launchAtLoginMenuItemClicked(_ sender: NSMenuItem) {
        let shouldEnable = sender.state != .on
        do {
            try LoginLaunchAgent.setEnabled(shouldEnable)
            sender.state = shouldEnable ? .on : .off
        } catch {
            showToast(L10n.launchAtLoginFailed)
            NSLog("CareAssets launch at login update failed: \(error.localizedDescription)")
        }
    }

    @objc private func searchClicked(_ sender: Any) {
        submitSearch()
    }

    private func submitSearch() {
        if let searchField {
            searchQuery = searchField.stringValue
        }
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            searchResults = []
            searchMessage = L10n.emptySearchPrompt
            render()
            return
        }
        guard !isSearching else { return }

        isSearching = true
        searchResults = []
        searchMessage = nil
        render()
        onSearchStocks?(query)
    }

    @objc private func addSearchResultClicked(_ sender: NSButton) {
        guard let id = sender.identifier?.rawValue,
              let result = searchResults.first(where: { $0.id == id }) else { return }
        toggleSearchResult(result)
    }

    private func toggleSearchResult(_ result: AssetSearchResult) {
        let wasTracked = isSearchResultTracked(result)
        if wasTracked {
            onRemoveAsset?(result.id)
        } else {
            onAddStock?(result)
        }

        render()
        showToast(wasTracked ? L10n.assetRemovedToast(result.name) : L10n.assetAddedToast(result.name))
    }

    @objc private func toggleVisibleClicked(_ sender: NSButton) {
        guard let id = sender.identifier?.rawValue else { return }
        onToggleVisible?(id, sender.state == .on)
    }

    @objc private func removeAssetClicked(_ sender: NSButton) {
        guard let id = sender.identifier?.rawValue else { return }
        onRemoveAsset?(id)
    }

    @objc private func editPositionClicked(_ sender: NSButton) {
        guard let id = sender.identifier?.rawValue else { return }
        onEditPosition?(id)
    }

    @objc private func quitClicked() {
        onQuit?()
    }

    func controlTextDidChange(_ notification: Notification) {
        guard let field = notification.object as? NSTextField else { return }
        searchQuery = field.stringValue
    }

    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        guard control === searchField else { return false }
        if commandSelector == #selector(NSResponder.insertNewline(_:)) {
            submitSearch()
            return true
        }
        return false
    }

    func focusSearchFieldIfNeeded() {
        guard isSearchOpen, let searchField else { return }
        DispatchQueue.main.async { [weak self, weak searchField] in
            guard let self, self.isSearchOpen, let searchField else { return }
            NSApp.activate(ignoringOtherApps: true)
            self.view.window?.makeKey()
            self.view.window?.makeFirstResponder(searchField)
        }
    }

    private func openSearchMode() {
        isSearchOpen = true
        isEditingAssets = false
        isSearching = false
        searchModeListHeight = assetListHeight
        searchQuery = ""
        searchResults = []
        searchMessage = L10n.emptySearchPrompt
        shouldFocusSearchField = true
    }

    private func closeSearchMode(clearSearch: Bool = false) {
        isSearchOpen = false
        isSearching = false
        shouldFocusSearchField = false
        searchModeListHeight = nil
        if clearSearch {
            searchQuery = ""
            searchResults = []
            searchMessage = nil
        }
    }

    private func makeMutedLabel(_ text: String, alignment: NSTextAlignment = .left) -> NSTextField {
        makeLabel(text, font: appFont(ofSize: 11, weight: .medium), color: NSColor.white.withAlphaComponent(0.50), alignment: alignment)
    }

    private func makeAssetCodeLine(_ asset: DisplayAsset) -> NSView {
        let row = NSStackView()
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 5

        let tag = makeAssetTypeTag(assetTagText(for: asset))
        let code = makeMutedLabel(asset.detailText, alignment: leadingTextAlignment)
        code.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        if isRTL {
            row.addArrangedSubview(code)
            row.addArrangedSubview(tag)
        } else {
            row.addArrangedSubview(tag)
            row.addArrangedSubview(code)
        }
        return row
    }

    private func makeAssetTypeTag(_ text: String) -> NSView {
        let container = NSView()
        container.wantsLayer = true
        container.layer?.backgroundColor = NSColor.white.withAlphaComponent(0.16).cgColor
        container.layer?.cornerRadius = 3
        container.heightAnchor.constraint(equalToConstant: 15).isActive = true

        let label = makeLabel(text, font: appFont(ofSize: 9, weight: .bold), color: NSColor.white.withAlphaComponent(0.82), alignment: .center)
        container.widthAnchor.constraint(equalToConstant: ceil(label.intrinsicContentSize.width) + 8).isActive = true
        label.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(label)

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 4),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -4),
            label.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])

        return container
    }

    private func assetTagText(for asset: DisplayAsset) -> String {
        switch asset.type {
        case .gold:
            return "GOLD"
        case .crypto:
            return "COIN"
        case .stock:
            let canonical = (asset.canonicalSymbol ?? canonicalAssetSymbol(type: asset.type, symbol: asset.symbol)).uppercased()
            if canonical.hasPrefix("HK:") { return "HK" }
            if canonical.hasPrefix("US:") { return "US" }
            if canonical.hasPrefix("KR:") { return "KR" }
            if canonical.hasPrefix("SH:") { return "SH" }
            if canonical.hasPrefix("SZ:") { return "SZ" }
            return "STOCK"
        }
    }

    private func showToast(_ message: String) {
        toastWorkItem?.cancel()
        toastView?.removeFromSuperview()

        let container = NSView()
        container.wantsLayer = true
        container.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.72).cgColor
        container.layer?.cornerRadius = 7
        container.translatesAutoresizingMaskIntoConstraints = false

        let label = makeLabel(message, font: appFont(ofSize: 11, weight: .semibold), color: .white, alignment: .center)
        label.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(label)
        view.addSubview(container)

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
            label.topAnchor.constraint(equalTo: container.topAnchor, constant: 6),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -6),
            container.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            container.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -bottomInset),
            container.widthAnchor.constraint(lessThanOrEqualToConstant: contentWidth - 48)
        ])

        toastView = container
        let workItem = DispatchWorkItem { [weak self, weak container] in
            container?.removeFromSuperview()
            if self?.toastView === container {
                self?.toastView = nil
            }
        }
        toastWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6, execute: workItem)
    }

    private func makeRTLScrollerGutter() -> NSView {
        let view = NSView()
        view.widthAnchor.constraint(equalToConstant: rtlScrollerGutterWidth).isActive = true
        return view
    }

    private func updateRefreshStateLabel() {
        guard let label = refreshStateLabel else { return }
        let font = appFont(ofSize: 11, weight: .semibold)
        let color = NSColor.white.withAlphaComponent(0.56)
        let style = NSMutableParagraphStyle()
        style.alignment = .right
        label.alignment = .right
        label.attributedStringValue = mixedAttributedString(
            L10n.refreshState(isRefreshing: isRefreshing, countdown: countdown),
            baseFont: font,
            asciiFont: senFont(ofSize: font.pointSize),
            color: color,
            paragraphStyle: style
        )
    }

    private func displayName(for asset: DisplayAsset) -> String {
        if asset.type == .gold, asset.symbol == "JD_GOLD" {
            return L10n.gold
        }
        return asset.name
    }

    private func isSearchResultTracked(_ result: AssetSearchResult) -> Bool {
        assets.contains { $0.id == result.id }
    }

    private func makeAssetPriceLine(_ asset: DisplayAsset) -> NSView {
        let row = NSView()
        row.widthAnchor.constraint(equalToConstant: rightColumnWidth).isActive = true
        row.heightAnchor.constraint(equalToConstant: 18).isActive = true

        let warning = makeQuoteTimeWarning(asset)
        warning.translatesAutoresizingMaskIntoConstraints = false
        warning.widthAnchor.constraint(equalToConstant: 12).isActive = true

        let change = makeChangePercentTag(asset)

        let price = makeLabel(asset.priceText, font: appFont(ofSize: 15, weight: .bold), color: valueColor(for: asset), alignment: .right)
        price.setContentCompressionResistancePriority(.required, for: .horizontal)

        let valueGroup = NSStackView()
        valueGroup.orientation = .horizontal
        valueGroup.alignment = .centerY
        valueGroup.spacing = 6
        valueGroup.translatesAutoresizingMaskIntoConstraints = false
        if isRTL {
            valueGroup.addArrangedSubview(price)
            valueGroup.addArrangedSubview(change)
        } else {
            valueGroup.addArrangedSubview(price)
            valueGroup.addArrangedSubview(change)
        }

        row.addSubview(warning)
        row.addSubview(valueGroup)
        if isRTL {
            NSLayoutConstraint.activate([
                valueGroup.leadingAnchor.constraint(equalTo: row.leadingAnchor),
                valueGroup.centerYAnchor.constraint(equalTo: row.centerYAnchor),
                valueGroup.trailingAnchor.constraint(lessThanOrEqualTo: warning.leadingAnchor, constant: -4),
                warning.trailingAnchor.constraint(equalTo: row.trailingAnchor),
                warning.centerYAnchor.constraint(equalTo: row.centerYAnchor)
            ])
        } else {
            NSLayoutConstraint.activate([
                warning.leadingAnchor.constraint(equalTo: row.leadingAnchor),
                warning.centerYAnchor.constraint(equalTo: row.centerYAnchor),
                valueGroup.leadingAnchor.constraint(greaterThanOrEqualTo: warning.trailingAnchor, constant: 4),
                valueGroup.trailingAnchor.constraint(equalTo: row.trailingAnchor),
                valueGroup.centerYAnchor.constraint(equalTo: row.centerYAnchor)
            ])
        }
        return row
    }

    private func makeChangePercentTag(_ asset: DisplayAsset) -> NSView {
        makePercentTag(formatPercent(asset.changePercent), color: valueColor(for: asset))
    }

    private func makePositionPercentTag(_ asset: DisplayAsset) -> NSView {
        makePercentTag(formatPercent(asset.positionProfitPercent), color: positionColor(for: asset))
    }

    private func makePercentTag(_ text: String, color: NSColor) -> NSView {
        let container = NSView()
        container.wantsLayer = true
        container.layer?.backgroundColor = color.withAlphaComponent(0.16).cgColor
        container.layer?.cornerRadius = 3
        container.heightAnchor.constraint(equalToConstant: 15).isActive = true

        let label = makeLabel(text, font: appFont(ofSize: 9, weight: .bold), color: color, alignment: .center)
        container.widthAnchor.constraint(equalToConstant: percentTagWidth).isActive = true
        label.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(label)

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 4),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -4),
            label.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])

        return container
    }

    private func makeQuoteTimeWarning(_ asset: DisplayAsset) -> NSTextField {
        let warningText = quoteTimeWarningText(for: asset)
        let label = makeLabel(warningText == nil ? "" : "⚠️", font: appFont(ofSize: 10, weight: .semibold), color: NSColor.systemYellow, alignment: .center)
        label.toolTip = warningText
        return label
    }

    private func quoteTimeWarningText(for asset: DisplayAsset) -> String? {
        guard asset.errorMessage == nil else { return nil }
        guard let updatedAt = asset.updatedAt else {
            return L10n.text("报价时间缺失", "Quote time is missing", zhHant: "報價時間缺失")
        }

        let now = Date()
        if updatedAt.timeIntervalSince(now) > 300 {
            return L10n.text(
                "报价时间异常：\(dateFormatter.string(from: updatedAt))",
                "Suspicious quote time: \(dateFormatter.string(from: updatedAt))",
                zhHant: "報價時間異常：\(dateFormatter.string(from: updatedAt))"
            )
        }

        let maxAge: TimeInterval = asset.type == .crypto ? 30 * 60 : 4 * 24 * 60 * 60
        if now.timeIntervalSince(updatedAt) > maxAge {
            return L10n.text(
                "报价可能过旧：\(dateFormatter.string(from: updatedAt))",
                "Quote may be stale: \(dateFormatter.string(from: updatedAt))",
                zhHant: "報價可能過舊：\(dateFormatter.string(from: updatedAt))"
            )
        }

        return nil
    }

    private func makeAssetDetailLabel(_ asset: DisplayAsset, percentText: String, dateText: String?, isError: Bool = false) -> NSTextField {
        let font = appFont(ofSize: 11, weight: .medium)
        let mutedColor = NSColor.white.withAlphaComponent(0.58)
        let label = NSTextField(labelWithString: "")
        label.font = font
        label.alignment = trailingTextAlignment
        label.lineBreakMode = .byTruncatingTail
        label.maximumNumberOfLines = 1

        let style = NSMutableParagraphStyle()
        style.alignment = trailingTextAlignment

        if isError {
            label.attributedStringValue = mixedAttributedString(
                percentText,
                baseFont: font,
                asciiFont: senFont(ofSize: font.pointSize),
                color: mutedColor,
                paragraphStyle: style
            )
            return label
        }

        let text = NSMutableAttributedString()
        text.append(mixedAttributedString(
            percentText,
            baseFont: font,
            asciiFont: senFont(ofSize: font.pointSize),
            color: valueColor(for: asset),
            paragraphStyle: nil
        ))

        if let dateText {
            text.append(mixedAttributedString(
                " · \(dateText)",
                baseFont: font,
                asciiFont: senFont(ofSize: font.pointSize),
                color: mutedColor,
                paragraphStyle: nil
            ))
        }

        text.addAttribute(.paragraphStyle, value: style, range: NSRange(location: 0, length: text.length))
        label.attributedStringValue = text
        return label
    }

    private func makePositionDetailLabel(_ asset: DisplayAsset) -> NSTextField {
        let font = appFont(ofSize: 11, weight: .medium)
        let label = NSTextField(labelWithString: "")
        label.font = font
        label.alignment = trailingTextAlignment
        label.lineBreakMode = .byTruncatingTail
        label.maximumNumberOfLines = 1
        label.widthAnchor.constraint(equalToConstant: rightColumnWidth).isActive = true

        let style = NSMutableParagraphStyle()
        style.alignment = trailingTextAlignment

        label.attributedStringValue = mixedAttributedString(
            positionDetailText(for: asset),
            baseFont: font,
            asciiFont: senFont(ofSize: font.pointSize),
            color: positionColor(for: asset),
            paragraphStyle: style
        )
        return label
    }

    private func makePositionSummaryLabel(_ asset: DisplayAsset) -> NSTextField {
        let label = makeLabel(
            positionSummaryText(for: asset),
            font: appFont(ofSize: 11, weight: .medium),
            color: positionColor(for: asset),
            alignment: trailingTextAlignment
        )
        label.lineBreakMode = .byTruncatingHead
        label.maximumNumberOfLines = 1
        return label
    }

    private func positionSummaryText(for asset: DisplayAsset) -> String {
        guard let amount = asset.positionProfitAmount,
              let marketValue = asset.positionMarketValue,
              let quantity = asset.holdingQuantity,
              let currency = asset.currency else {
            return "--"
        }
        let quantityText = formatNumber(quantity, minFraction: 0, maxFraction: 4)
        let positionText = L10n.text(
            "\(L10n.position) \(quantityText) 股",
            "\(L10n.position) \(quantityText) shares",
            zhHant: "\(L10n.position) \(quantityText) 股"
        )
        return "\(positionText) · \(L10n.marketValue) \(formatCurrencyWithCode(marketValue, currencyCode: currency, compact: true)) · \(L10n.profitLoss) \(formatSignedCurrencyWithCode(amount, currencyCode: currency, compact: true))"
    }

    private func makePositionFormulaLabel(_ asset: DisplayAsset) -> NSTextField? {
        guard let amount = asset.positionProfitAmount,
              let marketValue = asset.positionMarketValue,
              let cost = asset.positionCost,
              let currency = asset.currency else {
            return nil
        }
        let text = L10n.text(
            "\(L10n.marketValue) \(formatCurrencyWithCode(marketValue, currencyCode: currency, compact: false)) − \(L10n.cost) \(formatCurrencyWithCode(cost, currencyCode: currency, compact: false)) = \(formatSignedCurrencyWithCode(amount, currencyCode: currency, compact: false))",
            "\(L10n.marketValue) \(formatCurrencyWithCode(marketValue, currencyCode: currency, compact: false)) − \(L10n.cost) \(formatCurrencyWithCode(cost, currencyCode: currency, compact: false)) = \(formatSignedCurrencyWithCode(amount, currencyCode: currency, compact: false))",
            zhHant: "\(L10n.marketValue) \(formatCurrencyWithCode(marketValue, currencyCode: currency, compact: false)) − \(L10n.cost) \(formatCurrencyWithCode(cost, currencyCode: currency, compact: false)) = \(formatSignedCurrencyWithCode(amount, currencyCode: currency, compact: false))"
        )
        let label = makeLabel(text, font: appFont(ofSize: 10, weight: .medium), color: NSColor.white.withAlphaComponent(0.62), alignment: trailingTextAlignment)
        label.lineBreakMode = .byTruncatingHead
        label.maximumNumberOfLines = 1
        label.widthAnchor.constraint(equalToConstant: contentWidth - 16).isActive = true
        return label
    }

    private func positionDetailText(for asset: DisplayAsset) -> String {
        guard let amount = asset.positionProfitAmount,
              let percent = asset.positionProfitPercent,
              let marketValue = asset.positionMarketValue,
              let currency = asset.currency else {
            return "--"
        }
        return "\(L10n.marketValue) \(formatCurrencyWithCode(marketValue, currencyCode: currency, compact: true)) · \(formatPercent(percent)) · \(formatSignedCurrencyWithCode(amount, currencyCode: currency, compact: true))"
    }

    private func makeLabel(_ text: String, font: NSFont, color: NSColor, alignment: NSTextAlignment = .left) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.font = font
        label.textColor = color
        label.alignment = alignment
        label.lineBreakMode = .byTruncatingTail
        label.maximumNumberOfLines = 1
        let style = NSMutableParagraphStyle()
        style.alignment = alignment
        label.attributedStringValue = mixedAttributedString(
            text,
            baseFont: font,
            asciiFont: senFont(ofSize: font.pointSize),
            color: color,
            paragraphStyle: style
        )
        return label
    }

    private func valueColor(for asset: DisplayAsset) -> NSColor {
        priceColor(for: asset, mode: colorMode, whiteAlpha: 1, errorAlpha: 0.58)
    }

    private func positionColor(for asset: DisplayAsset) -> NSColor {
        priceColor(for: asset.positionProfitPercent, mode: colorMode, whiteAlpha: 1)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {
    private enum PositionEditResult {
        case save(quantity: Double, averageBuyPrice: Double)
        case clear
        case cancel
        case invalid
    }

    private var statusItem: NSStatusItem?
    private let tickerView = StatusTickerView()
    private let popover = NSPopover()
    private let panelViewController = AssetPanelViewController()
    private let service = AssetService()
    private var previewWindow: NSWindow?

    private var config = ConfigStore.loadOrCreate()
    private var assets: [DisplayAsset] = []
    private var timer: Timer?
    private var secondsUntilRefresh = 0
    private var isRefreshing = false
    private var searchRequestID = 0
    private var loadingFrame = 0
    private var localMouseMonitor: Any?
    private var globalMouseMonitor: Any?
    private var resignActiveObserver: NSObjectProtocol?

    func applicationDidFinishLaunching(_ notification: Notification) {
        FontRegistrar.registerBundledFonts()
        L10n.appLanguage = config.language
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        assets = config.assets.map(DisplayAsset.loading)
        secondsUntilRefresh = max(10, config.refreshIntervalSeconds)

        setupStatusItem()
        setupPopover()
        updateViews()
        refresh()

        if ProcessInfo.processInfo.environment["CAREASSETS_PREVIEW"] == "1" {
            showPreviewWindow()
        }

        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(tick), userInfo: nil, repeats: true)
    }

    private func setupStatusItem() {
        tickerView.items = visibleMenuAssets()
        tickerView.onClick = { [weak self] in
            self?.togglePopover()
        }

        if let button = statusItem?.button {
            button.title = ""
            button.image = nil
            button.toolTip = L10n.appTooltip
            button.target = self
            button.action = #selector(statusButtonClicked)

            if tickerView.superview == nil {
                button.addSubview(tickerView)
                tickerView.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    tickerView.leadingAnchor.constraint(equalTo: button.leadingAnchor),
                    tickerView.trailingAnchor.constraint(equalTo: button.trailingAnchor),
                    tickerView.topAnchor.constraint(equalTo: button.topAnchor),
                    tickerView.bottomAnchor.constraint(equalTo: button.bottomAnchor)
                ])
            }
        }
    }

    private func setupPopover() {
        popover.behavior = .transient
        popover.animates = true
        popover.appearance = NSAppearance(named: .darkAqua)
        popover.contentViewController = panelViewController
        popover.delegate = self

        panelViewController.onSearchStocks = { [weak self] query in
            self?.searchAssets(query)
        }
        panelViewController.onAddStock = { [weak self] result in
            self?.addAsset(result)
        }
        panelViewController.onToggleVisible = { [weak self] id, visible in
            self?.setAsset(id: id, visibleInMenuBar: visible)
        }
        panelViewController.onRemoveAsset = { [weak self] id in
            self?.removeAsset(id: id)
        }
        panelViewController.onMoveAsset = { [weak self] sourceID, targetID, placeAfterTarget in
            self?.moveAsset(id: sourceID, to: targetID, placeAfterTarget: placeAfterTarget)
        }
        panelViewController.onEditPosition = { [weak self] id in
            self?.editPosition(id: id)
        }
        panelViewController.onColorModeChange = { [weak self] mode in
            self?.setPriceColorMode(mode)
        }
        panelViewController.onStatusBarBackgroundModeChange = { [weak self] mode in
            self?.setStatusBarBackgroundMode(mode)
        }
        panelViewController.onStockDataSourceChange = { [weak self] source in
            self?.setStockDataSource(source)
        }
        panelViewController.onStockChartPeriodChange = { [weak self] period in
            self?.setStockChartPeriod(period)
        }
        panelViewController.onRequestStockChart = { [weak self] assetID in
            self?.requestStockChart(assetID: assetID)
        }
        panelViewController.onLanguageChange = { [weak self] language in
            self?.setLanguage(language)
        }
        panelViewController.onPreferredContentSizeChange = { [weak self] size in
            self?.popover.contentSize = size
            self?.previewWindow?.setContentSize(size)
        }
        panelViewController.onQuit = {
            NSApp.terminate(nil)
        }
    }

    private func showPreviewWindow() {
        _ = panelViewController.view
        let contentSize = panelViewController.preferredContentSize
        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: contentSize),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "CareAssets Preview"
        window.appearance = NSAppearance(named: .darkAqua)
        window.isReleasedWhenClosed = false
        window.contentViewController = panelViewController
        window.center()
        window.makeKeyAndOrderFront(nil)
        previewWindow = window
        NSApp.activate(ignoringOtherApps: true)
    }

    func popoverDidClose(_ notification: Notification) {
        stopPopoverDismissMonitoring()
    }

    @objc private func statusButtonClicked() {
        togglePopover()
    }

    private func togglePopover() {
        guard let button = statusItem?.button else { return }

        if popover.isShown {
            closePopover()
        } else {
            panelViewController.update(
                assets: assets,
                countdown: secondsUntilRefresh,
                isRefreshing: isRefreshing,
                colorMode: config.priceColorMode,
                statusBarBackgroundMode: config.statusBarBackgroundMode,
                stockDataSource: config.stockDataSource,
                stockChartPeriod: config.stockChartPeriod,
                language: config.language
            )
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            startPopoverDismissMonitoring()
            panelViewController.focusSearchFieldIfNeeded()
        }
    }

    private func closePopover() {
        guard popover.isShown else {
            stopPopoverDismissMonitoring()
            return
        }
        popover.performClose(nil)
    }

    private func startPopoverDismissMonitoring() {
        stopPopoverDismissMonitoring()

        let mouseEvents: NSEvent.EventTypeMask = [.leftMouseDown, .rightMouseDown, .otherMouseDown]
        localMouseMonitor = NSEvent.addLocalMonitorForEvents(matching: mouseEvents) { [weak self] event in
            self?.closePopoverIfEventIsOutside(event)
            return event
        }
        globalMouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: mouseEvents) { [weak self] _ in
            DispatchQueue.main.async {
                self?.closePopover()
            }
        }
        resignActiveObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didResignActiveNotification,
            object: NSApp,
            queue: .main
        ) { [weak self] _ in
            self?.closePopover()
        }
    }

    private func stopPopoverDismissMonitoring() {
        if let localMouseMonitor {
            NSEvent.removeMonitor(localMouseMonitor)
            self.localMouseMonitor = nil
        }
        if let globalMouseMonitor {
            NSEvent.removeMonitor(globalMouseMonitor)
            self.globalMouseMonitor = nil
        }
        if let resignActiveObserver {
            NotificationCenter.default.removeObserver(resignActiveObserver)
            self.resignActiveObserver = nil
        }
    }

    private func closePopoverIfEventIsOutside(_ event: NSEvent) {
        guard popover.isShown else { return }
        if event.window?.level == .popUpMenu {
            return
        }
        if let eventWindow = event.window, eventWindow == panelViewController.view.window {
            return
        }
        if isEventInStatusButton(event) {
            return
        }
        closePopover()
    }

    private func isEventInStatusButton(_ event: NSEvent) -> Bool {
        guard let button = statusItem?.button,
              let eventWindow = event.window,
              eventWindow == button.window else {
            return false
        }
        let location = button.convert(event.locationInWindow, from: nil)
        return button.bounds.contains(location)
    }

    @objc private func tick() {
        loadingFrame = (loadingFrame + 1) % 3
        tickerView.loadingFrame = loadingFrame

        guard !isRefreshing else {
            panelViewController.updateRefreshState(countdown: secondsUntilRefresh, isRefreshing: true)
            return
        }

        secondsUntilRefresh -= 1
        if secondsUntilRefresh <= 0 {
            refresh()
        } else {
            panelViewController.updateRefreshState(countdown: secondsUntilRefresh, isRefreshing: false)
        }
    }

    private func refresh() {
        guard !isRefreshing else { return }

        config = ConfigStore.loadOrCreate()
        L10n.appLanguage = config.language
        secondsUntilRefresh = max(10, config.refreshIntervalSeconds)
        isRefreshing = true
        updateViews()

        let currentConfig = config
        Task {
            let fetchedAssets = await service.fetchAssets(config: currentConfig)
            await MainActor.run {
                let fetchedByID = Dictionary(uniqueKeysWithValues: fetchedAssets.map { ($0.id, $0) })
                self.assets = self.config.assets.map { asset in
                    let id = self.key(for: asset)
                    return fetchedByID[id] ?? self.assets.first(where: { $0.id == id }) ?? DisplayAsset.loading(from: asset)
                }
                self.isRefreshing = false
                self.secondsUntilRefresh = max(10, self.config.refreshIntervalSeconds)
                self.updateViews()
            }
        }
    }

    private func updateViews() {
        let menuAssets = visibleMenuAssets()
        tickerView.colorMode = config.priceColorMode
        tickerView.backgroundMode = config.statusBarBackgroundMode
        tickerView.loadingFrame = loadingFrame
        tickerView.items = menuAssets
        statusItem?.length = tickerView.preferredWidth
        if let button = statusItem?.button {
            button.title = ""
            button.image = nil
            button.toolTip = L10n.appTooltip
        }
        panelViewController.update(
            assets: assets,
            countdown: secondsUntilRefresh,
            isRefreshing: isRefreshing,
            colorMode: config.priceColorMode,
            statusBarBackgroundMode: config.statusBarBackgroundMode,
            stockDataSource: config.stockDataSource,
            stockChartPeriod: config.stockChartPeriod,
            language: config.language
        )
    }

    private func visibleMenuAssets() -> [DisplayAsset] {
        assets.filter(\.visibleInMenuBar)
    }

    private func searchAssets(_ query: String) {
        searchRequestID += 1
        let requestID = searchRequestID

        Task {
            do {
                let results = try await service.searchAssets(query: query, stockDataSource: self.config.stockDataSource)
                await MainActor.run {
                    guard requestID == self.searchRequestID else { return }
                    let message = results.isEmpty ? L10n.noSearchResults : nil
                    self.panelViewController.updateSearch(results: results, isSearching: false, message: message)
                }
            } catch {
                await MainActor.run {
                    guard requestID == self.searchRequestID else { return }
                    self.panelViewController.updateSearch(
                        results: [],
                        isSearching: false,
                        message: L10n.searchFailed(error.localizedDescription)
                    )
                }
            }
        }
    }

    private func addAsset(_ result: AssetSearchResult) {
        let asset = result.trackedAsset
        let id = key(for: asset)
        guard !config.assets.contains(where: { key(for: $0) == id }) else {
            updateViews()
            return
        }

        config.assets.append(asset)
        ConfigStore.write(config)
        assets.append(DisplayAsset.loading(from: asset))
        updateViews()
        refresh()
    }

    private func setAsset(id: String, visibleInMenuBar: Bool) {
        guard let configIndex = config.assets.firstIndex(where: { key(for: $0) == id }) else { return }
        config.assets[configIndex].visibleInMenuBar = visibleInMenuBar
        ConfigStore.write(config)

        if let assetIndex = assets.firstIndex(where: { $0.id == id }) {
            assets[assetIndex].visibleInMenuBar = visibleInMenuBar
        }

        updateViews()
    }

    private func removeAsset(id: String) {
        config.assets.removeAll { key(for: $0) == id }
        assets.removeAll { $0.id == id }
        ConfigStore.write(config)
        updateViews()
    }

    private func editPosition(id: String) {
        guard let configIndex = config.assets.firstIndex(where: { key(for: $0) == id }),
              config.assets[configIndex].type == .stock else {
            return
        }

        let result = showPositionEditor(for: config.assets[configIndex])
        switch result {
        case let .save(quantity, averageBuyPrice):
            setPosition(id: id, quantity: quantity, averageBuyPrice: averageBuyPrice)
        case .clear:
            setPosition(id: id, quantity: nil, averageBuyPrice: nil)
        case .invalid:
            showMessageAlert(message: L10n.invalidPositionInput())
        case .cancel:
            break
        }
    }

    private func setPosition(id: String, quantity: Double?, averageBuyPrice: Double?) {
        guard let configIndex = config.assets.firstIndex(where: { key(for: $0) == id }) else { return }

        config.assets[configIndex].holdingQuantity = quantity
        config.assets[configIndex].averageBuyPrice = averageBuyPrice
        ConfigStore.write(config)

        if let assetIndex = assets.firstIndex(where: { $0.id == id }) {
            assets[assetIndex].holdingQuantity = quantity
            assets[assetIndex].averageBuyPrice = averageBuyPrice
        }

        updateViews()
    }

    private func showPositionEditor(for asset: TrackedAsset) -> PositionEditResult {
        let alert = NSAlert()
        alert.messageText = L10n.editPositionTitle(asset.name)
        alert.informativeText = asset.symbol
        alert.alertStyle = .informational
        alert.addButton(withTitle: L10n.save)
        alert.addButton(withTitle: L10n.clear)
        alert.addButton(withTitle: L10n.cancel)

        let quantityField = NSTextField(string: asset.holdingQuantity.map(positionInputText) ?? "")
        quantityField.placeholderString = L10n.quantity
        let averageField = NSTextField(string: asset.averageBuyPrice.map(positionInputText) ?? "")
        averageField.placeholderString = L10n.averageBuyPrice

        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 8
        stack.frame = NSRect(x: 0, y: 0, width: 260, height: 62)
        stack.addArrangedSubview(makePositionInputRow(label: L10n.quantity, field: quantityField))
        stack.addArrangedSubview(makePositionInputRow(label: L10n.averageBuyPrice, field: averageField))
        alert.accessoryView = stack

        let response = alert.runModal()
        if response == .alertSecondButtonReturn {
            return .clear
        }
        if response != .alertFirstButtonReturn {
            return .cancel
        }

        guard let quantity = parsePositiveDecimal(quantityField.stringValue),
              let averageBuyPrice = parsePositiveDecimal(averageField.stringValue) else {
            return .invalid
        }
        return .save(quantity: quantity, averageBuyPrice: averageBuyPrice)
    }

    private func makePositionInputRow(label title: String, field: NSTextField) -> NSView {
        let row = NSStackView()
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 8
        row.widthAnchor.constraint(equalToConstant: 260).isActive = true

        let label = NSTextField(labelWithString: title)
        label.font = appFont(ofSize: 12, weight: .medium)
        label.widthAnchor.constraint(equalToConstant: 92).isActive = true

        field.font = senFont(ofSize: 12)
        field.widthAnchor.constraint(equalToConstant: 160).isActive = true
        row.addArrangedSubview(label)
        row.addArrangedSubview(field)
        return row
    }

    private func showMessageAlert(message: String) {
        let alert = NSAlert()
        alert.messageText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    private func moveAsset(id sourceID: String, to targetID: String, placeAfterTarget: Bool) {
        guard sourceID != targetID,
              let sourceIndex = config.assets.firstIndex(where: { key(for: $0) == sourceID }) else {
            return
        }

        let movedAsset = config.assets.remove(at: sourceIndex)
        guard let targetIndexAfterRemoval = config.assets.firstIndex(where: { key(for: $0) == targetID }) else {
            config.assets.insert(movedAsset, at: sourceIndex)
            return
        }

        let insertionIndex = placeAfterTarget ? targetIndexAfterRemoval + 1 : targetIndexAfterRemoval
        config.assets.insert(movedAsset, at: min(insertionIndex, config.assets.count))
        ConfigStore.write(config)

        let displayAssetsByID = Dictionary(uniqueKeysWithValues: assets.map { ($0.id, $0) })
        assets = config.assets.map { asset in
            displayAssetsByID[key(for: asset)] ?? DisplayAsset.loading(from: asset)
        }
        updateViews()
    }

    private func setPriceColorMode(_ mode: PriceColorMode) {
        config.priceColorMode = mode
        ConfigStore.write(config)
        updateViews()
    }

    private func setStatusBarBackgroundMode(_ mode: StatusBarBackgroundMode) {
        config.statusBarBackgroundMode = mode
        ConfigStore.write(config)
        updateViews()
    }

    private func setStockDataSource(_ source: StockDataSource) {
        config.stockDataSource = source
        ConfigStore.write(config)
        updateViews()
        refresh()
    }

    private func setStockChartPeriod(_ period: StockChartPeriod) {
        config.stockChartPeriod = period
        ConfigStore.write(config)
        updateViews()
    }

    private func requestStockChart(assetID: String) {
        guard config.stockChartPeriod != .off,
              config.stockDataSource != .tencent,
              let asset = config.assets.first(where: { key(for: $0) == assetID && $0.type == .stock }) else {
            return
        }

        let source = config.stockDataSource
        let period = config.stockChartPeriod
        Task {
            do {
                let points = try await service.fetchStockChart(asset, dataSource: source, period: period)
                await MainActor.run {
                    self.panelViewController.updateStockChart(
                        assetID: assetID,
                        dataSource: source,
                        period: period,
                        state: .loaded(points)
                    )
                }
            } catch {
                await MainActor.run {
                    self.panelViewController.updateStockChart(
                        assetID: assetID,
                        dataSource: source,
                        period: period,
                        state: .failed
                    )
                }
            }
        }
    }

    private func setLanguage(_ language: AppLanguage) {
        config.language = language
        L10n.appLanguage = language
        ConfigStore.write(config)
        updateViews()
        refresh()
    }

    private func key(for asset: TrackedAsset) -> String {
        assetIdentity(for: asset)
    }

    private func makeStatusTitle(from assets: [DisplayAsset]) -> String {
        if assets.isEmpty {
            return "CA --"
        }

        let segments = assets.map { asset in
            "\(shortName(for: asset)) \(asset.menuPriceText.replacingOccurrences(of: "¥", with: ""))"
        }
        return "CA " + segments.joined(separator: "  ")
    }

    private func shortName(for asset: DisplayAsset) -> String {
        switch asset.type {
        case .gold:
            return L10n.gold
        case .crypto:
            return asset.name
        case .stock:
            return asset.name
        }
    }
}

// MARK: - Symbol Mapping

private func eastMoneyCanonicalSymbol(for item: EastMoneySearchItem) -> String? {
    if let quoteID = item.quoteID?.uppercased() {
        let parts = quoteID.split(separator: ".", maxSplits: 1).map(String.init)
        if parts.count == 2 {
            switch parts[0] {
            case "116":
                return "HK:\(paddedHongKongCode(parts[1]))"
            case "105", "106", "107":
                return "US:\(parts[1])"
            case "177":
                return "KR:\(parts[1])"
            case "1":
                return "SH:\(parts[1])"
            case "0":
                return "SZ:\(parts[1])"
            default:
                break
            }
        }
    }

    let classify = item.classify?.uppercased() ?? ""
    let exchange = item.exchange?.uppercased() ?? ""
    guard let code = item.code?.trimmingCharacters(in: .whitespacesAndNewlines), !code.isEmpty else {
        return nil
    }
    let uppercased = code.uppercased()

    if classify == "HK" || exchange == "HK" {
        return "HK:\(paddedHongKongCode(uppercased))"
    }
    if classify == "USSTOCK" || ["NASDAQ", "NYSE", "AMEX"].contains(exchange) {
        return "US:\(uppercased)"
    }
    if classify == "KRX" || exchange == "KRX" {
        return "KR:\(uppercased)"
    }
    if classify == "ASTOCK" {
        return uppercased.hasPrefix("6") ? "SH:\(uppercased)" : "SZ:\(uppercased)"
    }
    return nil
}

private func tencentStockSymbol(for asset: TrackedAsset) -> String? {
    let canonical = (asset.canonicalSymbol ?? canonicalAssetSymbol(type: asset.type, symbol: asset.symbol)).uppercased()
    let parts = canonical.split(separator: ":", maxSplits: 1).map(String.init)
    guard parts.count == 2 else { return nil }

    switch parts[0] {
    case "HK":
        return "hk\(paddedHongKongCode(parts[1]))"
    case "US":
        return "us\(parts[1])"
    case "SH":
        return "sh\(parts[1])"
    case "SZ":
        return "sz\(parts[1])"
    default:
        return nil
    }
}

private func eastMoneySecID(for asset: TrackedAsset) -> String? {
    let canonical = (asset.canonicalSymbol ?? canonicalAssetSymbol(type: asset.type, symbol: asset.symbol)).uppercased()
    let parts = canonical.split(separator: ":", maxSplits: 1).map(String.init)
    guard parts.count == 2 else { return nil }

    switch parts[0] {
    case "HK":
        return "116.\(paddedHongKongCode(parts[1]))"
    case "US":
        return "105.\(parts[1])"
    case "KR":
        return "177.\(parts[1])"
    case "SH":
        return "1.\(parts[1])"
    case "SZ":
        return "0.\(parts[1])"
    default:
        return nil
    }
}

private func eastMoneyPriceScale(for item: EastMoneyQuoteItem) -> Double {
    switch item.market {
    case 105, 106, 107, 116:
        return 1000
    default:
        return 100
    }
}

private func yahooStockSymbol(for asset: TrackedAsset) -> String {
    let canonical = (asset.canonicalSymbol ?? canonicalAssetSymbol(type: asset.type, symbol: asset.symbol)).uppercased()
    let parts = canonical.split(separator: ":", maxSplits: 1).map(String.init)
    guard parts.count == 2 else { return asset.symbol }

    switch parts[0] {
    case "HK":
        if let number = Int(parts[1]) {
            return "\(number).HK"
        }
        return "\(parts[1]).HK"
    case "SH":
        return "\(parts[1]).SS"
    case "SZ":
        return "\(parts[1]).SZ"
    case "US":
        return parts[1]
    case "KR":
        let original = asset.symbol.uppercased()
        if original.hasSuffix(".KS") || original.hasSuffix(".KQ") {
            return original
        }
        return parts[1]
    default:
        return asset.symbol
    }
}

private func stockCurrency(for asset: TrackedAsset) -> String {
    let canonical = (asset.canonicalSymbol ?? canonicalAssetSymbol(type: asset.type, symbol: asset.symbol)).uppercased()
    if canonical.hasPrefix("HK:") {
        return "HKD"
    }
    if canonical.hasPrefix("US:") {
        return "USD"
    }
    if canonical.hasPrefix("KR:") {
        return "KRW"
    }
    return "CNY"
}

private func eastMoneyDateString(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(identifier: "Asia/Shanghai")
    formatter.dateFormat = "yyyyMMdd"
    return formatter.string(from: date)
}

private func parseChartDate(_ string: String) -> Date? {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(identifier: "Asia/Shanghai")
    formatter.dateFormat = string.contains(":") ? "yyyy-MM-dd HH:mm" : "yyyy-MM-dd"
    return formatter.date(from: string)
}

private func cryptoBaseSymbol(from symbol: String) -> String {
    let uppercased = symbol.uppercased()
    for quote in ["USDT", "USDC", "USD"] {
        if uppercased.hasSuffix(quote) {
            return String(uppercased.dropLast(quote.count))
        }
    }
    return uppercased
}

private func parseTencentDate(_ string: String?) -> Date? {
    guard let string, !string.isEmpty else { return nil }
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(identifier: "Asia/Shanghai")

    for format in ["yyyy/MM/dd HH:mm:ss", "yyyy-MM-dd HH:mm:ss", "yyyyMMddHHmmss"] {
        formatter.dateFormat = format
        if let date = formatter.date(from: string) {
            return date
        }
    }
    return nil
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Formatting

private func parsePercent(_ string: String?) -> Double? {
    guard let string else { return nil }
    return Double(
        string
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "%", with: "")
    )
}

private func meaningfulPercent(_ string: String?) -> Double? {
    parsePercent(string).flatMap { abs($0) > 0.0001 ? $0 : nil }
}

private func positiveDouble(_ string: String?) -> Double? {
    guard let value = string.flatMap(Double.init), value > 0 else { return nil }
    return value
}

private func meaningfulChange(_ string: String?) -> Double? {
    guard let value = string.flatMap(Double.init), abs(value) > 0.0001 else { return nil }
    return value
}

private func parseMillisecondsDate(_ string: String?) -> Date? {
    guard let string, let milliseconds = Double(string) else { return nil }
    return Date(timeIntervalSince1970: milliseconds / 1000.0)
}

private func parseLocalDateTime(_ string: String?) -> Date? {
    guard let string, !string.isEmpty else { return nil }
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(identifier: "Asia/Shanghai")
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    return formatter.date(from: string)
}

private func parseISO8601Date(_ string: String?) -> Date? {
    guard let string else { return nil }

    let fractionalFormatter = ISO8601DateFormatter()
    fractionalFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    if let date = fractionalFormatter.date(from: string) {
        return date
    }

    return ISO8601DateFormatter().date(from: string)
}

private func latestDate(_ lhs: Date?, _ rhs: Date?) -> Date? {
    switch (lhs, rhs) {
    case let (left?, right?):
        return max(left, right)
    case let (left?, nil):
        return left
    case let (nil, right?):
        return right
    case (nil, nil):
        return nil
    }
}

private func formatNumber(_ value: Double, minFraction: Int, maxFraction: Int, usesGroupingSeparator: Bool = true) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.usesGroupingSeparator = usesGroupingSeparator
    formatter.minimumFractionDigits = minFraction
    formatter.maximumFractionDigits = maxFraction
    return formatter.string(from: NSNumber(value: value)) ?? String(format: "%.\(maxFraction)f", value)
}

private func formatStatusNumber(_ value: Double, minFraction: Int, maxFraction: Int) -> String {
    formatNumber(value, minFraction: minFraction, maxFraction: maxFraction, usesGroupingSeparator: false)
}

private func positionInputText(_ value: Double) -> String {
    formatNumber(value, minFraction: 0, maxFraction: 6, usesGroupingSeparator: false)
}

private func parsePositiveDecimal(_ string: String) -> Double? {
    let normalized = string
        .trimmingCharacters(in: .whitespacesAndNewlines)
        .replacingOccurrences(of: ",", with: "")
    guard let value = Double(normalized), value > 0 else {
        return nil
    }
    return value
}

private func formatCompact(_ value: Double) -> String {
    let absolute = abs(value)
    if absolute >= 1_000_000 {
        return "\(formatNumber(value / 1_000_000, minFraction: 1, maxFraction: 1))M"
    }
    if absolute >= 10_000 {
        return "\(formatNumber(value / 1_000, minFraction: 1, maxFraction: 1))K"
    }
    if absolute >= 1_000 {
        return "\(formatNumber(value / 1_000, minFraction: 1, maxFraction: 1))K"
    }
    if absolute >= 100 {
        return formatNumber(value, minFraction: 0, maxFraction: 1)
    }
    return formatNumber(value, minFraction: 2, maxFraction: 2)
}

private func formatCNY(_ value: Double, compact: Bool) -> String {
    formatCurrency(value, currencyCode: "CNY", compact: compact)
}

private func formatCurrency(_ value: Double, currencyCode: String, compact: Bool) -> String {
    let symbol = currencySymbol(for: currencyCode)
    if compact {
        return "\(symbol)\(formatCompact(value))"
    }
    let number = formatNumber(value, minFraction: 2, maxFraction: 2)
    if symbol.isEmpty {
        return "\(number) \(currencyCode.uppercased())"
    }
    return "\(symbol)\(number)"
}

private func formatCurrencyWithCode(_ value: Double, currencyCode: String, compact: Bool) -> String {
    let number = compact
        ? formatCompact(value)
        : formatNumber(value, minFraction: 2, maxFraction: 2)
    return "\(number) \(currencyCode.uppercased())"
}

private func formatSignedCurrency(_ value: Double, currencyCode: String, compact: Bool = false) -> String {
    let sign = value > 0 ? "+" : value < 0 ? "-" : ""
    let symbol = currencySymbol(for: currencyCode)
    let number = compact
        ? formatCompact(abs(value))
        : formatNumber(abs(value), minFraction: 2, maxFraction: 2)
    if symbol.isEmpty {
        return "\(sign)\(number) \(currencyCode.uppercased())"
    }
    return "\(sign)\(symbol)\(number)"
}

private func formatSignedCurrencyWithCode(_ value: Double, currencyCode: String, compact: Bool = false) -> String {
    let sign = value > 0 ? "+" : value < 0 ? "-" : ""
    let number = compact
        ? formatCompact(abs(value))
        : formatNumber(abs(value), minFraction: 2, maxFraction: 2)
    return "\(sign)\(number) \(currencyCode.uppercased())"
}

private func currencySymbol(for currencyCode: String) -> String {
    switch currencyCode.uppercased() {
    case "CNY", "CNH", "JPY":
        return "¥"
    case "HKD":
        return "HK$"
    case "USD":
        return "$"
    case "EUR":
        return "€"
    case "GBP":
        return "£"
    default:
        return ""
    }
}

private func formatChange(amount: Double?, percent: Double?, currencyPrefix: String) -> String {
    let amountText: String
    if let amount {
        let sign = amount > 0 ? "+" : ""
        amountText = "\(sign)\(currencyPrefix)\(formatNumber(amount, minFraction: 2, maxFraction: 2))"
    } else {
        amountText = "--"
    }

    let percentText: String
    if let percent {
        let sign = percent > 0 ? "+" : ""
        percentText = "\(sign)\(formatNumber(percent, minFraction: 2, maxFraction: 2))%"
    } else {
        percentText = "--"
    }

    return "\(amountText) · \(percentText)"
}

private func formatPercent(_ percent: Double?) -> String {
    guard let percent else {
        return "--"
    }
    let sign = percent > 0 ? "+" : ""
    return "\(sign)\(formatNumber(percent, minFraction: 2, maxFraction: 2))%"
}

private func priceColor(for asset: DisplayAsset, mode: PriceColorMode, whiteAlpha: CGFloat, errorAlpha: CGFloat) -> NSColor {
    if asset.errorMessage != nil {
        return NSColor.white.withAlphaComponent(errorAlpha)
    }

    return priceColor(for: asset.changePercent, mode: mode, whiteAlpha: whiteAlpha)
}

private func priceColor(for percent: Double?, mode: PriceColorMode, whiteAlpha: CGFloat) -> NSColor {
    let white = NSColor.white.withAlphaComponent(whiteAlpha)
    guard let percent, percent != 0 else {
        return white
    }

    let red = NSColor(calibratedRed: 1.0, green: 0.30, blue: 0.34, alpha: 1)
    let green = NSColor(calibratedRed: 0.35, green: 0.86, blue: 0.48, alpha: 1)

    switch mode {
    case .white:
        return white
    case .redRiseGreenFall:
        return percent > 0 ? red : green
    case .redFallGreenRise:
        return percent > 0 ? green : red
    }
}

private func appLogoImage() -> NSImage? {
    let bundle = Bundle.main
    for resource in [("AppLogo", "png"), ("AppLogo", "svg"), ("AppIcon", "svg"), ("CareAssets", "icns")] {
        guard let url = bundle.url(forResource: resource.0, withExtension: resource.1),
              let image = NSImage(contentsOf: url) else {
            continue
        }
        image.isTemplate = false
        return image
    }
    return nil
}

private func appFont(ofSize size: CGFloat, weight: NSFont.Weight = .regular) -> NSFont {
    for name in ["TeX Gyre Adventor", "TeXGyreAdventor", "Didact Gothic"] {
        guard let font = NSFont(name: name, size: size) else { continue }
        if [.semibold, .bold, .heavy, .black].contains(weight) {
            return NSFontManager.shared.convert(font, toHaveTrait: .boldFontMask)
        }
        return font
    }

    return NSFont.systemFont(ofSize: size, weight: weight)
}

private func senFont(ofSize size: CGFloat) -> NSFont {
    for name in ["Sen-Medium", "Sen Medium", "Sen"] {
        if let font = NSFont(name: name, size: size) {
            return font
        }
    }
    return NSFont.systemFont(ofSize: size, weight: .medium)
}

private func mixedAttributedString(
    _ text: String,
    baseFont: NSFont,
    asciiFont: NSFont,
    color: NSColor,
    paragraphStyle: NSParagraphStyle? = nil
) -> NSAttributedString {
    var attributes: [NSAttributedString.Key: Any] = [
        .font: baseFont,
        .foregroundColor: color
    ]
    if let paragraphStyle {
        attributes[.paragraphStyle] = paragraphStyle
    }

    let attributed = NSMutableAttributedString(string: text, attributes: attributes)
    var location = 0
    for character in text {
        let characterString = String(character)
        let length = (characterString as NSString).length
        if usesSenFont(character) {
            attributed.addAttribute(.font, value: asciiFont, range: NSRange(location: location, length: length))
        }
        location += length
    }
    return attributed
}

private func usesSenFont(_ character: Character) -> Bool {
    character.unicodeScalars.allSatisfy { scalar in
        scalar.value >= 0x20 && scalar.value <= 0x7E
    }
}

private func errorAsset(_ asset: TrackedAsset, source: String, message: String) -> DisplayAsset {
    DisplayAsset(
        id: assetIdentity(for: asset),
        type: asset.type,
        name: asset.name,
        symbol: asset.symbol,
        canonicalSymbol: asset.canonicalSymbol,
        source: source,
        currentPrice: nil,
        currency: nil,
        menuPriceText: "--",
        priceText: "--",
        detailText: source,
        changeText: "--",
        changePercent: nil,
        updatedAt: nil,
        holdingQuantity: asset.holdingQuantity,
        averageBuyPrice: asset.averageBuyPrice,
        visibleInMenuBar: asset.visibleInMenuBar,
        errorMessage: message
    )
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.setActivationPolicy(.accessory)
app.delegate = delegate
app.run()
