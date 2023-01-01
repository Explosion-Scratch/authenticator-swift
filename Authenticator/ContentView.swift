//Created by Explosion-Scratch

import SwiftUI
import CoreData

//TODO: Add deleting and editing items
//TODO: Allow export/import of JSON for all items

var text = [
    "no_selection": "Select an item from the menu =)",
    "add_item": "Add item",
    "no_title": "No title",
    "add_title": "Add 2fa code",
    "url_placeholder": "Paste URL here",
    "auth_accounts": "Accounts: ",
    "generate_code_err": "Error generating code",
    "last_copied": "Last copied on",
    "created_on": "Created on",
    "copied": "Copied!",
    "click_to_copy": "Click anywhere to copy",
    "nothing_yet": "Nothing here yet, add a new auth URL?",
]

struct ContentView: View {
    @State var addingItem = false
    @State var selectedItem: Item? = nil
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        entity: Item.entity(),
        sortDescriptors: [NSSortDescriptor(key: "dateCreated", ascending: false)]
    ) private var allItems: FetchedResults<Item>
    init() {
        initializeJS()
    }
    
    private func deleteItem(at offsets: IndexSet) {
        offsets.forEach {index in
            let item = allItems[index]
            viewContext.delete(item)
            do {
                try viewContext.save()
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    private func getKey(_ key: String, cb: @escaping (JSValue?) -> Void) -> String {
        if key.isEmpty {
            return "Error"
        }
        
        let callback : @convention(block) (JSValue?) -> Void = { calledBackValue in
            cb(calledBackValue)
        }
        
        let js_cb = JSValue.init(object: callback, in: jsContext)
        
        let result = jsContext?
            .objectForKeyedSubscript("getToken")
            .call(withArguments: [selectedItem?.secretKey!, js_cb])
        
        return ""
    }
    
    private func updateCode(){
        getKey((selectedItem?.secretKey!)!, cb: {value in
            authCode = value!.toString()
            loading = false
            return
        })
    }
    
    private func formatDate(date: Date) -> String{
        let format = DateFormatter()
        format.dateFormat = "MMM d, yyyy h:mm a"
        return format.string(from: date)
    }
    
    @State private var loading = true
    @State private var authCode = ""
    @State private var error = ""
    @State private var justCopied = false
    @State private var progressAmount = 10.0;
    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    var body: some View {
        ZStack {
            NavigationView {
                List {
                    ForEach(allItems) {item in
                        HStack {
                            Text(item.label ?? text["no_title"]!)
                                .foregroundColor(Color.accentColor)
                        }.onTapGesture {
                            error = ""
                            loading = true
                            selectedItem = item
                        }
                    }
                }
                .navigationTitle(text["auth_accounts"]!)
                .listStyle(.sidebar)
                .toolbar {
                    ToolbarItem {
                        Button(action: {
                            addingItem.toggle()
                        }) {
                            Label(text["add_item"]!, systemImage: "plus")
                        }
                    }
                }
                ZStack(alignment: .bottom) {
                    VStack {
                        if (selectedItem != nil) {
                            ProgressView(value: progressAmount, total: 100)
                                .onReceive(timer, perform: {a in
                                    progressAmount = (jsContext?.objectForKeyedSubscript("getTimeRemaining").call(withArguments: []).toDouble())!
                                })
                            Spacer()
                            VStack {
                                if loading {
                                    ProgressView()
                                        .cornerRadius(0)
                                } else if error.isEmpty {
                                    Text(authCode)
                                        .font(.largeTitle)
                                        .fontWeight(.heavy)
                                } else {
                                    Text("There was an error: \(error)")
                                }
                                Text(selectedItem?.label ?? "No label")
                                Text("\(text["created_on"]!) \(formatDate(date: (selectedItem?.dateCreated)!))")
                                    .padding(.top)
                                    .opacity(0.4)
                                    .font(.body)
                                    .italic()
                                Text("\(text["last_copied"]!) \(formatDate(date: (selectedItem?.lastCopied)!))")
                                    .opacity(0.4)
                                    .font(.body)
                                    .italic()
                            }.task {
                                if selectedItem == nil {
                                    return
                                }
                                if selectedItem?.secretKey == nil {
                                    error = text["generate_code_err"]!
                                    return
                                }
                                //so we don't need to mark updateCode as objc
                                updateCode()
                            }.onReceive(timer, perform: {a in
                                updateCode()
                            })
                            Spacer()
                        } else {
                            if (allItems.isEmpty) {
                                Text(text["nothing_yet"]!)
                                    .italic()
                                Button(action: {
                                    addingItem = true
                                }, label: {
                                    Label(text["add_item"]!, systemImage: "plus")
                                })
                                    .niceButton(foregroundColor: Color.white, backgroundColor: Color.accentColor)
                                    .frame(maxWidth: 100)
                            } else {
                                Text(text["no_selection"]!)
                            }
                        }
                    }
                    if (selectedItem != nil){
                        Text(justCopied ? text["copied"]! : text["click_to_copy"]!)
                            .padding(.bottom)
                            .italic()
                            .foregroundColor(.accentColor)
                    }
                }
                // End zstack
            }.onTapGesture {
                if selectedItem != nil && authCode != nil && loading != true {
                    justCopied = true
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.writeObjects([authCode as NSString])
                    Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { timer in
                        justCopied = false
                    }
                }
            }
            
            .sheet(isPresented: $addingItem, content: {
                AddItem(addingItem: $addingItem).environment(\.managedObjectContext, CoreDataManager.shared.persistentContainer.viewContext)
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

class ItemClass: NSObject {
    var dateCreated: Date = Date()
    var label: String = ""
    // var lastCopied: Date = Date()
    var secretKey: String = ""
    // var namespace: String = ""
    var type: String = ""
    var account: String = ""
    
    init(account: String?, dateCreated: Date, label: String, secretKey: String, type: String) {
        self.dateCreated = dateCreated
        self.label = label
        self.secretKey = secretKey
        self.type = type
        self.account = account ?? ""
    }
}

struct AddItem: View {
    @Binding var addingItem: Bool
    @Environment (\.managedObjectContext) private var viewContext
    @Environment (\.presentationMode) var presentationMode
    @State var input = "test"
    @State var disabled = true
    @State var status = "nothing"
    
    func addOtp(otp: String){
        do {
            let o = otp.decodeUrl()
            guard let parsed = jsContext?.objectForKeyedSubscript("parseOTP")?.call(withArguments: [o!]).toDictionary() else {
                print("Parsing otp failed: \(otp)")
                return
            }
            let item = Item(context: viewContext)
            print(item)
            for (key, value) in parsed {
                print("Value: \(value) for key: \(key)")
            }
            item.dateCreated = Date()
            item.uuid = UUID()
            item.accountName = (parsed["account"] as? String) ?? ""
            item.label = parsed["name"] as! String
            item.secretKey = parsed["secret"] as! String
            item.type = parsed["type"] as! String
            try viewContext.save()
        } catch {
            print(error.localizedDescription)
        }
    }
    
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
                })
            Button(action: {
                if disabled {return} else {
                    addOtp(otp: input)
                    addingItem = false
                }
            }, label: {
                Text("Save")
            })
            .niceButton(
                foregroundColor: disabled ? Color.gray : Color.white,
                backgroundColor: disabled ?  Color.gray.opacity(0) : Color.accentColor
            )
                .border(disabled ? .gray : Color.gray.opacity(0))
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
