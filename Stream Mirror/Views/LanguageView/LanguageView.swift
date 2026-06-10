//
//  LanguageView.swift
//  Stream Mirror
//
//  Created by Vivek Rakholiya on 10/06/26.
//

import SwiftUI

struct LanguageModel {
    var name: String
    var code: String
    var lan: String
}

var arrLanguage: [LanguageModel] = [
    .init(name: "English",   code: "en", lan: "English"),
    .init(name: "Hindi",     code: "hi", lan: "हिन्दी"),
    .init(name: "German",    code: "de", lan: "Deutsch"),
    .init(name: "Portuguese", code: "pt-PT", lan: "Português"),
    .init(name: "Italian",   code: "it", lan: "Italiano"),
    .init(name: "Spanish",   code: "es", lan: "Español"),
    .init(name: "Danish",    code: "da", lan: "dansk"),
    .init(name: "Turkish",   code: "tr", lan: "Türkçe"),
    .init(name: "Chinese",   code: "zh-Hant", lan: "繁體中文"),
    .init(name: "Russian",   code: "ru", lan: "Русский"),
    .init(name: "Japanese",  code: "ja", lan: "日本語"),
    .init(name: "Dutch",     code: "nl", lan: "Nederlands"),
    .init(name: "Korean",    code: "ko", lan: "한국인"),
    .init(name: "French",    code: "fr", lan: "Français"),
]

struct LanguageView: View {
    
    @AppStorage(SessionKeys.language) var language = false
    @AppStorage(SessionKeys.appLanguage) var appLanguage : String = "en"
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedLanguage: String = "en"
    @State private var navigateToIntro = false
    var isOpenFromSplash: Bool = false
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        ZStack {
            VStack {
                HStack {
                    VStack(alignment:.leading,spacing: 5) {
                        Text(str.SelectLanguage)
                            .font(.system(size: 24,weight: .bold))
                            .foregroundStyle(.white)
                        
                        Text(str.Selectyourpreferredlanguagebelow)
                            .font(.system(size: 14))
                            .foregroundStyle(AppColor.textColor)
                    }
                    Spacer()
                    
                    Button {
                        guard !selectedLanguage.isEmpty else { return }
                        
                        language = true
                        appLanguage = selectedLanguage
                        
                        LocalizationHelper.shared.setLanguage(code: selectedLanguage)
                        onLanguageChanged()
                        if isOpenFromSplash {
                            navigateToIntro = true
                        } else {
                            dismiss()
                        }
                    } label: {
                        ZStack {
                            Text(str.Done)
                                .font(.system(size: 14,weight: .medium))
                                .foregroundStyle(AppColor.textColor2)
                        }
                        .padding(.horizontal,15)
                        .frame(height: 34)
                        .background(.white)
                        .modifier(GlassCardModifier(cornerRadius: 17))
                        .clipShape(RoundedRectangle(cornerRadius: 17))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal,15)
                
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(arrLanguage, id: \.code) { item in
                            langaugeRow(
                                lang: item,
                                isSelected: selectedLanguage == item.code
                            )
                            .onTapGesture {
                                selectedLanguage = item.code
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .appScreen()
        .navigationDestination(isPresented: $navigateToIntro) {
            IntroMainView()
        }
    }
}

struct langaugeRow: View {
    
    var lang: LanguageModel
    var isSelected: Bool = false
    
    var body: some View {
        ZStack {
            HStack(alignment:.top) {
                VStack(alignment:.leading,spacing: 5) {
                    Text(lang.name)
                        .font(.system(size: isIpad() ? 22 : 16,weight: .medium))
                        .foregroundStyle(.white)
                    
                    Text(lang.lan)
                        .font(.system(size: isIpad() ? 20 : 14,weight: .light))
                        .foregroundStyle(AppColor.textColor)
                }
                Spacer()
                Image(isSelected ? "select" : "deselect")
                    .resizable()
                    .frame(width: isIpad() ? 24 : 20,height: isIpad() ? 24 : 20)
            }
            .padding()
        }
        .frame(maxWidth: .infinity)
        .frame(height: isIpad() ? 100 : 80)
        .modifier(GlassCardModifier(cornerRadius: isIpad() ? 30 : 20))
        
    }
}

#Preview {
    LanguageView()
}
