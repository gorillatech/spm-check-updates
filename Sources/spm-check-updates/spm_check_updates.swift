import ArgumentParser
import Foundation
import XcodeProj
import Progress
import Rainbow

@main
public struct spm_check_updates {

    public static func main() throws {
        
        let contents = try FileManager.default.contentsOfDirectory(atPath: FileManager.default.currentDirectoryPath)
        
        guard let path = contents.first(where: {$0.contains(".xcodeproj")}) else {
            print("Cannot find .xcodeproj in the current directory".red)
            exit(1)
        }

        let xcodeproj = try XcodeProj(pathString: path)
        
        print("Checking \(path)")

        guard let packages = xcodeproj.pbxproj.rootObject?.packages else {
            print("All packages are up to date!".green)
            return
        }
        
        ProgressBar.defaultConfiguration = [ProgressIndex(), ProgressBarLine()]

        
        var bar = ProgressBar(count: packages.count)
        
        var result = [String]()

        bar.next()
        for package in packages {
            bar.next()

            if let repo = package.repositoryURL, let version = package.versionRequirement {
                
                let latest = getLatestTag(repo: repo)
                
                let current = currentVersion(version: version)
                
                if let current {
                    if latest.versionCompare(current) == .orderedDescending {
                        result.append("\(package.name ?? package.repositoryURL ?? "unknown")          \(current)  ->  \(latest)")
                    }
                }
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
    
    static func getLatestTag(repo: String) -> String {
        
        //[0-9]*\\.[0-9]*\\.[0-9]*
        // matches only numeric values (seems to be whats xcode does by default), hownever some repos (facebook) use v15.0.0
        
        var v1 = shell("git -c 'versionsort.suffix=-' ls-remote --exit-code --refs --sort='version:refname' --tags " + repo + " '[0-9]*\\.[0-9]*\\.[0-9]*' | tail --lines=1 | cut -d '/' -f 3")

        var v2 = shell("git -c 'versionsort.suffix=-' ls-remote --exit-code --refs --sort='version:refname' --tags " + repo + " 'v[0-9]*\\.[0-9]*\\.[0-9]*' | tail --lines=1 | cut -d '/' -f 3")

        
        v1 = v1.trimmingCharacters(in: .whitespacesAndNewlines)
        v2 = v2.trimmingCharacters(in: .whitespacesAndNewlines)
        
        v2 = String(v2.dropFirst())
        
        return v1.versionCompare(v2) == .orderedAscending ? v2 : v1
        
    }
    
    static func shell(_ command: String) -> String {
        let task = Process()
        let pipe = Pipe()
        
        task.standardOutput = pipe
        task.standardError = pipe
        task.arguments = ["-c", command]
        task.launchPath = "/bin/zsh"
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
