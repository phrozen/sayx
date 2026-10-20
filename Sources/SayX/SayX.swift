import Foundation
import SayXCore

/// Main entrypoint executable for the `sayx` command-line utility.
@main
struct SayXMain {
    static func main() async {
        await SayXRunner.run()
    }
}
