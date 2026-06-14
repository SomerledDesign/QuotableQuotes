import Foundation
import Testing
@testable import ScreenSaver

@Test func quoteDeckShowsEachQuoteOncePerCycle() {
    var deck = QuoteDeck(quotes: [
        Quote(body: "One", author: "A"),
        Quote(body: "Two", author: "B"),
        Quote(body: "Three", author: "C")
    ])

    let cycleOne = [deck.next(), deck.next(), deck.next()]
    let cycleTwo = [deck.next(), deck.next(), deck.next()]

    #expect(Set(cycleOne.map(\.body)).count == 3)
    #expect(Set(cycleTwo.map(\.body)).count == 3)
    #expect(Set(cycleOne.map(\.body)) == Set(["One", "Two", "Three"]))
    #expect(Set(cycleTwo.map(\.body)) == Set(["One", "Two", "Three"]))
}

@Test func milestoneFallbackProvidesTenMixedQuotes() {
    let quotes = QuoteDeck.milestoneOneFallbackQuotes()
    #expect(quotes.count == 10)
    let themes = Set(quotes.compactMap(\.theme))
    #expect(themes == Set(["leadership", "stoicism", "comedic", "greek-philosophers", "french-revolutionaries"]))
}

@Test func quoteParserLoadsQuoteAuthorPairs() throws {
    let xml = """
    <QUOTES>
        <Quote>Alpha</Quote>
        <author>Alice</author>
        <Quote>Beta</Quote>
        <author>Bob</author>
    </QUOTES>
    """
    let parsed = try QuoteXMLParser().parse(data: Data(xml.utf8))
    #expect(parsed == [
        Quote(body: "Alpha", author: "Alice"),
        Quote(body: "Beta", author: "Bob")
    ])
}

@Test func quoteParserLoadsKeyedQuoteEntries() throws {
    let xml = """
    <QUOTES>
        <Quote>
            <body>Keyed Body</body>
            <author>Keyed Author</author>
            <theme>leadership</theme>
            <font>Avenir Next</font>
            <attribution>Collected Notes, Vol. 1</attribution>
        </Quote>
    </QUOTES>
    """
    let parsed = try QuoteXMLParser().parse(data: Data(xml.utf8))
    #expect(parsed == [
        Quote(
            body: "Keyed Body",
            author: "Keyed Author",
            theme: "leadership",
            font: "Avenir Next",
            attribution: "Collected Notes, Vol. 1"
        )
    ])
}

@Test func initialQuotesUsesCustomXMLPathWhenValid() throws {
    let xml = """
    <QUOTES>
        <Quote>Custom Body</Quote>
        <author>Custom Author</author>
    </QUOTES>
    """
    let tempURL = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString)
        .appendingPathExtension("xml")
    guard let xmlData = xml.data(using: .utf8) else {
        Issue.record("Failed to encode XML test content")
        return
    }
    try xmlData.write(to: tempURL)
    defer { try? FileManager.default.removeItem(at: tempURL) }

    let quotes = QuoteDeck.initialQuotes(customFilePath: tempURL.path)
    #expect(quotes.first == Quote(body: "Custom Body", author: "Custom Author"))
}

@Test func initialQuotesLoadsRequestedBundledThemeFile() {
    let quotes = QuoteDeck.initialQuotes(customFilePath: nil, bundledFileName: "leadership-quotes.xml")
    #expect(!quotes.isEmpty)
    #expect(quotes.first?.theme == "leadership")
}

@Test func bundledThemeLibrariesContainOneHundredUniqueQuotes() throws {
    let themeFiles = [
        "leadership-quotes.xml",
        "stoicism-quotes.xml",
        "comedic-quotes.xml",
        "greek-philosophers-quotes.xml",
        "french-revolutionaries-quotes.xml"
    ]

    for file in themeFiles {
        let quotes = try QuoteRepository.loadBundledQuotes(named: file)
        #expect(quotes.count == 100)
        #expect(Set(quotes.map(\.body)).count == 100)
    }
}

@Test func stoicismLibraryIncludesArthurSchopenhauer() throws {
    let quotes = try QuoteRepository.loadBundledQuotes(named: "stoicism-quotes.xml")
    let schopenhauerQuotes = quotes.filter { $0.author == "Arthur Schopenhauer" }
    #expect(!schopenhauerQuotes.isEmpty)
}

@Test func mixedBundledLibrarySamplesTwentyQuotesPerTheme() throws {
    let quotes = try QuoteRepository.loadBundledQuotes(named: "quotes.xml")
    #expect(quotes.count == 100)

    let counts = Dictionary(grouping: quotes, by: \.theme).mapValues(\.count)
    #expect(counts["leadership"] == 20)
    #expect(counts["stoicism"] == 20)
    #expect(counts["comedic"] == 20)
    #expect(counts["greek-philosophers"] == 20)
    #expect(counts["french-revolutionaries"] == 20)
}

@Test func quoteRecommendedDisplayDurationScalesWithWordCount() {
    let short = Quote(body: "One two three four five six seven", author: "A")
    let medium = Quote(body: "One two three four five six seven eight nine ten eleven twelve thirteen", author: "B")

    #expect(short.wordCount == 7)
    #expect(medium.wordCount == 13)
    #expect(short.recommendedDisplayDuration() == 5.0)
    #expect(medium.recommendedDisplayDuration() == 8.0)
}

@Test func quoteRecommendedDisplayDurationCapsForVeryLongQuotes() {
    let longBody = Array(repeating: "word", count: 80).joined(separator: " ")
    let quote = Quote(body: longBody, author: "A")
    #expect(quote.recommendedDisplayDuration() == 15.0)
}

@Test func quoteRecommendedDisplayDurationUsesCustomBaseTime() {
    let medium = Quote(body: "One two three four five six seven eight nine ten eleven twelve thirteen", author: "B")
    #expect(medium.recommendedDisplayDuration(baseSeconds: 6.0) == 9.0)
}

@Test func quotePreferredFontNameUsesXMLSuggestionWhenPresent() {
    let quoteWithFont = Quote(body: "Body", author: "Author", font: "Didot")
    let quoteWithoutFont = Quote(body: "Body", author: "Author", font: nil)
    let quoteWithBlankFont = Quote(body: "Body", author: "Author", font: "   ")

    #expect(quoteWithFont.preferredFontName(fallback: "Papyrus") == "Didot")
    #expect(quoteWithoutFont.preferredFontName(fallback: "Papyrus") == "Papyrus")
    #expect(quoteWithBlankFont.preferredFontName(fallback: "Papyrus") == "Papyrus")
}

@Test func animationStylesExposeAllMilestoneModes() {
    let styles = AppSettings.AnimationStyle.allCases
    #expect(styles.count == 7)
    #expect(styles.contains(.randomTransition))
    #expect(styles.contains(.fade))
    #expect(styles.contains(.dropDown))
    #expect(styles.contains(.slide))
    #expect(styles.contains(.materialize))
    #expect(styles.contains(.genie))
    #expect(styles.contains(.flagWave))
}
