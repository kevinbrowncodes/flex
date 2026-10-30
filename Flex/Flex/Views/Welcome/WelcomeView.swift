//
//  WelcomeView.swift
//  Flex
//
//  Created by Kevin Brown on 2/7/26.
//

import SwiftUI
import AuthenticationServices

struct WelcomeView: View {
    @Environment(AuthenticationManager.self) private var authManager
    @Environment(PreferencesManager.self) private var preferencesManager
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            Image(systemName: "figure.strengthtraining.traditional")
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .foregroundStyle(.gray.opacity(0.3))
                .ignoresSafeArea()
                .accessibilityHidden(true)

            Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: 30) {
                Spacer()

                VStack(spacing: 16) {
                    Text("Welcome to Flex")
                        .font(.system(size: 44, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    Text("Your workout journey starts here.")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 40)

                Spacer()

                VStack(spacing: 16) {
                    SignInWithAppleButton(
                        onRequest: { request in
                            request.requestedScopes = [.fullName, .email]
                        },
                        onCompletion: handleSignIn
                    )
                    .signInWithAppleButtonStyle(.white)
                    .frame(height: 50)
                    .cornerRadius(12)
                    .accessibilityIdentifier("sign-in-with-apple")

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                    }

                    Text("Track workouts • Build strength • Achieve goals")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 50)
            }
        }
    }

    private func handleSignIn(_ result: Result<ASAuthorization, Error>) {
        authManager.handleSignInWithApple(result: result)

        if authManager.isAuthenticated {
            errorMessage = nil
            withAnimation {
                preferencesManager.setHasSeenWelcome(true)
            }
            return
        }

        switch result {
        case .failure(let error):
            let authError = error as? ASAuthorizationError
            switch authError?.code {
            case .canceled?:
                // The user dismissed the Apple sheet; nothing went wrong.
                errorMessage = nil
            case .notHandled?, .unknown?:
                errorMessage = "Sign in isn't available right now. Please try again."
            default:
                errorMessage = "Sign in failed. Please try again."
            }
        case .success:
            errorMessage = "Sign in failed. Please try again."
        }
    }
}

#Preview {
    WelcomeView()
        .environment(AuthenticationManager())
        .environment(PreferencesManager())
}
