import Foundation
import Vapor
import Core

private let maximumPermalinkLength = 2000

extension ConstraintGroup: NodeRepresentable {
    
    func makeNode(in context: Context?) throws -> Node {
        
        return try makeNode(in: context, includePermalink: true)
    }
    
    func makeNode(in context: Context?, includePermalink: Bool) throws -> Node {
        
        let constraintNodes = try constraints.map { item in
            try item.makeNode(in: context, annotations: annotations)
        }
        let footnoteNodes = try footnotes.map { footnote in
            try footnote.makeNode(in: context)
        }
        
        let permalink: String?
        
        if includePermalink {
            let trimmed = raw.addingPercentEncoding(withAllowedCharacters: .alphanumerics)
            permalink = (trimmed?.characters.count ?? 0) < maximumPermalinkLength ? trimmed : nil
        } else {
            permalink = nil
        }
        
        return .object([
            "constraints": .array(constraintNodes),
            "permalink": permalink.map { .string($0) } ?? .null,
            "footnotes": .array(footnoteNodes)
            ])
    }
}

extension Constraint: NodeRepresentable {
    
    func makeNode(in context: Context?) throws -> Node {
        
        return .object(try makeObject(in: context))
    }
    
    func makeNode(in context: Context?, annotations: [Instance: Annotation] = [:]) throws -> Node {
        
        return .object(try makeObject(in: context, annotations: annotations))
    }
    
    func makeObject(in context: Context?, annotations: [Instance: Annotation] = [:]) throws -> [String: Node] {
        
        let hideConstant = constant.value == 0.0 && second != nil
        
        var object = [
            "identity": try identity.makeNode(in: context),
            "first": try first.makeNode(in: context, annotation: annotations[first.layoutItem]),
            "relation": try relation.makeNode(in: context),
            "constant": hideConstant ? .null : try constant.makeNode(in: context, includePositivePrefix: second != nil),
            "multiplier": try multiplier.makeNode(in: context),
            "description": .bytes(htmlDescription(annotations: annotations).bytes),
            "footnote": try footnote?.makeNode(in: context) ?? .null
        ]
        
        if let second = second {
            object["second"] = try second.makeNode(in: context, annotation: annotations[second.layoutItem])
        }
        return object
    }
}

extension LayoutItemAttribute: NodeRepresentable {
    
    func makeNode(in context: Context?) throws -> Node {
        
        return .object(try makeObject(in: context))
    }
    
    func makeNode(in context: Context?, annotation: Annotation? = nil) throws -> Node {
        
        return .object(try makeObject(in: context, annotation: annotation))
    }
    
    func makeObject(in context: Context?, annotation: Annotation? = nil) throws -> [String: Node] {
        
        return [
            "instance": try layoutItem.makeNode(in: context, annotation: annotation),
            "attribute": try attribute.makeNode(in: context)
        ]
    }
}

extension Instance: NodeRepresentable {
    
    func makeNode(in context: Context?) throws -> Node {
        
        return .object(try makeObject(in: context))
    }
    
    func makeNode(in context: Context?, annotation: Annotation? = nil) throws -> Node {
        
        return .object(try makeObject(in: context, annotation: annotation))
    }
    
    func makeObject(in context: Context?, annotation: Annotation? = nil) throws -> [String: Node] {
        
        let firstAlphanumeric = prettyName.unicodeScalars.first { CharacterSet.alphanumerics.contains($0) }
        let initial = firstAlphanumeric.map { String($0).uppercased() } ?? ""
        return [
            "address": .string(address),
            "class": .string(className),
            "name": .string(prettyName),
            "suffix": annotation.map { .string($0.uniquingSuffix) } ?? .null,
            "color": try (annotation?.color ?? .defaultColor).makeNode(in: context),
            "initial": .string(initial),
            "identifier": identifier.map { .string($0) } ?? .null
        ]
    }
}

extension Attribute: NodeRepresentable {
    
    func makeNode(in context: Context?) throws -> Node {
        
        return [
            "name": .string(rawValue),
            "includesMargin":  .bool(includesMargin)
        ]
    }
}

extension Constraint.Relation: NodeRepresentable {
    
    func makeNode(in context: Context?) throws -> Node {
        
        return .string(rawValue)
    }
}

extension Multiplier: NodeRepresentable {
    
    func makeNode(in context: Context?) throws -> Node {
        
        return value == 1.0 ? .null : .string("* \(format(number: value, maximumFractionDigits: 3))")
    }
}

extension Constant: NodeRepresentable {
    
    func makeNode(in context: Context?) throws -> Node {
        
        return try makeNode(in: context, includePositivePrefix: false)
    }
    
    func makeNode(in context: Context?, includePositivePrefix: Bool) throws -> Node {
        
        return .object(try makeObject(in: context, includePositivePrefix: includePositivePrefix))
    }
    
    func makeObject(in context: Context?, includePositivePrefix: Bool) throws -> [String: Node] {
        
        return [
            "value": .string(format(number: abs(value))),
            "prefix": value < 0 ? .string("- ") : includePositivePrefix ? .string("+ ") : .null
        ]
    }
}

extension Color: NodeRepresentable {
    
    func makeNode(in context: Context?) throws -> Node {
        
        return .string(rgb)
    }
}

extension Footnote: NodeRepresentable {
    
    func makeNode(in context: Context?) throws -> Node {
        
        return [
            "marker": .string(marker),
            "text": .bytes(htmlText.bytes)
        ]
    }
}
