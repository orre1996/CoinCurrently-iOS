//
//  ExchangeModel.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2021-05-25.
//

import Foundation

struct ExchangeModel: Codable, Equatable, Hashable {
    var id: String? = nil
    var name: String? = nil
    var year_established: Int? = nil
    var country: String? = nil
    var description: String? = nil
    var url: String? = nil
    var image: String? = nil
    var facebook_url: String? = nil
    var reddit_url: String? = nil
    var telegram_url: String? = nil
    var slack_url: String? = nil
    var other_url_1: String? = nil
    var other_url_2: String? = nil
    var twitter_handle: String? = nil
    var has_trading_incentive: Bool? = nil
    var centralized: Bool? = nil
    var public_notice: String? = nil
    var alert_notice: String? = nil
    var trust_score: Int? = nil
    var trust_score_rank: Int? = nil
    var trade_volume_24h_btc: Double? = nil
    var trade_volume_24h_btc_normalized: Double? = nil
    var coins: Int? = nil
    var pairs: Int? = nil
    var tickers: [ExchangeTicker]? = nil
    
    var toExchange: Exchange {
        return Exchange(
            id: id,
            name: name,
            year_established: year_established,
            country: country,
            description: description,
            url: url,
            image: image,
            facebook_url: facebook_url,
            reddit_url: reddit_url,
            telegram_url: telegram_url,
            slack_url: slack_url,
            other_url_1: other_url_1,
            other_url_2: other_url_2,
            twitter_handle: twitter_handle,
            has_trading_incentive: has_trading_incentive,
            centralized: centralized,
            public_notice: public_notice,
            alert_notice: alert_notice,
            trust_score: trust_score,
            trust_score_rank: trust_score_rank,
            trade_volume_24h_btc: trade_volume_24h_btc,
            trade_volume_24h_btc_normalized: trade_volume_24h_btc_normalized,
            status_updates: nil,
            coins: coins,
            pairs: pairs,
            tickers: tickers
        )
    }
}

struct Exchange: Codable, Equatable, Hashable {
    var id: String? = nil
    var name: String? = nil
    var year_established: Int? = nil
    var country: String? = nil
    var description: String? = nil
    var url: String? = nil
    var image: String? = nil
    var facebook_url: String? = nil
    var reddit_url: String? = nil
    var telegram_url: String? = nil
    var slack_url: String? = nil
    var other_url_1: String? = nil
    var other_url_2: String? = nil
    var twitter_handle: String? = nil
    var has_trading_incentive: Bool? = nil
    var centralized: Bool? = nil
    var public_notice: String? = nil
    var alert_notice: String? = nil
    var trust_score: Int? = nil
    var trust_score_rank: Int? = nil
    var trade_volume_24h_btc: Double? = nil
    var trade_volume_24h_btc_normalized: Double? = nil
    var status_updates: [Status]? = nil
    var coins: Int? = nil
    var pairs: Int? = nil
    var tickers: [ExchangeTicker]? = nil
    
    func copy(withId: String) -> Exchange {
        return Exchange(
            id: withId,
            name: name,
            year_established: year_established,
            country: country,
            description: description,
            url: url,
            image: image,
            facebook_url: facebook_url,
            reddit_url: reddit_url,
            telegram_url: telegram_url,
            slack_url: slack_url,
            other_url_1: other_url_1,
            other_url_2: other_url_2,
            twitter_handle: twitter_handle,
            has_trading_incentive: has_trading_incentive,
            centralized: centralized,
            public_notice: public_notice,
            alert_notice: alert_notice,
            trust_score: trust_score,
            trust_score_rank: trust_score_rank,
            trade_volume_24h_btc: trade_volume_24h_btc,
            trade_volume_24h_btc_normalized: trade_volume_24h_btc_normalized,
            status_updates: status_updates,
            coins: coins,
            pairs: pairs,
            tickers: tickers
        )
    }
}

struct ExchangeTicker: Codable, Equatable, Hashable {
    var base: String? = nil
    var target: String? = nil
    var market: ExchangeTickerMarket? = nil
    var last: Double? = nil
    var volume: Double? = nil
    var cost_to_move_up_usd: Double? = nil
    var cost_to_move_down_usd: Double? = nil
    var converted_last: ExchangeTickerConverted? = nil
    var converted_volume: ExchangeTickerConverted? = nil
    var trust_score: String? = nil
    var bid_ask_spread_percentage: Double? = nil
    var timestamp: String? = nil
    var last_traded_at: String? = nil
    var last_fetch_at: String? = nil
    var is_anomaly: Bool? = nil
    var is_stale: Bool? = nil
    var trade_url: String? = nil
    var token_info_url: String? = nil
    var coin_id: String? = nil
    var target_coin_id: String? = nil
}

struct ExchangeTickerMarket: Codable, Equatable, Hashable {
    var name: String? = nil
    var identifier: String? = nil
    var has_trading_incentive: Bool? = nil
    var logo: String? = nil
}

struct ExchangeTickerConverted: Codable, Equatable, Hashable {
    var btc: Double? = nil
    var eth: Double? = nil
    var usd: Double? = nil
}

struct ExchangeVolume: Codable {
    let volume: [[Int]]?
}

struct Status: Codable, Equatable, Hashable {
    let description: String?
    let category: String?
    let created_at: String?
}
