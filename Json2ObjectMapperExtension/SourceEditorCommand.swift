//
//  SourceEditorCommand.swift
//  Json2ObjectMapperExtension
//
//  Created by Kazuki Yamamoto on 2017/03/11.
//  Copyright © 2017 Kazuki Yamamoto. All rights reserved.
//

import Foundation
import XcodeKit
import Cocoa

enum JsonToObjectMapperError: Error {
  case clipboardIsNil
  case cannotConvertData
  case cannotConvertJson
  case jsonParseFail
  case unknown
}

class SourceEditorCommand: NSObject, XCSourceEditorCommand {

  func perform(with invocation: XCSourceEditorCommandInvocation, completionHandler: @escaping (Error?) -> Void) -> Void {
    // Implement your command here, invoking the completion handler when done. Pass it nil on success, and an NSError on failure.

    let pb = NSPasteboard.general()
    
    guard let paste = pb.string(forType: NSPasteboardTypeString) else {
      completionHandler(JsonToObjectMapperError.clipboardIsNil)
      return
    }

    guard let data = paste.data(using: .utf8) else {
      print("cannot convert string to data")
      completionHandler(JsonToObjectMapperError.cannotConvertData)
      return
    }

    guard let json = try? JSONSerialization.jsonObject(with: data) else {
      print("cannot convert data to json")
      completionHandler(JsonToObjectMapperError.cannotConvertJson)
      return
    }

    guard let object = parseJson(json: json, rootName: "Example") else {
      print("parse json fail")
      completionHandler(JsonToObjectMapperError.jsonParseFail)
      return
    }

    let mappableClass = generateObjectMapper(jObjects: object)
    let buffer = invocation.buffer
    guard let selection = buffer.selections.firstObject as? XCSourceTextRange else {
      completionHandler(JsonToObjectMapperError.unknown)
      return
    }
    
    invocation.buffer.lines.insert(mappableClass, at: selection.start.line)
    
    completionHandler(nil)
  }

}
