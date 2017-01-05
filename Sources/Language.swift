public enum Language {
    case c
    case cpp
    case cSharp
    case d
    case elixir
    case erlang
    case go
    case java
    case javaScript
    case haskell
    case kotlin
    case objectiveC
    case ocaml
    case perl
    case php
    case python
    case ruby
    case rust
    case scala
    case swift
    case typeScript
    case other(String)
    
    public init(identifier: String) {
        switch identifier {
        case "c":
            self = .c
        case "cpp", "c++":
            self = .cpp
        case "c#", "cs", "csharp":
            self = .cSharp
        case "d":
            self = .d
        case "ex", "elixir":
            self = .elixir
        case "erl", "erlang":
            self = .erlang
        case "go":
            self = .go
        case "hs", "haskell":
            self = .haskell
        case "java":
            self = .java
        case "js", "javascript":
            self = .javaScript
        case "kt", "kotlin":
            self = .kotlin
        case "objc", "objectivec", "objective-c":
            self = .objectiveC
        case "ml", "ocaml":
            self = .ocaml
        case "pl", "perl":
            self = .perl
        case "php":
            self = .php
        case "py", "python":
            self = .python
        case "rb", "ruby":
            self = .ruby
        case "rust":
            self = .rust
        case "scala":
            self = .scala
        case "swift":
            self = .swift
        case "ts", "typescript":
            self = .typeScript
        default:
            self = .other(identifier)
        }
    }
    
    public var identifier: String {
        switch self {
        case .c:
            return "c"
        case .cpp:
            return "cpp"
        case .cSharp:
            return "cs"
        case .d:
            return "d"
        case .elixir:
            return "elixir"
        case .erlang:
            return "erlang"
        case .go:
            return "go"
        case .haskell:
            return "haskell"
        case .java:
            return "java"
        case .javaScript:
            return "javascript"
        case .kotlin:
            return "kotlin"
        case .objectiveC:
            return "objc"
        case .ocaml:
            return "ocaml"
        case .perl:
            return "perl"
        case .php:
            return "php"
        case .python:
            return "python"
        case .ruby:
            return "ruby"
        case .rust:
            return "rust"
        case .scala:
            return "scala"
        case .swift:
            return "swift"
        case .typeScript:
            return "typescript"
        case let .other(identifier):
            return identifier
        }
    }
    
    public var filenameExtension: String? {
        switch self {
        case .c:
            return "c"
        case .cpp:
            return "cpp"
        case .cSharp:
            return "cs"
        case .d:
            return "d"
        case .elixir:
            return "ex"
        case .erlang:
            return "erl"
        case .go:
            return "go"
        case .haskell:
            return "hs"
        case .java:
            return "java"
        case .javaScript:
            return "js"
        case .kotlin:
            return "kt"
        case .objectiveC:
            return "m"
        case .ocaml:
            return "ml"
        case .perl:
            return "pl"
        case .php:
            return "php"
        case .python:
            return "py"
        case .ruby:
            return "rb"
        case .rust:
            return "rs"
        case .scala:
            return "scala"
        case .swift:
            return "swift"
        case .typeScript:
            return "ts"
        case .other(_):
            return nil
        }
    }
}

extension Language: Equatable {
    public static func ==(lhs: Language, rhs: Language) -> Bool {
        switch (lhs, rhs) {
        case (.c, .c):
            return true
        case (.cpp, .cpp):
            return true
        case (.cSharp, .cSharp):
            return true
        case (.d, .d):
            return true
        case (.elixir, .elixir):
            return true
        case (.erlang, .erlang):
            return true
        case (.go, .go):
            return true
        case (.haskell, .haskell):
            return true
        case (.java, .java):
            return true
        case (.javaScript, .javaScript):
            return true
        case (.kotlin, .kotlin):
            return true
        case (.objectiveC, .objectiveC):
            return true
        case (.ocaml, .ocaml):
            return true
        case (.perl, .perl):
            return true
        case (.php, .php):
            return true
        case (.python, .python):
            return true
        case (.ruby, .ruby):
            return true
        case (.rust, .rust):
            return true
        case (.scala, .scala):
            return true
        case (.swift, .swift):
            return true
        case (.typeScript, .typeScript):
            return true
        case let (.other(identifier1), .other(identifier2)):
            return identifier1 == identifier2
        default:
            return false
        }
    }
}
