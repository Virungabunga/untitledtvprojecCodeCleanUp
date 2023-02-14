//
//  ContentView.swift
//  untitledtvproject
//
//  Created by Emil Åkerman on 2023-01-10.
//

import SwiftUI
import FirebaseCore
import FirebaseAuth
import Firebase
import FirebaseFirestoreSwift
import FirebaseFirestore

struct ContentView: View {
    
    @State var signedIn = false
    
    @State var wantToSignUp = false
    
    @State var createdAccount = false
    
    var body: some View {
        if Auth.auth().currentUser != nil || signedIn {
            OverView()
        }
        if Auth.auth().currentUser == nil && !wantToSignUp {
            LoginView(signedIn: $signedIn, wantToSignUp: $wantToSignUp, createdAccount: $createdAccount)
        }
        if Auth.auth().currentUser == nil && wantToSignUp {
            SignUpView(wantToSignUp: $wantToSignUp, createdAccount: $createdAccount, signedIn: $signedIn)
        }
    }
}
struct LoginView: View {
    
    @Binding var signedIn : Bool
    @Binding var wantToSignUp : Bool
    @Binding var createdAccount : Bool
    
    @State var userInput : String = ""
    @State var pwInput : String = ""
    
    var newColor = Color(red: 243 / 255, green: 246 / 255, blue: 255 / 255)
    
    var body: some View {
        VStack {
            Text("Sign in")
            TextField("Username", text: $userInput)
                .padding()
                .background(newColor)
                .cornerRadius(5.0)
                .padding(.bottom, 20)
            SecureField("Password", text: $pwInput)
                .padding()
                .background(newColor)
                .cornerRadius(5.0)
                .padding(.bottom, 20)
            Button(action: { signIn() }) {
                Text("Sign in")}
            .font(.headline)
            .foregroundColor(.white)
            .padding()
            .frame(width: 220, height: 60)
            .background(Color.green)
            .cornerRadius(15.0)
            NavigationLink(destination: SignUpView(wantToSignUp: $wantToSignUp, createdAccount: $createdAccount, signedIn: $signedIn)) {
                Text("No account? Create account here")
            }
        }
        .navigationBarBackButtonHidden(true)
    }
    func signIn() {
        Auth.auth().signIn(withEmail: userInput, password: pwInput) { (result, error) in
            if error != nil {
                print(error?.localizedDescription ?? "")
            } else {
                signedIn = true
            }
        }
    }
}
struct SignUpView: View {
    
    @Binding var wantToSignUp : Bool
    @Binding var createdAccount : Bool
    @Binding var signedIn : Bool
    
    @State var userInput : String = ""
    @State var pwInput : String = ""
    
    var newColor = Color(red: 243 / 255, green: 246 / 255, blue: 255 / 255)
    
    var body: some View {
        VStack {
            Text("Create account")
            TextField("Username", text: $userInput)
                .padding()
                .background(newColor)
                .cornerRadius(5.0)
                .padding(.bottom, 20)
            SecureField("Password", text: $pwInput)
                .padding()
                .background(newColor)
                .cornerRadius(5.0)
                .padding(.bottom, 20)
            Button(action: { signUp() }) {
                Text("Create account")}
            .font(.headline)
            .foregroundColor(.white)
            .padding()
            .frame(width: 220, height: 60)
            .background(Color.green)
            .cornerRadius(15.0)
            NavigationLink(destination: LoginView(signedIn: $signedIn, wantToSignUp: $wantToSignUp, createdAccount: $createdAccount)) {
                Text("Already got an account? Login here")
            }
        }
        .navigationBarBackButtonHidden(true)
    }
    func signUp() {
        Auth.auth().createUser(withEmail: userInput, password: pwInput) { result, error in
            if let error = error {
                print("an error occured: \(error.localizedDescription)")
                return
            }
            if (result?.user.uid != nil) { createdAccount = true ; wantToSignUp = false ; signedIn = true }
        }
    }
}
struct OverView : View {
    
    //@State var searchScope = ApiShows.SearchScope.name
        
    @StateObject var showList = ShowList()
    @StateObject var apiShows = ApiShows()
    
    @State var searchText = ""
                
    let db = Firestore.firestore()
    
    @State var showingAlert = false
    
    @State var showingSettingsAlert = false


    var body: some View {
        NavigationView { //switched place vstack and navview test, vstack was on top at first
             VStack {
                Form {
                    Section {
                        ForEach(filteredMessages, id: \.show.summary) { returned in
                            NavigationLink(destination: ShowEntryView(show2: returned, name: returned.show.name, language: returned.show.language, summary: returned.show.summary, image: returned.show.image)) {
                                    RowTest(showTest: returned)
                            }
                        }
                    }
                    .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))/*
                   .searchScopes($searchScope) {
                       ForEach(ApiShows.SearchScope.allCases, id: \.self) { scope in //replace the .self with something else
                           Text(scope.rawValue.capitalized)
                       }
                   }*/
                   .onSubmit(of: .search, getData)
                   //.onChange(of: searchScope) { _ in getData()}
                   .disableAutocorrection(true)
                    Section(header: Text("Want to watch")) {
                        ForEach(showList.lists[.wantToWatch]!, id: \.show.summary.hashValue) { returned in //show.summary.hashValue istället för ett unikt ID, summary är alltid unikt
                            NavigationLink(destination: ShowEntryView(show2: returned, name: returned.show.name, language: returned.show.language, summary: returned.show.summary, image: returned.show.image)) {
                                    RowTest(showTest: returned)
                            }
                        }
                        .onDelete() { indexSet in
                            showList.delete(indexSet: indexSet, status: .wantToWatch)
                        }
                    }
                    Section(header: Text("Watching")) {
                        ForEach(showList.lists[.watching]!, id: \.show.summary.hashValue) { returned in
                            NavigationLink(destination: ShowEntryView(show2: returned, name: returned.show.name, language: returned.show.language, summary: returned.show.summary, image: returned.show.image)) {
                                RowTest(showTest: returned)
                            }
                        }
                        .onDelete() { indexSet in
                            showList.delete(indexSet: indexSet, status: .watching)
                        }
                    }
                    .onAppear() {
                        listenToFireStore()
                    }
                    
                    Section(header: Text("Completed")) {
                        ForEach(showList.lists[.completed]!, id: \.show.summary.hashValue) { returned in
                            NavigationLink(destination: ShowEntryView(show2: returned, name: returned.show.name, language: returned.show.language, summary: returned.show.summary, image: returned.show.image)) {
                                RowTest(showTest: returned)
                            }
                        }
                        .onDelete() { indexSet in
                            showList.delete(indexSet: indexSet, status: .completed)
                        }
                    }
                    Section(header: Text("Dropped")) {
                        ForEach(showList.lists[.dropped]!, id: \.show.summary.hashValue) { returned in
                            NavigationLink(destination: ShowEntryView(show2: returned, name: returned.show.name, language: returned.show.language, summary: returned.show.summary, image: returned.show.image)) {
                                RowTest(showTest: returned)
                            }
                        }
                        .onDelete() { indexSet in
                            showList.delete(indexSet: indexSet, status: .dropped)
                        }
                    }
                    /*
                    Section(header: Text("Recently deleted")) {
                        ForEach(showList.lists[.recentlyDeleted]!) { show in
                            NavigationLink(destination: ShowEntryView(name: show.name, language: show.language, summary: show.summary)) {
                                RowView(show: show)
                            }
                        }
                    }*/
                }
                .toolbar {
                    ToolbarItemGroup(placement: .bottomBar) {
                        HStack {
                            Button(action: {
                                //do nothing
                            }) {
                                Image("house.fill")
                                    .renderingMode(Image.TemplateRenderingMode?.init(Image.TemplateRenderingMode.original))
                            }
                            Spacer()
                            Button(action: {
                                
                            }) {
                                Image("redstats")
                                    .renderingMode(Image.TemplateRenderingMode?.init(Image.TemplateRenderingMode.original))
                            }
                            Spacer()
                            Button(action: {
                                
                            }) {
                                Image("plus.app")
                                    .renderingMode(Image.TemplateRenderingMode?.init(Image.TemplateRenderingMode.original))
                            }
                            Spacer()
                            Button(action: {
                                showingSettingsAlert = true
                            }) {
                                Image("square.and.pencil.circle.fill")
                                    .renderingMode(Image.TemplateRenderingMode?.init(Image.TemplateRenderingMode.original))
                            }
                            .alert("Settings", isPresented: $showingSettingsAlert) {
                                VStack {
                                    Button("Row background color") {
                                        
                                    }
                                    Button("Row text color") {
                                        //textColor = Color.blue
                                    }
                                    Button("Cancel", role: .cancel) { }
                                }
                            }
                            Spacer()
                            NavigationLink(destination: ProfileView(selectedUserName: "", userName: "")) {
                                Image("person.crop.circle.fill")
                                    .renderingMode(Image.TemplateRenderingMode?.init(Image.TemplateRenderingMode.original))
                            }
                        }
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationViewStyle(StackNavigationViewStyle())
    }
    var filteredMessages: [ApiShows.Returned] {
        searchText.isEmpty ? [] : apiShows.searchArray.filter{$0.show.name.localizedCaseInsensitiveContains(searchText)}
        /*
        if searchText.isEmpty {
            return apiShows.searchArray
        } else {
            if apiShows.searchArray.isEmpty {
                return apiShows.searchArray
            }
            return apiShows.searchArray.filter { $0.show.name.localizedCaseInsensitiveContains(searchText) }
        }*/
    }
    func listenToFireStore() { //make this shorter

        guard let user = Auth.auth().currentUser else {return}
                
        db.collection("users").document(user.uid).collection("Watching").addSnapshotListener { snapshot, err in
            guard let snapshot = snapshot else {return}
            
            if let err = err {
                print("Error getting document \(err)")
            } else {
                showList.lists[.watching]?.removeAll()
                for document in snapshot.documents {
                    let result = Result {
                        try document.data(as: ApiShows.Returned.self)
                    }
                    switch result  {
                    case .success(let show)  :
                        showList.lists[.watching]?.append(show)
                    case .failure(let error) :
                        print("Error decoding item: \(error)")
                    }
                }
            }
        }
        db.collection("users").document(user.uid).collection("Completed").addSnapshotListener { snapshot, err in
            guard let snapshot = snapshot else {return}
            
            if let err = err {
                print("Error getting document \(err)")
            } else {
                showList.lists[.completed]?.removeAll()
                for document in snapshot.documents {
                    let result = Result {
                        try document.data(as: ApiShows.Returned.self)
                    }
                    switch result  {
                    case .success(let show)  :
                        showList.lists[.completed]?.append(show)
                    case .failure(let error) :
                        print("Error decoding item: \(error)")
                    }
                }
            }
        }
        db.collection("users").document(user.uid).collection("Dropped").addSnapshotListener { snapshot, err in
            guard let snapshot = snapshot else {return}
            
            if let err = err {
                print("Error getting document \(err)")
            } else {
                showList.lists[.dropped]?.removeAll()
                for document in snapshot.documents {
                    let result = Result {
                        try document.data(as: ApiShows.Returned.self)
                    }
                    switch result  {
                    case .success(let show)  :
                        showList.lists[.dropped]?.append(show)
                    case .failure(let error) :
                        print("Error decoding item: \(error)")
                    }
                }
            }
        }
        db.collection("users").document(user.uid).collection("Want to watch").addSnapshotListener { snapshot, err in
            guard let snapshot = snapshot else {return}
            
            if let err = err {
                print("Error getting document \(err)")
            } else {
                showList.lists[.wantToWatch]?.removeAll()
                for document in snapshot.documents {
                    let result = Result {
                        try document.data(as: ApiShows.Returned.self)
                    }
                    switch result  {
                    case .success(let show)  :
                        showList.lists[.wantToWatch]?.append(show)
                    case .failure(let error) :
                        print("Error decoding item: \(error)")
                    }
                }
            }
        }
    }
    func getData() {
        
        searchText = searchText.replacingOccurrences(of: " ", with: "%20")
        let urlString = "https://api.tvmaze.com/search/shows?q=\(searchText)"
        
        print("trying to access the url \(urlString)")
        
        guard let url = URL(string: urlString) else {
            print("Error could not create url from \(urlString)")
            return
        }
        searchText = searchText.replacingOccurrences(of: "%20", with: " ") //problem med house of the dragon "-" "-" something
        
        //create urlsession
        let session = URLSession.shared
        //get data with .dataTask meth
        let task = session.dataTask(with: url) { data, response, error in
            if let error = error {
                print("error \(error.localizedDescription)")
            }
            //deal with the data
            do {
                apiShows.searchArray = try JSONDecoder().decode([ApiShows.Returned].self, from: data!)
            } catch {
                print("catch: json error: \(error.localizedDescription)")
            }
        }
        task.resume()
    }
}
struct RowTest : View {
    var showTest : ApiShows.Returned
    @State var textColor = Color.black
    @State var showingAlert = false
    @State var listChoice = ""
    
    var body: some View {
        HStack {
            Image(systemName: "arrow.up.and.down.and.arrow.left.and.right")
                .onTapGesture {
                    showingAlert = true
                }
            Text(showTest.show.name)
                .foregroundColor(textColor)
        }
        .alert("Move to what list?", isPresented: $showingAlert) {
            VStack {
                Button("Want to watch") {
                    listChoice = "Want to watch"
                    changeListFireStore()
                }
                Button("Watching") {
                    listChoice = "Watching"
                    changeListFireStore()
                }
                Button("Completed") {
                    listChoice = "Completed"
                    changeListFireStore()
                }
                Button("Dropped") {
                    listChoice = "Dropped"
                    changeListFireStore()
                }
                Button("Cancel", role: .cancel) { }
            }
        }
    }
    func changeListFireStore() {
        let db = Firestore.firestore()
        guard let user = Auth.auth().currentUser else {return}

        do {
            //move
            _ = try db.collection("users").document(user.uid).collection(listChoice).addDocument(from: showTest)
            //print(addedDoc.documentID) //prints the destination new docID
            //remove
            /*
            db.collection("users").document(user.uid).collection("Want to watch").getDocuments() { (querySnapshot, err) in
                if let err = err {
                    print("Error getting documents: \(err)")
                } else {
                    for document in querySnapshot!.documents {
                        //db.collection("users").document(user.uid).collection("Want to watch").document(addedDoc.documentID).delete()
                        print("\(document.documentID)") // Gets all documentIDs, so almost there
                    }
                }
            }*/
        } catch {
            print("catch error!")
            }/*
        func newFetch() {
            db.collection("users").document(user.uid).collection("Want to watch").addSnapshotListener { (querySnapshot, error) in
                guard let documents = querySnapshot?.documents else {
                    print("no docs")
                    return
                }
                documents.compactMap { (queryDocumentSnapshot) -> ApiShows.Returned? in
                    return try? queryDocumentSnapshot.data(as: ApiShows.Returned.self)
                }
            }
        }
        func fetchDocID(documentId: String) {
            let docRef = db.collection("users").document(user.uid).collection("Want to watch").document(showTest.show.id ?? "")

          docRef.getDocument { document, error in
            if let error = error as NSError? {
            print("Error getting document: \(error.localizedDescription)")
            }
            else {
              if let document = document {
                let id = document.documentID
                db.collection("users").document(user.uid).collection("Want to watch").document(id).delete()
                let data = document.data()
                let title = data?["title"] as? String ?? ""
                let numberOfPages = data?["numberOfPages"] as? Int ?? 0
                let author = data?["author"] as? String ?? ""
                //self.book = Book(id:id, title: title, numberOfPages: numberOfPages, author: author)
              }
            }
          }
        }*/
      }
    }
struct RowView : View {
    var show : ShowEntry
    
    var body: some View {
        HStack {
            Text(show.name)
        }
    }
}
/*
 struct ContentView_Previews: PreviewProvider {
 static var previews: some View {
 ContentView()
 }
 }
 */
