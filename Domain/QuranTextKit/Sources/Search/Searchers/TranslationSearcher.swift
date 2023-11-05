//
//  TranslationSearcher.swift
//
//
//  Created by Mohamed Afifi on 2021-11-17.
//

import Foundation
import QuranKit
import QuranText
import TranslationService
import VerseTextPersistence

struct TranslationSearcher: Searcher {
    // MARK: Internal

    let localTranslationRetriever: LocalTranslationsRetriever
    let versePersistenceBuilder: (Translation) -> SearchableTextPersistence

    func autocomplete(term: SearchTerm, quran: Quran) async throws -> [String] {
        let translations = try await getDownloadedTranslations()
        for translation in translations {
            let persistence = versePersistenceBuilder(translation)
            let persistenceSearcher = PersistenceSearcher(versePersistence: persistence, source: .translation(translation))
            let results = try await persistenceSearcher.autocomplete(term: term, quran: quran)
            if !results.isEmpty {
                return results
            }
        }
        return []
    }

    func search(for term: SearchTerm, quran: Quran) async throws -> [SearchResults] {
        let translations = try await getDownloadedTranslations()
        let results = try await translations.asyncMap { translation -> [SearchResults] in
            let persistence = versePersistenceBuilder(translation)
            let persistenceSearcher = PersistenceSearcher(versePersistence: persistence, source: .translation(translation))
            let results = try await persistenceSearcher.search(for: term, quran: quran)
            return results
        }
        return results.flatMap { $0 }
    }

    // MARK: Private

    private func getDownloadedTranslations() async throws -> [Translation] {
        let translations = try await localTranslationRetriever.getLocalTranslations()
        return translations.filter(\.isDownloaded)
    }
}
