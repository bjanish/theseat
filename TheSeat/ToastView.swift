import SwiftUI

struct ToastView: View {
    let message: String
    var borderColor: Color = Color(red: 0.85, green: 0.70, blue: 0.40)

    var body: some View {
        Text(message)
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(white: 0.14))
                    .stroke(borderColor.opacity(0.6), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.3), radius: 8)
    }
}

struct ToastModifier: ViewModifier {
    @Binding var toast: ToastMessage?

    func body(content: Content) -> some View {
        ZStack {
            content

            if let toast {
                VStack {
                    ToastView(message: toast.text, borderColor: toast.borderColor)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .padding(.top, 60)
                    Spacer()
                }
                .id(toast.id)
                .animation(.easeInOut(duration: 0.3), value: self.toast)
            }
        }
    }
}

struct ToastMessage: Equatable, Identifiable {
    let id = UUID()
    let text: String
    var borderColor: Color = Color(red: 0.85, green: 0.70, blue: 0.40)
    var duration: Double = 3.0

    static func == (lhs: ToastMessage, rhs: ToastMessage) -> Bool {
        lhs.id == rhs.id
    }
}

extension View {
    func toast(_ toast: Binding<ToastMessage?>) -> some View {
        self.modifier(ToastModifier(toast: toast))
    }
}

#Preview {
    ZStack {
        Color(white: 0.12).ignoresSafeArea()
        ToastView(message: "Brian joined")
    }
}
