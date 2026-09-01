import Testing
@testable import CoinCurrently

@Suite("Home carousel default")
struct HomeCarouselDefaultTests {

    @Test("opens on Favorites when the user has favorites")
    func favoritesWhenListIsNonEmpty() {
        #expect(CarouselFilter.defaultHomeFilter(hasFavorites: true) == .favorites)
    }

    @Test("opens on Top Coins when the user has no favorites")
    func topCoinsWhenListIsEmpty() {
        #expect(CarouselFilter.defaultHomeFilter(hasFavorites: false) == .topCoins)
    }
}
