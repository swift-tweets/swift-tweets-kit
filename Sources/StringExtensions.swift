import Foundation

extension String {
    internal var lines: [String] {
        var lines: [String] = []
        self.enumerateLines() { line, _ in
            lines.append(line)
        }
        return lines
    }
    
    internal func replacingOccurrences(of pattern: NSRegularExpression, with template: String) -> String {
        return pattern.stringByReplacingMatches(in: self, options: [], range: NSMakeRange(0, characters.count), withTemplate: template)
    }
}
