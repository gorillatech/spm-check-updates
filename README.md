# spm-check-updates

spm-check-updates shows if there are new versions available for SPM (Swift Package Manager) dependencies used in a Xcode project or in another Package.swift. 


## Installation

### Using homebrew (Preferred)

    brew install gorillatech/repo/spm-check-updates
    
### Build from source
    
    git clone https://github.com/gorillatech/spm-check-updates
    cd spm-check-updates
    make install
    
# Usage

Show all dependencies for the project in the current directory:

    $ spm-check-updates
    
    Checking Brass.xcodeproj
    [------------------------------] 22 of 22

    SkeletonView          1.30.3  ->  1.30.4
    

Show all dependencies for the Package.swift in the current directory

    $ spm-check-updates
    
    Checking Package.swift
    [------------------------------] 4 of 4

    https://github.com/apple/swift-argument-parser          1.2.1  ->  1.2.2
