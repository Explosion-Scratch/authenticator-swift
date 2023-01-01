//Created by Explosion-Scratch

import SwiftUI
import CoreData

var text = [
    "no_selection": "Select an item from the menu =)",
    "add_item": "Add item",
    "no_title": "No title",
    "add_title": "Add 2fa code",
    "url_placeholder": "Paste URL here",
]

struct ContentView: View {
    @State var addingItem = true
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        entity: Item.entity(),
        sortDescriptors: [NSSortDescriptor(key: "dateCreated", ascending: false)]
    ) private var allItems: FetchedResults<Item>
    init() {
        initializeJS()
    }
    var body: some View {
        ZStack {
            NavigationView {
                List {
                    ForEach(allItems){item in
                        HStack {
                            Text(item.label ?? text["no_title"]!)
                        }
                    }
                }
                .toolbar {
                    ToolbarItem {
                        Button(action: {
                            addingItem.toggle()
                        }) {
                            Label(text["add_item"]!, systemImage: "plus")
                        }
                    }
                }
                Text(text["no_selection"]!)
            }
            
            .sheet(isPresented: $addingItem, content: {
                AddItem()
            })
        }
    }
}

extension String: Error {}

extension String {
    var validURL: Bool {
        get {
            let regEx = "((?:http|https)://)?(?:www\\.)?[\\w\\d\\-_]+\\.\\w{2,3}(\\.\\w{2})?(/(?<=/)(?:[\\w\\d\\-./_]+)?)?"
            let predicate = NSPredicate(format: "SELF MATCHES %@", argumentArray: [regEx])
            return predicate.evaluate(with: self)
        }
    }
}

import JavaScriptCore
var jsContext = JSContext()

func initializeJS(){
    print("INITIALIZE JS")
    if let jsSourcePath = Bundle.main.path(forResource: "main", ofType: "js") {
        do {
            // Load its contents to a String variable.
            let jsSourceContents = try String(contentsOfFile: jsSourcePath)
            jsContext!.evaluateScript(jsSourceContents)
        }
        catch {
            print(error.localizedDescription)
        }
    }
}

func addOtp(){
    
}

struct AddItem: View {
    @Environment (\.presentationMode) var presentationMode
    @State var input = "test"
    @State var disabled = true
    @State var status = "nothing"
    var body: some View {
        VStack(alignment: .trailing) {
            Button {
                presentationMode.wrappedValue.dismiss()
            } label: {
                Image(systemName: "x.circle")
                    .font(.title2)
            }
            .buttonStyle(.plain)
            .opacity(0.3)
            .padding()
            .frame(maxWidth: .infinity, alignment: .trailing)
            Spacer()
        }
        VStack(alignment: .center){
            // Example QR Code: otpauth://totp/Heroku%3ARandom%20Person?secret=PFFXKOJMGU4EYOTVJJRFORRQ&issuer=Heroku
            Text(text["add_title"]!)
                .font(.title2)
            TextField(text["url_placeholder"]!, text: $input)
                .onChange(of: input, perform: {newValue in
                    let isValid = jsContext?.objectForKeyedSubscript("isOTPUrl")?.call(withArguments: [input])?.toBool() ?? false
                    status = String(isValid)
                    if isValid {
                        disabled = false
                    } else {
                        disabled = true
                    }
                    return
                    let valid = NSRegularExpression("otpauth://([ht]otp)/(?:[a-zA-Z0-9%]+:)?([^?]+)?secret=([0-9A-Za-z]+)(?:.*(?:<?counter=)([0-9]+))?")
                    if (valid.matches(input)){
                        let decoded = input.decodeUrl()
                        let url = URL(string: decoded!)
                        let components = URLComponents(url: URL(string: decoded!)!, resolvingAgainstBaseURL: false)
                        disabled = false
                    } else {disabled = true}
                })
            if !input.isEmpty {
                Text(status)
            }
            Button(action: {
                addOtp(input)
            }, label: {
                Text("Save")
            })
            .niceButton(
                foregroundColor: disabled ? Color.gray : Color.white,
                backgroundColor: disabled ? Color("#00000000") : Color.accentColor
            )
                .border(disabled ? .gray : Color("#00000000"))
                .cornerRadius(5)
                .opacity(disabled ? 0.3 : 1)
                .onHover { inside in
                    if inside && disabled {
                        NSCursor.operationNotAllowed.push()
                    } else {
                        NSCursor.pop()
                    }
                }
        }
            .frame(minWidth: 500.0)
            .padding(.all, 30.0)
    }
}

// https://stackoverflow.com/questions/58419161
struct NiceButtonStyle: ButtonStyle {
  var foregroundColor: Color
  var backgroundColor: Color
  var pressedColor: Color

  func makeBody(configuration: Self.Configuration) -> some View {
    configuration.label
      .font(.headline)
      .frame(maxWidth: .infinity)
      .padding(10)
      .foregroundColor(foregroundColor)
      .background(configuration.isPressed ? pressedColor : backgroundColor)
      .cornerRadius(5)
  }
}

extension View {
  func niceButton(
    foregroundColor: Color = .white,
    backgroundColor: Color = .gray,
    pressedColor: Color = .accentColor
  ) -> some View {
    self.buttonStyle(
      NiceButtonStyle(
        foregroundColor: foregroundColor,
        backgroundColor: backgroundColor,
        pressedColor: pressedColor
      )
    )
  }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let persistedContainer = CoreDataManager.shared.persistentContainer
        ContentView().environment(\.managedObjectContext, persistedContainer.viewContext)
    }
}

extension NSRegularExpression {
    convenience init(_ pattern: String) {
        do {
            try self.init(pattern: pattern)
        } catch {
            preconditionFailure("Illegal regular expression: \(pattern).")
        }
    }
}

extension NSRegularExpression {
    func matches(_ string: String) -> Bool {
        let range = NSRange(location: 0, length: string.utf16.count)
        return firstMatch(in: string, options: [], range: range) != nil
    }
}

extension String
{
    func encodeUrl() -> String?
    {
        return self.addingPercentEncoding( withAllowedCharacters: NSCharacterSet.urlQueryAllowed)
    }
    func decodeUrl() -> String?
    {
        return self.removingPercentEncoding
    }
}
