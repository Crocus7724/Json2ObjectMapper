//
// Created by Kazuki Yamamoto on 2017/03/11.
// Copyright (c) 2017 Kazuki Yamamoto. All rights reserved.
//

import Foundation

struct JProperty {
  let name: String
  let type: JType
  let isOptional: Bool
}

indirect enum JType {
  case string
  case int
  case double
  case bool
  case array(type: JType)
  case object(name: String)
  case null
}

func ==(a: JType, b: JType) -> Bool {
  switch (a, b) {
  case (.string, .string):
    return true
  case (.int, .int):
    return true
  case (.double, .double):
    return true
  case (.bool, .bool):
    return true
  case (.null, .null):
    return true
  case let (.array(type:x), .array(type:y)):
    return x == y
  case let (.object(name:x), .object(name:y)):
    return x == y
  default:
    return false
  }
}

func !=(a: JType, b: JType) -> Bool {
  return !(a == b)
}

func parseJson(json: Any, rootName:String) -> [String: [JProperty]]? {
  if let json = json as? [[String: Any]] {
    return parseArrayJson(json: json, rootName:rootName)
  }

  guard let json = json as? [String: Any] else {
    return nil
  }

  return convertFromJson(json: json, baseName:rootName)
}

func parseArrayJson(json: [[String: Any]], rootName:String) -> [String: [JProperty]]? {
  var jObj: [String: [JProperty]] = [:]

  for value in json {
    guard let obj = convertFromJson(json: value, baseName:rootName) else {
      return nil
    }
    jObj = margeJObject(original: jObj, other: obj)
  }

  return jObj
}

func convertFromJson(json: [String: Any], baseName:String) -> [String: [JProperty]]? {
  var name: String
  var type: JType
  var jObj: [String: [JProperty]] = [:]
  var properties:[JProperty] = []

  for (key, value) in json {
    name = key

    type = getType(value: value)

    if case .object = type {
      type = .object(name: name)
      guard let value = value as? [String: Any] else {
        return nil
      }

      guard let obj = convertFromJson(json: value, baseName: name) else {
        return nil
      }

      jObj = margeJObject(original: jObj, other: obj)
    }else if case .array(type:let t) = type {
      if case .object = t {
        guard let value = value as? [String: Any], let obj = convertFromJson(json: value, baseName:name) else {
          return nil
        }
        jObj = margeJObject(original: jObj, other: obj)
      }
    }
    properties.append(JProperty(name: name, type: type, isOptional: type == .null))
  }
  jObj[baseName] = properties

  return jObj
}

func getType(value: Any?) -> JType {
  switch value {
  case is Int:
    return .int
  case is Double:
    return .double
  case is Bool:
    return .bool
  case let value as Array<Any>:
    let type = getType(value: value.first)

    return .array(type: getType(value: type))
  case is [String: Any]:
    return .object(name: "")
  case is String:
    return .string
  default:
    return .null
  }
}

func margeJObject(original: [String: [JProperty]], other: [String: [JProperty]]) -> [String: [JProperty]] {
  var original = original
  for (name, properties) in other {
    guard let values = original[name] else {
      original[name] = properties
      continue
    }

    var buf: [JProperty] = []

    for prop in properties {
      if let value = values.first(where: { value in value.name == prop.name }) {
        if prop.type != value.type {
          buf.append(JProperty(name: value.name, type: .string, isOptional:prop.type == .null || value.isOptional))
        } else {
          buf.append(JProperty(name: value.name, type: value.type, isOptional: prop.type == .null || value.isOptional))
        }
      } else {
        buf.append(JProperty(name: prop.name, type: prop.type, isOptional: true))
      }
    }

    for value in values {
      guard !properties.contains(where: { property in property.name == value.name })  else {
        continue
      }

      buf.append(JProperty(name: value.name, type: value.type, isOptional: true))
    }

    original[name] = buf
  }

  return original
}