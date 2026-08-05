//
//  RequestsEquals.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 06/10/25.
//

class RequestsEquals {
    
    public static func areObjectsEqual(_ a: Any?, _ b: Any?) -> Bool {
        if a == nil && b == nil { return true }
        guard let a = a, let b = b else { return false }

        if let dictA = a as? [String: Any], let dictB = b as? [String: Any] {
            if dictA.count != dictB.count { return false }
            for key in dictA.keys {
                guard let valueB = dictB[key] else { return false }
                if !areObjectsEqual(dictA[key], valueB) { return false }
            }
            return true
        }

        if let listA = a as? [Any], let listB = b as? [Any] {
            if listA.count != listB.count { return false }
            for i in 0..<listA.count {
                if !areObjectsEqual(listA[i], listB[i]) { return false }
            }
            return true
        }

        return String(describing: a) == String(describing: b)
    }
    
    public static func areNamesEqual(_ namesA: [String]?, _ namesB: [String]?) -> Bool {
        let setA = Set(namesA ?? [])
        let setB = Set(namesB ?? [])

        if namesA == nil && (namesB == nil || namesB?.isEmpty == true) { return true }
        if namesB == nil && (namesA?.isEmpty == true) { return true }

        if setA.count != namesA?.count || setB.count != namesB?.count { return false }

        return setA == setB
    }
    
    public static func isNonRevokedEqual(
            _ a: AnonCredsNonRevokedInterval?,
            _ b: AnonCredsNonRevokedInterval?
        ) -> Bool {
            if a == nil {
                return b == nil || (b?.from == nil && b?.to == nil)
            }
            if b == nil {
                return a?.from == nil && a?.to == nil
            }
            return a?.from == b?.from && a?.to == b?.to
        }
        
        public static func areRestrictionsEqual(
            _ restrictionsA: [[String: Any]]?,
            _ restrictionsB: [[String: Any]]?
        ) -> Bool {
            if restrictionsA == nil {
                return restrictionsB == nil || restrictionsB?.isEmpty == true
            }
            if restrictionsB == nil {
                return restrictionsA?.isEmpty == true
            }

            var bList = restrictionsB!
            for aItem in restrictionsA! {
                if let index = bList.firstIndex(where: { areObjectsEqual($0, aItem) }) {
                    bList.remove(at: index)
                } else {
                    return false
                }
            }
            return true
        }
        
        public static func areAnonCredsProofRequestsEqual(
            _ a: AnonCredsProofRequest,
            _ b: AnonCredsProofRequest
        ) -> Bool {
            if !isNonRevokedEqual(a.nonRevoked, b.nonRevoked) {
                return false
            }

            let attrsA = Array(a.requestedAttributes.values)
            var attrsB = Array(b.requestedAttributes.values)

            if attrsA.count != attrsB.count { return false }

            for attrA in attrsA {
                if let index = attrsB.firstIndex(where: {
                    $0.name == attrA.name &&
                    RequestsEquals.areNamesEqual($0.names, attrA.names) &&
                    isNonRevokedEqual($0.nonRevoked, attrA.nonRevoked) &&
                    areRestrictionsEqual($0.restrictions as! [[String : Any]], attrA.restrictions as! [[String : Any]])
                }) {
                    attrsB.remove(at: index)
                } else {
                    return false
                }
            }

            let predsA = Array(a.requestedPredicates.values)
            var predsB = Array(b.requestedPredicates.values)

            if predsA.count != predsB.count { return false }

            for predA in predsA {
                if let index = predsB.firstIndex(where: {
                    $0.name == predA.name &&
                    $0.pType == predA.pType &&
                    $0.pValue == predA.pValue &&
                    isNonRevokedEqual($0.nonRevoked, predA.nonRevoked) &&
                    areRestrictionsEqual($0.restrictions as! [[String : Any]], predA.restrictions as! [[String : Any]])
                }) {
                    predsB.remove(at: index)
                } else {
                    return false
                }
            }

            return true
        }
    

}
