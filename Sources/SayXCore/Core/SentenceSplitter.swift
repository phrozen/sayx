import Foundation
import NaturalLanguage

/// Utility to split long-form text into natural sentences and clauses for streaming TTS.
///
/// Uses Apple's native `NLTokenizer` from `NaturalLanguage.framework` to enforce
/// Unicode Standard Annex #29 sentence boundary segmentation.
///
/// Features:
/// - Native Darwin/macOS framework: 0 MB weights, microsecond latency.
/// - Accurately preserves abbreviations (Dr., Mr., St., e.g., p.m.).
/// - Handles currencies, decimals, and percentages ($3.50, 3.8%, v2.0).
/// - Handles trailing dialogue quotes and non-Latin punctuation (Japanese 。, Spanish ¿?).
/// - Seamlessly isolates inline multi-voice and multi-language tags ([v:adam], [v:m1,l:es]) across speaker turns.
/// - Breaks abnormally long run-on sentences (> 35 words) on pause punctuation to maintain sub-200ms TTFA.
public enum SentenceSplitter {
    
    private static let speakerTagRegex = try! NSRegularExpression(
        pattern: #"(?i)\[(?:v(?:oice)?\s*:\s*([a-zA-Z0-9_\-/\.]+)(?:(?:\s*[,:]\s*(?:l(?:ang(?:uage)?)?\s*:\s*)?|\s*:\s*)([a-zA-Z0-9_\-]+))?|l(?:ang(?:uage)?)?\s*:\s*([a-zA-Z0-9_\-]+))\]"#
    )
    
    /// Extracts speaker voice and language tags (e.g. `[v:adam]`, `[v:m1,l:es]`, `[l:es]`) from text.
    public static func extractSpeakerTag(from text: String) -> (voice: String?, language: String?, cleanText: String) {
        guard let match = speakerTagRegex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let tagRange = Range(match.range, in: text) else {
            return (nil, nil, text)
        }
        
        var voice: String? = nil
        var lang: String? = nil
        
        if match.range(at: 1).location != NSNotFound, let r1 = Range(match.range(at: 1), in: text) {
            voice = String(text[r1])
        }
        if match.range(at: 2).location != NSNotFound, let r2 = Range(match.range(at: 2), in: text) {
            lang = String(text[r2])
        }
        if match.range(at: 3).location != NSNotFound, let r3 = Range(match.range(at: 3), in: text) {
            lang = String(text[r3])
        }
        
        var clean = text
        clean.removeSubrange(tagRange)
        return (voice, lang, clean.trimmingCharacters(in: .whitespaces))
    }
    
    /// Extracts an optional voice tag (e.g. `[v:adam]`, `[voice:bella]`) from text,
    /// returning the extracted voice name and the cleaned narrative text.
    public static func extractVoiceTag(from text: String) -> (voice: String?, cleanText: String) {
        let (voice, _, clean) = extractSpeakerTag(from: text)
        return (voice, clean)
    }
    
    /// Splits long-form text into an ordered sequence of sentence chunks ready for streaming speech synthesis.
    ///
    /// - Parameters:
    ///   - text: The raw text string (can be an entire book, a dialogue script, or a single clause).
    ///   - language: Optional language hint (e.g. `.spanish`, `.japanese`). If nil, Apple's `NLLanguageRecognizer` auto-detects.
    /// - Returns: Array of clean sentence chunks ready for hardware audio synthesis.
    public static func split(_ text: String, language: NLLanguage? = nil) -> [String] {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        
        // 1. Determine language for abbreviation dictionaries
        let targetLanguage: NLLanguage
        if let explicitLang = language {
            targetLanguage = explicitLang
        } else {
            let recognizer = NLLanguageRecognizer()
            recognizer.processString(trimmed)
            targetLanguage = recognizer.dominantLanguage ?? .english
        }
        
        // 2. Split by paragraphs (newlines) to preserve structure
        let paragraphs = trimmed.components(separatedBy: "\n")
        var results: [String] = []
        
        for rawParagraph in paragraphs {
            let paragraph = rawParagraph.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !paragraph.isEmpty else { continue }
            
            // 3. Segment paragraph by speaker tags so speaker changes always start a new chunk
            let sections = splitByVoiceTags(paragraph)
            
            for section in sections {
                let (voiceTag, langTag, narrative) = extractSpeakerTag(from: section)
                guard !narrative.isEmpty else { continue }
                
                // 4. Tokenize narrative sentences with Apple NLTokenizer
                let sentences = tokenizeSentences(narrative, language: targetLanguage)
                
                var isFirst = true
                for sentence in sentences {
                    // 5. Clause safety: break unusually long run-on sentences (> 35 words)
                    let subChunks = breakOverlongSentence(sentence)
                    
                    for chunk in subChunks {
                        let trimmedChunk = chunk.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmedChunk.isEmpty else { continue }
                        
                        if isFirst {
                            var tagPrefix = ""
                            if let v = voiceTag, let l = langTag {
                                tagPrefix = "[v:\(v),l:\(l)] "
                            } else if let v = voiceTag {
                                tagPrefix = "[v:\(v)] "
                            } else if let l = langTag {
                                tagPrefix = "[l:\(l)] "
                            }
                            results.append("\(tagPrefix)\(trimmedChunk)")
                            isFirst = false
                        } else {
                            results.append(trimmedChunk)
                        }
                    }
                }
            }
        }
        
        return results
    }
    
    /// Convenience helper to map standard BCP-47 or ISO language codes to NLLanguage.
    public static func resolveLanguage(code: String?) -> NLLanguage? {
        guard let code = code?.lowercased().trimmingCharacters(in: .whitespacesAndNewlines), !code.isEmpty else {
            return nil
        }
        switch code {
        case "en", "eng", "english": return .english
        case "es", "spa", "spanish": return .spanish
        case "fr", "fra", "french":  return .french
        case "de", "deu", "german":  return .german
        case "it", "ita", "italian": return .italian
        case "pt", "por", "portuguese": return .portuguese
        case "ja", "jpn", "japanese": return .japanese
        case "ko", "kor", "korean": return .korean
        case "zh", "zho", "chinese", "mandarin": return .simplifiedChinese
        case "ru", "rus", "russian": return .russian
        case "nl", "nld", "dutch": return .dutch
        case "pl", "pol", "polish": return .polish
        case "tr", "tur", "turkish": return .turkish
        case "ar", "ara", "arabic": return .arabic
        default: return NLLanguage(rawValue: code)
        }
    }
    
    // MARK: - Private Helpers
    
    /// Splits text at speaker tag boundaries so each speaker/turn change is an isolated section.
    private static func splitByVoiceTags(_ text: String) -> [String] {
        let nsString = text as NSString
        let matches = speakerTagRegex.matches(in: text, range: NSRange(location: 0, length: nsString.length))
        
        guard !matches.isEmpty else { return [text] }
        
        var sections: [String] = []
        var lastLocation = 0
        
        for match in matches {
            let matchLocation = match.range.location
            if matchLocation > lastLocation {
                let pre = nsString.substring(with: NSRange(location: lastLocation, length: matchLocation - lastLocation)).trimmingCharacters(in: .whitespaces)
                if !pre.isEmpty {
                    sections.append(pre)
                }
            }
            lastLocation = matchLocation
        }
        
        if lastLocation < nsString.length {
            let tail = nsString.substring(from: lastLocation).trimmingCharacters(in: .whitespaces)
            if !tail.isEmpty {
                sections.append(tail)
            }
        }
        
        return sections
    }
    
    /// Uses Apple's NLTokenizer to break narrative text into sentences.
    private static func tokenizeSentences(_ text: String, language: NLLanguage) -> [String] {
        let tokenizer = NLTokenizer(unit: .sentence)
        tokenizer.setLanguage(language)
        tokenizer.string = text
        
        var sentences: [String] = []
        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { range, _ in
            let s = String(text[range]).trimmingCharacters(in: .whitespacesAndNewlines)
            if !s.isEmpty {
                sentences.append(s)
            }
            return true
        }
        
        // If tokenizer produced nothing (e.g. unpunctuated text), return whole text
        return sentences.isEmpty ? [text] : sentences
    }
    
    /// Splits sentences exceeding 35 words into smaller clauses on natural punctuation.
    private static func breakOverlongSentence(_ sentence: String) -> [String] {
        let words = sentence.split(whereSeparator: { $0.isWhitespace })
        guard words.count > 35 else { return [sentence] }
        
        // Break on semicolons, colons, or em dashes first
        for delimiter in ["; ", ": ", " -- ", " — "] {
            if sentence.contains(delimiter) {
                let parts = sentence.components(separatedBy: delimiter)
                var chunks: [String] = []
                for (idx, part) in parts.enumerated() {
                    let cleaned = part.trimmingCharacters(in: .whitespaces)
                    if !cleaned.isEmpty {
                        // Reattach semicolon/colon if not last
                        if idx < parts.count - 1 && delimiter.starts(with: ";") {
                            chunks.append(cleaned + ";")
                        } else {
                            chunks.append(cleaned)
                        }
                    }
                }
                if chunks.count > 1 { return chunks }
            }
        }
        
        return [sentence]
    }
}
