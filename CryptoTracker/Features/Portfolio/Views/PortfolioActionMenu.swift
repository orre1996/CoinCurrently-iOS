//
//  PortfolioActionMenu.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 9/2/26.
//

import SwiftUI
import UIKit

struct PortfolioActionMenu: View {
    @Environment(NavigationViewModel.self) private var navigationViewModel
    @ScaledMetric private var scale: CGFloat = 1
    @AccessibilityFocusState private var actionMenuFocus: ActionMenuFocus?

    @Bindable var viewModel: PortfolioViewModelImp
    @Binding var isActionMenuExpanded: Bool
    @Binding var isTransactionTypeSheetShowing: Bool
    @Binding var isExportFormatSheetShowing: Bool
    @Binding var isBenchmarkCoinSelectorShowing: Bool

    private enum ActionMenuFocus: Hashable {
        case addTransaction
        case importWallet
        case exportPortfolio
        case benchmark
        case removeBenchmark
        case fab
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            if isActionMenuExpanded {
                Color.black.opacity(0.00001)
                    .ignoresSafeArea()
                    .onTapGesture {
                        isActionMenuExpanded = false
                    }
            }

            VStack(alignment: .trailing, spacing: 8) {
                if isActionMenuExpanded {
                    PrimaryButton(
                        text: Localization.string("Add Transaction"),
                        action: {
                            Task {
                                let hasPro = await viewModel.hasBoughtPro()
                                if (viewModel.portfolio?.allTransactionsCount ?? 0) >= 3 && !hasPro {
                                    AnalyticsManager.shared.log(
                                        BuyProOpened(fromScreen: .portfolio, action: .AddTransaction)
                                    )
                                    showBuyPro()
                                } else {
                                    AnalyticsManager.shared.log(
                                        SheetOpened(fromScreen: .portfolio, sheet: .portfolioAddTransactionType)
                                    )
                                    isTransactionTypeSheetShowing = true
                                }
                            }

                            isActionMenuExpanded = false
                        }
                    )
                    .padding(.trailing, 16)
                    .transition(.move(edge: .trailing))
                    .accessibilityFocused($actionMenuFocus, equals: .addTransaction)
                    .onAppear {
                        focusAddTransactionButton()
                    }

                    PrimaryButton(
                        text: Localization.string("Import Wallet (Pro)"),
                        action: {
                            isActionMenuExpanded = false

                            Task {
                                if await viewModel.hasBoughtPro() {
                                    AnalyticsManager.shared.log(
                                        Navigate(fromScreen: .portfolio, toScreen: .newImportTransaction)
                                    )
                                    navigationViewModel.navPath.append(
                                        NavigationScreens.ImportWalletTransaction
                                    )
                                } else {
                                    AnalyticsManager.shared.log(
                                        BuyProOpened(fromScreen: .portfolio, action: .ImportWallet)
                                    )
                                    navigationViewModel.showBuyPro = true
                                }
                            }
                        }
                    )
                    .padding(.trailing, 16)
                    .transition(.move(edge: .trailing))
                    .accessibilityLabel(Localization.string("Import wallet, pro feature"))
                    .accessibilityFocused($actionMenuFocus, equals: .importWallet)

                    PrimaryButton(
                        text: Localization.string("Export Portfolio"),
                        action: {
                            isActionMenuExpanded = false

                            guard (viewModel.portfolio?.allTransactionsCount ?? 0) > 0 else { return }

                            AnalyticsManager.shared.log(
                                SheetOpened(fromScreen: .portfolio, sheet: .portfolioExportFormat)
                            )
                            isExportFormatSheetShowing = true
                        }
                    )
                    .padding(.trailing, 16)
                    .transition(.move(edge: .trailing))
                    .disabled((viewModel.portfolio?.allTransactionsCount ?? 0) == 0)
                    .accessibilityLabel(Localization.string("Export portfolio"))
                    .accessibilityFocused($actionMenuFocus, equals: .exportPortfolio)

                    PrimaryButton(
                        text: viewModel.benchmarkCoin == nil
                            ? Localization.string("Benchmark")
                            : Localization.format("Benchmark (%@)", viewModel.benchmarkCoin?.symbol?.uppercased() ?? ""),
                        action: {
                            isActionMenuExpanded = false

                            AnalyticsManager.shared.log(
                                SheetOpened(fromScreen: .portfolio, sheet: .coinSearch)
                            )
                            isBenchmarkCoinSelectorShowing = true
                        }
                    )
                    .padding(.trailing, 16)
                    .transition(.move(edge: .trailing))
                    .accessibilityLabel(
                        viewModel.benchmarkCoin == nil
                            ? Localization.string("Benchmark portfolio")
                            : Localization.format("Change benchmark, currently %@", viewModel.benchmarkCoin?.name ?? "")
                    )
                    .accessibilityFocused($actionMenuFocus, equals: .benchmark)

                    if viewModel.benchmarkCoin != nil {
                        PrimaryButton(
                            text: Localization.string("Remove Benchmark"),
                            action: {
                                isActionMenuExpanded = false
                                viewModel.clearBenchmark()
                            }
                        )
                        .padding(.trailing, 16)
                        .transition(.move(edge: .trailing))
                        .accessibilityLabel(Localization.string("Remove benchmark"))
                        .accessibilityFocused($actionMenuFocus, equals: .removeBenchmark)
                    }
                }

                Button(action: {
                    if isActionMenuExpanded {
                        isActionMenuExpanded = false
                    } else {
                        isActionMenuExpanded = true
                        focusAddTransactionButton()
                    }
                }, label: {
                    Image.plus
                        .resizable()
                        .frame(width: 24 * min(scale, 1.5), height: 24 * min(scale, 1.5))
                        .foregroundStyle(isActionMenuExpanded ? Color.onSurfaceContainerDim : Color.onPrimary)
                        .padding(16)
                        .optionalGlassEffect(
                            color: isActionMenuExpanded ? Color.surfaceContainerHighest : Color.primary,
                            radius: 1000,
                            isInteractive: true
                        )
                        .padding(
                            EdgeInsets(
                                top: 0,
                                leading: 0,
                                bottom: 16,
                                trailing: 16
                            )
                        )
                })
                .accessibilityLabel(Localization.string(isActionMenuExpanded ? "Close add menu" : "Add portfolio item"))
                .accessibilityHint(
                    isActionMenuExpanded
                        ? ""
                        : Localization.string("Shows add transaction, import wallet, export portfolio, and benchmark options")
                )
                .accessibilityFocused($actionMenuFocus, equals: .fab)
                .shadow(color: .black.opacity(0.08), radius: 2, y: 1)
                .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        .animation(.default, value: isActionMenuExpanded)
        .onChange(of: actionMenuFocus) { old, new in
            if old == .removeBenchmark && new != .benchmark {
                isActionMenuExpanded = false
            } else if old == .benchmark && new != .exportPortfolio && new != .removeBenchmark {
                isActionMenuExpanded = false
            } else if old == .exportPortfolio && new != .importWallet && new != .benchmark {
                isActionMenuExpanded = false
            } else if old == .importWallet && new != .addTransaction && new != .exportPortfolio {
                isActionMenuExpanded = false
            }
        }
    }

    private func focusAddTransactionButton() {
        asyncMain(delay: 0.35) {
            actionMenuFocus = .addTransaction
            UIAccessibility.post(notification: .layoutChanged, argument: nil)
        }
    }
}
