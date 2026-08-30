import Testing
@testable import CoinCurrently

@Suite("Analytics event names")
struct AnalyticsEventContractTests {

    @Test("search uses the shared event name and search_term parameter")
    func searchEventName() {
        #expect(SearchPerformed.eventName == "search")
        let parameters = SearchPerformed(fromScreen: .toplist, query: "btc").parameters
        #expect(parameters?["search_term"] as? String == "btc")
        #expect(parameters?.keys.contains("query") != true)
    }

    @Test("main tab switches use tab_switched with from_tab and to_tab")
    func tabSwitchedEventName() {
        #expect(TabSwitched.eventName == "tab_switched")
        let parameters = TabSwitched(fromTab: .home, toTab: .market).parameters
        #expect(parameters?["from_tab"] as? String == "Home")
        #expect(parameters?["to_tab"] as? String == "Market")
    }

    @Test("inner segments use tab_changed")
    func tabChangedEventName() {
        #expect(TabChanged.eventName == "tab_changed")
    }
}
