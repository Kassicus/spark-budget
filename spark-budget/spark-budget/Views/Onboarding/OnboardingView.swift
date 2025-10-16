//
//  OnboardingView.swift
//  spark-budget
//
//  Created by Kason Suchow on 10/16/25.
//

import SwiftUI

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    @State private var currentPage = 0

    let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "dollarsign.circle.fill",
            title: "Welcome to Spark Budget",
            description: "Take control of your finances with smart budgeting tools and insights",
            color: .blue
        ),
        OnboardingPage(
            icon: "banknote.fill",
            title: "Track All Your Accounts",
            description: "Manage checking, savings, credit cards, and more in one place",
            color: .green
        ),
        OnboardingPage(
            icon: "calendar.badge.clock",
            title: "Daily Budget Calculator",
            description: "Know exactly how much you can spend each day until your next payday",
            color: .orange
        ),
        OnboardingPage(
            icon: "chart.bar.fill",
            title: "Powerful Analytics",
            description: "Visualize spending patterns and make informed financial decisions",
            color: .purple
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Page indicator
            HStack(spacing: 8) {
                ForEach(0..<pages.count, id: \.self) { index in
                    Capsule()
                        .fill(currentPage == index ? Color.primary : Color.gray.opacity(0.3))
                        .frame(width: currentPage == index ? 32 : 8, height: 8)
                        .animation(.smooth, value: currentPage)
                }
            }
            .padding(.top, 20)
            .padding(.bottom, 40)

            // Content
            TabView(selection: $currentPage) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                    OnboardingPageView(page: page)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            // Buttons
            VStack(spacing: 16) {
                if currentPage == pages.count - 1 {
                    Button {
                        completeOnboarding()
                    } label: {
                        Text("Get Started")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                    .sensoryFeedback(.success, trigger: currentPage)
                } else {
                    Button {
                        withAnimation {
                            currentPage += 1
                        }
                    } label: {
                        Text("Continue")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                }

                if currentPage < pages.count - 1 {
                    Button {
                        completeOnboarding()
                    } label: {
                        Text("Skip")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
    }

    private func completeOnboarding() {
        withAnimation {
            hasCompletedOnboarding = true
        }
        dismiss()
    }
}

struct OnboardingPage {
    let icon: String
    let title: String
    let description: String
    let color: Color
}

struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: page.icon)
                .font(.system(size: 80))
                .foregroundStyle(page.color)
                .symbolEffect(.bounce, value: page.icon)

            VStack(spacing: 12) {
                Text(page.title)
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text(page.description)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()
        }
        .padding()
    }
}

#Preview {
    OnboardingView()
}
