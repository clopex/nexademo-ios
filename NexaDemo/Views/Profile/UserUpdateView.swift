import PhotosUI
import SwiftUI
import UIKit

struct UserUpdateView: View {
    @Environment(AuthViewModel.self) private var authVM
    @State private var viewModel = UserUpdateViewModel()
    @State private var countryStore = CountryLookupStore()
    @State private var selectedItem: PhotosPickerItem?
    @State private var showCamera = false
    @State private var showImageSourceDialog = false
    @State private var showPhotoPicker = false
    @State private var showCountryPicker = false
    @State private var showDialCodePicker = false
    @FocusState private var focusField: Field?

    private enum Field: Hashable {
        case fullName
        case phone
        case country
        case city
        case address
    }

    var body: some View {
        ZStack {
            Color("Background").ignoresSafeArea()

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        HStack(alignment: .center, spacing: 16) {
                            Button {
                                showImageSourceDialog = true
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(Color.white)
                                        .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 6)

                                    if let image = viewModel.profileImage {
                                        Image(uiImage: image)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 100, height: 100)
                                            .clipShape(.circle)
                                    } else {
                                        Image(systemName: "person.crop.circle")
                                            .font(.largeTitle)
                                            .foregroundStyle(.black.opacity(0.4))
                                    }
                                }
                                .frame(width: 100, height: 100)
                                .overlay {
                                    if viewModel.isUploadingImage {
                                        AvatarProgressRing(isAnimating: viewModel.isUploadingImage)
                                            .frame(width: 103, height: 103)
                                    }
                                }
                            }
                            .buttonStyle(.plain)

                            HStack(spacing: 12) {
                                Button {
                                    Task { await viewModel.uploadProfileImage() }
                                } label: {
                                    Text(viewModel.isUploadingImage ? "Saving..." : "Save")
                                        .bold()
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.black)
                                .disabled(viewModel.selectedImageData == nil || viewModel.isUploadingImage)

                                Button {
                                    viewModel.deleteProfileImage()
                                } label: {
                                    Text("Delete")
                                        .bold()
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.bordered)
                                .tint(.black)
                                .disabled(viewModel.profileImage == nil && viewModel.profileImageURL == nil)
                            }
                            .frame(maxWidth: 200)
                        }
                        .padding(.top, 12)

                        VStack(spacing: 20) {
                            TextField("Full name", text: $viewModel.fullName)
                                .textFieldStyle(.plain)
                                .textInputAutocapitalization(.words)
                                .focused($focusField, equals: .fullName)
                                .id(Field.fullName)
                                .padding()
                                .background(Color.white)
                                .clipShape(.rect(cornerRadius: 14))
                                .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 6)

                            Menu {
                                Button("Male") { viewModel.gender = "Male" }
                                Button("Female") { viewModel.gender = "Female" }
                                Button("Other") { viewModel.gender = "Other" }
                                Button("Prefer not to say") { viewModel.gender = "Prefer not to say" }
                            } label: {
                                HStack {
                                    Text(viewModel.gender)
                                        .foregroundStyle(.black.opacity(viewModel.gender == "Select" ? 0.4 : 0.85))
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .foregroundStyle(.black.opacity(0.4))
                                }
                                .padding()
                                .background(Color.white)
                                .clipShape(.rect(cornerRadius: 14))
                                .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 6)
                            }
                            .buttonStyle(.plain)

                            Button {
                                showCountryPicker = true
                            } label: {
                                HStack {
                                    Text(viewModel.country.isEmpty ? "Country" : viewModel.country)
                                        .foregroundStyle(.black.opacity(viewModel.country.isEmpty ? 0.4 : 0.85))
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .foregroundStyle(.black.opacity(0.4))
                                }
                                .padding()
                                .background(Color.white)
                                .clipShape(.rect(cornerRadius: 14))
                                .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 6)
                            }
                            .buttonStyle(.plain)

                            HStack(spacing: 12) {
                                Button {
                                    showDialCodePicker = true
                                } label: {
                                    Text(viewModel.phoneDialCode)
                                        .foregroundStyle(.black.opacity(0.85))
                                }
                                .buttonStyle(.plain)

                                Divider()
                                    .frame(height: 22)
                                    .background(Color.black.opacity(0.1))

                                TextField("Phone", text: $viewModel.phone)
                                    .textFieldStyle(.plain)
                                    .keyboardType(.phonePad)
                                    .textContentType(.telephoneNumber)
                                    .focused($focusField, equals: .phone)
                                    .id(Field.phone)
                            }
                            .padding()
                            .background(Color.white)
                            .clipShape(.rect(cornerRadius: 14))
                            .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 6)
                            .onChange(of: viewModel.phone) { _, newValue in
                                let formatted = viewModel.formatPhoneInput(newValue)
                                if formatted != newValue {
                                    viewModel.phone = formatted
                                }
                            }

                            TextField("City", text: $viewModel.city)
                                .textFieldStyle(.plain)
                                .textInputAutocapitalization(.words)
                                .focused($focusField, equals: .city)
                                .id(Field.city)
                                .padding()
                                .background(Color.white)
                                .clipShape(.rect(cornerRadius: 14))
                                .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 6)

                            TextField("Address", text: $viewModel.address)
                                .textFieldStyle(.plain)
                                .textInputAutocapitalization(.words)
                                .focused($focusField, equals: .address)
                                .id(Field.address)
                                .padding()
                                .background(Color.white)
                                .clipShape(.rect(cornerRadius: 14))
                                .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 6)
                        }

                        Button {
                            Task {
                                if let user = await viewModel.updateProfile() {
                                    authVM.currentUser = user
                                    authVM.needsProfileSetup = false
                                }
                            }
                        } label: {
                            Text(viewModel.isUpdatingProfile ? "Updating..." : "Update")
                                .bold()
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 54)
                                .background(Color.black)
                                .clipShape(.rect(cornerRadius: 14))
                        }
                        .disabled(viewModel.isUpdatingProfile || viewModel.isUploadingImage)
                        .padding(.top, 8)

                        if let message = viewModel.imageStatusMessage {
                            Text(message)
                                .font(.footnote)
                                .foregroundStyle(.black.opacity(0.7))
                        }

                        if let message = viewModel.updateStatusMessage {
                            Text(message)
                                .font(.footnote)
                                .foregroundStyle(.black.opacity(0.7))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 220)
                }
                .scrollIndicators(.hidden)
                .onChange(of: focusField) { _, newValue in
                    guard let newValue else { return }
                    withAnimation(.easeInOut(duration: 0.2)) {
                        proxy.scrollTo(newValue, anchor: .top)
                    }
                }
            }
        }
        .navigationTitle("Update Profile")
        .sheet(isPresented: $showCamera) {
            CameraPickerView { image, data in
                viewModel.setSelectedImage(image, data: data)
            }
        }
        .onChange(of: selectedItem) { _, newItem in
            Task {
                let data = try? await newItem?.loadTransferable(type: Data.self)
                let image = data.flatMap { UIImage(data: $0) }
                await MainActor.run {
                    viewModel.setSelectedImage(image, data: data)
                }
            }
        }
        .confirmationDialog("Profile image", isPresented: $showImageSourceDialog, titleVisibility: .visible) {
            Button("Camera") { openCamera() }
            Button("Photo Library") { showPhotoPicker = true }
            Button("Cancel", role: .cancel) {}
        }
        .photosPicker(isPresented: $showPhotoPicker, selection: $selectedItem, matching: .images)
        .sheet(isPresented: $showCountryPicker) {
            if countryStore.isLoading {
                ProgressView()
            } else {
                CountryPickerView(countries: countryStore.countries) { selected in
                    viewModel.country = selected.name
                    if let dial = selected.dialCodes.first {
                        viewModel.phoneDialCode = dial
                    }
                }
            }
        }
        .sheet(isPresented: $showDialCodePicker) {
            if countryStore.isLoading {
                ProgressView()
            } else {
                DialCodePickerView(dialCodes: countryStore.dialCodes) { selected in
                    viewModel.phoneDialCode = selected.dialCode
                }
            }
        }
        .task {
            await countryStore.loadIfNeeded()
        }
    }

    private func openCamera() {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            showCamera = true
        } else {
            viewModel.imageStatusMessage = "Camera not available."
        }
    }
}

#Preview {
    NavigationStack {
        UserUpdateView()
            .environment(AuthViewModel())
    }
}
