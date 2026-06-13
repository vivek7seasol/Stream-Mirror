//
//  IPTVView.swift
//  Stream Mirror
//
//  Created by Vivek Rakholiya on 13/06/26.
//

import SwiftUI

struct IPTVView: View {
    
    @EnvironmentObject var commonVM: CommonConnectionViewModel
    @EnvironmentObject var TVRemoteVM: RemoteViewModel
    @StateObject private var iptvVM = IPTVViewModel()
    @FocusState private var isSearchFocused: Bool
    
    var filteredCountries: [IPTVCountryModelElement] {
        
        if iptvVM.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return iptvVM.countries
        }
        
        return iptvVM.countries.filter {
            ($0.country ?? "")
                .localizedCaseInsensitiveContains(iptvVM.text)
        }
    }

    var filteredCategories: [IPTVCategoryModelElement] {
        
        if iptvVM.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return iptvVM.categories
        }
        
        return iptvVM.categories.filter {
            ($0.category ?? "")
                .localizedCaseInsensitiveContains(iptvVM.text)
        }
    }
    
    var body: some View {
        ZStack {
            VStack {
                CommonStatusView(title: str.IPTV,onCast: {
                    
                })
                
                HStack(spacing:15) {
                    Button {
                        iptvVM.selectedType = .country
                    } label: {
                        ZStack {
                            Text(str.Countries)
                                .font(.system(size: 14,weight: .medium))
                                .foregroundStyle(iptvVM.selectedType == .country ? AppColor.textColor2 : .white)
                        }
                        .padding(.horizontal,30)
                        .frame(height: isIpad() ? 60 : 40)
                        .background(iptvVM.selectedType == .country ? .white : .clear)
                        .modifier(GlassCardModifier(cornerRadius: isIpad() ? 30 : 20))
                    } 
                    .buttonStyle(.plain)
                    
                    Button {
                        iptvVM.selectedType = .category
                    } label: {
                        ZStack {
                            Text(str.Categories)
                                .font(.system(size: 14,weight: .medium))
                                .foregroundStyle(iptvVM.selectedType == .category ? AppColor.textColor2 : .white)
                        }
                        .padding(.horizontal,30)
                        .frame(height: isIpad() ? 60 : 40)
                        .background(iptvVM.selectedType == .category ? .white : .clear)
                        .modifier(GlassCardModifier(cornerRadius: isIpad() ? 30 : 20))
                    }
                    .buttonStyle(.plain)

                }
                
                ZStack {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .resizable()
                            .foregroundStyle(AppColor.textColor)
                            .frame(width: 18, height: 18)
                        
                        TextField("", text: $iptvVM.text, prompt: Text(str.Search).foregroundColor(AppColor.textColor))
                            .foregroundColor(.white)
                            .focused($isSearchFocused)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .frame(maxWidth: .infinity)
                    }
                    .padding()
                }
                .frame(maxWidth: .infinity)
                .frame(height: isIpad() ? 70 : 50)
                .modifier(GlassCardModifier(cornerRadius: isIpad() ? 35 : 25))
                .padding(.horizontal, 15)
                .padding(.top, 10)
                
                if iptvVM.selectedType == .country && filteredCountries.isEmpty {

                    Spacer()

                    placeholderView(
                        image: "countryPH",
                        title: str.NoCountriesFound,
                        title2: "",
                        isTitle2: false,height: 110,width: 130
                    )

                    Spacer()

                } else if iptvVM.selectedType == .category && filteredCategories.isEmpty {

                    Spacer()

                    placeholderView(
                        image: "categoryPH",
                        title: str.NoCategoriesFound,
                        title2: "",
                        isTitle2: false,height: 110,width: 130
                    )

                    Spacer()
                } else {
                    ScrollView(.vertical,showsIndicators: false) {
                        if iptvVM.selectedType == .country {
                            
                            ForEach(filteredCountries, id: \.self) { country in
                                
                                catCountryCard(
                                    title: country.country ?? "Unknown",
                                    channel: "\(country.channels?.count ?? 0)", action: {
                                        iptvVM.selectedChannels = country.channels ?? []
                                        iptvVM.selectedTitle = country.country ?? "Channels"
                                        iptvVM.showChannelList = true
                                    }
                                )
                            }
                        } else {
                            if iptvVM.selectedType == .category {
                                ForEach(filteredCategories, id: \.self) { category in
                                    
                                    catCountryCard(
                                        title: category.category ?? "Unknown",
                                        channel: "\(category.channels?.count ?? 0)", action: {
                                            iptvVM.selectedChannels = category.channels ?? []
                                            iptvVM.selectedTitle = category.category ?? "Channels"
                                            iptvVM.showChannelList = true
                                        }
                                    )
                                }
                            }
                        }
                    }
                    .padding(.top,10)
                }
            }
        }
        .appScreen()
        .onTapGesture {
            hideKeyboard()
        }
        .onAppear {
            
            Task {
                
                iptvVM.isLoadings = true
                
                async let countries = iptvVM.fetchIPTVCountry()
                async let categories = iptvVM.fetchIPTVCategory()
                
                _ = await (countries, categories)
                
                await MainActor.run {
                    iptvVM.isLoadings = false
                }
            }
        }
        .navigationDestination(isPresented: $iptvVM.showChannelList) {
            
            IPTVChannelView(
                title: iptvVM.selectedTitle,
                channels: iptvVM.selectedChannels
            )
            .environmentObject(TVRemoteVM)
            .environmentObject(commonVM)
        }
    }
}

#Preview {
    IPTVView()
}
