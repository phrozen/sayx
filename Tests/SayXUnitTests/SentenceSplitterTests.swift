import Foundation
import NaturalLanguage
import Testing
@testable import SayXCore

@Suite("SentenceSplitter Unit Tests")
struct SentenceSplitterTests {
    
    @Test("Does not split on common English abbreviations and currency")
    func testEnglishAbbreviations() {
        let text = "Dr. Watson met Mr. Sherlock Holmes at 221B Baker St. in London. They arrived at 8:30 a.m. sharp for the $3.50 tea."
        let sentences = SentenceSplitter.split(text)
        #expect(sentences.count == 2)
        #expect(sentences[0].contains("Dr. Watson"))
        #expect(sentences[1].contains("$3.50"))
    }
    
    @Test("Extracts multi-engine speaker tags with voice and language directives")
    func testSpeakerTags() {
        let text = "[v:m1,l:es] ¡Hola mundo! [v:m-narrator,l:en] Welcome back. [v:adam] Doing fine."
        let sentences = SentenceSplitter.split(text)
        #expect(sentences.count == 3)
        
        let (v0, l0, t0) = SentenceSplitter.extractSpeakerTag(from: sentences[0])
        let (v1, l1, t1) = SentenceSplitter.extractSpeakerTag(from: sentences[1])
        let (v2, l2, t2) = SentenceSplitter.extractSpeakerTag(from: sentences[2])
        
        #expect(v0 == "m1")
        #expect(l0 == "es")
        #expect(t0 == "¡Hola mundo!")
        
        #expect(v1 == "m-narrator")
        #expect(l1 == "en")
        #expect(t1 == "Welcome back.")
        
        #expect(v2 == "adam")
        #expect(l2 == nil)
        #expect(t2 == "Doing fine.")
    }
    
    @Test("Supports shorthand colon speaker and language tags")
    func testColonTagFormat() {
        let text = "[v:m1:es] Buenas tardes."
        let (voice, lang, clean) = SentenceSplitter.extractSpeakerTag(from: text)
        #expect(voice == "m1")
        #expect(lang == "es")
        #expect(clean == "Buenas tardes.")
    }
    
    @Test("Supports standalone language switch tag")
    func testStandaloneLanguageTag() {
        let text = "[l:fr] Bonjour tout le monde."
        let (voice, lang, clean) = SentenceSplitter.extractSpeakerTag(from: text)
        #expect(voice == nil)
        #expect(lang == "fr")
        #expect(clean == "Bonjour tout le monde.")
    }
    
    @Test("Backward-compatible extractVoiceTag extracts voice and strips tag")
    func testExtractVoiceTagCompatibility() {
        let text = "[v:bella] How are you?"
        let (voice, clean) = SentenceSplitter.extractVoiceTag(from: text)
        #expect(voice == "bella")
        #expect(clean == "How are you?")
    }
    
    @Test("Protects Spanish abbreviations when language hint is provided")
    func testSpanishAbbreviations() {
        let text = "¿Cómo estás, amigo? El Sr. Pérez dijo que vendría hoy. ¡Qué buena noticia!"
        let sentences = SentenceSplitter.split(text, language: .spanish)
        #expect(sentences.count == 3)
        #expect(sentences[1].contains("El Sr. Pérez"))
    }
    
    @Test("Splits Japanese full-width punctuation naturally")
    func testJapanesePunctuation() {
        let text = "吾輩は猫である。名前はまだ無い。どこで生れたかとんと見当がつかぬ。"
        let sentences = SentenceSplitter.split(text, language: .japanese)
        #expect(sentences.count == 3)
    }
    
    @Test("Breaks unusually long run-on sentences on semicolons and colons")
    func testRunOnSentenceBreaking() {
        let words = (1...40).map { "word\($0)" }.joined(separator: " ")
        let overlong = "\(words); and then the second clause began with even more words."
        let chunks = SentenceSplitter.split(overlong)
        #expect(chunks.count >= 2)
    }
}
