import Foundation
import Testing
@testable import SayXCore

@Suite("VoiceRegistry Unit Tests")
struct VoiceRegistryTests {
    
    @Test("Resolves Kokoro friendly aliases to canonical IDs")
    func testKokoroVoiceResolution() {
        let resHeart = VoiceRegistry.resolve(query: "heart")
        if case .kokoro(let canonical, _) = resHeart {
            #expect(canonical == "af_heart")
        } else {
            Issue.record("Expected Kokoro resolution for 'heart'")
        }
        
        let resAdam = VoiceRegistry.resolve(query: "adam")
        if case .kokoro(let canonical, _) = resAdam {
            #expect(canonical == "am_adam")
        } else {
            Issue.record("Expected Kokoro resolution for 'adam'")
        }
    }
    
    @Test("Resolves PocketTTS studio voices")
    func testPocketVoiceResolution() {
        let resJavert = VoiceRegistry.resolve(query: "javert")
        if case .pocket(let voice, let isCloned, _) = resJavert {
            #expect(voice == "javert")
            #expect(!isCloned)
        } else {
            Issue.record("Expected PocketTTS resolution for 'javert'")
        }
        
        let resCosette = VoiceRegistry.resolve(query: "cosette")
        if case .pocket(let voice, _, _) = resCosette {
            #expect(voice == "cosette")
        } else {
            Issue.record("Expected PocketTTS resolution for 'cosette'")
        }
    }
    
    @Test("Resolves Supertonic-3 built-in character voice IDs")
    func testSupertonicBuiltInResolution() {
        let resM1 = VoiceRegistry.resolve(query: "m1")
        if case .supertonic(let voice, let isCustom, _, let lang) = resM1 {
            #expect(voice == "m1")
            #expect(!isCustom)
            #expect(lang == "en")
        } else {
            Issue.record("Expected Supertonic resolution for 'm1'")
        }
        
        let resF1 = VoiceRegistry.resolve(query: "f1")
        if case .supertonic(let voice, let isCustom, _, _) = resF1 {
            #expect(voice == "f1")
            #expect(!isCustom)
        } else {
            Issue.record("Expected Supertonic resolution for 'f1'")
        }
    }
    
    @Test("Resolves Supertonic-3 semantic aliases")
    func testSupertonicAliasResolution() {
        let resNarrator = VoiceRegistry.resolve(query: "m-narrator")
        if case .supertonic(let voice, _, _, _) = resNarrator {
            #expect(voice == "m1")
        } else {
            Issue.record("Expected 'm-narrator' to resolve to 'm1'")
        }
        
        let resStudio = VoiceRegistry.resolve(query: "f-studio")
        if case .supertonic(let voice, _, _, _) = resStudio {
            #expect(voice == "f1")
        } else {
            Issue.record("Expected 'f-studio' to resolve to 'f1'")
        }
    }
    
    @Test("Resolves direct .json style tensor file paths")
    func testDirectJSONStyleResolution() {
        let resJSON = VoiceRegistry.resolve(query: "/path/to/custom_voice.json")
        if case .supertonic(let voice, let isCustom, let url, _) = resJSON {
            #expect(voice == "custom_voice")
            #expect(isCustom)
            #expect(url?.lastPathComponent == "custom_voice.json")
        } else {
            Issue.record("Expected direct .json path to resolve to custom Supertonic style")
        }
    }
    
    @Test("Applies engine defaulting rules when voice is unspecified")
    func testEngineDefaulting() {
        let resPocket = VoiceRegistry.resolve(query: "", explicitEngine: "pocket")
        if case .pocket(let voice, _, _) = resPocket {
            #expect(voice == "alba")
        } else {
            Issue.record("Expected default voice 'alba' for pocket engine")
        }
        
        let resSupertonic = VoiceRegistry.resolve(query: "", explicitEngine: "supertonic")
        if case .supertonic(let voice, _, _, _) = resSupertonic {
            #expect(voice == "m1")
        } else {
            Issue.record("Expected default voice 'm1' for supertonic engine")
        }
        
        let resKokoro = VoiceRegistry.resolve(query: "", explicitEngine: "kokoro")
        if case .kokoro(let canonical, _) = resKokoro {
            #expect(canonical == "af_heart")
        } else {
            Issue.record("Expected default voice 'af_heart' for kokoro engine")
        }
    }
    
    @Test("Supertonic language resolver normalizes names and locale codes")
    func testSupertonicLanguageResolver() {
        #expect(SupertonicEngine.resolveLanguageCode("English") == "en")
        #expect(SupertonicEngine.resolveLanguageCode("spanish") == "es")
        #expect(SupertonicEngine.resolveLanguageCode("es-mx") == "es")
        #expect(SupertonicEngine.resolveLanguageCode("korean") == "ko")
        #expect(SupertonicEngine.resolveLanguageCode("ko-kr") == "ko")
        #expect(SupertonicEngine.resolveLanguageCode("ja") == "ja")
        #expect(SupertonicEngine.resolveLanguageCode("French") == "fr")
        #expect(SupertonicEngine.resolveLanguageCode("german") == "de")
        #expect(SupertonicEngine.resolveLanguageCode("pt-br") == "pt")
    }
}
