import Testing
@testable import AstroLex

struct BuildInfoTests {
    @Test func labelCarriesVersionAndBuild() {
        #expect(BuildInfo.label.hasPrefix("v"))
        #expect(BuildInfo.label.contains("("))
    }
}
