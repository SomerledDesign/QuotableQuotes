import Foundation

/// Quote model consumed by standalone and test targets.
struct Quote: Equatable {
    let body: String
    let author: String
    let theme: String?
    let font: String?
    let attribution: String?

    /// Creates a quote.
    ///
    /// - Parameters:
    ///   - body: Quote text body.
    ///   - author: Quote author name.
    ///   - theme: Optional theme key.
    ///   - font: Optional preferred font name.
    ///   - attribution: Optional source metadata string.
    init(body: String, author: String, theme: String? = nil, font: String? = nil, attribution: String? = nil) {
        self.body = body
        self.author = author
        self.theme = theme
        self.font = font
        self.attribution = attribution
    }

    /// Count of words used for dynamic display-duration calculation.
    var wordCount: Int {
        body.split { !$0.isLetter && !$0.isNumber }.count
    }

    /// Returns the preferred display font for this quote, falling back to the
    /// runtime-selected font when no XML font suggestion is present.
    /// - Parameter fallback: Font chosen in app settings.
    /// - Returns: XML-suggested font when non-empty; otherwise `fallback`.
    func preferredFontName(fallback: String) -> String {
        let suggested = font?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return suggested.isEmpty ? fallback : suggested
    }

    /// Recommends quote display duration based on word count.
    ///
    /// Uses a base duration at 7 words and scales linearly beyond that with a cap.
    ///
    /// - Parameter baseSeconds: Base display duration used for short quotes.
    /// - Returns: Calculated display interval in seconds.
    func recommendedDisplayDuration(baseSeconds: TimeInterval = 5.0) -> TimeInterval {
        let minimumWords = 7
        let words = max(wordCount, minimumWords)
        let extraWords = words - minimumWords
        let extraSecondsPerWord = 0.5
        let maxExtraSeconds = 10.0
        let scaledExtra = min(Double(extraWords) * extraSecondsPerWord, maxExtraSeconds)
        return baseSeconds + scaledExtra
    }
}

/// Errors raised while loading or parsing quote XML.
enum QuoteLoadError: Error {
    case invalidXML
}

/// XML parser that supports both keyed quote entries and legacy `<Quote>text</Quote><author>...`.
final class QuoteXMLParser: NSObject, XMLParserDelegate {
    private var currentElement: String?
    private var currentText = ""

    private var buildingBody: String?
    private var buildingAuthor: String?
    private var buildingTheme: String?
    private var buildingFont: String?
    private var buildingAttribution: String?
    private var insideQuote = false

    private var pendingBody: String?
    private(set) var quotes: [Quote] = []

    /// Parses XML quote data into quote models.
    /// - Parameter data: Raw XML bytes.
    /// - Returns: Parsed quotes array.
    /// - Throws: `QuoteLoadError.invalidXML` when XML parsing fails.
    func parse(data: Data) throws -> [Quote] {
        let parser = XMLParser(data: data)
        parser.delegate = self
        guard parser.parse() else {
            throw QuoteLoadError.invalidXML
        }
        return quotes
    }

    /// XML parser start-element callback.
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
        let key = elementName.lowercased()
        if key == "quote" {
            insideQuote = true
            buildingBody = nil
            buildingAuthor = nil
            buildingTheme = nil
            buildingFont = nil
            buildingAttribution = nil
            currentElement = key
            currentText = ""
            return
        }

        if key == "author" || key == "body" || key == "theme" || key == "font" || key == "attribution" {
            currentElement = key
            currentText = ""
        }
    }

    /// XML parser character callback.
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        guard currentElement != nil else { return }
        currentText += string
    }

    /// XML parser end-element callback.
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        let key = elementName.lowercased()
        let text = currentText.trimmingCharacters(in: .whitespacesAndNewlines)

        if key == "body" {
            if !text.isEmpty {
                buildingBody = text
            }
        } else if key == "theme" {
            if !text.isEmpty {
                buildingTheme = text
            }
        } else if key == "font" {
            if !text.isEmpty {
                buildingFont = text
            }
        } else if key == "attribution" {
            if !text.isEmpty {
                buildingAttribution = text
            }
        } else if key == "quote" {
            if let body = buildingBody, !body.isEmpty {
                if let author = buildingAuthor, !author.isEmpty {
                    quotes.append(
                        Quote(
                            body: body,
                            author: author,
                            theme: buildingTheme,
                            font: buildingFont,
                            attribution: buildingAttribution
                        )
                    )
                }
            } else if !text.isEmpty {
                pendingBody = text
            }
            insideQuote = false
        } else if key == "author", insideQuote {
            if !text.isEmpty {
                buildingAuthor = text
            }
        } else if key == "author", let body = pendingBody, !body.isEmpty, !text.isEmpty {
            quotes.append(Quote(body: body, author: text, theme: nil, font: nil, attribution: nil))
            pendingBody = nil
        }

        if key == "quote" || key == "author" || key == "body" || key == "theme" || key == "font" || key == "attribution" {
            currentElement = nil
            currentText = ""
        }
    }
}

/// Loader namespace for quote sources.
enum QuoteRepository {
    /// Loads quotes from a file URL.
    /// - Parameter url: XML file URL.
    /// - Returns: Parsed quote list.
    /// - Throws: File read or parse error.
    static func loadQuotes(from url: URL) throws -> [Quote] {
        let data = try Data(contentsOf: url)
        return try QuoteXMLParser().parse(data: data)
    }

    /// Loads quotes from bundled target resources.
    /// - Parameter fileName: Bundled file name (defaults to `quotes.xml`).
    /// - Returns: Parsed quote list.
    /// - Throws: `QuoteLoadError.invalidXML` or parser/file error.
    static func loadBundledQuotes(named fileName: String = "quotes.xml") throws -> [Quote] {
        let name = URL(fileURLWithPath: fileName).deletingPathExtension().lastPathComponent
        let ext = URL(fileURLWithPath: fileName).pathExtension
        let useExt = ext.isEmpty ? "xml" : ext
        let url = Bundle.module.url(forResource: name, withExtension: useExt)
        guard let url else {
            throw QuoteLoadError.invalidXML
        }
        return try loadQuotes(from: url)
    }
}

/// Non-repeating shuffled quote deck.
///
/// Returns each quote once per cycle, then reshuffles for the next cycle.
struct QuoteDeck {
    private(set) var drawIndex: Int = 0
    let quotes: [Quote]
    private var drawOrder: [Int]

    /// Creates a shuffled deck from a quote list.
    /// - Parameter quotes: Source quotes.
    init(quotes: [Quote]) {
        self.quotes = quotes
        self.drawOrder = Array(quotes.indices).shuffled()
    }

    /// Returns the next quote, reshuffling as required.
    /// - Returns: Next quote in current randomized cycle.
    mutating func next() -> Quote {
        guard !quotes.isEmpty else {
            return Quote(body: "No quotes configured.", author: "System")
        }

        if drawOrder.isEmpty {
            drawOrder = Array(quotes.indices).shuffled()
            drawIndex = 0
        }

        if drawIndex >= drawOrder.count {
            drawOrder = Array(quotes.indices).shuffled()
            drawIndex = 0
        }

        let quoteIndex = drawOrder[drawIndex]
        drawIndex += 1
        return quotes[quoteIndex]
    }

    /// Loads initial runtime quotes with fallback order.
    ///
    /// Fallback order:
    /// 1. Custom XML path
    /// 2. Bundled XML theme
    /// 3. Hardcoded sample fallback
    ///
    /// - Parameters:
    ///   - customFilePath: Optional custom XML path.
    ///   - bundledFileName: Bundled XML file name.
    /// - Returns: Non-empty quote array.
    static func initialQuotes(customFilePath: String? = nil, bundledFileName: String = "quotes.xml") -> [Quote] {
        if
            let customFilePath,
            let customURL = URL(string: customFilePath),
            customURL.isFileURL,
            let quotes = try? QuoteRepository.loadQuotes(from: customURL),
            !quotes.isEmpty
        {
            return quotes
        }

        if
            let customFilePath,
            !customFilePath.isEmpty
        {
            let customURL = URL(fileURLWithPath: customFilePath)
            if let quotes = try? QuoteRepository.loadQuotes(from: customURL), !quotes.isEmpty {
                return quotes
            }
        }

        if let quotes = try? QuoteRepository.loadBundledQuotes(named: bundledFileName), !quotes.isEmpty {
            return quotes
        }
        return milestoneOneFallbackQuotes()
    }

    /// Hardcoded fallback sample used if XML loading fails.
    /// - Returns: Small themed quote array.
    static func milestoneOneFallbackQuotes() -> [Quote] {
        [
            Quote(
                body: "Government of the people, by the people, for the people, shall not perish from the earth.",
                author: "Abraham Lincoln",
                theme: "leadership",
                font: "Avenir Next",
                attribution: "Gettysburg Address (1863) | https://en.wikiquote.org/wiki/Abraham_Lincoln"
            ),
            Quote(
                body: "Lead from the back and let others believe they are in front.",
                author: "Nelson Mandela",
                theme: "leadership",
                font: "Avenir Next",
                attribution: "Attributed saying | https://en.wikiquote.org/wiki/Nelson_Mandela"
            ),
            Quote(
                body: "Waste no more time arguing what a good man should be. Be one.",
                author: "Marcus Aurelius",
                theme: "stoicism",
                font: "Times New Roman",
                attribution: "Meditations 10.16 (c. 170 CE) | https://en.wikiquote.org/wiki/Marcus_Aurelius"
            ),
            Quote(
                body: "We suffer more often in imagination than in reality.",
                author: "Seneca",
                theme: "stoicism",
                font: "Times New Roman",
                attribution: "Epistulae Morales 13 (c. 65 CE) | https://en.wikiquote.org/wiki/Seneca_the_Younger"
            ),
            Quote(
                body: "The truth is rarely pure and never simple.",
                author: "Oscar Wilde",
                theme: "comedic",
                font: "Comic Sans MS",
                attribution: "The Importance of Being Earnest (1895) | https://en.wikiquote.org/wiki/Oscar_Wilde"
            ),
            Quote(
                body: "Outside of a dog, a book is man's best friend. Inside of a dog it's too dark to read.",
                author: "Groucho Marx",
                theme: "comedic",
                font: "Comic Sans MS",
                attribution: "Collected wit | https://en.wikiquote.org/wiki/Groucho_Marx"
            ),
            Quote(
                body: "The unexamined life is not worth living.",
                author: "Socrates",
                theme: "greek-philosophers",
                font: "Palatino",
                attribution: "Plato, Apology 38a (c. 399 BCE) | https://en.wikiquote.org/wiki/Socrates"
            ),
            Quote(
                body: "Happiness depends upon ourselves.",
                author: "Aristotle",
                theme: "greek-philosophers",
                font: "Palatino",
                attribution: "Nicomachean Ethics I.7 (c. 340 BCE) | https://en.wikiquote.org/wiki/Aristotle"
            ),
            Quote(
                body: "Woman is born free and lives equal to man in her rights.",
                author: "Olympe de Gouges",
                theme: "french-revolutionaries",
                font: "Didot",
                attribution: "Declaration of the Rights of Woman, Art. 1 (1791) | https://en.wikiquote.org/wiki/Olympe_de_Gouges"
            ),
            Quote(
                body: "Men are born and remain free and equal in rights.",
                author: "French National Assembly",
                theme: "french-revolutionaries",
                font: "Didot",
                attribution: "Declaration of the Rights of Man, Art. 1 (1789) | https://en.wikiquote.org/wiki/Declaration_of_the_Rights_of_Man_and_of_the_Citizen"
            )
        ]
    }
}
