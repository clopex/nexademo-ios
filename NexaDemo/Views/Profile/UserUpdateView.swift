import PhotosUI
import SwiftUI
import UIKit

struct UserUpdateView: View {
    @Environment(AuthViewModel.self) private var authVM
    @State private var viewModel = UserUpdateViewModel()
    @State private var countryStore = CountryLookupStore()
    @State private var selectedItem: PhotosPickerItem?
    @State private var showToast = false
    @State private var toast = Toast.example
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
        let isUpdateDisabled = viewModel.isUpdatingProfile || viewModel.isUploadingImage || !viewModel.hasChanges
        let isInitialSetup = authVM.needsProfileSetup

        ZStack {
            Color("Background").ignoresSafeArea()

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        HStack(alignment: .center, spacing: 16) {
                            Button {
                                focusField = nil
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
                                    } else if let urlString = viewModel.profileImageURL,
                                              let url = URL(string: urlString) {
                                        AsyncImage(url: url) { phase in
                                            switch phase {
                                            case .success(let image):
                                                image
                                                    .resizable()
                                                    .scaledToFill()
                                            case .failure:
                                                Image(systemName: "person.crop.circle")
                                                    .foregroundStyle(.black.opacity(0.4))
                                            case .empty:
                                                ProgressView()
                                            @unknown default:
                                                Image(systemName: "person.crop.circle")
                                                    .foregroundStyle(.black.opacity(0.4))
                                            }
                                        }
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

            if isInitialSetup {
                VStack {
                    Spacer()
                    UpdateProfileBottomButtonView(
                        isDisabled: isUpdateDisabled,
                        action: handleUpdate
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                }
            }
        }
        .navigationTitle("Update Profile")
        .dynamicIslandToasts(isPresented: $showToast, value: toast)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if !isInitialSetup {
                    Button(action: handleUpdate) {
                        Image(systemName: "person.fill.checkmark")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(isUpdateDisabled ? Color.gray : Color.black)
                    }
                    .disabled(isUpdateDisabled)
                }
            }
        }
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
            viewModel.prefill(from: authVM.currentUser)
        }
        .onChange(of: authVM.currentUser?.id) { _, _ in
            viewModel.prefill(from: authVM.currentUser, force: true)
        }
    }

    private func openCamera() {
        focusField = nil
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            showCamera = true
        } else {
            viewModel.imageStatusMessage = "Camera not available."
        }
    }

    private func handleUpdate() {
        focusField = nil
        guard viewModel.hasPendingImageUpload == false else {
            toast = Toast(
                symbol: "exclamationmark.triangle.fill",
                symbolFont: .system(size: 28),
                symbolForegrgoundStyle: (.white, .orange),
                title: "Save image first",
                message: "Upload and save the selected profile image before updating."
            )
            showToast = true
            return
        }

        Task {
            if let user = await viewModel.updateProfile() {
                authVM.completeProfileSetup(with: user)
                viewModel.prefill(from: user, force: true)
            }
        }
    }
}

#Preview {
    NavigationStack {
        UserUpdateView()
            .environment(AuthViewModel())
    }
}
