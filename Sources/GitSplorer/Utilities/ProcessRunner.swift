import Foundation

enum ProcessRunnerError: Error {
    case nonZeroExit(Int, String)
}

struct ProcessRunner {
    static func run(_ launchPath: String, _ arguments: [String], environment: [String: String] = [:]) throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: launchPath)
        process.arguments = arguments

        var env = ProcessInfo.processInfo.environment
        environment.forEach { env[$0.key] = $0.value }
        process.environment = env

        let pipe = Pipe()
        let errPipe = Pipe()
        process.standardOutput = pipe
        process.standardError = errPipe

        try process.run()
        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let errData = errPipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(decoding: data, as: UTF8.self)
        let errorOutput = String(decoding: errData, as: UTF8.self)

        if process.terminationStatus != 0 {
            throw ProcessRunnerError.nonZeroExit(Int(process.terminationStatus), errorOutput.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        return output.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
