import ArgumentParser
import Foundation
import XcodeProj
import Progress
import Rainbow

@main
public struct spm_check_updates {

    struct Package {
        var url: String
        var version: String
    }
    
    public static func main() throws {
        let contents = try FileManager.default.contentsOfDirectory(atPath: FileManager.default.currentDirectoryPath)

        var packages: [Package] = []
        
        if let path = contents.first(where: {$0.contains(".xcodeproj")}) {
            packages = try parseXcodeProj(path: path)
        } else if let path = contents.first(where: {$0 == "Package.swift"}) {
            packages = parsePackageSwift(path: path)
        } else {
            print("Cannot find .xcodeproj or Package.swift in the current directory".red)
            exit(1)
        }
        
        if packages.count == 0 {
            print("All packages are up to date!".green)
            return
        }
        
        ProgressBar.defaultConfiguration = [ProgressBarLine(), ProgressIndex()]

        var bar = ProgressBar(count: packages.count)
        bar.setValue(1)
        
        var result = [String]()

        for package in packages {
            bar.next()
                        
            if let latestVersion = getLatestTag(repo: package.url), latestVersion.versionCompare(package.version) == .orderedDescending {
                result.append("\(package.url)          \(package.version)  ->  \(latestVersion)")
            }
        }

        print("\n")

        if result.count > 0 {
            for row in result {
                print(row)
            }
        } else {
            print("All dependencies match the latest package versions :)".green)
        }
        
        //try! xcodeproj.write(pathString: path, override: true)
    }
    
    static func parsePackageSwift(path: String) -> [Package] {
        print("Checking \(path)")

        guard let dependenciesString = try? String(contentsOfFile: path, encoding: .utf8) else {
            print("Failed to read Package.swift file".red)
            exit(1)
        }
        
        let dependencyRegex = try! NSRegularExpression(pattern: "\\.package\\(url:\\s*\"([^\"]+)\",\\s*from:\\s*\"([^\"]*)\"\\s*\\)", options: [])
        
        var dependencies: [Package] = []
        
        dependenciesString.enumerateLines { line, _ in
            
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if let match = dependencyRegex.firstMatch(in: trimmedLine, options: [], range: NSRange(location: 0, length: trimmedLine.utf16.count)) {
                guard match.numberOfRanges == 3 else {
                    return
                }
                
                let urlRange = Range(match.range(at: 1), in: trimmedLine)!
                let fromRange = Range(match.range(at: 2), in: trimmedLine) ?? Range(NSRange(location: NSNotFound, length: 0), in: "")
                
                let urlValue = String(trimmedLine[urlRange])
                let fromValue = String(trimmedLine[fromRange!])
                dependencies.append(Package(url: urlValue, version: fromValue))
            }
        }
        
        return dependencies
    }
    
    static func parseXcodeProj(path: String) throws -> [Package] {
        print("Checking \(path)")

        let xcodeproj = try XcodeProj(pathString: path)
        
        guard let packages = xcodeproj.pbxproj.rootObject?.remotePackages else {
            return []
        }
        
        return packages.compactMap { package in
            
            if let repo = package.repositoryURL, let version = package.versionRequirement, let current = currentVersion(version: version) {
                return Package(url: repo, version: current)
            }
            return nil
        }
        
    }
    
    static func currentVersion(version: XCRemoteSwiftPackageReference.VersionRequirement) -> String? {
        
        switch version {
        case .upToNextMajorVersion(let string):
            return string
        case .upToNextMinorVersion(let string):
            return string
        case .range(let from, let to):
            return from
        case .exact(let string):
            return string
        case .branch(let string):
            return nil
        case .revision(let string):
            return nil
        }
    }
        
    static func getLatestTag(repo: String) -> String? {
        
        let v1 = shell("git -c 'versionsort.suffix=-' ls-remote --exit-code --refs --sort='version:refname' --tags " + repo)

        let versions = v1.components(separatedBy: CharacterSet.newlines);
                
        let regex = try! NSRegularExpression(pattern: "(?:/v?)([0-9]+\\.[0-9]+\\.[0-9]+)$", options: [])

        return versions.compactMap { line in
            let range = NSRange(location: 0, length: line.utf16.count)
            if let match = regex.firstMatch(in: line, options: [], range: range), let versionRange = Range(match.range(at: 1), in: line) {
                return String(line[versionRange])
            }
            return nil
        }.last
    }
    
    static func shell(_ command: String) -> String {
        let task = Process()
        let pipe = Pipe()
        
        task.standardOutput = pipe
        task.standardError = pipe
        task.arguments = ["-c", command]
        task.launchPath = "/bin/sh"
        task.standardInput = nil
        task.launch()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)!
        
        return output
    }


}

extension String {
    func versionCompare(_ otherVersion: String) -> ComparisonResult {
        let versionDelimiter = "."
        
        var versionComponents = self.components(separatedBy: versionDelimiter)
        var otherVersionComponents = otherVersion.components(separatedBy: versionDelimiter)
        
        let zeroDiff = versionComponents.count - otherVersionComponents.count
        
        if zeroDiff == 0 {
            // Same format, compare normally
            return self.compare(otherVersion, options: .numeric)
        } else {
            let zeros = Array(repeating: "0", count: abs(zeroDiff))
            if zeroDiff > 0 {
                otherVersionComponents.append(contentsOf: zeros)
            } else {
                versionComponents.append(contentsOf: zeros)
            }
            return versionComponents.joined(separator: versionDelimiter)
                .compare(otherVersionComponents.joined(separator: versionDelimiter), options: .numeric)
        }
    }
}
