//
// Created by Kazuki Yamamoto on 2017/03/11.
// Copyright (c) 2017 Kazuki Yamamoto. All rights reserved.
//

import Foundation

func generateObjectMapper(jObjects: [String: [JProperty]]) -> String {
  var builder: String = ""

  builder += createHeader()

  for (name, properties) in jObjects {
    builder += createClass(className: name, members: properties)
    builder += "\n"
  }

  return builder
}

func createHeader() -> String {
  return "// generate by json2objectmapper\n" +
          "\n" +
          "import Foundation\n" +
          "import ObjectMapper\n" +
          "\n"
}

func createClass(className: String, members: [JProperty]) -> String {
  var builder: String = ""
  builder += "class \(getSwiftyClassName(name: className)): Mappable {\n"

  for member in members {
    builder += createMember(name: member.name, type: member.type, isOptional: member.isOptional)
  }

  builder += "\n"

  builder += createInitializer()

  builder += "\n"

  builder += createMapping(members: members)

  builder += "}\n"

  return builder
}

func createMember(name: String, type: JType, isOptional: Bool) -> String {
  return "    var \(getSwiftyMemberName(name: name)): \(translateJTypeToSwiftType(type: type, isOptional: isOptional))\n"
}

func createInitializer() -> String {
  return "    required init?(map: Map) {\n" +
          "    }\n"
}

func createMapping(members:[JProperty]) -> String {
  var builder = ""

  builder += "    func mapping(map:Map) {\n"

  for member in members {
    builder += "        \(getSwiftyMemberName(name: member.name)) <- map[\"\(member.name)\"]\n"
  }

  builder += "    }\n"

  return builder
}

func translateJTypeToSwiftType(type: JType, isOptional: Bool) -> String {
  switch type {
  case .int:
    return "Int" + getIfOptional(optional: isOptional)
  case .double:
    return "Double" + getIfOptional(optional: isOptional)
  case .string:
    return "String" + getIfOptional(optional: isOptional)
  case .bool:
    return "Bool" + getIfOptional(optional: isOptional)
  case .null:
    return "String" + getIfOptional(optional: isOptional)
  case let .array(type:type):
    return "[\(translateJTypeToSwiftType(type: type, isOptional: false))]" + getIfOptional(optional: isOptional)
  case let .object(name:name):
    return getSwiftyClassName(name: name) + getIfOptional(optional: isOptional)
  }
}

func getIfOptional(optional: Bool) -> String {
  return optional ? "?" : "!"
}

func getSwiftyMemberName(name:String) -> String {
  return convertSnakeCaseToCamelCase(input: name, lower: true)
}

func getSwiftyClassName(name: String) -> String {
  return convertSnakeCaseToCamelCase(input: name, lower: false)
}

func convertSnakeCaseToCamelCase(input:String, lower:Bool) -> String {
  var camelCase = input.capitalized.replacingOccurrences(of: "(\\w{0,1})_", with: "$1",options: .regularExpression,range: nil)

  if lower {
    let head = input.substring(to: input.index(input.startIndex, offsetBy: 1))
    camelCase.replaceSubrange(camelCase.startIndex ... camelCase.startIndex, with: head.lowercased())
  }

  return camelCase
}


