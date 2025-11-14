import Testing
@testable import ARCDevTools

struct ARCDevToolsTests {
    @Test
    func testHelloFunction() {
        #expect(ARCDevTools.hello() == "Hello from ARCDevTools!")
    }
}
