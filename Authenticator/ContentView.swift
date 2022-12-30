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

struct AddItem: View {
    @Environment (\.presentationMode) var presentationMode
    @State var input = "test"
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
            Button(action: {}, label: {
                Text("Save")
            })
                .niceButton()
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


struct Previews_ContentView_Previews: PreviewProvider {
    static var previews: some View {
        /*@START_MENU_TOKEN@*/Text("Hello, World!")/*@END_MENU_TOKEN@*/
    }
}
