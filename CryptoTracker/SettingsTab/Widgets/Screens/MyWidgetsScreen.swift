//
//  MyWidgetsScreen.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2021-05-27.
//

import SwiftUI
import UniformTypeIdentifiers

struct MyWidgetsScreen: View {
    @Environment(\.accessibilityVoiceOverEnabled) private var accessibilityVoiceOverEnabled
    @Environment(\.presentationMode) private var presentationMode
    
    @Environment(NavigationViewModel.self) private var navigationViewModel
    
    @ScaledMetric private var scale: CGFloat = 1

    @State var viewModel = MyWidgetsViewModelImp()

    @State private var isEditMode: EditMode = .active
    @State private var draggedItem: Toplist?
    @State private var showInfoSheet = false
    
    var body: some View {
        ZStack {
            Color.surface
                .ignoresSafeArea()
            
            ScrollView(.vertical) {
                VStack(alignment: .center, spacing: 4) {
                    if viewModel.widgetCurrencies.isEmpty{
                        emptyView
                    } else {
                        list
                            .scrollDisabled(true)
                    }
                }
                .ignoresSafeArea(edges: .bottom)
                .padding(
                    EdgeInsets(
                        top: 24,
                        leading: 16,
                        bottom: 24,
                        trailing: 16
                    )
                )
            }
        }
        .navigationBarTitle("Widgets", displayMode: .inline)
        .toolbar {
            Button(action: {
                AnalyticsManager.shared.log(
                    SheetOpened(fromScreen: .widgets, sheet: .widgetsHelp)
                )
                showInfoSheet = true
            }, label: {
                Image.info
            })
            .accessibilityLabel("Help understand how widgets work")
        }
        .task {
            await viewModel.setStartData()
        }
        .sheet(isPresented: $showInfoSheet) {
            WidgetsHelpSheet()
        }
    }
    
    @ViewBuilder
    private var list: some View {
        ForEach(viewModel.widgetCurrencies, id: \.self) { currentCurrency in
            WidgetListView(
                currency: currentCurrency,
                deleteAction: {
                    AnalyticsManager.shared.log(
                        WidgetDeleted(fromScreen: .widgets, coinName: currentCurrency.name ?? "")
                    )
                    Task {
                        await viewModel.deleteCoin(coin: currentCurrency)
                    }
                },
                selectAction: {
                    draggedItem = currentCurrency
                },
                dragProvider: {
                    draggedItem = currentCurrency
                    return NSItemProvider(item: nil, typeIdentifier: currentCurrency.id ?? "")
                }
            )
            .onDrop(of: [UTType.item],
                    delegate: DragDropHelper(
                        item: currentCurrency,
                        items: $viewModel.widgetCurrencies,
                        draggedItem: $draggedItem,
                        orderChanged: { widgetItems in
                            AnalyticsManager.shared.log(
                                WidgetOrderChanged(fromScreen: .widgets)
                            )
                            Task {
                                await viewModel.widgetCurrenciesChangedOrder(newOrder: widgetItems)
                            }
                        }
                    )
            )
        }
    }
    
    private var emptyView: some View {
        EmptyContent(
            title: "Track prices without opening the app",
            subTitle: "Open any coin's detail page and tap \"Add to Widget\" from the menu.",
            buttonTitle: "Explore Coins",
            buttonAction: {
                NotificationCenter.default.post(
                    name: .changeMarketPage,
                    object: nil,
                    userInfo: ["page": 0]
                )
                
                navigationViewModel.navPath.removeLast()
                navigationViewModel.selectedTab = 2
            }
        )
        .padding(
            EdgeInsets(
                top: 40,
                leading: 16,
                bottom: 40,
                trailing: 16
            )
        )
    }
}
