//
//  SurveyView.swift
//  SwiftSurvey
//
//  Created by CC Laan on 6/13/21.
//  Edited and Maintained in Repo by James Jolly since Feb, 2025
//

import SwiftUI
import Combine
//import KeyboardAware


// TODO: the introspect lib might also be useful
// https://stackoverflow.com/questions/59003612/extend-swiftui-keyboard-with-custom-button

struct TextEditorWithDone: UIViewRepresentable {
    
    @Binding var text: String
    
    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }
    
    func makeUIView(context: Context) -> UITextView {
        
        let textfield = UITextView()
        textfield.font = UIFont.systemFont(ofSize: UIFont.systemFontSize + 2)
        
        let toolBar = UIToolbar(frame: CGRect(x: 0, y: 0, width: textfield.frame.size.width, height: 44))
        let doneButton = UIBarButtonItem(title: "Dismiss", style: .done, target: self, action: #selector(textfield.doneButtonTapped(button:)))
        
        let spacer = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)

        toolBar.items = [spacer, doneButton]
        
        textfield.inputAccessoryView = toolBar
        textfield.delegate = context.coordinator
        textfield.backgroundColor = .clear
        textfield.textColor = .black
        return textfield
        
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        uiView.text = text
        
    }
    
}


extension TextEditorWithDone {
    class Coordinator: NSObject, UITextViewDelegate {
        @Binding var text: String

        init(text: Binding<String>) {
            _text = text
        }

        func textViewDidChangeSelection(_ textView: UITextView) {
            DispatchQueue.main.async {
                self.text = textView.text ?? ""
            }
        }
    }
}


extension  UITextView{
    @objc func doneButtonTapped(button:UIBarButtonItem) -> Void {
       self.resignFirstResponder()
    }

}

struct TextFieldWithDone: UIViewRepresentable {
    
    let placeHolder : String
    @Binding var text: String
    var keyType: UIKeyboardType
    let showToolbar = false
    
    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    func makeUIView(context: Context) -> UITextField {
        let textfield = UITextField()
        textfield.placeholder = placeHolder
        textfield.keyboardType = keyType
        textfield.borderStyle = .roundedRect
        textfield.returnKeyType = .done
        textfield.autocorrectionType = .no
        textfield.text = text
        
        
        textfield.addTarget(textfield, action: #selector(textfield.doneButtonTapped(button:)), for: .editingDidEndOnExit)
        
        if showToolbar {
            let toolBar = UIToolbar(frame: CGRect(x: 0, y: 0, width: textfield.frame.size.width, height: 44))
            let doneButton = UIBarButtonItem(title: "Dismiss", style: .done, target: self, action: #selector(textfield.doneButtonTapped(button:)))
            let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
            toolBar.items = [spacer, doneButton]
            textfield.inputAccessoryView = toolBar
        }
                
        textfield.delegate = context.coordinator
        return textfield
    }

    func updateUIView(_ view: UITextField, context: Context) {
        view.text = text
    }
}

extension TextFieldWithDone {
    class Coordinator: NSObject, UITextFieldDelegate {
        @Binding var text: String

        init(text: Binding<String>) {
            _text = text
        }

        func textFieldDidChangeSelection(_ textField: UITextField) {
            DispatchQueue.main.async {
                self.text = textField.text ?? ""
            }
        }
    }
}

extension  UITextField{
    @objc func doneButtonTapped(button:UIBarButtonItem) -> Void {
       self.resignFirstResponder()
    }

}

extension UIView {
    var firstResponder: UIView? {
        guard !isFirstResponder else { return self }

        for subview in subviews {
            if let firstResponder = subview.firstResponder {
                return firstResponder
            }
        }

        return nil
    }
}

final class KeyboardResponder: ObservableObject {
    private var notificationCenter: NotificationCenter
    
    @Published private(set) var currentHeight: CGFloat = 0
    @Published private(set) var isShowing: Bool = false

    init(center: NotificationCenter = .default) {
        notificationCenter = center
        notificationCenter.addObserver(self, selector: #selector(keyBoardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(keyBoardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    deinit {
        notificationCenter.removeObserver(self)
    }

    @objc func keyBoardWillShow(notification: Notification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            currentHeight = keyboardSize.height
        }
        isShowing = true
    }

    @objc func keyBoardWillHide(notification: Notification) {
        currentHeight = 0
        isShowing = false
    }
}


extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct CustomButtonStyle: ButtonStyle {
    let bgColor : Color
    func makeBody(configuration: Self.Configuration) -> some View {
        return configuration.label
            //.padding(EdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20))
            //.frame(width: 104, height: 40)
            
            .padding(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
            .frame(minWidth: 104, minHeight: 40)
            
            .background(bgColor)
            .cornerRadius(20.0)
            .foregroundColor(Color.white)
            .opacity(configuration.isPressed ? 0.7 : 1)
            .scaleEffect(configuration.isPressed ? 0.8 : 1)
            .animation(.easeInOut, value: 0.2)
            
    }
}

struct YesNoButtonStyle: ButtonStyle {
    let bgColor : Color
    init(bgColor: Color = Color.gray) {
        self.bgColor = bgColor
    }
    func makeBody(configuration: Self.Configuration) -> some View {
        return configuration.label
            .padding(EdgeInsets(top: 20, leading: 40, bottom: 20, trailing: 40))
            .background(bgColor)
            .cornerRadius(26.0)
            .foregroundColor(Color.white)
            .opacity(configuration.isPressed ? 0.7 : 1)
            .scaleEffect(configuration.isPressed ? 0.8 : 1)
            .animation(.easeInOut, value: 0.2)
            
    }
}

struct RoundedCornersShape: Shape {
    let corners: UIRectCorner
    let radius: CGFloat
    let extraHeight : CGFloat
    func path(in rect: CGRect) -> Path {
        let rectExtended = CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: rect.height + extraHeight)
        let path = UIBezierPath(roundedRect: rectExtended,
                                byRoundingCorners: corners,
                                cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

// Extension to do both stroke and fill at same time
extension Shape {
    func fill<Fill: ShapeStyle, Stroke: ShapeStyle>(_ fillStyle: Fill, strokeBorder strokeStyle: Stroke, lineWidth: CGFloat = 1) -> some View {
        self
            .stroke(strokeStyle, lineWidth: lineWidth)
            .background(self.fill(fillStyle))
    }
}


struct BinaryChoiceQuestionView : View {
    
    @State var selectedIndices : Set<Int> = []
    @ObservedObject var question : BinaryQuestion
    
    let onChoiceMade : (() -> Void)?
    
    @State private var autoAdvanceProgress : CGFloat = 0.0
    @State private var goingToNext : Bool = true
    
    var body : some View {
        
        VStack {
            
            //Text(question.title).font(.title).padding(16)
            Text(question.title).font(.title).fontWeight(.bold).padding(16)
            
            //Spacer()
            //Text("Choice2: ".appendingFormat("%i", selectedIndices.count)).opacity(0.5) // view refresh hack
            
            HStack {
                
                Button(action: { selectChoice(0) }, label: {
                    Text(question.choices[0].text).font(.title).bold()
                }).buttonStyle(YesNoButtonStyle(bgColor: selectedIndices.contains(0) ? Color.green : Color.gray))
                .padding(6)
                
                
                Button(action: { selectChoice(1) }, label: {
                    Text(question.choices[1].text).font(.title)
                }).buttonStyle(YesNoButtonStyle(bgColor: selectedIndices.contains(1) ? Color.green : Color.gray))
                .padding(6)
                
                
            }
            //.frame(height: UIScreen.main.bounds.height * 0.6)
            .padding(EdgeInsets(top: 40, leading: 20, bottom: 20, trailing: 20))
            
        }.onAppear(perform: {
            self.autoAdvanceProgress = 0
            self.updateChoices()
        })
        .frame(maxWidth: .infinity) // stretch whole width
        //.background(Color.red)
        .overlay(Rectangle().frame(width: autoAdvanceProgress, height: 3, alignment: .top).foregroundColor(Color(.systemBlue)), alignment: .top)
        .animation(.easeInOut, value: 0.51)
        
    }
    
    // Update the local @State with selected choice
    // TODO: figure out how to directly use the question to update UI
    //        tried observable stuff with no luck
    func updateChoices() {
        selectedIndices = []
        for (i,choice) in question.choices.enumerated() {
            if choice.selected {
                selectedIndices.insert(i)
            }
        }
    }
    
    func selectChoice( _ choiceIndex : Int ) {
        selectedIndices = []
        selectedIndices.insert(choiceIndex)
        //question.choices[choiceIndex].selected = true;
        for (i,choice) in question.choices.enumerated() {
            choice.selected = i == choiceIndex
            question.choices[i].selected = choice.selected
        }
        
        self.goingToNext = true
        if question.autoAdvanceOnChoice {
            self.autoAdvanceProgress = UIScreen.main.bounds.width
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.51) {
            if question.autoAdvanceOnChoice {
                self.onChoiceMade?()
            }
            self.autoAdvanceProgress = 0
        }
        
        
    }
    
}



struct ContactFormQuestionView : View {
    
    @ObservedObject var question : ContactFormQuestion
    
    init(question: ContactFormQuestion ) {
        
        self.question = question
    }
    
    
    var body : some View {
        VStack {
            //Text(question.title).font(.title).padding(16)
            Text(question.title).font(.title).fontWeight(.bold).padding(16)

            VStack(alignment: .leading) {
                Text("Name (optional)")
                    .font(.callout)
                    .bold()
                TextField("Name", text: $question.name)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .disableAutocorrection(true)
            }.padding()
            
            
            VStack(alignment: .leading) {
                Text("Email Address")
                    .font(.callout)
                    .bold()
                TextField("Email Address", text: $question.emailAddress)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .disableAutocorrection(true)
                    .textContentType(.emailAddress)
                    
                    
            }.padding()
            
            VStack(alignment: .leading) {
                Text("Company ( optional )")
                    .font(.callout)
                    .bold()
                TextField("Company", text: $question.company)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .disableAutocorrection(true)
            }.padding()
            
            
            VStack(alignment: .leading) {
                Text("Comments ( optional )")
                    .font(.callout)
                    .bold()
                TextField("Comments / Feedback", text: $question.feedback)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .disableAutocorrection(true)
            }.padding()
                    
        }
        
                
    }
    
    
}



struct CommentsFormQuestionView : View {
    
    @ObservedObject var question : CommentsFormQuestion
    
    
    
    var body : some View {
        VStack {
            Text(question.title).font(.title).fontWeight(.bold).padding(EdgeInsets(top: 12, leading: 28, bottom: 2, trailing: 28)).foregroundColor(.black)
            Text(question.subtitle).font(.title3).italic().foregroundColor(.gray)
                .padding(EdgeInsets(top: 0, leading: 28, bottom: 1, trailing: 28))
            
            
            VStack(alignment: .leading) {

                Text("Answer"/*"Comments"*/)
                    .font(.callout)
                    .bold()
                    .foregroundColor(.black)

                
                TextField("# of servings", text: $question.feedback)
                    .textFieldStyle(PlainTextFieldStyle())
                    .frame(width: 75.0)
                    .background(RoundedRectangle(cornerRadius: 15)
                        .fill(Color.white))
                    .foregroundColor(.black)
                    .border(Color.black)

            }.padding()
            
        
        }
                
    }
    
}


struct InlineMultipleChoiceQuestionGroupView : View {
    
    @ObservedObject var group : InlineMultipleChoiceQuestionGroup
    @State var selectedIndices : Set<Int> = []
    
    @State var customText : String = ""
    
    var body: some View {
        
        VStack {
            Text(group.title).font(.title2).fontWeight(.bold).padding(EdgeInsets(top: 12, leading: 12, bottom: 1, trailing: 12)).foregroundColor(.black)
                
            ForEach(group.questions, id: \.uuid) { inline_question in
                
                if inline_question.choices.first!.allowsCustomTextEntry {
                    
                } else {
                InlineMultipleChoiceQuestionView(question: inline_question)
                    .padding(7)
                    .background(Color(.gray).opacity(0.15))
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(.systemGray5), lineWidth: 2))
                    .padding(EdgeInsets(top: 8, leading: 0, bottom: 0, trailing: 0))
                }
                    
            }
        }
        .frame(maxWidth: .infinity) // stretch whole width
        
    }
    
}


struct InlineMultipleChoiceQuestionView : View {
    
    @ObservedObject var question : MultipleChoiceQuestion
    @State var selectedChoices : Set<UUID> = []
    
    let colors : [Color] = [.red, .orange, .yellow, .green]
    private func getColor( _ choice : MultipleChoiceResponse ) -> Color {
        return self.colors[ self.question.choices.firstIndex(where: { $0.uuid == choice.uuid })! ]
    }
    var body: some View {
        
        VStack {
        
            Text(question.title).font(.body).fontWeight(.semibold).foregroundColor(.black/*Color(.label)*/).opacity(0.6).padding(2).lineLimit(nil).fixedSize(horizontal: false, vertical: true)

            HStack {
                
            ForEach(question.choices, id: \.uuid) { choice in
                
                
                Button(action: { selectChoice(choice) }, label: {
                    
                    Spacer()
                    
                    Text( choice.text )
                        .font(.system(size: 12, weight: choice.selected ? .bold : .semibold)).multilineTextAlignment(.center)
                        .foregroundColor( choice.selected ? .black : .gray.opacity(0.65) )
                        
                        .padding(2)
                    
                    Spacer()
                    
                    
                })
                .frame(width: 80, height: 40)
                
                .background(getColor(choice).opacity( choice.selected ? 0.25 : 0.1 ))
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12)
                            .stroke( choice.selected ? getColor(choice) : getColor(choice).opacity(0.0), lineWidth: 2) )
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white))
                .padding(2)
                
                .opacity( (selectedChoices.count > 0 && !selectedChoices.contains(choice.uuid)) ? 0.5 : 1.0 )
                
            }
            }
            
        }
//        .overlay(Rectangle().frame(width: 180, height: 1, alignment: .top).foregroundColor(Color(.systemGray5)), alignment: .top)

        
    }
    
    
    func selectChoice( _ selectedChoice : MultipleChoiceResponse ) {
        // required to refresh the view ...
        // not sure how to do it automatically
        
        // when new choice == choice in list :
        //  - if its in there, remove it
        //  - if not add it
        // else
        //  - only remove if multiple
        
        
        if question.allowsMultipleSelection {

            assert(false) // TODO: fix

        } else {

            selectedChoices = []
            
            for choice in question.choices {
                if selectedChoice.uuid == choice.uuid {
                    choice.selected = true;
                    selectedChoices = [choice.uuid]
                } else {
                    choice.selected = false;
                }

            }

        }
        
    }
    
    
}




struct MultipleChoiceResponseView : View {
    
    @Environment(\.colorScheme) var colorScheme
    
    @ObservedObject var question : MultipleChoiceQuestion
    @ObservedObject var choice : MultipleChoiceResponse
    
    @Binding public var selectedIndices : Set<Int>
    
    var scrollProxy : ScrollViewProxy
    
    @State private var customTextEntry: String = ""
    
    static let OtherTextFieldID : Int = 8919
    
    var body : some View {
        
        VStack {
                        
            
            Button(action: { selectChoice(choice) }, label: {
                
                Circle().fill(choice.selected ? Color.green : Color(.systemGray5)).frame(width: 30, height: 30, alignment: .center).padding(EdgeInsets.init(top: 0, leading: 20, bottom: 0, trailing: 0))
                    .overlay(
                        choice.selected ?
                            Image(systemName: "checkmark").foregroundColor(.white)
                            .padding(EdgeInsets(top:0, leading: 20, bottom: 0, trailing: 0)): nil
                        
                    )
                    
                Text( choice.text )
                    .font( .title3)
                    .fontWeight( choice.selected ? .bold : .regular )
                    .foregroundColor( Color(.black)/*Color(.label)*/ )
                    .padding()
                

                Spacer()
                
                
            })
            
            
            .cornerRadius(selectedIndices.count == 0 ? 28 : 28)
            .overlay(RoundedRectangle(cornerRadius: 28)
                        .stroke( choice.selected ? Color.green : Color(.systemGray5), lineWidth: 2) )
            .background(RoundedRectangle(cornerRadius: 28).fill(Color.white))
            .padding(EdgeInsets.init(top: 3, leading: 35, bottom: 3, trailing: 35))
            
            
            if choice.allowsCustomTextEntry && choice.selected {
                
//                HStack {
                ScrollView(.horizontal) {
                    TextFieldWithDone(placeHolder:"Tap to Edit!", text: $customTextEntry, keyType: .default)
                        .onChange(of: customTextEntry, perform: { value in
                            self.updateCustomText(choice, value)
                        })
                        .frame(minWidth: 250)
                        .padding(EdgeInsets(top: 16, leading: 10, bottom: 3, trailing: 10))
                        .foregroundColor(Color(.systemGray2))
                        .id(Self.OtherTextFieldID)
                    
                        .onAppear(perform: {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                self.scrollProxy.scrollTo(Self.OtherTextFieldID, anchor: .bottom)
                                
                                if let text = choice.customTextEntry {
                                    self.customTextEntry = text
                                }
                            }
                        })
                }
                
                
                
                .background(
                    RoundedCornersShape(corners: [.bottomLeft, .bottomRight], radius: 14, extraHeight: 22)
                        .fill(Color(.systemGray6), strokeBorder: Color(.systemGray2), lineWidth: 2)
                        //.stroke(Color(UIColor.systemGray6), lineWidth: 5)
                        .offset(y:-14)
                )
                .padding(EdgeInsets.init(top: 5, leading: 35, bottom: 12, trailing: 35))
                .offset(y: -24.0)
                .zIndex(-1)
                
                
                
            }
            
        }
        
    }
    
    
    
    func selectChoice( _ selectedChoice : MultipleChoiceResponse ) {
        // required to refresh the view ...
        // not sure how to do it automatically
        //selectedChoiceIndex = -1
        
        if question.allowsMultipleSelection {
            
            for (i,choice) in question.choices.enumerated() {
                if selectedChoice.uuid == choice.uuid {
                    if selectedIndices.contains(i) {
                        selectedIndices.remove(i)
                        question.choices[i].selected = false;
                        selectedChoice.selected = false;
                        //print("Button turning gray")
                    } else {
                        selectedIndices.insert(i)
                        question.choices[i].selected = true;
                        selectedChoice.selected = true;
                        //print("Button turning green")
                    }
                    
                }
                
            }
            
        } else {
            
            selectedIndices = []
            for (i,choice) in question.choices.enumerated() {
                if selectedChoice.uuid == choice.uuid {
                    choice.selected = true;
                    selectedIndices = [i]
                } else {
                    choice.selected = false;
                }
                
            }
            
        }
        
        if ( selectedChoice.allowsCustomTextEntry && selectedChoice.selected ) {
            //self.scrollProxy.scrollTo(OtherTextFieldID)
        }
        
        
    }
    
    func updateCustomText( _ selectedChoice : MultipleChoiceResponse, _ text : String ) {
        
        for (i,choice) in question.choices.enumerated() {
            if selectedChoice.uuid == choice.uuid {
                question.choices[i].customTextEntry = text
                selectedChoice.customTextEntry = text
            }
        }
        
    }
    
}

struct MultipleChoiceQuestionView : View {
    
    @ObservedObject var question : MultipleChoiceQuestion
    var scrollProxy : ScrollViewProxy
    
    // @State hack required to update view it seems
    @State var selectedIndices : Set<Int> = []
    
    @State private var customTextEntry: String = ""
    
    
    var body: some View {
        VStack {
                    
            Text(question.title).font(.title).fontWeight(.bold).padding(EdgeInsets(top:14, leading: 16, bottom: 8, trailing: 16)).foregroundColor(.black)
            
        if question.allowsMultipleSelection {
            Text("Pick as many as you want").font(.title3).italic().foregroundColor(Color(.gray))
        }
            
        ForEach(question.choices, id: \.uuid) { choice in
            
            MultipleChoiceResponseView(question: question,
                                       choice: choice,
                                       selectedIndices: $selectedIndices,
                                       scrollProxy: scrollProxy)
            
        } // end ForEach
            
        }
        .frame(maxWidth: .infinity) // stretch whole width
        //.background(Color.white)
        
    }
    
    func selectChoice( _ selectedChoice : MultipleChoiceResponse ) {
        // required to refresh the view ...
        // not sure how to do it automatically
        //selectedChoiceIndex = -1
        if question.allowsMultipleSelection {
            
            for (i,choice) in question.choices.enumerated() {
                if selectedChoice.uuid == choice.uuid {
                    if selectedIndices.contains(i) {
                        selectedIndices.remove(i)
                        question.choices[i].selected = false;
                        selectedChoice.selected = false;
                    } else {
                        selectedIndices.insert(i)
                        question.choices[i].selected = true;
                        selectedChoice.selected = true;
                    }
                    
                }
                
            }
            
        } else {
            
            selectedIndices = []
            for (i,choice) in question.choices.enumerated() {
                if selectedChoice.uuid == choice.uuid {
                    choice.selected = true;
                    selectedIndices = [i]
                } else {
                    choice.selected = false;
                }
                
            }
            
        }
        
    }
    
    func updateCustomText( _ selectedChoice : MultipleChoiceResponse, _ text : String ) {
        
        for (i,choice) in question.choices.enumerated() {
            if selectedChoice.uuid == choice.uuid {
                question.choices[i].customTextEntry = text
                selectedChoice.customTextEntry = text
            }
        }
        
    }
    
}


struct TimeInputQuestionView : View {
    
    @ObservedObject var question : TimeInputQuestion
    
    
    var body : some View {
        VStack {
            Text(question.title).font(.title).fontWeight(.bold).padding(EdgeInsets(top: 12, leading: 28, bottom: 2, trailing: 28)).foregroundColor(.black)
            Text(question.subtitle).font(.title3).italic().foregroundColor(.gray)
                .padding(EdgeInsets(top: 0, leading: 28, bottom: 1, trailing: 28))
            
            
            VStack(alignment: .leading) {

                Text("Answer"/*"Comments"*/)
                    .font(.callout)
                    .bold()
                    .foregroundColor(.black)

                DatePicker("Please enter a date", selection: $question.timeOnWheels, displayedComponents:.hourAndMinute)
                    .onChange(of: question.timeOnWheels) { newValue in
                        question.feedback=newValue.formatted()
                    }
                    
                
//                TextField("# of servings", text: $question.feedback)
//                    .textFieldStyle(PlainTextFieldStyle())
//                    .frame(width: 75.0)
//                    .background(RoundedRectangle(cornerRadius: 15)
//                        .fill(Color.white))
//                    .foregroundColor(.black)
//                    .border(Color.black)

            }
            
            .padding()
            
        
        }
                
    }
    
}





// Not sure how this is used
protocol SurveyViewDelegate : AnyObject {
    func surveyCompleted( with survey : Survey )
    func surveyDeclined()
    func surveyRemindMeLater()
}

struct SurveyView: View {
    

    var PhoneLogger = PhoneAppLogger.shared
    
    @Binding var wasSurveySubmittedFlag: Bool
    
    
    @ObservedObject var survey : Survey
    //let survey : Survey
    @State var currentQuestion : Int = 0
    
    enum SurveyState {
        case showingIntroScreen
        case taking
        case onConfirmation
        case submitted
    }
    
    //Value used by IntroView to trigger starting the survey
    @State var startSurveyFlag: Bool = false
    
    @State var surveyState : SurveyState = .taking
    @State var processing = false
    
    @ObservedObject private var keyboard = KeyboardResponder()
    
    @State var showSheet: Bool = false
    @State var jsonData: Data?
    
    // Save Time when user took the survey and ended the survey
    @State var startSurveyTime: Date = Date.now // Date(timeIntervalSince1970: 0) // Initialize to not null
    @State var endSurveyTime: Date = Date(timeIntervalSince1970: 0) // Initialize to not null
    
    var participantID: String
    @StateObject private var vm = FileManagerViewModel()
    // Deprecated in iOS 17.4, may need to switch to isPresented or dismiss (15.0+)
    @Environment(\.presentationMode) private var presentationMode
    
    var body: some View {

        
        if surveyState == .onConfirmation {
            VStack {
                
                Text("Are you finished taking the survey?")
                    .font(.title)
                    .padding(30)
                    .multilineTextAlignment(.center)
                
                ProgressView()
                    .opacity( processing ? 1.0 : 0.0 )
                
                Button(action: {
                    PhoneLogger.info(Subsystem: "Surv", Msg: "Submit Button Pressed")
                    submitSurveyTapped()
                    self.surveyState = .submitted
                }, label: {
                    Text("YES - Submit Survey").bold()
                })
                .buttonStyle(.borderedProminent)
//                .buttonStyle(CustomButtonStyle(bgColor: Color.blue))
                .padding()
                .font(.title3)
                
            
                Button(action: {
                    self.editSurveyResponsesTapped()
                    
                }, label: {
                    Text("NO - Edit Responses")
                })
                .buttonStyle(.bordered)
                .padding()
                .font(.title3)
            }
            
        } 
        else if surveyState == .submitted {
            VStack {
                
                Text("Thank you for submitting the survey for this meal!")
                    .font(.system(size: 45))
                    .multilineTextAlignment(.center)
              
                Text("We really appreciate your feedback!")
                    .font(.title)
                    .padding(30)
                    .multilineTextAlignment(.center)
                
                ProgressView()
                    .opacity( processing ? 1.0 : 0.0 )
                
                Button(action: {
                    PhoneLogger.info(Subsystem: "Surv", Msg: "Leaving Survey View")
                    // Used for iOS13.0-17.4
                    presentationMode.wrappedValue.dismiss()
                    //Switch to dismiss (not presentation mode dismiss) for iOS 15+
                    //showSheet.toggle()
                }, label: {
                    Text("Return to Main App").bold()
                })
                .buttonStyle(.borderedProminent)
//                .buttonStyle(CustomButtonStyle(bgColor: Color.blue))
                .padding()
            }
            
        }
        
        else { // surveyState == .taking
        
            VStack(spacing:0) {
                                    
                Text("Question ".appendingFormat("%i of %i", currentQuestion+1, self.survey.questions.count))
                    .bold().padding(EdgeInsets(top: 5, leading: 0, bottom: 2, trailing: 0))
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.black)
                    .font(.title2)
                
                        

                ForEach(survey.questions.indices, id: \.self) { i in
                    
                    if i == currentQuestion {
                        
                        ScrollViewReader { proxy in
                        ScrollView {
                            
                            if let question = survey.questions[currentQuestion] as? MultipleChoiceQuestion {
                                MultipleChoiceQuestionView(question: question, scrollProxy: proxy )
                            } else if let question = survey.questions[currentQuestion] as? BinaryQuestion {
                                BinaryChoiceQuestionView(question: question, onChoiceMade: { nextTapped() })
                            } else if let question = survey.questions[currentQuestion] as? ContactFormQuestion {
                                ContactFormQuestionView(question: question)
                            } else if let question = survey.questions[currentQuestion] as? CommentsFormQuestion {
                                CommentsFormQuestionView(question: question)
                            } else if let question = survey.questions[currentQuestion] as? InlineMultipleChoiceQuestionGroup {
                                InlineMultipleChoiceQuestionGroupView(group: question)
                            } else if let question = survey.questions[currentQuestion] as? TimeInputQuestion {
                                TimeInputQuestionView(question: question)
                            }
                            
                            
                        }
                        .background(Color.white)
                        .keyboardAware()
                        .overlay(Rectangle().frame(width: nil, height: 1, alignment: .top).foregroundColor(Color(.systemGray4)), alignment: .top)
                        }


                    }
                }
                
                
                
                
                HStack() {
                                    
                    Button(action: { previousTapped() }, label: {
                        Text("Previous").foregroundColor(Color(.secondaryLabel)).bold()
                    }).buttonStyle(CustomButtonStyle(bgColor: Color(.systemGray5)))
                    
                    Spacer()
                    Button(action: { nextTapped() }, label: {
                        Text("Next").bold()
                    }).buttonStyle(CustomButtonStyle(bgColor: Color.blue))
                                    
                }.padding(EdgeInsets(top: 12, leading: 22, bottom: 18, trailing: 22))
                    
                .background(Color(.systemGray6))
                .edgesIgnoringSafeArea( [.leading, .trailing] )
                

                
            }
            .background(Color.white)
            
            .edgesIgnoringSafeArea( .bottom )
            //.background(Color.red)
            
        }
        
            
            
    }
    
    private func closeKeyboard() {
        UIApplication.shared.endEditing()
    }
    
    
    func previousTapped() {
        var i = self.currentQuestion
        
        while i > 0 {
            i = i - 1
            
            let question = survey.questions[i]
            if question.isVisible(for: survey) {
                self.currentQuestion = i
                break
            }
        }
        
    }
    
    func nextTapped() {
        
        if self.currentQuestion == survey.questions.count-1 {
            // Survey done
            self.setToConfirmationScreen()
        } else {
            //self.currentQuestion += 1
            for i in (self.currentQuestion+1)..<self.survey.questions.count {
                let question = survey.questions[i]
                if question.isVisible(for: survey) {
                    self.currentQuestion = i
                    break
                }
                
                if i == self.survey.questions.count-1 {
                    self.setToConfirmationScreen()
                }
            }
        }
    }
    
    func submitSurveyTapped() {
        
        self.processing = true
        
        self.endSurveyTime = Date.now //Grab End Time for when submit was sent
        
        var meta : [String : String] = [:]
        
        #if DEBUG
        meta["debug"] = "true"
        #endif
        
        meta["app_version"] = Bundle.main.releaseVersionNumber
        meta["build"] = Bundle.main.buildVersionNumber
        // Add Survey Times
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd-HH-mm-ss"
        meta["start_time"] = df.string(from: self.startSurveyTime)
        meta["end_time"] = df.string(from: self.endSurveyTime)
        //Save the difference in times
        let totalTime = UInt64(self.endSurveyTime.timeIntervalSince1970 - self.startSurveyTime.timeIntervalSince1970)
        print("Total Survey Time = \(totalTime)")
        meta["elapsed_time_sec"] = totalTime.formatted()
        survey.metadata = meta
        
        surveyCompleted(with: self.survey, participantID: participantID)
        //self.delegate?.surveyCompleted(with: self.survey)
        
        // Set survey was taken flag to true
        wasSurveySubmittedFlag = true
        
        
        
        self.processing = false
        
    }

    
//    func noThanksTapped() {
//        self.delegate?.surveyDeclined()
//    }
//
//    func remindMeLaterTapped() {
//        self.delegate?.surveyRemindMeLater()
//    }
    
    func editSurveyResponsesTapped() {
        
        self.currentQuestion = 0
        self.surveyState = .taking
        
    }
    
    func setToConfirmationScreen() {
        
        self.surveyState = .onConfirmation
        
    }
    
    func surveyCompleted(with survey: Survey, participantID: String) {
        let date = Date()
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd-HH-mm-ss"
        let surveyName = participantID+"-"+df.string(from: date)+"-survey.json"
        guard let jsonUrl = vm.getSurveyURL(surveyName: surveyName) else {return}
        try? jsonData = Survey.SaveToFile(survey: survey, url: jsonUrl)
        print("Saved survey to: \n" , jsonUrl.path)
    }
    
}


