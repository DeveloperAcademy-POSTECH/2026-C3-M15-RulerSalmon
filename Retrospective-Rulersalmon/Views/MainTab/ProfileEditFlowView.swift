//
//  ProfileEditFlowView.swift
//  Retrospective-Rulersalmon
//
//  Created by DevPaul on 6/10/26.
//

import SwiftUI

struct UserInfoEditView: View {
    @StateObject private var viewModel: ProfileEditorViewModel
    let onSaved: () -> Void

    @MainActor
    init(onSaved: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: ProfileEditorViewModel())
        self.onSaved = onSaved
    }

    @MainActor
    init(
        viewModel: ProfileEditorViewModel,
        onSaved: @escaping () -> Void
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onSaved = onSaved
    }

    var body: some View {
        UserInfoView(
            nickname: $viewModel.nickname,
            selectedJob: $viewModel.selectedJob,
            selectedAgeGroup: $viewModel.selectedAgeGroup,
            validationMessage: viewModel.validationMessage,
            isNextEnabled: viewModel.canSaveUserInfo
        ) {
            if viewModel.saveUserInfo() {
                onSaved()
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}

struct MentorEditView: View {
    @StateObject private var viewModel: ProfileEditorViewModel
    let onSaved: () -> Void

    @MainActor
    init(onSaved: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: ProfileEditorViewModel())
        self.onSaved = onSaved
    }

    @MainActor
    init(
        viewModel: ProfileEditorViewModel,
        onSaved: @escaping () -> Void
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onSaved = onSaved
    }

    var body: some View {
        MentorSelectView(
            selectedMentorID: $viewModel.selectedMentorID,
            validationMessage: viewModel.validationMessage
        ) {
            if viewModel.saveMentor() {
                onSaved()
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}

struct UserInfoEditView_Previews: PreviewProvider {
    static var previews: some View {
        UserInfoEditView(onSaved: {})
    }
}

struct MentorEditView_Previews: PreviewProvider {
    static var previews: some View {
        MentorEditView(onSaved: {})
    }
}
